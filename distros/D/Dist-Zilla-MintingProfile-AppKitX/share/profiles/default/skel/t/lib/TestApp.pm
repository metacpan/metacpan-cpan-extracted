package TestApp;
use strict;
use warnings;
use TestApp::Builder;

my $builder = TestApp::Builder->new(
    appname => __PACKAGE__,
);

$builder->bootstrap;

1;