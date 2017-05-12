#!/usr/bin/perl -w

use Test::More;
use HTML::Template::Pro;

eval "require Tie::Hash";
if ($@) {
    plan skip_all => "Tie::Hash is required for testing POD";
    exit;
}
eval "require Tie::Array";
if ($@) {
    plan skip_all => "Tie::Array is required for testing POD";
    exit;
}
else {
    $tests=2;
    plan tests => $tests;
}

my %plainhash;
tie %plainhash, 'TestHash1';
my @plainarray;
tie @plainarray, 'TestArray';

my $t = HTML::Template::Pro->new( filename => 'templates-Pro/test_loop2.tmpl' , 
				  debug=>0,
				  case_sensitive => 1,
    );

$t->param('HASHREF1' => [ \%plainhash] );
ok($t->output =~/MAGIC1/);

$t->param('HASHREF1' => \@plainarray );
my $out=$t->output();
ok($out =~/MAGIC1/ && $out =~/MAGIC2/);
#$t->output();

package TestHash1;
use vars qw/@ISA/;
@ISA = 'Tie::StdHash';
require Tie::Hash;

sub TIEHASH  {
    my $none;
    my $storage = bless \$none, shift;
    $storage
}

sub FETCH    {
    return 'MAGIC1';
}

package TestHash2;
use vars qw/@ISA/;
@ISA = 'Tie::StdHash';
require Tie::Hash;

sub TIEHASH  {
    my $storage = bless {}, shift;
    $storage
}

sub FETCH    {
    return 'MAGIC2';
}

package TestArray;
use vars qw/@ISA $count/;
@ISA = ('Tie::StdArray');
require Tie::Array;

BEGIN {
$count = 0;
}

sub TIEARRAY  {
    my $none;
    my $storage = bless \$none, shift;
    $storage
}

sub FETCHSIZE {
    return 2;
}

sub FETCH {
    my %myhash;
    if ($count++==0) {
	tie %myhash, 'TestHash1';
    } else {
	tie %myhash, 'TestHash2';
    }
    return \%myhash;
}
