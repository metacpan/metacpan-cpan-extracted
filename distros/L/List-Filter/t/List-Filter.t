# Test file. Run like: "perl List-Filter.t"
#   doom@kzsu.stanford.edu     2007/03/13 02:35:07

use warnings;
use strict;
$|=1;
my $DEBUG = 0;
use Data::Dumper;

use Test::More;
BEGIN { plan tests => 8};
use FindBin qw($Bin);
use lib ("$Bin/../..");

BEGIN {
  use_ok( 'List::Filter' );
}

ok(1, "Traditional: 'Made it this far'");

my ( $filter1,  $filter2 );

{ my $test_name = "Testing creation an empty filter object and then loading it with setters";
   my $expectorant = define_expect_1();

   $filter1 = List::Filter->new();  # creates an *empty* filter

   my @terms = ['-\.vb$', '-\.js$'];
   $filter1->set_terms( \@terms );
   $filter1->set_name('skip_dull');
   $filter1->set_method('skip_boring_stuff');
   $filter1->set_description(
             "Skip the really boring stuff");
   $filter1->set_modifiers( "xi" );

   my $dump1 = Dumper($filter1);
   ($DEBUG) && print "filter object: $dump1\n";

   is_deeply($filter1, $expectorant, "$test_name");
 }


{  my $test_name = "Testing creation of a filter object with defined fields";
   my $expectorant = define_expect_2();

   $filter2 = List::Filter->new(
     { terms => ['-\.vb$', '\-.js$'],
       name         => 'skip_dull',
       method       => 'skip_boring_stuff',
       description  => "Skip the really boring stuff",
       modifiers    => "xi",
     } );

   my $dump2 = Dumper($filter2);
   ($DEBUG) && print "filter object: $dump2\n";
   is_deeply($filter2, $expectorant, "$test_name");

   $test_name = "Testing the getters: ";

   my $terms  = $filter2->terms;
   my $method        = $filter2->method;
   my $description   = $filter2->description;
   my $modifiers     = $filter2->modifiers;

   my $expected_terms = ['-\.vb$', '\-.js$'];
   my $expected_method       = 'skip_boring_stuff';
   my $expected_description  = "Skip the really boring stuff";
   my $expected_modifiers    = "xi";

   is_deeply($terms, $expected_terms, "$test_name: terms");

   is($method,      $expected_method,       "$test_name: method");
   is($description, $expected_description,  "$test_name: description");
   is($modifiers,   $expected_modifiers,    "$test_name: modifiers");
 }


### Heredoc ghetto
# (These don't just return strings, but rather eval strings to get de-serialized objects)
sub define_expect_1 {
   my $definition =<<'EXP1';
     my $ret = bless( {
                 'save_filters_when_used' => undef,
                 '_ID' => 'List::Filter',
                 'name' => 'skip_dull',
                 'terms' => [
                              [
                                '-\\.vb$',
                                '-\\.js$'
                              ]
                            ],
                 'description' => 'Skip the really boring stuff',
                 'storage_handler' => undef,
                 '_DEBUG' => 0,
                 'modifiers' => 'xi',
                 'method' => 'skip_boring_stuff',
                 '_ERROR' => '',
                 'dispatcher' => bless( {
                                          'plugin_root' => 'List::Filter::Filters',
                                          '_ID' => 'List::Filter::Dispatcher',
                                          '_DEBUG' => 0,
                                          '_ERROR' => ''
                                        }, 'List::Filter::Dispatcher' )
               }, 'List::Filter' );
     return $ret;
EXP1
   my $ret = eval $definition;
   if ($@) {
     die "Problem in evaluation of code: $ret\n";
   }
   return $ret;
 }

sub define_expect_2 {
   my $definition =<<'EXP2';
     my $ret = bless( {
                 'save_filters_when_used' => undef,
                 '_ID' => 'List::Filter',
                 'name' => 'skip_dull',
                 'terms' => [
                              '-\\.vb$',
                              '\\-.js$'
                            ],
                 'description' => 'Skip the really boring stuff',
                 'storage_handler' => undef,
                 '_DEBUG' => 0,
                 'modifiers' => 'xi',
                 'method' => 'skip_boring_stuff',
                 '_ERROR' => '',
                 'dispatcher' => bless( {
                                          'plugin_root' => 'List::Filter::Filters',
                                          '_ID' => 'List::Filter::Dispatcher',
                                          '_DEBUG' => 0,
                                          '_ERROR' => ''
                                        }, 'List::Filter::Dispatcher' )
               }, 'List::Filter' );
   return $ret;
EXP2
   my $ret = eval $definition ;
   if ($@) {
     die "Problem in evaluation of code: $ret\n";
   }
   return $ret;
 }
