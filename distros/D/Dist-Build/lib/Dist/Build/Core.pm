package Dist::Build::Core;
$Dist::Build::Core::VERSION = '0.004';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use Exporter 5.57 'import';
our @EXPORT_OK = qw/copy mkdir make_executable manify tap_harness install/;

use Carp qw/croak/;
use ExtUtils::Install ();
use File::Basename qw/dirname/;
use File::Copy ();
use File::Path qw/make_path/;
use File::Spec::Functions qw/catdir rel2abs/;

use ExtUtils::Builder::Node;
use ExtUtils::Builder::Action::Function;

sub new_action {
	my ($name, @args) = @_;
	return ExtUtils::Builder::Action::Function->new(
		function  => $name,
		module    => __PACKAGE__,
		arguments => \@args,
		exports   => 'explicit',
	);
}

sub add_methods {
	my ($self, $planner) = @_;

	$self->add_delegate($planner, 'copy_file', sub {
		my ($source, $destination) = @_;
		my $copy = new_action('copy', $source, $destination);
		ExtUtils::Builder::Node->new(
			target       => $destination,
			dependencies => [ $source ],
			actions      => [ $copy ],
		);
	});

	$self->add_delegate($planner, 'copy_executable', sub {
		my ($source, $destination) = @_;
		my $copy = new_action('copy', $source, $destination);
		my $make_executable = new_action('make_executable', $destination);
		ExtUtils::Builder::Node->new(
			target       => $destination,
			dependencies => [ $source ],
			actions      => [ $copy, $make_executable ],
		);
	});

	$self->add_delegate($planner, 'manify', sub {
		my ($source, $destination, $section) = @_;
		my $manify = new_action('manify', $source, $destination, $section);
		ExtUtils::Builder::Node->new(
			target       => $destination,
			dependencies => [ $source ],
			actions      => [ $manify ],
		);
	});

	$self->add_delegate($planner, 'mkdirs', sub {
		my ($target, @mkdirs) = @_;
		my @actions = map { new_action('mkdir', $_) } @mkdirs;
		ExtUtils::Builder::Node->new(
			target  => $target,
			phony   => 1,
			actions => \@actions,
		);
	});

	$self->add_delegate($planner, 'tap_harness', sub {
		my ($target, %options) = @_;
		ExtUtils::Builder::Node->new(
			target       => $target,
			dependencies => $options{dependencies},
			phony        => 1,
			actions      => [
				new_action('tap_harness', test_files => $options{test_files} ),
			],
		);
	});

	$self->add_delegate($planner, 'install', sub {
		my ($target, %options) = @_;
		ExtUtils::Builder::Node->new(
			target       => $target,
			dependencies => $options{dependencies},
			phony        => 1,
			actions      => [
				new_action('install', install_map => $options{install_map}),
			]
		);
	})
}

sub copy {
	my ($source, $target, %options) = @_;

	make_path(dirname($target));
	File::Copy::copy($source, $target) or croak "Could not copy: $!";
	printf "cp %s %s\n", $source, $target;

	my ($atime, $mtime) = (stat $source)[8,9];
	utime $atime, $mtime, $target;
	chmod 0444 & ~umask, $target;

	return;
}

sub mkdir {
	my ($source, %options) = @_;
	make_path($source, %options);
	return;
}

sub make_executable {
	my ($target) = @_;
	ExtUtils::Helpers::make_executable($target);
}

sub manify {
	my ($input_file, $output_file, $section) = @_;
	require Pod::Man;
	Pod::Man->new(section => $section)->parse_from_file($input_file, $output_file);
	return;
}

my @default_libs = map { catdir('blib', $_) } qw/arch lib/;

sub tap_harness {
	my (%args) = @_;
	my @test_files = @{ delete $args{test_files} };
	my @libs = $args{libs} ? @{ $args{libs} } : @default_libs;
	my %test_args = (
		(color => 1) x !!-t STDOUT,
		%args,
		lib => [ map { rel2abs($_) } @libs ],
	);
	$test_args{verbosity} = delete $test_args{verbose} if exists $test_args{verbose};
	require TAP::Harness::Env;
	my $tester  = TAP::Harness::Env->create(\%test_args);
	my $results = $tester->runtests(@test_files);
	croak "Errors in testing.  Cannot continue.\n" if $results->has_errors;
}

sub install {
	my (%args) = @_;
	ExtUtils::Install::install($args{install_map}, $args{verbose}, 0, $args{uninst});
	return;
}

1;

# ABSTRACT: core functions for Dist::Build

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Build::Core - core functions for Dist::Build

=head1 VERSION

version 0.004

=head1 DESCRIPTION

This plugin contains many of the core actions of C<Dist::Build>.

=head2 Delegates

=over 4

=item * copy_file($source, $destination)

Copy the file C<$source> to C<$destination>.

=item * copy_executable($source, $destination)

Copy the executable C<$source> to C<$destination>.

=item * manify($source, $destination, $section)

Manify C<$source> to C<$destination>, as section C<$section>.

=item * mkdirs($target, @dirs)

This ensures the given directories exist.

=item * tap_harness(%options)

This runs tests for the dist.

=over 4

=item * test_files

The list of files to run.

=item * jobs

The number of concurrent test files to run.

=item * color

This enables color in the harness.

=back

=item * install(%options)

This installs the distribution

=over 4

=item * install_map

The map of intermediate paths to install locations, as produced by L<ExtUtils::InstallPaths>.

=item * verbose

This enables verbose mode.

=item * uninst

This uninstalls files before installing the new ones.

=back

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
