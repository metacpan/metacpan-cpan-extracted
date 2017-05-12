#!/usr/bin/perl

####################################################################
# This test tests the repository (Froody::Repository)
####################################################################

use strict;
use warnings;

# use the local directory.  Note that this doesn't work

# useful diagnostic modules that's good to have loaded
use Data::Dumper;
use Devel::Peek;

# colourising the output if we want to
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

###################################
# user editable parts

# start the tests
use Test::More tests => 73;
use Test::Exception;

use_ok("Froody::Repository");
use_ok("Froody::Method");
use_ok("Froody::ErrorType");

use Froody::Error qw(err);

########
# create a repository
########

my $repos = Froody::Repository->new();
isa_ok($repos, "Froody::Repository");

########
# do we have the default stuff in there?
########

lives_ok {
  my @methods = $repos->get_methods();
  is(@methods, 5, "right number of default methods");
  isa_ok($_, "Froody::Method", "got a froody method back")
    foreach (@methods);
  is_deeply([ sort map { $_->full_name } @methods], [qw(
    froody.reflection.getErrorTypeInfo
    froody.reflection.getErrorTypes
    froody.reflection.getMethodInfo
    froody.reflection.getMethods
    froody.reflection.getSpecification
  )], "right default methods returned");
} "got default methods back without dieing";

lives_ok {
  my $errortype = $repos->get_errortype("");
  isa_ok($errortype, "Froody::ErrorType", "got right error type back");
  is($errortype->name, "", "error type of no name returns");
};

#######
# inserting and getting methods
#######

{

# stuff a couple of methods into it
my $fish = Froody::Method->new
                         ->full_name("bungle.wibble.fish");
my $fosh = Froody::Method->new
                         ->full_name("bungle.wibble.fosh");

lives_ok {
  $repos->register_method($fish);
  $repos->register_method($fosh);
} "stuffed methods in okay";

# we can't just stuff any old junk in here can we?

dies_ok {
  $repos->register_method("this is just a string");
} "dies when registering a string";
ok(err("perl.methodcall.param"), "bad param me no like!")
 or diag($@);

dies_ok {
  $repos->register_method();
} "dies when registering emptyness";
ok(err("perl.methodcall.param"), "bad param me no like!")
 or diag($@);

dies_ok {
  $repos->register_method(bless {}, "Frood::ErrorType");
} "dies when registering wrong object type";
ok(err("perl.methodcall.param"), "bad param me no like!")
 or diag($@);

# can we get those methods back?

lives_ok {
  my $fish2 = $repos->get_method("bungle.wibble.fish");
  my $fosh2 = $repos->get_method("bungle.wibble.fosh");
  isa_ok($fish2, "Froody::Method");
  isa_ok($fosh2, "Froody::Method");
  is($fish2->full_name, "bungle.wibble.fish", "fish came out okay");
  is($fosh2->full_name, "bungle.wibble.fosh", "fosh came out okay");
} "lives when getting methods";

# can we not get back some made up method name?

dies_ok {
  $repos->get_method("some made up string!");
} "getting made up method name!";
ok(err("froody.invoke.nosuchmethod"), "bad param me no like!")
 or diag($@);

# can we get back our methods using a regular expression?
lives_ok {
  my ($fish2, $fosh2) =
    sort { $a->full_name cmp $b->full_name } $repos->get_methods(qr/bungle/);
  isa_ok($fish2, "Froody::Method");
  isa_ok($fosh2, "Froody::Method");
  is($fish2->full_name, "bungle.wibble.fish", "fish came out okay");
  is($fosh2->full_name, "bungle.wibble.fosh", "fosh came out okay");
} "lives when getting methods with regexp";

# can we get back our methods using a wildcard expression?
lives_ok {
  my ($fish2, $fosh2) =
    sort { $a->full_name cmp $b->full_name } $repos->get_methods("bungle.wibble.*");
  isa_ok($fish2, "Froody::Method");
  isa_ok($fosh2, "Froody::Method");
  is($fish2->full_name, "bungle.wibble.fish", "fish came out okay");
  is($fosh2->full_name, "bungle.wibble.fosh", "fosh came out okay");
} "lives when getting methods with wildcard";

}

#######
# inserting and getting errors
#######

{
# stuff a couple of methods into it
my $fish = Froody::ErrorType->new
                         ->name("zippy.wibble.fish");
my $fosh = Froody::ErrorType->new
                         ->name("zippy.wibble.fosh");

lives_ok {
  $repos->register_errortype($fish);
  $repos->register_errortype($fosh);
} "stuffed ets in okay";

# we can't just stuff any old junk in here can we?

dies_ok {
  $repos->register_errortype("this is just a string");
} "dies when registering a string";
ok(err("perl.methodcall.param"), "bad param me no like!")
 or diag($@);


dies_ok {
  $repos->register_errortype();
} "dies when registering emptyness";
ok(err("perl.methodcall.param"), "bad param me no like!")
 or diag($@);

dies_ok {
  $repos->register_errortype(bless {}, "Froody::Method");
} "dies when registering wrong method type";
ok(err("perl.methodcall.param"), "bad param me no like!")
 or diag($@);


# can we get those methods back?

lives_ok {
  my $fish2 = $repos->get_errortype("zippy.wibble.fish");
  my $fosh2 = $repos->get_errortype("zippy.wibble.fosh");
  isa_ok($fish2, "Froody::ErrorType");
  isa_ok($fosh2, "Froody::ErrorType");
  is($fish2->name, "zippy.wibble.fish", "fish came out okay");
  is($fosh2->name, "zippy.wibble.fosh", "fosh came out okay");
} "lives when getting methods";

# can we get back our methods using a regular expression?
lives_ok {
  my ($fish2, $fosh2) =
    sort { $a->name cmp $b->name } $repos->get_errortypes(qr/zippy/);
  isa_ok($fish2, "Froody::ErrorType");
  isa_ok($fosh2, "Froody::ErrorType");
  is($fish2->name, "zippy.wibble.fish", "fish came out okay");
  is($fosh2->name, "zippy.wibble.fosh", "fosh came out okay");
} "lives when getting methods with regexp";

# can we get back our methods using a wildcard expression?
lives_ok {
  my ($fish2, $fosh2) =
    sort { $a->name cmp $b->name } $repos->get_errortypes("zippy.wibble.*");
  isa_ok($fish2, "Froody::ErrorType");
  isa_ok($fosh2, "Froody::ErrorType");
  is($fish2->name, "zippy.wibble.fish", "fish came out okay");
  is($fosh2->name, "zippy.wibble.fosh", "fosh came out okay");
} "lives when getting methods with wildcard";

}

#######
# nearest matching for error things
#######

{

# stuff a couple of methods into it
foreach (qw(one.alpha.antman one.alpha.batman one.beta.antman
            one.beta.batman one.alpha one))
{
  $repos->register_errortype(Froody::ErrorType->new->name($_));
};

my %hash = (

  # things that are just in there are things that just things that are in there

 'one.alpha.antman' => 'one.alpha.antman',
 'one.alpha.batman' => 'one.alpha.batman',
 'one.beta.antman' => 'one.beta.antman',
 'one.beta.batman' => 'one.beta.batman',
 'one.alpha' => 'one.alpha',
 'one' => 'one',
 
 # something that doesn't match anything goes back to the default
 "three" => "",
 
 # something that doesn't exist goes back to the right level
 "one.alpha.spiderman"                => "one.alpha",
 "one.alpha.spiderman.amazingfriends" => "one.alpha",
 "one.beta"                           => "one",
 "one.beta.spiderman"                 => "one",
 "two.alpha.antman"                   => "",
);

foreach (keys %hash)
{
   my $et = $repos->get_closest_errortype( $_ );
   is($et->name, $hash{ $_ }, "closest error type for '$_'?");
}

}
