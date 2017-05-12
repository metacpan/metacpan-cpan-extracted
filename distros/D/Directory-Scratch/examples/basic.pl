#!/usr/bin/perl
# basic.pl 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Directory::Scratch;

=pod

Guided tour of Directory::Scratch.

First, create a Directory::Scratch object

=cut

my $tmp = Directory::Scratch->new;

=pod

Then create a file.

=cut

print "Hello reader!  Welcome to this Knuth-like journey!\n";

my $file = $tmp->touch('foo');
print "foo was created as $file\n";

=pod

We dont't have to remember $file, we can get the full path later:

=cut

my $path = $tmp->exists('foo');
print "$file and $path are the same\n";

=pod

C<exists> also checks for existence, of course.

=cut

print "No file called fake!\n" if(!$tmp->exists('fake'));

=pod

That's all for now.

=cut

print "Goodbye.  I'm cleaning up $tmp for you!";
