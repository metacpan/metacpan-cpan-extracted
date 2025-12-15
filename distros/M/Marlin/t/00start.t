=pod

=encoding utf-8

=head1 PURPOSE

Print version numbers, etc.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use Test2::V0;

my @modules = qw(
	B
	B::Hooks::AtRuntime
	Carp
	Class::Method::Modifiers
	Class::XSAccessor
	Class::XSConstructor
	Exporter::Tiny
	Lexical::Sub
	List::Util
	Module::Runtime
	MRO::Compat
	Role::Tiny
	Scalar::Util
	Sub::HandlesVia
	Sub::Accessor::Small
	Test2::V0
	Type::Tiny
	Type::Tiny::XS
	constant
	strict
	warnings
);

diag "\n####";
for my $mod ( sort @modules ) {
	eval "require $mod;";
	diag sprintf( '%-26s %s', $mod, eval { $mod->VERSION } or '-' );
}
diag "####";

pass;

done_testing;

