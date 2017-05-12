
BEGIN { $| = 1; print "1..17\n"; }
END {print "not ok 1\n" unless $loaded;}

no warnings;
use Lingua::ZH::MacChinese::Traditional qw(decode encode);

$loaded = 1;
print "ok 1\n";

$a = decode();
print $a eq "" ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = encode();
print $a eq "" ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = decode(\"1");
print $a eq "" ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = encode(\"1");
print $a eq "" ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = decode(sub { shift });
print $a eq "" ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = encode(sub { shift });
print $a eq "" ? "ok" : "not ok", " ", ++$loaded, "\n";

eval { $a = decode([]) };
print $@ ? "ok" : "not ok", " ", ++$loaded, "\n";

eval { $a = encode([]) };
print $@ ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = decode("Perl");
print $a eq "Perl" ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = encode("Perl");
print $a eq "Perl" ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = decode(\"1", "Perl");
print $a eq "Perl" ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = encode(\"1", "Perl");
print $a eq "Perl" ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = decode(sub { shift }, "Perl");
print $a eq "Perl" ? "ok" : "not ok", " ", ++$loaded, "\n";

$a = encode(sub { shift }, "Perl");
print $a eq "Perl" ? "ok" : "not ok", " ", ++$loaded, "\n";

eval { $a = decode([], "Perl") };
print $@ ? "ok" : "not ok", " ", ++$loaded, "\n";

eval { $a = encode([], "Perl") };
print $@ ? "ok" : "not ok", " ", ++$loaded, "\n";

__END__
