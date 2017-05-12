#!/usr/bin/perl

# Test that our META.yml file matches the specification
use strict;
BEGIN
{
    $|  = 1;
    $^W = 1;

    use Test::More;
    unless ($ENV{AUTHOR_TESTING})
    {
        plan skip_all => "Author tests not required for installation";
    }
    elsif (! -f 'META.yml')
    {
        plan skip_all => "No META.yml file present";
    }
    else
    {
        eval "use Test::CPAN::Meta;";
    }
}

meta_yaml_ok();

exit;
