#!/usr/bin/perl
use 5.008_001;
use strict;
use warnings FATAL => 'all';
use CGI;
#use CGI::Carp qw(fatalsToBrowser);

use HTML::FillInForm::Lite;
use utf8;

binmode *STDOUT, ":utf8";
binmode *DATA  , ":utf8";

my $q = CGI->new;

print $q->header(-charset => 'utf-8');
print HTML::FillInForm::Lite->fill(
	\*DATA,
	$q,
);


__DATA__
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
	"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>FillInForm Demo</title>
</head>
<body>
<h1>FillInForm Demo</h1>
<p><a href="demo.cgi">All clear</a></p>
<form method="get">
<p>
<input type="text" name="t" value="text 1" />
<input type="text" name="t" value="text 2" />
</p>
<p>
<label for="c1"><input type="checkbox" name="c" value="c1"  id="c1"/>Check1</label>
<label for="c2"><input type="checkbox" name="c" value="c2"  id="c2"/>Check2</label>
<label for="c3"><input type="checkbox" name="c" value="c3"  id="c3"/>Check3</label>
</p>
<p>
<label for="s1"><input type="radio" name="r" value="s1"  id="s1" checked="checked"/>Radio1</label>
<label for="s2"><input type="radio" name="r" value="s2"  id="s2"/>Radio2</label>
<label for="s3"><input type="radio" name="r" value="s3"  id="s3"/>Radio3</label>
</p>

<p>
<select name="s">
	<option value="s1">Select1</option>
	<option value="s2">Select2</option>
	<option value="s3">Select3</option>
</select>
<select name="s">
	<option value="s1">Select1</option>
	<option value="s2">Select2</option>
	<option value="s3">Select3</option>
</select>
<select name="s">
	<option value="s1">Select1</option>
	<option value="s2">Select2</option>
	<option value="s3">Select3</option>
</select>
</p>

<p>
<textarea name="text">
blah blah blah
</textarea>
</p>

<p>
<input type="submit"/>
</p>
</form>
</body>
</html>
