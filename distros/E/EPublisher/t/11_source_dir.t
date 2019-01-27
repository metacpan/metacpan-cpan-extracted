#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 30; 
use File::Basename;
use File::Spec;
use lib qw(../lib ../../perllib);
use YAML::Tiny;

my $dir    = File::Spec->rel2abs( dirname( __FILE__ ) );

my $module = 'EPublisher::Source';
use_ok( $module );

{
    package # private package
        MockPublisher;
    
    my $test = '';
    
    sub new { return bless {}, shift }
    sub debug { $test = $_[1] if @_ == 2; return $test }
}

{
   my $source = $module->new({
      type => 'Dir',
      path => File::Spec->catdir( dirname( __FILE__ ), 'lib' ),
   });
   
   ok( $source->isa( 'EPublisher::Source::Plugin::Dir' ), '$source isa EPublisher::Source::Plugin::Dir' );
   ok( $source->isa( 'EPublisher::Source::Base' ),        '$source isa EPublisher::Source::Base' );

   my ($info) = $source->load_source;
   ok( $source->load_source, 'check *::Dir::load_source()' );

   my $check = {
       pod => '=pod

=head1 Text - a test library for text output

Ein Absatz im POD.

=cut
',
       filename => 'Text.pm',
       title => 'Text.pm',
   };
   
   is_deeply( $info, $check, 'check return value of *::File::load_source()' );
}

{
   my $source = $module->new({
      type => 'Dir',
      path => File::Spec->catdir( dirname( __FILE__ ), 'lib' ),
      title => 'pod',
   });
   
   ok( $source->isa( 'EPublisher::Source::Plugin::Dir' ), '$source isa EPublisher::Source::Plugin::Dir' );
   ok( $source->isa( 'EPublisher::Source::Base' ),         '$source isa EPublisher::Source::Base' );

   my ($info) = $source->load_source;
   ok( $source->load_source, 'check *::Dir::load_source()' );

   my $check = {
       pod => '=pod

=head1 Text - a test library for text output

Ein Absatz im POD.

=cut
',
       filename => 'Text.pm',
       title => 'Text - a test library for text output',
   };
   
   is_deeply( $info, $check, 'check return value of *::Dir::load_source()' );
}


{
   my $source = $module->new({
      type => 'Dir',
      path => [ File::Spec->catdir( dirname( __FILE__ ), 'lib' ) ],
      title => 'pod',
   });
   
   ok( $source->isa( 'EPublisher::Source::Plugin::Dir' ), '$source isa EPublisher::Source::Plugin::Dir' );
   ok( $source->isa( 'EPublisher::Source::Base' ),         '$source isa EPublisher::Source::Base' );

   my ($info) = $source->load_source;
   ok( $source->load_source, 'check *::Dir::load_source()' );

   my $check = {
       pod => '=pod

=head1 Text - a test library for text output

Ein Absatz im POD.

=cut
',
       filename => 'Text.pm',
       title => 'Text - a test library for text output',
   };
   
   is_deeply( $info, $check, 'check return value of *::Dir::load_source()' );
}

{
   my $source = $module->new({
      type => 'Dir',
      path => [ 
          File::Spec->catdir( dirname( __FILE__ ), 'lib' ),
          File::Spec->catdir( dirname( __FILE__ ), 'second_lib' ),
      ],
      title => 'pod',
   });
   
   ok( $source->isa( 'EPublisher::Source::Plugin::Dir' ), '$source isa EPublisher::Source::Plugin::Dir' );
   ok( $source->isa( 'EPublisher::Source::Base' ),         '$source isa EPublisher::Source::Base' );

   my @info = $source->load_source;
   ok( $source->load_source, 'check *::Dir::load_source()' );

   my $check = [
       {
           pod => '=pod

=head1 Text - a test library for text output

Ein Absatz im POD.

=cut
',
           filename => 'Text.pm',
           title => 'Text - a test library for text output',
       },
       {
           pod => '=pod

=head1 AnotherText - a test library for text output

Ein Absatz im POD.

=cut
',
           filename => 'AnotherText.pm',
           title => 'AnotherText - a test library for text output',
       },
   ];
   
   is_deeply( \@info, $check, 'two libraries' );
}


{
   my $path   = File::Spec->catdir( dirname( __FILE__ ), 'nonexistent_lib' );
   my $source = $module->new({
      type => 'Dir',
      path => [ 
          File::Spec->catdir( dirname( __FILE__ ), 'lib' ),
          $path,
      ],
      title => 'pod',
   });
   
   my $mock_publisher = MockPublisher->new;
   $source->publisher( $mock_publisher );
   
   ok( $source->isa( 'EPublisher::Source::Plugin::Dir' ), '$source isa EPublisher::Source::Plugin::Dir' );
   ok( $source->isa( 'EPublisher::Source::Base' ),         '$source isa EPublisher::Source::Base' );

   my @info = $source->load_source;
   ok( $source->load_source, 'check *::Dir::load_source()' );

   my $check = [
       {
           pod => '=pod

=head1 Text - a test library for text output

Ein Absatz im POD.

=cut
',
           filename => 'Text.pm',
           title => 'Text - a test library for text output',
       },
   ];
   
   is_deeply( \@info, $check, 'debug on non-existant dir' );
   is $mock_publisher->debug, "400: $path does not exist", 'non existant dir not found (debug message)';
}


{
   my $source = $module->new({
      type => 'Dir',
      path => File::Spec->catdir( dirname( __FILE__ ), 'lib' ),
      title => 'package',
   });
   
   ok( $source->isa( 'EPublisher::Source::Plugin::Dir' ), '$source isa EPublisher::Source::Plugin::Dir' );
   ok( $source->isa( 'EPublisher::Source::Base' ),         '$source isa EPublisher::Source::Base' );

   my ($info) = $source->load_source;
   ok( $source->load_source, 'check *::Dir::load_source()' );

   my $check = {
       pod => '=pod

=head1 Text - a test library for text output

Ein Absatz im POD.

=cut
',
       filename => 'Text.pm',
       title => 'Test::Text',
   };
   
   is_deeply( $info, $check, 'package namespace used as title' );
}



{
   my $source = $module->new({
      type => 'Dir',
      path => File::Spec->catdir( dirname( __FILE__ ), 'third_lib' ),
      title => 'package',
      exclude => 'subdir'
   });
   
   ok( $source->isa( 'EPublisher::Source::Plugin::Dir' ), '$source isa EPublisher::Source::Plugin::Dir' );
   ok( $source->isa( 'EPublisher::Source::Base' ),         '$source isa EPublisher::Source::Base' );

   my ($info) = $source->load_source;
   ok( $source->load_source, 'check *::Dir::load_source()' );

   my $check = {
       pod => '=pod

=head1 AnotherText - a test library for text output

Ein Absatz im POD.

=cut
',
       filename => 'AnotherText.pm',
       title => 'AnotherText.pm',
   };
   
   is_deeply( $info, $check, 'exclude subdirectory' );
}
