package Lab::XPRESS::hub;
use Lab::Exception;
use strict;
use Exporter 'import';
use Module::Load qw/load autoload/;
use Try::Tiny;

our $VERSION = '3.543';

our @EXPORT_OK = qw(DataFile Sweep Frame Instrument Connection);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};
    bless( $self, $class );

    return $self;

}

sub DataFile {
    my $self = shift if ref( $_[0] ) eq __PACKAGE__;
    my ( $filenamebase, $foldername ) = @_;

    use Lab::XPRESS::Data::XPRESS_DataFile;
    my $xFile
        = new Lab::XPRESS::Data::XPRESS_DataFile( $filenamebase, $foldername )
        or die Lab::Exception::CorruptParameter->throw(
        error => "Can't open file $filenamebase\n" );
    return $xFile;

}

sub Sweep {
    my $self = shift if ref( $_[0] ) eq __PACKAGE__;
    my $sweep = shift;

    $sweep = "Lab::XPRESS::Sweep::" . $sweep;
    eval "require $sweep; $sweep->import(); 1;"
        or do Lab::Exception::CorruptParameter->throw( error => $@ );

    return $sweep->new(@_);

}

sub Frame {
    my $self = shift if ref( $_[0] ) eq __PACKAGE__;

    my $frame = "Lab::XPRESS::Sweep::Frame";
    eval "require $frame; $frame->import(); 1;"
        or do Lab::Exception::CorruptParameter->throw( error => $@ );

    #or do Lab::Exception::CorruptParameter->throw( error => "Can't locate module $frame\n" );

    return $frame->new(@_);

}

sub Instrument {
    my $self = shift;
    my $instrument;
    if ( ref($self) eq __PACKAGE__ ) {
        $instrument = shift;
    }
    else {
        $instrument = $self;
    }

    my $found_module;
    my $module;
    try {
        $module = "Lab::Instrument::" . $instrument;
        warn "before autoload";
        autoload($module);
        warn "after autoload";
        $found_module = 1;
    };

    if ($found_module) {
        return $module->new(@_);
    }

    $module = "Lab::Moose::Instrument::" . $instrument;
    load($module);

    my $args_ref          = shift;
    my $connection_type   = delete $args_ref->{connection_type};
    my $connection_module = "Lab::Moose::Connection::" . $connection_type;
    load($connection_module);
    my $connection = $connection_module->new($args_ref);
    return $module->new(
        %{$args_ref},
        connection => $connection
    );
}

sub Connection {
    my $self = shift if ref( $_[0] ) eq __PACKAGE__;
    my $connection = shift;

    $connection = "Lab::Connection::" . $connection;
    eval "require $connection; $connection->import(); 1;"
        or do Lab::Exception::CorruptParameter->throw( error => $@ );

    #or do Lab::Exception::CorruptParameter->throw( error => "Can't locate module $connection\n" );

    return $connection->new(@_);

}

sub show_available_objects {
    my $self = shift if ref( $_[0] ) eq __PACKAGE__;

    my $xDIR = $INC{"Lab/XPRESS/hub.pm"};
    $xDIR =~ s/hub.pm//g;

    opendir( DIR, $xDIR . "Sweep" );
    my @sweeps = readdir(DIR);
    shift @sweeps;    # shift "."
    shift @sweeps;    # shift ".."

    $xDIR =~ s/XPRESS\///g;
    opendir( DIR, $xDIR . "Instrument" );
    my @instruments = readdir(DIR);
    shift @instruments;    # shift "."
    shift @instruments;    # shift ".."

    $xDIR =~ s/Instrument\///g;
    opendir( DIR, $xDIR . "Connection" );
    my @connections = readdir(DIR);
    shift @connections;    # shift "."
    shift @connections;    # shift ".."

    print "\n\n";
    print "================\n";
    print " XPRESS add-on: \n";
    print "================\n";
    print "\n\n";

    print "available connections:\n";
    print "--------------------------\n";
    foreach my $module (@connections) {
        $module =~ s/\.pm//g;
        print $module. "\n";
    }
    print "--------------------------\n";
    print "\n\n";

    print "available Instruments:\n";
    print "--------------------------\n";
    foreach my $module (@instruments) {
        $module =~ s/\.pm//g;
        print $module. "\n";
    }
    print "--------------------------\n";
    print "\n\n";

    print "available sweep modules:\n";
    print "--------------------------\n";
    foreach my $module (@sweeps) {
        $module =~ s/\.pm//g;
        print $module. "\n";
    }
    print "--------------------------\n";
    print "\n\n";

}

1;
