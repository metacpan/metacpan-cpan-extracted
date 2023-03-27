=pod

=encoding utf-8

=head1 PURPOSE

Print version numbers, etc.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;

my @modules = qw(
	Eval::TypeTiny
	Exporter::Shiny
	Import::Into
	Module::Runtime
	Type::Library
	Type::Registry
	Types::Common
	
	Test2::V0
	Test2::Tools::Spec
	Test2::Require::AuthorTesting
	Test2::Require::Module
	Test2::Plugin::BailOnFail
);

diag "\n####";
for my $mod ( sort @modules ) {
	eval "require $mod;";
	diag sprintf( '%-20s %s', $mod, $mod->VERSION );
}
diag "####";

pass;

done_testing;

