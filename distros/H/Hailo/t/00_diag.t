use v5.28.0;
use strict;
use Moose;
use Test::More tests => 1;
use Hailo;

my $version = $Hailo::VERSION // 'dev-git';

diag("Testing Hailo $version with $^X $]");
pass("Token test");
