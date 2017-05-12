#!env perl -w

#
# more tests for exception handling.
#

use strict;
use warnings;

use Test::More
	tests => 33;

BEGIN { use_ok 'Glib'; }

package MyClass;

use Glib::Object::Subclass
   Glib::Object::,
   signals    =>
      {
          first => {},
          second => {},
      },
   ;

sub first  { $_[0]->signal_emit ('first'); }
sub second { $_[0]->signal_emit ('second'); }

############
package main;

# keep stderr quiet, redirect it to stdout...
$SIG{__WARN__} = sub { print $_[0]; };

my $tag = Glib->install_exception_handler (sub {
		$_[0] =~ s/\n/\\n/g;
		ok (1, "trapped exception '$_[0]'");
		# this should be ignored, too, and should NOT create an
		# infinite loop.
		die "oh crap, another exception!\nthis one has multiple lines!\nappend something";
		1 });

ok( $tag, 'installed exception handler' );

ok( Glib->install_exception_handler (sub {
		if ($_[0] =~ /ouch/) {
			ok (1, 'saw ouch, uninstalling');
			return 0;
		} else {
			ok (0, 'additional handler still installed');
			return 1;
		}
		}),
    'installed an additional handler' );

{
   my $my = new MyClass;
   $my->signal_connect (first => sub { 
			ok (1, 'in first handler, calling second');
			$_[0]->second;
			ok (1, "handler may die, but we shouldn't");
		});
   $my->signal_connect (second => sub {
			ok (!$@, "signal handlers are eval'd so \$@ should always be empty");
			ok (1, "in second handler, dying with 'ouch\\n'");
			die "ouch\n";
			ok (0, "should NEVER get here");
		});

   $_ = $my;
   ok (1, 'calling second');
   $my->second;
   ok (1, "handler may die, but we shouldn't be affected");
   is ($_, $my, 'we should not clobber $_');
   $_ = undef;

   # expect identical behavior in eval context 
   eval {
   	ok (1, 'calling second in eval');
	$my->second;
	ok (1, "handler may die, but we shouldn't be affected");
   };
   is ($@, "", "exception should be cleared already");

   # super double gonzo...
   ok (1, "calling first");
   $my->first;
   ok (1, "after eval");
   print " # calling first out of eval - should not result in crash\n";
   $my->first;

   # more exception trapping behavior tests
   $@ = undef;
   $my->second;
   is ($@, undef, 'exception value should remain unchanged');
   $@ = 'neener';
   $my->first;
   is ($@, 'neener', 'exception value should remain unchanged');
}


__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
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
