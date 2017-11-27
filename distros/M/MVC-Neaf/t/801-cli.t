#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;
use MVC::Neaf::CLI;

my $warn = 0;
$SIG{__WARN__} = sub { $warn++; warn $_[0]; };

my $app = MVC::Neaf->new;

$app->route( foo => sub { +{}} );
$app->route( bar => sub { +{}} );
MVC::Neaf->route( noexist => sub { +{} } );

my $data;
{
    local *STDOUT;
    open (STDOUT, ">", \$data) or die "Failed to redirect STDOUT";
    local @ARGV = qw(--list);

    $app->run;
};
like ($data, qr(^\[.*GET.*/bar.*\n\[.*GET.*/foo.*\n$)s, "--list works");
unlike $data, qr(noexist), "No mentions of parallel reality routes";
note $data;

{
    local *STDOUT;
    open (STDOUT, ">", \$data) or die "Failed to redirect STDOUT";
    local @ARGV = qw(--view Dumper /foo);

    $app->run;
};
like ($data, qr/\n\n\$VAR1\s*=\s*\{.*\};?$/s, "force view worked");
note $data;

ok !$warn, "$warn warnings issued";
done_testing;
