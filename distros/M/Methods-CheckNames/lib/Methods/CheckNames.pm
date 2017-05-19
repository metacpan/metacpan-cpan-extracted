#!/usr/bin/perl

package Methods::CheckNames;

use strict;
use warnings;
use B::Hooks::OP::Check;
use B::Hooks::OP::PPAddr;
use B::Hooks::EndOfScope;
use namespace::clean;

our $VERSION = "0.06";

eval {
	require XSLoader;
	XSLoader::load(__PACKAGE__, $VERSION);
	1;
} or do {
	require DynaLoader;
	push our @ISA, 'DynaLoader';
	__PACKAGE__->bootstrap($VERSION);
};

sub import {
    my ($class) = @_;
    my $caller = caller;

    my $hook = $class->setup;

    on_scope_end {
        $class->teardown($hook);
    };

    return;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Methods::CheckNames - Statically check for named methods

=head1 SYNOPSIS

	my Foo $object;

	$object->method(); # dies at compile time unless a method can be found

=head1 DESCRIPTION

This module enables simplistic checking of method names for typed my variables.

It's not much more than a proof of concept.

=head1 TODO

=over 4

=item *

Use the C<can> meta method instead of C<gv_fetchmethod>

=item *

Make the checking pluggable

=back

=head1 VERSION CONTROL

This module is maintained using git. You can get the latest version from
L<git://github.com/rafl/methods-checknames.git>.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut

