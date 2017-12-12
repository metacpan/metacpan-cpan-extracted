#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More 'no_plan';
use Doit;
use File::Temp 'tempdir';

sub slurp ($) { open my $fh, shift or die $!; local $/; <$fh> }

my $tempdir = tempdir(CLEANUP => 1);

my $d = Doit->init;

$d->write_binary("$tempdir/srcfile", "source data\n");
$d->mkdir("$tempdir/destdir1");
$d->mkdir("$tempdir/destdir2");

# copy with fully qualified path
$d->copy("$tempdir/srcfile", "$tempdir/destdir1/destfile");
ok -e "$tempdir/destdir1/destfile", 'destination file was created';
is slurp("$tempdir/destdir1/destfile"), "source data\n", 'content as expected';

$d->copy("$tempdir/srcfile", "$tempdir/destdir1/destfile");
pass 'no copy, unchanged file';

# copy with destination directory only
$d->copy("$tempdir/srcfile", "$tempdir/destdir2");
ok -e "$tempdir/destdir2/srcfile", 'destination file was created (only destdir was specified)';
is slurp("$tempdir/destdir2/srcfile"), "source data\n", 'content as expected';

$d->copy("$tempdir/srcfile", "$tempdir/destdir2");
pass 'no copy, unchanged file';

$d->change_file("$tempdir/srcfile", {add_if_missing => "a new line"});
my $new_contents = slurp("$tempdir/srcfile");

$d->copy("$tempdir/srcfile", "$tempdir/destdir1/destfile");
is slurp("$tempdir/destdir1/destfile"), $new_contents, 'copy was again done after changed file';

$d->copy("$tempdir/srcfile", "$tempdir/destdir2");
is slurp("$tempdir/destdir2/srcfile"), $new_contents, 'copy was again done after changed file';

# copy to non-existent directory
eval { $d->copy("$tempdir/srcfile", "$tempdir/non-existent-directory/destfile") };
like $@, qr{Copy failed: };

# copy non-existent source file
eval { $d->copy("$tempdir/non-existent-srcfile", "$tempdir/destdir2") };
like $@, qr{Copy failed: };

__END__
