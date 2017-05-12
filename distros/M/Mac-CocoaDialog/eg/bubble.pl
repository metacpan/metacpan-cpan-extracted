#!/usr/bin/perl 
use strict;
use warnings;
use lib qw( ../lib );
use Mac::CocoaDialog;

$|++;

my $path =
'/Applications/ZUploadr/ZUploadr.app/Contents/Resources/CocoaDialog.app/Contents/MacOS/CocoaDialog';

my $cocoa = Mac::CocoaDialog->new(path => $path);
$cocoa->bubble()->title('Hello')->text('Unfiltered at all')
  ->foreground_system();
my $rv =
  $cocoa->yesno_msgbox()->title('Hello again')->text('Here we come again')
  ->icon('heart')->grab();
print {*STDOUT} "GOT: $rv\n";
