package Dist::Build::Core;
$Dist::Build::Core::VERSION = '0.018';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use Exporter 5.57 'import';
our @EXPORT_OK = qw/copy make_executable manify tap_harness install dump_binary dump_text dump_json/;

use Carp qw/croak/;
use ExtUtils::Helpers 0.028 qw/make_executable man1_pagename man3_pagename/;
use ExtUtils::Install ();
use File::Basename qw/basename dirname/;
use File::Copy ();
use File::Find ();
use File::Path qw/make_path remove_tree/;
use File::Spec::Functions qw/catdir catfile abs2rel rel2abs/;
use Parse::CPAN::Meta;

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

sub find {
	my ($pattern, $dir) = @_;
	my @ret;
	File::Find::find(sub { push @ret, abs2rel($File::Find::name) if /$pattern/ && -f }, $dir) if -d $dir;
	return @ret;
}

sub contains_pod {
	my ($file) = @_;
	return 0 if not -f $file;
	open my $fh, '<:utf8', $file;
	my $content = do { local $/; <$fh> };
	return $content =~ /^\=(?:head|pod|item)/m;
}

sub add_methods {
	my ($self, $planner) = @_;

	$planner->add_delegate('copy_file', sub {
		my ($planner, $source, $destination) = @_;
		my $copy = new_action('copy', $source, $destination);
		$planner->create_node(
			target       => $destination,
			dependencies => [ $source ],
			actions      => [ $copy ],
		);
		return $destination;
	});

	$planner->add_delegate('copy_executable', sub {
		my ($planner, $source, $destination) = @_;
		my $copy = new_action('copy', $source, $destination);
		my $make_executable = new_action('make_executable', $destination);
		$planner->create_node(
			target       => $destination,
			dependencies => [ $source ],
			actions      => [ $copy, $make_executable ],
		);
		return $destination;
	});

	$planner->add_delegate('manify', sub {
		my ($planner, $source, $destination, $section) = @_;
		my $manify = new_action('manify', $source, $destination, $section);
		my $dirname = dirname($destination);
		$planner->create_node(
			target       => $destination,
			dependencies => [ $source, $dirname ],
			actions      => [ $manify ],
		);
		return $destination;
	});

	$planner->add_delegate('mkdir', sub {
		my ($planner, $target, %options) = @_;
		my $action = ExtUtils::Builder::Action::Function->new(
			function  => 'make_path',
			module    => 'File::Path',
			arguments => [ $target, %options ],
			exports   => 'explicit',
			message   => "mkdir $target",
		);
		$planner->create_node(
			target  => $target,
			actions => [ $action ],
		);
		return $target;
	});

	$planner->add_delegate('tap_harness', sub {
		my ($planner, $target, %options) = @_;
		$planner->create_node(
			target       => $target,
			dependencies => $options{dependencies},
			phony        => 1,
			actions      => [
				new_action('tap_harness', test_dir => $options{test_dir} ),
			],
		);
		return $target;
	});

	$planner->add_delegate('install', sub {
		my ($planner, $target, %options) = @_;
		$planner->create_node(
			target       => $target,
			dependencies => $options{dependencies},
			phony        => 1,
			actions      => [
				new_action('install', install_map => $options{install_map}),
			]
		);
		return $target;
	});

	$planner->add_delegate('dump_binary', sub {
		my ($planner, $target, $content, %options) = @_;
		$planner->create_node(
			target       => $target,
			dependencies => $options{dependencies},
			actions      => [
				new_action('dump_binary', $target, $content),
			]
		);
	});

	$planner->add_delegate('dump_text', sub {
		my ($planner, $target, $content, %options) = @_;
		$planner->create_node(
			target       => $target,
			dependencies => $options{dependencies},
			actions      => [
				new_action('dump_text', $target, $content, $options{encoding} // 'utf-8'),
			]
		);
	});

	$planner->add_delegate('dump_json', sub {
		my ($planner, $target, $content, %options) = @_;
		$planner->create_node(
			target       => $target,
			dependencies => $options{dependencies},
			actions      => [
				new_action('dump_json', $target, $content),
			]
		);
	});

	$planner->add_delegate('script_dir', sub {
		my ($planner, $base) = @_;
		(my $prefix = $base) =~ s/\W/-/g;

		my $script_files = $planner->create_pattern(
			dir  => $base,
		);
		my $script_pod_files = $planner->create_pattern(
			name => "$prefix-pod-files",
			on   => $script_files,
			file => '*.pod',
		);
		my $script_script_files = $planner->create_pattern(
			name   => "$prefix-script-files",
			on     => $script_files,
			file   => '*.pod',
			negate => 1,
		);

		$planner->create_subst(
			on     => $script_script_files,
			add_to => 'code',
			subst  => sub {
				my ($source) = @_;
				my $destination = catfile('blib', 'script', abs2rel($source, $base));
				return $planner->copy_executable($source, $destination);
			},
		);

		$planner->create_subst(
			on     => $script_pod_files,
			add_to => 'code',
			subst  => sub {
				my ($source) = @_;
				my $destination = catfile('blib', 'script', basename($source));
				return $planner->copy_file($source, $destination);
			},
		);

		my $script_doc_files = $planner->create_filter(on => $script_script_files, condition => \&contains_pod);

		my $section1 = $planner->config->get('man1ext');
		my $blib_doc_files = $planner->create_subst(
			on     => [ $script_pod_files, $script_doc_files ],
			add_to => 'manify',
			subst  => sub {
				my ($source) = @_;
				my $destination = catfile('blib', 'bindoc', man1_pagename($source, $section1));
				return $planner->manify($source, $destination, $section1);
			},
		);
	});

	$planner->add_delegate('lib_dir', sub {
		my ($planner, $base) = @_;
		(my $prefix = $base) =~ s/\W/-/g;

		my $files = $planner->create_pattern(
			dir  => $base,
		);
		my $pm_files = $planner->create_pattern(
			name => "${prefix}-pm-files",
			on   => $files,
			file => '*.pm',
		);
		my $pod_files = $planner->create_pattern(
			name => "{$prefix}-pod-files",
			on   => $files,
			file => '*.pod',
		);

		my $blib_files = $planner->create_subst(
			on     => [ $pm_files, $pod_files ],
			add_to => 'code',
			subst  => sub {
				my ($source) = @_;
				my $destination = catfile('blib', 'lib', abs2rel($source, $base));
				return $planner->copy_file($source, $destination);
			},
		);

		my $pm_doc_files = $planner->create_filter(
			on        => $pm_files,
			condition => \&contains_pod,
		);
		my $section3 = $planner->config->get('man3ext');
		my $blib_doc_files = $planner->create_subst(
			on     => [ $pm_doc_files, $pod_files ],
			add_to => 'manify',
			subst  => sub {
				my ($source) = @_;
				my $destination = catfile('blib', 'libdoc', man3_pagename($source, $base, $section3));
				return $planner->manify($source, $destination, $section3);
			}
		);
	});

	$planner->add_delegate('autoclean', sub {
		my ($planner) = @_;
		my @targets = grep { !/^blib\b/ } map { $_->target } grep { ! $_->phony } $planner->materialize->nodes;

		my $clean_action = ExtUtils::Builder::Action::Function->new(
			function  => 'remove_tree',
			module    => 'File::Path',
			arguments => [ 'blib', @targets ],
			exports   => 'explicit',
			message   => "rm_r @targets",
		);
		$planner->create_node(
			target       => 'clean',
			phony        => 1,
			actions      => [ $clean_action ],
		);

		my @real_targets = qw/Build _build MYMETA.json MYMETA.yml/;
		my $realclean_action = ExtUtils::Builder::Action::Function->new(
			function  => 'remove_tree',
			module    => 'File::Path',
			arguments => \@real_targets,
			exports   => 'explicit',
			message   => "rm_r @real_targets",
		);
		$planner->create_node(
			target       => 'realclean',
			phony        => 1,
			dependencies => [ 'clean' ],
			actions      => [ $realclean_action ],
		);
	});
}

sub copy {
	my ($source, $target, %options) = @_;

	make_path(dirname($target));
	unlink $target if -f $target;
	File::Copy::copy($source, $target) or croak "Could not copy: $!";

	my ($atime, $mtime) = (stat $source)[8,9];
	utime $atime, $mtime, $target;
	chmod 0444 & ~umask, $target;

	return;
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
	my @test_files;
	if ($args{test_files}) {
		@test_files = @{ delete $args{test_files} };
	} else {
		my $dir = delete $args{test_dir} // 't';
		@test_files = sort +find(qr/\.t$/, $dir);
	}
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
	ExtUtils::Install::install($args{install_map}, $args{verbose}, $args{dry_run}, $args{uninst});
	return;
}

sub dump_binary {
	my ($filename, $content) = @_;
	open my $fh, '>:raw', $filename;
	print $fh $content;
}

sub dump_text {
	my ($filename, $content, $encoding) = @_;
	open my $fh, ">:encoding($encoding)", $filename;
	print $fh $content;
}

my $json_backend = Parse::CPAN::Meta->json_backend;
my $json = $json_backend->new->canonical->pretty->utf8;

sub dump_json {
	my ($filename, $content) = @_;
	open my $fh, '>:raw', $filename;
	print $fh $json->encode($content);
}

1;

# ABSTRACT: core functions for Dist::Build

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Build::Core - core functions for Dist::Build

=head1 VERSION

version 0.018

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

=item * mkdir($target, $dir, %options)

This ensures the given directory exist.

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

=item * dump_binary($filename, $content, %named_arguments)

Write C<$content> to C<$filename> as binary data.

=item * dump_text($filename, $content, %named_arguments)

Write C<$content> to C<$filename> as text of the given encoding.

=item * dump_json($filename, $content, %named_arguments)

Write C<$content> to C<$filename> as JSON.

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
