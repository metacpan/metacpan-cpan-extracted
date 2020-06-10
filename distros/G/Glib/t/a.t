#!/usr/bin/env perl

#
# message logging.
#

use strict;
use warnings;
use Data::Dumper;
use Test::More;
use Glib;
use Config;

if ($Config{archname} =~ m/^(x86_64|mipsel|mips|alpha)/
    and not Glib->CHECK_VERSION (2,2,4)) {
	# there is a bug in glib which makes g_log print messages twice
	# on 64-bit x86 platforms.  yosh has fixed this on the 2.2.x branch
	# and in 2.4.0 (actually 2.3.2).
	plan skip_all => "g_log doubles messages by accident on 64-bit platforms";
} else {
	plan tests => 32;
}

package Foo;

use Glib::Object::Subclass
    'Glib::Object';

package main;

$SIG{__WARN__} = sub { chomp (my $msg = $_[0]); ok(1, "in __WARN__: $msg"); };
#$SIG{__DIE__} = sub { ok(1, 'in __DIE__'); };

Glib->message (undef, 'whee message');
Glib->critical (undef, 'whee critical');
Glib->warning (undef, 'whee warning');

{
	local %ENV = %ENV;

	# These should not call the __WARN__ handler above.
	$ENV{G_MESSAGES_DEBUG} = '';
	Glib->info (undef, 'whee info');
	Glib->debug (undef, 'whee debug');

	# Now they sould.
	$ENV{G_MESSAGES_DEBUG} = 'all';
	Glib->info (undef, 'whee info');
	Glib->debug (undef, 'whee debug');
}

my $id =
Glib::Log->set_handler (__PACKAGE__,
                        [qw/ error critical warning message info debug /],
			sub {
				ok(1, "in custom handler $_[1][0]");
			});

Glib->message (__PACKAGE__, 'whee message');
Glib->critical (__PACKAGE__, 'whee critical');
Glib->warning (__PACKAGE__, 'whee warning');
Glib->log (__PACKAGE__, qw/ warning /, 'whee log warning');

Glib::Log->remove_handler (__PACKAGE__, $id);

SKIP: {
	# See <http://bugzilla.gnome.org/show_bug.cgi?id=577137>.
	skip 'using multiple log levels breaks g_log on some platforms', 2
		if (!Glib->CHECK_VERSION(2, 20, 1) &&
		    $Config{archname} =~ /powerpc|amd64|s390/);
	my $id = Glib::Log->set_handler (undef,
		[qw/ error critical warning message info debug /],
		sub {
			ok(1, "in custom handler $_[1][0]");
		});
	Glib->log (undef, [qw/ info debug /], 'whee log warning');
	Glib::Log->remove_handler (undef, $id);
}

# i would expect this to call croak, but it actually just aborts.  :-(
#eval { Glib->error (__PACKAGE__, 'error'); };

Glib::Log::default_handler ('Test-Domain', ['info'], 'ignore this message');
Glib::Log::default_handler ('Test-Domain', ['info'],
                            'another message to ignore', 'userdata');

SKIP: {
  skip "new 2.6 stuff", 18
    unless Glib->CHECK_VERSION (2,6,0);
  Glib->log ('An-Unknown-Domain', ['info'], 'this is a test message');

  is (Glib::Log->set_default_handler(undef),
      \&Glib::Log::default_handler,
      'default log handler: install undef, prev default');
  Glib->log ('An-Unknown-Domain', ['info'], 'this is a test message');

  is (Glib::Log->set_default_handler(\&Glib::Log::default_handler),
      \&Glib::Log::default_handler,
      'default log handler: install default, prev default');
  Glib->log ('An-Unknown-Domain', ['info'], 'this is another test message');

  # anon subs like $sub1 and $sub2 must refer to something like $x in the
  # environment or they're not gc-ed immediately
  my $x = 123;
  my $sub1 = sub {
    my @args = @_;
    is (scalar @args, 3, 'sub1 arg count');
    is ($args[0], 'An-Unknown-Domain', 'sub1 domain');
    isa_ok ($args[1], 'Glib::LogLevelFlags', 'sub1 flags type');
    ok ($args[1] == ['info'], 'sub1 flags value');
    is ($args[2], 'a message', 'sub1 message');
    return $x
  };
  is (Glib::Log->set_default_handler($sub1),
      \&Glib::Log::default_handler,
      'default log handler: install sub1, prev default');
  Glib->log ('An-Unknown-Domain', ['info'], 'a message');

  my $sub2 = sub {
    my @args = @_;
    is (scalar @args, 4, 'sub2 arg count');
    is ($args[0], 'Another-Unknown-Domain', 'sub2 domain');
    isa_ok ($args[1], 'Glib::LogLevelFlags', 'sub2 flags type');
    ok ($args[1] == ['warning'], 'sub2 flags value');
    is ($args[2], 'a message', 'sub2 message');
    is ($args[3], 'some userdata', 'sub2 userdata');
    return $x
  };
  is (Glib::Log->set_default_handler($sub2,'some userdata'), $sub1,
      'default log handler: install sub2, prev sub1');
  require Scalar::Util;
  Scalar::Util::weaken ($sub1);
  is ($sub1, undef,
      'sub1 garbage collected by weakening');
  Glib->log ('Another-Unknown-Domain', ['warning'], 'a message');

  is (Glib::Log->set_default_handler(undef), $sub2,
      'default log handler: install undef, prev sub2');
  Glib->log ('Another-Unknown-Domain', ['info'], 'this is a test message');

  is (Glib::Log->set_default_handler(undef),
      \&Glib::Log::default_handler,
      'default log handler: install undef, prev default');
  Glib->log ('Another-Unknown-Domain', ['info'], 'this is yet another a test message');

  # test that a custom log handler can safely call the default log handler
  Glib::Log->set_default_handler(sub { Glib::Log::default_handler (@_); });
  Glib->log ('Another-Unknown-Domain', ['info'], 'custom to default test');
  Glib::Log->set_default_handler(undef);
}


# when you try to connect to a non-existant signal, you get a CRITICAL
# log message...
my $object = Foo->new;
{
ok(1, 'attempting to connect a non-existant signal');
local $SIG{__WARN__} = sub { ok( $_[0] =~ /nonexistant/, 'should warn' ); };
$object->signal_connect (nonexistant => sub { ok(0, "shouldn't get here") });
delete $SIG{__WARN__};
}

## try that again with a fatal mask
#Glib::Log->set_always_fatal (['critical', 'fatal-mask']);
#{
#local $SIG{__DIE__} = sub { ok(1, 'should die'); };
#eval {
#$object->signal_connect (nonexistant => sub { ok(0, "shouldn't get here") });
#};
#print "$@\n";
#}

# Check that messages with % chars make it through unaltered and don't cause
# crashes
{
	my $id = Glib::Log->set_handler (
		__PACKAGE__,
		qw/debug/,
		sub { is($_[2], '%s %d %s', 'a message with % chars'); });

	Glib->log (__PACKAGE__, qw/debug/, '%s %d %s');

	Glib::Log->remove_handler (__PACKAGE__, $id);
}

Glib::Log->set_fatal_mask (__PACKAGE__, [qw/ warning message /]);
Glib::Log->set_always_fatal ([qw/ info debug /]);

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
