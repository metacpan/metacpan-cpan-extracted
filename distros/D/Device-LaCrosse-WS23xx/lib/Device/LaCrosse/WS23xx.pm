# -*- perl -*-
#
# Device::LaCrosse::WS23xx - interface to La Crosse WS-23xx weather stations
#
# $Id: 214 $
#
package Device::LaCrosse::WS23xx;

use 5.006;

use strict;
use warnings;
use Carp;
use Time::Local;
use Device::LaCrosse::WS23xx::MemoryMap;

(our $ME = $0) =~ s|^.*/||;

###############################################################################
# BEGIN user-customizable section

# The conversions we know how to do.  Format of this table is:
#
#    <from>    <to>(<precision>)   <expression>
#
# where:
#
#    from        name of units to convert FROM.  This must be one of the
#                units used in WS23xx/MemoryMap.pm
#
#    to          name of units to convert TO.  Feel free to add your own.
#                Say, m/s to furlongs/fortnight or even degrees to radians.
#
#    precision   how many significant digits to return
#
#    expression  mathematical expression using the variable '$value'
#
our $Conversions = <<'END_CONVERSIONS';
C	F(1)		$value * 9.0 / 5.0 + 32

hPa	inHg(2)		$value / 33.8638864
hPa	mmHg(1)		$value / 1.3332239

m/s	kph(1)		$value * 3.6
m/s	kt(1)		$value * 1.9438445
m/s	mph(1)		$value * 2.2369363

mm	in(2)		$value / 25.4
END_CONVERSIONS

# END   user-customizable section
###############################################################################

require Exporter;
require DynaLoader;

use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT);

@ISA = qw(Exporter DynaLoader);

%EXPORT_TAGS = ( );
@EXPORT_OK   = ( );
@EXPORT      = ( );

our $VERSION = '0.10';

our $PKG = __PACKAGE__;		# For interpolating into error messages

bootstrap Device::LaCrosse::WS23xx $VERSION;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $device = shift                     # in: mandatory arg
      or croak "Usage: ".__PACKAGE__."->new( \"/dev/LACROSSE-DEV-NAME\" )";

    # Is $device path a plain (not device) file with a special name?
    if ($device =~ /map.*\.txt/  &&  ! -c $device) {
	return Device::LaCrosse::WS23xx::Fake->new($device, @_);
    }

    my $self = {
	path => $device,
	mmap => Device::LaCrosse::WS23xx::MemoryMap->new(),

	cache_expire    => 10,
	cache_readahead => 30,
    };

    # Any cache parameters included?
    if (@_) {
	my %param;
	if (@_ % 2 == 0) {
	    %param = @_;
	}
	elsif (@_ == 1) {
	    ref($_[0]) eq 'HASH'
		or croak "Second arg to ->new() must be a hashref";
	    %param = %{$_[0]};
	}
	else {
	    croak "$PKG->new() takes options, but you need to read the docs";
	}

	if (my $n = delete $param{cache_expire}) {
	    $n =~ /^\s*(\d{1,3})\s*$/
		or croak "cache_expire must be a 1- to 3-digit number";
	    $self->{cache_expire} = $1;
	}

	if (my $n = delete $param{cache_readahead}) {
	    $n =~ /^\s*(\d{1,2})\s*$/
		or croak "cache_readahead must be a 1- or 2-digit number";
	    $n = $1;
	    if ($n > 30) {
		carp "cache_readahead is limited to 30 nybbles; truncating";
		$n = 30;
	    }
	    $self->{cache_readahead} = $n;
	}

	if (my $p = delete $param{trace}) {
	    if ($p eq '1') {
		my @lt = localtime;
		$p = sprintf(".ws23xx-trace.%04d-%02d-%02d_%02d%02d%02d",
			     $lt[5]+1900,$lt[4]+1,@lt[3,2,1,0]);
	    }
	    _ws_trace_path($p);
	}

	if (my @unknown = sort keys %param) {
	    croak "Unknown param '@unknown'";
	}
    }

    # Open and initialize the device.  If that fails, we'll get undef
    # and pass it along (hoping that $! is set).
    $self->{fh} = _ws_open($device)
	or return undef;

    return bless $self, $class;
}


#############
#  DESTROY  #  Destructor.  Call C code to close the filehandle.
#############
sub DESTROY {
    my $self = shift;

    if (defined $self->{fh}) {
	_ws_close($self->{fh})
	    or warn "$ME: Error closing $self->{path}: $!";
    }
}


sub _read_data {
    my $self    = shift;
    my $address = shift;
    my $length  = shift;

    if ($length > 30) {
	carp "cannot read more than 30 nybbles; truncating";
	$length = 30;
    }

    # See if we've already cached this address range
    if (my $cache = $self->{cache}) {
      CACHE_ENTRY:
	for (my $i=0; $i < @$cache; $i++) {
	    my $c = $cache->[$i];

	    # First, delete expired entries
	    if ($c->{expires} < time) {
		splice @$cache, $i, 1;
		last CACHE_ENTRY		if @$cache == 0;
		redo CACHE_ENTRY;
	    }

	    # Check range
	    if ($c->{address} <= $address) {
		if ($address+$length < $c->{address} + @{$c->{data}}) {
		    my $data = $c->{data};
		    my $start = $address - $c->{address};
		    return @{$data}[$start .. $start + $length - 1];
		}
	    }
	}
    }

    # Not cached (or expired).  Read the desired range, plus a few more.
    my $n_read = $self->{cache_readahead};
    my $expire = $self->{cache_expire};

    if (($n_read < $length) || ($expire == 0)) {
	$n_read = $length;
    }

    my @data = _ws_read($self->{fh}, $address, $n_read);

    # Preserve in our cache
    if ($expire != 0) {
	$self->{cache} ||= [];
	push @{ $self->{cache} }, {
	    address => $address,
	    data    => \@data,
	    expires => time + $self->{cache_expire},
	};
    }

    # Return desired address range
    return @data[0 .. $length-1];
}

sub get {
    my $self  = shift;
    my $field = shift
      or croak "Usage: $PKG->new( FIELD )";

    my $get = $self->{mmap}->find_field( $field )
	or croak "No such field, '$field'";

    my @data = $self->_read_data($get->{address}, $get->{count});

    # Convert to string context: (0, 3, 0xF, 9) becomes '03F9'.
    my $data = join('', map { sprintf "%X",$_ } @data);

    # Asked for raw data?  If called with 'raw' as second argument,
    # return the nybbles directly as they are.
    if (@_ && lc($_[0]) eq 'raw') {
	return wantarray ? @data
	                 : $data;
    }

    # Interpret.  This will be done inside an eval which may access
    # the variable $BCD.  $BCD is simply the sequence of data nybbles
    # read from the device, in string form.  Note that data nybbles
    # are returned Least Significant First.  So if @data = (0, 3, 2)
    # then $BCD will be '230' (two hundred and thirty), not '032'.
    my $BCD = reverse($data);
    $BCD =~ s/^0+//;
    $BCD = '0' if $BCD eq '';

    my $expr = $get->{expr};

    # Bug 41461 <https://rt.cpan.org/Public/Bug/Display.html?id=41461>
    # Every so often the unit returns "AA" as a data value, leading to:
    #    Argument "AA10" isn't numeric in division (/) at (eval 8) line 1
    # ...which isn't very helpful.
    # Try to detect those, and issue a better warning.  If we see any
    # non-decimal characters, issue a warning (if desired) and return undef.
    if ($BCD =~ /[^0-9]/ && $expr !~ /hex/) {
        warn "$ME: WARNING: device returned invalid '$BCD' for $field\n"
            if $^W;
        return;
    }

    # Special case for datetime: return a unix time_t
    sub _time_convert($$) {
        #                 YY      MM     DD    hh    mm
        if ($_[0] =~ m!^(\d{1,2})(\d\d)(\d\d)(\d\d)(\d\d)$!) {
            return timelocal( 0,$5,$4, $3, $2-1, $1+100);
        }

        carp "$ME: ->$_[1](): WARNING: bad datetime '$_[0]'";
        return 0;
    }

    # Special case for values with well-defined meanings:
    #    0=Foo, 1=Bar, 2=Fubar, ...
    if ($expr =~ /\d=.*,.*\d=/) {
	my @string_value;
	for my $pair (split(/\s*,\s*/, $expr)) {
	    # FIXME: don't die!  This is customer code.
	    $pair =~ /([0-9a-f])=(.*)/i or die;
	    $string_value[hex($1)] = $2;
	}

	my $val = $string_value[hex($BCD)];
	if (defined $val) {
	    return $val;
	}
	else {
	    return "undefined($BCD)";
	}
    }

    # Interpret the equation, e.g. $BCD / 10.0
    my $val = eval($expr);
    if ($@) {
	croak "$ME: ->$field(): eval( $get->{expr} ) died: $@";
    }

    # Asked to convert units?
    if (@_) {
	return _unit_convert($val, $get->{units}, $_[0]);
    }

    return $val;
}


sub _unit_convert {
    my $value     = shift;
    my $units_in  = shift;
    my $units_out = shift;

    # Identity?
    if (lc($units_in) eq lc($units_out)) {
	return $value;
    }

    our %Convert;
    # First time through?  Read and parse the conversion table at top
    if (! keys %Convert) {
	for my $line (split "\n", $Conversions) {
	    next if $line eq '';
	    $line =~ m!^(\S+)\s+(\S+)\((\d+)\)\s+(.*)!
	      or croak "Internal error: Cannot grok conversion '$line'";
	    push @{ $Convert{$1} }, { to => $2, precision => $3, expr => $4 };
	}
    }

    # No known conversions for this unit?
    if (! exists $Convert{$units_in}) {
	warn "$ME: Cannot convert '$units_in' to anything\n";
	return $value;
    }
    my @conversions = @{ $Convert{$units_in} };

    # There exists at least one conversion.  Do we have the one
    # requested by our caller?
    my @match = grep { lc($_->{to}) eq lc($units_out) } @conversions;
    if (! @match) {
	my @try = map { $_->{to} } @conversions;
	my $try = join ", ", @try;
	warn "$ME: Cannot convert '$units_in' to '$units_out'.  Try: $try\n";
	return $value;
    }

    my $newval = eval $match[0]->{expr};
    if ($@) {
	warn "$@";
	return $value;
    }

    return sprintf("%.*f", $match[0]->{precision}, $newval);
}

###############################################################################
# BEGIN tie() code for treating the ws23xx as a perl array

sub TIEARRAY {
    my $class = shift;
    my $ws    = shift;		# in: weatherstation object _or_ path

    my $ws_obj;
    if (ref($class)) {
	# Called as: 'tie @X, $ws'
	$ws_obj = $class;
    }
    elsif ($ws) {
	if (ref($ws)) {
	    if (ref($ws) =~ /^Device::LaCrosse::WS23xx/) {
		$ws_obj = $ws;
	    }
	    else {
		croak "Error: you called 'tie' with a strange object";
	    }
	}
	else {
	    # $ws is not a ref: assume it's a path
	    $ws_obj = $class->new($ws)
		or die "Cannot make a WS object out of $ws";
	}
    }
    else {
	# Called without a class object or a ws
	croak "Usage: tie \@X, [ WS obj | \"$PKG\", \"/dev/path\" ]";
    }

    my $self = { ws => $ws_obj };

    return bless $self, ref($class)||$class;
}

sub FETCH {
    my $self  = shift;
    my $index = shift;

    # FIXME: assert that 0 <= index <= MAX
    # FIXME: read and cache more than just 1
    my @data = $self->{ws}->_read_data($index, 1);

    return $data[0];
}

sub FETCHSIZE {
    return 0x13D0;
}

sub STORE {
    croak "Cannot (yet) write to WS23xx";
}

# END   tie() code for treating the ws23xx as a perl array
###############################################################################
# BEGIN fake-device handler for testing

package Device::LaCrosse::WS23xx::Fake;

use strict;
use warnings;
use Carp;
use Device::LaCrosse::WS23xx::MemoryMap;

our @ISA = qw(Device::LaCrosse::WS23xx);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $path = shift
      or croak "Usage: ".__PACKAGE__."->new( \"path_to_mem_map.txt\" )";

    my $self = {
        path     => $path,
	mmap     => Device::LaCrosse::WS23xx::MemoryMap->new(),
	fakedata => [],
    };

    open my $map_fh, '<', $path
      or croak "Cannot read $path: $!";
    while (my $line = <$map_fh>) {
	# E.g. 0019 0   alarm set flags
	if ($line =~ m!^([0-9a-f]{4})\s+([0-9a-f])\s*!i) {
	    $self->{fakedata}->[hex($1)] = hex($2);
	}
    }
    close $map_fh;

    return bless $self, $class;
}

sub _read_data {
    my $self    = shift;
    my $address = shift;
    my $length  = shift;

    return @{$self->{fakedata}}[$address .. $address+$length-1];
}

# END   fake-device handler for testing
###############################################################################

###############################################################################
# BEGIN documentation

=head1  NAME

Device::LaCrosse::WS23xx - read data from La Crosse weather station

=head1  SYNOPSIS

  use Device::LaCrosse::WS23xx;

  my $serial = "/dev/ttyUSB0";
  my $ws = Device::LaCrosse::WS23xx->new($serial)
      or die "Cannot communicate with $serial: $!\n";

  for my $field qw(Indoor_Temp Pressure_Rel Outdoor_Humidity) {
      printf "%-15s = %s\n", $field, $ws->get($field);
  }


=head1  DESCRIPTION

Device::LaCrosse::WS23xx provides a simple interface for
reading data from La Crosse Technology WS-2300 series
weather stations.  It is based on the Open2300 project,
but differs in several respects:

=over 2

=item *

Simplicity: the interface is simple and intuitive.  For hackers,
the Tied interface makes it easy to visualize the address space.
And you don't have to do any of the nybble shifting or masking:
it's all done for you.

=item *

Versatility: read the values you want, in the units you want.
Write a script that logs only the values you're interested in.

=item *

Caching: to minimize communication errors, Device::LaCrosse::WS23xx
reads large blocks and caches them for a few seconds.

=item *

Debugging: the La Crosse units don't always communicate too
reliably.  Use the B<trace> option to log serial I/O and track down
problems.

=back

=head1  CONSTRUCTOR

=over 4

=item B<new>( PATH [,OPTIONS] )

Establishes a connection to the weather station.
PATH is the serial line hooked up to the weather station.  Typical
values are F</dev/ttyS0>, F</dev/ttyUSB0>.

Available options are:

=over 3

=item B<cache_expire> =E<gt> SECONDS (default: B<10>)

How long to keep cached data.  If your WS-23xx uses a cabled connection,
you probably want to set this to 8 seconds or less.  If you use a wireless
connection, you might want to go as far as 128 seconds.  To disable
caching entirely, set to B<0>.

=item B<cache_readahead> =E<gt> NYBBLES (default: B<30>)

How much data to cache (max B<30>).

=item B<trace> =E<gt> PATH

Log all serial I/O to B<PATH>.  If PATH is just '1', a filename
is autogenerated of the form F<.ws23xx-trace.YYYY-MM-DD_hhmmss>.

=back

=back

=head1  METHODS

=over 4

=item   B<get>( FIELD [, UNITS] )

Retrieves a reading from the weather station, optionally
converting it to B<UNITS>.

For a list of the available FIELDs and their default units,
see L<Device::LaCrosse::WS23xx::MemoryMap>

Example:

    $h = $ws->get('Humidity_Indoor');             # e.g. '37'
    $p = $ws->get('Absolute_Pressure', 'inHg');	  # e.g. '23.20'

Only a few reasonable UNIT conversions are available:

     From       To
     ----       --
     C          F
     hPa        inHh, mmHg
     m/s        kph, mph, kt
     mm         in

It's trivial to add your own: see the module source.  (If you do add
conversions you think might be useful to others, please send them
to the module author).

=back

=head1	Tied Array Interface

The WS-2300 memory map can be visualized as a simple sequence
of addresses, each of which contains one data nybble.  In
other words, a perl array:

    my $serial = '/dev/ttyUSB0';
    tie my @ws, 'Device::LaCrosse::WS23xx', $serial
      or die "Cannot tie to $serial: $!\n";

Or, if you already have a $ws object, it's even simpler:

    tie my @ws, $ws;

Then access any WS-2300 memory cells as if the unit were
directly mapped to the array:

    print "backlight = $ws[0x16]\n";

    my @temp_in = @ws[0x346..0x349];
    print "@temp_in\n";		# e.g. '0 8 9 4'

Note that each value is a B<nybble>: a value between 0 and 0xF.

The tied interface is not really useful for actual weather station monitoring.
It is intended for hackers who want direct access to the device,
either for learning purposes or because Device::LaCrosse::WS23xx
is missing some important mappings.

The Tied interface is read-only.  If you have a need for read/write,
contact the author.

=head1  AUTHOR

Eduardo Santiago <esm@cpan.org>

=head1	ACKNOWLEDGMENTS

I am indebted to Kenneth Lavrsen, author of Open2300, for his
excellent code and documentation.  Thanks also to Claude
Ocquidant for very helpful notes on the WS-23xx protocol.

=head1 BUGS

No support for writing values to the device.  To reset the rain
counters or perform other write operations, use the Open2300 tools.

Please report any bugs or feature requests to C<bug-device-lacrosse-ws23xx at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-LaCrosse-WS23xx>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1	SEE ALSO

Open2300:
L<http://www.lavrsen.dk/twiki/bin/view/Open2300/WebHome>

Claude Ocquidant:
L<http://perso.orange.fr/claude.ocquidant/autrespages/leprotocol/protocol-eng.htm>

=cut

# END   documentation
###############################################################################

1;
