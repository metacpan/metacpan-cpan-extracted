#!/usr/bin/perl

use strict;
use warnings;

use Devel::Peek qw(Dump);
use JavaScript;

my $v = {};

my $rt = JavaScript::Runtime->new();
my $cx = $rt->create_context();

$cx->bind_function(dump => sub { my $y = shift;  });
$cx->call(dump => {});

JavaScript::dump_sv_report_used();