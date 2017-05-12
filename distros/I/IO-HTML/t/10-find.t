#! /usr/bin/perl
#---------------------------------------------------------------------
# 10-find.t
# Copyright 2012 Christopher J. Madsen
#
# Test the find_charset_in function
#---------------------------------------------------------------------

use strict;
use warnings;

use Test::More 0.88;            # done_testing
use Scalar::Util 'blessed';

use IO::HTML 'find_charset_in';

plan tests => 23;

sub test
{
  my $charset = shift;
  my @data = shift;
  push @data, shift if ref $_[0]; # options for find_charset_in
  my $name = shift;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  is(scalar find_charset_in(@data), $charset, $name);
} # end test

#---------------------------------------------------------------------
test 'utf-8-strict' => <<'';
<meta charset="UTF-8">

test 'utf-8-strict' => <<'';
<!-- UTF-16 is recognized only with a BOM -->
<meta charset="UTF-16BE">

test 'iso-8859-15' => <<'';
<meta charset ="ISO-8859-15">

test 'iso-8859-15' => <<'';
<meta charset= "ISO-8859-15">

test 'iso-8859-15' => <<'';
<meta charset =
 "ISO-8859-15">

test 'utf-8-strict' => <<'';
<meta foo=bar some=" charset =
 "ISO-8859-15">
<meta charset="UTF-8">

test 'cp1252' => <<'';
<meta charset="Windows-1252">

test undef, <<'', 'misspelled charset';
<meta charseat="Windows-1252">

test 'utf-8-strict' => <<'';
<meta charset="UTF-8">
<meta charset="Windows-1252">
<meta charseat="Windows-1252">

test 'cp1252' => <<'';
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1" />
<title>Title</title>

test 'iso-8859-15' => <<'';
<html>
<head><!-- somebody forgot the quotes -->
<meta http-equiv=Content-Type content=text/html; charset=ISO-8859-15 />
<title>Title</title>

test 'iso-8859-15' => <<'';
<html>
<head><!-- somebody forgot the quotes -->
<meta http-equiv
=Content-Type content=text/html; charset=ISO-8859-15 />
<title>Title</title>

test 'iso-8859-15' => <<'';
<html>
<head><!-- different order -->
<meta content=text/html; charset=ISO-8859-15 http-equiv=Content-Type>
<title>Title</title>

test 'cp1252' => <<'';
<html>
<head>
<meta content="text/html;charset=ISO-8859-1" http-equiv=Content-Type>
<title>Title</title>

test undef, <<'', 'incomplete attribute';
<html>
<foo href="c06.

test 'iso-8859-15' => <<'', 'short comment';
<!--><meta charset="ISO-8859-15">-->

test 'iso-8859-15' => <<'', 'strange comment';
<!---><meta charset="ISO-8859-15">-->

test undef, <<'', 'inside comment';
<!-- ><meta charset="ISO-8859-15">-->

test undef, <<'', 'wrong pragma';
<html>
<head>
<meta http-equiv="X-Content-Type" content="text/html; charset=UTF-8" />
<title>Title</title>

test 'utf-8-strict', <<'', {need_pragma => 0}, 'need_pragma 0';
<html>
<head>
<meta http-equiv="X-Content-Type" content="text/html; charset=UTF-8" />
<title>Title</title>

test 'iso-8859-15' => <<'', 'bogus encoding';
<meta charset="Totally-Bogus-Encoding-That-Doesnt-Exist">
<meta charset=ISO-8859-15>

{
  my $encoding = find_charset_in('<meta charset="UTF-8">', { encoding => 1 });

  ok(blessed($encoding), 'encoding is an object');

  is(eval { $encoding->name }, 'utf-8-strict', 'encoding is UTF-8');
}

done_testing;
