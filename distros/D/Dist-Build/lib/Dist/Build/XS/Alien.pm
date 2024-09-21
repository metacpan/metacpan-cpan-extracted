package Dist::Build::XS::Alien;
$Dist::Build::XS::Alien::VERSION = '0.015';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use Carp 'croak';
use ExtUtils::Builder::Util 'require_module';
use ExtUtils::Helpers 'split_like_shell';

sub add_methods {
	my ($self, $planner, %args) = @_;

	my $add_xs = $planner->can('add_xs') or croak 'XS must be loaded before imports can be done';

	$planner->add_delegate('add_xs', sub {
		my ($planner, %args) = @_;

		if (my $alien = delete $args{alien}) {
			my @aliens = ref $alien ? @{ $alien } : $alien;

			for my $alien (@aliens) {
				my $module = $alien =~ /::/ ? $alien : "Alien::$alien";
				require_module($module);

				my $use_static = $module->install_type eq 'share' && $module->can('cflags_static');
				my ($cflags, $ldflags) = $use_static ? ($module->cflags_static, $module->libs_static) : ($module->cflags, $module->libs);

				for my $compiler_flag (split_like_shell($cflags)) {
					if ($compiler_flag =~ s/^-I//) {
						unshift @{ $args{include_dirs} }, $compiler_flag;
					} elsif ($compiler_flag =~ /^-D(\w+)=(.*)/) {
						$args{defines}{$1} //= $2;
					} elsif ($compiler_flag =~ /^-D(\w+)/) {
						$args{defines}{$1} //= '';
					} else {
						unshift @{ $args{extra_compiler_flags} }, $compiler_flag;
					}
				}

				for my $linker_flag (split_like_shell($ldflags)) {
					if ($linker_flag =~ s/^-l//) {
						unshift @{ $args{libraries} }, $linker_flag;
					} elsif ($linker_flag =~ s/^-L//) {
						unshift @{ $args{library_dirs} }, $linker_flag;
					} else {
						unshift @{ $args{extra_linker_flags} }, $linker_flag;
					}
				}
			}
		}

		$planner->$add_xs(%args);
	});
}

1;

# ABSTRACT: Dist::Build extension to use Alien modules.

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Build::XS::Alien - Dist::Build extension to use Alien modules.

=head1 VERSION

version 0.015

=head1 SYNOPSIS

 load_module('Dist::Build::XS');
 load_module('Dist::Build::XS::Alien');

 add_xs(
     module => 'Foo::Bar',
     alien  => 'xz',
 );

=head1 DESCRIPTION

This module is an extension of L<Dist::Build::XS|Dist::Build::XS>, adding an additional argument to the C<add_xs> function: C<alien>. It will add the appropriate arguments for that alien module to the build. It can be either a string or a list of strings. If the strings don't contain C<::> they're prepended with C<'Alien::'> before the module is loaded.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
