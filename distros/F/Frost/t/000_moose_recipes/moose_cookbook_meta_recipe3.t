#!/usr/bin/perl -w

use strict;
use Test::More;
use Test::Exception;
$| = 1;

BEGIN
{
	plan skip_all => 'TODO: Adopt for Forst';
}

# =begin testing SETUP
{

  package MyApp::Meta::Attribute::Trait::Labeled;
  use Moose::Role;

  has label => (
      is        => 'rw',
      isa       => 'Str',
      predicate => 'has_label',
  );

  package Moose::Meta::Attribute::Custom::Trait::Labeled;
  sub register_implementation {'MyApp::Meta::Attribute::Trait::Labeled'}

  package MyApp::Website;
  use Moose;

  has url => (
      traits => [qw/Labeled/],
      is     => 'rw',
      isa    => 'Str',
      label  => "The site's URL",
  );

  has name => (
      is  => 'rw',
      isa => 'Str',
  );

  sub dump {
      my $self = shift;

      my $meta = $self->meta;

      my $dump = '';

      for my $attribute ( map { $meta->get_attribute($_) }
          sort $meta->get_attribute_list ) {

          if (   $attribute->does('MyApp::Meta::Attribute::Trait::Labeled')
              && $attribute->has_label ) {
              $dump .= $attribute->label;
          }
          else {
              $dump .= $attribute->name;
          }

          my $reader = $attribute->get_read_method;
          $dump .= ": " . $self->$reader . "\n";
      }

      return $dump;
  }

  package main;

  my $app = MyApp::Website->new( url => "http://google.com", name => "Google" );
}



# =begin testing
{
my $app2
    = MyApp::Website->new( url => "http://google.com", name => "Google" );
is(
    $app2->dump, q{name: Google
The site's URL: http://google.com
}, '... got the expected dump value'
);
}



done_testing;

