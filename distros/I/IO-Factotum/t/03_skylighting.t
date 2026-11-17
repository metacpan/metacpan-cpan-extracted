use v5.16;
use warnings;
use Test::More 0.98;
use File::Temp qw(tempdir);
use File::Spec;

BEGIN {
    my $found = grep { -x "$_/skylighting" } File::Spec->path;
    plan skip_all => 'skylighting is not installed' unless $found;
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

put 'a.c',   "int x = 1;\n";
put 'e.c',   "\e[31mred\e[m\n";
put 'noext', "#!/bin/bash\necho\n";

# the module registers its converter, without tying ARGV when it is
# only required
require IO::Factotum::Highlight::skylighting;
IO::Factotum::Highlight::skylighting::setup();
ok !tied(*ARGV), 'setup does not tie ARGV';

subtest 'skylighting: C source' => sub {
    my $out = slurp(IO::Factotum::open_input("$dir/a.c"));
    like $out, qr/\e\[/, 'has colors';
    like $out, qr/int/, 'has the text';
    # -S pygments has no background, -C 16 no 256 or RGB colors
    unlike $out, qr/\e\[[0-9;]*\b(?:4[0-7]|10[0-7]|[34]8)\b/, 'no background, 16 colors';
};

subtest 'skylighting: empty lines stay empty' => sub {
    put 'b.c', "int x;\n\nint y;\n";
    my @lines = IO::Factotum::open_input("$dir/b.c")->getlines;
    is scalar @lines, 3, 'three lines';
    like $lines[0], qr/\e\[/, 'colored';
    is $lines[1], "\n", 'the empty line has no sequence';
};

# skylighting puts \e[22;23;24m after every reset.  A line which ends
# with two sequences makes Text::ANSI::Fold give an empty line after it
# when the text fills the width.
subtest 'skylighting: a line ends with one reset' => sub {
    my $out = slurp(IO::Factotum::open_input("$dir/a.c"));
    unlike $out, qr/\e\[[0-9;]*m\e\[[0-9;]*m$/m, 'not two sequences at the end';
    unlike $out, qr/\e\[0m\e\[0m/, 'no reset twice';
    like $out, qr/\e\[0m$/m, 'reset at the end';
    (my $text = $out) =~ s/\e\[[0-9;]*m//g;
    is $text, "int x = 1;\n", 'the text is the same';
};

subtest 'skylighting: CRLF' => sub {
    put 'crlf.c', "int x;\r\nint y;\r\n";
    my $out = slurp(IO::Factotum::open_input("$dir/crlf.c"));
    like $out, qr/\e\[/, 'colored';
    is scalar(() = $out =~ /\r\n/g), 2, 'CR and LF stay together';
    is scalar(() = $out =~ /\R/g), 2, 'two line ends';
};

subtest 'skylighting: large and empty files' => sub {
    put 'empty.c', "";
    is slurp(IO::Factotum::open_input("$dir/empty.c")), "", 'an empty file is empty';
    put 'big.c', "int x;\n" x 100;
    local $IO::Factotum::Highlight::skylighting::MAX_SIZE = 700;
    like slurp(IO::Factotum::open_input("$dir/big.c")), qr/\e\[/, 'within the limit';
    local $IO::Factotum::Highlight::skylighting::MAX_SIZE = 699;
    is slurp(IO::Factotum::open_input("$dir/big.c")), "int x;\n" x 100,
	'a file over the limit is as it is';
    local $IO::Factotum::Highlight::skylighting::MAX_SIZE = 0;
    like slurp(IO::Factotum::open_input("$dir/big.c")), qr/\e\[/, 'no limit by 0';
};

subtest 'skylighting: file with ESC' => sub {
    is slurp(IO::Factotum::open_input("$dir/e.c")), "\e[31mred\e[m\n",
	'as it is';
};

subtest 'skylighting: no extension' => sub {
    put 'plain', "some text\nwith no interpreter\n";
    is slurp(IO::Factotum::open_input("$dir/plain")),
	"some text\nwith no interpreter\n", 'as it is';
    put 'unknown', "#!/usr/local/bin/nosuchlanguage\ntext\n";
    is slurp(IO::Factotum::open_input("$dir/unknown")),
	"#!/usr/local/bin/nosuchlanguage\ntext\n", 'unknown interpreter: as it is';
};

# A file whose name does not tell the language is taken as the script
# of the interpreter on its first line
subtest 'skylighting: interpreter line' => sub {
    my $text = sub { $_[0] =~ s/\e\[[0-9;]*m//gr };
    for (
	[ 'noext',   "#!/bin/bash\necho hello\n" ],
	[ 'env',     "#!/usr/bin/env perl\nmy \$x = 1;\n" ],
	[ 'envopt',  "#!/usr/bin/env -S perl -w\nmy \$x = 1;\n" ],
	[ 'version', "#!/usr/bin/python3\nx = 1\n" ],
	[ 'perl5',   "#! /usr/local/bin/perl5.36 -w\nmy \$x = 1;\n" ],
	[ 'node',    "#!/usr/bin/env node\nvar x = 1;\n" ],
    ) {
	my($name, $content) = @$_;
	put $name, $content;
	my $out = slurp(IO::Factotum::open_input("$dir/$name"));
	like $out, qr/\e\[/, "$name: colored";
	is $text->($out), $content, "$name: the text is the same";
    }
};

subtest 'skylighting: interpreter' => sub {
    my $interp = \&IO::Factotum::Highlight::skylighting::interpreter;
    is $interp->("#!/bin/sh\n"), 'sh';
    is $interp->("#!/usr/bin/env perl\n"), 'perl';
    is $interp->("#!/usr/bin/env -S perl -w\n"), 'perl';
    is $interp->("#!/usr/bin/env FOO=1 python3\n"), 'python';
    is $interp->("#! /usr/local/bin/perl5.36 -w\n"), 'perl';
    is $interp->("#!/usr/bin/env node\n"), 'javascript';
    is $interp->("#!/usr/bin/tclsh8.6\n"), 'tcl';
    is $interp->("#!/bin/ksh\n"), 'bash';
    is $interp->("# not an interpreter line\n"), undef;
    is $interp->("#!\n"), undef;
    is $interp->(""), undef;
};

subtest 'skylighting: setup twice' => sub {
    IO::Factotum::Highlight::skylighting::setup();
    like slurp(IO::Factotum::open_input("$dir/a.c")), qr/\e\[/;
};

subtest 'skylighting: -M ties ARGV' => sub {
    my $out = qx{$^X -I"$lib" -MIO::Factotum::Highlight::skylighting -ne 'print "\$ARGV: \$_"' "$dir/a.c" 2>&1};
    like $out, qr/^\Q$dir\E\/a\.c: .*\e\[/, 'one-liner reads the colored text';
};

subtest 'Getopt::EX::Factotum: load' => sub {
    my $script = put 'load.pl', q{
	use Getopt::EX::Factotum;
	Getopt::EX::Factotum::load(q(Highlight::skylighting) => 1);
	print tied(*ARGV) ? "tied\n" : "not tied\n";
	print IO::Factotum::open_input(shift)->getlines;
    };
    my $out = qx{$^X -I"$lib" "$script" "$dir/a.c" 2>&1};
    like $out, qr/\Anot tied\n/, 'ARGV is not tied';
    like $out, qr/\e\[/, 'has colors';
};

subtest 'load' => sub {
    my $script = put 'ioload.pl', q{
	use IO::Factotum;
	IO::Factotum::load('Highlight::skylighting');
	print tied(*ARGV) ? "tied\n" : "not tied\n";
	print IO::Factotum::open_input(shift)->getlines;
    };
    my $out = qx{$^X -I"$lib" "$script" "$dir/a.c" 2>&1};
    like $out, qr/\Anot tied\n/, 'ARGV is not tied';
    like $out, qr/\e\[/, 'has colors';
    ok !eval { IO::Factotum::load('nosuchconverter'); 1 }, 'unknown name dies';
    like $@, qr/nosuchconverter: no such converter/, 'with the name';
    ok !eval { IO::Factotum::load('a b'); 1 }, 'invalid name dies';
};

subtest 'Getopt::EX::Factotum: unknown name' => sub {
    my $script = put 'unknown.pl', q{
	use Getopt::EX::Factotum;
	Getopt::EX::Factotum::load(nosuchconverter => 1);
    };
    my $out = qx{$^X -I"$lib" "$script" 2>&1};
    isnt $?, 0, 'fails';
    like $out, qr/nosuchconverter/, 'with the name';
};

done_testing;
