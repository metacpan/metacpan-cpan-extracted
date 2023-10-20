package Lab::Instrument;
$Lab::Instrument::VERSION = '3.899';
#ABSTRACT: Instrument base class

use v5.20;

use strict;
use warnings;

#use POSIX; # added for int() function
use Lab::Generic;
use Lab::Exception;
use Lab::Connection;
use Carp qw(cluck croak);
use Data::Dumper;
use Clone qw(clone);
use Class::ISA qw(self_and_super_path);
use Hook::LexWrap;

use Time::HiRes qw (usleep sleep);

our @ISA = ('Lab::Generic');

our $AUTOLOAD;

our %fields = (

    device_name    => undef,
    device_comment => undef,

    ins_debug => 0,    # do we need additional output?

    connection            => undef,
    supported_connections => ['ALL'],

    # for connection default settings/user supplied settings. see accessor method.
    connection_settings => { timeout => 1 },

    # default device settings/user supplied settings. see accessor method.
    device_settings => {
        name              => undef,
        wait_status       => 10e-6,    # sec
        wait_query        => 10e-6,    # sec
        query_length      => 300,      # bytes
        query_long_length => 10240,    # bytes
    },

    device_cache => {

    },

    device_cache_order => [],

    config => {},
);

sub new {
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $config = undef;
    if   ( ref $_[0] eq 'HASH' ) { $config = shift }
    else                         { $config = {@_} }

    my $self = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    # wrap additional code for automatic cache-handling aroung all paramter set- and get-functions defined in %fields->{device_cache}
    my @isa  = Class::ISA::self_and_super_path($class);
    my $flag = 0;
    while (@isa) {
        my $isa = pop @isa;
        if ( $flag == 1 ) {
            $self->_init_cache_handling($isa);
        }
        if ( $isa eq 'Lab::Instrument' ) {
            $flag = 1;
        }

    }

    $self->config($config);

    #
    # In most inherited classes, configure() is run through _construct()
    #
    $self->${ \( __PACKAGE__ . '::configure' ) }( $self->config() )
        ;    # use local configure, not possibly overwritten one

    if ( $class eq __PACKAGE__ ) {

        # _setconnection after providing $config - needed for direct instantiation of Lab::Instrument
        $self->_setconnection();
    }

    # digest parameters
    $self->device_name( $self->config('device_name') )
        if defined $self->config('device_name');
    $self->device_comment( $self->config('device_comment') )
        if defined $self->config('device_comment');

    $self->register_instrument();

    return $self;
}

#
# Call this in inheriting class's constructors to conveniently initialize the %fields object data.
#
sub _construct {    # _construct(__PACKAGE__);
    ( my $self, my $package ) = ( shift, shift );

    my $class  = ref($self);
    my $fields = undef;
    {
        no strict 'refs';
        $fields = *${ \( $package . '::fields' ) }{HASH};
    }

    foreach my $element ( keys %{$fields} ) {

        # handle special subarrays
        if ( $element eq 'device_settings' ) {

            # don't overwrite filled hash from ancestor
            $self->{device_settings} = {}
                if !exists( $self->{device_settings} );
            for my $s_key ( keys %{ $fields->{'device_settings'} } ) {
                $self->{device_settings}->{$s_key}
                    = clone( $fields->{device_settings}->{$s_key} );
            }
        }
        elsif ( $element eq 'connection_settings' ) {

            # don't overwrite filled hash from ancestor
            $self->{connection_settings} = {}
                if !exists( $self->{connection_settings} );
            for my $s_key ( keys %{ $fields->{connection_settings} } ) {
                $self->{connection_settings}->{$s_key}
                    = clone( $fields->{connection_settings}->{$s_key} );
            }
        }
        else {
            # handle the normal fields - can also be hash refs etc, so use clone to get a deep copy
            $self->{$element} = clone( $fields->{$element} );

            #warn "here comes\n" if($element eq 'device_cache');
            #warn Dumper($Lab::Instrument::DummySource::fields) if($element eq 'device_cache');
        }
        $self->{_permitted}->{$element} = 1;

    }

    # @{$self}{keys %{$fields}} = values %{$fields};

    #
    # run configure() of the calling package on the supplied config hash.
    # this parses the whole config hash on every heritance level (and with every version of configure())
    # For Lab::Instrument itself it does not make sense, as $self->config() is not set yet. Instead it's run from the new() method, see there.
    #
    $self->${ \( $package . '::configure' ) }( $self->config() )
        if $class ne 'Lab::Instrument'
        ;   # use configure() of calling package, not possibly overwritten one

    #
    # Check and parse the connection data OR the connection object in $self->config(), but only if
    # _construct() has been called from the instantiated class (and not from somewhere up the heritance hierarchy)
    # That's because child classes can add new entrys to $self->supported_connections(), so delay checking to the top class.
    # Also, don't run _setconnection() for Lab::Instrument, as in this case the needed fields in $self->config() are not set yet.
    # It's run in Lab::Instrument::new() instead if needed.
    #
    # Also, other stuff that should only happen in the top level class instantiation can go here.
    #

    if ( $class eq $package && $class ne 'Lab::Instrument' ) {

        $self->_setconnection();

        # Match the device hash with the device
        # The cache carries the default values set above and was possibly modified with user
        # defined values through configure() before the connection was set. These settings are now transferred
        # to the device.
        $self->_device_init();    # enable device communication if necessary
        $self->_set_config_parameters();    # transfer configuration to device

    }

}

# this methode implements the cache-handling:
#
# It will wrap all get- and set-functions for parameters initialized in $fields->{device_cache} with additional pre- and post-processing code.
# If a get-function is called and read_mode == cache, the $self->{device_cache}->{parameter} will be returned immediately. The original get-function won't be executed in this case.
# This behaviour can be disabled by setting the parmeter $self->{config}->{no_cache} = 1.
# The return-value of the get-function will be cached in $self->{device_cache}in any case.
#
# Set-functions will automatically call the corresponding get-function in the post-processing section, in order to keep the cache up to date.
#
# If a requestID has been set, only the get-function, which placed the request will be executed, while all others return the cache-value. Set-functions won't be executed at all.
#

sub _init_cache_handling {
    my $self  = shift;
    my $class = shift;

    no strict 'refs';

    # avoid to redefine the subs twice
    if ( defined ${ $class . '::MODIFIED' } ) {
        return;
    }

    my $fields       = *${ \( $class . '::fields' ) }{HASH};
    my @cache_params = keys %{ $fields->{device_cache} };

    # wrap parameter function defined in %fields->{device_cache}:
    foreach my $cache_param (@cache_params) {
        my $set_sub = "set_" . $cache_param;
        my $get_sub = "get_" . $cache_param;

        my $get_methode = *{ $class . "::" . $get_sub };
        my $set_methode = *{ $class . "::" . $set_sub };

        if ( $class->can( "set_" . $cache_param ) and exists &$set_methode ) {

            # Change STDERR to undef, in order to avoid warnings from Hook::LexWrap and
            # and save original STDERR stream in SAVEERR to be able to restore original
            # behavior
            local (*SAVEERR);

            #open SAVEERR, ">&STDERR";
            #open(STDERR, '>', undef);

            # wrap set-function:
            wrap(
                $class . "::" . $set_sub,

                # before set-functions is executed:
                pre => sub {
                    my $self = shift;

                    ${__PACKAGE__::SELF} = $self;
                    ${__PACKAGE__::SELF}->{fast_cache_value} = $_[0];

                    # read_mode handling: do not execute if request is set:
                    if ( defined $self->{requestID}
                        or $self->connection()->is_blocked() ) {
                        $_[-1] = 'connection blocked';
                    }
                },

                # after set-functions is executed:
                post => sub {

                    if ( not defined ${__PACKAGE__::SELF} ) {
                        return;
                    }

                    # skip get_sub if $self->{config}->{fast_cache} is set.
                    if ( defined ${__PACKAGE__::SELF}->{config}->{fast_cache}
                        and ${__PACKAGE__::SELF}->{config}->{fast_cache} > 0 )
                    {
                        ${__PACKAGE__::SELF}->device_cache(
                            {
                                $cache_param =>
                                    ${__PACKAGE__::SELF}->{fast_cache_value}
                            }
                        );
                        return;
                    }

                    # call coresponding get-function in order to keep the cache up to date, if available

                    if ( ${__PACKAGE__::SELF}->can($get_sub)
                        and not ${__PACKAGE__::SELF}->{config}->{no_cache} ) {
                        my $var = ${__PACKAGE__::SELF}->$get_sub();
                    }

                }
            );

            # Restore Warnings:
            #open STDERR, ">&SAVEERR";

        }

        if ( $class->can( "get_" . $cache_param ) and exists &$get_methode ) {

            # Change STDERR to undef, in order to avoid warnings from Hook::LexWrap and
            # and save original STDERR stream in SAVEERR to be able to restore original
            # behavior
            local (*SAVEERR);

            #open SAVEERR, ">&STDERR";
            #open(STDERR, '>', undef);

            my $parameter = $cache_param;

            # wrap get-function:
            wrap(
                $class . "::" . $get_sub,

                # before get-functions is executed:
                pre => sub {
                    my $self = shift;

                    ${__PACKAGE__::SELF} = $self;

                    # read_mode handling:
                    my @args = @_;
                    pop @args;
                    my ( $read_mode, $tail )
                        = $self->_check_args( \@args, ['read_mode'] );

                    # do not read if request has been set. set read_mode to cache if cache is available
                    $read_mode = $self->{config}->{default_read_mode}
                        if !defined($read_mode)
                        and exists( $self->{config}->{default_read_mode} );

                    if ( $self->connection()->is_blocked() == 1 ) {
                        if ( defined $self->device_cache($parameter) ) {
                            $read_mode = 'cache';
                        }
                        else {
                            $_[-1] = 'connection_blocked';
                        }
                    }

                    if ( defined $self->{requestID} ) {
                        my ( $package, $filename, $subroutine, $line )
                            = split( / /, $self->{requestID} );

                        if ( $subroutine ne $class . "::" . $get_sub ) {
                            if ( defined $self->device_cache($parameter) ) {

                                $read_mode = 'cache';
                            }
                            else {
                                $_[-1] = 'connection_blocked';
                            }
                        }
                        else {
                            $read_mode = undef;
                            pop @_;
                        }

                    }

                    # return cache value if read_mode is set to cache
                    if (    defined $read_mode
                        and $read_mode eq 'cache'
                        and defined $self->device_cache($parameter)
                        and not $self->{config}->{no_cache} ) {
                        $_[-1] = $self->device_cache($parameter);
                    }

                },

                # after get-functions is executed:
                post => sub {

                    if ( not defined ${__PACKAGE__::SELF} ) {
                        return;
                    }
                    my $retval = $_[-1];

                    # refresh cache value
                    if ( not defined $retval
                        or ref($retval) eq 'Hook::LexWrap::Cleanup' ) {
                        return;
                    }
                    else {
                        my $cache_value = wantarray ? $retval->[0] : $retval;
                        ${__PACKAGE__::SELF}
                            ->device_cache( { $parameter => $cache_value } );
                    }
                }
            );

            # Restore Warnings:
            #open STDERR, ">&SAVEERR";
        }

    }

    # remeber that we have allready redefined the functions
    ${ $class . '::MODIFIED' } = 1;

    use strict 'refs';

}

sub register_instrument {
    my $self = shift;

    push( @{Lab::Instrument::REGISTERED_INSTRUMENTS}, $self );

}

sub unregister_instrument {
    my $self = shift;

    @{Lab::Instrument::REGISTERED_INSTRUMENTS}
        = grep { $_ ne $self } @{Lab::Instrument::REGISTERED_INSTRUMENTS};

}

sub sprint_config {
    my $self = shift;

    $Data::Dumper::Varname = "device_cache_";
    my $config = Dumper $self->device_cache();

    $config .= "\n";

    $Data::Dumper::Maxdepth = 1;
    $Data::Dumper::Varname  = "connection_settings_";
    if ( defined $self->connection() ) {
        $config .= Dumper $self->connection()->config();
    }
    return $config;

}

sub _set_config_parameters {
    my $self = shift;

    my @order = @{ $self->device_cache_order() };
    my @keys  = keys %{ $self->config() };

    foreach my $ckey (@order) {
        my $subname = 'set_' . $ckey;
        if ( defined $self->config($ckey) and $self->can($subname) ) {
            my $result = $self->$subname( $self->config($ckey) );
            @keys = grep { $_ ne $ckey } @keys;
        }
    }

    foreach my $ckey (@keys) {
        my $subname = 'set_' . $ckey;
        if ( $self->can($subname) ) {
            my $result = $self->$subname( $self->config($ckey) );
        }
    }

}

# old; replaced by _refresh_cache and _set_config_parameters
sub _getset_key {
    my $self = shift;
    my $ckey = shift;

    #print Dumper $self->device_cache();

    Lab::Exception::CorruptParameter->throw(
        "No field with name $ckey in device_cache!\n")
        if !exists $self->device_cache()->{$ckey};
    if (    !defined $self->device_cache()->{$ckey}
        and !defined $self->config()->{$ckey} ) {
        my $subname = 'get_' . $ckey;
        Lab::Exception::CorruptParameter->throw(
            "No get method defined for device_cache field $ckey! \n")
            if !$self->can($subname);
        my $result = $self->$subname();
    }
    else {
        my $subname = 'set_' . $ckey;
        print Dumper $self->device_cache() if !$self->can($subname);
        Lab::Exception::CorruptParameter->throw(
            "No set method defined for device_cache field $ckey!\n")
            if !$self->can($subname);
        my $result = $self->$subname( $self->device_cache()->{$ckey} );
    }

}

#
# Sync the field set in $self->device_cache with the device.
# Undefined fields are filled in from the device, existing values in device_cache are written to the device.
# Without parameter, parses the whole $self->device_cache. Else, the parameter list is parsed as a list of
# field names. Contained fields for which have no corresponding getter/setter/device_cache entry exists will result in an exception thrown.
#
# old; replaced by _refresh_cache and _set_config_parameters
# still used in Yokogawa7651 and SignalRecovery726x
sub _cache_init {
    my $self    = shift;
    my $subname = shift;
    my @ckeys   = scalar(@_) > 0 ? @_ : keys %{ $self->device_cache() };

    #print Dumper $self->config();

    print "ckeys: @ckeys\n";

    # a key hash, to search for given keys quickly
    my %ckeyhash;
    my %orderhash;
    @ckeyhash{@ckeys} = ();

    my @order = @{ $self->device_cache_order() };

    if ( $self->device_cache() && $self->connection() ) {

        # do we have a preferred order for device cache settings?
        if (@order) {
            @orderhash{@order} = ();
            foreach my $ckey (@order) {
                $self->_getset_key($ckey) if exists $ckeyhash{$ckey};
            }

            # initialize all values not in device_cache_order
            #for my $ckey (@ckeys){
            #	$self->_getset_key($ckey) if not exists $orderhash{$ckey};
            #}
        }

        # no ordering requestd
        else {
            foreach my $ckey (@ckeys) {
                $self->_getset_key($ckey);
            }
        }
    }
}

#
# Fill $self->device_settings() from config parameters
#
sub configure {
    my $self   = shift;
    my $config = shift;

    if ( ref($config) ne 'HASH' ) {
        Lab::Exception::CorruptParameter->throw(
            error => 'Given Configuration is not a hash.' );
    }
    else {
        #
        # fill matching fields defined in %fields from the configuration hash ($self->config )
        # this will also catch an explicitly given device_settings, default_device_settings (see Source.pm) or connection_settings hash ( overwritten default config )
        #
        for my $fields_key ( keys %{ $self->{_permitted} } ) {
            {    # restrict scope of "no strict"
                no strict 'refs';
                $self->$fields_key( $config->{$fields_key} )
                    if exists $config->{$fields_key};
            }
        }

        #
        # fill fields $self->device_settings and $self->device_cache from entries given in configuration hash (this is usually the same as $self->config )
        #
        $self->device_settings($config);

        #$self->device_cache($config);
    }
}

sub _checkconnection
{ # Connection object or connection_type string (as in Lab::Connections::<connection_type>)
    my $self       = shift;
    my $connection = shift || undef;
    my $found      = 0;

    $connection = ref($connection) || $connection;

    return 0 if !defined $connection;

    no strict 'refs';
    if ( grep( /^ALL$/, @{ $self->supported_connections() } ) == 1 ) {
        return $connection;
    }
    elsif ($connection->isa('Lab::Connection::DEBUG')
        or $connection->isa('Lab::Connection::Mock') ) {
        return $connection;
    }
    else {
        for my $conn_supp ( @{ $self->supported_connections() } ) {
            return $conn_supp
                if ( $connection->isa( 'Lab::Connection::' . $conn_supp ) );
        }
    }

    return undef;
}

sub _setconnection
{    # $self->setconnection() create new or use existing connection
    my $self = shift;

    #
    # fill in unset connection parameters with the defaults from $self->connections_settings to $self->config
    #
    my $config          = $self->config();
    my $connection_type = undef;
    my $full_connection = undef;

    for my $setting_key ( keys %{ $self->connection_settings() } ) {
        $config->{$setting_key} = $self->connection_settings($setting_key)
            if !defined $config->{$setting_key};
    }

    # check the configuration hash for a valid connection object or connection type, and set the connection
    if ( defined( $self->config('connection') ) ) {

        if ( $self->_checkconnection( $self->config('connection') ) ) {
            $self->connection( $self->config('connection') );

        }
        else {
            Lab::Exception::CorruptParameter->throw(
                error => "Received invalid connection object!\n" );
        }
    }

    #	else {
    #		Lab::Exception::CorruptParameter->throw( error => 'Received no connection object!\n' );
    #	}
    elsif ( defined $self->config('connection_type') ) {

        $connection_type = $self->config('connection_type');

        if ( $connection_type !~ /^[A-Za-z0-9_\-\:]*$/ ) {
            Lab::Exception::CorruptParameter->throw( error =>
                    "Given connection type is does not look like a valid module name.\n"
            );
        }

        if ( $connection_type eq 'none' ) {
            if ( grep( /^none$/, @{ $self->supported_connections() } ) == 1 )
            {
                return;
            }
            else {
                Lab::Exception::Error->throw( error =>
                        "Sorry, this instrument cannot work without a connection.\n"
                );
            }
        }

        $full_connection = "Lab::Connection::" . $connection_type;
        eval("require ${full_connection};");
        if ($@) {
            Lab::Exception::Error->throw( error =>
                    "Sorry, I was not able to load the connection ${full_connection}.\n"
                    . "The error received from the connections was\n===\n$@\n===\n"
            );
        }

        if ( $self->_checkconnection( "Lab::Connection::" . $connection_type )
            ) {

            # let's get creative
            no strict 'refs';

            # yep - pass all the parameters on to the connection, it will take the ones it needs.
            # This way connection setup can be handled generically. Conflicting parameter names? Let's try it.
            $self->connection( $full_connection->new($config) )
                || Lab::Exception::Error->throw(
                error => "Failed to create connection $full_connection!\n" );

            use strict;
        }
        else {
            Lab::Exception::CorruptParameter->throw(
                error => "Given Connection not supported!\n" );
        }
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "Neither a connection nor a connection type was supplied.\n"
        );
    }

    # add predefined connection settings to connection config:
    # no overwriting of user defined connection settings
    my $new_config = $self->connection()->config();
    for my $key ( keys %{ $self->connection_settings() } ) {
        if ( not defined $self->connection()->config($key) ) {
            $new_config->{$key} = $self->connection_settings($key);
        }
    }
    $self->connection()->config($new_config);
    $self->connection()->_configurebus();
}

sub _checkconfig {
    my $self   = shift;
    my $config = $self->config();

    return 1;
}

#
# To be overwritten...
# Returned $errcode has to be 0 for "no error"
#
sub get_error {
    my $self = shift;

    # overwrite with device specific error retrieval...
    warn(     "There was an error on the device "
            . ref($self)
            . ", but the driver is not able to supply more details.\n" );

    return ( -1, undef );    # ( $errcode, $message )
}

#
# Optionally implement this to return a hash with device specific named status bits for this device, e.g. from the status byte/serial poll for GPIB
# return { ERROR => 1, READY => 1, DATA => 0, ... }
#
sub get_status {
    my $self = shift;
    Lab::Exception::Unimplemented->throw(
        "get_status() not implemented for " . ref($self) . ".\n" );
    return undef;
}

sub check_errors {
    my $self    = shift;
    my $command = shift;
    my @errors  = ();

    if ( $self->get_status()->{'ERROR'} ) {
        my ( $code, $message ) = $self->get_error();
        while ( $code != 0 && $code != -1 ) {
            push @errors, [ $code, $message ];
            warn
                "\nReceived device error with code $code\nMessage: $message\n";
            ( $code, $message ) = $self->get_error();
        }

        if ( @errors || $code == -1 ) {
            Lab::Exception::DeviceError->throw(
                error =>
                    "An Error occured in the device while executing the command: $command \n",
                device_class => ref $self,
                command      => $command,
                error_list   => \@errors,
            );
        }
    }
    return 0;
}

#
# Generic utility methods for string based connections (most common, SCPI etc.).
# For connections not based on command strings these should probably be overwritten/disabled!
#

#
# passing through generic write, read and query from the connection.
#

sub set_name {
    my $self = shift;
    my ($name) = $self->_check_args( \@_, ['name'] );
    $self->device_settings( { 'name' => $name } );

}

sub get_name {
    my $self = shift;
    return $self->device_settings('name');
}

sub get_id {
    my $self = shift;
    my @name = split( /::/, ref($self) );
    return pop(@name);
}

sub set_id {

}

sub write {
    my $self = shift;
    my $command
        = scalar(@_) % 2 == 0 && ref $_[1] ne 'HASH'
        ? undef
        : shift
        ; # even sized parameter list and second parm no hashref? => Assume parameter hash
    my $args
        = scalar(@_) % 2 == 0
        ? {@_}
        : ( ref( $_[0] ) eq 'HASH' ? $_[0] : undef );
    Lab::Exception::CorruptParameter->throw("Illegal parameter hash given!\n")
        if !defined($args);

    $args->{'command'} = $command if defined $command;

    my $result = $self->connection()->Write($args);

    $self->check_errors( $args->{'command'} ) if $args->{error_check};

    return $result;
}

sub read {
    my $self = shift;
    my $args
        = scalar(@_) % 2 == 0
        ? {@_}
        : ( ref( $_[0] ) eq 'HASH' ? $_[0] : undef );
    Lab::Exception::CorruptParameter->throw("Illegal parameter hash given!\n")
        if !defined($args);

    my $result = $self->connection()->Read($args);
    $self->check_errors('Just a plain and simple read.')
        if $args->{error_check};

    $result =~ s/^[\r\t\n]+|[\r\t\n]+$//g;
    return $result;
}

sub clear {
    my $self = shift;
    $self->connection()->Clear();
}

sub request {
    my $self = shift;
    my ( $command, $args ) = $self->parse_optional(@_);
    my $read_mode
        = ( defined $args->{'read_mode'} ) ? $args->{'read_mode'} : 'device';

    # generate requestID from caller:
    my ( $package, $filename, $line, $subroutine );
    ( $package, $filename, $line, $subroutine ) = caller(1);
    ( $package, $filename, $line ) = caller(0);
    my $requestID
        = $package . " " . $filename . " " . $subroutine . " " . $line;

    # # avoid to return an undef value:
    if ( $read_mode eq 'request' and not defined $self->{requestID} ) {
        $self->write(@_);
        $self->connection()->block_connection();
        $self->{requestID} = $requestID;
        return undef;
    }
    elsif ( defined $self->{requestID} and $self->{requestID} eq $requestID )
    {
        $self->connection()->unblock_connection();
        $self->{requestID} = undef;
        return $self->read(@_);
    }
    else {
        return $self->query(@_);
    }

}

sub query {
    my $self = shift;
    my ( $command, $args ) = $self->parse_optional(@_);
    my $read_mode
        = ( defined $args->{'read_mode'} ) ? $args->{'read_mode'} : 'device';
    $args->{'command'} = $command if defined $command;

    if ( not defined $args->{'command'} ) {
        Lab::Exception::CorruptParameter->throw("No 'command' given!\n");
    }

    my $result = $self->connection()->Query($args);
    $self->check_errors( $args->{'command'} ) if $args->{error_check};

    $result =~ s/^[\r\t\n]+|[\r\t\n]+$//g;
    return $result;

}

#
# infrastructure stuff below
#

#
# tool function to safely handle an optional scalar parameter in presence with a parameter hash/list
# only one optional scalar parameter can be handled, and its value must not be a hashref!
#
sub parse_optional {
    my $self = shift;

    my $optional
        = scalar(@_) % 2 == 0 && ref $_[1] ne 'HASH'
        ? undef
        : shift
        ; # even sized parameter list and second parm no hashref? => Assume parameter hash
    my $args
        = scalar(@_) % 2 == 0
        ? {@_}
        : ( ref( $_[0] ) eq 'HASH' ? $_[0] : undef );
    Lab::Exception::CorruptParameter->throw("Illegal parameter hash given!\n")
        if !defined($args);

    return $optional, $args;
}

#
# accessor for device_settings
#
sub device_settings {
    my $self  = shift;
    my $value = undef;

    #warn "device_settings got this:\n" . Dumper(@_) . "\n";

    if ( scalar(@_) == 0 )
    {    # empty parameters - return whole device_settings hash
        return $self->{'device_settings'};
    }
    elsif ( scalar(@_) == 1 )
    {    # one parm - either a scalar (key) or a hashref (try to merge)
        $value = shift;
    }
    elsif ( scalar(@_) > 1 && scalar(@_) % 2 == 0 )
    {    # even sized list - assume it's keys and values and try to merge it
        $value = {@_};
    }
    else {    # uneven sized list - don't know what to do with that one
        Lab::Exception::CorruptParameter->throw(
                  error => "Corrupt parameters given to "
                . __PACKAGE__
                . "::device_settings().\n" );
    }

    #warn "Keys present: \n" . Dumper($self->{device_settings}) . "\n";

    if ( ref($value) =~ /HASH/ ) { # it's a hash - merge into current settings
        for my $ext_key ( keys %{$value} ) {
            $self->{'device_settings'}->{$ext_key} = $value->{$ext_key}
                if ( exists( $self->device_settings()->{$ext_key} ) );
        }
        return $self->{'device_settings'};
    }
    else {    # it's a key - return the corresponding value
        return $self->{'device_settings'}->{$value};
    }
}

#
# Accessor for device_cache settings
#

sub device_cache {
    my $self  = shift;
    my $value = undef;

    #warn "device_cache got this:\n" . Dumper(@_) . "\n";

    if ( scalar(@_) == 0 )
    {    # empty parameters - return whole device_settings hash
        return $self->{'device_cache'};
    }
    elsif ( scalar(@_) == 1 )
    {    # one parm - either a scalar (key) or a hashref (try to merge)
        $value = shift;
    }
    elsif ( scalar(@_) > 1 && scalar(@_) % 2 == 0 )
    {    # even sized list - assume it's keys and values and try to merge it
        $value = {@_};
    }
    else {    # uneven sized list - don't know what to do with that one
        Lab::Exception::CorruptParameter->throw(
                  error => "Corrupt parameters given to "
                . __PACKAGE__
                . "::device_cache().\n" );
    }

    #warn "Keys present: \n" . Dumper($self->{device_settings}) . "\n";

    if ( ref($value) =~ /HASH/ ) { # it's a hash - merge into current settings
        for my $ext_key ( keys %{$value} ) {
            $self->{'device_cache'}->{$ext_key} = $value->{$ext_key}
                if ( exists( $self->device_cache()->{$ext_key} ) );
        }
        return $self->{'device_cache'};
    }
    else {    # it's a key - return the corresponding value
        return $self->{'device_cache'}->{$value};
    }
}

sub reset_device_cache {
    my $self         = shift;
    my @cache_params = keys %{ $self->{'device_cache'} };
    for my $param (@cache_params) {
        $self->device_cache( $param => undef );
    }
}

#
# accessor for connection_settings
#
sub connection_settings {
    my $self  = shift;
    my $value = undef;

    if ( scalar(@_) == 0 )
    {    # empty parameters - return whole device_settings hash
        return $self->{'connection_settings'};
    }
    elsif ( scalar(@_) == 1 )
    {    # one parm - either a scalar (key) or a hashref (try to merge)
        $value = shift;
    }
    elsif ( scalar(@_) > 1 && scalar(@_) % 2 == 0 )
    {    # even sized list - assume it's keys and values and try to merge it
        $value = {@_};
    }
    else {    # uneven sized list - don't know what to do with that one
        Lab::Exception::CorruptParameter->throw(
                  error => "Corrupt parameters given to "
                . __PACKAGE__
                . "::connection_settings().\n" );
    }

    if ( ref($value) =~ /HASH/ ) { # it's a hash - merge into current settings
        for my $ext_key ( keys %{$value} ) {
            $self->{'connection_settings'}->{$ext_key} = $value->{$ext_key}
                if ( exists( $self->{'connection_settings'}->{$ext_key} ) );

            # warn "merge: set $ext_key to " . $value->{$ext_key} . "\n";
        }
        return $self->{'connection_settings'};
    }
    else {    # it's a key - return the corresponding value
        return $self->{'connection_settings'}->{$value};
    }
}

sub _check_args {
    my $self   = shift;
    my $args   = shift;
    my $params = shift;

    my $arguments = {};

    my $i = 0;
    foreach my $arg ( @{$args} ) {
        if ( ref($arg) ne "HASH" ) {
            if ( defined @{$params}[$i] ) {
                $arguments->{ @{$params}[$i] } = $arg;
            }
            $i++;
        }
        else {
            %{$arguments} = ( %{$arguments}, %{$arg} );
            $i++;
        }
    }

    my @return_args = ();

    foreach my $param ( @{$params} ) {
        if ( exists $arguments->{$param} ) {
            push( @return_args, $arguments->{$param} );
            delete $arguments->{$param};
        }
        else {
            push( @return_args, undef );
        }
    }

    foreach my $param ( 'from_device', 'from_cache'
        ) # Delete Standard option parameters from $arguments hash if not defined in device driver function
    {
        if ( exists $arguments->{$param} ) {
            delete $arguments->{$param};
        }
    }

    push( @return_args, $arguments );

    if (wantarray) {
        return @return_args;
    }
    else {
        return $return_args[0];
    }

}

sub _check_args_strict {
    my $self   = shift;
    my $args   = shift;
    my $params = shift;

    my @result = $self->_check_args( $args, $params );

    my $num_params = @result - 1;

    for ( my $i = 0; $i < $num_params; ++$i ) {
        if ( not defined $result[$i] ) {
            croak("missing mandatory argument '$params->[$i]'");
        }
    }

    if (wantarray) {
        return @result;
    }
    else {
        return $result[0];
    }
}

#
# config gets it's own accessor - convenient access like $self->config('GPIB_Paddress') instead of $self->config()->{'GPIB_Paddress'}
# with a hashref as argument, set $self->{'config'} to the given hashref.
# without an argument it returns a reference to $self->config (just like AUTOLOAD would)
#
sub config {    # $value = self->config($key);
    ( my $self, my $key ) = ( shift, shift );

    if ( !defined $key ) {
        return $self->{'config'};
    }
    elsif ( ref($key) =~ /HASH/ ) {
        return $self->{'config'} = $key;
    }
    else {
        return $self->{'config'}->{$key};
    }
}

# sub device_cache {	# $value = $self->{'device_cache'}($key);
# (my $self, my $key) = (shift, shift);

# if(!defined $key) {
# return $self->{'device_cache'};
# }
# elsif(ref($key) =~ /HASH/) {
# return $self->{'device_cache'} =  ($self->{'device_cache'}, $key);
# }
# else {
# return $self->{'device_cache'}->{$key};
# }
# }

#
# provides generic accessor methods to the fields defined in %fields and to the elements of $self->device_settings
#
sub AUTOLOAD {

    my $self  = shift;
    my $type  = ref($self) or croak "\$self is not an object";
    my $value = undef;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;    # strip fully qualified portion

    if ( exists $self->{_permitted}->{$name} ) {
        if (@_) {
            return $self->{$name} = shift;
        }
        else {
            return $self->{$name};
        }
    }
    elsif ( $name =~ qr/^(get_|set_)(.*)$/ ) {
        if ( exists $self->device_settings()->{$2} ) {
            return $self->getset( $1, $2, "device_settings", @_ );
        }
        elsif ( exists $self->device_cache()->{$2} ) {
            return $self->getset( $1, $2, "device_cache", @_ );
        }
        else {
            Lab::Exception::Warning->throw( error =>
                    "AUTOLOAD could not find var for getter/setter: $name \n"
            );
        }
    }
    elsif ( exists $self->{'device_settings'}->{$name} ) {
        if (@_) {
            return $self->{'device_settings'}->{$name} = shift;
        }
        else {
            return $self->{'device_settings'}->{$name};
        }
    }
    else {
        Lab::Exception::Warning->throw( error => "AUTOLOAD in "
                . __PACKAGE__
                . " couldn't access field '${name}'.\n" );
    }
}

# needed so AUTOLOAD doesn't try to call DESTROY on cleanup and prevent the inherited DESTROY
sub DESTROY {
    my $self = shift;

    #$self->connection()->DESTROY();
    $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}

sub getset {
    my $self     = shift;
    my $gs       = shift;
    my $varname  = shift;
    my $subfield = shift;
    if ( $gs eq 'set_' ) {
        my $value = shift;
        if ( !defined $value || ref($value) ne "" ) {
            Lab::Exception::CorruptParameter->throw( error =>
                    "No or no scalar value given to generic set function $AUTOLOAD in "
                    . __PACKAGE__
                    . "::AUTOLOAD().\n" );
        }
        if ( @_ > 0 ) {
            Lab::Exception::CorruptParameter->throw( error =>
                    "Too many values given to generic set function $AUTOLOAD "
                    . __PACKAGE__
                    . "::AUTOLOAD().\n" );
        }
        return $self->{$subfield}->{$varname} = $value;
    }
    else {
        if ( @_ > 0 ) {
            Lab::Exception::CorruptParameter->throw( error =>
                    "Too many values given to generic get function $AUTOLOAD "
                    . __PACKAGE__
                    . "::AUTOLOAD().\n" );
        }
        return $self->{$subfield}->{$varname};
    }
}

#
# This is a hook which is called after connection initialization and before the device cache is synced (see _construct).
# Necessary for some devices to put them into e.g. remote control mode or otherwise enable communication.
# Overwrite this if needed.
#
sub _device_init {
}

#
# This tool just returns the index of the element in the provided list
#

sub function_list_index {
    1 while $_[0] ne pop;
    $#_;
}

# sub WriteConfig {
#         my $self = shift;
#
#         my %config = @_;
# 	%config = %{$_[0]} if (ref($_[0]));
#
# 	my $command = "";
# 	# function characters init
# 	my $inCommand = "";
# 	my $betweenCmdAndData = "";
# 	my $postData = "";
# 	# config data
# 	if (exists $self->{'CommandRules'}) {
# 		# write stating value by default to command
# 		$command = $self->{'CommandRules'}->{'preCommand'}
# 			if (exists $self->{'CommandRules'}->{'preCommand'});
# 		$inCommand = $self->{'CommandRules'}->{'inCommand'}
# 			if (exists $self->{'CommandRules'}->{'inCommand'});
# 		$betweenCmdAndData = $self->{'CommandRules'}->{'betweenCmdAndData'}
# 			if (exists $self->{'CommandRules'}->{'betweenCmdAndData'});
# 		$postData = $self->{'CommandRules'}->{'postData'}
# 			if (exists $self->{'CommandRules'}->{'postData'});
# 	}
# 	# get command if sub call from itself
# 	$command = $_[1] if (ref($_[0]));
#
#         # build up commands buffer
#         foreach my $key (keys %config) {
# 		my $value = $config{$key};
#
# 		# reference again?
# 		if (ref($value)) {
# 			$self->WriteConfig($value,$command.$key.$inCommand);
# 		} else {
# 			# end of search
# 			$self->Write($command.$key.$betweenCmdAndData.$value.$postData);
# 		}
# 	}
#
# }

# =head2 WriteConfig
#
# this is NOT YET IMPLEMENTED in this base class so far
#
#  $instrument->WriteConfig( 'TRIGGER' => { 'SOURCE' => 'CHANNEL1',
#   			  	                          'EDGE'   => 'RISE' },
#     	               'AQUIRE'  => 'HRES',
#     	               'MEASURE' => { 'VRISE' => 'ON' });
#
# Builds up the commands and sends them to the instrument. To get the correct
# format a
# command rules hash has to be set up by the driver package
#
# e.g. for SCPI commands
# $instrument->{'CommandRules'} = {
#                   'preCommand'        => ':',
#     		  'inCommand'         => ':',
#     		  'betweenCmdAndData' => ' ',
#     		  'postData'          => '' # empty entries can be skipped
#     		};
#
#
#


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument - Instrument base class (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

Lab::Instrument is meant to be used as a base class for inheriting instruments.
For very simple applications it can also be used directly, like

  $generic_instrument = new Lab::Instrument ( connection_type => VISA_GPIB, gpib_address => 14 );
  my $idn = $generic_instrument->query('*IDN?');

Every inheriting class constructor should start as follows:

  sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);
    $self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);  # check for supported connections, initialize fields etc.
    ...
  }

Beware that only the first set of parameters specific to an individual GPIB
board or any other bus hardware gets used. Settings for EOI assertion for
example.

If you know what you're doing or you have an exotic scenario you can use the
connection parameter "ignore_twins => 1" to force the creation of a new bus
object, but this is discouraged - it will kill bus management and you might run
into hardware/resource sharing issues.

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

C<Lab::Instrument> is the base class for Instruments. It doesn't do much by
itself, but is meant to be inherited in specific instrument drivers. It provides
general C<read>, C<write> and C<query> methods and basic connection handling
(internally, C<_set_connection>, C<_check_connection>).

=head1 CONSTRUCTOR

=head2 new

This blesses $self (don't do it yourself in an inheriting class!), initializes
the basic "fields" to be accessed via AUTOLOAD and puts the configuration hash
in $self->config to be accessed in methods and inherited classes.

Arguments: just the configuration hash (or even-sized list) passed along from a
child class constructor. 

=head1 METHODS

=head2 write

 $instrument->write($command <, {optional hashref/hash}> );

Sends the command C<$command> to the instrument. An option hash can be supplied
as second or also as only argument. Generally, all options are passed to the
connection/bus, so additional named options may be supported based on the
connection and bus and can be passed as a hashref or hash. See
L<Lab::Connection>.

Optional named parameters for hash:

 error_check => 1/0

Invoke $instrument->check_errors after write. Defaults to off.

=head2 read

 $result=$instrument->read({ read_length => <max length>, brutal => <1/0>);

Reads a result of C<ReadLength> from the instrument and returns it. Returns an
exception on error.

If the parameter C<brutal> is set, a timeout in the connection will not result
in an Exception thrown, but will return the data obtained until the timeout
without further comment. Be aware that this data is also contained in the the
timeout exception object (see C<Lab::Exception>).

Generally, all options are passed to the connection/bus, so additional named
options may be supported based on the  connection and bus and can be passed as a
hashref or hash. See L<Lab::Connection>.

=head2 query

 $result=$instrument->query({ command => $command,
 	                          wait_query => $wait_query,
                              read_length => $read_length);

Sends the command C<$command> to the instrument and reads a result from the
instrument and returns it. The length of the read buffer is set to
C<read_length> or to the default set in the connection.

Waits for C<wait_query> microseconds before trying to read the answer.

Generally, all options are passed to the connection/bus, so additional named
options may be supported based on the connection and bus and can be passed as a
hashref or hash. See L<Lab::Connection>.

=head2 get_error

	($errcode, $errmsg) = $instrument->get_error();

Method stub to be overwritten. Implementations read one error (and message, if
available) from the device.

=head2 get_status

	$status = $instrument->get_status();
	if( $instrument->get_status('ERROR') ) {...}

Method stub to be overwritten. This returns the status reported by the device
(e.g. the status byte retrieved via serial poll from GPIB devices). When
implementing, use only information which can be retrieved very fast from the
device, as this may be used often. 

Without parameters, has to return a hashref with named status bits, e.g.

 $status => {
 	ERROR => 1,
 	DATA => 0,
 	READY => 1
 }

If present, the first argument is interpreted as a key and the corresponding
value of the hash above is returned directly.

The 'ERROR'-key has to be implemented in every device driver!

=head2 check_errors

	$instrument->check_errors($last_command);
	
	# try
	eval { $instrument->check_errors($last_command) };
	# catch
	if ( my $e = Exception::Class->caught('Lab::Exception::DeviceError')) {
		warn "Errors from device!";
		@errors = $e->error_list();
		@devtype = $e->device_class();
		$command = $e->command();		
	}

Uses get_error() to check the device for occured errors. Reads all present
errors and throws a Lab::Exception::DeviceError. The list of errors, the device
class and the last issued command(s) (if the script provided them) are enclosed.

=head2 _check_args

Parse the arguments given to a method. The typical use is like this:

 sub my_method () {
     my $self = shift;
     my ($arg_1, $arg_2, $tail) = $self->_check_args(\@_, ['arg1', 'arg2']);
     ...
 }

There are now two ways, how a user can give arguments to C<my_method>. Both of
the following calls will assign C<$value1> to C<$arg1> and C<$value2> to C<$arg2>.

=over

=item old style:

 $instrument->my_method($value1, $value2, $tail);

=item new style:

 $instrument->my_method({arg1 => $value1, arg2 => $value2});

Remaining key-value pairs will be consumed by C<$tail>. For example, after

 $instrument->my_method({arg1 => $value1, arg2 => $value2, x => $value_x});

C<$tail> will hold the hashref C<< {x => $value_x} >>.

Multiple hashrefs given to C<my_method> are concatenated.

For a method without named arguments, you can either use

 my ($tail) = $self->_check_args(\@_, []);

or

 my ($tail) = $self->_check_args(\@);

=back

=head2 _check_args_strict

Like C<_check_args>, but makes all declared arguments mandatory.

If an argument does not
receive a non-undef value, this will throw an exception. Thus, the returned
array will never contain undefined values.

=head1 CAVEATS/BUGS

Probably many, with all the porting. This will get better.

=head1 SEE ALSO

=over 4

=item * L<Lab::Bus>

=item * L<Lab::Connection>

=item * L<Lab::Instrument::HP34401A>

=item * L<Lab::Instrument::HP34970A>

=item * L<Lab::Instrument::Source>

=item * L<Lab::Instrument::Yokogawa7651>

=item * and many more...

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2005-2006  Daniel Schroeer
            2009       Andreas K. Huettel
            2010       Andreas K. Huettel, Daniel Schroeer, Florian Olbrich, Matthias Voelker
            2011       Andreas K. Huettel, Florian Olbrich
            2012       Alois Dirnaichner, Andreas K. Huettel, Christian Butschkow, Florian Olbrich, Stefan Geissler
            2013       Alois Dirnaichner, Andreas K. Huettel, Christian Butschkow, Stefan Geissler
            2014       Alexei Iankilevitch, Christian Butschkow
            2016       Charles Lane, Simon Reinhardt
            2017       Andreas K. Huettel
            2019       Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
