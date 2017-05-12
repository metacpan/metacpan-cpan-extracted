#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing new
{
use_ok('MasonX::StaticBuilder');
my $t = MasonX::StaticBuilder->new(".");
isa_ok($t, 'MasonX::StaticBuilder');
can_ok($t, qw(input_dir));

my $no = MasonX::StaticBuilder->new("this/directory/does/not/exist");
is($no, undef, "return undef if dir doesn't exist");
}



# =begin testing write
{
my $t = MasonX::StaticBuilder->new("t/test-input-dir");
system "rm -rf t/test-output-dir";
mkdir("t/test-output-dir");
$t->write("t/test-output-dir", foo => "bar");

my %expected_contents = (
    simple => "bugger all",
    expr   => 42,
    args   => "Foo is bar",
    init   => "Baz is quux",
    "sub-component" => "bugger all",
    "autohandler-dir/ahtest" => "This is a header",
    "autohandler-dir/ahtest" => "autohandler goodness",
);

foreach my $file (sort keys %expected_contents) {
    my $fullfile = "t/test-output-dir/$file";
    open FILE, "<", $fullfile;
    local $/ = undef;
    my $file_contents = <FILE>;
    like(
        $file_contents,
        qr($expected_contents{$file}),
        "File $file expanded correctly."
    );
    close FILE;
}
}




1;
