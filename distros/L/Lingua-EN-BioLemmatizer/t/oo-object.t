#
# Lingua/EN/BioLemmatizer/t/oo-object.t 
#
# This tests object method calls.  See oo-class.t for testing
# class method calls and overall class mechanics.
#
# This is in a separate file because it takes a 
# really long time (~10 seconds) to instantiate an object.
#
##############################################

use 5.010;
use strict;
use warnings;

use Scalar::Util qw(blessed openhandle reftype looks_like_number);
use Devel::Peek  qw(SvREFCNT);  # to check refcounting on object
use Errno;			# imports magical %! to track errno in $!

use Test::More;
use Test::Exception;

BEGIN { 
    use_ok("Lingua::EN::BioLemmatizer")
	|| BAIL_OUT("can't run any tests without the module available");
}

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

our $SELF;

############################################################
# Test new() contructor
############################################################
{

    $SELF = Lingua::EN::BioLemmatizer->new();

    ok $SELF->isa("Lingua::EN::BioLemmatizer"), 
	"create Lingua::EN::BioLemmatizer object...";

    is 1, SvREFCNT($SELF), "ref count on object is just 1";

    # make sure all known methods invocable on real object
    for my $meth (@All_Methods) {
	can_ok($SELF, $meth);
    }

}


############################################################
# Test child_pid() object method (getter, not setter)
############################################################
{

    throws_ok { $SELF->child_pid($$) } 
	qr/readonly method called with arguments/
     => "catch attempt to use child_pid as setter";

     my $pid = $SELF->child_pid;
     ok looks_like_number($pid), "pid $pid looks like a number";
     ok kill(ZERO => $pid), "pid $pid is alive, and you own it";

}

############################################################
# Test into_biolemmer() object method (getter, not setter)
############################################################
{

    throws_ok { $SELF->into_biolemmer("bogus") } 
	qr/readonly method called with arguments/
     => "catch attempt to use into_biolemmer as setter";

    my $fh = $SELF->into_biolemmer;
    ok $fh, "invoke into_biolemmer as getter";
    ok openhandle($fh) => "got openhandle outta into_biolemmer";

}

############################################################
# Test from_biolemmer() object method (getter, not setter)
############################################################
{

    throws_ok { $SELF->from_biolemmer("bogus") } 
	qr/readonly method called with arguments/
     => "catch attempt to use from_biolemmer as setter";

    my $fh = $SELF->from_biolemmer;
    ok $fh, "invoke from_biolemmer as getter";
    ok openhandle($fh) => "got openhandle outta from_biolemmer";

}

############################################################
# Test lemma_cache() object method (getter, not setter)
############################################################
{

    throws_ok { $SELF->lemma_cache({ "mice" => "mouse" }) }
	qr/readonly method called with arguments/
     => "catch attempt to use lemma_cache as setter";

    my $href;

    lives_ok { $href = $SELF->lemma_cache } "invoke lemma_cache as getter";

    ok reftype($href) eq "HASH" 
	=> "lemma_cache returns hash ref";

}

############################################################
# Test java_path() class getter/setter or object getter only
############################################################
{

    throws_ok { $SELF->java_path("/foo/bar/java") }
	qr/readonly method called with arguments/
     => "catch attempt to use java_path as setter";

    my $java_path; 

    lives_ok { $java_path = $SELF->java_path } "invoke java_path as getter";

    ok length($java_path) => "lengthy string from java_path getter";

}

############################################################
# Test jar_path() class getter/setter or object getter only
############################################################
{

    throws_ok { $SELF->jar_path("/foo/bar/something.jar") }
	qr/readonly method called with arguments/
     => "catch attempt to use jar_path as setter";

    my $jar_path; 

    lives_ok { $jar_path = $SELF->jar_path } "invoke jar_path as getter";

    ok length($jar_path) => "lengthy string from jar_path getter";

}

############################################################
# Test java_args() class getter/setter or object getter only
############################################################
{

    throws_ok { $SELF->java_args(["bad stuff"]) }
	qr/readonly method called with arguments/
     => "catch attempt to use java_args as setter";

    my($aref, @args);
    lives_ok { $aref = $SELF->java_args } "invoke java_args as getter (SCALAR)";
    lives_ok { @args = $SELF->java_args } "invoke java_args as getter (LIST)";
    is_deeply $aref, \@args, "same java_args return in scalar as in list context";

}

############################################################
# Test jar_args() class getter/setter or object getter only
############################################################
{

    throws_ok { $SELF->jar_args(["really bad stuff"]) }
	qr/readonly method called with arguments/
     => "catch attempt to use jar_args as setter";

    my($aref, @args);
    lives_ok { $aref = $SELF->jar_args } "invoke jar_args as getter (SCALAR)";
    lives_ok { @args = $SELF->jar_args } "invoke jar_args as getter (LIST)";
    is_deeply $aref, \@args, "same jar_args return in scalar as in list context";

}

############################################################
# Test command_args() dual getter, not setter
############################################################
{

    throws_ok { $SELF->command_args(["you are hosed"]) }
	qr/unexpected args/
     => "catch attempt to use command_args as setter";

    my($cmd_string, @cmd_array);
    lives_ok { $cmd_string = $SELF->command_args } "invoke command_args as getter (SCALAR)";
    lives_ok { @cmd_array  = $SELF->command_args } "invoke command_args as getter (LIST)";

    is $cmd_string, "@cmd_array", "same command_args return in scalar as in list context";

}

############################################################
# Test get_biolemma() object method, not class method
############################################################
{

    # test just a few simple ones
    # see penn.t for exaustive testing

    my %lemmata = qw{

	mouse	    mice
	child       children
	run 	    ran
	write       written
	technical   technically
	woman	    women
	corpus	    corpora
	stigma	    stigmata
	lemma	    lemmata
	octopus	    octopodes
	ultimatum   ultimata
	drive	    driven
	dream	    dreamt
	fish	    fish

    };

    while (my($citation, $inflection) = each %lemmata) {
	like $SELF->get_biolemma($inflection), qr/\b\Q$citation\E\b/
	    => "lemma of $inflection is $citation";
    } 


}

############################################################
# Test _handle_request() notationally private method
############################################################
{

    ;;;
    # XXX: Should I even bother?  It's internal.

}

############################################################
# Test implicit destruction to make sure resources go away
# when object's implicit DESTROY method fires off
############################################################
{

    my $pid = $SELF->child_pid;

    # sending "signal zero" is a way to check
    # whether pid is alive&yours
    ok kill(ZERO => $pid), "predeath pid $pid is alive and you own it";

    # need to cache old descriptor number, *not* old filehandle, because
    # the handle would be ref counted and not go away, but the integer
    # is safe to remember
    my $fd_in  = fileno($SELF->from_biolemmer);
    ok defined($fd_in), "input handle has defined fileno";

    my $fd_out = fileno($SELF->into_biolemmer);
    ok defined($fd_in), "output handle has defined fileno";

    # Now deallocate object; this should get rid of all the resources
    # provided its refcount is at 1 cause we've made no pointer copies
    is 1, SvREFCNT($SELF), "ref count on doomed object is still just 1";
    undef $SELF;   # <--- now ref count goes to 0

    # NB: funky open mode "<&=" is how to do an fdopen() on a descriptor
    #     number in perl.  Must make sure those are invalid now with %!
    #     errno variable. %!{EBADF} is identical to (errno == EBADF)
    my $dupfh;
    ok !open($dupfh, "<&=", $fd_in), "test failed fdopen on $fd_in";
    ok $!{EBADF},  "check errno from bad open on in handle is EBADF";
    ok !defined fileno($dupfh), "check for undefined input fileno postdestruction";
    ok !open($dupfh, ">&=", $fd_out), "test failed fdopen on $fd_out";
    ok $!{EBADF},  "check errno from bad open on out handle is EBADF";
    ok !defined fileno($dupfh), "check for undefined output fileno postdestruction";

    unless(ok !kill(ZERO => $pid), "postdeath pid $pid dead or changed uid") {
	system("ps l$pid");
    }
} 

done_testing();
