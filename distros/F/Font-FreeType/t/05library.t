# Check that Font::FreeType objects can be created and destroyed without
# crashing, and that the method on it works.

use strict;
use warnings;
use Test::More tests => 5;
use Test::Warnings;
use Font::FreeType;
use Font::FreeType::CharMap;

# Make an object.
my $ft = Font::FreeType->new;
is(ref $ft, 'Font::FreeType',
   'Font::FreeType->new() should return Font::FreeType object');

# Version number, in both list and scalar context.
my $version = $ft->version;
ok($version =~ /^\d+\.\d+\.\d+\z/, 'version number should be formated right');
is(join('.', $ft->version), $version,
   'version() in list context should return same nums as in scalar context');

eval 'use Font::FreeType'; # should not emit redefinition warnings
ok !$@, 'successfully re-imported Font::FreeType';

# vim:ft=perl ts=4 sw=4 expandtab:
