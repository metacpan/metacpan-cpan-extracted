package Dist::Build::XS::Import;
$Dist::Build::XS::Import::VERSION = '0.014';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use Carp 'croak';
use File::Spec::Functions 'catdir';
use File::ShareDir::Tiny 'module_dir';

sub add_methods {
	my ($self, $planner, %args) = @_;

	my $add_xs = $planner->can('add_xs') or croak 'XS must be loaded before imports can be done';

	$planner->add_delegate('add_xs', sub {
		my ($planner, %args) = @_;

		if (my $import = delete $args{import}) {
			my @modules = ref $import ? @{ $import } : $import;
			for my $module (@modules) {
				my $module_dir = module_dir($module);
				my $include = catdir($module_dir, 'include');
				croak "No such import $module" if not -d $include;

				unshift @{ $args{include_dirs} }, $include;
			}
		}

		$planner->$add_xs(%args);
	});
}

1;

# ABSTRACT: Dist::Build extension to import headers for other XS modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Build::XS::Import - Dist::Build extension to import headers for other XS modules

=head1 VERSION

version 0.014

=head1 SYNOPSIS

 load_module('Dist::Build::XS');
 load_module('Dist::Build::XS::Import');

 add_xs(
     module => 'Foo::Bar',
     import => 'My::Dependency',
 );

=head1 DESCRIPTION

This module is an extension of L<Dist::Build::XS|Dist::Build::XS>, adding an additional argument to the C<add_xs> function: C<import>. It will add the include dir (as exported by L<Dist::Build::XS::Export|Dist::Build::XS::Export>)

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
