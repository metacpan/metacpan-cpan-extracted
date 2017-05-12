use strict;
use Test;

BEGIN {
	plan tests => 45
}

use ELFF::Parser;

print "# Testing instantiation\n";
my $p = new ELFF::Parser();
defined($p) ? ok(1) : ok(0);

print "# Testing non-fields directives with trailing new-lines\n";
my $res = $p->parse_line(qq{#Version: 1.0\n});
(defined($res->{directive}) && $res->{directive} eq 'Version') ? ok(1) : ok(0);
(defined($res->{value}) && $res->{value} eq '1.0') ? ok(1) : ok(0);

$res = $p->parse_line(qq{#Remark: this is a test\n});
(defined($res->{directive}) && $res->{directive} eq 'Remark') ? ok(1) : ok(0);
(defined($res->{value}) && $res->{value} eq 'this is a test') ? ok(1) : ok(0);


print "# Testing non-fields directives without trailing new-lines\n";
$res = $p->parse_line(qq{#Version: 1.0});
(defined($res->{directive}) && $res->{directive} eq 'Version') ? ok(1) : ok(0);
(defined($res->{value}) && $res->{value} eq '1.0') ? ok(1) : ok(0);

$res = $p->parse_line(qq{#Remark: this is a test});
(defined($res->{directive}) && $res->{directive} eq 'Remark') ? ok(1) : ok(0);
(defined($res->{value}) && $res->{value} eq 'this is a test') ? ok(1) : ok(0);


print "# Testing fields directives with trailing new-lines\n";
$res = $p->parse_line(qq{#Fields: foo bar fnord\n});
(defined($res->{directive}) && $res->{directive} eq 'Fields') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[0] eq 'foo') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[1] eq 'bar') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[2] eq 'fnord') ? ok(1) : ok(0);

$res = $p->parse_line(qq{#Fields: foo bar fnord Header(User-Agent)\n});
(defined($res->{directive}) && $res->{directive} eq 'Fields') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[0] eq 'foo') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[1] eq 'bar') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[2] eq 'fnord') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[3] eq 'Header(User-Agent)') ? ok(1) : ok(0);


print "# Testing fields directives without trailing new-lines\n";
$res = $p->parse_line(qq{#Fields: foo bar fnord});
(defined($res->{directive}) && $res->{directive} eq 'Fields') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[0] eq 'foo') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[1] eq 'bar') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[2] eq 'fnord') ? ok(1) : ok(0);

$res = $p->parse_line(qq{#Fields: foo bar fnord Header(User-Agent)});
(defined($res->{directive}) && $res->{directive} eq 'Fields') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[0] eq 'foo') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[1] eq 'bar') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[2] eq 'fnord') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[3] eq 'Header(User-Agent)') ? ok(1) : ok(0);


print "# Setting simple log format\n";
$res = $p->parse_line(qq{#Fields: a b\n});
(defined($res->{directive}) && $res->{directive} eq 'Fields') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[0] eq 'a') ? ok(1) : ok(0);
(defined($res->{fields}) && $res->{fields}[1] eq 'b') ? ok(1) : ok(0);

print "# Testing log entry with no quotes and trailing new-line\n";
$res = $p->parse_line(qq{foo bar\n});
(defined($res->{href}{a}) && $res->{href}{a} eq 'foo') ? ok(1) : ok(0);
(defined($res->{href}{b}) && $res->{href}{b} eq 'bar') ? ok(1) : ok(0);

print "# Testing log entry with no quotes and no trailing new-line\n";
$res = $p->parse_line(qq{foo bar});
(defined($res->{href}{a}) && $res->{href}{a} eq 'foo') ? ok(1) : ok(0);
(defined($res->{href}{b}) && $res->{href}{b} eq 'bar') ? ok(1) : ok(0);

print "# Testing log entry with first field quoted\n";
$res = $p->parse_line(qq{"foo bar" fnord});
(defined($res->{href}{a}) && $res->{href}{a} eq 'foo bar') ? ok(1) : ok(0);
(defined($res->{href}{b}) && $res->{href}{b} eq 'fnord') ? ok(1) : ok(0);

print "# Testing log entry with last field quoted\n";
$res = $p->parse_line(qq{foo "bar fnord"});
(defined($res->{href}{a}) && $res->{href}{a} eq 'foo') ? ok(1) : ok(0);
(defined($res->{href}{b}) && $res->{href}{b} eq 'bar fnord') ? ok(1) : ok(0);

print "# Testing log entry with both fields quoted\n";
$res = $p->parse_line(qq{"foo bar" "fnord baz"});
(defined($res->{href}{a}) && $res->{href}{a} eq 'foo bar') ? ok(1) : ok(0);
(defined($res->{href}{b}) && $res->{href}{b} eq 'fnord baz') ? ok(1) : ok(0);

print "# Testing change in log format\n";
$res = $p->parse_line(qq{foo bar baz});
defined($res->{aref}) ? ok(1) : ok(0);
@{$res->{aref}} == 3 ? ok(1) : ok(0);
$res->{aref}[0] eq 'foo' ? ok(1) : ok(0);
$res->{aref}[1] eq 'bar' ? ok(1) : ok(0);
$res->{aref}[2] eq 'baz' ? ok(1) : ok(0);

