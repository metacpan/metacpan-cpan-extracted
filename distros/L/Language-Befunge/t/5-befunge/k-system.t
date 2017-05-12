#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

# -- system stuff

use strict;
use warnings;

use Test::More tests => 24;
use Test::Output;

use File::Spec::Functions qw{ catfile };
use Language::Befunge;
my $bef = Language::Befunge->new;


# exec instruction
SKIP: {
    skip 'will barf on windows...', 1 if $^O eq 'MSWin32';

    # this will warn on unix systems
    local $SIG{__WARN__} = sub {};

    $bef->store_code( '< q . = "a_file_unlikely_to_exist"0' );
    stdout_is { $bef->run_code } '-1 ', 'exec, non-existing file';
}
$bef->store_code( qq{< q . = "$^X t/_resources/exit3.pl"0} );
stdout_is { $bef->run_code } '3 ', 'exec, regular';


# system info retrieval
$bef->store_code( '1y.q' );
stdout_is { $bef->run_code } '15 ', 'sysinfo, 1. flags';

$bef->store_code( '2y.q' );
stdout_is { $bef->run_code } '4 ', 'sysinfo, 2. size of funge integers in bytes';

$bef->store_code( '3y.q' );
my $handprint = 0;
$handprint = $handprint*256 + ord($_) for split //, $bef->get_handprint;
stdout_is { $bef->run_code } "$handprint ", 'sysinfo, 3. handprint';

$bef->store_code( '4y.q' );
my $ver = $Language::Befunge::VERSION;
$ver =~ s/\.//g;
stdout_is { $bef->run_code } "$ver ", 'sysingo, 4. interpreter version';

$bef->store_code( '5y.q' );
stdout_is { $bef->run_code } '1 ', 'sysinfo, 5. id code';

$bef->store_code( '6y,q' );
stdout_is { $bef->run_code } catfile('',''), 'sysinfo, 6. path separator';

$bef->store_code( '7y.q' );
stdout_is { $bef->run_code } '2 ', 'sysinfo, 7. size of funge (2d)';

$bef->store_code( '8y.q' );
stdout_like { $bef->run_code } qr/^\d+ $/, 'sysinfo, 8. ip id';

$bef->store_code( '9y.q' );
stdout_is { $bef->run_code } '0 ', 'sysinfo, 9. netfunge (unimplemented)';

$bef->store_code( <<'END_OF_CODE' );
bav
  > y.y.q
END_OF_CODE
stdout_is { $bef->run_code } '1 6 ', 'sysinfo, 10-11. ip position';

$bef->store_code( <<'END_OF_CODE' );
v y
    .
      q
>dc 21  x
          y
            .
END_OF_CODE
stdout_is { $bef->run_code } '1 2 ', 'sysinfo, 12-13. ip delta';

$bef->store_code( '   0   {  fey.y.q' );
stdout_is { $bef->run_code } '0 8 ', 'sysinfo, 14-15. storage offset';

$bef->store_code( '6 03-04-p f1+f2+ y.y.q' );
stdout_is { $bef->run_code } '-3 -4 ', 'sysinfo, 16-17. top-left corner of lahey space';

$bef->store_code( '6 ff+8p 6 03-04-p f3+f4+y.y.q' );
stdout_is { $bef->run_code } '33 12 ', 'sysinfo, 18-19. bottom-right corner of lahey space';

my ($s,$m,$h,$dd,$mm,$yy)=localtime;
my $date1 = $yy*256*256+($mm+1)*256+$dd;
my $date2 = $date1 + 1; # tiny little chance that the date has changed
$bef->store_code( 'f5+y.q' );
stdout_like { $bef->run_code } qr/^($date1|$date2) $/, 'sysinfo, 20. date';

$bef->store_code( 'f6+y.q' );
my $time = $h*256*256+$m*256+$s;
# the 2 tests should not take more than 15 seconds
my $regex = join '|', map { $time+$_ } 0..15;
stdout_like { $bef->run_code } qr/^($regex) $/, 'sysinfo, 21. time';

$bef->store_code( '0{0{0{0{ f7+y. 0}0} f7+y.q' );
stdout_is { $bef->run_code } '5 3 ', 'sysinfo, 22. size of stack stack';

$bef->store_code( '123 0{ 12 0{ 987654 f8+y.f9+y.fa+y.q' );
stdout_is { $bef->run_code } '6 4 5 ', 'sysinfo, 23-24. size of each stack';

$bef->store_code( <<'END_OF_CODE' );
yf7+k$ >  :#, _ $a, :#v _q
       ^              <
END_OF_CODE
stdout_is { $bef->run_code( "foo", 7, "bar" ) } "STDIN\nfoo\n7\nbar\n", 'sysinfo, 23+ args';

%ENV= ( LANG   => "C",
        LC_ALL => "C",
      );
$bef->store_code( <<'END_OF_CODE' );
v                   > $ ;EOL; a,  v
              > :! #^_ ,# #! #: <
> y ff+k$   : | ;new pair;   :    <
              q
END_OF_CODE
stdout_is { $bef->run_code } "LANG=C\nLC_ALL=C\n", 'sysinfo, 24+ %ENV';

$bef->store_code( '02-y..q' );
stdout_is { $bef->run_code } '15 4 ', 'sysinfo, negative';

%ENV= ();
$bef->store_code( '1234567 75*y.q' );
stdout_is { $bef->run_code } '5 ', 'sysinfo, pick in stack';

