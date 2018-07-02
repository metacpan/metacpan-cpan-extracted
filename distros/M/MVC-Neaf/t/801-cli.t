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
neaf->route( noexist => sub { +{} } ); # this should NOT affect the new() routes

my $data;
{
    local *STDOUT;
    open (STDOUT, ">", \$data) or die "Failed to redirect STDOUT";
    local @ARGV = qw(--list);

    $app->run;
    1;
};
like ($data, qr(^\[.*GET.*/bar.*\n\[.*GET.*/foo.*\n$)s, "--list works");
unlike $data, qr(noexist), "No mentions of parallel reality routes";
note $data;

# 1st app has its routes already locked
# And we cannot reinitialise (yet)
my $app2 = MVC::Neaf->new;
$app2->add_route( quux => sub { +{} } );

$data = '';
{
    local *STDOUT;
    open (STDOUT, ">", \$data) or die "Failed to redirect STDOUT";
    local @ARGV = qw(--view Dumper /quux);

    $app2->run;
    1;
};
like ($data, qr/\n\n\$VAR1\s*=\s*\{.*\};?$/s, "force view worked");
note $data;

ok !$warn, "$warn of 0 warnings issued";
done_testing;
