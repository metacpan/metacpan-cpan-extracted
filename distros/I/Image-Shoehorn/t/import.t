use strict;

use Test::More;
plan tests => 19;

{
  &main();
  exit;
}

sub main {

  # Tests 1-3

  use_ok(qq(Image::Shoehorn));
  use_ok(qq(Data::Dumper));
  use_ok(qq(Cwd));

  # Test 4

  my $examples = &Cwd::getcwd()."/examples";
  ok(-d $examples);

  # Test 5

  my $source = "$examples/20020313-scary-easter-monsters.jpg";
  ok(-f $source);

  # Test 6

  my $image = Image::Shoehorn->new({
				    tmpdir  => $examples,
				    cleanup => \&cleanup,
				   });

  isa_ok($image,"Image::Shoehorn");

  # Test 7

  my $imgs = $image->import({
			     source     => $source,
			     valid      => [ "png" ],
			     convert    => 1,
			     max_height => 200,
			     scale      => {small=>"25%"},
			  });

  # Test 8

  cmp_ok(scalar(keys %$imgs),"==",2);

  # Tests 9-14

  ok(-f $imgs->{source}->{path});
  cmp_ok($imgs->{source}->{width},"==",298);
  cmp_ok($imgs->{source}->{height},"==",200);
  cmp_ok($imgs->{source}->{extension},"eq","png");
  cmp_ok($imgs->{source}->{contenttype},"eq","image/png");
  cmp_ok($imgs->{source}->{format},"eq","Portable Network Graphics");

  # Tests 15-19

  ok(-f $imgs->{small}->{path});
  cmp_ok($imgs->{small}->{width},"==",74);
  cmp_ok($imgs->{small}->{height},"==",50);
  cmp_ok($imgs->{small}->{extension},"eq","png");
  cmp_ok($imgs->{small}->{contenttype},"eq","image/png");
  cmp_ok($imgs->{source}->{format},"eq","Portable Network Graphics");

  #

  &diag(&Dumper($imgs));
  return 1;
}

sub cleanup {
  my $imgs = shift;
  print "This is the user-defined cleanup method.\n";
  map { print "Hello $imgs->{$_}->{'path'}\n"; } keys %$imgs;
}

# $Id: import.t,v 1.1 2003/05/30 22:44:28 asc Exp $
