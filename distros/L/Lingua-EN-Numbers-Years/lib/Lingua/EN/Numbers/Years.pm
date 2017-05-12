package Lingua::EN::Numbers::Years;
$Lingua::EN::Numbers::Years::VERSION = '1.05';
use 5.006;
use strict;
use warnings;

use Lingua::EN::Numbers 1.01 qw(num2en);

require Exporter;
our @ISA = qw(Exporter);

my $T    = 'thousand';
my $H    = 'hundred';
my $Oh   = 'oh';
my $Zero = 'zero';
my %DD;
my %OhDD;
my %D;

our @EXPORT    = qw(year2en);

BEGIN { *DEBUG = sub () {0} unless defined &DEBUG } # setup a DEBUG constant

#--------------------------------------------------------------------------

@DD{ '00' .. '09' } = @DD{ '0' .. '9' } = @D{ '0' .. '9' }
 = @OhDD{ '0' .. '9' }
 = qw(oh one two three four five six seven eight nine);

@OhDD{ '00' .. '09' } = map "$Oh $_", @D{  '0' ..  '9' };
 # Altho "oh oh" presumably is never used

for my $num ('10' .. '99') { 
  $OhDD{$num} = $DD{$num} = num2en($num);
  DEBUG > 1 and print "$num = $DD{$num}\n";
}

#--------------------------------------------------------------------------

sub year2en ($) {
  my $y = $_[0];
  return undef unless defined $y and length $y;
  $y =~ s/,//g;
  if( $y =~ m/\d/  and  $y =~ m/^(-?)(\d{1,5})$/s  ) {
    my $neg =  $1 ? "negative " : '';
    local $_ = $2;
    return $Zero if $_ eq '0';
    return "$neg$DD{$_}" if $DD{$_};

    m/^(..)000$/     and return "$neg$DD{$1} $T";
    
    if( m/^.0...$/ ) {
      # A family of troublesome cases: things like "60123".
      # We can't say "sixty one twenty-three" because that sounds
      #  just like sixty-one twenty-three.  So we special-case this
      #  whole group.
      m/^(.0)000$/     and return "$neg$DD{$1} $T";
      m/^(.0)00(.)$/   and return "$neg$DD{$1} $T $D{$2}";
      m/^(.0)0(..)$/   and return "$neg$DD{$1} $T $DD{$2}";
      m/^(.0)(.)00$/   and return "$neg$DD{$1} $T $D{$2} $H";
      m/^(.0)(.)(..)$/ and return "$neg$DD{$1} $T $D{$2} $OhDD{$3}";
      DEBUG and print "Falling thru with x0,xxx number $_ !\n";
    }
    
    m/^(.)000$/      and return "$neg$DD{$1} $T";
    m/^(..)00$/      and return "$neg$DD{$1} $H";
    m/^(.)00$/       and return "$neg$DD{$1} $H";

    m/^(..)00(.)$/   and return "$neg$DD{$1} $Oh $Oh $DD{$2}";
    m/^(..)0(..)$/   and return "$neg$DD{$1} $Oh $DD{$2}";

    m/^(.)00(.)$/    and return "$neg$DD{$1} $T $DD{$2}";
    #m/^(..)00(.)$/  and return "$neg$DD{$1} $T $DD{$2}";

    m/^(..)(.)(..)$/ and return "$neg$OhDD{$1} $D{$2} $OhDD{$3}";
    m/^(..)(..)$/    and return "$neg$OhDD{$1} $OhDD{$2}";
    m/^(.)(..)$/     and return "$neg$OhDD{$1} $OhDD{$2}";
    
    # Else fallthru:
  }
  
  if(DEBUG) {
    my $x = num2en($y);
    print "Using superclass to return numerification \"$x\".\n";
    return $x;
  } else {
    return num2en($y);
  }
}
#--------------------------------------------------------------------------

1;

__END__


=head1 NAME

Lingua::EN::Numbers::Years - turn "1984" into "nineteen eighty-four", etc

=head1 SYNOPSIS

  use Lingua::EN::Numbers::Years;

  my $x = 1803;
  print "I'm old!  I was born in ", year2en($x), "!\n";

prints:

  I'm old!  I was born in eighteen oh three!

=head1 DESCRIPTION

Lingua::EN::Numbers::Years turns numbers that represent years, into English text.
It exports one function, C<year2en>, which takes a scalar value
and returns a scalar value.  The return value is the English text expressing that 
year-number; or if what you provided wasn't a number, then it returns undef.

Unless the input is an at-most five-digit integer (with commas allowed),
then C<year2en> just returns C<num2en(I<value>)>
(C<num2en> is a function provided by L<Lingua::EN::Numbers>),
as a reasonable fall-through.

=head1 NOTES

This module is necessary because English pronounces year-numbers differently from
normal numbers.  So the year 1984 was pronounced "nineteen eighty-four", never
"one thousand, nine hundred and eighty-four".

This module makes guesses as to how to pronounce year-numbers between
ten thousand and a hundred thousand -- so C<year2num(10191)> returns
"ten thousand one ninety-one".  But clearly these are not established in English
usage.  Yet.

Note that C<year2en> doesn't try to append "BC" or "AD".

=head1 SEE ALSO

L<Lingua::EN::Numbers> - more general purpose module for turning
numbers into English text.

L<Lingua::EN::Words2Nums> - another general purpose module
for converting numbers into English text.
I'd recommend using the previous module.


=head1 REPOSITORY

L<https://github.com/neilb/Lingua-EN-Numbers-Years>

=head1 COPYRIGHT

Copyright (c) 2005, Sean M. Burke, author of the later versions.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself (L<perlartistic>).

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

(But if you have any problems with this library, I ask that you let
me know.)

=head1 AUTHOR

Sean M. Burke, sburke@cpan.org

=cut

