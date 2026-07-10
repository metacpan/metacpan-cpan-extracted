#!/usr/bin/perl
# Copyright (c) 2016-2019 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use warnings;
use strict;

eval "use Locale::VersionedMessages";
$::ti->skip_all("Locale::VersionedMessages not loadable") if $@;

$::ti->use_ok('Locale::VersionedMessages');
$::lm = new Locale::VersionedMessages;

# We have an extra library that must be loaded.

my $testdir = $::ti->testdir();
eval("use lib '$testdir/lib'");

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:

