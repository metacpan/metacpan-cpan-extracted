use v5.16;
use warnings;
use Test::More 0.98;
use File::Temp qw(tempdir);
use File::Spec;

BEGIN {
    my $found = grep { -x "$_/source-highlight" } File::Spec->path;
    plan skip_all => 'source-highlight is not installed' unless $found;
}

use IO::Factotum;

my $dir = tempdir(CLEANUP => 1);
my $lib = File::Spec->rel2abs('lib');

sub put {
    my($name, $text) = @_;
    open my $fh, '>', "$dir/$name" or die "$name: $!";
    print $fh $text;
    close $fh;
    "$dir/$name";
}

sub slurp {
    my $fh = shift;
    local $/;
    scalar <$fh>;
}

my $text = sub { $_[0] =~ s/\e\[[0-9;]*m//gr };

IO::Factotum::load('sourcehighlight');
ok !tied(*ARGV), 'load does not tie ARGV';

subtest 'sourcehighlight: C source' => sub {
    my $c = "int x = 1; // c\n\nchar *s = \"str\";\n";
    put 'a.c', $c;
    my $out = slurp(IO::Factotum::open_input("$dir/a.c"));
    like $out, qr/\e\[/, 'has colors';
    is $text->($out), $c, 'the text is the same';
    is((split /^/, $out)[1], "\n", 'the empty line has no sequence');
    unlike $out, qr/\e\[[0-9;]*m\e\[[0-9;]*m$/m, 'not two sequences at the end of a line';
};

subtest 'sourcehighlight: interpreter line' => sub {
    my $perl = "#!/usr/bin/env perl\nmy \$x = 1;\n";
    put 'script', $perl;
    my $out = slurp(IO::Factotum::open_input("$dir/script"));
    like $out, qr/\e\[/, 'has colors';
    is $text->($out), $perl, 'the text is the same';
};

subtest 'sourcehighlight: files left as they are' => sub {
    put 'plain', "some text\nwith no language\n";
    is slurp(IO::Factotum::open_input("$dir/plain")),
	"some text\nwith no language\n", 'unknown language';
    put 'e.c', "\e[31mred\e[m\n";
    is slurp(IO::Factotum::open_input("$dir/e.c")), "\e[31mred\e[m\n",
	'a file with ESC';
    put 'empty.c', "";
    is slurp(IO::Factotum::open_input("$dir/empty.c")), "", 'an empty file';
    put 'big.c', "int x;\n" x 100;
    local $IO::Factotum::sourcehighlight::MAX_SIZE = 699;
    is slurp(IO::Factotum::open_input("$dir/big.c")), "int x;\n" x 100,
	'a file over the limit';
    local $IO::Factotum::sourcehighlight::MAX_SIZE = 700;
    like slurp(IO::Factotum::open_input("$dir/big.c")), qr/\e\[/, 'within the limit';
};

subtest 'sourcehighlight: style' => sub {
    put 'a.c', "int x = 1;\n";
    local @IO::Factotum::sourcehighlight::STYLE = ('--style-file=nosuchstyle.style');
    is slurp(IO::Factotum::open_input("$dir/a.c")), "int x = 1;\n",
	'a style which is not found leaves the file as it is';
};

subtest 'sourcehighlight: -M ties ARGV' => sub {
    put 'a.c', "int x = 1;\n";
    my $out = qx{$^X -I"$lib" -MIO::Factotum::sourcehighlight -ne 'print "\$ARGV: \$_"' "$dir/a.c" 2>&1};
    like $out, qr/^\Q$dir\E\/a\.c: .*\e\[/, 'one-liner reads the colored text';
};

done_testing;
