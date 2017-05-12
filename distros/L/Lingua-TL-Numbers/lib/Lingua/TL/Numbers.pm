package Lingua::TL::Numbers;

use strict;
use warnings;

use integer;

use base qw(Exporter);
our @EXPORT_OK = qw(num2tl num2tl_ordinal);

our $VERSION = 0.02;

my @CARDINAL_UNITS = (undef, qw(
    isa dalawa tatlo apat lima anim pito walo siyam sampu labing-isa labindalawa
    labintatlo labing-apat labinlima labing-anim labimpito labingwalo labinsiyam
));

my @CARDINAL_TENS = (undef, qw(
    sampu dalawampu tatlumpu apatnapu limampu animnapu pitumpu walumpu siyamnapu
));


sub _cardinal_thousands {
    my ($number, $div, $suffix, $at) = @_; 

    my $word = _cardinal($number / $div);
    if    ($word =~ /[aeiou]$/) { $word .= 'ng '  . $suffix }
    elsif ($word =~ /n$/)       { $word .= 'g '   . $suffix }
    else                        { $word .= ' na ' . $suffix }
    $word .= $at . _cardinal($number % $div) if $number % $div;
    return $word;
}

sub _cardinal {
    my $number = shift;    

    return $CARDINAL_UNITS[$number] if $number < 20;

    if ($number < 100) {
        my $word = $CARDINAL_TENS[$number / 10];
        $word .= "'t " . $CARDINAL_UNITS[$number % 10] if $number % 10;
        return $word;
    }
    if ($number < 1000) {
        my $word = _cardinal($number / 100); 
        $word .= $word =~ /[aeiou]$/ ? 'ng daan' : ' na raan';
        $word = substr($word, 0, -1) . "'t " . _cardinal($number % 100) if $number % 100;
        return $word;
    }

    return _cardinal_thousands($number, 1_000, 'libo', "'t ")        if $number < 1_000_000;
    return _cardinal_thousands($number, 1_000_000, 'milyon', ' at ') if $number < 1_000_000_000;
}

sub num2tl {
    my $number = shift;

    return if $number < 1 or $number > 999_999_999;
  
    return _cardinal($number);
}

sub _ordinal_ika {
    my $number = shift;

    return 'una'     if 1 == $number;
    return 'ikalawa' if 2 == $number;
    return 'ikatlo'  if 3 == $number;

    my $word = num2tl($number) or return;

    my $prefix = 'ika';
    $prefix .= '-' if  $word =~ /^[aeiou]/; 

    return $prefix . $word;
}

sub _ordinal_pang {
    my $number = shift;
    
    return 'panguna'   if 1 == $number;
    return 'pangalawa' if 2 == $number;
    return 'pangatlo'  if 3 == $number;

    my $word = num2tl($number) or return;

    my $prefix = '';
    if    ($word =~ /^[aieou]/) { $prefix = 'pang-' }
    elsif ($word =~ /^w/)       { $prefix = 'pang'  }
    elsif ($word =~ /^[dtls]/)  { $prefix = 'pan'   }
    elsif ($word =~ /^p/)       { $prefix = 'pam'   }

    return $prefix . $word;
}

sub num2tl_ordinal {
    my $number = shift;
    my %options = @_;

    my %opts = (
        ika   => 0,
        hypen => 0,
    );
    foreach my $key (keys %opts) {
        $opts{$key} = ! !$options{$key} if exists $options{$key};
    }

    my $word =  $opts{ika} ? _ordinal_ika($number) 
                           : _ordinal_pang($number);

    $word =~ tr/ /-/ if $opts{hypen};

    return $word;
}

1;

__END__

=head1 NAME

Lingua::TL::Numbers - Convert numbers into Tagalog words

=head1 SYNOPSIS

  use Lingua::TL::Numbers qw(num2tl num2tl_ordinal);

  $words = num2tl(1234);
  # "isang libo't dalawang daa't tatlumpu't apat"

  $words = num2tl_ordinal(12345);
  # "panlabindalawang libo't tatlong daa't apatnapu't lima"

  $words = num2tl_ordinal(12345, ika => 1);
  # "ikalabindalawang libo't tatlong daa't apatnapu't lima"

=head1 DESCRIPTION

This module provides functions to convert numbers into words in Tagalog,
a language of the Philippines.

=head1 FUNCTIONS

The following functions can be imported from this module. No functions
are exported by default.

=over 4

=item $words = num2tl($number)

Returns a Tagalog representation of $number.

=item $words = num2tl_ordinal($number, %options)

Returns an ordinal equivalent of $number in Tagalog. It accepts the
following options:

=over 8

=item * ika

If set to a true value, ordinal number will be formed by prefixing "ika-"
to cardinal number. The default is to use "pang-" prefix.

=item * hypen

Set to a true value to replace spaces between words with hypens.

=back

=back

=head1 REFERENCES

Paul Schachter and Fe T. Otanes. I<Tagalog Reference Grammar>. University of California Press, 1982. L<http://books.google.com/books?id=E8tApLUNy94C>

Teresita V. Ramos. I<Conversational Tagalog: a functional-situational approach>. University of Hawaii Press, 1985. L<http://books.google.com/books?id=p1C7-AmU1QsC>

Teresita V. Ramos. I<Tagalog Structures>. University of Hawaii Press, 1971. L<http://books.google.com/books?id=cc7wUSVhaYwC>

=head1 AUTHOR

Sherwin Daganato E<lt>sherwin@daganato.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Lingua::EN::Numbers> L<http://en.wikipedia.org/wiki/Tagalog>

=cut
