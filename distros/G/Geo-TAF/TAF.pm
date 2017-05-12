#
# A set of routine for decode TAF and METAR a bit better and more comprehensively
# than some other products I tried.
#
# $Id: TAF.pm,v 1.1.2.4 2003/02/03 17:26:37 minima Exp $
#
# Copyright (c) 2003 Dirk Koopman G1TLH
#

package Geo::TAF;

use 5.005;
use strict;
use vars qw($VERSION);

$VERSION = '1.04';


my %err = (
		   '1' => "No valid ICAO designator",
		   '2' => "Length is less than 10 characters",
		   '3' => "No valid issue time",
		   '4' => "Expecting METAR or TAF at the beginning", 
		  );

my %clt = (
		   SKC => 1,
		   CLR => 1,
		   NSC => 1,
		   BLU => 1,
		   WHT => 1,
		   GRN => 1,
		   YLO => 1,
		   AMB => 1,
		   RED => 1,
		   BKN => 1,
		   NIL => 1,
		  );

my %ignore = (
			  AUTO => 1,
			  COR => 1,
			 );

		   
# Preloaded methods go here.

sub new
{
	my $pkg = shift;
	my $self = bless {@_}, $pkg;
	$self->{chunk_package} ||= "Geo::TAF::EN";
	return $self;
}

sub metar
{
	my $self = shift;
	my $l = shift;
	return 2 unless length $l > 10;
	$l = 'METAR ' . $l unless $l =~ /^\s*(?:METAR|TAF)\s/i;
	return $self->decode($l);
}

sub taf
{
	my $self = shift;
	my $l = shift;
	return 2 unless length $l > 10;
	$l = 'TAF ' . $l unless $l =~ /^\s*(?:METAR|TAF)\s/i;
	return $self->decode($l);
}

sub as_string
{
	my $self = shift;
	return join ' ', $self->as_strings;
}

sub as_strings
{
	my $self = shift;
	my @out;
	for (@{$self->{chunks}}) {
		push @out, $_->as_string;
	}
	return @out;
}

sub chunks
{
	my $self = shift;
	return exists $self->{chunks} ? @{$self->{chunks}} : ();
}

sub as_chunk_strings
{
	my $self = shift;
	my @out;
	
	for (@{$self->{chunks}}) {
		push @out, $_->as_chunk;
	}
	return @out;
}

sub as_chunk_string
{
	my $self = shift;
	return join ' ', $self->as_chunk_strings;
}

sub raw
{
	return shift->{line};
}

sub is_weather
{
	return $_[0] =~ /^\s*(?:(?:METAR|TAF)\s+)?[A-Z]{4}\s+\d{6}Z?\s+/;
}

sub errorp
{
	my $self = shift;
	my $code = shift;
	return $err{"$code"};
}

# basically all metars and tafs are the same, except that a metar is short
# and a taf can have many repeated sections for different times of the day
sub decode
{
	my $self = shift;
	my $l = uc shift;

	$l =~ s/=$//;
	
	my @tok = split /\s+/, $l;

	$self->{line} = join ' ', @tok;
	
	
	# do we explicitly have a METAR or a TAF
	my $t = shift @tok;
	if ($t eq 'TAF') {
		$self->{taf} = 1;
	} elsif ($t eq 'METAR') {
		$self->{taf} = 0;
	} else {
	    return 4;
	}

	# next token is the ICAO dseignator
	$t = shift @tok;
	if ($t =~ /^[A-Z]{4}$/) {
		$self->{icao} = $t;
	} else {
		return 1;
	}

	# next token is an issue time
	$t = shift @tok;
	if (my ($day, $time) = $t =~ /^(\d\d)(\d{4})Z?$/) {
		$self->{day} = $day;
		$self->{time} = _time($time);
	} else {
		return 3;
	}

	# if it is a TAF then expect a validity (may be missing)
	if ($self->{taf}) {
		if (my ($vd, $vfrom, $vto) = $tok[0] =~ /^(\d\d)(\d\d)(\d\d)$/) {
			$self->{valid_day} = $vd;
			$self->{valid_from} = _time($vfrom * 100);
			$self->{valid_to} = _time($vto * 100);
			shift @tok;
		} 
	}

	# we are now into the 'list' of things that can repeat over and over

	my @chunk = (
				 $self->_chunk('HEAD', $self->{taf} ? 'TAF' : 'METAR', 
							   $self->{icao}, $self->{day}, $self->{time})
				);
	
	push @chunk, $self->_chunk('VALID', $self->{valid_day}, $self->{valid_from}, 
							   $self->{valid_to}) if $self->{valid_day};

	while (@tok) {
		$t = shift @tok;
		
		# temporary 
		if ($t eq 'TEMPO' || $t eq 'BECMG') {
			
			# next token may be a time if it is a taf
			my ($from, $to);
			if (@tok && (($from, $to) = $tok[0] =~ /^(\d\d)(\d\d)$/)) {
				if ($self->{taf} && $from >= 0 && $from <= 24 && $to >= 0 && $to <= 24) {
					shift @tok;
					$from = _time($from * 100);
					$to = _time($to * 100);
				} else {
					undef $from;
					undef $to;
				}
			}
			push @chunk, $self->_chunk($t, $from, $to);			

		# ignore
		} elsif ($ignore{$t}) {
			;
			
        # no sig weather
		} elsif ($t eq 'NOSIG' || $t eq 'NSW') {
			push @chunk, $self->_chunk('WEATHER', 'NOSIG');

		# specific broken on its own
		} elsif ($t eq 'BKN') {
			push @chunk, $self->_chunk('WEATHER', $t);
			
        # other 3 letter codes
		} elsif ($clt{$t}) {
			push @chunk, $self->_chunk('CLOUD', $t);
			
		# EU CAVOK viz > 10000m, no cloud, no significant weather
		} elsif ($t eq 'CAVOK') {
			$self->{viz_dist} ||= ">10000";
			$self->{viz_units} ||= 'm';
			push @chunk, $self->_chunk('CLOUD', 'CAVOK');

        # RMK group (end for now)
		} elsif ($t eq 'RMK') {
			last;

        # from
        } elsif (my ($time) = $t =~ /^FM(\d\d\d\d)$/ ) {
			push @chunk, $self->_chunk('FROM', _time($time));

        # Until
        } elsif (($time) = $t =~ /^TL(\d\d\d\d)$/ ) {
			push @chunk, $self->_chunk('TIL', _time($time));

        # probability
        } elsif (my ($percent) = $t =~ /^PROB(\d\d)$/ ) {

			# next token may be a time if it is a taf
			my ($from, $to);
			if (@tok && (($from, $to) = $tok[0] =~ /^(\d\d)(\d\d)$/)) {
				if ($self->{taf} && $from >= 0 && $from <= 24 && $to >= 0 && $to <= 24) {
					shift @tok;
					$from = _time($from * 100);
					$to = _time($to * 100);
				} else {
					undef $from;
					undef $to;
				}
			}
			push @chunk, $self->_chunk('PROB', $percent, $from, $to);

        # runway
        } elsif (my ($sort, $dir) = $t =~ /^(RWY?|LDG)(\d\d[RLC]?)$/ ) {
			push @chunk, $self->_chunk('RWY', $sort, $dir);

		# a wind group
		} elsif (my ($wdir, $spd, $gust, $unit) = $t =~ /^(\d\d\d|VRB)(\d\d)(?:G(\d\d))?(KT|MPH|MPS|KMH)$/) {
			
			my ($fromdir, $todir);
			
			if	(@tok && (($fromdir, $todir) = $tok[0] =~ /^(\d\d\d)V(\d\d\d)$/)) {
				shift @tok;
			}
			
			# it could be variable so look at the next token

			$spd = 0 + $spd;
			$gust = 0 + $gust if defined $gust;
			$unit = ucfirst lc $unit;
			$unit = 'm/sec' if $unit eq 'Mps';
			$self->{wind_dir} ||= $wdir;
			$self->{wind_speed} ||= $spd;
			$self->{wind_gusting} ||= $gust;
			$self->{wind_units} ||= $unit;
			push @chunk, $self->_chunk('WIND', $wdir, $spd, $gust, $unit, $fromdir, $todir);
			
		# pressure 
		} elsif (my ($u, $p, $punit) = $t =~ /^([QA])(?:NH)?(\d\d\d\d)(INS?)?$/) {

			$p = 0 + $p;
			if ($u eq 'A' || $punit && $punit =~ /^I/) {
				$p = sprintf "%.2f", $p / 100;
				$u = 'in';
			} else {
				$u = 'hPa';
			}
			$self->{pressure} ||= $p;
			$self->{pressure_units} ||= $u;
			push @chunk, $self->_chunk('PRESS', $p, $u);

		# viz group in metres
		} elsif (my ($viz, $mist) = $t =~ m!^(\d\d\d\d[NSEW]{0,2})([A-Z][A-Z])?$!) {
			$viz = $viz eq '9999' ? ">10000" : 0 + $viz;
			$self->{viz_dist} ||= $viz;
			$self->{viz_units} ||= 'm';
			push @chunk, $self->_chunk('VIZ', $viz, 'm');
			push @chunk, $self->_chunk('WEATHER', $mist) if $mist;

		# viz group in KM
		} elsif (($viz) = $t =~ m!^(\d+)KM$!) {
			$viz = $viz eq '9999' ? ">10000" : 0 + $viz;
			$self->{viz_dist} ||= $viz;
			$self->{viz_units} ||= 'Km';
			push @chunk, $self->_chunk('VIZ', $viz, 'Km');

		# viz group in miles and faction of a mile with space between
		} elsif (my ($m) = $t =~ m!^(\d)$!) {
			my $viz;
			if (@tok && (($viz) = $tok[0] =~ m!^(\d/\d)SM$!)) {
				shift @tok;
				$viz = "$m $viz";
				$self->{viz_dist} ||= $viz;
				$self->{viz_units} ||= 'miles';
				push @chunk, $self->_chunk('VIZ', $viz, 'miles');
			}
			
		# viz group in miles (either in miles or under a mile)
		} elsif (my ($lt, $mviz) = $t =~ m!^(M)?(\d+(:?/\d)?)SM$!) {
			$mviz = '<' . $mviz if $lt;
			$self->{viz_dist} ||= $mviz;
			$self->{viz_units} ||= 'Stat. Miles';
			push @chunk, $self->_chunk('VIZ', $mviz, 'Miles');
			

		# runway visual range
		} elsif (my ($rw, $rlt, $range, $vlt, $var, $runit, $tend) = $t =~ m!^R(\d\d[LRC]?)/([MP])?(\d\d\d\d)(?:V([MP])(\d\d\d\d))?(?:(FT)/?)?([UND])?$!) {
			$runit = 'm' unless $runit;
			$runit = lc $unit;
			$range = "<$range" if $rlt && $rlt eq 'M';
			$range = ">$range" if $rlt && $rlt eq 'P';
			$var = "<$var" if $vlt && $vlt eq 'M';
			$var = ">$var" if $vlt && $vlt eq 'P';
			push @chunk, $self->_chunk('RVR', $rw, $range, $var, $runit, $tend);
		
		# weather
		} elsif (my ($deg, $w) = $t =~ /^(\+|\-|VC)?([A-Z][A-Z]{1,4})$/) {
			push @chunk, $self->_chunk('WEATHER', $deg, $w =~ /([A-Z][A-Z])/g);
			 
        # cloud and stuff 
		} elsif (my ($amt, $height, $cb) = $t =~ m!^(FEW|SCT|BKN|OVC|SKC|CLR|VV|///)(\d\d\d|///)(CB|TCU)?$!) {
			push @chunk, $self->_chunk('CLOUD', $amt, $height eq '///' ? 0 : $height * 100, $cb) unless $amt eq '///' && $height eq '///';

		# temp / dew point
		} elsif (my ($ms, $t, $n, $d) = $t =~ m!^(M)?(\d\d)/(M)?(\d\d)?$!) {
			$t = 0 + $t;
			$d = 0 + $d;
			$t = -$t if defined $ms;
			$d = -$d if defined $d && defined $n;
			$self->{temp} ||= $t;
			$self->{dewpoint} ||= $d;
			push @chunk, $self->_chunk('TEMP', $t, $d);
		} 
		
	}			
	$self->{chunks} = \@chunk;
	return undef;	
}

sub _chunk
{
	my $self = shift;
	my $pkg = shift;
	no strict 'refs';
	$pkg = $self->{chunk_package} . '::' . $pkg;
	return $pkg->new(@_);
}

sub _time
{
	return sprintf "%02d:%02d", unpack "a2a2", sprintf "%04d", shift;
}

# accessors
sub AUTOLOAD
{
	no strict;
	my ($package, $name) = $AUTOLOAD =~ /^(.*)::(\w+)$/;
	return if $name eq 'DESTROY';

	*$AUTOLOAD = sub {return $_[0]->{$name}};
    goto &$AUTOLOAD;
}

#
# these are the translation packages
#
# First the factory method
#

package Geo::TAF::EN;

sub new
{
	my $pkg = shift;
	return bless [@_], $pkg; 
}

sub as_chunk
{
	my $self = shift;
	my ($n) = (ref $self) =~ /::(\w+)$/;
	return '[' . join(' ', $n, map {defined $_ ? $_ : '?'} @$self) . ']';
}

sub as_string
{
	my $self = shift;
	my ($n) = (ref $self) =~ /::(\w+)$/;
	return join ' ', ucfirst $n, map {defined $_ ? $_ : ()} @$self;
}

sub day
{
	my $pkg = shift;
	my $d = sprintf "%d", ref($pkg) ? shift : $pkg;
	if ($d =~ /1$/) {
		return "${d}st";
	} elsif ($d =~ /2$/) {
		return "${d}nd";
	} elsif ($d =~ /3$/) {
		return "${d}rd";
	}
	return "${d}th";
}


package Geo::TAF::EN::HEAD;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

sub as_string
{
	my $self = shift;
	return "$self->[0] for $self->[1] issued at $self->[3] on " . $self->day($self->[2]);
}

package Geo::TAF::EN::VALID;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

sub as_string
{
	my $self = shift;
	return "valid from $self->[1] to $self->[2] on " . $self->day($self->[0]);
}


package Geo::TAF::EN::WIND;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

# direction, $speed, $gusts, $unit, $fromdir, $todir
sub as_string
{
	my $self = shift;
	my $out = "wind";
	$out .= $self->[0] eq 'VRB' ? " variable" : " $self->[0]";
    $out .= " varying between $self->[4] and $self->[5]" if defined $self->[4];
	$out .= ($self->[0] eq 'VRB' ? '' : " degrees") . " at $self->[1]";
	$out .= " gusting $self->[2]" if defined $self->[2];
	$out .= $self->[3];
	return $out;
}

package Geo::TAF::EN::PRESS;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

# $pressure, $unit
sub as_string
{
	my $self = shift;
	return "QNH $self->[0]$self->[1]";
}

# temperature, dewpoint
package Geo::TAF::EN::TEMP;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

sub as_string
{
	my $self = shift;
	my $out = "temperature $self->[0]C";
	$out .= " dewpoint $self->[1]C" if defined $self->[1];

	return $out;
}

package Geo::TAF::EN::CLOUD;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

my %st = (
		  VV => 'vertical visibility',
		  SKC => "no cloud",
		  CLR => "no cloud no significant weather",
		  SCT => "3-4 oktas",
		  BKN => "5-7 oktas",
		  FEW => "0-2 oktas",
		  OVC => "8 oktas overcast",
		  CAVOK => "no cloud below 5000ft >10Km visibility no significant weather (CAVOK)",
		  CB => 'thunder clouds',
          TCU => 'towering cumulus',
		  NSC => 'no significant cloud',
		  BLU => '3 oktas at 2500ft 8Km visibility',
		  WHT => '3 oktas at 1500ft 5Km visibility',
		  GRN => '3 oktas at 700ft 3700m visibility',
		  YLO => '3 oktas at 300ft 1600m visibility',
		  AMB => '3 oktas at 200ft 800m visibility',
		  RED => '3 oktas at <200ft <800m visibility',
		  NIL => 'no weather',
		  '///' => 'some',
		 );

sub as_string
{
	my $self = shift;
	return $st{$self->[0]} if @$self == 1;
	return $st{$self->[0]} . " $self->[1]ft" if $self->[0] eq 'VV';
	return $st{$self->[0]} . " cloud at $self->[1]ft" . ((defined $self->[2]) ? " with $st{$self->[2]}" : "");
}

package Geo::TAF::EN::WEATHER;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

my %wt = (
		  '+' => 'heavy',
          '-' => 'light',
          'VC' => 'in the vicinity',

		  MI => 'shallow',
		  PI => 'partial',
		  BC => 'patches of',
		  DR => 'low drifting',
		  BL => 'blowing',
		  SH => 'showers',
		  TS => 'thunderstorms containing',
		  FZ => 'freezing',
		  RE => 'recent',
		  
		  DZ => 'drizzle',
		  RA => 'rain',
		  SN => 'snow',
		  SG => 'snow grains',
		  IC => 'ice crystals',
		  PE => 'ice pellets',
		  GR => 'hail',
		  GS => 'small hail/snow pellets',
		  UP => 'unknown precip',
		  
		  BR => 'mist',
		  FG => 'fog',
		  FU => 'smoke',
		  VA => 'volcanic ash',
		  DU => 'dust',
		  SA => 'sand',
		  HZ => 'haze',
		  PY => 'spray',
		  
		  PO => 'dust/sand whirls',
		  SQ => 'squalls',
		  FC => 'tornado',
		  SS => 'sand storm',
		  DS => 'dust storm',
		  '+FC' => 'water spouts',
		  WS => 'wind shear',
		  'BKN' => 'broken',

		  'NOSIG' => 'no significant weather',
		  
		 );

sub as_string
{
	my $self = shift;
	my @out;

	my ($vic, $shower);
	my @in;
	push @in, @$self;
	
	while (@in) {
		my $t = shift @in;

		if (!defined $t) {
			next;
		} elsif ($t eq 'VC') {
			$vic++;
			next;
		} elsif ($t eq 'SH') {
			$shower++;
			next;
		} elsif ($t eq '+' && $self->[0] eq 'FC') {
			push @out, $wt{'+FC'};
			shift;
			next;
		}
		
		push @out, $wt{$t};
		
		if (@out && $shower) {
			$shower = 0;
			push @out, $wt{'SH'};
		}
	}
	push @out, $wt{'VC'} if $vic;

	return join ' ', @out;
}

package Geo::TAF::EN::RVR;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

sub as_string
{
	my $self = shift;
	my $out = "visual range on runway $self->[0] is $self->[1]$self->[3]";
	$out .= " varying to $self->[2]$self->[3]" if defined $self->[2];
	if (defined $self->[4]) {
		$out .= " decreasing" if $self->[4] eq 'D';
		$out .= " increasing" if $self->[4] eq 'U';
	}
	return $out;
}

package Geo::TAF::EN::RWY;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

sub as_string
{
	my $self = shift;
	my $out = $self->[0] eq 'LDG' ? "landing " : '';  
	$out .= "runway $self->[1]";
	return $out;
}

package Geo::TAF::EN::PROB;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

sub as_string
{
	my $self = shift;
    
	my $out = "probability $self->[0]%";
	$out .= " $self->[1] to $self->[2]" if defined $self->[1];
	return $out;
}

package Geo::TAF::EN::TEMPO;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

sub as_string
{
	my $self = shift;
	my $out = "temporarily";
	$out .= " $self->[0] to $self->[1]" if defined $self->[0];

	return $out;
}

package Geo::TAF::EN::BECMG;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

sub as_string
{
	my $self = shift;
	my $out = "becoming";
	$out .= " $self->[0] to $self->[1]" if defined $self->[0];

	return $out;
}

package Geo::TAF::EN::VIZ;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

sub as_string
{
    my $self = shift;

    return "visibility $self->[0]$self->[1]";
}

package Geo::TAF::EN::FROM;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

sub as_string
{
    my $self = shift;

    return "from $self->[0]";
}

package Geo::TAF::EN::TIL;
use vars qw(@ISA);
@ISA = qw(Geo::TAF::EN);

sub as_string
{
    my $self = shift;

    return "until $self->[0]";
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Geo::TAF - Decode METAR and TAF strings

=head1 SYNOPSIS

  use strict;
  use Geo::TAF;

  my $t = new Geo::TAF;

  $t->metar("EGSH 311420Z 29010KT 1600 SHSN SCT004 BKN006 01/M00 Q1021");
  or
  $t->taf("EGSH 311205Z 311322 04010KT 9999 SCT020
     TEMPO 1319 3000 SHSN BKN008 PROB30
     TEMPO 1318 0700 +SHSN VV///
     BECMG 1619 22005KT");
  or 
  $t->decode("METAR EGSH 311420Z 29010KT 1600 SHSN SCT004 BKN006 01/M00 Q1021");
  or
  $t->decode("TAF EGSH 311205Z 311322 04010KT 9999 SCT020
     TEMPO 1319 3000 SHSN BKN008 PROB30
     TEMPO 1318 0700 +SHSN VV///
     BECMG 1619 22005KT");

  foreach my $c ($t->chunks) {
	  print $c->as_string, ' ';
  }
  or
  print $self->as_string;

  foreach my $c ($t->chunks) {
	  print $c->as_chunk, ' ';
  }
  or 
  print $self->as_chunk_string;

  my @out = $self->as_strings;
  my @out = $self->as_chunk_strings;
  my $line = $self->raw;
  print Geo::TAF::is_weather($line) ? 1 : 0;

=head1 ABSTRACT

Geo::TAF decodes aviation METAR and TAF weather forecast code 
strings into English or, if you sub-class, some other language.

=head1 DESCRIPTION

METAR (Routine Aviation weather Report) and TAF (Terminal Area
weather Report) are ascii strings containing codes describing
the weather at airports and weather bureaus around the world.

This module attempts to decode these reports into a form of 
English that is hopefully more understandable than the reports
themselves. 

It is possible to sub-class the translation routines to enable
translation to other langauages. 

=head1 METHODS

=over

=item new(%args)

Constructor for the class. Each weather announcement will need
a new constructor. 

If you sub-class the built-in English translation routines then 
you can pick this up by called the constructor thus:-
 
  my $t = Geo::TAF->new(chunk_package => 'Geo::TAF::ES');

or whatever takes your fancy.

=item decode($line)

The main routine that decodes a weather string. It expects a
string that begins with either the word C<METAR> or C<TAF>.
It creates a decoded form of the weather string in the object.

There are a number of fixed fields created and also array
of chunks L<chunks()> of (as default) C<Geo::TAF::EN>.

You can decode these manually or use one of the built-in routines.

This method returns undef if it is successful, a number otherwise.
You can use L<errorp($r)> routine to get a stringified
version. 

=item metar($line)

This simply adds C<METAR> to the front of the string and calls
L<decode()>.

=item taf($line)

This simply adds C<TAF> to the front of the string and calls
L<decode()>.

It makes very little difference to the decoding process which
of these routines you use. It does, however, affect the output
in that it will mark it as the appropriate type of report.

=item as_string()

Returns the decoded weather report as a human readable string.

This is probably the simplest and most likely of the output
options that you might want to use. See also L<as_strings()>.

=item as_strings()

Returns an array of strings without separators. This simply
the decoded, human readable, normalised strings presented
as an array.

=item as_chunk_string()

Returns a human readable version of the internal decoded,
normalised form of the weather report. 

This may be useful if you are doing something special, but
see L<chunks()> or L<as_chunk_strings()> for a procedural 
approach to accessing the internals.  

Although you can read the result, it is not, officially,
human readable.

=item as_chunk_strings()

Returns an array of the stringified versions of the internal
normalised form without separators.. This simply
the decoded (English as default) normalised strings presented
as an array.

=item chunks()

Returns a list of (as default) C<Geo::TAF::EN> objects. You 
can use C<$c-E<gt>as_string> or C<$c-E<gt>as_chunk> to 
translate the internal form into something readable. There
is also a routine (C<$c-E<gt>day>)to turn a day number into 
things like "1st", "2nd" and "24th". 

If you replace the English versions of these objects then you 
will need at an L<as_string()> method.

=item raw()

Returns the (cleaned up) weather report. It is cleaned up in the
sense that all whitespace is reduced to exactly one space 
character.

=item errorp($r)

Returns a stringified version of any error returned by L<decode()>

=back

=head1 ACCESSORS

=over

=item taf()

Returns whether this object is a taf or not.

=item icao()

Returns the ICAO code contained in the weather report

=item day()

Returns the day of the month of this report

=item time()

Returns the issue time of this report

=item valid_day()

Returns the day this report is valid for (if there is one).

=item valid_from()

Returns the time from which this report is valid for (if there is one).

=item valid_to()

Returns the time to which this report is valid for (if there is one).

=item viz_dist()

Returns the minimum visibility, if present.

=item viz_units()

Returns the units of the visibility information.

=item wind_dir()

Returns the wind direction in degrees, if present.

=item wind_speed()

Returns the wind speed.

=item wind_units()

Returns the units of wind_speed.

=item wind_gusting()

Returns any wind gust speed. It is possible to have L<wind_speed()> 
without gust information.

=item pressure()

Returns the QNH (altimeter setting atmospheric pressure), if present.

=item pressure_units()

Returns the units in which L<pressure()> is messured.

=item temp()

Returns any temperature present.

=item dewpoint()

Returns any dewpoint present.

=back

=head1 ROUTINES

=over

=item is_weather($line)

This is a routine that determines, fairly losely, whether the
passed string is likely to be a weather report;

This routine is not exported. You must call it explicitly.

=back

=head1 SEE ALSO

L<Geo::METAR>

For a example of a weather forecast from the Norwich Weather 
Centre (EGSH) see L<http://www.tobit.co.uk>

For data see L<ftp://weather.noaa.gov/data/observations/metar/>
L<ftp://weather.noaa.gov/data/forecasts/taf/> and also
L<ftp://weather.noaa.gov/data/forecasts/shorttaf/>

To find an ICAO code for your local airport see
L<http://www.ar-group.com/icaoiata.htm>

=head1 AUTHOR

Dirk Koopman, L<mailto:djk@tobit.co.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003 by Dirk Koopman, G1TLH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
