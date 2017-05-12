#!/usr/bin/env perl

use warnings;
use strict;

use HTML::Restrict;
use Test::More;

my $hr = HTML::Restrict->new;

my $text = '<!DOCTYPE HTML> ';
$hr->debug(1);

is $hr->process($text), '', 'declaration not preserved';
$hr->allow_declaration(1);
is $hr->process($text), '<!DOCTYPE HTML>', 'declaration is preserved';

$text
    = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">';
is $hr->process($text), $text, 'declaration preserved';

done_testing();
