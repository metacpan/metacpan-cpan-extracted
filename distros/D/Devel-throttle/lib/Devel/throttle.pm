#! /bin/false

# This file is part of Devel-throttle.
# Copyright (C) 2009 Guido Flohr <guido@imperia.net>, 
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Devel::throttle;

use strict;

use vars qw ($VERSION @args);
$VERSION = '0.01';

sub import {
	my ($self, $throttle, @code) = @_;

	$DB::throttle = $throttle;

	if (@code) {
		my $code = shift @code;

		if (ref $code && 'CODE' eq ref $code) {
			$DB::throttlefunc = $code;
		}

		if (ref $code && 'CODE' eq ref $code) {
			@args = @code;
		} else {
			@args = ();
			$DB::throttlefunc = sub { eval $code; warn $@ if $@ };
		}
	} else {
		@args = ();
	}
}

sub throttlefunc {
	my $timeout = shift || 0;

	$timeout *= 1;

	return unless $timeout > 0;

	select undef, undef, undef, $timeout
		if $timeout;
}

package DB;

$DB::throttlefunc = \&Devel::throttle::throttlefunc;

sub DB {
	my @args = @Devel::throttle::args ?
		@Devel::throttle::args : $DB::throttle; 

	$DB::throttlefunc->(@args)
		if $DB::throttlefunc;
}

1;

__END__

=head1 NAME

Devel::throttle - Slow down execution of Perl code

=head1 SYNOPSIS

In order to slow down a script, invoke Perl like this:

	perl -d:"throttle(0.2)" myscript.pl

Or using the shebang line:

	#! /usr/bin/perl -d:throttle(0.2)

If you want to slow down only certain parts of your software, do not
specify a sleep time:

	perl -d:throttle myscript.pl

Or:

	#! /usr/bin/perl -d:throttle

If you want to use your own throttling function:

	#! /usr/bin/perl -d:throttle(0.2, \&myfunc)

With arguments:

	#! /usr/bin/perl -d:throttle(undef, \&myfunc, 'foo', 'bar')
	
Or enter code directly:

	#! /usr/bin/perl -d:throttle(undef, 'sleep 1; print "continue\n"')

=head1 DESCRIPTION

It is sometimes desirable to slow down the execution of Perl code.  With
the help of this module, you can let your Perl scripts (or parts of it)
run in slow-motion.

This is achieved by pausing the script after each instruction for a
certain amount of time.  You can also call your own custom sleep
function, if you are not happy with the default.

=head1 CONFIGURATION

You can configure the behavior of the module at invocation time
and/or any time later during your script.

=head2 Invocation options

You can specify all configuration options, when you invoke your
script using either command-line options or in the she-bang line.
When using command-line options, you have to make sure to properly
escape characters special to your shell.

The following usages are currently supported:

=over 4
    
=item B<-d:throttle>

This will just load the framework, but - except for a minimal overhead -
not slow down your script.

=item B<-d:throttle(SLEEPTIME)>

This will slow down your script, by sleeping for B<SLEEPTIME> seconds
after each instruction.  B<SLEEPTIME> can be a fractional value.

=item B<-d:throttle(SLEEPTIME, CODEREF)>

If you specify a code reference as the optional second argument, this
code will be called instead of the default throttling function.  The
code will be invoked with B<SLEEPTIME> as its single argument.

=item B<-d:throttle(SLEEPTIME, CODEREF, ARGUMENT, ...)>

If you specify more arguments, the B<CODEREF> will be called with these
arguments.  You can access B<SLEEPTIME> via the variable B<$DB::throttle>.

=item B<-d:throttle(SLEEPTIME, STRING)>

If the second argument is present and not a code reference, it is 
interpreted as Perl code that is executed instead of the default
throttling function.  You can access B<SLEEPTIME> via the variable
B<$DB::throttle>.

=back

=head2 Run-time configuration

You can change the behavior of the module at any time during execution
of your script.  This is useful, if you only want to slow down certain
portions of your code.

=over 4

=item B<$DB::throttle>

The default throttling function will sleep B<$DB::throttle> seconds
after each Perl instruction.  Setting the variable to zero or
a non-number, will mostly disable the slow-down.  Higher values
will slow down execution.

=item B<$DB::throttlefunc>

This variable holds a reference to the code that is executed after
each Perl instruction.  It is called with the arguments
B<@Devel::throttle::args> if present, or B<$DB::throttle> otherwise.

The default function looks roughly like this:

    sub { select undef, undef, undef, shift }

In fact, the function is a little bit more complicated, since it does
a sanity check on its argument.

=item B<@Devel::throttle::args>

If this list is not empty, the throttling function will be called
with these arguments instead of the default argument B<$DB::throttle>.

=back

Since B<Devel::throttle> is a custom debugger, you can also influence
its behavior by the standard debugging API (see B<DB(3pm)>).

=head1 FREQUENTLY ASKED QUESTIONS (FAQ)

=over 4

=item B<Is there anything useful you can do with this module?>

If you find a useful application, drop me a line.  I personally
wrote the module in order to debug concurrency problems of a
CGI application.  The idea goes like this: Fire many parallel
http requests, and measure the average execution time.  Now
repeat the test, this time slowing down one single request
with B<Devel::throttle>.  If this overproportionally slows down
the other requests, it is quite likely that you have a mutual
locking problem.

You can then later narrow the search for the culprit in your code
by only slowing down a portion of the script.

=item B<Why is there a start-up delay of Devel::throttle?>

There is none.  Probably you tested this module with a little loop
printing out some stuff, and you forgot that a couple of instructions
(including compilation) have already been executed, before the
loop is entered.

=item B<Why isn't there a Devel::accel module that does the opposite
of Devel::throttle?>

Well, in fact, I have such a module.  I just did not bother to
publish it.

=back

=head1 BUGS

You can report bugs via the bug-tracking system at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Devel-throttle>.

=head1 AUTHOR

Copyright (C) 2009, Guido Flohr E<lt>guido@imperia.netE<gt>, all
rights reserved.

This free software is contributed to the Perl community by Imperia
(L<http://www.imperia.net/>).  You can re-distribute it or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

DB(3pm), perl(1)
