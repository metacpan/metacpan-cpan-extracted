#!perl -w
use strict;
use File::Spec;

use IO::Handle::unread;

open my $io, '<', File::Spec->devnull;

$io->unread("foo\n");

print scalar <$io>; # => "foo\n"

$io->unread("foo\nbar\n", 4);
print scalar <$io>; # => "foo\n"

# It works like a stack.
$io->unread("bar\n");
$io->unread("foo\n");

print scalar <$io>;
print scalar <$io>;
