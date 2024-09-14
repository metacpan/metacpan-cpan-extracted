package Dist::Build::XS::PkgConfig;

use strict;
use warnings;

our $VERSION = '0.001';

use Carp 'croak';
use ExtUtils::Helpers 'split_like_shell';
use PkgConfig;
use version;

sub add_methods {
	my ($self, $planner, %args) = @_;

	my $add_xs = $planner->can('add_xs') or croak 'XS must be loaded before imports can be done';

	$planner->add_delegate('add_xs', sub {
		my ($planner, %args) = @_;

		if (my $pkg_config = delete $args{pkg_config}) {
			my @packages = ref($pkg_config) eq 'ARRAY' ? @{ $pkg_config } : $pkg_config;

			for my $pkg_args (@packages) {
				my $library = delete $pkg_args->{library};

				my $package = PkgConfig->find($library, %{$pkg_args});

				croak "No such library $library" unless $package && $package->pkg_exists;

				if (my $min_version = $pkg_args->{min_version}) {
					my $pkg_version = version->new($package->pkg_version);
					croak "Library $library version $pkg_version smaller than $min_version" if $pkg_version < version->new($min_version);
				}

				unshift @{ $args{extra_compiler_flags} }, split_like_shell($package->get_cflags);
				unshift @{ $args{extra_linker_flags}   }, split_like_shell($package->get_ldflags);
			}
		}

		$planner->$add_xs(%args);
	});
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Build::XS::PkgConfig - Dist::Build extension to use pkg-config.

=head1 SYNOPSIS

 load_module('Dist::Build::XS');
 load_module('Dist::Build::XS::PkgConfig');

 add_xs(
     module => 'Foo::Bar',
     pkg_config => {
         library     => 'tree-sitter',
         min_version => '0.6.3',
     },
 );

=head1 DESCRIPTION

This module is an extension of L<Dist::Build::XS|Dist::Build::XS>, adding an additional argument to the C<add_xs> function: C<pkg_config>, allowing you to add flags to your build based on a pkg-config library file. This argument will either contain a hash, or a list of hashes. The hashes will contain the following entries:

=over 4

=item * library

B<Mandatory>. The name of the library you want to link to.

=item * min_version

The minimum version of the library.

=item * static

Also specify static libraries.

=back

It will add the appropriate arguments for that pkgmodule to the build.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


