# Test file created outside of h2xs framework.
# Run this like so: `perl List-Filter-Transform.t'
#   doom@kzsu.stanford.edu     2007/04/14 19:32:02

use warnings;
use strict;
$|=1;
my $DEBUG = 0;
use Data::Dumper;

use Test::More;
BEGIN { plan tests => 8 };
use FindBin qw($Bin);
use lib ("$Bin/../../..");


BEGIN {
  use_ok( 'List::Filter::Transform' );
}

ok(1, "Traditional 'made it this far'");

#########################

my ( $transform1,  $transform2 );

my $test_terms = [ [qr{pointy-haired \s+ boss}, 'i', 'esteemed leader' ],
                   [qr{kill},                   '' , 'reward' ],
                   [qr{Kill},                   '' , 'Reward' ],
                   [qr{attack at midnight},     '' , 'go out for donuts' ],
                 ];

{#2
   my $test_name = "Testing creation an empty transform object and then loading it with setters";
   my $expectorant = define_expect_1();

   $transform1 = List::Filter::Transform->new();  # creates an *empty* transform

   $transform1->set_terms( $test_terms );
   $transform1->set_name('sanitize_email');
   $transform1->set_method('sequential');
   $transform1->set_description(
             "remove dangerous phrases");
   $transform1->set_modifiers( "x" );

   my $dump1 = Dumper($transform1);
   ($DEBUG) && print "transform object:\n$dump1\n";

   is_deeply($transform1, $expectorant, "$test_name");
 }


{# 3-7
   my $test_name = "Testing creation of a transform object with defined fields";
   my $expectorant = define_expect_2();

   $transform2 = List::Filter::Transform->new(
     { terms        => \@{ $test_terms },     # aref to copy of contents of aref
       name         => 'sanitize_email',
       method       => 'sequential',
       description  => "remove dangerous phrases",
       modifiers    => "x",
     } );

   my $dump2 = Dumper($transform2);
   ($DEBUG) && print "transform object:\n$dump2\n";
   is_deeply($transform2, $expectorant, "$test_name");

   $test_name = "Testing the getters: ";

   my $terms  = $transform2->terms;
   my $method        = $transform2->method;
   my $description   = $transform2->description;
   my $modifiers     = $transform2->modifiers;

   my $expected_terms = \@{ $test_terms };
   my $expected_method       = 'sequential';
   my $expected_description  = "remove dangerous phrases";
   my $expected_modifiers    = "x";

   is_deeply($terms, $expected_terms, "$test_name: terms");

   is($method,      $expected_method,       "$test_name: method");
   is($description, $expected_description,  "$test_name: description");
   is($modifiers,   $expected_modifiers,    "$test_name: modifiers");
 }





### Heredoc ghetto
# (These routines no longer return strings, but rather eval them to get de-serialized objects)
sub define_expect_2 {
   my $definition =<<'EXP1';
     my $ret = bless( {
                 'save_filters_when_used' => undef,
                 '_ID' => 'List::Filter::Transform',
                 'name' => 'sanitize_email',
                 'terms' => [
                              [
                                qr/(?-xism:pointy-haired \s+ boss)/,
                                'i',
                                'esteemed leader'
                              ],
                              [
                                qr/(?-xism:kill)/,
                                '',
                                'reward'
                              ],
                              [
                                qr/(?-xism:Kill)/,
                                '',
                                'Reward'
                              ],
                              [
                                qr/(?-xism:attack at midnight)/,
                                '',
                                'go out for donuts'
                              ]
                            ],
                 'description' => 'remove dangerous phrases',
                 'storage_handler' => undef,
                 '_DEBUG' => 0,
                 'modifiers' => 'x',
                 'method' => 'sequential',
                 '_ERROR' => '',
                 'dispatcher' => bless( {
                                          'plugin_root' => 'List::Filter::Transforms',
                                          '_ID' => 'List::Filter::Dispatcher',
                                          '_DEBUG' => 0,
                                          '_ERROR' => ''
                                        }, 'List::Filter::Dispatcher' )
               }, 'List::Filter::Transform' );
EXP1
   my $ret = eval $definition;
   if ($@) {
     die "Problem in evaluation of code: $ret\n";
   }
   return $ret;
 }

sub define_expect_1 {

   my $definition =<<'EXP2';
     my $ret
 = bless( {
                 'save_filters_when_used' => undef,
                 '_ID' => 'List::Filter::Transform',
                 'name' => 'sanitize_email',
                 'terms' => [
                              [
                                qr/(?-xism:pointy-haired \s+ boss)/,
                                'i',
                                'esteemed leader'
                              ],
                              [
                                qr/(?-xism:kill)/,
                                '',
                                'reward'
                              ],
                              [
                                qr/(?-xism:Kill)/,
                                '',
                                'Reward'
                              ],
                              [
                                qr/(?-xism:attack at midnight)/,
                                '',
                                'go out for donuts'
                              ]
                            ],
                 'description' => 'remove dangerous phrases',
                 'storage_handler' => undef,
                 '_DEBUG' => 0,
                 'modifiers' => 'x',
                 'method' => 'sequential',
                 '_ERROR' => '',
                 'dispatcher' => bless( {
                                          'plugin_root' => 'List::Filter::Transforms',
                                          '_ID' => 'List::Filter::Dispatcher',
                                          '_DEBUG' => 0,
                                          '_ERROR' => ''
                                        }, 'List::Filter::Dispatcher' )
               }, 'List::Filter::Transform' );
   return $ret;
EXP2
   my $ret = eval $definition ;
   if ($@) {
     die "Problem in evaluation of code: $ret\n";
   }
   return $ret;
 }
