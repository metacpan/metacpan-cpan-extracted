#!/usr/bin/env perl
use strict;
use TestApp;

my $app = TestApp->apply_default_middlewares(TestApp->psgi_app);
$app;


