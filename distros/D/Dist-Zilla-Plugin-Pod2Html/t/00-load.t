#!/usr/bin/env perl
use strict;
use warnings;

#use Test::More qw(no_plan);
use Test::More tests => 1;

BEGIN {
    use_ok ('Dist::Zilla::Plugin::Pod2Html');
}
## no critic
no strict;    # because the $VERSION will be added only when
no warnings;  # the distribution is fully built up
diag( "Loading Dist::Zilla::Plugin::Pod2Html $Dist::Zilla::Plugin::Pod2Html::VERSION, Perl $], $^X" );
