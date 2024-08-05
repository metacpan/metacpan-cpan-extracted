package Dist::Build::Core;
$Dist::Build::Core::VERSION = '0.010';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use Exporter 5.57 'import';
our @EXPORT_OK = qw/copy mkdir rm_r make_executable manify tap_harness install/;

use Carp qw/croak/;
use ExtUtils::Helpers 0.007 qw/man1_pagename man3_pagename/;
use ExtUtils::Install ();
use File::Basename qw/dirname/;
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
	open my $fh, '<:utf8', $file;
	my $content = do { local $/; <$fh> };
	return $content =~ /^\=(?:head|pod|item)/m;
}

sub add_methods {
	my ($self, $planner) = @_;

	$planner->add_delegate('copy_file', sub {
		my (undef, $source, $destination) = @_;
		my $copy = new_action('copy', $source, $destination);
		$planner->create_node(
			target       => $destination,
			dependencies => [ $source ],
			actions      => [ $copy ],
		);
	});

	$planner->add_delegate('copy_executable', sub {
		my (undef, $source, $destination) = @_;
		my $copy = new_action('copy', $source, $destination);
		my $make_executable = new_action('make_executable', $destination);
		$planner->create_node(
			target       => $destination,
			dependencies => [ $source ],
			actions      => [ $copy, $make_executable ],
		);
	});

	$planner->add_delegate('manify', sub {
		my (undef, $source, $destination, $section) = @_;
		my $manify = new_action('manify', $source, $destination, $section);
		my $dirname = dirname($destination);
		$planner->create_node(
			target       => $destination,
			dependencies => [ $source, $dirname ],
			actions      => [ $manify ],
		);
	});

	$planner->add_delegate('mkdir', sub {
		my (undef, $target, %options) = @_;
		$planner->create_node(
			target  => $target,
			actions => [ new_action('mkdir', $target, %options) ],
		);
	});

	$planner->add_delegate('tap_harness', sub {
		my (undef, $target, %options) = @_;
		$planner->create_node(
			target       => $target,
			dependencies => $options{dependencies},
			phony        => 1,
			actions      => [
				new_action('tap_harness', test_dir => $options{test_dir} ),
			],
		);
	});

	$planner->add_delegate('install', sub {
		my (undef, $target, %options) = @_;
		$planner->create_node(
			target       => $target,
			dependencies => $options{dependencies},
			phony        => 1,
			actions      => [
				new_action('install', install_map => $options{install_map}),
			]
		);
	});

	$planner->add_delegate('dump_binary', sub {
		my (undef, $target, %options) = @_;
		$planner->create_node(
			target       => $target,
			dependencies => $options{dependencies},
			actions      => [
				new_action('dump_binary', $options{content}),
			]
		);
	});

	$planner->add_delegate('dump_text', sub {
		my (undef, $target, %options) = @_;
		$planner->create_node(
			target       => $target,
			dependencies => $options{dependencies},
			actions      => [
				new_action('dump_text', $options{content}, $options{encoding} || 'utf-8'),
			]
		);
	});

	$planner->add_delegate('dump_json', sub {
		my (undef, $target, %options) = @_;
		$planner->create_node(
			target       => $target,
			dependencies => $options{dependencies},
			actions      => [
				new_action('dump_json', $options{content}),
			]
		);
	});

	$planner->add_delegate('script_files', sub {
		my ($planner, @files) = @_;
		my %scripts = map { $_ => catfile('blib', $_) } @files;
		my %sdocs   = map { $_ => delete $scripts{$_} } grep { /.pod$/ } keys %scripts;

		for my $source (keys %sdocs) {
			$planner->copy_file($source, $scripts{$source});
		}

		for my $source (keys %scripts) {
			$planner->copy_executable($source, $scripts{$source});
		}

		my (%man1);
		if ($planner->install_paths->is_default_installable('bindoc')) {
			my $section1 = $planner->config->get('man1ext');
			my @files = keys %scripts, keys %sdocs;
			for my $source (@files) {
				next unless contains_pod($source);
				my $destination = catfile('blib', 'bindoc', man1_pagename($source));
				$planner->manify($source, $destination, $section1);
				$man1{$source} = $destination;
			}
		}

		$planner->create_phony('code', values %scripts);
		$planner->create_phony('manify', values %man1);
	});

	$planner->add_delegate('script_dir', sub {
		my ($planner, $dir) = @_;

		my @files = find(qr/(?!\.)/, 'script');
		$planner->script_files(@files);
	});

	$planner->add_delegate('lib_files', sub {
		my ($planner, @files) = @_;
		my %modules = map { $_ => catfile('blib', $_) } @files;

		for my $source (keys %modules) {
			$planner->copy_file($source, $modules{$source});
		}

		my %man3;
		if ($planner->install_paths->is_default_installable('libdoc')) {
			my $section3 = $planner->config->get('man3ext');
			my @files = grep { contains_pod($_) } keys %modules;
			for my $source (@files) {
				my $destination = catfile('blib', 'libdoc', man3_pagename($source));
				$planner->manify($source, $destination, $section3);
				$man3{$source} = $destination;
			}
		}
		$planner->create_phony('code', 'config', values %modules);
		$planner->create_phony('manify', 'config', values %man3);
	});

	$planner->add_delegate('lib_dir', sub {
		my ($planner, $dir) = @_;
		my @files = find(qr/\.p(?:m|od)$/, $dir);
		$planner->lib_files(@files);
	});

	$planner->add_delegate('autoclean', sub {
		my ($planner) = @_;
		my @targets = grep { !/^blib\b/ } map { $_->target } grep { ! $_->phony } $planner->materialize->nodes;

		$planner->create_node(
			target       => 'clean',
			phony        => 1,
			actions      => [
				new_action('rm_r', 'blib', @targets),
			],
		);

		$planner->create_node(
			target       => 'realclean',
			phony        => 1,
			dependencies => [ 'clean' ],
			actions      => [
				new_action('rm_r', 'Build', '_build', 'MYMETA.json', 'MYMETA.yml'),
			],
		);
	});
}

sub copy {
	my ($source, $target, %options) = @_;

	make_path(dirname($target));
	File::Copy::copy($source, $target) or croak "Could not copy: $!";

	my ($atime, $mtime) = (stat $source)[8,9];
	utime $atime, $mtime, $target;
	chmod 0444 & ~umask, $target;

	return;
}

sub mkdir {
	my ($source, %options) = @_;
	make_path($source, \%options);
	return;
}

sub rm_r {
	my (@sources) = @_;
	remove_tree(@sources);
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

version 0.010

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

=item * dump_binary($filename, $content)

Write C<$content> to C<$filename> as binary data.

=item * dump_text($filename, $content, $encoding = 'utf8')

Write C<$content> to C<$filename> as text of the given encoding.

=item * dump_json($filename, $content)

Write C<$content> to C<$filename> as JSON.

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
