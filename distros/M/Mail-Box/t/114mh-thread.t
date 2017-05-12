#!/usr/bin/env perl

#
# Test threading of MH folders.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Manager;

use Test::More tests => 5;
use File::Spec;
use List::Util 'sum';

my $mhsrc = File::Spec->catfile($folderdir, 'mh.src');

clean_dir $mhsrc;
unpack_mbox2mh($src, $mhsrc);

my $mgr    = Mail::Box::Manager->new;

my $folder = $mgr->open
  ( folder    => $mhsrc
  , lock_type => 'NONE'
  , extract   => 'LAZY'
  , access    => 'rw'
  );

my $threads = $mgr->threads(folder => $folder);

cmp_ok($threads->known , "==",  0);

my @all = $threads->sortedAll;
cmp_ok(scalar(@all) , "==",  28);
my $msgs = sum map {$_->numberOfMessages} @all;
cmp_ok($msgs, "==", scalar($folder->messages));

my $out = join '', map {$_->threadToString} @all;

my @lines = split /^/, $out;
cmp_ok(@lines, '==', $folder->messages);
$out      = join '', sort @lines;

my $dump = $Mail::Message::crlf_platform ? <<'__DUMP_CRLF' : <<'__DUMP_LF';
1.4K Resize with Transparency
1.3K *- Re: File Conversion From HTML to PS and TIFF
2.1K    `--*- Re: File Conversion From HTML to PS and TIFF
2.1K       `- Re: File Conversion From HTML to PS and TIFF
1.5K Transparency question
2.5K RE: Transparency question
3.4K RE: Transparency question
5.7K RE: Transparency question
7.4K RE: Transparency question
2.8K RE: jpeg2000 question
1.3K *- Problem resizing images through perl script
843  |  `- Re: Problem resizing images through perl script
1.9K |     `- RE: Problem resizing images through perl script
1.0K |        `- Re: Problem resizing images through perl script
1.2K `- Re: Convert HTM, HTML files to the .jpg format
766  Undefined Symbol: SetWarningHandler
1.1K `- Re: Undefined Symbol: SetWarningHandler
1.9K *- Re: watermarks/embossing
316  Re: Annotate problems (PR#298)
585  `- Re: Annotate problems (PR#298)
1.0K 
1.4K `- Re: your mail
2.0K    `- Re: your mail
156  Re: your mail
703  `- Re: your mail
194  Re: your mail
2.0K 
684  Re: your mail
4.5K `- Re: your mail
569  mailing list archives
1.4K delegates.mgk set-up for unixware printing
1.5K printing solution for UW 7.1
1.5K *- Re: converts new sharpen factors
1.2K New ImageMagick mailing list
 28  subscribe
847  Confirmation for subscribe magick-developer
 64  `- Re: Confirmation for subscribe magick-developer
 11K Welcome to magick-developer
1.7K core dump in simple ImageMagick example
2.2K `- Re: core dump in simple ImageMagick example
908     `- Re: core dump in simple ImageMagick example
770        `- Re: core dump in simple ImageMagick example
2.0K Core Dump on ReadImage
1.0K `- Re: Core Dump on ReadImage
1.6K Font metrics
__DUMP_CRLF
1.3K Resize with Transparency
1.2K *- Re: File Conversion From HTML to PS and TIFF
2.1K    `--*- Re: File Conversion From HTML to PS and TIFF
2.1K       `- Re: File Conversion From HTML to PS and TIFF
1.4K Transparency question
2.4K RE: Transparency question
3.3K RE: Transparency question
5.5K RE: Transparency question
7.2K RE: Transparency question
2.7K RE: jpeg2000 question
1.2K *- Problem resizing images through perl script
820  |  `- Re: Problem resizing images through perl script
1.8K |     `- RE: Problem resizing images through perl script
1.0K |        `- Re: Problem resizing images through perl script
1.2K `- Re: Convert HTM, HTML files to the .jpg format
747  Undefined Symbol: SetWarningHandler
1.1K `- Re: Undefined Symbol: SetWarningHandler
1.8K *- Re: watermarks/embossing
307  Re: Annotate problems (PR#298)
573  `- Re: Annotate problems (PR#298)
1.0K 
1.4K `- Re: your mail
1.9K    `- Re: your mail
152  Re: your mail
686  `- Re: your mail
189  Re: your mail
2.0K 
670  Re: your mail
4.4K `- Re: your mail
552  mailing list archives
1.4K delegates.mgk set-up for unixware printing
1.5K printing solution for UW 7.1
1.4K *- Re: converts new sharpen factors
1.2K New ImageMagick mailing list
 27  subscribe
822  Confirmation for subscribe magick-developer
 63  `- Re: Confirmation for subscribe magick-developer
 11K Welcome to magick-developer
1.7K core dump in simple ImageMagick example
2.2K `- Re: core dump in simple ImageMagick example
882     `- Re: core dump in simple ImageMagick example
754        `- Re: core dump in simple ImageMagick example
2.0K Core Dump on ReadImage
1.0K `- Re: Core Dump on ReadImage
1.6K Font metrics
__DUMP_LF

$dump = join '', sort split /^/, $dump;
compare_thread_dumps($out, $dump, 'sort thread full dump');
clean_dir $mhsrc;
