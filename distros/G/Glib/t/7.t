#!/usr/bin/perl

use strict;
use warnings;

=comment

test some GSignal stuff - marshaling, exception trapping, order of operations.

based on the Glib::Object::Subclass, since it already worked, but not
in that test because it would confound too many issues.

we do not use Test::More or even Test::Simple because we need to test
order of execution...  the ok() funcs from those modules assume you
are doing all your tests in order, but our stuff will jump around.


my apologies for the extreme density and ugliness of this code.

=cut

use Test::More import => ['diag'];

print "1..36\n";

sub ok($$;$) {
    my($test, $num, $name) = @_;

    my $out = $test ? "ok" : "not ok";
    $out .= " $num" if $num;
    $out .= " - $name" if defined $name;

    print "$out\n";

    return $test;
}

sub pass($;$) {
    my($num, $name) = @_;
    return ok(1, $num, $name);
}

sub fail(;$) {
    my($name) = @_;
    return ok(0, 0, $name);
}


use Glib;

pass(1, 'Glib compiled');

package MyClass;

use Glib::Object::Subclass
   Glib::Object::,
   signals    =>
      {
          # a simple void-void signal
          something_changed => {
             class_closure => undef, # disable the class closure
             flags         => [qw/run-last action/],
             return_type   => undef,
             param_types   => [],
          },
          # test the marshaling of parameters
          test_marshaler => {
             flags       => 'run-last',
             param_types => [qw/Glib::String Glib::Boolean Glib::Uint Glib::Object/],
          },
          # one that returns a value
          returner => {
             flags       => 'run-last',
             return_type => 'Glib::Double',
             # using the default accumulator, which just returns the last
             # value
          },
          # more complicated/sophisticated value returner
          list_returner => {
             class_closure => sub {
                       ::pass(32, "hello from the class closure");
                       -1
             },
             flags         => 'run-last',
             return_type   => 'Glib::Scalar',
             accumulator   => sub {
                 my ($ihint, $return_accu, $handler_return) = @_;
                 # let's turn the return_accu into a list of all the handlers'
                 # return values.  this is weird, but the sort of thing you
                 # might actually want to do.
                 print "# in accumulator, got $handler_return, previously "
		      . (defined ($return_accu) ? $return_accu : 'undef')
		      . "\n";
                 if ('ARRAY' eq ref $return_accu) {
                        push @{$return_accu}, $handler_return;
                 } else {
                        $return_accu = [$handler_return];
                 }
                 # we must return two values --- a boolean that says whether
                 # the signal keeps emitting, and the accumulated return value.
                 # we'll stop emitting if the handler returns the magic 
                 # value 42.
                 ($handler_return != 42, $return_accu)
	     },
	  },
      },
   ;

sub do_test_marshaler {
	print "# \$@ $@\n";
	print "# do_test_marshaller: @_\n";
	return 2.718;
}

sub do_emit {
	my $name = shift;
	print "\n\n".("="x79)."\n";
	print "emitting: $name"
	   . (__PACKAGE__->can ("do_$name") ? " (closure exists)" : "")
	   . "\n";
	my $ret = shift->signal_emit ($name, @_);
	#use Data::Dumper;
	#print Dumper( $ret );
	print "\n".("-"x79)."\n";
	return $ret;
}

sub do_returner {
	::pass(24);
	-1.5;
}

sub something_changed { do_emit 'something_changed', @_ }
sub test_marshaler    { do_emit 'test_marshaler', @_ }
sub list_returner     { do_emit 'list_returner', @_ }
sub returner          { do_emit 'returner', @_ }

#############
package main;

my $a = 0;
my $b = 0;

sub func_a {
        ok(0==$a++, 4, "func_a");
}
sub func_b {
	if (0==$b++) {
		pass(5, "func_b");
		$_[0]->signal_handlers_disconnect_by_func (\&func_a);
	} else {
	        pass(7, "func_b again");
	}

	$_[0]->signal_stop_emission_by_name("something_changed");
}

{
   my $my = new MyClass;
   pass(2, "instantiated MyClass");
   $my->signal_connect (something_changed => \&func_a);
   my $id_b = $my->signal_connect (something_changed => \&func_b);
   pass(3, "connected handlers");

   $my->something_changed;
   pass(6);
   $my->something_changed;
   pass(8);

   $my->signal_handler_block ($id_b);
   $my->signal_handler_unblock ($id_b);
   ok($my->signal_handler_is_connected ($id_b), 9);

   $my->signal_handler_disconnect ($id_b);
   $my->something_changed;

   # attempting to marshal the wrong number of params should croak.
   # this is part of the emission process going wrong, not a handler,
   # so it's a bug in the calling code, and thus we shouldn't eat it.
   eval { $my->test_marshaler (); };
   ok( $@ =~ m/Incorrect number/, 10, "signal_emit barfs on bad input" );

   $my->test_marshaler (qw/foo bar 15/, $my);
   pass(11);
   my $id = $my->signal_connect (test_marshaler => sub {
	   ok( $_[0] == $my   &&
	       $_[1] eq 'foo' &&
	       $_[2]          && # string bar is true
	       $_[3] == 15    && # expect an int
	       $_[4] == $my   && # object passes unmolested
	       $_[5][1] eq 'two' # user-data is an array ref
               ,
	       13,
               "marshalling"
           );
	   return 77.1;
   	}, [qw/one two/, 3.1415]);
   ok($id, 12);
   $my->test_marshaler (qw/foo bar/, 15, $my);
   pass(14);

   $my->signal_handler_disconnect ($id);

   # here's a signal handler that has an exception.
   # we should be able to emit the signal all we like without catching
   # exceptions here, because we don't care what other people may have
   # connected to the signal.  the signal's exception can be caught with
   # an installed exception handler.
   $id = $my->signal_connect (test_marshaler => sub {
                              # signal handlers are always eval'd, so
                              # $@ should be empty.
                              warn "internal problem: \$@ is not empty in "
                                 . "signal handler!!!" if $@;
                              die "ouch"
                              });

   my $tag;
   $tag = Glib->install_exception_handler (sub {
                ok( $tag, 16, "exception_handler" );
	   	0  # returning FALSE uninstalls
	   }, [qw/foo bar/, 0]);
   ok($tag, 15, "installed exception handler");

   # the exception in the signal handler should not affect the value of
   # $@ at this code layer.
   $@ = 'neener neener neener';
   print "# before invocation: \$@ $@\n";
   $my->test_marshaler (qw/foo bar/, 4154, $my);
   print "# after invocation: \$@ $@\n";
   pass(17, "still alive after an exception in a callback");
   ok($@ eq 'neener neener neener', 18, "$@ is preserved across signals") ||
        diag "# expected 'neener neener neener'\n",
	     "   # got '$@'";
   $tag = 0;

   # that was a single-shot -- the exception handler shouldn't run again.
   {
   local $SIG{__WARN__} = sub {
	   if ($_[0] =~ m/unhandled/m) {
	   	pass(20, "unhandled exception just warns");
	   } elsif ($_[0] =~ m/isn't numeric/m) {
	   	pass(19, "string value isn't numeric");
	   } else {
		fail("got something unexpected in __WARN__: $_[0]\n");
	   }
	};
   $my->test_marshaler (qw/foo bar baz/, $my);
   pass(21);
   }

   use Data::Dumper;
   $my->signal_connect (returner => sub { pass(23); 0.5 });
   # the class closure should be called in between these two
   $my->signal_connect_after (returner => sub { pass(25); 42.0 });
   pass(22);
   my $ret = $my->returner;
   # we should have the return value from the last handler
   ok( $ret == 42.0, 26 ) || diag("expected 42.0, got $ret");

   # now with our special accumulator
   $my->signal_connect (list_returner => sub { pass(28); 10 });
   $my->signal_connect (list_returner => sub { pass(29); '15' });
   $my->signal_connect (list_returner => sub { pass(30); [20] });
   $my->signal_connect (list_returner => sub { pass(31); {thing => 25} });
   # class closure should before the "connect_after" ones,
   # and this one will stop everything by returning the magic value.
   $my->signal_connect_after (list_returner => sub { pass(33, "stopper"); 42 });
   # if this one is called, the accumulator isn't working right
   $my->signal_connect_after (list_returner => sub { fail("shouldn't get here"); 0 });
   pass(27);
   print Dumper( $my->list_returner );


   # Check that a signal_connect() of a non-existant signal name doesn't
   # leak the subr passed to it, ie. doesn't keep it alive forever.
   #
   # Note $subr has to use $x or similar in its containing environment to be
   # a closure.  If not then it's treated as part of the mainline code and
   # won't be gc'ed immediately -- or something like that.
   {
     my $x = 123;
     my $subr = sub { return $x };

     # handler to suppress the warning message from nosuchsignal
     my $logid = Glib::Log->set_handler ('GLib-GObject', ['warning'], sub { });
     my $sigid = $my->signal_connect ('nosuchsignal' => $subr);
     Glib::Log->remove_handler ('GLib-GObject', $logid);

     ok(! $sigid, 34, "'nosuchsignal' not connected");
     require Scalar::Util;
     Scalar::Util::weaken ($subr);
     ok(! defined $subr, 35, "subr gc'ed after bad signal name");
   }
}

pass(36);




__END__

Copyright (C) 2003, 2009 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
