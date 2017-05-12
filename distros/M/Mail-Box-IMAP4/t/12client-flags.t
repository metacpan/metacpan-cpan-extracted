#!/usr/bin/env perl
#
# Test flags conversion of IMAP4 folders.

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Transport::IMAP4;

use Test::More tests => 65;

my $mti = 'Mail::Transport::IMAP4';

###
### Checking labels2flags
###

sub expect_flags($$$)
{   my ($got, $expect, $text) = @_;
    my $errors = 0;

    my %got;
    $got{$_}++ for split " ", $got;

    if(grep {$_ > 1} values %got)
    {   $errors++;
        ok(0, "found double, $text");
    }
    else
    {   ok(1, $text);
    }

    foreach my $e (split " ", $expect)
    {   if(delete $got{$e}) { ok(1, "found $e")   }
        else { $errors++;     ok(0, "missing $e") }
    }

    if(keys %got)
    {   ok(0, "got too much: ".join(" ", keys %got));
        $errors++;
    }
    else
    {   ok(1, "exact match");
    }

    if($errors)
    {   warn "$errors errors, expected '$expect' got '$got'\n";
    }
}

my $flags = $mti->labelsToFlags();
expect_flags($flags, '', "Empty set");

$flags = $mti->labelsToFlags(seen => 1, flagged => 1, old => 1);
expect_flags($flags, '\Seen \Flagged', "No old");

$flags = $mti->labelsToFlags( {seen => 1, flagged => 1, old => 1} );
expect_flags($flags, '\Seen \Flagged', "No old as hash");

$flags = $mti->labelsToFlags(seen => 1, flagged => 1, old => 0);
expect_flags($flags, '\Seen \Flagged \Recent', "No old");

$flags = $mti->labelsToFlags( {seen => 1, flagged => 1, old => 0} );
expect_flags($flags, '\Seen \Flagged \Recent', "No old as hash");

$flags = $mti->labelsToFlags(seen => 1, replied => 1, flagged => 1,
  deleted => 1, draft => 1, old => 0, spam => 1);
expect_flags($flags, '\Seen \Answered \Flagged \Deleted \Draft \Recent \Spam',
   "show all flags");

$flags = $mti->labelsToFlags(seen => 0, replied => 0, flagged => 0,
  deleted => 0, draft => 0, old => 1, spam => 0);
expect_flags($flags, '', "show no flags");

###
### Checking flagsToLabels
###

sub expect_labels($$$)
{   my ($got, $expect, $text) = @_;

    my $gotkeys = join " ", %$got;
    my $expkeys = join " ", %$expect;
# warn "expected '$expkeys' got '$gotkeys'\n";

    # depends on predefined labels
    cmp_ok(scalar keys %$got, '==', 7, "$text; nr fields");

    foreach my $k (keys %$got)
    {   my $g = $got->{$k}    || 0;
        my $e = $expect->{$k} || 0;
        cmp_ok($g, '==', $e, "got $k");
    }

    foreach my $k (keys %$expect)
    {   my $g = $got->{$k}    || 0;
        my $e = $expect->{$k} || 0;
        cmp_ok($g, '==', $e, "expect $k");
    }
}

my $labels = $mti->flagsToLabels('REPLACE');
expect_labels $labels, {old => 1}, "flagsToLabels: Empty set";

$labels = $mti->flagsToLabels(REPLACE => qw[\Seen \Flagged] );
expect_labels $labels
            , {old => 1, seen => 1, flagged => 1}
            , "flagsToLabels: Empty set";

$labels = $mti->flagsToLabels(REPLACE =>
              qw[\Seen \Answered \Flagged \Deleted \Draft \Recent \Spam] );

expect_labels $labels
            , { seen => 1, replied => 1, flagged => 1, deleted => 1
              , draft => 1, spam => 1
              }
            , "show all labels";

exit 0;
