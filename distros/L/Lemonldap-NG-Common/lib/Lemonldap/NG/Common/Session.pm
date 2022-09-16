##@file
# Base package for LemonLDAP::NG session object

##@class
# Specify a session object, how to create/update/remove session

package Lemonldap::NG::Common::Session;

use strict;
use Lemonldap::NG::Common::Apache::Session;

our $VERSION = '2.0.15';

# Workaround for another ModPerl/Mouse issue...
BEGIN {
    require Mouse;
    no warnings;
    my $v =
      $Mouse::VERSION
      ? sprintf( "%d.%03d%03d", ( $Mouse::VERSION =~ /(\d+)/g ) )
      : 0;
    if ( $v < 2.005001 and $Lemonldap::NG::Handler::Apache2::Main::VERSION ) {
        require Moose;
        Moose->import();
    }
    else {
        Mouse->import();
    }
}

has 'id' => (
    is  => 'rw',
    isa => 'Str|Undef',
);

has 'force' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'kind' => (
    is  => 'rw',
    isa => 'Str|Undef',
);

has 'data' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'options' => (
    is  => 'rw',
    isa => 'HashRef',
);

has 'storageModule' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'storageModuleOptions' => (
    is  => 'ro',
    isa => 'HashRef|Undef',
);

has 'cacheModule' => (
    is  => 'rw',
    isa => 'Str|Undef',
);

has 'cacheModuleOptions' => (
    is  => 'rw',
    isa => 'HashRef|Undef',
);

has 'error' => (
    is  => 'rw',
    isa => 'Str|Undef',
);

has info => ( is => 'rw' );

has timeout => ( is => 'rw', default => 5 );

sub BUILD {
    my ($self) = @_;

    # Load Apache::Session module
    unless ( $self->storageModule->can('populate') ) {
        eval "require " . $self->storageModule;
        return undef if $@;
    }

    # Register options for common Apache::Session module
    my $moduleOptions = $self->storageModuleOptions || {};
    $self->timeout( delete $moduleOptions->{timeout} )
      if $moduleOptions->{timeout};
    my %options = (
        %$moduleOptions,
        backend             => $self->storageModule,
        localStorage        => $self->cacheModule,
        localStorageOptions => $self->cacheModuleOptions
    );

    $self->options( \%options );

    my $data = $self->_tie_session;

    # Is it a session creation request?
    my $creation = 1
      if ( !$self->id or ( $self->id and !$data and $self->force ) );

    # If session id was submitted but session is not found
    # And we want to force id
    # Then use setId to create session
    if ( $self->id and $creation ) {
        $options{setId} = $self->id;
        $self->options( \%options );
        $self->id(undef);
        $self->error(undef);
        $data = $self->_tie_session;
    }

    if ( $self->{info} ) {
        foreach ( keys %{ $self->{info} } ) {
            next if ( $_ eq "_session_id"   and $data->{_session_id} );
            next if ( $_ eq "_session_kind" and $data->{_session_kind} );
            if ( defined $self->{info}->{$_} ) {
                $data->{$_} = $self->{info}->{$_};
            }
            else {
                delete $data->{$_};
            }
        }
        delete $self->{info};
    }

    # If session is created
    # Then set session kind in session
    if ( $creation and $self->kind ) {
        $data->{_session_kind} = $self->kind;
    }

    # Load session data into object
    if ($data) {
        if ( $self->kind and $data->{_session_kind} ) {
            unless ( $data->{_session_kind} eq $self->kind ) {
                $self->error(
                    "Session kind mismatch : $data->{_session_kind} is not "
                      . $self->kind );
                return undef;
            }
        }
        $self->_save_data($data);
        $self->kind( $data->{_session_kind} );
        $self->id( $data->{_session_id} );

        untie(%$data);
    }
}

sub _tie_session {
    my $self    = $_[0];
    my $options = $_[1] || {};
    my %h;

    eval {
        local $SIG{ALRM} = sub { die "TIMEOUT\n" };
        eval {
            alarm $self->timeout;

            # SOAP/REST session module must be directly tied
            if ( $self->storageModule =~
                /^Lemonldap::NG::Common::Apache::Session/ )
            {
                tie %h, $self->storageModule, $self->id,
                  { %{ $self->options }, %$options, kind => $self->kind };
            }
            else {
                tie %h, 'Lemonldap::NG::Common::Apache::Session', $self->id,
                  { %{ $self->options }, %$options };
            }
        };
        alarm 0;
        die $@ if $@;

    };
    if ( $@ or not tied(%h) ) {
        my $msg = "Session cannot be tied";
        $msg .= ": $@" if $@;
        $self->error($msg);
        return undef;
    }

    return \%h;
}

sub _save_data {
    my ( $self, $data ) = @_;

    my %saved_data = %$data;
    $self->data( \%saved_data );
}

sub update {
    my ( $self, $infos, $tieOptions ) = @_;

    unless ( ref $infos eq "HASH" ) {
        $self->error("You need to provide a HASHREF");
        return 0;
    }

    my $data = $self->_tie_session(
        { ( $tieOptions ? %$tieOptions : () ), noCache => 1 } );

    if ($data) {
        foreach ( keys %$infos ) {
            if ( defined $infos->{$_} ) {
                $data->{$_} = $infos->{$_};
            }
            else {
                delete $data->{$_};
            }
        }

        $self->_save_data($data);

        untie(%$data);
        return 1;
    }

    $self->error("No data found in session");
    return 0;
}

sub remove {
    my ( $self, $tieOptions ) = @_;

    my $data = $self->_tie_session($tieOptions);

    eval { tied(%$data)->delete(); };

    if ($@) {
        $self->error("Unable to delete session: $@");
        return 0;
    }

    return 1;
}

no Mouse;

1;
