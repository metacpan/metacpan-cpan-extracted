#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use File::Temp 'tempdir';
use Test::More 'no_plan';

use Doit;

sub slurp ($) { open my $fh, shift or die $!; local $/; <$fh> }

my $tempdir = tempdir('doit_XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
chdir $tempdir or die "Can't chdir to $tempdir: $!";

local @ARGV = ('--dry-run');
my $r = Doit->init;

my $changes;

eval { $r->change_file("blubber") };
like $@, qr{blubber does not exist};

eval { $r->change_file(".") };
like $@, qr{\. is not a file};

{ open my $ofh, '>', 'work-file' or die $! }
$changes = $r->change_file("work-file");
ok -z "work-file", "still empty";
ok !$changes, 'no changes';

$changes = $r->change_file("work-file",
			   {add_if_missing => "a new line"},
		          );
is slurp("work-file"), "", "still empty in dry-run mode";
is $changes, 1, "but number of changes is propagated";

__END__
