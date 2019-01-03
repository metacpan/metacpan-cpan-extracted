######################################################################
#
# make_test_A_by_B.pl
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict; die $_ if ($_=`$^X -cw @{[__FILE__]} 2>&1`) !~ /^.+ syntax OK$/;
use FindBin;
use lib "$FindBin::Bin/../lib";

my @data = ();
open(JACODE4E,"$FindBin::Bin/../lib/Jacode4e.pm") || die;
while (<JACODE4E>) {
    if (/^__DATA__$/) {
        chomp(@data = grep( ! /^#/, <JACODE4E>));
        last;
    }
}
close(JACODE4E);

my @encoding = qw( cp932x cp932 sjis2004 cp00930 keis78 keis83 keis90 jef jipsj jipse letsj unicode utf8 utf8jp );
my @io_encoding = (grep( ! /^unicode$/, @encoding), 'jef9p');
my %geta = (
    'cp932x'   => '81AC',
    'cp932'    => '81AC',
    'sjis2004' => '81AC',
    'cp00930'  => '447D',
    'keis78'   => 'A2AE',
    'keis83'   => 'A2AE',
    'keis90'   => 'A2AE',
    'jef'      => 'A2AE',
    'jef9p'    => 'A2AE',
    'jipsj'    => '222E',
    'jipse'    => '7F4B',
    'letsj'    => 'A2AE',
    'utf8'     => 'E38093',
    'utf8jp'   => 'F3B085AB',
);

my $fileno = 1001;
for my $INPUT_encoding (@io_encoding) {
    for my $OUTPUT_encoding (@io_encoding) {
        my $filename = sprintf("%04d_${OUTPUT_encoding}_by_${INPUT_encoding}.t", $fileno++);
print STDERR $filename, "\n";
        mkdir('xt',0777);
        open(TEST,">xt/$filename") || die;
        binmode(TEST);
        printf TEST (<<'END___________________________________________________________________',$filename);
######################################################################
#
# %s
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use vars qw(@test);
    @test = (
END___________________________________________________________________

        for (@data) {
            my %data = ();
            @data{@encoding} = split(/ +/,$_);
            $data{'jef9p'} = $data{'jef'};
            if ($data{$INPUT_encoding} !~ /^[0123456789ABCDEF]+$/) {
                next;
            }
            my $input = '';
            if (1) {
                $input = join('', map {"\\x$_"} ($data{$INPUT_encoding}  =~ /([0123456789ABCDEF]{2})/g));
            }
            my $output = '';
            if ($data{$OUTPUT_encoding} =~ /^[0123456789ABCDEF]+$/) {
                $output = join('', map {"\\x$_"} ($data{$OUTPUT_encoding} =~ /([0123456789ABCDEF]{2})/g));
            }
            else {
                $output = join('', map {"\\x$_"} ($geta{$OUTPUT_encoding} =~ /([0123456789ABCDEF]{2})/g));
            }
            printf TEST ' ' x 8;
            printf TEST (qq{["%s",'%s','%s',{'INPUT_LAYOUT'=>'%s'},"%s"],\n},
                $input,
                $OUTPUT_encoding,
                $INPUT_encoding,
                ($input =~ /^\\x[0123456789ABCDEF]{2}$/) ? 'S' : 'D',
                $output,
            );
        }

        print TEST <<'END___________________________________________________________________';
    );
    $|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }
}

use Jacode4e;

for my $test (@test) {
    my($give,$OUTPUT_encoding,$INPUT_encoding,$option,$want) = @{$test};
    my $got = $give;
    my $return = Jacode4e::convert(\$got,$OUTPUT_encoding,$INPUT_encoding,$option);

    my $option_content = '';
    if (defined $option) {
        my @option_content = ();
        push(@option_content, qq{INPUT_LAYOUT=>$option->{'INPUT_LAYOUT'}})        if exists $option->{'INPUT_LAYOUT'};
        push(@option_content, qq{OUTPUT_SHIFTING=>$option->{'OUTPUT_SHIFTING'}})  if exists $option->{'OUTPUT_SHIFTING'};
        push(@option_content, qq{SPACE=>@{[uc unpack('H*',$option->{'SPACE'})]}}) if exists $option->{'SPACE'};
        push(@option_content, qq{GETA=>@{[uc unpack('H*',$option->{'GETA'})]}})   if exists $option->{'GETA'};
        $option_content = "{@option_content}";
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
