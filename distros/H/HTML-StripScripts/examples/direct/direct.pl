#!/usr/bin/perl
use strict;
use warnings;
use blib;

use HTML::StripScripts();

my $f = HTML::StripScripts->new({ Context        => 'Flow' });

$f->input_start_document;
$f->input_start('<ul>');

$f->input_start('<li>');
$f->input_text ('List Item 1');
$f->input_end  ('</li>');

$f->input_start('<li>');
$f->input_text ('List Item 2');
$f->input_end  ('</li>');

## Send bad tag
$f->input_end  ('</li>');

$f->input_end  ('</ul>');
$f->input_end_document;

print "\n\nFiltered HTML:\n\n  "
      .$f->filtered_document
      ."\n\n";

