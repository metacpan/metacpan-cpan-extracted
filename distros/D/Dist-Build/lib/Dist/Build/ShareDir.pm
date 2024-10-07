package Dist::Build::ShareDir;
$Dist::Build::ShareDir::VERSION = '0.016';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use File::Find 'find';
use File::Spec::Functions qw/abs2rel catfile/;

sub add_methods {
	my ($self, $planner) = @_;

	$planner->add_delegate('dist_sharedir', sub {
		my ($planner, $dir, $dist_name) = @_;
		$dist_name //= $planner->distribution;

		my @outputs;
		find(sub {
			return unless -f;
			my $output = catfile(qw/blib lib auto share dist/, $dist_name, abs2rel($File::Find::name, $dir));
			$planner->copy_file(abs2rel($File::Find::name), $output);
			push @outputs, $output;
		}, $dir);

		$planner->create_phony('code', @outputs);
	});

	$planner->add_delegate('module_sharedir', sub {
		my ($planner, $dir, $module_name) = @_;
		$module_name //= $planner->main_module;
		(my $module_dir = $module_name) =~ s/::/-/g;

		my @outputs;
		find(sub {
			return unless -f;
			my $output = catfile(qw/blib lib auto share module/, $module_dir, abs2rel($File::Find::name, $dir));
			$planner->copy_file(abs2rel($File::Find::name), $output);
			push @outputs, $output;
		}, $dir);

		$planner->create_phony('code', @outputs);
	});
}

1;

# ABSTRACT: Sharedir support for Dist::Build

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Build::ShareDir - Sharedir support for Dist::Build

=head1 VERSION

version 0.016

=head1 SYNOPSIS

 load_module("Dist::Build::ShareDir");
 dist_sharedir('share', 'Foo-Bar');
 module_sharedir('foo', 'Foo::Bar');

=head1 DESCRIPTION

This Dist::Build extension implements sharedirs. It does not take any arguments at loading time, and exposts two functions to the planner:

=head2 dist_sharedir($dir, $distribution)

This marks C<$dir> as the source sharedir for the distribution C<$distribution>. If C<$distribution> isn't given, it defaults to the C<distribution> of the planner.

=head2 module_sharedir($dir, $module_name)

This marks C<$dir> as the source sharedir for the module C<$module_name>. If C<$module_name> isn't given, it defaults to the C<main_module> of the planner.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
