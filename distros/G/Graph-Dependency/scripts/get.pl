#!/usr/bin/perl -w

use strict;

my $module = shift;
my $author = shift;

die ("Need module name") unless $module;
die ("Need author name") unless $author;

# turn "Foo::Bar" into "Foo-Bar"
$module =~ s/::/-/g;

# protect against random data
$module =~ s/[^\w\d\._+-]//g;

# the first one will redirect to the second one
my $url = "http://search.cpan.org/~$author/$module/META.yml";

# we do not know the latest version, so can't use this one:
#my $url = "http://search.cpan.org/src/$author/$module-LATEST-VERSION/META.yml";

unlink "tmp/$module-META.yml";

my $rc = `wget $url -o /tmp/wget.log -O tmp/$module-META.yml`;

