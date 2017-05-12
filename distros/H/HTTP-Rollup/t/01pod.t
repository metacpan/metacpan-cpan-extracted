#!/usr/local/bin/perl -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}

my $Original_File = 'Rollup.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 126 Rollup.pm

use lib "./blib/lib";
use HTTP::Rollup qw(RollupQueryString);
use Data::Dumper;

my $s1 = "one=abc&two=def&three=ghi";
my $r1 = new HTTP::Rollup;
my $hr = $r1->RollupQueryString($s1); # default delimiter
ok ($hr->{one} eq "abc");
ok ($hr->{two} eq "def");
ok ($hr->{three} eq "ghi");

my $string = <<_END_;
employee.name.first=Jane
employee.name.last=Smith
employee.address=123%20Main%20St.
employee.city=New%20York
id=444
phone=(212)123-4567
phone=(212)555-1212
\@fax=(212)999-8877
_END_

my $r2 = new HTTP::Rollup(DELIM => "\n");
my $hashref = $r2->RollupQueryString($string);
ok($hashref->{employee}->{name}->{first} eq "Jane",
   "2-nested scalar");
ok($hashref->{employee}->{city} eq "New York",
   "1-nested scalar, with unescape");
ok($hashref->{id} eq "444",
   "top-level scalar");
ok($hashref->{phone}->[1] eq "(212)555-1212",
   "auto-list");
ok($hashref->{fax}->[0] eq "(212)999-8877",
   "\@-list");

my $string2 = "employee.name.first=Jane;employee.name.last=Smith;employee.address=123%20Main%20St.;employee.city=New%York;id=444;phone=(212)123-4567;phone=(212)555-1212;\@fax=(212)999-8877";

my $r3 = new HTTP::Rollup(DELIM => ";");
$hashref = $r3->RollupQueryString($string2);
ok($hashref->{employee}->{name}->{first} eq "Jane",
   "nested scalar");
ok($hashref->{id} eq "444",
   "top-level scalar");
ok($hashref->{phone}->[1] eq "(212)555-1212",
   "auto-list");
ok($hashref->{fax}->[0] eq "(212)999-8877",
   "\@-list");

my $r4 = new HTTP::Rollup(FORCE_LIST => 1, DELIM => "\n");
my $hashref2 = $r4->RollupQueryString($string);
ok($hashref2->{'employee.name.first'}->[0] eq "Jane",
   "nested scalar");
ok($hashref2->{id}->[0] eq "444",
   "top-level scalar");
ok($hashref2->{phone}->[1] eq "(212)555-1212",
   "auto-list");
ok($hashref2->{'@fax'}->[0] eq "(212)999-8877",
   "\@-list");


    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

