#!/usr/bin/env perl
# Test list command for IMAP servers
#
# A lot of the basic administration handling is tested in 52manager/30collect.t

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::MH;
use Mail::Box::Identity;
use Mail::Server::IMAP4::List;

use Test::More tests => 41;

my $msil = 'Mail::Server::IMAP4::List';
my $mbi  = 'Mail::Box::Identity';

my @boxes =
 qw( a1
     a1/b1
     a1/b2
     a1/b2/c1
     a1/b2/c2
     a1/b2/c3
     a1/b2/c3/d1
     a1/b2/c3/d2
     a1/b3
     a2
     a3
   );

# Create the directory hierarchy

my $top = '60imap-test';
clean_dir($top);
mkdir $top or die "$top: $!";

foreach my $box (@boxes)
{   my $dir = "$top/$box";
    mkdir $dir or die "$dir: $!";
}


# Create the top object

my $folders = $mbi->new
 ( name        => '='
 , folder_type => 'Mail::Box::MH'
 , only_subs   => 1
 );

ok(defined $folders,                        "Created the top folder");
isa_ok($folders, $mbi);


# Load the structure

my $count = 0;
sub setloc($)
{   my $node = shift;
    my $full = $node->fullname;
    $full =~ s/^\=/$top/;
    $node->location($full);
    $count++;
}

$folders->foreach(\&setloc);

cmp_ok($count, '==', @boxes+1,              "Succesfully expanded");
ok($folders->onlySubfolders,                "top without msgs");
my $a1 =  $folders->folder('a1');
ok(defined $a1,                             "found $a1");
ok(!$a1->onlySubfolders,                    "other with msgs");

#
# Let's do the simple LIST check.
#

sub str(@)
{   return '' unless @_;
    my @lines;
    foreach my $record (@_)
    {   my($flags, $delim, $rest) = @$record;
        $rest = '""' unless length $rest;
        push @lines, "$flags \"$delim\" $rest\n";
    }
    join '', @lines;
}

my $imap = $msil->new(folders => $folders, delimiter => '#');
isa_ok($imap, $msil);

is(str($imap->list('', '')), <<'__DELIM',   'as for delim');
(\Noselect) "#" ""
__DELIM

is(str($imap->list('#', 'a1')), <<'__DELIM');
() "#" #a1
__DELIM

$folders->folder('a1')->deleted(1);
is(str($imap->list('#', 'a1')), <<'__DELIM');
(\Noselect) "#" #a1
__DELIM

$folders->folder('a1')->deleted(0);
is(str($imap->list('#', 'a1')), <<'__DELIM');
() "#" #a1
__DELIM

$folders->folder('a1')->onlySubfolders(1);
is(str($imap->list('#', 'a1')), <<'__DELIM');
(\Noselect) "#" #a1
__DELIM

$folders->folder('a1')->marked(1);
is(str($imap->list('#', 'a1')), <<'__DELIM', 'marked');
(\Noselect \Marked) "#" #a1
__DELIM

$folders->folder('a1')->marked(0);
is(str($imap->list('#', 'a1')), <<'__DELIM', 'unmarked');
(\Noselect \Unmarked) "#" #a1
__DELIM

$folders->folder('a1')->marked(undef);
is(str($imap->list('#', 'a1')), <<'__DELIM', 'not marked');
(\Noselect) "#" #a1
__DELIM

is(str($imap->list('a1', 'b1')), <<'__DELIM', 'straight forward');
() "#" #a1#b1
__DELIM

is(str($imap->list('a1', 'none')), <<'__DELIM', 'missing');
__DELIM

is(str($imap->list('a1#b2', 'c3')), <<'__DELIM', 'stacking');
() "#" #a1#b2#c3
__DELIM

#
# Flags
#

my $abc = $folders->folder('a1', 'b2', 'c3');
ok(defined $abc,                                  'got abc');

$abc->marked(1);
is(str($imap->list('a1#b2', 'c3')), <<'__DELIM',  'abc marked');
(\Marked) "#" #a1#b2#c3
__DELIM

$abc->marked(0);
is(str($imap->list('a1#b2', 'c3')), <<'__DELIM',  'abc unmarked');
(\Unmarked) "#" #a1#b2#c3
__DELIM

$abc->marked(undef);
is(str($imap->list('a1#b2', 'c3')), <<'__DELIM',  'abc undef marked');
() "#" #a1#b2#c3
__DELIM

$abc->inferiors(0);
is(str($imap->list('a1#b2', 'c3')), <<'__DELIM',  'abc no inferiors');
(\Noinferiors) "#" #a1#b2#c3
__DELIM

$abc->inferiors(1);
is(str($imap->list('a1#b2', 'c3')), <<'__DELIM',  'abc inferiors');
() "#" #a1#b2#c3
__DELIM

$abc->inferiors(0);
$abc->marked(1);
is(str($imap->list('a1#b2', 'c3')), <<'__DELIM',  'abc inferiors');
(\Noinferiors \Marked) "#" #a1#b2#c3
__DELIM

$abc->inferiors(1);
$abc->marked(1);
is(str($imap->list('a1#b2', 'c3')), <<'__DELIM',  'abc inferiors');
(\Marked) "#" #a1#b2#c3
__DELIM

#
# Now for some real searching
#

is(str($imap->list('a1#none', '%')), <<'__DELIM', 'find none %');
__DELIM

is(str($imap->list('a1#none', '*')), <<'__DELIM', 'find none *');
__DELIM

is(str($imap->list('a1#b1', '%')), <<'__DELIM', 'find here %');
() "#" #a1#b1
__DELIM

is(str($imap->list('a1#b1', '*')), <<'__DELIM', 'find here *');
() "#" #a1#b1
__DELIM

is(str($imap->list('a1#b2', '%')), <<'__DELIM', 'find none %');
() "#" #a1#b2#c1
() "#" #a1#b2#c2
(\Marked) "#" #a1#b2#c3
__DELIM

is(str($imap->list('a1#b2', '*')), <<'__DELIM', 'find none *');
() "#" #a1#b2
() "#" #a1#b2#c1
() "#" #a1#b2#c2
(\Marked) "#" #a1#b2#c3
() "#" #a1#b2#c3#d1
() "#" #a1#b2#c3#d2
__DELIM

is(str($imap->list('a1', '%#b3')), <<'__DELIM', 'find inside %');
__DELIM

is(str($imap->list('a1', '*#b3')), <<'__DELIM', 'find inside *');
() "#" #a1#b3
__DELIM

is(str($imap->list('a1', 'b2#*')), <<'__DELIM', 'find inside *');
() "#" #a1#b2
() "#" #a1#b2#c1
() "#" #a1#b2#c2
(\Marked) "#" #a1#b2#c3
() "#" #a1#b2#c3#d1
() "#" #a1#b2#c3#d2
__DELIM

is(str($imap->list('a1', '*#c2')), <<'__DELIM', 'find inside *');
() "#" #a1#b2#c2
__DELIM

is(str($imap->list('a1', '*#d2')), <<'__DELIM', 'find inside *');
() "#" #a1#b2#c3#d2
__DELIM

#
# Complicated delimiter, as defined by the RFC.  Examples in 6.3.8
#

sub combi_delim($)
{   my $path = shift;
    my ($delim, $root)
      = $path =~ m/^(#news\.)/ ? ('.', $1)
      : $path =~ m!^/!         ? ('/', '/')
      :                          ('/', '');
    wantarray ? ($delim, $root) : $delim;
}

$folders->onlySubfolders(0);
ok(! $folders->onlySubfolders);

$imap = $msil->new(folders => $folders, delimiter => \&combi_delim);

is(str($imap->list('', '')), <<'__DELIM',   'combi delim');
(\Noselect) "/" ""
__DELIM

is(str($imap->list('#news.comp.mail.misc', '')), <<'__DELIM');
(\Noselect) "." #news.
__DELIM

is(str($imap->list('/usr/staff/jones', '')), <<'__DELIM');
(\Noselect) "/" /
__DELIM

clean_dir($top);
