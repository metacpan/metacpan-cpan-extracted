package HTML::Fraction;
use strict;
use warnings;
our $VERSION = "0.50";

# numbers with an exact fractional part
my %dec = (
  '25'  => "1/4",
  '5'   => "1/2",
  '75'  => "3/4",
  '2'   => "1/5",
  '4'   => "2/5",
  '6'   => "3/5",
  '8'   => "4/5",
  '125' => "1/8",
  '375' => "3/8",
  '625' => "5/8",
  '875' => "7/8",
  '1'   => "1/10",
);

# two decimal 
my %tdp = (
  '13' => "1/8",
  '38' => "3/8",
  '63' => "5/8",
  '88' => "7/8",  
);

my %name2char = (
  '1/4' => '&frac14;',
  '1/2' => '&frac12;',
  '3/4' => '&frac34;',
  '0/3' => '&#8585;',
  '1/3' => '&#8531;',
  '2/3' => '&#8532;',
  '1/5' => '&#8533;',
  '2/5' => '&#8534;',
  '3/5' => '&#8535;',
  '4/5' => '&#8536;',
  '1/6' => '&#8537;',
  '5/6' => '&#8538;',
  '1/7' => '&#8528;',
  '1/8' => '&#8539;',
  '3/8' => '&#8540;',
  '5/8' => '&#8541;',
  '7/8' => '&#8542;',
  '1/9' => '&#8529;',
  '1/10' => '&#8530;',
);

sub _name2char { shift; $name2char{shift()} }

sub new { bless {}, shift }

sub tweak
{
  my ($self, $in) = @_;
  return $self->tweak_frac($self->tweak_dec($in));
}

sub tweak_frac
{
  my ($self, $in) = @_;

  my $thingy = join '|', keys %name2char;
  $in =~ s{\b($thingy)\b}{
    $self->_name2char($1)
  }ge;

  # repeatin
  return $in;
}

sub tweak_dec
{
  my ($self, $in) = @_;
  
  my $thingy = join '|', keys %dec;
  $in =~ s{([0-9]*)\.($thingy)0*\b}{
    no warnings;
    ($1+0 ? $1 : "") . $self->_name2char($dec{$2})
  }ge;

  $thingy = join '|', keys %tdp;
  $in =~ s{([0-9]*)\.($thingy)\b}{
    no warnings;
    ($1+0 ? $1 : "") . $self->_name2char($tdp{$2})
  }ge;

  $in =~ s{([0-9]*)\.33+\b}{
    no warnings;
    ($1+0 ? $1 : "") . $self->_name2char("1/3")
  }ge;
  
  $in =~ s{([0-9]*)\.66*7+\b}{
    no warnings;
    ($1+0 ? $1 : "") . $self->_name2char("2/3")
  }ge;
  
  $in =~ s{([0-9]*)\.83+\b}{
    no warnings;
    ($1+0 ? $1 : "") . $self->_name2char("5/6")
  }ge;

  $in =~ s{([0-9]*)\.16*7+\b}{
    no warnings;
    ($1+0 ? $1 : "") . $self->_name2char("1/6")
  }ge;

  $in =~ s{([0-9]*)\.11+\b}{
    no warnings;
    ($1+0 ? $1 : "") . $self->_name2char("1/9")
  }ge;

  # 0.142857142857143
  $in =~ s{
      ([0-9]*)
      \.
      14
      (?:
        3|2(?:
            9|8(?:
              6|5(?:
                7(?: 1(?:4\d*)? )?
                 )
               )
           )
      )?
  \b}{
    no warnings;
    ($1+0 ? $1 : "") . $self->_name2char("1/7")
  }gex;

  return $in;
}


1;

__END__

=head1 NAME

HTML::Fraction - Encode fractions as HTML entities

=head1 SYNOPSIS

  my $fraction = HTML::Fraction->new;
  print $fraction->tweak($html);
  
=head1 DESCRIPTION

The L<HTML::Fraction> encodes fractions as HTML entities. Some very
common fractions have HTML entities (eg C<1/2> is C<&frac12>;). Additionally,
common vulgar fractions have Unicode characters (eg C<1/5> is C<&#8533;>). This
module takes a string and encodes fractions as entities: this means that
it will look pretty in the browser.

Fractions that are supported: 

  1/4, 1/2, 3/4, 0/3, 1/3, 2/3, 1/5, 2/5, 3/5,
  4/5, 1/6, 5/6, 1/7, 1/8, 3/8, 5/8, 7/8, 1/9, 1/10

Fractions may be in the string in the form numerator slash denominator (C<1/5>)
or in decimal form (C<0.5>).  Numbers must be equal to the fraction to two
decimal places.  This module supports converting whole and fractional decimal
numbers (e.g. C<2.25>.)

For sanity the decimal C<0> will not be turned into the unicode for C<0/3>

=head1 CONSTRUCTOR

=head2 new

The constructor takes no arguments:

  my $fraction = HTML::Fraction->new;

=head1 METHODS

=head2 tweak

Encode the fractions in the HTML as HTML entities:

  print $fraction->tweak($html);

=head2 tweak_frac

Encode the fractions that are in the form "1/3" or "5/6" in the HTML as HTML
entities, but not decimal fractions of the form "0.5".

=head2 tweak_dec

Encode the fractions that are in the form "0.5" or "0.5" in the HTML as HTML
entities, but not fractions of the form "1/2" or "1/3".  

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>. Mark Fowler C<< <mark@twoshortplanks> >>
added some code, and probably some bugs.

=head1 COPYRIGHT

Copyright (C) 2005, 2012 Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=head1 BUGS

We don't perform normalisation of the denominator and numerator so "4/6" is
not converted like C<2/3> is.  This is intentional.

C<2.25> doesn't render to the same thing as C<2 1/2> (the latter has a space
between the digit 2 and the fraction.)

C<1/7> doesn't represent as a reoccuring pattern of digits in decimal therefore
we don't check that digits after C<0.14285714> are correct, and assume that
they are.


