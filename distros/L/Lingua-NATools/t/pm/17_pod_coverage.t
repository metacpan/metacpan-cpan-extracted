#!/usr/bin/perl

use Test::More;
use Test::Pod::Coverage;

plan skip_all => "export AUTHOR_TEST for author tests" unless $ENV{AUTHOR_TEST};

pod_coverage_ok "Lingua::NATools::Lexicon";
pod_coverage_ok "Lingua::NATools::CGI";
pod_coverage_ok "Lingua::NATools::Client";
pod_coverage_ok "Lingua::NATools::Config";

done_testing();
