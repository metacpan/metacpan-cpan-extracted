package Dist::Build::XS::Alien;

use strict;
use warnings;

our $VERSION = '0.001';

use parent 'ExtUtils::Builder::Planner::Extension';

use Alien::Base::Wrapper;
use Carp 'croak';
use ExtUtils::Helpers 'split_like_shell';

sub add_methods {
	my ($self, $planner, %args) = @_;

	my $add_xs = $planner->can('add_xs') or croak 'XS must be loaded before imports can be done';

	$planner->add_delegate('add_xs', sub {
		my ($planner, %args) = @_;

		if (my $alien = delete $args{alien}) {
			my @aliens = ref $alien ? @{ $alien } : $alien;
			my %mb_args = Alien::Base::Wrapper->new(@aliens)->mb_args;

			for my $key (qw/extra_compiler_flags extra_linker_flags/) {
				unshift @{ $args{$key} }, split_like_shell($mb_args{$key} // '');
			}

			if ($mb_args{config}) {
				my $config = $args{config} || $planner->config;
				$args{config} = $config->but($mb_args{config});
			}
		}

		$planner->$add_xs(%args);
	});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Build::XS::Alien - Dist::Build extension to use Alien modules.

=head1 SYNOPSIS

 load_module('Dist::Build::XS');
 load_module('Dist::Build::XS::Alien');

 add_xs(
     module => 'Foo::Bar',
     alien  => 'Alien::xz',
 );

=head1 DESCRIPTION

This module is an extension of L<Dist::Build::XS|Dist::Build::XS>, adding an additional argument to the C<add_xs> function: C<alien>. It will add the appropriate arguments for that alien module to the build.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
