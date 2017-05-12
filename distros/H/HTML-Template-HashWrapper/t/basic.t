#!/usr/bin/perl -w
use strict;
use Test::More tests => 109;
#use Test::Exception;

BEGIN {
  use_ok( 'HTML::Template::HashWrapper' );
}

{ # package for testing extension of existing objects
  package Temp::Test;
  sub test {
    my $self = shift;
    return 31337;
  }
}

{ # package for testing subclassing of H::T::HW
  package Temp::MySubclass;
  our @ISA = qw( HTML::Template::HashWrapper );

  sub chicken {
    return "chicken";
  }

  package Temp::MySubclass::Plain;
  our @ISA = qw( HTML::Template::HashWrapper::Plain );
}

my @test_classes = ( 'HTML::Template::HashWrapper',
		     'Temp::MySubclass',
		   );

foreach my $test_class (@test_classes) {
  blessed_hashref_tests       ( $test_class );
  blessed_object_tests        ( $test_class );
  unblessed_hashref_tests     ( $test_class );
  unblessed_object_tests      ( $test_class );
}

# Run the bogus tests only if we have test::exception available
SKIP: {
  eval "require Test::Exception";
  skip( "Test::Exception not installed", 4*@test_classes ) if $@;

  foreach my $test_class (@test_classes) {
    blessed_bogus_input_tests   ( $test_class );
    unblessed_bogus_input_tests ( $test_class );
  }
}

subclass_tests();

sub subclass_tests {
  foreach my $nobless (0,1) {
    my $simple = { guido => '251-5049',
		   cheap_company => '555-1212',
		 };
    my $x = Temp::MySubclass->new( $simple, nobless => $nobless );
    can_ok( $x, 'chicken' );
    ok( $x->chicken eq "chicken", 'Inherits ok' );
  }
}

#----------------------------------------
# nobless => 0 (default)

sub blessed_hashref_tests {
  my $CLASSNAME = shift;

  # new(hashref) should result in a H::T::HW::ANON_*
  my $simple = { guido => '251-5049',
		 cheap_company => '555-1212',
	       };
  ok( ref($simple) eq 'HASH', 'orig is a hashref');
  my $x = $CLASSNAME->new($simple);
  # $simple is now blessed
  ok( ref($simple) ne 'HASH', 'orig is blessed' );
  isa_ok( $x, 'HTML::Template::HashWrapper');
  # $simple and $x are same reference
  ok( $simple eq $x, 'new and orig are same reference' );
  # param exists as a method
  can_ok( $x, 'param' );
  # param() returns the right value
  ok( $x->param('guido') eq $simple->{guido}, 'new obj can do param correct' );
  ok( $x->param('guido') eq '251-5049', 'data still exists in hashref' );
  # param($n,$v) is setter
  $x->param('newname', 'newval');
  ok( $x->param('newname') eq 'newval', 'param($x,$y) works as setter' );
  # test param() in list context => param names
  ok( scalar($x->param()) == 3, 'zero-arg param returns name list' );
  ok( grep('guido', $x->param()), 'param() returns name list (1)' );
  ok( grep('cheap_company', $x->param()), 'param() returns name list (2)' );
  ok( grep('newname', $x->param()), 'param() returns name list (3)' );
}

sub blessed_bogus_input_tests {
  my $CLASSNAME = shift;

  # new(non-hashref) should result in death
  foreach my $bogus( 251, [2,5,1,5,0,4,9] ) {
    Test::Exception::dies_ok( sub {
				my $x = $CLASSNAME->new($bogus);
			      },
			      "not allowed: wrapping $bogus"
			    );
  }
}

sub blessed_object_tests {
  my $CLASSNAME = shift;

  # new($object) should result in a new H::T::HW::ANON,
  #    which extends $obj's class
  my $obj = bless { sneaky => 'devil' }, 'Temp::Test';
  ok( ref($obj), 'orig is a reference' );
  my $orig_type = ref($obj);
  my $x = $CLASSNAME->new($obj);
  ok( defined($x), 'new returned something' );
  ok( $x eq $obj, 'returned ref is same ref as orig' );
  ok( ref($obj) ne $orig_type, 'original reblessed' );
  isa_ok( $x, $orig_type );
  isa_ok( $x, 'HTML::Template::HashWrapper' );
  can_ok( $x, 'param' );
  can_ok( $x, 'test' ); # $x should retain old interface
  ok( $x->test() == 31337, 'old interface still works' );
  ok( $x->param( 'sneaky' ) eq $x->{sneaky}, 'param works' );
  ok( $x->param( 'sneaky' ) eq 'devil', 'param works and data still exists' );
  # param($n,$v) is setter
  $x->param('newname', 'newval');
  ok( $x->param('newname') eq 'newval', 'param($x,$y) works as setter' );
}

#----------------------------------------
# HTML::Template::Plain

sub unblessed_hashref_tests {
  my $CLASSNAME = shift;

  # new(hashref) should return a H::T::HW::Plain
  # should leave the original unblessed
  my $simple = { guido => '251-5049',
		 cheap_company => '555-1212',
	       };
  ok( ref($simple) eq 'HASH', 'orig is a hashref');
  my $x = HTML::Template::HashWrapper::Plain->new($simple);
  # $simple is still blessed
  ok( ref($simple) eq 'HASH', 'orig remains unblessed' );
  isa_ok( $x, 'HTML::Template::HashWrapper'); # someone might care
  isa_ok( $x, 'HTML::Template::HashWrapper::Plain');
  # $simple and $x are different references
  ok( $simple ne $x, 'new and orig are different references' );
  # param exists as a method
  can_ok( $x, 'param' );
  # param() returns the right value
  ok( $x->param('guido') eq $simple->{guido}, 'new obj can do param correct' );
  ok( $x->param('guido') eq '251-5049', 'data still exists in hashref' );
  # param($n,$v) is setter
  $x->param('newname', 'newval');
  ok( $x->param('newname') eq 'newval', 'param($x,$y) works as setter' );
  # param setter also modifies original hash
  ok( $simple->{newname} eq 'newval', 'param($x) modifies original' );
  # test param() in list context => param names
  ok( scalar($x->param()) == 3, 'zero-arg param returns name list' );
  ok( grep('guido', $x->param()), 'param() returns name list (1)' );
  ok( grep('cheap_company', $x->param()), 'param() returns name list (2)' );
  ok( grep('newname', $x->param()), 'param() returns name list (3)' );
}

sub unblessed_bogus_input_tests {
  my $CLASSNAME = shift;

  # new(non-hashref) should result in death - unchanged for nobless
  foreach my $bogus( 251, [2,5,1,5,0,4,9] ) {
    Test::Exception::dies_ok
	( sub {
	    my $x = HTML::Template::HashWrapper::Plain->new($bogus);
	  },
	  "not allowed: wrapping $bogus"
	);
  }
}

sub unblessed_object_tests {
  my $CLASSNAME = shift;

  # new($object) should result in a new H::T::HW::Plain
  #    which extends $obj's class
  my $obj = bless { sneaky => 'devil' }, 'Temp::Test';
  ok( ref($obj), 'orig is a reference' );
  my $orig_type = ref($obj);
  my $x = HTML::Template::HashWrapper::Plain->new($obj);
  ok( defined($x), 'new returned something' );
  ok( $x ne $obj, 'returned ref is not same ref as orig' );
  ok( ref($obj) eq $orig_type, 'original is not reblessed' );
  #isa_ok( $x, $orig_type ); # $x does *not* extend the original
  isa_ok( $x, 'HTML::Template::HashWrapper' );
  isa_ok( $x, 'HTML::Template::HashWrapper::Plain' );
  can_ok( $x, 'param' );
  # can_ok( $x, 'test' ); # $x should retain old interface
  # ok( $x->test() == 31337, 'old interface still works' );
  ok( $x->param( 'sneaky' ) eq $x->{_ref}->{sneaky}, 'param works' );
  ok( $x->param( 'sneaky' ) eq 'devil', 'param works and data still exists' );
  # param($n,$v) is setter
  $x->param('newname', 'newval');
  ok( $x->param('newname') eq 'newval', 'param($x,$y) works as setter' );
}
