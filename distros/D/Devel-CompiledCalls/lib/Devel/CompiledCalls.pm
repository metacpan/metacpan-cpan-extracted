package Devel::CompiledCalls;

use 5.008;

use strict;
use warnings;

use B::Compiling qw( PL_compiling );
use B::CallChecker qw(
	cv_get_call_checker
	cv_set_call_checker
);
use Sub::Identify qw(sub_fullname);

our $VERSION = "2.00";

=head1 NAME

Devel::CompiledCalls - show where calls to a named subroutine are compiled

=head1 SYNOPSIS

  # from the shell
  shell$ perl -c -MDevel::CompiledCalls=Data::Dumper::Dumper myscript.pl
  Data::Dumper::Dumper call at myscript.pl line 4.
  Data::Dumper::Dumper call at myscript.pl line 5.
  myscript.pl syntax OK

  # from within a Perl script
  use Devel::CompiledCalls qw(Data::Dumper::Dumper);

  # from a perl script with custom callback
  use Devel::CompiledCalls;
  BEGIN {
    Devel::CompiledCalls::attach_callback("Data::Dumper::Dumper", sub {
      my ($subname, $filename, $line) = @_;
      say "$subname at $line of $filename";
    });
  };

=head1 DESCRIPTION

This module allows you to put hooks into Perl so that whenever a call to
a named subroutine has been compiled a callback is fired.  The easiest syntax
(import Devel::CompiledCalls and pass the name of the subroutine) simply
logs the line and filename of the call to STDERR.

Note that since we are hooking the process of compiling not the execution of
the subroutines (technically, we're hooking the process of subroutine parameter
checking, but the effects are the same) this module will find calls that aren't
normally captured by modules like Hook::LexWrap because they're not normally
executed during the program's execution (e.g. a call in exception handling code
that only occurs once every four years.)

=head2 Use with import

The simpliest way to to hook is to pass the name of the function in the
import list:

    use Devel::CompiledCalls qw(foo);
    ...

Or from the command line:

    perl -MDevel::CompiledCalls=foo -e '...'

In both these cases the standard callback - which simply prints to STDERR - will
be installed.

=head2 Custom callbacks

Custom callbacks can be installed with the C<attach_callback> subroutine.
This routine is not exported and must be called with a fully qualified
function call.

=over

=item attach_callback( $subroutine_ref, $callback )

=item attach_callback( $subroutine_name, $callback )

The callback will be called whenever a call to the subroutine is compiled.  The
subroutine can either be passed by reference, by fully qualified name (including
the package,) or by just the subroutine name (in which case it will be assumed
to be in the same package as C<attach_callback> is called from.)

The callback will be executed with three parameters: The name of the subroutine,
the filename of the source file, and the the line of the sourcefile that
contains the subroutine.

=back

=cut

sub import {
	shift;
	attach_callback($_, sub {
		my ($name, $file, $line,$stash) = @_;
		local $\ = undef;  # locally reset back to default just in case
		print {*STDERR} "$name call at $file line $line.\n";
	}) foreach @_;
	return;
}

sub attach_callback {
	my $name = shift;
	my $callback = shift;

	# check for an unqualifed subroutine name.  If we have one
	# then we need to give it our *caller's* package (or, potentially
	# our caller's caller package
	my $fully_qualified_name =
		ref $name eq "CODE" ? $name :
		$name =~ /::/x      ? $name  : do {
			my $caller_package;
			my $level = 1;
			do { ($caller_package) = caller($level++) }
				while ($caller_package eq __PACKAGE__);
			$caller_package.'::'.$name;
		};
	$name = sub_fullname($name) if ref($name) eq "CODE";

	# get the sub (this will spring into existence with autovivication
	# if needed)
	my $uboat = do { no strict 'subs'; \&{$fully_qualified_name} };

	# work out what original check would have been made
	my ($original_check, $data) = cv_get_call_checker($uboat);

	# install our own checker that doesn't actually do any checking
	# but instead simply calls the callback
	cv_set_call_checker($uboat, sub {

		my $file = PL_compiling->file;
		my $line = PL_compiling->line;
		$callback->($name, $file, $line);

		# return the results of making the normal check
		return $original_check->(@_);
	}, $data);
	return;
}

=head1 BUGS

This module can't find calls that aren't compiled until the point they are
actually compiled.  For example this code:

   use Devel::CompiledCalls qw(foo);
   sub foo  { ... }
   sub fred { eval "foo('bar')" }

Won't print out until C<fred> is executed, since the call C<foo> is not
compiled until that point.  A similar problem happens with modules that are
loaded at runtime on demand;  Until the module is loaded the code is not
compiled and nothing is printed until such compilation happens.

Also, this module can't find calls that are constructed in any way other
than standard function calling.  For example accessing the
symbolic name of the function directly.  This won't print anything:

   use Devel::CompiledCalls qw(foo);
   sub foo  { ... }
   my $uboat = \&{"foo"};
   $uboat->();

As no subroutine call is actually compiled.  Similarly this won't print
anything either:

   use Devel::CompiledCalls qw(foo);
   sub foo  { ... }
   &foo;
   &foo("whatever");

Because the use of the C<&> sigil disables prototype checking which is
what we're hooking to record the call.

Using this module has the effect of making the subroutine we are hooking
"exist".  i.e.

   use Devel::CompiledCalls qw(foo);
   say "YES" if exists &foo;

Prints C<YES> out even before we define the subroutine foo anywhere.

Bugs (and requests for new features) can be reported though the CPAN
RT system:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-CompiledCalls>

Alternatively, you can simply fork this project on github and
send me pull requests.  Please see L<http://github.com/2shortplanks/Devel-CompiledCalls>

=head1 AUTHOR

Written by Mark Fowler B<mark@twoshortplanks.com>.

Copyright Mark Fowler 2012.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Hook::LexWrap> allows you to hook subroutines whenever they
are called.

L<B::Compiling> and L<B::CallChecker> were used in the construction of this
module, but I don't expose any user-accessible parts.

=cut

1;