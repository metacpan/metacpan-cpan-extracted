# IO::Callback 1.08 t/callback.t
# Check the interface to the callback coderef

use strict;
use warnings;

use Test::More tests => 11;
use Test::Exception;
use Test::NoWarnings;

use IO::Callback;

foreach my $ret_eof ('return', 'return undef', 'return ""') {
    my @blocks = ('foo', 'bar', 'RETURN_EOF', 'baz');
    my $callback = eval <<EOF; die $@ if $@;
        sub {
            my \$blocks = shift;
            my \$ret = shift \@\$blocks;
            $ret_eof if \$ret eq 'RETURN_EOF';
            return \$ret;
        }
EOF
    my $fh = IO::Callback->new('<', $callback, \@blocks);
    my $got = join '', <$fh>;
    is $got, "foobar", "recognised '$ret_eof' as EOF";
}

our $fh = IO::Callback->new("<", sub { return });
my $ret = read $fh, $_, 100;
is $_, "", "empty string read if callback sends nothing";
is $ret, 0, "0 len reported if callback sends nothing";

$fh = IO::Callback->new('<', sub { return IO::Callback::Error });
$ret = read $fh, $_, 100;
ok ! defined $ret, "error reported if read callback returns Error";
$fh = IO::Callback->new('<', sub { return [] });
SKIP: {
    skip "perl too old", 1 if $] < 5.008;
    # Running this under 5.6.2 causes the test script to exit with status 0,
    # feels like an old perl bug.

    throws_ok { read $fh, $_, 100 }
        '/^unexpected reference type ARRAY returned by callback/',
        "invalid read callback ref return trapped";
};

$fh = IO::Callback->new('>', sub { return IO::Callback::Error });
$ret = print $fh "foo\n";
ok ! defined $ret, "error reported if write callback returns Error";
$fh = IO::Callback->new('>', sub { return [] });
lives_ok { $ret = print $fh "foo\n" } "arbitrary write callback ref return: no croak";
ok $ret, "arbitrary write callback ref return: no fail";

