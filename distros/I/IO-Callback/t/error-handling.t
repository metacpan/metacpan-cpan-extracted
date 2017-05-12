# IO::Callback 1.08 t/error-handling.t
# Check that IO::Callback's error handling is consistent with the way Perl
# handles errors on real files.

use strict;
use warnings;

use Test::More tests => 347;
use Test::Exception;
use Test::NoWarnings;

our $test_nowarnings_hook = $SIG{__WARN__};
$SIG{__WARN__} = sub {
    my $warning = shift;
    return if $warning =~ /stat\(\) on unopened filehandle/i;
    $test_nowarnings_hook->($warning);
};

use IO::Callback;

# Closed files and writing on read files and visa versa
my %code_for_operation = (
    '<' => [
        'read $fh, $_, 10',
        '$fh->getc'
       ],
    '>' => [
        q{print $fh "foo\n"},
        q{$fh->print("foo\n")},
        q{$fh->write("foo\n")},
        q{syswrite $fh, "foo\n"},
        q{printf $fh '%s', 0},
        q{$fh->printf('%s', 0)},
       ],
);
foreach my $rw ('>', '<') {
    foreach my $close_it_first (0, 1) {
        foreach my $operation ('>', '<') {
            foreach my $code (@{ $code_for_operation{$operation} }) {
                my $test_name = "file $rw, op '$code', closed $close_it_first";
                my $fh = IO::Callback->new($rw, sub {"x"});
                ok $fh->opened, "fh opened after open";
                close $fh if $close_it_first;
                my $ret = eval $code;
                ok !$@, "$test_name non-fatal error, no croak";
                my $should_be_ok = $rw eq $operation && not $close_it_first;
                is defined($ret), $should_be_ok, "$test_name returned";
                is $fh->error, ($should_be_ok ? 0 : -1), "$test_name fh->error as expected";
                is $fh->clearerr, 0, "clearerr returned 0";
                is $fh->error, 0, "$test_name fh->error after clear as expected";
            }
        }
    }
}

# close should fail on a write fh if the callback returns error.
{
    my $wfh = IO::Callback->new(">", sub { IO::Callback::Error });
    my $ret = $wfh->close;
    ok ! defined $ret, "undef return on failing close";
    is $wfh->error, 1, "error flag set on failing close";
    $wfh->clearerr;
    is $wfh->error, 0, "error flag cleared after failing close";
}

# a failed write should leave the error flag set, and should lead to a failed close.
{
    my $wfh = IO::Callback->new(">", sub { return IO::Callback::Error if $_[0] eq "foo" }); # fail on the write, but not on the close
    my $ret = $wfh->print("foo");
    ok ! defined $ret, "errored write returned undef";
    is $wfh->error, 1, "error flag set on failed write";
    $ret = $wfh->close;
    ok ! defined $ret, "errored write lead to undef on close";
    is $wfh->error, 1, "error flag still set after close after failed write";
}

my $fh = IO::Callback->new('<', sub {});

throws_ok { $fh->getlines }
    qr{^getlines\(\) called in scalar context at },
    "getlines() croaks in scalar context";

throws_ok { seek $fh, 0, 0 }
    qr{^Illegal seek at },
    "seek croaks";

throws_ok { $fh->setpos(1234) }
    qr{^setpos not implemented for IO::Callback at },
    "setpos croaks";

throws_ok { $fh->truncate(1234) }
    qr{^truncate not implemented for IO::Callback at },
    "truncate croaks";

is_deeply [stat $fh], [], "stat returns empty list";
my $stat = stat $fh;
ok !$stat, "stat returns false in a scalar context";

# getline/getlines should fail if there's a read error before the first eol 
my @readcode = (
    '$ret = <$fh>',
    'local $/; $ret = <$fh>',
    'local $/=""; $ret = <$fh>',
    '($ret) = <$fh>',
    'local $/; ($ret) = <$fh>',
    'local $/=""; ($ret) = <$fh>',
);
foreach my $readcode (@readcode) {
    my $block = "x" x 10240;
    my @ret = ($block, $block, $block, IO::Callback::Error, $block, $block);
    my $fh = IO::Callback->new('<', sub { shift @{$_[0]} }, \@ret);

    my $ret;
    eval $readcode; die $@ if $@;
    ok ! defined $ret, "getline(s) ($readcode) failed on error";

    foreach my $readcode2 (@readcode) {
        eval $readcode2; die $@ if $@;
        ok ! defined $ret, "getline(s) continued to fail after error ($readcode) / ($readcode2)";
    }
}


# All write ops should fail if the callback returns error
my @writecode = (
    q{$ret = print $fh $_},
    q{$ret = $fh->print($_)},
    q{$ret = printf $fh $_},
    q{$ret = $fh->printf($_)},
    q{$ret = printf $fh 'foo%s', $_},
    q{$ret = $fh->printf('foo%s', $_)},
    q{$ret = $fh->write($_)},
    q{$ret = $fh->syswrite($_)},
    q{$ret = syswrite $fh, $_},
);
foreach my $writecode (@writecode) {
    my $fh = IO::Callback->new('>', sub { return IO::Callback::Error if $_[0] =~ /poison/ });

    my $ret;
    $_ = "foo";
    eval $writecode; die $@ if $@;
    ok $ret, "no error without poison ($writecode)";

    $_ = "poison";
    eval $writecode; die $@ if $@;
    ok ! defined $ret, "error with poison ($writecode)";

    $_ = "bar";
    foreach my $writecode2 (@writecode) {
        eval $writecode2; die $@ if $@;
        ok ! defined $ret, "error in write after error ($writecode) / ($writecode2)";
    }
}

