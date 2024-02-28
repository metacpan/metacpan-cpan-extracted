#!/usr/bin/perl
use strict;
use warnings;

use ExtUtils::MakeMaker;
 
WriteMakefile(
    NAME            => 'LWP::UserAgent::msgraph',
    VERSION_FROM    => 'lib/LWP/UserAgent/msgraph.pm',
    test => {TESTS => 't/*.t'}, 
    LICENSE => "apache_2_0",
    NO_META => 1,
    AUTHOR => 'Erich Strelow <estrelow@cpan.org>',
    PREREQ_PM => {
       "JSON"        => "2.00",
       "Carp"=> "1.00",
       "URI"  =>"5.16" ,
       "perl" => "5.004",
       "HTTP::Request" => "6.00",
       "Data::UUID" => "1.00",
       "File::Spec" => "3.26",
       "Net::EmptyPort" => "2.19",
       "HTTP::Server::Simple::CGI"=>"0.40",
       "LWP::UserAgent" => "6.00",
       "Test::More" =>"1.00"}
);
