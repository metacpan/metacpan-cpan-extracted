package Lemonldap::NG::Common::CliSessions;

use strict;
use Mouse;
use JSON;
use Lemonldap::NG::Common::Conf;
use Lemonldap::NG::Common::Logger::Std;
use Lemonldap::NG::Common::Apache::Session;
use Lemonldap::NG::Common::Session;
use Lemonldap::NG::Common::Util qw/getPSessionID genId2F/;

our $VERSION = '2.0.9';

has opts => ( is => 'rw' );

has stdout => (
    is      => 'ro',
    default => *STDOUT,
);

has stderr => (
    is      => 'ro',
    default => *STDERR,
);

has conf => (
    is      => 'ro',
    default => sub {
        my $res = Lemonldap::NG::Common::Conf->new( { (
                    ref $_[0] && $_[0]->{iniFile}
                    ? ( confFile => $_[0]->{iniFile} )
                    : ()
                )
            }
        );
        die $Lemonldap::NG::Common::Conf::msg unless ($res);
        return $res->getConf();
    },
);

sub _to_json {
    my $self = shift;
    my $obj  = shift;
    return to_json( $obj, { pretty => 1, canonical => 1 } );
}

sub _search {
    my ($self) = shift;
    my $backendStorage =
      ( lc( $self->opts->{backend} || 'global' ) ) . "Storage";

    # Handle --persistent
    if ( $self->opts->{persistent} ) {
        $backendStorage = "persistentStorage";
    }

    $backendStorage = "globalStorage" unless $self->conf->{$backendStorage};

    my $args = $self->conf->{"${backendStorage}Options"};
    $args->{backend} = $self->conf->{$backendStorage};

    my @fields = @{ $self->opts->{select} || [] };
    if ( $self->opts->{idonly} ) {
        @fields = ('_session_id');
    }

    my $res;
    if ( $self->opts->{where} ) {

        # TODO fix regexp?
        if ( $self->opts->{where} =~ /^(\w+)\s*=\s*(.*)/ ) {
            my ( $selectField, $value ) = ( $1, $2 );
            $res = Lemonldap::NG::Common::Apache::Session->searchOn( $args,
                $selectField, $value, @fields );
        }
        else {
            die "Invalid --where option : " . $self->opts->{where};
        }
    }
    else {
        $res =
          Lemonldap::NG::Common::Apache::Session->get_key_from_all_sessions(
            $args, ( @fields ? [@fields] : () ) );
    }

    return $res;
}

sub search {
    my ($self) = shift;
    my $res    = $self->_search();
    my $o      = $self->stdout;
    if ( $self->opts->{idonly} ) {
        print $o map { $res->{$_}->{_session_id} . "\n" } keys %{$res};
    }
    else {
        print $o $self->_to_json( [ values %{$res} ] );
    }
    return 0;

}

# Returns the session object, so we can modify it
sub _get_one_session {
    my ( $self, $id, $backend ) = @_;

    # Lookup backend storage from CLI options
    my $backendStorage =
      ( lc( $self->opts->{backend} || 'global' ) ) . "Storage";

    # allow argument to overwrite the backend
    if ($backend) {
        $backendStorage = $backend . "Storage";
    }

    # Handle --persistent
    elsif ( $self->opts->{persistent} ) {
        $backendStorage = "persistentStorage";
        $id             = getPSessionID($id);
    }

    # In any case, fall back to global storage if we couldn't find the backend
    $backendStorage = "globalStorage" unless $self->conf->{$backendStorage};

    my $as = Lemonldap::NG::Common::Session->new( {
            storageModule        => $self->conf->{$backendStorage},
            storageModuleOptions => $self->conf->{"${backendStorage}Options"},
            id                   => $id,
        }
    );

    if ( $as->error ) {
        my $e = $self->stderr;
        print $e $as->error;
        return undef;
    }
    else {
        return $as;
    }
}

# Returns only session data
sub _get_one_data {
    my ( $self, $id ) = @_;
    my $as = $self->_get_one_session($id);
    if ($as) {
        my $new;

        # Filter
        if (    ( ref( $self->opts->{select} ) eq 'ARRAY' )
            and ( scalar @{ $self->opts->{select} } > 0 ) )
        {
            for ( @{ $self->opts->{select} } ) {
                $new->{$_} = $as->data->{$_} if defined $as->data->{$_};
            }
        }
        else {
            $new = $as->data;
        }
        return $new;
    }
    return undef;
}

sub delete {
    my ($self) = shift;
    my $result = 0;
    my @sessions;

    # Run search if a where option was provided
    if ( $self->opts->{where} ) {
        my $res = $self->_search();
        @sessions = keys %{$res};
    }
    else {
        @sessions = @_;
    }

    my @result;
    for my $id (@sessions) {
        my $as = $self->_get_one_session($id);
        if ($as) {
            unless ( $as->remove ) {
                my $e = $self->stderr;
                print $e $as->error;
                $result = 1;
            }
        }
    }
    return $result;
}

sub get {
    my $self = shift;
    my $o    = $self->stdout;

    my @result;
    for my $id (@_) {
        my $new = $self->_get_one_data($id);
        push @result, $new if $new;
    }
    print $o $self->_to_json( \@result );
    return 0;
}

sub _get_psession {
    my ( $self, $uid ) = @_;
    my $psession_id = getPSessionID($uid);
    my $res         = $self->_get_one_session( $psession_id, 'persistent' );
    die "Could not get psession for user $uid" unless $res;
    return $res;
}

sub _get_psession_data {
    my ( $self, $uid ) = @_;
    my $ps = $self->_get_psession($uid);
    return $ps->data;
}

# This method takes a special psession key (oidcConsents, 2fDevices..)
# and returns the expected JSON object
# idBuilder is a sub that gets applied to every object in the array, yielding the key of
# this object in the resulting hash
sub _get_psession_special {
    my ( $self, $target, $keyName, $idBuilder ) = @_;
    my $psession = $self->_get_psession_data($target);
    my $res      = {};
    my $special  = $psession->{$keyName} || "[]";
    $special = from_json($special);
    die "Expecting JSON array in $keyName" unless ref($special) eq "ARRAY";
    for my $item ( @{$special} ) {
        my $id = $idBuilder->($item);
        $res->{$id} = $item;
    }
    return $res;
}

# This method deletes all matching items from an array psession key (oidcConsents, 2fDevices..)
# keyBuilder is a sub that gets applied to every object in the array, yielding the value to be
# compared against
sub _del_psession_special {
    my ( $self, $target, $specialKeyName, $itemKeyBuilder, @todelete ) = @_;
    my $psession = $self->_get_psession($target);
    my $data     = $psession->data;
    my $deleted  = 0;

    my $special = $data->{$specialKeyName} || "[]";
    $special = from_json($special);

    die "Expecting JSON array in $specialKeyName"
      unless ref($special) eq "ARRAY";

    my @new;
    for my $item ( @{$special} ) {
        my $id = $itemKeyBuilder->($item);
        if ( $id and grep { $_ eq $id } @todelete ) {
            $deleted = $deleted + 1;
        }
        else {
            push @new, $item;
        }
    }
    if ($deleted) {
        $data->{$specialKeyName} = to_json( [@new] );
    }

    # TODO should this be in the if???
    $psession->update($data);
}

sub _migrateu2f_device {
    my ( $self, $device ) = @_;

    my $credential_id = $device->{_keyHandle};
    my $_userKey      = $device->{_userKey};

    eval { require Authen::WebAuthn };
    if ($@) {
        die "Missing Authen::WebAuthn dependency: $@";
    }

    my $credential_pubkey =
      Authen::WebAuthn::convert_raw_ecc_to_cose($_userKey);

    return {
        type                 => "WebAuthn",
        name                 => "$device->{name}",
        _credentialId        => "$credential_id",
        _credentialPublicKey => "$credential_pubkey",
        _signCount           => 0,
        epoch                => "$device->{epoch}",
    };
}

sub _migrateu2f {
    my $self   = shift;
    my $target = shift;

    my $psession = $self->_get_psession($target);
    my $data     = $psession->data;
    my $migrated = 0;

    my $_2fDevices = $data->{_2fDevices} || "[]";
    $_2fDevices = from_json($_2fDevices);

    die "Expecting JSON array in _2fDevices"
      unless ref($_2fDevices) eq "ARRAY";

    my @new_2fDevices = @{$_2fDevices};
    my @u2f_devices   = grep { $_->{type} eq "U2F" } @{$_2fDevices};

    my %migrated_devices;
    for my $u2f_device (@u2f_devices) {
        my $migrated_device = $self->_migrateu2f_device($u2f_device);
        $migrated_devices{ $migrated_device->{_credentialId} } =
          $migrated_device;
    }

    for my $migrated_device ( keys %migrated_devices ) {

        # If credentialId is not already present
        unless (
            grep {
                      $_->{type} eq "WebAuthn"
                  and $_->{_credentialId} eq $migrated_device
            } @new_2fDevices
          )
        {
            push @new_2fDevices, $migrated_devices{$migrated_device};
            $migrated = 1;
        }
    }

    if ($migrated) {
        $data->{_2fDevices} = to_json( [@new_2fDevices] );
        $psession->update($data);
    }

}

sub consents_get {
    my $self   = shift;
    my $target = shift;
    return 0 unless $target;

    my $o        = $self->stdout;
    my $consents = $self->_get_psession_special( $target, '_oidcConsents',
        sub { $_[0]->{rp} } );
    print $o $self->_to_json($consents);
    return 0;
}

sub secondfactors_get {
    my $self   = shift;
    my $target = shift;
    return 0 unless $target;

    my $o        = $self->stdout;
    my $consents = $self->_get_psession_special( $target, '_2fDevices',
        sub { genId2F( $_[0] ) } );
    print $o $self->_to_json($consents);
    return 0;
}

sub consents_delete {
    my $self   = shift;
    my $target = shift;
    return 0 unless $target;

    my @ids = @_;
    return 0 unless @ids;

    $self->_del_psession_special( $target, '_oidcConsents',
        sub { $_[0]->{rp} }, @ids );
    return 0;
}

sub secondfactors_delete {
    my $self   = shift;
    my $target = shift;
    return 0 unless $target;

    my @ids = @_;
    return 0 unless @ids;
    $self->_del_psession_special( $target, '_2fDevices',
        sub { genId2F( $_[0] ) }, @ids );
    return 0;
}

sub _get_psession_targets {
    my ( $self, @args ) = @_;

    if ( $self->opts->{where} or $self->opts->{all} ) {
        $self->opts->{persistent} = 1;

        if ( $self->opts->{all} ) {
            delete $self->opts->{where};
        }

        my $res = $self->_search();
        return ( map { $res->{$_}->{_session_uid} } keys %{$res} );
    }
    else {
        return @args;
    }
}

sub secondfactors_delType {
    my $self = shift;

    my $target;
    unless ( $self->opts->{where} or $self->opts->{all} ) {
        $target = shift;
    }

    my @types = @_;
    return 0 unless @types;

    my @targets = $self->_get_psession_targets($target);
    for my $target (@targets) {
        $self->_del_psession_special( $target, '_2fDevices',
            sub { $_[0]->{type} }, @types );
    }

    return 0;
}

sub secondfactors_migrateu2f {
    my ( $self, @ids ) = @_;
    my $result   = 0;
    my @sessions = $self->_get_psession_targets(@ids);

    for my $id (@sessions) {
        if ( !$self->_migrateu2f($id) ) {
            $result = 1;
        }
    }
    return $result;
}

sub setKey {
    my $self = shift;
    my $id   = shift;
    die "Unever number of arguments" unless ( @_ % 2 ) == 0;
    my %newvalues = (@_);
    die "Session ID and new values not provided" unless $id and %newvalues;

    my $as = $self->_get_one_session($id);
    die unless $as;

    my $data = $as->data;

    for ( keys %newvalues ) {
        $data->{$_} = $newvalues{$_};
    }

    $as->update($data);
    return 0;
}

sub delKey {
    my $self     = shift;
    my $id       = shift;
    my @todelete = @_;
    die "Session ID and key names not provided" unless $id and @todelete;

    my $as = $self->_get_one_session($id);
    die unless $as;

    my $data = $as->data;

    for (@todelete) {

        # Weird, I know. But that's how
        # Lemonldap::NG::Common::Session::update works
        $data->{$_} = undef;
    }

    $as->update($data);
    return 0;
}

sub run {
    my $self   = shift;
    my $action = shift;
    my $opts   = shift;

    unless ( ref $self ) {
        $self = $self->new;
    }
    unless ($action) {
        die 'nothing to do, aborting';
    }
    $self->opts($opts);

    # Simple commands
    if ( $action =~ /^(?:get|search|delete|setKey|delKey)$/ ) {
        return $self->$action(@_);
    }

    # Subcommands and target
    elsif ( $action =~ /^(?:secondfactors|consents)$/ ) {
        my $subcommand = shift;
        unless ($subcommand) {
            die "Missing subcommand $action";
        }
        my $func = "${action}_${subcommand}";
        if ( $self->can($func) ) {
            return $self->$func(@_);
        }
        else {
            die "Unknown subcommand $subcommand for action $action";
        }
    }
    else {
        die "unknown action $action. Only get or search are allowed";
    }
}

1;
