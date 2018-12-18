#!/usr/bin/perl
use Test::More tests => 3;
use File::Extension qw(extplain);



is(
  (extplain('NES')),
  "Nintendo (NES) ROM File",
  "extplain('NES') OK",
);


is(
  (extplain('dwlibrary')),
  "Paperless Document Library",
  "extplain('dwlibrary') OK",
);


is(
  (extplain('.p6')),
  "Perl 6 Source Code File",
  "extplain('.p6') OK",
);
