#!/usr/bin/perl
#
# Test Email::Fingerprint's "smart" read method.

use strict;
use warnings;
use Email::Fingerprint;

use Test::More;
use Test::Exception;

my $fp;
my $file     = "t/data/1.txt";
my $checksum = 35445;
my $options  = {
    checksum        => 'unpack',
    strict_checking => 1,
};

#
# Now read the same message every way imaginable.
#

open FILE, "<", $file;
my @array  = <FILE>;
my $string = join "", @array;
close FILE;

# As a string
$fp = new Email::Fingerprint($options);
$fp->read($string);
ok $fp->checksum eq $checksum, "Scalar input";

# As an array
$fp = new Email::Fingerprint($options);
$fp->read(\@array);
ok $fp->checksum eq $checksum, "Arrayref input";

# As a glob
open FILE, "<", $file;
$fp = new Email::Fingerprint($options);
$fp->read(\*FILE);
ok $fp->checksum eq $checksum, "Glob input";
close FILE;

# Any other reference, except an object, is forbidden.
$fp = new Email::Fingerprint($options);
dies_ok { $fp->read( {} ) } "Can't read a hashref";
dies_ok { $fp->read( sub {} ) } "Can't read a CODE ref";

# An object is ALSO useless, if it doesn't offer any suitable methods.
my $object;
$object = bless \$object, "Impotent::Class";
dies_ok { $fp->read( $object ) } "Can't read impotent objects";

# A simple object with stringification
{
    package MyString;

    use overload qw{""} => sub {
        my $self   = shift;
        return $self->{string};
    };

    package main;

    my $string = bless { string => $string }, "MyString";

    $fp = new Email::Fingerprint($options);
    $fp->read($string);
    ok $fp->checksum eq $checksum, "Stringifiable object input";
}

# A simple object with iteration
SKIP: {

    eval "use FileHandle";
    skip "Skipping: FileHandle module not installed", 1 if $@;

    my $fh = new FileHandle;
    $fh->open($file, "<");

    $fp = new Email::Fingerprint($options);
    $fp->read($fh);
    ok $fp->checksum eq $checksum, "Iteratable object input";
}

# That's all, folks!
done_testing();
