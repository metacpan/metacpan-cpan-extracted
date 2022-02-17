#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Devel::Deanonymize qw(alterContent);

sub read_file {
    my $path = shift;
    my $fh;
    open $fh, '<', $path or die "Can't open `$path`: $!";
    my $file_content = do {
        local $/;
        <$fh>
    };
    return $file_content;
}


my @files = ("Dummy0.pm", "Dummy1.pm", "Dummy2.pm", "Dummy3.pm", "Dummy4.pm", "Dummy5.pm");
my @test_titles = (
    "`1;` endmarker, with evil variables ",
    "`1;` endmarker, with evil comment",
    "`__END__` endmarker, with anon sub",
    "`1;` endmarker, open =cut section",
    "`1` endmarker, no semicolon",
    "No endmarker"
);
for my $idx (0 .. $#files) {
    my $input = read_file("t/test_data/$files[$idx]");
    my $expected = read_file("t/test_data/$files[$idx]_exp");
    my $res1 = Devel::Deanonymize::alterContent($input, "wrapper_$idx");
    # if ($files[$idx] eq "Dummy3.pm") {
    #     print $res1;
    # }
    ok $res1 eq $expected, $files[$idx] .": ". $test_titles[$idx];
    eval($res1);
    if ($@) {
        print $@ . "\n";
        fail "eval failed";
    }
    else {
        ok 1, "$files[$idx]: eval modified ";
    }
}
done_testing();

