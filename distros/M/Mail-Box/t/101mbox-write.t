#!/usr/bin/env perl

#
# Test writing of mbox folders.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Mbox;

use Test::More tests => 5;
use File::Compare;
use File::Copy;

#
# We will work with a copy of the original to avoid that we write
# over our test file.
#

unlink $cpy;
copy $src, $cpy
    or die "Cannot create test folder $cpy: $!\n";

my $folder = new Mail::Box::Mbox
  ( folder       => "=$cpyfn"
  , folderdir    => $workdir
  , lock_type    => 'NONE'
  , extract      => 'ALWAYS'
  , access       => 'rw'
  );

die "Couldn't read $cpy: $!\n"
     unless $folder;

#
# None of the messages should be modified.
#

my $modified = 0;
$modified ||= $_->modified foreach $folder->messages;
ok(!$modified);

#
# Write unmodified folder to different file.
# Because file-to-file copy of unmodified messages, the result must be
# the same.
#

$folder->modified(1);  # force write
ok($folder->write(policy => 'REPLACE'));

# Try to read it back

my $copy = new Mail::Box::Mbox
  ( folder    => "=$cpyfn"
  , folderdir => $workdir
  , lock_type => 'NONE'
  , extract   => 'ALWAYS'
  );

ok($copy);
cmp_ok($folder->messages, "==", $copy->messages);

# Check also if the subjects are the same.

my @folder_subjects = sort map {$_->head->get('subject')||''} $folder->messages;
my @copy_subjects   = sort map {$_->head->get('subject')||''} $copy->messages;

while(@folder_subjects)
{   last unless shift(@folder_subjects) eq shift(@copy_subjects);
}
ok(!@folder_subjects);
