##@file
# Base package for LemonLDAP::NG session object

##@class
# Specify a session object, how to create/update/remove session

package Lemonldap::NG::Common::Session;

our $VERSION = '1.9.1';

use Mouse;
use Lemonldap::NG::Common::Apache::Session;

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

sub BUILD {
    my $self = shift;

    # Load Apache::Session module
    unless ( $self->storageModule->can('populate') ) {
        eval "require " . $self->storageModule;
        return undef if $@;
    }

    # Register options for common Apache::Session module
    my $moduleOptions = $self->storageModuleOptions || {};
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

    # If session is created
    # Then set session kind in session
    if ( $creation and $self->kind ) {
        $data->{_session_kind} = $self->kind;
    }

    # Load session data into object
    if ($data) {
        $self->_save_data($data);
        $self->kind( $data->{_session_kind} );
        $self->id( $data->{_session_id} );

        untie(%$data);
    }
}

sub _tie_session {
    my $self = shift;
    my $options = shift || {};

    my %h;

    eval {
        # SOAP session module must be directly tied
        if ( $self->storageModule =~
            /Lemonldap::NG::Common::Apache::Session::SOAP/ )
        {
            tie %h, $self->storageModule, $self->id,
              { %{ $self->options }, %$options };
        }
        else {
            tie %h, 'Lemonldap::NG::Common::Apache::Session', $self->id,
              { %{ $self->options }, %$options };
        }
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
    my $self       = shift;
    my $infos      = shift;
    my $tieOptions = shift;

    unless ( ref $infos eq "HASH" ) {
        $self->error("You need to provide a HASHREF");
        return 0;
    }

    my $data = $self->_tie_session($tieOptions);

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
    my $self       = shift;
    my $tieOptions = shift;

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
