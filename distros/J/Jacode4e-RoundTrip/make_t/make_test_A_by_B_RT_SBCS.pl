######################################################################
#
# make_test_A_by_B_RT_SBCS.pl
#
# Copyright (c) 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict; die $_ if ($_=`$^X -cw @{[__FILE__]} 2>&1`) !~ /^.+ syntax OK$/;
use FindBin;
use lib "$FindBin::Bin/../lib";

my @encoding = qw( cp932x cp932 sjis2004 cp00930 keis78 keis83 keis90 jef jipsj jipse letsj unicode utf8 utf8jp );

my %tr = ();
open(JACODE4E_ROUNDTRIP,"$FindBin::Bin/../lib/Jacode4e/RoundTrip.pm") || die;
while (<JACODE4E_ROUNDTRIP>) {
    if (/^__DATA__$/) {
        last;
    }
}
while (<JACODE4E_ROUNDTRIP>) {
    chomp;
    my %hex = ();
    @hex{@encoding} = split(/ +/,$_);
    for my $encoding (@encoding) {
        if ($hex{$encoding} =~ /^[0123456789ABCDEF]+$/) {
            $tr{$encoding}{'utf8jp'}{$hex{$encoding}} = $hex{'utf8jp'};
            $tr{'utf8jp'}{$encoding}{$hex{'utf8jp'}}  = $hex{$encoding};
        }
    }
}
close(JACODE4E_ROUNDTRIP);

my @io_encoding = (grep( ! /^(unicode)$/, @encoding), 'jef9p');

my $fileno = 4001;
for my $INPUT_encoding (@io_encoding) {
    for my $OUTPUT_encoding (@io_encoding) {
        my $filename = sprintf("%04d_${OUTPUT_encoding}_by_${INPUT_encoding}_RT_SBCS.t", $fileno++);
print STDERR $filename, "\n";
        mkdir('xt',0777);
        open(TEST,">xt/$filename") || die;
        binmode(TEST);
        printf TEST (<<'END___________________________________________________________________',$filename);
######################################################################
#
# %s
#
# Copyright (c) 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use vars qw(@test);
    @test = (
END___________________________________________________________________

        (my $_INPUT_encoding  = $INPUT_encoding)  =~ s/^jef9p$/jef/;
        (my $_OUTPUT_encoding = $OUTPUT_encoding) =~ s/^jef9p$/jef/;

        for my $octet1 (0x00 .. 0xFF) {
            my $hex_utf8jp = $tr{'cp932x'}{'utf8jp'}{sprintf('%02X',$octet1)};
            my $input  = join('', map {"\\x$_"} ($tr{'utf8jp'}{$_INPUT_encoding }{$hex_utf8jp} =~ /\G(..)/gc));
            my $output = join('', map {"\\x$_"} ($tr{'utf8jp'}{$_OUTPUT_encoding}{$hex_utf8jp} =~ /\G(..)/gc));

            printf TEST ' ' x 8;
            printf TEST (qq{["%s%s",'%s','%s',{'INPUT_LAYOUT'=>'%s'},"%s%s"],\n},
                $input,
                ($_INPUT_encoding eq 'utf8jp') ? '\\xF3\\xB0\\x80\\x80' : '\\x00',
                $_OUTPUT_encoding,
                $_INPUT_encoding,
                'SS',
                $output,
                ($_OUTPUT_encoding eq 'utf8jp') ? '\\xF3\\xB0\\x80\\x80' : '\\x00',
            );

            # do test again
            printf TEST ' ' x 8;
            printf TEST (qq{["%s%s",'%s','%s',{'INPUT_LAYOUT'=>'%s'},"%s%s"],\n},
                $output,
                ($_OUTPUT_encoding eq 'utf8jp') ? '\\xF3\\xB0\\x80\\x80' : '\\x00',
                $_INPUT_encoding,
                $_OUTPUT_encoding,
                'SS',
                $input,
                ($_INPUT_encoding eq 'utf8jp') ? '\\xF3\\xB0\\x80\\x80' : '\\x00',
            );

            printf TEST "\n";
        }

        print TEST <<'END___________________________________________________________________';
    );
    $|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }
}

use Jacode4e::RoundTrip;

for my $test (@test) {
    my($give,$OUTPUT_encoding,$INPUT_encoding,$option,$want) = @{$test};
    my $got = $give;
    my $return = Jacode4e::RoundTrip::convert(\$got,$OUTPUT_encoding,$INPUT_encoding,$option);

    my $option_content = '';
    if (defined $option) {
        $option_content .= qq{INPUT_LAYOUT=>$option->{'INPUT_LAYOUT'}}        if exists $option->{'INPUT_LAYOUT'};
        $option_content .= qq{OUTPUT_SHIFTING=>$option->{'OUTPUT_SHIFTING'}}  if exists $option->{'OUTPUT_SHIFTING'};
        $option_content .= qq{SPACE=>@{[uc unpack('H*',$option->{'SPACE'})]}} if exists $option->{'SPACE'};
        $option_content .= qq{GETA=>@{[uc unpack('H*',$option->{'GETA'})]}}   if exists $option->{'GETA'};
        $option_content = "{$option_content}";
    }

    ok(($return > 0) and ($got eq $want),
        sprintf(qq{$INPUT_encoding(%s) to $OUTPUT_encoding(%s), $option_content => return=$return,got=(%s)},
            uc unpack('H*',$give),
            uc unpack('H*',$want),
            uc unpack('H*',$got),
        )
    );
}

__END__
END___________________________________________________________________
        close(TEST);
    }
}

__END__
