#!/usr/bin/env perl
#
# Test searching with grep
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Manager;
use Mail::Box::Search::Grep;

use Test::More tests => 58;
use IO::Scalar;
use File::Copy;

copy $src, $cpy
    or die "Cannot create test folder $cpy: $!\n";

my $mgr    = Mail::Box::Manager->new;

my $folder = $mgr->open($cpy, lock_type => 'NONE');
ok(defined $folder,                   'open folder');
cmp_ok($folder->messages , "==",  45, 'folder full of messages');

#
# Simple search in body
#

my $output= '';
my $fh    = IO::Scalar->new(\$output)
    or die "Cannot create an IO::Scalar: $!";

my $oldfh = select $fh;

my $grep1  = Mail::Box::Search::Grep->new
 ( match   => 'However'
 , in      => 'BODY'
 , deliver => 'PRINT'
 );

$grep1->search($folder);
$fh->close;
select $oldfh;

$output =~ s!\Q$workdir\E!t/folders!g;
$output =~ s#\\#/#g;  # windows

is($output, <<'EXPECTED',                       'search for However');
t/folders/mbox.cpy, message 8: Resize with Transparency
   21: However, ImageMagick (ImageMagick 4.2.7, PerlMagick 4.27 on Linux)
t/folders/mbox.cpy, message 38: Re: core dump in simple ImageMagick example
   38: However, it is only reproduceable when this statement is included in
t/folders/mbox.cpy, message 41: Re: core dump in simple ImageMagick example
    4: > However, it is only reproduceable when this statement is included in
EXPECTED

undef $grep1;

#
# search in head with limit
#

$output = '';
$fh    = IO::Scalar->new(\$output) or die $!;
select $fh;

my $grep2  = Mail::Box::Search::Grep->new
 ( match   => 'atcmpg'
 , in      => 'HEAD'
 , limit   => -4
 , deliver => 'PRINT'
 );

my @m2 = $grep2->search($folder);
$fh->close;
select $oldfh;

cmp_ok(@m2, "==", 4);

my $last = shift @m2;
foreach (@m2)
{   ok($last->seqnr < $_->seqnr,                'messages ordered');
    $last = $_;
}

# messages are reversed ordered here, but in order returned: looking
# backwards in the folder file.

$output =~ s!\Q$workdir\E!t/folders!g;
$output =~ s#\\#/#g;  # windows

is($output, <<'EXPECTED',                       'search result atcmp in head');
t/folders/mbox.cpy, message 44: Font metrics
  Received: from ns.ATComputing.nl (ns.ATComputing.nl [195.108.229.25])
  	by atcmpg.ATComputing.nl (8.9.0/8.9.0) with ESMTP id TAA26427
  	for <markov@ATComputing.nl>; Wed, 4 Oct 2000 19:56:00 +0200 (MET DST)
t/folders/mbox.cpy, message 43: Core Dump on ReadImage
  Received: from ns.ATComputing.nl (ns.ATComputing.nl [195.108.229.25])
  	by atcmpg.ATComputing.nl (8.9.0/8.9.0) with ESMTP id WAA14913
  	for <markov@ATComputing.nl>; Tue, 1 Aug 2000 22:37:13 +0200 (MET DST)
t/folders/mbox.cpy, message 42: Re: Core Dump on ReadImage
  Message-ID: <20000807113844.A22119@atcmpg.ATComputing.nl>
t/folders/mbox.cpy, message 41: Re: core dump in simple ImageMagick example
  Received: from ns.ATComputing.nl (ns.ATComputing.nl [195.108.229.25])
  	by atcmpg.ATComputing.nl (8.9.0/8.9.0) with ESMTP id NAA29434
  	for <markov@ATComputing.nl>; Wed, 26 Jul 2000 13:46:33 +0200 (MET DST)
  References: <397C6C6B.989E4BB2@catchword.com> <20000726133231.G25170@atcmpg.ATComputing.nl>
EXPECTED

undef $grep2;

#
# Test regexp search
#

my @hits;
my $grep3  = Mail::Box::Search::Grep->new
  ( match   => qr/ImageMagick/
  , in      => 'MESSAGE'
  , deliver => \@hits
  );

my @m3 = $grep3->search($folder);
#warn $_.": ".$_->subject, "\n" for @m3;
cmp_ok(@m3, "==", 24,                           'messages with ImageMagick');
cmp_ok(@hits, "==", 60,                         'hits on ImageMagick');

$last = shift @m3;
my %m3 = ($last->seqnr => 1);
foreach (@m3)   # in order?
{   ok($last->seqnr < $_->seqnr,                'messages ordered');
    $m3{$_->seqnr}++;
    $last = $_;
}
cmp_ok(keys %m3, "==", 24,                      'returned message unique');

my %h3 = map +($_->{message}->seqnr => 1), @hits;
cmp_ok(keys %h3, "==", 24,                      'returned hits in the messages');

undef $grep3;

#
# Test regexp search with case-ignore
#

@hits = ();
my $grep4  = Mail::Box::Search::Grep->new
  ( match   => qr/ImageMagick/i
  , in      => 'MESSAGE'
  , deliver => \@hits
  );

my @m4 = $grep4->search($folder);
cmp_ok(@m4, "==", 28,                           'messages with /ImageMagick/i');
cmp_ok(@hits, "==", 102,                        'hits with /ImageMagick/i');

undef $grep4;

#
# Test regexp search with case-ignore and some deleted messages
#

@hits = ();
$folder->message($_)->delete(1) for 3, 6, 8, 9, 11, 13, 23, 33;

my $grep5  = Mail::Box::Search::Grep->new
  ( match   => qr/ImageMagick/i
  , in      => 'MESSAGE'
  , deliver => \@hits
  );

my @m5 = $grep5->search($folder);
cmp_ok(@m5, "==", 22,                           'msgs, search excludes deleted');
cmp_ok(@hits, "==", 89,                         'hits, search excludes deleted');

undef $grep5;

# Include-deleted

@hits = ();
my $grep6  = Mail::Box::Search::Grep->new
  ( match   => qr/ImageMagick/i
  , in      => 'MESSAGE'
  , deleted => 1
  , deliver => \@hits
  );

my @m6 = $grep6->search($folder);
cmp_ok(@m6, "==", 28,                           'msgs, search includes deleted');
cmp_ok(@hits, "==", 102,                        'hits, search includes deleted');

undef $grep6;

# only in header

@hits = ();
my $grep7  = Mail::Box::Search::Grep->new
  ( match   => qr/ImageMagick/i
  , in      => 'HEAD'
  , deliver => \@hits
  );

my @m7 = $grep7->search($folder);
cmp_ok(@m7, "==", 11,                            'msgs, /ImageMagick/i in head');
cmp_ok(@hits, "==", 27,                          'hits, /ImageMagick/i in head');

undef $grep7;

# only in body

@hits = ();
my $grep8  = Mail::Box::Search::Grep->new
  ( match   => qr/ImageMagick/i
  , in      => 'BODY'
  , deliver => \@hits
  );

my @m8 = $grep8->search($folder);
cmp_ok(@m8, "==", 20,                            'msgs, /ImageMagick/i in body');
cmp_ok(@hits, "==", 62,                          'hits, /ImageMagick/i in body');

cmp_ok($grep8->search($folder), "==", 20,        'search returns msgs in scalar');

undef $grep8;

# only test for match: stops at first hit

my $grep9  = Mail::Box::Search::Grep->new
  ( match   => qr/ImageMagick/i
  , in      => 'BODY'
  );

cmp_ok($grep9->search($folder), "==", 1,         'no deliver, then only find one');

undef $grep9;

#
# Search in thread
#

undef $output;
$fh   = IO::Scalar->new(\$output) or die $!;
select $fh;

my $grep10  = Mail::Box::Search::Grep->new
  ( match   => 'ImageMagick'
  , in      => 'BODY'
  , deliver => 'PRINT'
  );

my $t     = $mgr->threads($folder);
my $start = $t->threadStart($folder->message(25));  #isa multipart
my @msgs  = $start->threadMessages;

cmp_ok(@msgs, "==", 2,                           'messages in thread');
ok($grep10->search($start),                      'found in thread');

$output =~ s!\Q$workdir\E!t/folders!g;
$output =~ s#\\#/#g;  # windows

is($output, <<'EXPECTED',                        'result search in thread');
t/folders/mbox.cpy, message 26: Re: your mail
   13: Are you using ImageMagick 5.2.0?  When I used the script I sent the
t/folders/mbox.cpy, message 25: Re: your mail
p  19: > Are you using ImageMagick 5.2.0?  When I used the script I sent the
EXPECTED

my @m10 = $grep10->search(\@msgs);
cmp_ok(@m10, "==", 2,                            'messages found in list');
cmp_ok($m10[0], "==", $msgs[0]);
cmp_ok($m10[1], "==", $msgs[1]);

$fh->close;
select $oldfh;

undef $grep10;

# Without multipart

undef $output;
$fh   = IO::Scalar->new(\$output) or die $!;
select $fh;

my $grep11  = Mail::Box::Search::Grep->new
  ( match      => 'ImageMagick'
  , in         => 'BODY'
  , deliver    => 'PRINT'
  , multiparts => 0
  );

my @m11 = $grep11->search($start);
cmp_ok(@m11, "==", 1,                            'do not search multiparts');

$fh->close;
select $oldfh;

$output =~ s!\Q$workdir\E!t/folders!g;
$output =~ s#\\#/#g;  # windows

is($output, <<'EXPECTED',                        'not in multipart');
t/folders/mbox.cpy, message 26: Re: your mail
   13: Are you using ImageMagick 5.2.0?  When I used the script I sent the
EXPECTED

undef $grep11;

#
# Check search in encoded part
#

my $msg = $folder->messageId('8172.960997992@mystic');
ok($msg);

undef $output;
$fh   = IO::Scalar->new(\$output) or die $!;
select $fh;

my $grep12  = Mail::Box::Search::Grep->new
  ( match      => 'pointsize'
  , in         => 'MESSAGE'
  , binaries   => 1
  , deliver    => 'PRINT'
  );

my @m12 = $grep12->search($msg);
cmp_ok(@m12, "==", 1,                            'search binaries');

$fh->close;
select $oldfh;

$output =~ s!\Q$workdir\E!t/folders!g;
$output =~ s#\\#/#g;  # windows

is($output, <<'EXPECTED',                        'found in encoded text');
t/folders/mbox.cpy, message 20: 
p  12:       , pointsize => $poinsize
EXPECTED

$folder->close(write => 'NEVER');
undef $grep12;
