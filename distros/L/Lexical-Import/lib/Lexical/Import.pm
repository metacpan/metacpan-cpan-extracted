=head1 NAME

Lexical::Import - clean imports from package-exporting modules

=head1 SYNOPSIS

	use Lexical::Import "Carp";

	use Lexical::Import qw(Time::HiRes time sleep);

	use Lexical::Import qw(Fcntl-1.01 :flock);

	use Lexical::Import (
		["Carp"],
		[qw(Time::HiRes time sleep)],
		[qw(Fcntl-1.01 :flock)],
	);

=head1 DESCRIPTION

This module allows functions and other items, from a separate
module, to be imported into the lexical namespace (as implemented by
L<Lexical::Var>), when the exporting module exports non-lexically to
a package in the traditional manner.  This is a translation layer,
to help code written in the new way to use modules written in the old way.

A lexically-imported item takes effect from the end of the definition
statement up to the end of the immediately enclosing block, except
where it is shadowed within a nested block.  This is the same lexical
scoping that the C<my>, C<our>, and C<state> keywords supply.  Within its
scope, any use of the single-part name of the item (e.g., "C<$foo>")
refers directly to that item, regardless of what is in any package.
Explicitly package-qualified names (e.g., "C<$main::foo>") still refer
to the package.  There is no conflict between a lexical name definition
and the same name in any package.

This mechanism only works on Perl 5.11.2 and later.  Prior to that,
it is impossible for lexical subroutine imports to work for bareword
subroutine calls.  (See L<Lexical::Var/BUGS> for details.)  Other kinds
of lexical importing are possible on earlier Perls, but because this is
such a critical kind of usage in most code, this module will ensure that
it works, for convenience.  If the limited lexical importing is desired
on earlier Perls, use L<Lexical::Var> directly.

=cut

package Lexical::Import;

{ use 5.011002; }
use warnings;
use strict;

use Carp qw(croak);
use Lexical::Var 0.006 ();
use Module::Runtime 0.011 qw($module_name_rx require_module);
use Params::Classify 0.000 qw(is_string is_ref);
use version 0.81 ();

our $VERSION = "0.002";

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 PACKAGE METHODS

These methods are meant to be invoked on the C<Lexical::Import> package.

=over

=item Lexical::Import->import(MODULE_NAME, ARGS ...)

I<MODULE_NAME> must be a Perl module name, in bareword syntax with C<::>
separators.  The named module is loaded, and its C<import> method is
called with the supplied I<ARGS>.  It is expected to insert some set of
functions and other items to the package from which its C<import> method
was called.  Whatever scalars, arrays, hashes, and subroutines it thus
exported are added to the lexical environment that is currently compiling.

The overall effect, when this is performed at compile time (usually via
C<use>), is that a C<use> is performed on the I<MODULE_NAME> and I<ARGS>,
with all of the module's package-based exporting being turned into
lexical exporting.  If the exporting module does some lexical exporting
of its own, that will still work correctly when done by this indirect
mechanism, but there is no point to the indirection if the exporting
module uses lexical exporting exclusively.

Optionally, I<MODULE_NAME> may be suffixed with a version number,
separated from the module name by a "C<->".  The version number must
conform to the "strict" syntax (see L<version::Internals>).  If this
is done, then after loading the module it will be checked that what was
loaded is at least the specified version.  For example, "C<Fcntl-1.01>"
requests the C<Fcntl> module, version 1.01 or later.  This check is
actually performed by calling the C<VERSION> method of the module, so the
module can redefine it to have effects other than version checking, which
some modules do even though it shows poor taste.  Any items exported by
C<VERSION> into the calling package will be picked up and added to the
lexical environment, just as if they had been exported by C<import>.

Optionally, I<MODULE_NAME> may be prefixed with a "C<->", in which
case the module's C<unimport> method is called instead of C<import>.
This effectively performs a C<no> instead of a C<use>.  This is meant
to handle the few modules which, in poor taste, switch the conventional
meanings of C<use> and C<no>.

=item Lexical::Import->import(IMPORT_LIST, ...)

There must be one or more I<IMPORT_LIST>, each of which is a reference
to an array containing a I<MODULE_NAME> and I<ARGS> as described for
the preceding form of C<import>.  Each such list is processed in turn
for importing.  This is a shorthand for where several invocations of
this module would otherwise be required.

=cut

sub Lexical::Import::__DELETE_STAGE::DESTROY {
	no strict "refs";
	delete $Lexical::Import::{$_[0]->{name}."::"};
}

my $next_stagenum = 0;

sub import {
	my $class = shift;
	croak "$class does no default importation" if @_ == 0;
	foreach my $arglist (is_ref($_[0], "ARRAY") ? @_ : (\@_)) {
		croak "non-array in $class multi-import list"
			unless is_ref($arglist, "ARRAY");
		croak "$class needs the name of a module to import from"
			unless is_string($arglist->[0]);
		my($no, $mname, $reqver) =
			($arglist->[0] =~
			 /\A(-)?($module_name_rx)(?:-($version::STRICT))?\z/o);
		croak "malformed module name `@{[$arglist->[0]]}'"
			unless defined $mname;
		require_module($mname);
		my $stagename = "__STAGE".($next_stagenum++);
		my $stagepkg = "Lexical::Import::".$stagename;
		my $cleanup_stage = bless({name=>$stagename},
					"Lexical::Import::__DELETE_STAGE");
		no strict "refs";
		%{$stagepkg."::"} = ();
		eval(qq{
			package $stagepkg;
			sub {
				my \$mname = shift;
				my \$reqver = shift;
				my \$import = shift;
				\$mname->VERSION(\$reqver) if defined \$reqver;
				\$mname->\$import(\@_);
			}
		})->(
			$mname, $reqver, $no ? "unimport" : "import",
			@{$arglist}[1..$#$arglist],
		);
		my @imports;
		foreach my $name (keys %{$stagepkg."::"}) {
			next unless $name =~ /\A[A-Z_a-z][0-9A-Z_a-z]*\z/;
			my $glob = \*{$stagepkg."::".$name};
			push @imports, "\$".$name, *{$glob}{SCALAR}
				if _glob_has_scalar($glob);
			push @imports, "\@".$name, *{$glob}{ARRAY}
				if defined *{$glob}{ARRAY};
			push @imports, "%".$name, *{$glob}{HASH}
				if defined *{$glob}{HASH};
			push @imports, "&".$name, *{$glob}{CODE}
				if defined *{$glob}{CODE};
		}
		Lexical::Var->import(@imports) if @imports;
	}
}

=item Lexical::Import->unimport

Unimportation is not supported by this module, so this method just
C<die>s.

=cut

sub unimport { croak "$_[0] does not support unimportation" }

=back

=head1 BUGS

Only scalars, arrays, hashes, and subroutines can be translated from the
package namespace to the lexical namespace.  If a module exports more
exotic items, such as bareword I/O handles or formats, they will be lost.

If an exporting module does anything more complex than just inserting
items into the calling package, this is liable to fail.  For example, if
it records the name of the calling package for some functional purpose
then this won't work as intended: it will get the name of a temporary
package that doesn't exist once the importing is complete.

If an exporting module tries to read a variable in the calling package,
this will fail in two ways.  Firstly, because it sees a temporary
package, it won't pick up any variable from the real caller.  Secondly,
it is liable to bring the variable into existence (with an empty value),
which looks like it exported the variable, so the empty variable will
be lexically imported by the real caller.

Subroutine calls, to lexically-imported subroutines, that have neither
sigil nor parentheses (around the argument list) are subject to an
ambiguity with indirect object syntax.  If the first argument expression
begins with a bareword or a scalar variable reference then the Perl
parser is liable to interpret the call as an indirect method call.
Normally this syntax would be interpreted as a subroutine call if the
subroutine exists, but the parser doesn't look at lexically-defined
subroutines for this purpose.  The call interpretation can be forced by
prefixing the first argument expression with a C<+>, or by wrapping the
whole argument list in parentheses.

If this package's C<import> method is called from inside a string
C<eval> inside a C<BEGIN> block, it does not have proper access to the
compiling environment, and will complain that it is being invoked outside
compilation.  Calling from the body of a C<require>d or C<do>ed file
causes the same problem.  Other kinds of indirection within a C<BEGIN>
block, such as calling via a normal function, do not cause this problem.
Ultimately this is a problem with the Perl core, and may change in a
future version.

=head1 SEE ALSO

L<Lexical::Var>,
L<Sub::Import>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2010, 2011 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
