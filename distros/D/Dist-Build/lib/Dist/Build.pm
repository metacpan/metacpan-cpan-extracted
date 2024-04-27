package Dist::Build;
$Dist::Build::VERSION = '0.001';
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT = qw/Build Build_PL/;

use Carp qw/croak/;
use CPAN::Meta;
use ExtUtils::Config;
use ExtUtils::Helpers 0.007 qw/split_like_shell detildefy make_executable man1_pagename man3_pagename/;
use ExtUtils::InstallPaths;
use File::Find ();
use File::Spec::Functions qw/catfile catdir abs2rel /;
use Getopt::Long 2.36 qw/GetOptionsFromArray/;
use Parse::CPAN::Meta;

use ExtUtils::Builder::Planner;
use Dist::Build::Serializer;

my $json_backend = Parse::CPAN::Meta->json_backend;
my $json = $json_backend->new->canonical->pretty->utf8;
my $serializer = 'Dist::Build::Serializer';

sub load_json {
	my $filename = shift;
	open my $fh, '<:raw', $filename;
	my $content = do { local $/; <$fh> };
	return $json->decode($content);
}

sub save_json {
	my ($filename, $content) = @_;
	open my $fh, '>:raw', $filename;
	print $fh $json->encode($content);
	return;
}

my @options = qw/install_base=s install_path=s% installdirs=s destdir=s prefix=s config=s% uninst:1 verbose:1 dry_run:1 pureperl_only|pureperl-only:1 create_packlist=i jobs=i/;

sub get_config {
	my ($meta_name, @arguments) = @_;
	my %options;
	GetOptionsFromArray([ @$_ ], \%options, @options) or die "Could not parse arguments" for @arguments;

	$options{$_} = detildefy($options{$_}) for grep { exists $options{$_} } qw/install_base destdir prefix/;
	if ($options{install_path}) {
		$_ = detildefy($_) for values %{ $options{install_path} };
	}
	$options{config} = ExtUtils::Config->new($options{config});
	$options{install_paths} = ExtUtils::InstallPaths->new(%options, dist_name => $meta_name);

	return %options;
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

sub Build_PL {
	my ($args, $env) = @_;

	my $meta = CPAN::Meta->load_file('META.json', { lazy_validation => 0 });

	my @env = defined $env->{PERL_MB_OPT} ? split_like_shell($env->{PERL_MB_OPT}) : ();
	my %options = get_config($meta->name, $args, \@env);

	my $planner = ExtUtils::Builder::Planner->new;
	$planner->load_module('Dist::Build::Core');

	my %modules = map { $_ => catfile('blib', $_) } find(qr/\.pm$/, 'lib');
	my %docs    = map { $_ => catfile('blib', $_) } find(qr/\.pod$/, 'lib');
	my %scripts = map { $_ => catfile('blib', $_) } find(qr/(?:)/, 'script');
	my %sdocs   = map { $_ => delete $scripts{$_} } grep { /.pod$/ } keys %scripts;

	my %most = (%modules, %docs, %sdocs);

	for my $source (keys %most) {
		$planner->copy_file($source, $most{$source});
	}

	for my $source (keys %scripts) {
		$planner->copy_executable($source, $scripts{$source});
	}

	my (%man1, %man3);
	if ($options{install_paths}->is_default_installable('bindoc')) {
		my $section1 = $options{config}->get('man1ext');
		my @files = grep { contains_pod($_) } keys %scripts, keys %sdocs;
		for my $source (@files) {
			my $destination = catfile('blib', 'bindoc', man1_pagename($source));
			$planner->manify($source, $destination, $section1);
			$man1{$source} = $destination;
		}
	}
	if ($options{install_paths}->is_default_installable('libdoc')) {
		my $section3 = $options{config}->get('man3ext');
		my @files = grep { contains_pod($_) } keys %modules, keys %docs;
		for my $source (@files) {
			my $destination = catfile('blib', 'libdoc', man3_pagename($source));
			$planner->manify($source, $destination, $section3);
			$man3{$source} = $destination;
		}
	}

	$planner->mkdirs('config', map { catfile('blib', $_) } qw/lib arch bindoc libdoc script bin/);
	$planner->create_phony('code', 'config', values %most, values %scripts);
	$planner->create_phony('manify', 'config', values %man1, values %man3);
	$planner->create_phony('dynamic');
	$planner->create_phony('pure_all', 'code', 'manify', 'dynamic');
	$planner->create_phony('build', 'pure_all');

	$planner->tap_harness('test', dependencies => [ 'pure_all' ], test_files => [ find(qr/\.t$/, 't')]);
	$planner->install('install', dependencies => [ 'pure_all' ], install_map => $options{install_paths}->install_map);

	$planner->add_delegate('meta', sub { $meta });
	$planner->add_delegate('dist_name', sub { $meta->name });
	$planner->add_delegate('dist_version', sub { $meta->version });
	$planner->add_delegate('release_status', sub { $meta->release_status });
	$planner->add_delegate('perl_path', sub { get_perl(%options) });

	for my $variable (qw/config install_paths verbose uninst jobs pureperl_only/) {
		$planner->add_delegate($variable, sub { $options{$variable} });
	}

	for my $file (glob 'planner/*.pl') {
		my $inner = $planner->new_scope;
		$inner->add_delegate('outer', sub { $planner });
		$inner->run_dsl($file);
	}

	my $plan = $planner->materialize;

	mkdir '_build' if not -d '_build';
	save_json(catfile(qw/_build graph/), $serializer->serialize_plan($plan));
	save_json(catfile(qw/_build params/), [ $args, \@env ]);

	$meta->save('MYMETA.json');

	printf "Creating new 'Build' script for '%s' version '%s'\n", $meta->name, $meta->version;
	my $dir = $meta->name eq 'Dist-Build' ? 'lib' : 'inc';
	open my $fh, '>:utf8', 'Build';
	print $fh "#!perl\nuse lib '$dir';\nuse Dist::Build;\nBuild(\\\@ARGV, \\\%ENV);\n";
	close $fh;
	make_executable('Build');

	return;
}

sub Build {
	my ($args, $env) = @_;
	my $meta = CPAN::Meta->load_file('MYMETA.json', { lazy_validation => 0 });

	my ($bpl, $mbopts) = @{ load_json(catfile(qw/_build params/)) };
	my %options = get_config($meta->name, $bpl, $mbopts, $args);
	my $action = @{$args} ? shift @{$args} : 'build';

	my $preplan = load_json(catfile(qw/_build graph/));
	my $plan = $serializer->deserialize_plan($preplan, %options);
	return $plan->run($action);
}

1;

# ABSTRACT: A modern module builder, author tools not included!

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Build - A modern module builder, author tools not included!

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Dist::Build;
 Build_PL(\@ARGV, \%ENV);

=head1 DESCRIPTION

C<Dist::Build> is a Build.PL implementation. Unlike L<Module::Build::Tiny> it is extensible, unlike L<Module::Build> it uses a build graph internally which makes it easy to combine different customizations. It's typically extended by adding a C<.pl> script in C<planner/>. E.g.

 load_module("Dist::Build::ShareDir");
 dist_sharedir('share', 'Foo-Bar');
 
 load_module("Dist::Build::XS");
 add_xs(
   libraries     => [ 'foo' ],
   extra_sources => [ glob 'src/*.c' ],
 );

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
