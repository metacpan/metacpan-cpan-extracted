#!perl  -T

# In here I'm throwing tests that don't quite fit anywhere else. All the
# other test files deal with an ECMAScript section (test written in JS) or
# the Perl interface of a module. Some tests written in Perl for JS run-
# time things have been thrown in here, for instance.

BEGIN { require './t/test.pl' }

use Test::More tests => 10;
use strict;
use utf8;

use JE;
our $j = JE->new;

#--------------------------------------------------------------------#
# Test 1: Attempt to free unreferenced scalar in perl 5.8.x
# fixed via a workaround for perl bug #24254

{
	my $x;
	local $SIG{__WARN__} = sub { $x = $_[0] };
	$j->eval('a(I_hope_thiS_var_doesnt_exist+b)');
	is $x, undef, '"Attempt to free unreferenced scalar" avoided';
}

#--------------------------------------------------------------------#
# Tests 2-3: 0.029 broke this and 0.030 fixed it: bind_class-style error
#                                              objects thrown from Perl

{
	package HTML::DOM::Exception;
	sub new { bless[] }
}
$j->new_function(die => sub { die new HTML::DOM::Exception });
$j->bind_class(name => "HTML::DOM::Exception");
is $j->eval('
	try{ die() }
	catch(e) { String(e) }
'), '[object HTML::DOM::Exception]',
	'bind_class-style error objects with try'
	or diag $@;
$j->eval(' die() ');
is $@, '[object HTML::DOM::Exception]',
	'bind_class-style error objects without try';

#--------------------------------------------------------------------#
# Tests 4-9: Escape functions with the global ‘prop’ overridden
#            (fixed in 0.032)

{
 package subclass;
 our @ISA = 'JE';
 sub prop { SUPER::prop{shift}@_ }
 my $j = new subclass;
 ::ok eval {$j->{$_}();1}, "$_ with global prop overridden" or ::diag $@
  for qw; escape unescape encodeURI decodeURI encodeURIComponent
          decodeURIComponent;
}

#--------------------------------------------------------------------#
# Test 10: Throwing new Errors while *@ is localised
# This is actually a perl bug, which we now work around in version 0.055.

{
 local *@;
 new JE  ->eval('throw new Error');
} # <-- It used to crash when exiting this scope.
ok(1, "throw new Error works when *@ is localised");
