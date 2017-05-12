#!/usr/bin/perl

package Devel::ArgNames;

use strict;
use warnings;

our $VERSION = "0.03";

use base qw(Exporter);

our @EXPORT_OK = our @EXPORT = qw(arg_names);

use PadWalker qw(peek_my peek_our);

sub arg_names (;$) {
	my $level = shift || 2;
	{ package DB; () = caller($level - 1) }
	@{{ reverse %{peek_my($level)}, %{peek_our($level)} }}{\(@DB::args)};
}

__PACKAGE__

__END__

=pod

=head1 NAME

Devel::ArgNames - Figure out the names of variables passed into subroutines.

=head1 SYNOPSIS

	use Devel::ArgNames;

	sub foo {
		warn "foo() called with arguments: "
			. join(", ", map { defined() ? $_ : "<unknown>" } arg_names(@_) );
	}

	foo($bar, $gorch, $blah[4]);	

=head1 DESCRIPTION

When print-debugging code, you will often ind yourself going:

	print "\$foo is $foo, \$bar is $bar"

With this module, you can write a reusable subroutine easily:

	sub my_print_vars {
		my %vars;

		@vars{arg_names()} = @_;

		foreach my $var ( keys %vars ) {
			warn "$var is $vars{$var}\n";
		}
	}

	my_print_vars($foo, $bar);

This module doesn't provide dumping facilities because there are too many to
choose from. This is a DIY kit ;-)

=head1 EXPORTS

=over 4

=item arg_names [ $level ]

This function will return the names associated with the variables found on
C<@_>, at the level $level. If C<$level> is not provided C<arg_names>'s
caller's caller will be used (C<$level == 2> in that case).

=back

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/Devel-ArgNames/>, and use C<darcs send> to
commit changes.

=head1 SEE ALSO

L<Data::Dumper::Simple>, L<DB>, L<Devel::Caller>, L<Devel::Caller::Perl>,
L<PadWalker>.

=head1 AUTHORS

Ran Eilam

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2007 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut

