#!/usr/bin/perl
use strict;
use warnings;

use ExtUtils::MakeMaker;
 
WriteMakefile(
    NAME            => 'HTTP::Request::Webpush',
    VERSION_FROM    => 'lib/HTTP/Request/Webpush.pm',
    test => {TESTS => 't/*.t'},
    LICENSE => "apache_2_0",
    AUTHOR => 'Erich Strelow <estrelow@cpan.org',
    PREREQ_PM => {
       "JSON"        => "2.00",
       "Crypt::JWT"  => "0.013",
       "MIME::Base64"=> "3.11",
       "Crypt::PRNG" => "0.048",
       "Crypt::AuthEnc::GCM" => "0.049",
       "Crypt::PK::ECC" => "0.042",
       "Digest::SHA" => "5.83",
       "Carp"=> "1.00",
       "URI"  =>"1.00"   }
);
