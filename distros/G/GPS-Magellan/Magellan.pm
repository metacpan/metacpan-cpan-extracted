package GPS::Magellan;

use strict;
use warnings;

use GPS::Magellan::Message;
use GPS::Magellan::Coord;

use vars qw($AUTOLOAD);

our $VERSION = '0.61';

sub new {
    my $proto = shift;

    my $class = ref($proto) || $proto;

    my %args = @_;

    my $port = $args{port} || '/dev/ttyS0';

    my $self = bless {
        RUN_OFFLINE => $args{RUN_OFFLINE} || 0,
        port => $port,
        raw_file => 'magellan.log',
        debug => 1,
    }, $class;

    warn "calling init\n";
    magellan_init() unless $self->RUN_OFFLINE;
    $self;
}

sub connect {
    my $self = shift;
    return if $self->RUN_OFFLINE;
#    die sprintf("GPS::Magellan::new(): port not specified") unless $self->{port};
#    OpenPort($self->{port});
}

sub getPoints {
    my $self = shift;
    my $cmd = shift or die "getPoint( WAYPOINT | TRACKLOG )\n";

    my @messages = $self->command($cmd);
    my @coords = (); 
    foreach my $msg (@messages){
        my $wpt = GPS::Magellan::Coord->new($msg->DATA);
        push @coords, $wpt;
    }
    return @coords;
}

sub command {
    my $self = shift;
    my $cmd = shift;

    die "command() needs cmd" unless $cmd;

    return $self->_command($cmd) unless $self->RUN_OFFLINE;

    my $data_file = "test-data/$cmd";

    open(DATA, "$data_file") or die "cannot open $data_file\n";
    my @result = <DATA>;
    close(DATA);

    map { 
        chomp;
        my $data = $_;
        $_ = GPS::Magellan::Message->new;
        $_->DATA($data);
    } @result;
    
    return @result;

}

sub _command {
    my $self = shift;
    my $cmd = shift;

    die "_command() needs cmd" unless $cmd;

    magellan_handon();

    MagWriteMessageSum("PMGNCMD,$cmd");

    my @messages = ();

    while(1){
        my $raw_msg = magellan_findmessage('$PMGN') or next;

        my $msg = GPS::Magellan::Message->new($raw_msg);
        
        if($msg->COMMAND eq 'CMD'){
            last if $msg->DATA eq 'END';
        }

        my $chksum = $msg->CHECKSUM;

        my $ack = sprintf("PMGNCSM,%s", $chksum);

        MagWriteMessageNoAck($ack);
    
        push @messages, $msg;
    }
    return @messages;
}


# Accessors
sub _get {
    my $self = shift;
    my $attr = shift;
    return $self->{$attr};
}

sub _set {
    my $self = shift;
    my $attr = shift;
    my $value = shift || '';

    return unless $attr;

    $self->{$attr} = $value;
    return $self->_get($attr);
}

sub _debug_autoload {
    my $self = shift;
    $self->_set('_debug_autoload', shift) if @_;
    $self->_get('_debug_autoload');
}

    
sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;

    $attr =~ s/.*:://;

    return if $attr =~ /^_/;

    warn "AUTOLOAD: $attr\n" if $self->_debug_autoload;

    if(@_){
        $self->_set($attr, shift);
    }
    return $self->_get($attr);
}

sub DESTROY {
    ClosePort() unless shift->RUN_OFFLINE;
}

require XSLoader;
XSLoader::load('GPS::Magellan', $VERSION);

1;

__END__

=head1 NAME

GPS::Magellan - Module for communicating with Magellan receivers

=head1 SYNOPSIS

 GPS::Magellan::OpenPort('/dev/ttyS0');

 $gps = GPS::Magellan->new(
     port => '/dev/ttyS0'
 );

 # Download waypoints
 @waypoints = $gps->getPoints('WAYPOINT');

 foreach $coord (@waypoints){
    printf("longitude: %s, latitude: %s\n", $coord->longitude, $coord->latitude);
 }

 # Download trackpoints
 @trackpoints = $gps->getPoints('TRACKLOG');

 foreach $coord (@trackpoints){
    printf("longitude: %s, latitude: %s\n", $coord->longitude, $coord->latitude);
 }

 $file = GPS::Magellan::File::Way_Txt->new(
    coords => \@waypoints
 );
 
 print $file->as_string();
 
=cut

=head1 DESCRIPTION

Soming soon, until then see README, examples/magellan.pl and the 
test suite for example.

=head1 METHODS

=over 4

=cut

=item new ( port => SERIAL_DEVICE )

Instantiates a new GPS::Magellan object.  SERIAL_DEVICE specifies which port
if the receiver connected to.

=cut


=item getPoints( 'WAYPOINT' | 'TRACKLOG' )

Downloads coordinates of the specified type from the receiver.

Returns: an array of L<GPS::Magellan::Coord> objects.

=cut

=item command( COMMAND )

Send arbitrary command to the receiver.

Returns: the receiver's response as an array of L<GPS::Magellan::Message> objects.

=cut

=back 4

=head1 AUTHOR

Peter Banik E<lt>peter@login-fo.netE<gt>

=head1 SEE ALSO

L<GPS::Magellan::Coord>
L<GPS::Magellan::Message>
L<GPS::Magellan::File>

=head1 VERSION

$Id: Magellan.pm,v 1.2 2004/02/29 21:48:38 peter Exp $

=head1 BUGS

 Missing coordinate upload feature.
 Needs more documentation.
 Instead of GPS::Magellan::Coord, it should make use of a generic coordinate class.
 
Please report bugs to the author.

=head1 COPYRIGHT

Copyright (c) 2003 

=cut



