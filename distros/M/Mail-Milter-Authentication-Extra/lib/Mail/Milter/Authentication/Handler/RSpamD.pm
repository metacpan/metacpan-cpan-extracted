package Mail::Milter::Authentication::Handler::RSpamD;
use strict;
use warnings;
use base 'Mail::Milter::Authentication::Handler';
use version; our $VERSION = version->declare('v1.1.5');

use English qw{ -no_match_vars };
use Sys::Syslog qw{:standard :macros};
use HTTP::Tiny;
use JSON;

use Data::Dumper;

sub default_config {
    return {
        'default_user'   => 'nobody',
        'rs_host'        => 'localhost',
        'rs_port'        => '11333',
        'hard_reject'    => 1,
        'remove_headers' => 'yes',
    }
}

sub grafana_rows {
    my ( $self ) = @_;
    my @rows;
    push @rows, $self->get_json( 'RSpamD_metrics' );
    return \@rows;
}

sub register_metrics {
    return {
        'rspamd_total' => 'The number of emails processed for RSpamD',
    };
}

sub get_user {
    my ( $self ) = @_;
    my $user_handler = $self->get_handler('UserDB');
    my $user = $user_handler->{'local_user'};
    return $user if $user;
    my $config = $self->handler_config();
    return $config->{'default_user'};
}

sub remove_header {
    my ( $self, $key, $value ) = @_;
    if ( !exists( $self->{'remove_headers'} ) ) {
        $self->{'remove_headers'} = {};
    }
    if ( !exists( $self->{'remove_headers'}->{ lc $key } ) ) {
        $self->{'remove_headers'}->{ $key } = [];
    }
    push @{ $self->{'remove_headers'}->{ lc $key } }, $value;
    return;
}

sub helo_callback {
    my ( $self, $helo_host ) = @_;
    $self->{'helo_name'} = $helo_host;
    return;
}

sub envfrom_callback {
    my ($self, $from) = @_;
    $self->{'lines'} = [];
    $self->{'rcpt_to'} = [];
    $self->{'mail_from'} = $from;
    delete $self->{'header_index'};
    delete $self->{'remove_headers'};
    $self->{'metrics_data'} = {};
    $self->{ 'metrics_data' }->{ 'header_removed' } = 'no';
    return;
}

sub envrcpt_callback {
    my ( $self, $env_to ) = @_;
    push @{ $self->{'rcpt_to'} }, $env_to;
    return;
}

sub header_callback {
    my ( $self, $header, $value ) = @_;
    push @{$self->{'lines'}} ,$header . ': ' . $value . "\r\n";
    my $config = $self->handler_config();

    return if ( $self->is_trusted_ip_address() );
    return if ( lc $config->{'remove_headers'} eq 'no' );

    foreach my $header_type ( qw{ X-Spam-score X-Spam-Status X-Spam-Action } ) {
        if ( lc $header eq lc $header_type ) {
            if ( !exists $self->{'header_index'} ) {
                $self->{'header_index'} = {};
            }
            if ( !exists $self->{'header_index'}->{ lc $header_type } ) {
                $self->{'header_index'}->{ lc $header_type } = 0;
            }
            $self->{'header_index'}->{ lc $header_type } =
            $self->{'header_index'}->{ lc $header_type } + 1;
            $self->remove_header( $header_type, $self->{'header_index'}->{ lc $header_type } );
            $self->{ 'metrics_data' }->{ 'header_removed' } = 'yes';
            if ( lc $config->{'remove_headers'} ne 'silent' ) {
                my $forged_header =
                  '(Received ' . $header_type . ' header removed by '
                  . $self->get_my_hostname()
                  . ')' . "\n"
                  . '    '
                  . $value;
                $self->append_header( 'X-Received-' . $header_type,
                    $forged_header );
            }
        }
    }

    return;
}

sub eoh_callback {
    my ( $self ) = @_;
    push @{$self->{'lines'}} , "\r\n";
    return;
}

sub body_callback {
    my ( $self, $chunk ) = @_;
    push @{$self->{'lines'}} , $chunk;
    return;
}

sub get_auth_name {
    my ($self) = @_;
    my $protocol = Mail::Milter::Authentication::Config::get_config()->{'protocol'};
    if ( $protocol ne 'milter' ) {
        return 'unauthorized';
    }
    my $name = $self->get_symbol('{auth_authen}') || 'unauthorized';
    return $name;
}

sub eom_callback {
    my ($self) = @_;

    my $config = $self->handler_config();

    my $host = $config->{'rs_host'} || 'localhost';
    my $port = $config->{'rs_port'} || 11333;
    my $user = $self->get_user();

    $self->dbgout( 'RSpamDUser', $user, LOG_INFO );

    my $queue_id = $self->get_symbol('i') || q{--};

    my $message = join( q{} , @{$self->{'lines'} } );
    my $headers = {
        'Deliver-To' => $user,
        'IP' => $self->ip_address(),
        'Helo' => $self->{'helo_name'},
        'From' => $self->{'mail_from'},
        'Queue-Id' => $queue_id,
        'Rcpt' => $self->{'rcpt_to'},
        'Pass' => 'all', # all to check all filters
        'User' => $self->get_auth_name(),
    };

    my $http = HTTP::Tiny->new(
        'keep_alive' => 0,
    );
    my $response = $http->post( "http://$host:$port/check", { 'headers' => $headers, 'content' => $message } );
    if ( ! $response->{'success'} ) {
        $self->log_error( 'RSpamD could not connect to server - ' . $response->{'status'} . ' - ' . $response->{'reason'} . ' - ' . $response->{'content'} );
        $self->add_auth_header('x-rspam=temperror');
        $self->{ 'metrics_data' }->{ 'result' } = 'servererror';
        $self->metric_count( 'rspamd_total', $self->{ 'metrics_data' } );
        return;
    }

    my $j = JSON->new();
    my $rspamd_data = eval{ $j->decode( $response->{'content'} ); };
    if ( ! exists( $rspamd_data->{'default'} ) ) {
        $self->log_error( 'RSpamD bad data from server' );
        $self->add_auth_header('x-rspam=temperror');
        $self->{ 'metrics_data' }->{ 'result' } = 'serverdataerror';
        $self->metric_count( 'rspamd_total', $self->{ 'metrics_data' } );
        return;
    }
    my $spam = $rspamd_data->{ 'default' };

    my $status = join( q{},
        ( $spam->{'is_spam'} eq 0 ? 'No, ' : 'Yes, ' ),
        'score=', sprintf( '%.02f', $spam->{'score'} ),
        ' ',
        'required=', sprintf( '%.02f', $spam->{'required_score'} ),
    );

    my $action = $spam->{'action'};

    if ( $action eq 'rewrite subject' ) {
        $action .= ' - ' . $spam->{'subject'};
        ## ToDo - Rewrite the subject
    }

    if ( $action eq 'reject' ) {
        if ( $config->{'hard_reject'} ) {
            if ( ( ! $self->is_local_ip_address() ) && ( ! $self->is_trusted_ip_address() ) ) {
                $self->reject_mail( '550 5.7.0 SPAM policy violation' );
                $self->dbgout( 'RSpamDReject', "Policy reject", LOG_INFO );
            }
        }
    }

    $self->prepend_header( 'X-Spam-score',  sprintf( '%.02f',  $spam->{'score'} ) );
    $self->prepend_header( 'X-Spam-Status', $status );
    $self->prepend_header( 'X-Spam-Action', $action );

    my $header = join(
        q{ },
        $self->format_header_entry(
            'x-rspam',
            ( $spam->{'is_spam'} eq 0 ? 'pass' : 'fail' ),
        ),
        $self->format_header_entry( 'score',    sprintf ( '%.02f', $spam->{'score'} ) ),
        $self->format_header_entry( 'required', sprintf ( '%.02f', $spam->{'required_score'} ) ),
    );

    $self->add_auth_header($header);

    $self->{ 'metrics_data' }->{ 'result' } = ( $spam->{'is_spam'} eq 0 ? 'pass' : 'fail' );

    $self->metric_count( 'rspamd_total', $self->{ 'metrics_data' } );
    return if ( lc $config->{'remove_headers'} eq 'no' );

    foreach my $header_type ( qw{ X-Spam-score X-Spam-Status X-Spam-Action } ) {
        if ( exists( $self->{'remove_headers'}->{ lc $header_type } ) ) {
            foreach my $header ( reverse @{ $self->{'remove_headers'}->{ lc $header_type } } ) {
                $self->dbgout( 'RemoveSpamHeader', $header_type . ', ' . $header, LOG_DEBUG );
                $self->change_header( lc $header_type, $header, q{} );
            }
        }
    }

    return;
}

sub close_callback {
    my ( $self ) = @_;

    delete $self->{'lines'};
    delete $self->{'mail_from'};
    delete $self->{'helo_name'};
    delete $self->{'rcpt_to'};
    delete $self->{'remove_headers'};
    delete $self->{'header_index'};
    delete $self->{'metrics_data'};
    return;
}

1;

__END__

=head1 NAME

  Authentication Milter - RSpamD Module

=head1 DESCRIPTION

Check email for spam using rspamd.

=head1 CONFIGURATION

        "RSpamD" : {
            "default_user"   : "nobody",
            "rs_host"        : "localhost",
            "rs_port"        : "11333",
            "hard_reject"    : "1",
            "remove_headers" : "yes"
        },

=head1 SYNOPSIS

=head2 CONFIG

Add a block to the handlers section of your config as follows.

        "RSpamD" : {
            "default_user"   : "nobody",
            "rs_host"        : "localhost",
            "rs_port"        : "11333",
            "hard_reject"    : "1",
            "remove_headers" : "yes"
        },

=head1 AUTHORS

Marc Bradshaw E<lt>marc@marcbradshaw.netE<gt>

=head1 COPYRIGHT

Copyright 2017

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.



