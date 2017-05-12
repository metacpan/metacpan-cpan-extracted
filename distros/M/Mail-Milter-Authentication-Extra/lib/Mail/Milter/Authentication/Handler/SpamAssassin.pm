package Mail::Milter::Authentication::Handler::SpamAssassin;
use strict;
use warnings;
use base 'Mail::Milter::Authentication::Handler';
use version; our $VERSION = version->declare('v1.1.1');

use English qw{ -no_match_vars };
use Sys::Syslog qw{:standard :macros};

use Mail::SpamAssassin;
use Mail::SpamAssassin::Client;

# Issues
#
# Message may have multiple rcpt to addresses, in this
# case we can't load individual configs, would need to
# split the message and re-inject, which is a bloody
# meess!
# HOWEVER, spamassass-milter doesn't appear to do the
# right thing either, so we're actually no worse off.

sub default_config {
    return {
        'default_user'   => 'nobody',
        'sa_host'        => 'localhost',
        'sa_port'        => '783',
        'hard_reject_at' => 10,
        'remove_headers' => 'yes',
    }
}

sub register_metrics {
    return {
        'spamassassin_total' => 'The number of emails processed for SpamAssassin',
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

sub envfrom_callback {
    my ($self) = @_;
    $self->{'lines'} = [];
    $self->{'rcpt_to'} = q{};
    delete $self->{'header_index'};
    delete $self->{'remove_headers'};
    $self->{'metrics_data'} = {};
    $self->{ 'metrics_data' }->{ 'header_removed' } = 'no';
    return;
}

sub envrcpt_callback {
    my ( $self, $env_to ) = @_;
    $self->{'rcpt_to'} = $env_to;
    return;
}

sub header_callback {
    my ( $self, $header, $value ) = @_;
    push @{$self->{'lines'}} ,$header . ': ' . $value . "\r\n";
    my $config = $self->handler_config();

    return if ( $self->is_trusted_ip_address() );
    return if ( lc $config->{'remove_headers'} eq 'no' );

    foreach my $header_type ( qw{ X-Spam-score X-Spam-Status X-Spam-hits } ) {
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

sub eom_callback {
    my ($self) = @_;

    my $config = $self->handler_config();

    my $host = $config->{'sa_host'} || 'localhost';
    my $port = $config->{'sa_port'} || 783;
    my $user = $self->get_user();

    $self->dbgout( 'SpamAssassinUser', $user, LOG_INFO );

    my $sa_client = Mail::SpamAssassin::Client->new({
        'port'     => $port,
        'host'     => $host,
        'username' => $user,
    });

    if ( ! $sa_client->ping() ) {
        $self->log_error( 'SpamAssassin could not connect to server' );
        $self->add_auth_header('x-spam=temperror');
        $self->{ 'metrics_data' }->{ 'result' } = 'servererror';
        $self->metric_count( 'spamassassin_total', $self->{ 'metrics_data' } );
        return;
    }

    my $message = join( q{} , @{$self->{'lines'} } );

    my $sa_status = $sa_client->_filter( $message, 'SYMBOLS' );
    #my $sa_status = $sa_client->check( $message );

    my $status = join( q{},
        ( $sa_status->{'isspam'} eq 'False' ? 'No, ' : 'Yes, ' ),
        'score=', sprintf( '%.02f', $sa_status->{'score'} ),
        ' ',
        'required=', sprintf( '%.02f', $sa_status->{'threshold'} ),
    );

    my $hits = $sa_status->{'message'};
    # Wrap hits header
    {
        my @hitsplit = split ',', $hits;
        my $header = q{};
        my $max = 74;
        my $part  = q{};
        my $last_hit = pop @hitsplit;
        @hitsplit = map { "$_," } @hitsplit;
        push @hitsplit, $last_hit;
        foreach my $hit ( @hitsplit ) {
            if ( length ( $part . $hit ) > $max ) {
                $header .= $part . "\n    ";
                $part = q{};
            }
            $part .= $hit;
        }
        $header .= $part;
        $hits = $header;
    }

    $self->prepend_header( 'X-Spam-score',  sprintf( '%.02f',  $sa_status->{'score'} ) );
    $self->prepend_header( 'X-Spam-Status', $status );
    $self->prepend_header( 'X-Spam-hits',   $hits );

    my $header = join(
        q{ },
        $self->format_header_entry(
            'x-spam',
            ( $sa_status->{'isspam'} eq 'False' ? 'pass' : 'fail' ),
        ),
        $self->format_header_entry( 'score',    sprintf ( '%.02f', $sa_status->{'score'} ) ),
        $self->format_header_entry( 'required', sprintf ( '%.02f', $sa_status->{'threshold'} ) ),
    );

    $self->add_auth_header($header);

    $self->{ 'metrics_data' }->{ 'result' } = ( $sa_status->{'isspam'} eq 'False' ? 'pass' : 'fail' );

    if ( $sa_status->{'isspam'} eq 'True' ) {
        if ( $config->{'hard_reject_at'} ) {
            if ( $sa_status->{'score'} >= $config->{'hard_reject_at'} ) {
                if ( ( ! $self->is_local_ip_address() ) && ( ! $self->is_trusted_ip_address() ) ) {
                    $self->reject_mail( '550 5.7.0 SPAM policy violation' );
                    $self->dbgout( 'SpamAssassinReject', "Policy reject", LOG_INFO );
                }
            }
        }
    }

    $self->metric_count( 'spamassassin_total', $self->{ 'metrics_data' } );
    return if ( lc $config->{'remove_headers'} eq 'no' );

    foreach my $header_type ( qw{ X-Spam-score X-Spam-Status X-Spam-hits } ) {
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
    delete $self->{'rcpt_to'};
    delete $self->{'remove_headers'};
    delete $self->{'header_index'};
    delete $self->{'metrics_data'};
    return;
}

1;

__END__

=head1 NAME

  Authentication Milter - SpamAssassin Module

=head1 DESCRIPTION

Check email for spam using SpamAssassin spamd.

=head1 CONFIGURATION

        "SpamAssassin" : {
            "default_user" : "nobody",
            "sa_host" : "localhost",
            "sa_port" : "783",
            "hard_reject_at" : "10",
            "remove_headers" : "yes"
        },

=head1 SYNOPSIS

=head2 CONFIG

Add a block to the handlers section of your config as follows.

        "SpamAssassin" : {
            "default_user"   : "nobody",
            "sa_host"        : "localhost",
            "sa_port"        : "783",
            "hard_reject_at" : "10",
            "remove_headers" : "yes"
        },

=head1 AUTHORS

Marc Bradshaw E<lt>marc@marcbradshaw.netE<gt>

=head1 COPYRIGHT

Copyright 2015

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.


