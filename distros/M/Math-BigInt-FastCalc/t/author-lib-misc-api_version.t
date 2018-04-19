#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 5;

###############################################################################
# Read and load configuration file and backend library.

use Config::Tiny ();

my $config_file = 't/author-lib.ini';
my $config = Config::Tiny -> read('t/author-lib.ini')
  or die Config::Tiny -> errstr();

# Read the library to test.

our $LIB = $config->{_}->{lib};

die "No library defined in file '$config_file'"
  unless defined $LIB;
die "Invalid library name '$LIB' in file '$config_file'"
  unless $LIB =~ /^[A-Za-z]\w*(::\w+)*\z/;

# Load the library.

eval "require $LIB";
die $@ if $@;

###############################################################################

can_ok($LIB, 'api_version');

# List context.

{
    my @got;

    my $test = qq|\@got = $LIB->api_version();|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "api_version() in list context: $test", sub {
        plan tests => 3,

        cmp_ok(scalar @got, '==', 1,
               "'$test' gives one output arg");

        is(ref($got[0]), "",
           "'$test' output is a Perl scalar");

        like($got[0], qr/^[1-9]\d*(\.\d+)?$/,
             "'$test' output is a decimal number'");
    };
}

# Scalar context.

{
    my $got;

    my $test = qq|\$got = $LIB->api_version();|;

    diag("\n$test\n\n") if $ENV{AUTHOR_DEBUGGING};

    eval $test;
    is($@, "", "'$test' gives emtpy \$\@");

    subtest "api_version() in scalar context: $test", sub {
        plan tests => 2,

        is(ref($got), "",
           "'$test' output is a Perl scalar");

        like($got, qr/^[1-9]\d*(\.\d+)?$/,
             "'$test' output is a decimal number'");
    };
}
