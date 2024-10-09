##@file
# Base package for LemonLDAP::NG session object

##@class
# Specify a session object, how to create/update/remove session

package Lemonldap::NG::Common::Session;

use strict;
use Exporter 'import';
use Digest::SHA;
use JSON;
use Lemonldap::NG::Common::Apache::Session;
use Lemonldap::NG::Common::Apache::Session::Generate::SHA256;

our $VERSION = '2.20.0';

# Export method needed to handle hashed storage
our @EXPORT = qw(id2storage hashedKinds reHashedKinds);

use constant hashedKinds => ( 'SSO', 'OIDC', 'CDA' );

sub reHashedKinds {
    my $s = '^(' . join( '|', hashedKinds() ) . ')$';
    return qr/$s/;
}

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

# Convert a session ID into store entry
sub id2storage {
    return $_[0] ? Digest::SHA::sha256_hex( $_[0] ) : undef;
}

sub randomId {
    my $tmp = {};
    &Lemonldap::NG::Common::Apache::Session::Generate::SHA256::generate($tmp);
    return $tmp->{data}->{_session_id};
}

has id => (
    is      => 'rw',
    isa     => 'Str|Undef',
    trigger => sub {
        $_[0]->{storageId} =
          ( $_[0]->hashStore && $_[0]->id )
          ? id2storage( $_[0]->id )
          : $_[0]->id;
    }
);

has storageId => ( is => 'rw', );

has force => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has kind => (
    is  => 'rw',
    isa => 'Str|Undef',
);

has data => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has options => (
    is  => 'rw',
    isa => 'HashRef',
);

has storageModule => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has storageModuleOptions => (
    is  => 'ro',
    isa => 'HashRef|Undef',
);

has cacheModule => (
    is  => 'rw',
    isa => 'Str|Undef',
);

has cacheModuleOptions => (
    is  => 'rw',
    isa => 'HashRef|Undef',
);

has error => (
    is  => 'rw',
    isa => 'Str|Undef',
);

has info => ( is => 'rw' );

has timeout => ( is => 'rw', default => 5 );

has hashStore => ( is => 'rw' );

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
                    "Session kind mismatch: $data->{_session_kind} is not "
                      . $self->kind );
                return undef;
            }
        }
        $self->_save_data($data);
        $self->kind( $data->{_session_kind} );
        $self->id( $data->{_session_id} );
        if ( $self->hashStore and $self->id ) {
            $self->_hashDataSessionId($data);
            $data->{_session_hashed} ||= 1;
        }

        untie(%$data);
    }
}

sub _tie_session {
    my $self    = $_[0];
    my $options = $_[1] || {};
    my %h;

    # Secured storage for new session: generate a new random ID and calculate
    # the storage ID
    my $securedId = $self->id;
    if ( $self->hashStore ) {
        if ( !$self->id ) {
            my $id = $self->options->{setId} || randomId();
            $securedId = $id;
            $self->storageId( id2storage($securedId) );
            $self->options->{setId} = $options->{setId} = $self->storageId;
            $self->error(undef);
        }
    }

    eval {
        local $SIG{ALRM} = sub { die "TIMEOUT\n" };
        eval {
            alarm $self->timeout;

            # SOAP/REST session module must be directly tied
            if ( $self->storageModule =~
                /^Lemonldap::NG::Common::Apache::Session/ )
            {
                tie %h, $self->storageModule,
                  ( $options->{setId} ? $self->id : $self->storageId ),
                  { %{ $self->options }, %$options, kind => $self->kind };
            }
            else {
                tie %h, 'Lemonldap::NG::Common::Apache::Session',
                  ( $options->{setId} ? $self->id : $self->storageId ),
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
    if ( $self->hashStore ) {

        # Before returning the session, set here the real cookie value
        my $status = tied(%h)->{status};
        $h{_session_id} = $securedId;
        tied(%h)->{status} = $status;
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

    # Before saving, hide the real ID and replace it by the storage ID
    $self->_hashDataSessionId($data) if $self->hashStore;

    eval { tied(%$data)->delete(); };

    if ($@) {
        $self->error("Unable to delete session: $@");
        return 0;
    }

    return 1;
}

sub _hashDataSessionId {
    my ( $self, $data, $id ) = @_;
    my $nid = id2storage( $id || $self->id );
    if ( $nid ne $data->{_session_id} ) {
        my $status = tied(%$data)->{status};
        $data->{_session_id} = id2storage( $self->id );
        tied(%$data)->{status} = $status;
    }
}

no Mouse;

1;
