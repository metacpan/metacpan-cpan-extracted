package Dist::Build::XS::Import;
$Dist::Build::XS::Import::VERSION = '0.025';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use Carp 'croak';
use File::Spec::Functions qw/catfile catdir/;
use Dist::Build::Util 'module_dir';
use Parse::CPAN::Meta;

my $json_backend = Parse::CPAN::Meta->json_backend;
my $json = $json_backend->new->canonical->pretty->utf8;

sub add_methods {
	my ($self, $planner, %args) = @_;

	my $add_xs = $planner->can('add_xs') or croak 'XS must be loaded before imports can be done';

	$planner->add_delegate('add_xs', sub {
		my ($planner, %args) = @_;

		if (my $import = delete $args{import}) {
			my @modules = ref $import ? @{ $import } : $import;
			for my $module (@modules) {
				my $module_dir = module_dir($module);
				my $found = 0;

				my $include = catdir($module_dir, 'include');
				if (-d $include) {
					unshift @{ $args{include_dirs} }, $include;
					$found++;
				}

				my $typemap = catfile($module_dir, 'typemap');
				if (-e $typemap) {
					unshift @{ $args{typemap} }, $typemap;
					$found++;
				}

				my $config = catfile($module_dir, 'compile.json');
				if (-e $config) {
					open my $fh, '<:raw', $config or die "Could not open $config: $!";
					my $content = do { local $/; <$fh> };
					my $payload = $json->decode($content);

					for my $key (qw/include_dirs library_dirs libraries extra_compiler_flags extra_linker_flags/) {
						unshift @{ $args{$key} }, @{ $payload->{$key} || [] };
					}

					for my $key (keys %{ $payload->{defines} // {} }) {
						$args{defines}{$key} //= $payload->{defines}{$key};
					}
					$found++;
				}

				warn "No such import $module\n" if $found == 0;
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

version 0.025

=head1 SYNOPSIS

 load_extension('Dist::Build::XS');
 load_extension('Dist::Build::XS::Import');

 add_xs(
     module => 'Foo::Bar',
     import => 'My::Dependency',
 );

=head1 DESCRIPTION

This module is an extension of L<Dist::Build::XS|Dist::Build::XS>, adding an additional argument to the C<add_xs> function: C<import>. It is a counterpart to L<Dist::Build::XS::Export|Dist::Build::XS::Export>) will add the include dir, typemap and compilation flags for the given module.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
