#!/usr/bin/perl 
use strict;
use warnings;

use Test::More tests => 15;
use lib qw( lib );
use Lingua::EN::NameParse::Simple;

my $test_cases = get_test_cases();

foreach my $test_case (keys %{$test_cases}){

  my %name = Lingua::EN::NameParse::Simple::ParseName($test_case);
  foreach my $key (keys %name){
    is($test_cases->{$test_case}->{$key},$name{$key},"NameParse returned correct $key for $test_case");
  }
}

sub get_test_cases {
  my %test_cases = ();

  $test_cases{'Hugh R Esco, III'} = {
         TITLE => '', 
         FIRST => 'Hugh', 
        MIDDLE => 'R', 
          LAST => 'Esco', 
        SUFFIX => 'III'
    };

  $test_cases{'Mr. James P. Jones'} = {
         TITLE => 'Mr.', 
         FIRST => 'James', 
        MIDDLE => 'P', 
          LAST => 'Jones', 
        SUFFIX => ''
    };

  $test_cases{'Minnie Mouse'} = {
         TITLE => '', 
         FIRST => 'Minnie', 
        MIDDLE => '', 
          LAST => 'Mouse', 
        SUFFIX => ''
    };

  $test_cases{'Donald Q. Duck'} = {
         TITLE => '', 
         FIRST => 'Donald', 
        MIDDLE => 'Q', 
          LAST => 'Duck', 
        SUFFIX => ''
    };

  $test_cases{'123 Elm Street; Yourtown GA 30001'} = {
         ERROR => 'We do not expect to see digits in a person\'s name', 
    };

  $test_cases{'So-and-soEnterprises.com'} = {
         ERROR => 'Does not appear to be a person\'s name conforming to traditional English format', 
    };

  return \%test_cases;
}

1;

