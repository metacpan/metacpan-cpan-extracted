#!/usr/bin/perl

use strict;
use warnings;

use lib qw( t/lib );

use Test::More;
use Test::Framework;

use Fcntl qw( :seek );
use File::BOM qw( %enc2bom );

# Expected data for "moose" tests (below)
our %should_be = (
    'UTF-8'    => "\x{ef}\x{bb}\x{bf}m\x{c3}\x{b8}\x{c3}\x{b8}se\x{e2}\x{80}\x{a6}",
    'UTF-16BE' => "\x{fe}\x{ff}\x{0}m\x{0}\x{f8}\x{0}\x{f8}\x{0}s\x{0}e &",
    'UTF-16LE' => "\x{ff}\x{fe}m\x{0}\x{f8}\x{0}\x{f8}\x{0}s\x{0}e\x{0}& ",
    'UTF-32BE' => "\x{0}\x{0}\x{fe}\x{ff}\x{0}\x{0}\x{0}m\x{0}\x{0}\x{0}\x{f8}\x{0}\x{0}\x{0}\x{f8}\x{0}\x{0}\x{0}s\x{0}\x{0}\x{0}e\x{0}\x{0} &",
    'UTF-32LE' => "\x{ff}\x{fe}\x{0}\x{0}m\x{0}\x{0}\x{0}\x{f8}\x{0}\x{0}\x{0}\x{f8}\x{0}\x{0}\x{0}s\x{0}\x{0}\x{0}e\x{0}\x{0}\x{0}& \x{0}\x{0}",
);

plan tests => 2 * @test_files + 6 * keys(%enc2bom) + keys(%should_be) + 2;

# Work around bug in older PerlIO::via
# The PerlIO::via version number was not incremented when the bug was fixed.
my $compat = $] >= 5.008007 ? '' : ':utf8';

# Ignore known harmless warning
local $SIG{__WARN__} = sub {
    my $warning = "@_";
    if ($warning !~ /^UTF-(?:16|32)LE:Partial character/) {
	warn $warning;
    }
};

for my $test_file (@test_files) {
    ok(
	open(FH, "<:via(File::BOM)$compat", $file2path{$test_file}),
	"$test_file: opened through layer"
    ) or diag "$test_file: $!";

    my $line = <FH>; chomp $line; 
    is($line, $filecontent{$test_file}, "$test_file: read OK through layer")
	or diag("HEX: ".hexdump($line));
    close FH;
}

for my $enc (sort keys %enc2bom) {
    my $file = "test_file-$enc.txt";
    ok(
	open(BOM_OUT, ">:encoding($enc):via(File::BOM)$compat", $file),
	"Opened file for writing $enc via layer"
    ) or diag "$file: $!";

    my $line_one = "Unicode text\x{2026}";
    my $test = print(BOM_OUT "$line_one\n");
    ok($test, 'print() through layer')
	or diag("print() returned ". (defined($test)?$test:'undef'));

    my $line_two = "\x{62cd}\x{8ce3}";
    $test = print(BOM_OUT "$line_two\n");
    ok($test, 'print() through layer again')
	or diag("print() returned ". (defined($test)?$test:'undef'));

    close BOM_OUT;

    # check BOM
    if (open my $fh, '<:bytes', $file) {
	read $fh, my $sample, $File::BOM::MAX_BOM_LENGTH;
	like($sample, qr/^\Q$enc2bom{$enc}/, "BOM written correctly");
	close $fh;
    }
    else {
	diag "Couldn't open $file: $!";
	fail(1);
    }

    # now re-read
    my $line;
    open(BOM_IN, "<:via(File::BOM)$compat", $file);

    $line = <BOM_IN>; chomp $line;
    is($line, $line_one, 'BOM was written successfully via layer');

    $line = <BOM_IN>; chomp $line;
    is($line, $line_two, 'BOM not written in second print call');

    close BOM_IN;

    unlink $file or diag "Couldn't remove $file: $!";
}

# Mark Fowler's "moose" test:
{
    # This is 'moose...' (with slashes in the 'o's them, and the '...'
    # as one char).  As the '...' can't be represented in latin-1 then
    # perl will store the thing internally as a utf8 string with the
    # utf8 flag enabled.
    my $moose = "m\x{f8}\x{f8}se\x{2026}";

    for my $enc (keys %should_be) {
	my $file = "moose-$enc.txt";
	open(FH, ">:encoding($enc):via(File::BOM)$compat", $file) or die "Can't write to $file: $!\n";
	print FH $moose;
	close FH;

	open(FH, '<', $file) or die "Can't read $file: $!\n";
	local $/ = undef;
	my $value = <FH>;
	close FH;

	is(
	    reasciify($value),
	    reasciify($should_be{$enc}),
	    "check file for $enc"
	);

	unlink $file or diag "Can't remove '$file': $!";
    }
}

# Spurkis' seek test
{
    use utf8;
    my $file = 't/data/utf8_data.csv';

    open my $fh, '>:utf8', $file or die "Can't write $file: $!";
    print $fh <<"END_DATA";
\x{feff}id,street,town,pc,country,english,french,chinese,arabic
'10,"écoles",zoom,12,france,auctions,"Enchères","拍賣","مزاد"
END_DATA

    open $fh, '<:via(File::BOM)', $file
	or die "Can't read $file: $!\n";

    my $first_line = <$fh>;
    my $pos = tell($fh); # position of second line
    my $rest = join('', <$fh>);

    seek($fh, 0, SEEK_SET) or die "Couldn't seek: $!";

    my $new_first_line = <$fh>;
    seek($fh, $pos, SEEK_SET) or die "Couldn't seek: $!";
    my $new_rest = join('', <$fh>);

    is($new_first_line, $first_line, "seek() works");
    is($new_rest,	      $rest, "tell() works")
	or diag "Position was $pos";

    close $fh;

    unlink $file or warn "Couldn't remove $file: $!\n";
}

# sub for moose test
sub reasciify {
    my $string = shift;
    $string = join "", map {
    my $ord = ord($_);
	($ord > 127 || ($ord < 32 && $ord != 10))
	? sprintf '\x{%x}', $ord
	: $_
    } split //, $string
}

__END__

vim: ft=perl
