# $Id: Bootstring.pm,v 1.9 2004/06/01 08:52:29 sauber Exp $
# Encode and decode utf8 into a set of basic code points

package Encode::Bootstring;

use strict;
use integer;
use utf8;

=head1 NAME

Encode::Bootstring - Encode and decode utf8 into a set of basic code points

=head1 VERSION

VERSION 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  $BS = new Encode::Bootstring(
      BASIC => ["a".."z", "A".."Z", "0".."9"],
      TMAX => 53,
      SKEW => 78,
      INITIAL_BIAS => 32,
      TMIN => 38,
      DAMP => 40,
      DELIMITER => '_',
  );

  $bootstring = $BS->encode($utf8);
  $utf8 = $BS->encode($bootstring);

=head1 DESCRIPTION

Punycode is a specific use of bootstring encoding; it encodes the
larger code set to preprogrammed code set suitable for DNS names, such
as ASCII characters and numbers. It also ignores casing of letters.

Bootstring on the other hand is the generalised concept and allows any
code set to be encoded as any other smaller code set.

=head1 INTERFACE

All parameters are optional. Refer to RFC3492 for details of each parameter.
The above parameters are suitable for encoding a variety of alphabets
to ascii letters and numbers.

=cut

# Constructor
#
sub new {
  my $invocant  = shift;
  my $class     = ref($invocant) || $invocant;
  my $self = { @_ };
  bless $self, $class;
  $self->_initialize();
  return $self;
}

# Initializer
#
# This load the basic code points table and set constants for encoding
# and decoding.
# Note: Are these constants reasonable?
#
sub _initialize {
  my $self  = shift;

  # Read parameters from new();
  %{$self} = ( %{$self}, @_ );

  # BASE is number of basic code points
  $self->{BASIC} ||= ["a".."z", "A".."Z", "0".."9"];
  $self->{BASE} = scalar @{$self->{BASIC}};

  # Defaults
  $self->{DELIMITER} ||= '-';
  $self->{TMIN} ||= 1;
  $self->{TMAX} ||= $self->{BASE} - 1;
  $self->{INITIAL_N} = $self->{BASE} + 1;
  $self->{INITIAL_BIAS} ||= 72;
  $self->{SKEW} ||= 38;
  $self->{DAMP} ||= 700;

  # Render a modification of ascii table
  $self->newtable();
}

# Handle errors
#
sub _croak { require Carp; Carp::croak(@_); }

# Create a variation of the ascii table (or part of it or beyond)
# where all basic code points are first.
#
sub newtable {
  my $self = shift;

  my $n = 0;

  # Put basic code points in beginning of table
  for ( @{$self->{BASIC}} ) {
    $self->{ord}{$_} = $n;
    $n++;
    $self->{maxord} = ord if not exists $self->{maxord} or $self->{maxord} < ord;
  }

  # Put skipped chars after basic code points
  for ( 0..$self->{maxord} ) {
    my $c = chr $_;
    unless ( exists $self->{ord}{$c} ) {
      $self->{ord}{$c} = $n;
      $n++;
    } else {
    }
  }

  # Create a reverse map
  %{$self->{chr}} = reverse %{$self->{ord}};
}

# Input int output char using modified table
#
sub nchr {
  my($self,$c) = @_;

  #return $_[0] > $self->{maxord} ? chr($_[0]) : $self->{chr}{$_[0]} ;
  return $c > $self->{maxord} ? chr($c) : $self->{chr}{$c} ;
}

# Input char output char using modified table
#
sub nord {
  my($self,$c) = @_;

  return exists $self->{ord}{$c} ? $self->{ord}{$c} : ord($c) ;
}

# Hex code of ascii/utf8 char
#
sub hex4 {
  return sprintf('%04x', ord(shift));
}

# Dump modified table, for testing
#
sub dumptable {
  my $self = shift;

  for (0..$self->{maxord}) {
    printf "%d = %s\n", $_, $self->nchr($_);
  }
}

# The bootstring adaption algorithm
#
sub adapt {
  my($self,$delta, $numpoints, $firsttime) = @_;

  $delta = $firsttime
         ? $delta / $self->{DAMP}
         : $delta / 2;
  $delta += $delta / $numpoints;
  my $k = 0;
  while ( $delta > (($self->{BASE}-$self->{TMIN})*$self->{TMAX})/2 ) {
    $delta /= $self->{BASE} - $self->{TMIN};
    $k += $self->{BASE};
  }
  return $k + ( (($self->{BASE}-$self->{TMIN}+1) * $delta)
                / ($delta+$self->{SKEW}) );
}

=head2 encode

  $encoded = $BS->encode( $raw );

Encodes raw data.

=cut

# Encoding routine
#
sub encode {
  my $self = shift;
  my $input = shift;

  if ( exists $self->{DEBUG} ) {
    $self->{trace} = "Encoding trace of $input:\n\n";
  }

  #my @input = split //, $input; # doesn't work in 5.6.x!
  my @input = map substr($input, $_, 1), 0..length($input)-1;

  my $n     = $self->{INITIAL_N};
  my $delta = 0;
  my $bias  = $self->{INITIAL_BIAS};
  unless ( exists $self->{BasicRE} ) {
    my $BasicRE = join'',@{$self->{BASIC}};
    $self->{BasicRE} = qr/[$BasicRE]/;
  }

  # Trace output
  if ( exists $self->{DEBUG} ) {
    $self->{trace} .= "bias is $bias\n"
                   .  "input is:\n"
                   .  join(' ', map hex4($_), @input) . "\n";
  }

  my @output;
  my @tmpout;
  #my @basic = grep /$BasicRE/, @input;
  my @basic = grep /$self->{BasicRE}/, @input;
  my $h = my $b = @basic;
  push @output, @basic, $self->{DELIMITER} if $b > 0;

  if ( exists $self->{DEBUG} ) {
    if ( @basic ) {
      $self->{trace} .= 'basic code points ('
                     .  join(', ', map hex4($_), @basic)
                     .  ') are copied to literal portion: "'
                     .  join('', @output)
                     .  '"' . "\n";
    } else {
      $self->{trace} .= "there are no basic code points, so no literal portion\n";
    }
  }

  my @ninput = map $self->nord($_), @input;
  while ($h < @input) {
    my $m = min(grep { $_ >= $n } @ninput);
    if ( exists $self->{DEBUG} ) {
      $self->{trace} .= sprintf "next code point to insert is %04x\n", $m;
    }
    $delta += ($m - $n) * ($h + 1);
    $n = $m;
    for my $c (@ninput) {
      #my $c = $i;
      $delta++ if $c < $n;
      if ($c == $n) {
        my $q = $delta;
      LOOP:
        for (my $k = $self->{BASE}; 1; $k += $self->{BASE}) {
          my $t = ($k <= $bias) ? $self->{TMIN} :
            ($k >= $bias + $self->{TMAX}) ? $self->{TMAX} : $k - $bias;
          last LOOP if $q < $t;
          my $cp = $self->nchr($t + (($q - $t) % ($self->{BASE} - $t)));
          push @tmpout, $cp;
          $q = ($q - $t) / ($self->{BASE} - $t);
        }
        push @tmpout, $self->nchr($q);
        $bias = $self->adapt($delta, $h + 1, $h == $b);
        $delta = 0;
        $h++;
      }
    }
    if ( exists $self->{DEBUG} ) {
      $self->{trace} .= "needed delta is $delta, encodes as " . '"'
                     .  join('',@tmpout) . '"' . "\n"
                     .  "bias becomes $bias\n";
    }
    push @output, @tmpout;
    @tmpout = ();
    $delta++;
    $n++;
  }
  if ( exists $self->{DEBUG} ) {
    $self->{trace} .= 'output is "' . join('', @output) . '"' . "\n";
  }
  return join '', @output;
}

# Find minimum value in list
#
sub min {
  my $min = shift;
  for (@_) { $min = $_ if $_ <= $min }
  return $min;
}

=head2 decode

  $original = $BS->decode( $encoded );

Decode bootstring encoded data.

=cut

# Bootstring decoding routing
#
sub decode{
  my $self = shift;
  my $code = shift;

  if ( exists $self->{DEBUG} ) {
    $self->{trace} = "Decoding trace of $code:\n\n";
  }

  my $n      = $self->{INITIAL_N};
  my $i      = 0;
  my $bias   = $self->{INITIAL_BIAS};
  #my $BasicRE = join'',@{$self->{BASIC}};
  #$BasicRE = qr/[$BasicRE]/;
  #$BasicRE = qr/[join'',@{$self->{BASIC}}]/;

  my @output;

  if ( exists $self->{DEBUG} ) {
    $self->{trace} .= "n is $n, i is $i, bias = $bias\n"
                   .  'input is "' . $code . '"' . "\n";
  }

  if ($code =~ s/(.*)$self->{DELIMITER}//o) {
    push @output, map $self->nord($_), split //, $1;
    if ( exists $self->{DEBUG} ) {
      $self->{trace} .= 'literal portion is "' . $1 . $self->{DELIMITER}
                     .  '", so extended string starts as:' . "\n"
                     .  join(' ', map hex4($self->nchr($_)), @output) . "\n";
    }
    my $bas = join('',@{$self->{BASIC}});
    for ( split //, $1 ) {
      return _croak('non-basic code point' ) unless $bas =~ /$_/o;
    }
  } else {
    if ( exists $self->{DEBUG} ) {
      $self->{trace} .=
           "there is no delimiter, so extended string starts empty\n";
    }
  }

  while ($code) {
    my $oldi = $i;
    my $w    = 1;
    if ( exists $self->{DEBUG} ) {
      $self->{trace} .= 'delta "';
    }
  LOOP:
    for (my $k = $self->{BASE}; 1; $k += $self->{BASE}) {
      my $cp = substr($code, 0, 1, '');
      my $digit = $self->nord($cp);
      if ( exists $self->{DEBUG} ) {
        $self->{trace} .= $cp;
      }
      defined $digit or return _croak("invalid punycode input");
      $i += $digit * $w;
        my $t = ($k <= $bias)
                ? $self->{TMIN}
                : ($k >= $bias + $self->{TMAX})
                  ? $self->{TMAX}
                  : $k - $bias;
        last LOOP if $digit < $t;
        $w *= ($self->{BASE} - $t);
    }
    if ( exists $self->{DEBUG} ) {
      $self->{trace} .= '" decodes to ' . "$i\n";
    }
    $bias = $self->adapt($i - $oldi, @output + 1, $oldi == 0);
    if ( exists $self->{DEBUG} ) {
      $self->{trace} .= "bias becomes $bias\n";
    }
    $n += $i / (@output + 1);
    $i = $i % (@output + 1);
    splice(@output, $i, 0, $n);
    if ( exists $self->{DEBUG} ) {
      $self->{trace} .= join(' ', map hex4($self->nchr($_)), @output) . "\n";
    }
    $i++;
  }
  my $res = pack("C*", map ord $self->nchr($_), @output);
  return $res;
}

=head1 AUTHOR

Soren Dossing, C<< <netcom at sauber.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-encode-bootstring at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Encode-Bootstring>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Encode::Bootstring


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Encode-Bootstring>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Encode-Bootstring>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Encode-Bootstring>

=item * Search CPAN

L<http://search.cpan.org/dist/Encode-Bootstring/>

=back


=head1 ACKNOWLEDGEMENTS

Adam M. Costello for punycode reference implementation, and for advice and
review of this more generic module.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Encode::Bootstring
