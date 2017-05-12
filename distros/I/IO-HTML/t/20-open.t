#! /usr/bin/perl
#---------------------------------------------------------------------
# 20-open.t
# Copyright 2012 Christopher J. Madsen
#
# Actually open files and check the encoding
#---------------------------------------------------------------------

use strict;
use warnings;

use Test::More 0.88;

plan tests => 85;

use IO::HTML;
use File::Temp;
use Scalar::Util 'blessed';

#---------------------------------------------------------------------
sub test
{
  my ($expected, $out, $data, $name, $nextArg) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $options;
  if (ref $name) {
    $options = $name;
    $name    = $nextArg;
  }

  unless ($name) {
    $name = 'test ' . ($expected || 'cp1252');
  }

  my $tmp = File::Temp->new(UNLINK => 1);
  open(my $mem, '>', \(my $buf)) or die;

  if ($out) {
    $out = ":encoding($out)" unless $out =~ /^:/;
    binmode $tmp, $out;
    binmode $mem, $out;
  }

  print $mem $data;
  print $tmp $data;
  close $mem;
  $tmp->close;

  my ($fh, $encoding, $bom) = IO::HTML::file_and_encoding("$tmp", $options);

  if ($options and $options->{encoding}) {
    ok(blessed($encoding), 'returned an object');

    $encoding = eval { $encoding->name };
  }

  is($encoding, $expected || 'cp1252', $name);

  my $firstLine = <$fh>;
  like($firstLine, qr/^<html/i);

  close $fh;

  $fh = html_file("$tmp", $options);

  is(<$fh>, $firstLine);

  close $fh;

  # Test sniff_encoding:
  undef $mem;
  open($mem, '<', \$buf) or die "Can't open in-memory file: $!";

  delete $options->{encoding} if $options;

  ($encoding, $bom) = IO::HTML::sniff_encoding($mem, undef, $options);

  is($encoding, $expected);

  seek $mem, 0, 0;

  $options->{encoding} = 1;

  ($encoding, $bom) = IO::HTML::sniff_encoding($mem, undef, $options);

  if (defined $expected) {
    ok(blessed($encoding), 'encoding is an object');

    is(eval { $encoding->name }, $expected);
  } else {
    is($encoding, undef);
  }
} # end test

#---------------------------------------------------------------------
test 'utf-8-strict' => '' => <<'';
<html><meta charset="UTF-8">

test 'utf-8-strict' => ':utf8' => <<"";
<html><head><title>Foo\xA0Bar</title>

test undef, latin1 => <<"";
<html><head><title>Foo\xA0Bar</title>

test 'UTF-16BE' => 'UTF-16BE' => <<"";
\x{FeFF}<html><head><title>Foo\xA0Bar</title>

test 'utf-8-strict' => ':utf8' => <<"";
\x{FeFF}<html><meta charset="UTF-16">

test 'utf-8-strict' => ':utf8' => <<"";
<html><meta charset="UTF-16BE">

test 'UTF-16LE' => 'UTF-16LE' => <<"";
\x{FeFF}<html><meta charset="UTF-16">

test 'UTF-16LE' => 'UTF-16LE' => <<"", { encoding => 1 };
\x{FeFF}<html><meta charset="UTF-16">

test 'utf-8-strict' => ':utf8' => <<"", { encoding => 1, need_pragma => 0 };
<html><meta charset="UTF-16BE">

test 'utf-8-strict' => ':utf8' =>
  "<html><title>Foo\xA0Bar" . ("\x{2014}" x 512) . "</title>\n",
  'UTF-8 character crosses boundary';

test 'utf-8-strict' => ':utf8' =>
  "<html><title>Foo Bar" . ("\x{2014}" x 512) . "</title>\n",
  'UTF-8 character crosses boundary 2';

test undef, '', <<'', 'wrong pragma';
<html>
<head>
<meta http-equiv="X-Content-Type" content="text/html; charset=UTF-8" />
<title>Title</title>

test 'utf-8-strict', '', <<'', {need_pragma => 0}, 'need_pragma 0';
<html>
<head>
<meta http-equiv="X-Content-Type" content="text/html; charset=UTF-8" />
<title>Title</title>

test 'iso-8859-15', '', <<"", { encoding => 1, need_pragma => 0 };
<html>
<meta content="text/html; charset=ISO-8859-15">
<meta charset="UTF-16BE">

done_testing;
