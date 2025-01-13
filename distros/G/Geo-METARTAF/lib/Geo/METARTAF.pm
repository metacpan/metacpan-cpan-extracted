# A module to decode North American METAR's and TAF's
# Based on Geo::TAF (Designed for European METAR's/TAF's)
# but updated with information from Transport Canada AIM.
# These changes may cause the module to fail with European data.
# Copyright (c) 2025 Peter Carter

package Geo::METARTAF;

use 5.005;
use strict;
use vars qw($VERSION);

$VERSION = '1.01';

my %err = (
   '0' => "",
   '1' => "No valid ICAO designator",
   '2' => "Length is less than 15 characters",
   '3' => "No valid issue time",
   '4' => "Expecting METAR, SPECI, or TAF at the beginning", 
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
   COR  => 1,
);
		   
# Module methods

# Create a new object
sub new
{
	my $pkg = shift;
	my $self = bless {@_}, $pkg;
	$self->{decode_language} ||= "Geo::METARTAF::EN";
	return $self;
}

# Precede input data with 'METAR' and decode
sub metar
{
	my $self = shift;
	my $l = shift;
	$l = 'METAR ' . $l unless $l =~ /^\s*(?:METAR|TAF|SPECI)\s/i;
	return $self->decode($l);
}

# Precede input data with 'SPECI' and decode
sub speci
{
	my $self = shift;
	my $l = shift;
	$l = 'SPECI ' . $l unless $l =~ /^\s*(?:METAR|TAF|SPECI)\s/i;
	return $self->decode($l);
}

# Precede input data with 'TAF' and decode
sub taf
{
	my $self = shift;
	my $l = shift;
	$l = 'TAF ' . $l unless $l =~ /^\s*(?:METAR|TAF|SPECI)\s/i;
	return $self->decode($l);
}

# Format and print decoded data as a string
sub as_string
{
	my $self = shift;
   my $decoded_data = '';
   my $subsection = '';
   for (@{$self->{sections}})  {
      my $line = $_->as_string;
      if ($line =~ /^~/)  {
         my ($section_name, $section_data) = $line =~ /^~(.+?:)(.+)/;
         if ($subsection eq $section_name)  {
            $decoded_data .= "     $section_data\n";
         }
         else  {
            $decoded_data .= "   $section_name\n";
            $decoded_data .= "     $section_data\n";
            $subsection = $section_name;
         }
      }
      else  {
         $decoded_data .= "$line\n";
         $subsection = '';
      }
   }
   return $decoded_data;
}

# Format and print decoded data as an HTML table
sub as_html
{
	my $self = shift;
   my $decoded_data = '<table class="metartaf_table">' . "\n";
   my $subsection = '';
   my $endTr = 0;
   for (@{$self->{sections}})  {
      my $line = $_->as_string;
      chomp $line;
      if ($line =~ /^~/)  {
         my ($section_name, $section_data) = $line =~ /^~(.+?:)(.+)/;
         if ($subsection eq $section_name)  {
            $decoded_data .= '<br>' . $section_data;
         }
         else  {
            $decoded_data .= "</td>\n</tr>\n" if ($endTr);
            $decoded_data .= "<tr>\n";
            $decoded_data .= '   <td class="metartaf_data_type">' . $section_name . '</td>' . "\n";
            $decoded_data .= '   <td class="metartaf_data_info">' . $section_data;
            $subsection = $section_name;
            $endTr = 1;
         }
      }
      else  {
         if ($endTr)  {
            $decoded_data .= "</td>\n</tr>\n";
            $endTr = 0;
         }
         if ($line =~ /METAR|SPECI|TAF/)  {
            $decoded_data .= "<tr>\n" . '<td colspan="2" class="metartaf_report">' . $line . "</td>\n</tr>\n";
         }
         elsif ($line =~ /^Valid/)  {
            $decoded_data .= "<tr>\n" . '<td colspan="2" class="metartaf_validity">' . $line . "</td>\n</tr>\n";
         }
         elsif ($line =~ /^Temporarily/)  {
            $decoded_data .= "<tr>\n" . '<td colspan="2" class="metartaf_tempo">' . $line . "</td>\n</tr>\n";
         }
         elsif ($line =~ /^Probability/)  {
            $decoded_data .= "<tr>\n" . '<td colspan="2" class="metartaf_prob">' . $line . "</td>\n</tr>\n";
         }
         elsif ($line =~ /^Becoming/)  {
            $decoded_data .= "<tr>\n" . '<td colspan="2" class="metartaf_becmg">' . $line . "</td>\n</tr>\n";
         }
         elsif ($line =~ /^From/)  {
            $decoded_data .= "<tr>\n" . '<td colspan="2" class="metartaf_fm">' . $line . "</td>\n</tr>\n";
         }
         elsif ($line =~ /^Until/)  {
            $decoded_data .= "<tr>\n" . '<td colspan="2" class="metartaf_tl">' . $line . "</td>\n</tr>\n";
         }
         else  {
            $decoded_data .="<tr>\n" . '<td colspan="2" class="metartaf_unknown">' . $line . "</td>\n</tr>\n";
         }
         $subsection = '';
      }
   }
   $decoded_data .= "</td>\n</tr>\n" if ($endTr);
   $decoded_data .= "</table>";
   $decoded_data =~ s/°/&deg;/g if $decoded_data =~ /°/;
   return $decoded_data;
}

# Return input data with excess spaces removed
sub minimal
{
	return shift->{line};
}

# Return error codes
sub errorp
{
	my $self = shift;
	return $err{$self->error_code} . "\n";
}

# Decode input data
sub decode
{
	my $self = shift;
	my $l = uc shift;

	$l =~ s/=$//;

   unless (length $l > 15)  {
      $self->{error_code} = 2;
      return;
   }
	
	my @tok = split /\s+/, $l;

	$self->{line} = join ' ', @tok;
	
	# Do we explicitly have a METAR, SPECI, or a TAF
	my $t = shift @tok;
	if ($t eq 'TAF') {
		$self->{taf} = 1;
      $self->{report_type} = $t;
	} elsif ($t eq 'METAR' || $t eq 'SPECI') {
		$self->{taf} = 0;
      $self->{report_type} = $t;
	} else {
	   $self->{error_code} = 4;
		return;
	}

   # The next token may be "AMD" (amended) if it is a TAF
   if ($self->{taf} && $tok[0] eq 'AMD')  {
      $self->{amendedOrCorrected} = '(Amended/Corrected)';
      shift @tok;
   }

	# The next token is the ICAO designator
	$t = shift @tok;
	if ($t =~ /^[A-Z]{4}$/) {
		$self->{icao} = $t;
	} else {
      $self->{error_code} = 1;
		return;
	}

	# The next token is the issue / observation date and time
	$t = shift @tok;
	if (my ($day, $time) = $t =~ /^(\d\d)(\d{4})Z?$/) {
		$self->{day} = $day;
		$self->{time} = _time($time) . ' UTC';
	} else {
		$self->{error_code} = 3;
		return;
	}

   # The next token may be "CCx" (corrected) and/or AUTO (AWOS) if it is a METAR/SPECI
   while (!$self->{taf} && $tok[0] =~ /^AUTO|CC[A-Z]$/)  {
      if ($tok[0] eq 'AUTO')  {
         $self->{amendedOrCorrected} .= 'reported by AWOS ';
         shift @tok;
      }
      else  {
         my ($revLetter) = $tok[0] =~ /CC([A-Z])/;
         my $revNumber = ord($revLetter) - 64;
         $self->{amendedOrCorrected} .= "(Correction # $revNumber) ";
         shift @tok;
      }
   }

	# If it is a TAF then expect a validity period
	if ($self->{taf}) {
		if (my ($v_from_day, $v_from_hour, $v_to_day, $v_to_hour) = $tok[0] =~ /^(\d{2})(\d{2})\/(\d{2})(\d{2})$/) {
			$self->{valid_from_day} = $v_from_day;
         $self->{valid_from_hour} = _time($v_from_hour * 100) . ' UTC';
         $self->{valid_to_day} = $v_to_day;
			$self->{valid_to_hour} = _time($v_to_hour * 100) . ' UTC';
         $self->{valid_from} = "$v_from_hour:00 UTC on $v_from_day";
         $self->{valid_to} = "$v_to_hour:00 UTC on $v_to_day";
			shift @tok;
      }
	}

	# Next is the 'list' of things that can repeat over and over

   my $ceiling = 100000;

	my @section = (
	   $self->_section('HEAD', $self->{report_type}, $self->{icao}, $self->{day}, $self->{time}, $self->{amendedOrCorrected})
	);
	
	push @section, $self->_section('VALID', $self->{valid_from_day}, $self->{valid_from_hour}, $self->{valid_to_day}, $self->{valid_to_hour}) if $self->{valid_from_day};

	while (@tok) {
		$t = shift @tok;
		
		# Temporary or Becoming 
		if ($t eq 'TEMPO' || $t eq 'BECMG') {
         push @section, $self->_section('CEIL', $ceiling) if ($ceiling < 100000);
			$ceiling = 100000;
			# Next token should be a time if it is a TAF
			my ($from_day, $from_hour, $to_day, $to_hour);
			if (@tok && (($from_day, $from_hour, $to_day, $to_hour) = $tok[0] =~ /^(\d\d)(\d\d)\/(\d\d)(\d\d)$/)) {
				if ($self->{taf} && $from_hour >= 0 && $from_hour <= 24 && $to_hour >= 0 && $to_hour <= 24) {
					shift @tok;
					$from_hour = _time($from_hour * 100);
					$to_hour = _time($to_hour * 100);
				} else {
               undef $from_day;
					undef $from_hour;
               undef $from_day;
					undef $to_hour;
				}
			}
			push @section, $self->_section($t, $from_day, $from_hour, $to_day, $to_hour);

		# Ignore
		} elsif ($ignore{$t}) {
			;
			
      # No significant weather
		} elsif ($t eq 'NOSIG' || $t eq 'NSW') {
			push @section, $self->_section('WEATHER', 'NOSIG');

		# Specify broken on its own
		} elsif ($t eq 'BKN') {
			push @section, $self->_section('WEATHER', $t);
			
      # Other 3 letter codes
		} elsif ($clt{$t}) {
			push @section, $self->_section('CLOUD', $t);
			
		# EU CAVOK visibility > 10000m, no cloud, no significant weather
		} elsif ($t eq 'CAVOK') {
			$self->{visibility_dist} ||= ">10000";
			$self->{visibility_units} ||= 'm';
			push @section, $self->_section('CLOUD', 'CAVOK');

      # RMK group (Display ceiling, if one exists, and end)
		} elsif ($t eq 'RMK') {
         push @section, $self->_section('CEIL', $ceiling) if ($ceiling < 100000);
			last;

      # From
      } elsif (my ($fromDay, $fromTime) = $t =~ /^FM(\d{2})(\d{4})$/ ) {
         push @section, $self->_section('CEIL', $ceiling) if ($ceiling < 100000);
         $ceiling = 100000;
			push @section, $self->_section('FROM', "$fromDay-" . _time($fromTime));

      # Until
      } elsif (my ($tilDay, $tilTime) = $t =~ /^TL(\d{2})(\d{4})$/ ) {
         push @section, $self->_section('CEIL', $ceiling) if ($ceiling < 100000);
         $ceiling = 100000;
			push @section, $self->_section('TIL', "$tilDay-" . _time($tilTime));

      # Probability
      } elsif (my ($percent) = $t =~ /^PROB(\d\d)$/ ) {
         push @section, $self->_section('CEIL', $ceiling) if ($ceiling < 100000);
         $ceiling = 100000;
			# Next token may be a time if it is a TAF
			my ($from_day, $from_hour, $to_day, $to_hour);
			if (@tok && (($from_day, $from_hour, $to_day, $to_hour) = $tok[0] =~ /^(\d\d)(\d\d)\/(\d\d)(\d\d)$/)) {
				if ($self->{taf} && $from_hour >= 0 && $from_hour <= 24 && $to_hour >= 0 && $to_hour <= 24) {
					shift @tok;
					$from_hour = _time($from_hour * 100);
					$to_hour = _time($to_hour * 100);
				} else {
               undef $from_day;
					undef $from_hour;
               undef $from_day;
					undef $to_hour;
				}
			}
			push @section, $self->_section('PROB', $percent, $from_day, $from_hour, $to_day, $to_hour);

      # Runway
      } elsif (my ($sort, $dir) = $t =~ /^(RWY?|LDG)(\d\d[RLC]?)$/ ) {
			push @section, $self->_section('RWY', $sort, $dir);

		# Wind
		} elsif (my ($wdir, $spd, $gust, $unit) = $t =~ /^(\d\d\d|VRB)(\d\d)(?:G(\d\d))?(KT|MPH|MPS|KMH)$/) {
			
			my ($fromdir, $todir);
			
			if	(@tok && (($fromdir, $todir) = $tok[0] =~ /^(\d\d\d)V(\d\d\d)$/)) {
				shift @tok;
			}
			
			# It could be variable so look at the next token

			$spd = 0 + $spd;
			$gust = 0 + $gust if defined $gust;
			$unit = ucfirst lc $unit;
			$unit = 'm/sec' if $unit eq 'Mps';
         $unit = 'knots' if $unit eq 'Kt';
			$self->{wind_dir} ||= $wdir;
			$self->{wind_speed} ||= $spd;
			$self->{wind_gusting} ||= $gust;
			$self->{wind_units} ||= $unit;
			push @section, $self->_section('WIND', $wdir, $spd, $gust, $unit, $fromdir, $todir);
			
		# Altimeter setting 
		} elsif (my ($u, $p, $punit) = $t =~ /^([QA])(?:NH)?(\d\d\d\d)(INS?)?$/) {

			$p = 0 + $p;
			if ($u eq 'A' || $punit && $punit =~ /^I/) {
				$p = sprintf "%.2f", $p / 100;
				$u = 'inHg';
			} else {
				$u = 'hPa';
			}
			$self->{pressure} ||= $p;
			$self->{pressure_units} ||= $u;
			push @section, $self->_section('PRESS', $p, $u);

      # Current (METAR) wind shear
      } elsif ($t eq 'WS') {
         my $runway = '';
         if ($tok[0] eq 'ALL' && $tok[1] eq 'RWY')  {
            $runway = 'all runways';
            shift @tok; shift @tok;
         }
         elsif ($tok[0] eq 'RWY' && $tok[1] =~ /\d\d[LRC]?/)  {
            $runway = "Runway $tok[1]";
            shift @tok; shift @tok;
         }
         push @section, $self->_section('CURRENTSHEAR', $runway);

      # Forecast (TAF) wind shear
      } elsif (my ($top, $direction, $speed) = $t =~ m!^WS(\d{3})\/(\d{3})(\d+)KT$!) {
         push @section, $self->_section('FORECASTSHEAR', $top * 100, $direction, $speed);

		# Visibility group in metres
		} elsif (my ($visibility, $mist) = $t =~ m!^(\d\d\d\d[NSEW]{0,2})([A-Z][A-Z])?$!) {
			$visibility = $visibility eq '9999' ? ">10000" : 0 + $visibility;
			$self->{visibility_dist} ||= $visibility;
			$self->{visibility_units} ||= 'metres';
			push @section, $self->_section('VISIBILITY', $visibility, 'm');
			push @section, $self->_section('WEATHER', $mist) if $mist;

		# Visibility group in kilometres
		} elsif (($visibility) = $t =~ m!^(\d+)KM$!) {
			$visibility = $visibility eq '9999' ? ">10000" : 0 + $visibility;
			$self->{visibility_dist} ||= $visibility;
			$self->{visibility_units} ||= 'kilometres';
			push @section, $self->_section('VISIBILITY', $visibility, 'Km');

		# Visibility group in miles and fraction of a mile with space between them
		} elsif (my ($m) = $t =~ m!^(\d)$!) {
			my $visibility;
			if (@tok && (($visibility) = $tok[0] =~ m!^(\d/\d)SM$!)) {
				shift @tok;
				$visibility = "$m $visibility";
				$self->{visibility_dist} ||= $visibility;
				$self->{visibility_units} ||= 'Statute Miles';
				push @section, $self->_section('VISIBILITY', $visibility, 'miles');
			}
			
		# Visibility group in miles (either in miles or under a mile)
		} elsif (my ($lt, $mvisibility) = $t =~ m!^([MP])?(\d+(:?/\d)?)SM$!) {
			$mvisibility = 'Less than ' . $mvisibility if $lt eq 'M';
         $mvisibility = 'Greater than ' . $mvisibility if $lt eq 'P';
			$self->{visibility_dist} ||= $mvisibility;
			$self->{visibility_units} ||= 'Statute Miles';
         my $units = 'miles';
         $units = 'mile' if ($mvisibility == 1 || $mvisibility =~ /M|\//);
			push @section, $self->_section('VISIBILITY', $mvisibility, $units);
			
		# Runway Visual Range
		} elsif (my ($rw, $rlt, $range, $vlt, $var, $runit, $tend) = $t =~ m!^R(\d\d[LRC]?)/([MP])?(\d\d\d\d)(?:([VMP])(\d\d\d\d))?(?:(FT)/?)?([UND])?$!) {
			$runit = 'm' unless $runit;
			$runit = lc $runit;
         $runit = 'feet' if $runit eq 'ft';
			$range = "<$range" if $rlt && $rlt eq 'M';
			$range = ">$range" if $rlt && $rlt eq 'P';
			$var = "<$var" if $vlt && $vlt eq 'M';
			$var = ">$var" if $vlt && $vlt eq 'P';
			push @section, $self->_section('RVR', $rw, $range, $var, $runit, $tend);
		
		# Weather
      # The symbol used for "light" descriptor appears to vary; included both a
      # hyphen and an en dash.
		} elsif (my ($deg, $w) = $t =~ /^(−|-|\+|VC)?((?:SH)?\S{0,4})$/) {
         # Replace +FC (tornado) with module specific 'ZZ' code
         if ("$deg$w" eq '+FC')  {
            $deg = '';
            $w = 'ZZ';
         } elsif ($w eq '+FC')  {
            $w = 'ZZ';
         }
			push @section, $self->_section('WEATHER', $deg, $w =~ /([A-Z][A-Z])/g);

      # Sky conditions
		} elsif (my ($amt, $height, $cb) = $t =~ m!^(FEW|SCT|BKN|OVC|SKC|CLR|VV|///)(\d\d\d|///)(CB|TCU)?$!) {
			push @section, $self->_section('CLOUD', $amt, $height eq '///' ? 0 : $height * 100, $cb) unless $amt eq '///' && $height eq '///';
         if ($amt =~ /BKN|OVC|VV/)  {
            $ceiling = $height * 100 if ($height * 100 < $ceiling);
         }

		# Temperature / Dew Point (only appears in METAR/SPECI)
		} elsif (my ($ms, $t, $n, $d) = $t =~ m/^(M)?(\d\d)\/(M)?(\d\d)?$/) {
			$t = 0 + $t;
			$d = 0 + $d;
			$t = -$t if defined $ms;
			$d = -$d if defined $d && defined $n;
			$self->{temp} ||= $t;
			$self->{dewpoint} ||= $d;
			push @section, $self->_section('TEMP', $t);
         push @section, $self->_section('DWPT', $d);
		} 
		
	}			
	$self->{sections} = \@section;
   $self->{error_code} = 0;
	return undef;	
}

sub _section
{
	my $self = shift;
	my $pkg = shift;
	no strict 'refs';
	$pkg = $self->{decode_language} . '::' . $pkg;
	return $pkg->new(@_);
}

sub _time
{
	return sprintf "%02d:%02d", unpack "a2a2", sprintf "%04d", shift;
}

# Accessors
sub AUTOLOAD
{
	no strict;
	my ($package, $name) = $AUTOLOAD =~ /^(.*)::(\w+)$/;
	return if $name eq 'DESTROY';

	*$AUTOLOAD = sub {return $_[0]->{$name}};
    goto &$AUTOLOAD;
}

#
# These are the translation packages
#
# First the factory method
#

package Geo::METARTAF::EN;

sub new
{
	my $pkg = shift;
	return bless [@_], $pkg; 
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
	if ($d == 1 || $d == 21 || $d == 31) {
		return "${d}st";
	} elsif ($d == 2 || $d == 22) {
		return "${d}nd";
	} elsif ($d == 3 || $d == 23) {
		return "${d}rd";
	}
	return "${d}th";
}

# Report header (type, location, issue time, and date)
package Geo::METARTAF::EN::HEAD;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
	my $self = shift;
	return "$self->[0] for $self->[1] issued at $self->[3] on the " . $self->day($self->[2]) . " $self->[4]\n";
}

# TAF valid period
package Geo::METARTAF::EN::VALID;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
	my $self = shift;
   my $out = "Valid from $self->[1]";
   # If the day is the same for both times
   if ($self->[0] == $self->[2])  {
      $out .= " to $self->[3] on the " . $self->day($self->[0]);
   }
   else  {
      $out .= " on the " . $self->day($self->[0]) . " to $self->[3] on the " . $self->day($self->[2]);
   }
   return $out;
}

# Wind Info: direction, $speed, $gusts, $unit, $fromdir, $todir
package Geo::METARTAF::EN::WIND;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
	my $self = shift;
	my $out = "~Wind Conditions: ";
   if ($self->[0] == 0 && $self->[1] == 0)  {
      $out .= 'Calm';
   }
   else  {
	   $out .= $self->[0] eq 'VRB' ? "Variable" : "$self->[0]";
      $out .= "°T varying between $self->[4]°T and $self->[5]" if defined $self->[4];
	   $out .= ($self->[0] eq 'VRB' ? '' : "°T") . " at $self->[1] $self->[3]";
	   $out .= " gusting to $self->[2] $self->[3]" if defined $self->[2];
   }
	return $out;
}

# Altimeter setting
package Geo::METARTAF::EN::PRESS;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
	my $self = shift;
	return "~Altimeter Setting: $self->[0] $self->[1]";
}

# Low-level wind shear in METAR
package Geo::METARTAF::EN::CURRENTSHEAR;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
	my $self = shift;
	return "~Low-Level Wind Shear: Within 1500 feet AGL along the take-off or approach path of $self->[0]";
}

# Low-level wind shear in TAF
package Geo::METARTAF::EN::FORECASTSHEAR;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
	my $self = shift;
	return "~Low-Level Wind Shear: $self->[1]°T at $self->[2] knots with top layer at $self->[0] feet AGL";
}

# Temperature
package Geo::METARTAF::EN::TEMP;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
	my $self = shift;
	my $out = "~Temperature: $self->[0]°C";
	return $out;
}

# Dew Point
package Geo::METARTAF::EN::DWPT;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
	my $self = shift;
	my $out = "~Dew Point: $self->[0]°C";
	return $out;
}

# Cloud coverage
package Geo::METARTAF::EN::CLOUD;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

my %st = (
   VV => "Obscured at",
   SKC => "Clear - No cloud",
   CLR => "Clear - No cloud and no significant weather",
   SCT => "Scattered clouds (3-4 oktas) at",
   BKN => "Broken clouds (5-7 oktas) at",
   FEW => "Few clouds (0-2 oktas) at",
   OVC => "Overcast clouds (8 oktas) at",
   CAVOK => "No cloud below 5000 feet, >= 10 km visibility, and no significant weather (CAVOK)",
   CB => "Cumulonimbus clouds present",
   TCU => "Towering Cumulus clouds present",
   NSC => "No significant cloud",
   BLU => "3 oktas at 2500ft 8Km visibility",
   WHT => "3 oktas at 1500ft 5Km visibility",
   GRN => "3 oktas at 700ft 3700m visibility",
   YLO => "3 oktas at 300ft 1600m visibility",
   AMB => "3 oktas at 200ft 800m visibility",
   RED => "3 oktas at <200ft <800m visibility",
   NIL => "No weather",
   '///' => "some",
);

sub as_string
{
	my $self = shift;
	return "~Sky Conditions: " . $st{$self->[0]} if @$self == 1;
	return "~Sky Conditions: " . $st{$self->[0]} . " $self->[1] feet AGL" if $self->[0] eq 'VV';
	return "~Sky Conditions: " . $st{$self->[0]} . " $self->[1] feet AGL" . ((defined $self->[2]) ? " with $st{$self->[2]}" : "");
}

# Local ceiling
package Geo::METARTAF::EN::CEIL;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
	my $self = shift;
	my $out = "~Ceiling: $self->[0] feet AGL";
	return $out;
}

# Weather phenomena
package Geo::METARTAF::EN::WEATHER;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

my %wt = (
	'+'  => "Heavy",
   '−'  => "Light",
   '-'  => "Light",
   'VC' => "",

	MI => "Shallow",
	PR => "Partial",
	BC => "Patches of",
	DR => "Drifting",
	BL => "Blowing",
	SH => "Showers",
	TS => "Thunderstorm",
	FZ => "Freezing",
	RE => "Recent",
	
	DZ => "Drizzle",
	RA => "Rain",
	SN => "Snow",
	SG => "Snow Grains",
	IC => "Ice Crystals (Vis <= 6 SM)",
	PL => "Ice Pellets",
	GR => "Hail",
	GS => "Snow Pellets",
	UP => "Unknown precipitation",
	
	BR => "Mist (Vis >= 5/8 SM)",
	FG => "Fog (Vis < 5/8 SM)",
	FU => "Smoke (Vis <= 6 SM)",
	VA => "Volcanic Ash",
	DU => "Dust (Vis <= 6 SM)",
	SA => "Sand (Vis <= 6 SM)",
	HZ => "Haze (Vis <= 6 SM)",
	PY => "Spray",
	
	PO => "Dust/Sand Whirls (Dust Devils)",
	SQ => "Squalls",
	FC => "Funnel Cloud",
	SS => "Sandstorm (Vis < 5/8 SM)",
	DS => "Dust Storm (Vis < 5/8 SM)",
   WS => "Wind Shear",
   ZZ => "Tornado or Waterspout", # Only for this module (actual code is '+FC')

	'BKN' => "Broken",
   'NOSIG' => "No significant weather",
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
         # VC is within 5-10 NM of an aerodrome, but not at the aerodrome, in a TAF
         if ($self->{report_type} eq 'TAF')  {
            $wt{'VC'} = 'within 5-10 NM of the aerodrome (but not at the aerodrome)';
         }
         # But in a METAR/SPECI, it is within 5 SM of an aerodrome (but not at the aerodrome)
         else  {
            $wt{'VC'} = 'within 5 SM of the aerodrome (but not at the aerodrome)';
         }
			$vic++;
			next;
		} elsif ($t eq 'SH') {
         if ($vic)  {
            push @out, $wt{'SH'};
         } else  {
            $shower++;
         }
			next;
		}
		
      # Display singular of phenomena when associated with showers
      # (e.g. - 'Ice Pellet Showers' instead of 'Ice Pellets Showers')
      if ($shower && $wt{$t} =~ /s$/)  {
         push @out, substr($wt{$t}, 0, -1);
      } else  {
         push @out, $wt{$t};
      }

	}
   
   if (@out && $shower) {
		$shower = 0;
		push @out, $wt{'SH'};
	}
	push @out, $wt{'VC'} if $vic;

	return "~Weather Phenomena: " . join ' ', @out;
}

# Runway Visual Range
package Geo::METARTAF::EN::RVR;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
	my $self = shift;
	my $out = "~Runway Visual Range: $self->[1] $self->[3]";
	$out .= " varying to $self->[2] $self->[3]" if defined $self->[2];
	if (defined $self->[4]) {
		$out .= " and decreasing" if $self->[4] eq 'D';
		$out .= " and increasing" if $self->[4] eq 'U';
	}
   $out .= " on Runway $self->[0]";
	return $out;
}

package Geo::METARTAF::EN::RWY;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
	my $self = shift;
	my $out = $self->[0] eq 'LDG' ? "landing " : '';  
	$out .= "runway $self->[1]";
	return $out;
}

# Visibility
package Geo::METARTAF::EN::VISIBILITY;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
   my $self = shift;
   return "~Visibility: $self->[0] $self->[1]";
}

# Probability
package Geo::METARTAF::EN::PROB;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
	my $self = shift;
	my $out = "Probability $self->[0]%";
   if (defined $self->[1])  {
      $out .= " between $self->[2]";
      # If the day is the same for both times
      if ($self->[1] == $self->[3])  {
         $out .= " and $self->[4] on the " . $self->day($self->[1]);
      }
      else  {
         $out .= " on the " . $self->day($self->[1]) . " and $self->[4] on the " . $self->day($self->[3]);
      }
   }
	return $out;
}

# Temporary
package Geo::METARTAF::EN::TEMPO;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
	my $self = shift;
	my $out = "Temporarily";
	$out .= " between $self->[1]";
   # If the day is the same for both times
   if ($self->[0] == $self->[2])  {
      $out .= " and $self->[3] on the " . $self->day($self->[0]);
   }
   else  {
      $out .= " on the " . $self->day($self->[0]) . " and $self->[3] on the " . $self->day($self->[2]);
   }
   return $out;
}

# Becoming
package Geo::METARTAF::EN::BECMG;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
	my $self = shift;
	my $out = "Becoming";
   $out .= " between $self->[1]";
   # If the day is the same for both times
   if ($self->[0] == $self->[2])  {
      $out .= " and $self->[3] on the " . $self->day($self->[0]);
   }
   else  {
      $out .= " on the " . $self->day($self->[0]) . " and $self->[3] on the " . $self->day($self->[2]);
   }
	return $out;
}

# From
package Geo::METARTAF::EN::FROM;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
   my $self = shift;
   my ($theDay, $theHour) = split(/-/, $self->[0]);
   return "From $theHour on the " . $self->day($theDay);
}

# Until
package Geo::METARTAF::EN::TIL;
use vars qw(@ISA);
@ISA = qw(Geo::METARTAF::EN);

sub as_string
{
   my $self = shift;
   return "Until $self->[0]";
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Geo::METARTAF - Decode METAR, SPECI, and TAF strings

=head1 SYNOPSIS

  use strict;
  use Geo::METARTAF;

  my $t = new Geo::METARTAF;

  $t->metar("CYVR 280200Z 09011KT 6SM -RA BR FEW006 OVC011 06/06 A2964 RMK ST2SC6 SLP039=");
  or
  $t->speci("CYVR 280240Z 08010KT 6SM BR FEW006 OVC010 06/06 A2962 RMK SF2SC6 SLP034=");
  or
  $t->taf("CYVR 280103Z 2801/2906 10012KT 6SM -RA BR SCT005 OVC025
           TEMPO 2801/2808 2SM SHRA BR BKN005 OVC025
           BECMG 2806/2808 12015G25KT
           FM280800 12015G25KT P6SM -RA SCT008 OVC030
           TEMPO 2808/2818 3SM -RA BR BKN008 OVC030
           FM281800 16018G28KT P6SM SCT030 OVC050
           TEMPO 2818/2906 6SM -SHRA BR OVC030
           BECMG 2900/2902 16012KT
           RMK NXT FCST BY 280300Z=");
  or 
  $t->decode("METAR CYHZ 280200Z 34007KT 15SM SKC M03/M04 A3027 RMK SLP261=");
  or
  $t->decode("TAF CYYT 272340Z 2800/2824 02012G22KT 1/2SM -DZ -RA FG VV002
              FM281200 01012KT 1/2SM FG VV002 
              PROB30 2812/2815 2SM -FZDZ BR
              FM281500 35012KT 2SM BR OVC004
              PROB30 2815/2821 1 1/2SM -FZDZ BR OVC003
              FM282300 30010KT 2SM BR OVC004
              PROB30 2823/2824 BKN003
              RMK NXT FCST BY 280600Z=");

  print $t->as_string;
  print $t->minimal;

=head1 ABSTRACT

Geo::METARTAF decodes aviation METAR, SPECI, and TAF weather code 
strings into English or, if you sub-class, some other language.

=head1 DESCRIPTION

METAR (Meteorological Aerodrome Report), SPECI (Special METAR), and
TAF (Terminal Aerodrome Forecast) are ASCII strings containing codes
describing the weather at airports and weather bureaus around the world.

This module attempts to decode these reports into a form of English
that is (hopefully) more understandable than the reports themselves.

The decoded data is based on the Transport Canada AIM.

It is possible to sub-class the translation routines to enable
translation to other langauages. 

=head1 METHODS

=over

=item new(%args)

Constructor for the class. Each weather announcement will need
a new constructor. 

If you sub-class the built-in English translation routines then 
you can pick this up by calling the constructor using:
 
  my $t = Geo::METARTAF->new(decode_language => 'Geo::METARTAF::FR');

or whatever you decide to use.

=item decode(weather_string)

The main routine that decodes a weather string. It expects a string
that begins with either the word C<METAR>, C<SPECI>, or C<TAF>.
It creates a decoded form of the weather string in the object.

If this method is unable to process the weather string,
you can use the L<error> method to get the reason. 

=item metar(weather_string)

This simply adds C<METAR> to the front of the string and calls
L<decode()>.

=item speci(weather_string)

This simply adds C<SPECI> to the front of the string and calls
L<decode()>.

=item taf(weather_string)

This simply adds C<TAF> to the front of the string and calls
L<decode()>.

It makes very little difference to the decoding process which
of these routines you use. It does, however, affect the output
in that it will mark it as the appropriate type of report.

=item as_string

Returns the decoded weather report as a human readable string.

This is probably the simplest, and most likely, of the output
options that you might want to use.

=item as_html

Returns the decoded weather report as an HTML table.

Classes are assigned to all of the table data elements allowing
you to format the results using CSS styles.

=item minimal

Returns the (cleaned up) weather report. It is cleaned up in the
sense that all whitespace is reduced to exactly one space character.

=item error

If L<decode()> is unable to process the string, this method returns the reason.

=back

=head1 ACCESSORS

=over

=item icao()

Returns the ICAO code contained in the weather report

=item day()

Returns the day of the month of this report

=item time()

Returns the issue time of this report

=item valid_from()

Returns the time from which this report is valid for (if there is one).

=item valid_to()

Returns the time to which this report is valid for (if there is one).

=item visibility_dist()

Returns the minimum visibility, if present.

=item visibility_units()

Returns the units of the visibility information.

=item wind_dir()

Returns the wind direction in degrees, if present.

=item wind_speed()

Returns the wind speed.

=item wind_units()

Returns the units of wind speed.

=item wind_gusting()

Returns any wind gust speed. It is possible to have L<wind_speed()> 
without gust information.

=item pressure()

Returns the altimeter setting, if present.

=item pressure_units()

Returns the units in which L<pressure()> is measured.

=item temp()

Returns any outside air temperature present.

=item dewpoint()

Returns any dew point temperature present.

=back

=head1 SEE ALSO

L<Geo::METAR> and L<Geo::TAF>

This module is a modified version of the Geo::TAF module created by Dirk Koopman

For an example of a weather forecast for a Canadian airport (CYHZ)
see L<https://metar-taf.com/cyhz>

=head1 AUTHOR

Peter Carter, L<pecarter@yahoo.ca>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 by Peter Carter

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
