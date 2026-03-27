#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

plan tests => 6;

my $tempdir;
my $file;
BEGIN {
    $tempdir = File::Temp::tempdir(CLEANUP => 1);
    $file = File::Spec->catfile($tempdir, 'test-format.log');
}

{
    package TestFormat;

    use Medusa::XS (
        LOG_FILE => $file,
        FORMAT_MESSAGE => sub {
            my %params = @_;
            return sprintf("CUSTOM|%s|%s",
                $params{level},
                $params{message},
            );
        },
    );

    sub new { bless {}, $_[0]; }

    sub greet :Audit {
        my ($self, $name) = @_;
        return "hello $name";
    }
}

my $obj = TestFormat->new();
my $result = $obj->greet('world');
is($result, 'hello world', 'audited sub returns correct value');

open my $fh, '<', $file or die "Cannot open $file: $!";
my $content = do { local $/; <$fh> };
close $fh;

my @lines = split "\n", $content;

like($lines[0], qr/^CUSTOM\|/, 'custom format applied to call log');
like($lines[0], qr/\|debug\|/, 'custom format includes level');
like($lines[0], qr/called with args/, 'custom format includes call message');
like($lines[1], qr/^CUSTOM\|/, 'custom format applied to return log');
like($lines[1], qr/returned/, 'custom format includes return message');

done_testing();
