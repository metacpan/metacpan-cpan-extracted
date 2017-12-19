package Mail::Milter::Authentication::Handler::UserDB;
use strict;
use warnings;
use DB_File;
use Mail::Milter::Authentication::Handler::UserDB::Hash;
use Sys::Syslog qw{:standard :macros};
use base 'Mail::Milter::Authentication::Handler';
use version; our $VERSION = version->declare('v1.1.5');

my $CHECKED_TIME;

sub default_config {
    return {
        'add_header' => 1,
        'lookup'     => [ 'hash:/etc/postfix/virtusertable' ],
    };
}

sub grafana_rows {
    my ( $self ) = @_;
    my @rows;
    push @rows, $self->get_json( 'UserDB_metrics' );
    return \@rows;
}

sub register_metrics {
    return {
        'userdb_total' => 'The number of emails processed for UserDB',
    };
}

sub setup_callback {
    my ( $self ) = @_;
    delete $self->{'local_user'};
    return;
}

sub envrcpt_callback {
    my ( $self, $env_to ) = @_;
    my $address = $self->get_address_from( $env_to );
    my $user = $self->get_user_from_address( $address );
    $self->{'local_user'} = $user if $user;
    return;
}

sub eoh_callback {
    my ( $self ) = @_;
    my $config = $self->handler_config();
    if ( $self->{'local_user'} ) {
        $self->metric_count( 'userdb_total', { 'result' => 'pass' } );
        if ( $config->{'add_header'} ) {
            $self->add_auth_header('x-local-user=pass');
        }
    }
    else {
        $self->metric_count( 'userdb_total', { 'result' => 'fail' } );
    }
    return;
}

sub close_callback {
    my ( $self ) = @_;
    delete $self->{'local_user'};
    return;
}

{
    my $lookers_cache;

    sub get_lookers {
        my ( $self ) = @_;

        if ( $lookers_cache ) {
            my $reloaded = 0;
            foreach my $looker ( @{$lookers_cache} ) {
                $reloaded = $reloaded + $looker->check_reload();
            }
            if ( $reloaded ) {
                $self->dbgout( 'UserDb', 'Re-loading User DB', LOG_INFO );
            }
            return $lookers_cache;
        }
    
        $self->dbgout( 'UserDb', 'Loading User DB', LOG_DEBUG );

        my @lookers;
        my $config = $self->handler_config();
        my $lookups = $config->{'lookup'};
        foreach my $lookup ( @$lookups ) {
            my ( $type, $data ) = split ':', $lookup, 2;
            if ( $type eq 'hash' ) {
                my $looker = Mail::Milter::Authentication::Handler::UserDB::Hash->new( $data );
                push @lookers, $looker;
                $looker->preload();
            }
            else {
                die "Unknown UserDB lookup type $type";
            }
        }
        $lookers_cache = \@lookers;
        return $lookers_cache;
    }

}

sub get_user_from_address {
    my ( $self, $address ) = @_;
    $self->dbgout( 'UserDb Lookup', $address, LOG_DEBUG );
    my $lookers = $self->get_lookers();
    foreach my $looker ( @{$lookers} ) {
        my $user = $looker->get_user_from_address( $address );
        $self->dbgout( 'UserDb Found', $user, LOG_DEBUG ) if $user;
        return $user if $user;
    }
    return;
}

1;

__END__

=head1 NAME

  Authentication Milter - UserDB Module

=head1 DESCRIPTION

Check if email has a local recipient account.

=head1 CONFIGURATION

        "UserDB" : {
            "add_header" : 1,
            "lookup" : [ "hash:/etc/postfix/virtusertable" ]
        },

=head1 SYNOPSIS

=head2 CONFIG

Add a block to the handlers section of your config as follows.

        "UserDB" : {
            "add_header" : 1,
            "lookup"     : [ "hash:/etc/postfix/virtusertable" ]
        },


=head1 AUTHORS

Marc Bradshaw E<lt>marc@marcbradshaw.netE<gt>

=head1 COPYRIGHT

Copyright 2017

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.


