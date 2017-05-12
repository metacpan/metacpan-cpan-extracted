
BEGIN { $| = 1; print "1..17\n"; }

use strict;
use warnings;
no warnings 'uninitialized';

use Lingua::AR::MacArabic qw(decode encode);

our $loaded = 1;
print "ok 1\n";

$a = decode();
print $a eq ""
   ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = encode();
print $a eq ""
   ? "ok" : "not ok", " ", ++$loaded, "\n";

eval { $a = decode(\"1") };
print $@
   ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = encode(\"1");
print $a eq ""
   ? "ok" : "not ok", " ", ++$loaded, "\n";

eval { $a = decode(sub { shift }) };
print $@
   ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = encode(sub { shift });
print $a eq ""
   ? "ok" : "not ok", " ", ++$loaded, "\n";

eval { $a = decode([]) };
print $@
   ? "ok" : "not ok", " ", ++$loaded, "\n";

eval { $a = encode([]) };
print $@
   ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = decode("Perl");
print $a eq "Perl"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = encode("Perl");
print $a eq "Perl"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

eval { $a = decode(\"1", "Perl") };
print $@
   ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = encode(\"1", "Perl");
print $a eq "Perl"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

eval { $a = decode(sub { shift }, "Perl") };
print $@
   ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = encode(sub { shift }, "Perl");
print $a eq "Perl"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

eval { $a = decode([], "Perl") };
print $@
   ? "ok" : "not ok", " ", ++$loaded, "\n";

eval { $a = encode([], "Perl") };
print $@
   ? "ok" : "not ok", " ", ++$loaded, "\n";

__END__
