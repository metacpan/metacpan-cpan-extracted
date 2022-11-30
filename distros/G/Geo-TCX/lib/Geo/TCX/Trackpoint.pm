package Geo::TCX::Trackpoint;
use strict;
use warnings;

our $VERSION = '1.03';

=encoding utf-8

=head1 NAME

Geo::TCX::Trackpoint - Class to store and edit TCX trackpoints

=head1 SYNOPSIS

  use Geo::TCX::Trackpoint;

=head1 DESCRIPTION

This package is mainly used by the L<Geo::TCX> module and serves little purpose on its own. The interface is documented mostly for the purpose of code maintainance.

L<Geo::TCX::Trackpoint> provides a data structure for TCX trackpoints and provides accessor methods to read and edit trackpoint data.

TCX trackpoints are different from GPX trackpoints in that they contain tags such as C<AltitudeMeters>, C<DistanceMeters>, C<HeartRateBpm>, C<Time>, and potentially C<Cadence>, C<SensorState>. Also the coordinates are tagged with longer-form fields as C<LatitudeDegrees>, C<LongitudeDegrees>.

=cut

use Geo::Calc;
use Geo::Gpx::Point;
use Carp qw(confess croak cluck);
use vars qw($AUTOLOAD %possible_attr);

# file-scoped lexicals
my @attr = qw/ LatitudeDegrees LongitudeDegrees /;
$possible_attr{$_} = 1 for @attr;

=head2 Constructor Methods

=over 4

=item new( $xml_str )

Takes an xml string argument containing coordinates contained within the C<Position> xml tag (optional) as recorded by Garmin Edge devices and returns a basic C<Geo::TCX::Trackpoint> object containing only coordinates.

  $str_basic = '<Position><LatitudeDegrees>45.304996</LatitudeDegrees><LongitudeDegrees>-72.637243</LongitudeDegrees></Position>';
  $tp_basic = Geo::TCX::Trackpoint->new( $str_basic );

=item Geo::TCX::Trackpoint::Full::new( $xml_str, $previous_pt )

Takes an xml string argument in the form of a Garmin TCX trackpoint, as recorded by Garmin Edge devices, and returns a C<Geo::TCX::Trackpoint::Full> object containing fields that are supplementary to coordinates. See the list of fields in the AUTOLOAD section below.

  $str_full = '<Trackpoint><Time>2014-08-11T10:25:26Z</Time><Position><LatitudeDegrees>45.304996</LatitudeDegrees><LongitudeDegrees>-72.637243</LongitudeDegrees></Position><AltitudeMeters>211.082</AltitudeMeters><DistanceMeters>13.030</DistanceMeters><HeartRateBpm><Value>80</Value></HeartRateBpm></Trackpoint>';

  $tp_full = Geo::TCX::Trackpoint::Full->new( $str_full );

I<$previous_pt> is optional and if specified will be interpreted as the previous trackpoint and be used to keep track of the distance and time that have elapsed since the latter. See the methods below to access these "elapsed" fields. If no previous trackpoint is provided, the elapsed time will remain undefined and the elapsed distance will set to the C<DistanceMeters> field of the trackpoint.

=back

=cut

sub new {
    my ($proto, $pt_str) = (shift, shift);
    croak 'too many arguments specified' if @_;
    my $class = ref($proto) || $proto;
    my $pt = {};
    bless($pt, $class);

    # Lat and Long are contained in that tag, not needed
    $pt_str =~ s,\</*Position\>,,g;

    # initialize fields/attr
    while ($pt_str =~ m,\<([^<>]*)\>(.*?)\</([^<>]*)\>,gs) {
        # or could simply state =~ m,\<(.*?)\>(.*?)\</.*?\>,gs)
        croak 'Could not match identical attr' unless $1 eq $3;
        croak 'field not allowed' unless $possible_attr{$1};
        $pt->{$1} = $2
    }
    return $pt
}

=over 4

=item clone()

Returns a deep copy of a C<Geo::TCX::Trackpoint> instance.

  $clone = $trackpoint->clone;

=back

=cut

sub clone {
    my $clone;
    eval(Data::Dumper->Dump([ shift ], ['$clone']));
    confess $@ if $@;
    return $clone
}

=head2 AUTOLOAD Methods

=cut

=over 4

=item I<field>( $value )

Methods with respect to certain fields can be autoloaded and return the current or newly set value.

For Basic trackpoints, LatitudeDegrees and LongitudeDegrees are the supported fields.

For Full trackpoints, supported fields are: LatitudeDegrees, LongitudeDegrees, AltitudeMeters, HeartRateBpm, Cadence, and SensorState.

Some fields may contain a value of 0. It is safer to check if a field is defined with C<< if (defined $trackpoint->Cadence) >> rather than C<< if ($trackpoint->Cadence) >>.

Caution should be used if setting a I<$value> as no checks are performed to ensure the value is appropriate or in the proper format.

=back

=cut

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;
    return unless $attr =~ /[^A-Z]/;  # skip DESTROY and all-cap methods
    croak "invalid attribute method: -> $attr()" unless $possible_attr{$attr};
    $self->{$attr} = shift if @_;
    return $self->{$attr}
}

=head2 Object Methods

=cut

=over 4

=item to_gpx()

Returns a trackpoint as a L<Geo::Gpx::Point>.

=back

=cut

sub to_gpx {
    my ($pt, %attr) = @_;           # call to new() will handle error check
    my %fields = (  lat => $pt->LatitudeDegrees, lon => $pt->LongitudeDegrees );
    $fields{ele} = $pt->AltitudeMeters if defined $pt->AltitudeMeters;
    $fields{time} = $pt->{_time_epoch} if defined $pt->Time;
    return Geo::Gpx::Point->new( %fields, %attr );
}

=over 4

=item to_geocalc()

Returns a trackpoint as a L<Geo::Calc> object.

=back

=cut

sub to_geocalc {
    my $pt = shift;
    croak "to_geocalc() takes no arguments" if @_;
    return Geo::Calc->new( lat => $pt->LatitudeDegrees, lon => $pt->LongitudeDegrees );
}

=over 4

=item to_basic()

Returns a trackpoint as a C<Geo::TCX::Trackpoint> object with only position information (i.e coordinates).

=back

=cut

sub to_basic {
    my $pt = shift;
    croak "to_geocalc() takes no arguments" if @_;
    my $newpt = {};
    bless($newpt, 'Geo::TCX::Trackpoint');
    $newpt->LatitudeDegrees(  $pt->LatitudeDegrees );
    $newpt->LongitudeDegrees( $pt->LongitudeDegrees );
    return $newpt
}

=over 4

=item distance_to ( $trackpoint )

Calculates and returns the distance to the specified I<$trackpoint> object using the L<Geo::Calc> module.

=back

=cut

sub distance_to {
    my ($from, $to) = (shift, shift);
    croak 'expects a single trackpoint as argument' if @_ or ! $to->isa('Geo::TCX::Trackpoint');
    my $g = Geo::Calc->new( lat => $from->LatitudeDegrees, lon => $from->LongitudeDegrees );
    my $dist = $g->distance_to( { lat => $to->LatitudeDegrees, lon => $to->LongitudeDegrees } );
    return $dist
}

=over 4

=item xml_string()

returns a string containing the XML representation of the object, equivalent to the string argument expected by C<new()>.

=back

=cut

sub xml_string {
    my $pt = shift;
    my %opts = @_;

    my $newline = $opts{indent} ? "\n" : '';
    my $tab     = $opts{indent} ? '  ' : '';
    my $n_tabs  = $opts{n_tabs} ? $opts{n_tabs} : 4;

    my $str;
    $str .= $newline . $tab x ($n_tabs + 1) . '<Position>';
    $str .= $newline . $tab x ($n_tabs + 2) . '<LatitudeDegrees>'  . $pt->LatitudeDegrees . '</LatitudeDegrees>';
    $str .= $newline . $tab x ($n_tabs + 2) . '<LongitudeDegrees>' . $pt->LongitudeDegrees . '</LongitudeDegrees>';
    $str .= $newline . $tab x ($n_tabs + 1) . '</Position>';
    return $str
}

=over 4

=item summ()

For debugging purposes, summarizes the fields of the trackpoint by printing them to screen. Returns true.

=back

=cut

sub summ {
    my $pt = shift;
    croak 'summ() expects no arguments' if @_;
    my %fields;
    foreach my $key (keys %{$pt}) {
        print "$key: ", $pt->{$key}, "\n"
    }
    return 1
}

package Geo::TCX::Trackpoint::Full;
use strict;
use warnings;

use DateTime::Format::ISO8601;
use Carp qw(confess croak cluck);

our $VERSION = '1.03';
our @ISA=qw(Geo::TCX::Trackpoint);


{ # lexical scope for that package

use vars qw($AUTOLOAD %possible_attr);

our ($LocalTZ, $Formatter);
$LocalTZ   = DateTime::TimeZone->new( name => 'local' );
$Formatter = DateTime::Format::Strptime->new( pattern => '%a %b %e %H:%M:%S %Y' );
my $formatter_xsd = DateTime::Format::Strptime->new( pattern => '%Y-%m-%dT%H:%M:%SZ' );
# ... to avoid looking up timezone each time Trackpoint->new is called

# file-scoped lexicals
my @attr = qw/ LatitudeDegrees LongitudeDegrees AltitudeMeters DistanceMeters Time HeartRateBpm Cadence SensorState /;
$possible_attr{$_} = 1 for @attr;

sub new {
    my ($proto, $pt_str, $previous_pt) = (shift, shift, shift);
    if (ref $previous_pt) {
        croak 'second argument must be a Trackpoint object' unless $previous_pt->isa('Geo::TCX::Trackpoint')
    }
    croak 'too many arguments specified' if @_;
    my $class = ref($proto) || $proto;

    # Ignoring Extensions tags, might support them at some point
    $pt_str =~ s,\<Extensions\>.*?\</Extensions\>,,g;

    my $chomped_str = $pt_str;
    if ( $chomped_str =~ m,\s*^\<Trackpoint\>(.*)\</Trackpoint\>\s*$,gs ) {
        $chomped_str = $1
    }
    # contrary to Track, the <Trackpoint>...</Trackpoint> are optional

    # Extract the Position tag and create a basic positional trackpoint
    my $pt;
    if ( $chomped_str =~ s/(<Position>.*<\/Position>)//g ) {
        $pt =$class->SUPER::new( $1 )
    } else {
        # $DB::single=1;
        # I put a debug flag here because I want to see instances where
        # a trackpoint does not have coordinates and see how I should address those
        # croak 'no <Position>...</Position> xml tag in string'
        # call it anyway for now until I figure out how to handle those
        $pt = {};
        bless($pt, $class);
    }
    $chomped_str =~ s,\</*Value\>,,g;         # HeartRateBpm value contained in that tag, not needed

    # initialize fields/attr
    while ($chomped_str=~ m,\<([^<>]*)\>(.*?)\</([^<>]*)\>,gs) {
        # or could simply state =~ m,\<(.*?)\>(.*?)\</.*?\>,gs)
        croak 'Could not match identical attr' unless $1 eq $3;
        croak 'field not allowed' unless $possible_attr{$1};
        $pt->{$1} = $2
    }

    # for debugging -- allow trackpoints with only coordinates but inspect them in debugger
    $pt->{_noTime} = 1 unless defined $pt->{Time};
    $pt->{_noDist} = 1 unless defined $pt->{DistanceMeters};
    if ($pt->{_noTime} or $pt->{_noDist}) {
        # commented out as I am building my databases, way too many files to parse to inspect them now, will uncomment when I am done parsing my databases
        #        $DB::single=1
    }

    $pt->_reset_distance( $pt->{DistanceMeters}, $previous_pt ) unless $pt->{_noDist};
    unless ($pt->{_noTime}) {
        my $orig_time_string = $pt->{Time};
        $pt->_reset_time( $pt->{Time}, $previous_pt ) unless $pt->{_noTime};
        print "strange ISO time not equal to time string from TCX file for this trackpoint\n"
                            if $orig_time_string ne $pt->{_time_iso8601};
    }
    return $pt
}

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;
    return unless $attr =~ /[^A-Z]/;  # skip DESTROY and all-cap methods
    croak "invalid attribute method: -> $attr()" unless $possible_attr{$attr};
    $self->{$attr} = shift if @_;
    return $self->{$attr}
}

=head2 Object Methods for class Geo::TXC::Trackpoint::Full

=over 4

=item DistanceMeters()

Returns the C<DistanceMeters> field of a trackpoint.

=back

=cut

sub DistanceMeters { return shift->{DistanceMeters} }

=over 4

=item distance_elapsed( $value, force => true/false )

Returns the elapsed distance (in meters) of a point as initially computed when the trackpoint was created. The value is never reset unless C<< force => 1 >> is specified.

C<force> is needed internally by L<Geo::TCX::Lap>'s C<split()> and L<Geo::TCX::Track>'s <merge()> methods. Use with caution.

=back

=cut

sub distance_elapsed {
    my ($pt, $value)  = (shift, shift);
    my %opts = @_;
    if (defined $value) {
        croak "need to specify option 'force => 1' to set a value" unless $opts{force};
        $pt->{_distance_elapsed} = sprintf '%.3f', $value
    }
    return $pt->{_distance_elapsed}
}

=over 4

=item Time()

Returns the C<Time> field of a trackpoint.

=back

=cut

sub Time { return shift->{Time} }

=over 4

=item time_dt ()

=item time_datetime ()

Return a L<DateTime> object corresponding to the time of a trackpoint.

=back

=cut

sub time_dt          { return DateTime::Format::ISO8601->parse_datetime( shift->Time ) }
sub time_datetime    { return DateTime::Format::ISO8601->parse_datetime( shift->Time ) }
# we never store a DateTime object but provide a method to create one

=over 4

=item time_local( $trackpoint )

Returns the formatted local time of the trackpoint. The local time is always represented based on the locale of the system that calls this method, not that of where the trackpoint was recorded. It is not possible to know in which time zone a trackpoint was recorded at this stage.

=back

=cut

sub time_local { return shift->{_time_local} }

=over 4

=item time_add( @duration )

=item time_subtract( @duration )

Perform L<DateTime> math on the timestamps of each lap's starttime and trackpoint by adding the specified time duration and return true.

The duration can be provided as an actual L<DateTime::Duration> object or an array of arguments as per the syntax of L<DateTime>'s C<add()> or C<subtract()> methods, which expect a hash of keys such as
    years        => 3,
    months       => 5,
    weeks        => 1,
    days         => 1,
    hours        => 6,
    minutes      => 15,
    seconds      => 45,
    nanoseconds  => 12000,
    end_of_month => 'limit'

where only the relevant keys need to be specified i.e. C<< time_add( minutes > 30, seconds > 15) >>.

=back

=cut

sub time_add {
    my ($pt, $dur)  = shift;
    if (ref $_[0] and $_[0]->isa('DateTime::Duration') ) {
        $dur = shift
    } else { $dur = DateTime::Duration->new( @_ ) }
    my $dt = $pt->time_datetime;
    $dt->add( $dur );
    $pt->_set_time_keys( $dt );
    return 1
}

sub time_subtract {
    my ($pt, $dur)  = shift;
    if (ref $_[0] and $_[0]->isa('DateTime::Duration') ) {
        $dur = shift
    } else { $dur = DateTime::Duration->new( @_ ) }
    my $dt = $pt->time_datetime;
    $dt->subtract( $dur );
    $pt->_set_time_keys( $dt );
    return 1
}

=over 4

=item time_epoch()

Returns the epoch time of a point.

=back

=cut

sub time_epoch { return shift->{_time_epoch} }

=over 4

=item time_elapsed( $value, force => true/false )

Returns the elapsed time of a point as initially computed when the trackpoint was created. The value is never reset unless C<< force => 1 >> is specified.

C<force> is needed internally by L<Geo::TCX::Lap>'s constructor, C<split()>, and C<reverse()> methods as well as L<Geo::TCX::Track>'s <reverse()>. Use with caution.

=back

=cut

sub time_elapsed {
    my ($pt, $value)  = (shift, shift);
    my %opts = @_;
    if (defined $value) {
        croak "need to specify option 'force => 1' to set a value" unless $opts{force};
        $pt->{_time_elapsed} = $value
    }
    return $pt->{_time_elapsed}
}

=over 4

=item time_duration( $datetime or $trackpoint or $string or $integer )

Returns a L<DateTime::Duration> object containing the duration between the timestamps of two trackpoints. Consistent with the documentation for L<DateTime::Duration> the "duration is relative to the object from which I<$datetime> is subtracted". The duration will be positive if the timestamp of I<$datetime> occurs prior to the trackpoint, otherwise it will be negative.

This method accepts four forms for the argument: a L<DateTime> object such as that returned by C<< $pt->time >>, an ISO8601 string such as that returned by  C<< $pt->Time >>, a Trackpoint object, or an integer than can be interpreted as an epoch time.

These duration objects are useful to pass to C<time_add()> or C<time_subtract>.

=back

=cut

sub time_duration {
    my $self  = shift;
    my ($dt, $datetime);
    # first arg can time DateTime or trackpoint, and epoch time, or a time string
    if (ref $_[0]) {
        if ( $_[0]->isa('DateTime') ) {
            $datetime = $_[0]
        } else {
            croak 'object as argument must be either a DateTime or a Trackpoint instance'
                     unless $_[0]->isa('Geo::TCX::Trackpoint');
            $datetime = $_[0]->time_datetime
        }
    } elsif ($_[0] =~ /^(\d+)$/) {
        $datetime = DateTime->from_epoch( epoch => $1 )
    } else {
        $datetime = DateTime::Format::ISO8601->parse_datetime( $_[0] )
    }
    $dt = $self->time_datetime;

    my $dur = $dt->subtract_datetime( $datetime );
    return $dur
}

sub xml_string {
    my $pt = shift;
    my %opts = @_;

    my $newline = $opts{indent} ? "\n" : '';
    my $tab     = $opts{indent} ? '  ' : '';
    my $n_tabs  = $opts{n_tabs} ? $opts{n_tabs} : 4;

    my $str;
    $str .= $newline . $tab x $n_tabs . '<Trackpoint>';
    $str .= $newline . $tab x ($n_tabs + 1) . '<Time>' . $pt->Time . '</Time>';
    if (defined $pt->LatitudeDegrees) {
        $str .= $newline . $tab x ($n_tabs + 1) . '<Position>';
        $str .= $newline . $tab x ($n_tabs + 2) . '<LatitudeDegrees>' . $pt->LatitudeDegrees . '</LatitudeDegrees>';
        $str .= $newline . $tab x ($n_tabs + 2) . '<LongitudeDegrees>' . $pt->LongitudeDegrees . '</LongitudeDegrees>';
        $str .= $newline . $tab x ($n_tabs + 1) . '</Position>';
    }
    $str .= $newline . $tab x ($n_tabs + 1) . '<AltitudeMeters>'. $pt->AltitudeMeters . '</AltitudeMeters>';
    $str .= $newline . $tab x ($n_tabs + 1) . '<DistanceMeters>'. $pt->DistanceMeters . '</DistanceMeters>';
    if (defined $pt->HeartRateBpm) {
        $str .= '<HeartRateBpm><Value>'. $pt->HeartRateBpm . '</Value></HeartRateBpm>'
    }
    if (defined $pt->Cadence) {
        $str .= '<Cadence>'. $pt->Cadence . '</Cadence>'
    }
    if (defined $pt->SensorState) {
        $str .= '<SensorState>'. $pt->SensorState . '</SensorState>'
    }
    $str .= $newline . $tab x $n_tabs . '</Trackpoint>';
    return $str
}

# Internal methods and functions

sub _reset_time {                              # called by new() and by Track.pm
    my ($pt, $time, $previous_pt) = @_;
    $previous_pt = pop if ref $_[-1] and $_[-1]->isa('Geo::TCX::Trackpoint');
    delete $pt->{_time_elapsed};               # by design, immutable in _set_*
    $pt->_set_time_keys($time, $previous_pt);
    return 1
}

sub _reset_time_from_epoch {                   # called by Track.pm
    my ($pt, $epoch, $previous_pt) = @_;
    my $dt = DateTime->from_epoch( epoch => $epoch );
    delete $pt->{_time_elapsed};
    $pt->_set_time_keys( $dt, $previous_pt );
    return 1
}

sub _reset_distance {                          # called by new() and by Track.pm
    my ($pt, $distance, $previous_pt) = @_;
    if (ref $previous_pt) {
        croak 'second argument must be a Trackpoint object' unless $previous_pt->isa('Geo::TCX::Trackpoint')
    }
    delete $pt->{_distance_elapsed};
    $pt->_set_distance_keys($distance, $previous_pt);
    return 1
}

# Expects a I<$time_string> in a format parseable by L<DateTime::Format::ISO8601>'s C<parse_datetime> constructor
# . sets the time-related fields for the trackpoint. Returns true.
# . if the _time_elapsed key for the point is not already defined and another trackpoint object is also provided,
#     e.g. the previous trackpoint, it will also set it (as number of seconds since the timestamp of that previous point)
# . allows a DateTime obj as argument instead of $time which is required by methods that need to modify time so
#     that we can update the keys to be consistent with the new time e.g. time_add(), time_subtract(), _reset_time_from_epoch()

sub _set_time_keys {
    my ($pt, $time, $previous_pt) = (shift, shift);
    $previous_pt = pop if ref $_[-1] and $_[-1]->isa('Geo::TCX::Trackpoint');

    my $dt;
    if ( ref( $time ) and $time->isa('DateTime') ) {
        $dt = $time
    } else {
        $pt->{Time} = $time;
        $dt = $pt->time_datetime
    }

    $pt->{Time}          = _time_format($dt);
    $pt->{_time_iso8601} = _time_format($dt);
    $pt->{_time_local}   = _time_format($dt, local => 1);
    $pt->{_time_epoch}   = $dt->epoch;

    if ( ! exists $pt->{_time_elapsed} ) {          # i.e. immutable here
        if ( $previous_pt ) {
            $pt->{_time_elapsed} = $pt->{_time_epoch} - $previous_pt->{_time_epoch}
        } else { $pt->{_time_elapsed} = undef }
    }
    return 1
}

sub _time_format {
    my $dt = shift;
    # !! TODO:  check that ref is not a Garmin Object (croack that function is not a class method)
    my %opts = @_;
    if ($opts{'local'}) {
        $dt->set_formatter( $Formatter );      # see pattern in $Formatter
        $dt->set_time_zone( $LocalTZ )
    } else {
        $dt->set_formatter( $formatter_xsd )
    }
    return $dt->stringify
}

# Expects a decimal-number or integer and sets the C<DistanceMeters> field for the trackpoint and returns true
# . if the _distance_elapsed key for the point is not already defined and another trackpoint object is also provided,
#     e.g. the previous trackpoint, it will also set it (number of meters from that previous point)

sub _set_distance_keys {
    my ($pt, $meters, $previous_pt) = shift;
    $previous_pt = pop if ref $_[-1] and $_[-1]->isa('Geo::TCX::Trackpoint');
    $meters = shift;

    my $meters_formatted;
    $meters_formatted  = sprintf("%.3f", $meters) if defined $meters;

    $pt->{DistanceMeters} = $meters_formatted;

    if ( ! exists $pt->{_distance_elapsed} ) {      # i.e. immutable here
        if ( $previous_pt ) {
            my $dist_elapsed = $pt->DistanceMeters - $previous_pt->DistanceMeters;
            $pt->{_distance_elapsed} = sprintf("%.3f", $dist_elapsed)
        } else { $pt->{_distance_elapsed} = $meters_formatted }
    }
    return 1
}

}

=head1 EXAMPLES

Coming soon.

=head1 AUTHOR

Patrick Joly

=head1 VERSION

1.03

=head1 SEE ALSO

perl(1).

=cut

1;

__END__

A trackpoint string looks like:

 <Time>2014-08-11T10:55:26Z</Time><Position><LatitudeDegrees>45.293131</LatitudeDegrees><LongitudeDegrees>-72.650505</LongitudeDegrees></Position><AltitudeMeters>368.591</AltitudeMeters><DistanceMeters>3844.748</DistanceMeters><HeartRateBpm><Value>128</Value></HeartRateBpm>
