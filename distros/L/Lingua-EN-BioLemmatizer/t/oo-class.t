#
# Lingua/EN/BioLemmatizer/t/oo-class.t 
#
# This tests overall class mechanics and class method calls,
# and verifies that you can't call object methods as class methods.
# See oo-object.t for testing object methods.
#
# No actual BioLemmatizer is needed for this test set, which means
# it will run fast and won't incur the 10-second start-up delay needed
# to actually launch the BioLemmatizer, the way oo-object.t does.
#

use 5.010;
use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok("Lingua::EN::BioLemmatizer")
	|| BAIL_OUT("can't run any tests without the module available");
}

ok !defined(&biolemma) => "no import without asking";

our @All_Methods = (
  # List all constructor methods here:
    "new",
  # List all regular methods here:
    "child_pid",
    "command_args",
    "from_biolemmer",
    "get_biolemma",
    "into_biolemmer",
    "jar_args",
    "jar_path",
    "java_args",
    "java_path",
    "lemma_cache",
  # List all (pseudo-)private methods here:
   "_handle_request",
);

for my $meth (@All_Methods) {
    can_ok("Lingua::EN::BioLemmatizer", $meth);
}


############################################################
# Test new() contructor
############################################################
{

# here check only for bad calls, stuff that shouldn't get a good one.
# save time-expensive object creation in other file.

    throws_ok { Lingua::EN::BioLemmatizer::new() } 
	   qr/expected args/
	=> "catch constructor miscalled as function of no args";

    throws_ok { Lingua::EN::BioLemmatizer::new( \42 ) } 
	   qr/constructor called as function with unblessed ref argument/
	=> "catch constructor miscalled as function with unblessed ref";

    # make a fake object because we don't want to pay the 10s start up
    # for a real one for this purpose
    my $bogus_obj = bless {} => "Lingua::EN::BioLemmatizer";

    throws_ok { $bogus_obj->new } 
	   qr/constructor invoked as object method/
	=> "catch constructor misinvoked as object method";

    throws_ok { Lingua::EN::BioLemmatizer->new("fred", "barney") }  
	   qr/unexpected arg/
	=> "catch class constructor with unexpected argument pair";

    throws_ok { Lingua::EN::BioLemmatizer->new(1 .. 20) }  
	   qr/unexpected arg/
	=> "catch class constructor with many unexpected arguments";

}


############################################################
# Test child_pid() object method (getter, not setter)
############################################################
{

    throws_ok { Lingua::EN::BioLemmatizer->child_pid }
	qr/object method called as class method/
     => "catch child_pid called as class method";

}

############################################################
# Test into_biolemmer() object method (getter, not setter)
############################################################
{

    throws_ok { Lingua::EN::BioLemmatizer->into_biolemmer }
	qr/object method called as class method/
     => "catch into_biolemmer called as class method";

}

############################################################
# Test from_biolemmer() object method (getter, not setter)
############################################################
{

    throws_ok { Lingua::EN::BioLemmatizer->from_biolemmer }
	qr/object method called as class method/
     => "catch from_biolemmer called as class method";

}

############################################################
# Test lemma_cache() object method (getter, not setter)
############################################################
{

    throws_ok { Lingua::EN::BioLemmatizer->lemma_cache }
	qr/object method called as class method/
     => "catch lemma_cache called as class method";

}

############################################################
# Test java_path() class getter/setter or object getter only
############################################################
{
    if (lives_ok { Lingua::EN::BioLemmatizer->java_path }
	"invoke java_path getter as class method")
    {
	my $old_path = Lingua::EN::BioLemmatizer->java_path;
	my $new_path = "/foo/bar/java";
	if (lives_ok { Lingua::EN::BioLemmatizer->java_path($new_path) }
	    "invoke java_path setter as class method") 
	{
	    is(Lingua::EN::BioLemmatizer->java_path, $new_path,
		"set java_path to new value and fetch it back");
	    # now put it back for safe-keeping
	    Lingua::EN::BioLemmatizer->java_path($old_path);
	} 
    } 

}

############################################################
# Test jar_path() class getter/setter or object getter only
############################################################
{

    if (lives_ok { Lingua::EN::BioLemmatizer->jar_path }
	"invoke jar_path getter as class method")
    {
	my $old_path = Lingua::EN::BioLemmatizer->jar_path;
	my $new_path = "/foo/bar/blemmatize.jar";
	if (lives_ok { Lingua::EN::BioLemmatizer->jar_path($new_path) }
	    "invoke jar_path setter as class method") 
	{
	    is(Lingua::EN::BioLemmatizer->jar_path, $new_path,
		"set jar_path to new value and fetch it back");
	    # now put it back for safe-keeping
	    Lingua::EN::BioLemmatizer->jar_path($old_path);
	} 
    } 


}

############################################################
# Test java_args() class getter/setter or object getter only
############################################################
{
    if (lives_ok { Lingua::EN::BioLemmatizer->java_args }
	"invoke java_args getter as class method")
    {
	my $old_args = Lingua::EN::BioLemmatizer->java_args;
	my $new_args = ["fie", "fie", "foe", "fum"];
	if (lives_ok { Lingua::EN::BioLemmatizer->java_args($new_args) }
	    "invoke java_args setter as class method") 
	{
	    my $argref = Lingua::EN::BioLemmatizer->java_args;
	    is_deeply($argref, $new_args,
		"set java_args to new value and fetch it back (SCALAR)");

	    # try list context return
	    my @args = Lingua::EN::BioLemmatizer->java_args;
	    is_deeply(\@args, $new_args,
		"set java_args to new value and fetch it back (LIST)");

	    # now put it back for safe-keeping
	    Lingua::EN::BioLemmatizer->java_args($old_args);

	    $argref = Lingua::EN::BioLemmatizer->java_args;
	    is_deeply($argref, $old_args, "restore original java_args value");
	} 
    } 
}

############################################################
# Test jar_args() class getter/setter or object getter only
############################################################
{
    if (lives_ok { Lingua::EN::BioLemmatizer->jar_args }
	"invoke jar_args getter as class method")
    {
	my $old_args = Lingua::EN::BioLemmatizer->jar_args;
	my $new_args = ["fie", "fie", "foe", "fum"];
	if (lives_ok { Lingua::EN::BioLemmatizer->jar_args($new_args) }
	    "invoke jar_args setter as class method") 
	{
	    my $argref = Lingua::EN::BioLemmatizer->jar_args;
	    is_deeply($argref, $new_args,
		"set jar_args to new value and fetch it back (SCALAR)");

	    # try list context return
	    my @args = Lingua::EN::BioLemmatizer->jar_args;
	    is_deeply(\@args, $new_args,
		"set jar_args to new value and fetch it back (LIST)");

	    # now put it back for safe-keeping
	    Lingua::EN::BioLemmatizer->jar_args($old_args);

	    $argref = Lingua::EN::BioLemmatizer->jar_args;
	    is_deeply($argref, $old_args, "restore original jar_args value");
	} 
    } 

}

############################################################
# Test command_args() dual getter, not setter
############################################################
{
    dies_ok { Lingua::EN::BioLemmatizer->command_args("a", "b") }
	"command_args correctly dies used as class setter";

    if (lives_ok { Lingua::EN::BioLemmatizer->command_args }
	"invoke command_args getter as class method")
    {
	my @args = Lingua::EN::BioLemmatizer->command_args;
	my $argc = scalar @args;
	cmp_ok $argc, ">=", 3, "at least three command args";
    } 

}

############################################################
# Test get_biolemma() object method, not class method
############################################################
{
    dies_ok { Lingua::EN::BioLemmatizer->get_biolemma("mice") }
	"catch get_biolemma correctly dying used as class method";
}

############################################################
# Test _handle_request() notationally private method
############################################################
{

    throws_ok { Lingua::EN::BioLemmatizer->_handle_request("mice")  }
	qr/don't call private methods/,
	"catch invoke _handle_request private method";

    throws_ok { package Lingua::EN::BioLemmatizer; 
	       Lingua::EN::BioLemmatizer->_handle_request("mice")  }
	qr/object method called as class method/,
	"catch (privately) invoke _handle_request as class method";


}

done_testing();
