######################################################################
#
# 001_test.t for testing jacode.pl
#
# Copyright (c) 2010, 2011, 2014, 2015, 2016 INABA Hitoshi <ina@cpan.org>
#
######################################################################

print "1..64\n";
$switch = '';
if ($^X =~ /jperl/i) {
    if (`$^X -e "print \$]"` =~ /^5\./) {
        $switch = '-b';
    }
    else {
        $switch = '-Llatin';
    }
}

$tno = 1;

%testdata = split(' ',<<END);
    h2z_jis.pl    han
    h2z_sjis.pl   han
    h2z_euc.pl    han
    h2z_utf8.pl   han
    z2h_jis.pl    zen
    z2h_sjis.pl   zen
    z2h_euc.pl    zen
    z2h_utf8.pl   zen
    JIStoEUC.pl   jis
    JIStoSJIS.pl  jis
    JIStoUTF8.pl  jis
    SJIStoJIS.pl  sjis
    SJIStoEUC.pl  sjis
    SJIStoUTF8.pl sjis
    EUCtoJIS.pl   euc
    EUCtoSJIS.pl  euc
    EUCtoUTF8.pl  euc
    UTF8toJIS.pl  utf8
    UTF8toSJIS.pl utf8
    UTF8toEUC.pl  utf8
END

chdir('t');

for $libname ('jcode_', 'jacode_') {
    for $script (sort keys %testdata) {
        if (-e "$testdata{$script}.txt") {
            if (-e "$script.got") {
                unlink("$script.got") || die;
            }
            open(GOT,">$script.got") || die;
            print GOT `$^X $switch -I.. $libname$script $testdata{$script}.txt`;
            close(GOT);
            if (&filecompare("$script.want","$script.got")) {
                print "ok - $tno $libname$script (Kanji)\n";
            }
            else{
                print "not ok - $tno $libname$script (Kanji)\n";
            }
            $tno++;
        }
        if (-e "$testdata{$script}.kana.txt") {
            if (-e "$script.kana.got") {
                unlink("$script.kana.got") || die;
            }
            open(GOT,">$script.kana.got") || die;
            print GOT `$^X $switch -I.. $libname$script $testdata{$script}.kana.txt`;
            close(GOT);
            if (&filecompare("$script.kana.want","$script.kana.got")) {
                print "ok - $tno $libname$script (Kana)\n";
            }
            else{
                print "not ok - $tno $libname$script (Kana)\n";
            }
            $tno++;
        }
    }
}

chdir('..');

sub filecompare {
    local ($file1, $file2) = @_;
    open(FILE1, $file1) || die "Can't open file: $file1";
    open(FILE2, $file2) || die "Can't open file: $file2";
    while(<FILE1>){
        $_2 = <FILE2>;
        $_  =~ s/(\r\n|\r|\n)+$//;
        $_2 =~ s/(\r\n|\r|\n)+$//;
        if($_ ne $_2){
            print "file compare:\n";
            if (0) {
                @_1 = $_  =~ /([\x00-\xff][\x00-\xff])/g;
                @_2 = $_2 =~ /([\x00-\xff][\x00-\xff])/g;

                while (@_2) {
                    $_1 = shift @_1;
                    $_2 = shift @_2;
                    if ($_1 ne $_2) {
                        $hex1 = unpack( 'H*', $_1 );
                        $hex2 = unpack( 'H*', $_2 );
                        print "[$_1]$hex1 <=> [$_2]$hex2\n";
                    }
                }
            }
            else {
                print "want[$_]\n";
                print " got[$_2]\n";
                close(FILE1);
                close(FILE2);
            }
            return 0;
        }
    }
    if(!eof(FILE1)){
        close(FILE1);
        close(FILE2);
        return 0;
    }
    if(!eof(FILE2)){
        close(FILE1);
        close(FILE2);
        return 0;
    }
    close(FILE1);
    close(FILE2);
    return 1;
}

1;
__END__
