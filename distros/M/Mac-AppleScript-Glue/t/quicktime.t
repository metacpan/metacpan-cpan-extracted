#!/usr/bin/perl -w

# vim: set filetype=perl :

use strict;

use Test;

BEGIN { plan tests => 5 };

use Mac::AppleScript::Glue;

##;;$Mac::AppleScript::Glue::Debug{SCRIPT} = 1;
##;;$Mac::AppleScript::Glue::Debug{RESULT} = 1;

######################################################################

my $finder = new Mac::AppleScript::Glue::Application('Finder');

ok(defined $finder)
    or die "can't initialize application object (Finder)\n";

######################################################################

my $preview = new Mac::AppleScript::Glue::Application('Preview');

ok(defined $preview)
    or die "can't initialize application object (Preview)\n";

######################################################################

my $file = $preview->objref(
    posix_file => "/System/Library/CoreServices/Dock.app/Contents/Resources/finder.png",
);

ok(defined $file)
    or die "can't initialize 'file' object\n";

######################################################################

my $doc = $file->open;

ok(defined $doc)
    or die "can't open file in Preview\n";

######################################################################

sleep(1);

$doc->close;

ok(1);
