# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;

print "1..2\n";

my $__FILE__ = __FILE__;

if ($^O eq 'MacOS') {
    print "ok - 1 # SKIP $^X $__FILE__\n";
    print "ok - 2 # SKIP $^X $__FILE__\n";
    exit;
}

my $null = '';
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    if (($ENV{'PERL5SHELL'}||$ENV{'COMSPEC'}) =~ / \\COMMAND\.COM \z/oxmsi) {
        $null = '';
    }
    else {
        $null = '2>NUL';
    }
}
else{
    $null = '2>/dev/null';
}

my $script = __FILE__ . '.pl';

open(TEST,">$script") || die "Can't open file: $script\n";
print TEST <<'END';
# encoding: KSC5601
use KSC5601;
'-' =~ /(ㄲ[ㄲ-ㄴ])/;
print "PASS\n";
END
close(TEST);
eval {
    $result = qx{$^X $script $null};
};
if ($result =~ /PASS/) {
    print "ok - 1 $^X $__FILE__ die ('-' =~ /ㄲ[ㄲ-ㄴ]/).\n";
}
else {
    print "not ok - 1 $^X $__FILE__ die ('-' =~ /ㄲ[ㄲ-ㄴ]/).\n";
}
unlink("$script");
unlink("$script.e");

open(TEST,">$script") || die "Can't open file: $script\n";
print TEST <<'END';
# encoding: KSC5601
use KSC5601;
'-' =~ /(ㄲ[ㄴ-ㄲ])/;
print "PASS\n";
END
close(TEST);
eval {
    $result = qx{$^X $script $null};
};
if ($result !~ /PASS/) {
    print "ok - 2 $^X $__FILE__ die ('-' =~ /ㄲ[ㄴ-ㄲ]/).\n";
}
else {
    print "not ok - 2 $^X $__FILE__ die ('-' =~ /ㄲ[ㄴ-ㄲ]/).\n";
}
unlink("$script");
unlink("$script.e");

__END__

