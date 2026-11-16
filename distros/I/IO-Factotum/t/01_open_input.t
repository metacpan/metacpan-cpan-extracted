use v5.16;
use warnings;
use Test::More 0.98;
use File::Temp qw(tempdir);

use IO::Factotum;

my $dir = tempdir(CLEANUP => 1);

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

put 'a.up',   "hello\n";
put 'a.txt',  "hello\n";
put 'a b.up', "hello\n";

my @upper = (match => qr/\.up$/, command => ['perl', '-pe', '$_ = uc']);

subtest 'open_input: converted' => sub {
    IO::Factotum::clear();
    IO::Factotum::register(@upper);
    my $fh = IO::Factotum::open_input("$dir/a.up");
    isa_ok $fh, 'IO::File';
    is slurp($fh), "HELLO\n", 'content is converted';
    is slurp(IO::Factotum::open_input("$dir/a.up")), "HELLO\n", 'again';
};

subtest 'open_input: not matched' => sub {
    IO::Factotum::clear();
    IO::Factotum::register(@upper);
    my $fh = IO::Factotum::open_input("$dir/a.txt");
    isa_ok $fh, 'IO::File';
    is slurp($fh), "hello\n", 'content is as it is';
};

subtest 'open_input: no converter' => sub {
    IO::Factotum::clear();
    is slurp(IO::Factotum::open_input("$dir/a.up")), "hello\n";
};

subtest 'open_input: converter fails' => sub {
    IO::Factotum::clear();
    IO::Factotum::register(match => qr/\.up$/, command => ['false']);
    is slurp(IO::Factotum::open_input("$dir/a.up")), "hello\n",
	'the file itself is read';
};

subtest 'open_input: first match wins' => sub {
    IO::Factotum::clear();
    IO::Factotum::register(@upper);
    IO::Factotum::register(match => qr/\.up$/, command => ['false']);
    is slurp(IO::Factotum::open_input("$dir/a.up")), "HELLO\n";
};

subtest 'open_input: code reference' => sub {
    IO::Factotum::clear();
    IO::Factotum::register(
	match   => sub { $_[0] =~ /\.up$/ },
	command => [ sub {
	    open my $f, '<', $_[-1] or die;
	    print scalar reverse do { local $/; <$f> };
	} ]);
    is slurp(IO::Factotum::open_input("$dir/a.up")), "\nolleh";
    is slurp(IO::Factotum::open_input("$dir/a.txt")), "hello\n",
	'code match is false';
};

subtest 'open_input: file name with a space' => sub {
    IO::Factotum::clear();
    IO::Factotum::register(@upper);
    is slurp(IO::Factotum::open_input("$dir/a b.up")), "HELLO\n";
};

subtest 'open_input: missing file' => sub {
    IO::Factotum::clear();
    IO::Factotum::register(@upper);
    my $fh = IO::Factotum::open_input("$dir/none.txt");
    ok !defined $fh, 'undef';
    ok $!{ENOENT}, 'errno';
    $fh = IO::Factotum::open_input("$dir/none.up");
    ok !defined $fh, 'undef for a name that matches';
    ok $!{ENOENT}, 'errno';
};

subtest 'open_input: stdin' => sub {
    my $script = put 'stdin.pl', q{
	use IO::Factotum;
	IO::Factotum::register(match => qr/./, command => ['perl', '-pe', '$_ = uc']);
	print IO::Factotum::open_input('-')->getlines;
    };
    my $out = qx{echo hello | $^X -Ilib "$script"};
    is $out, "hello\n", 'stdin is not converted';
};

subtest 'open_input: bytes' => sub {
    IO::Factotum::clear();
    my $utf8 = "\xe3\x81\x82\n";	# U+3042 in UTF-8
    put 'j.up',  $utf8;
    put 'j.txt', $utf8;
    IO::Factotum::register(match => qr/\.up$/, command => ['cat']);
    is slurp(IO::Factotum::open_input("$dir/j.up")),  $utf8, 'converted';
    is slurp(IO::Factotum::open_input("$dir/j.txt")), $utf8, 'as it is';
};

done_testing;
