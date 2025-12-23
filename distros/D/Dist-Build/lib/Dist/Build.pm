package Dist::Build;
$Dist::Build::VERSION = '0.025';
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT = qw/Build Build_PL/;

use Carp qw/croak/;
use CPAN::Meta;
use ExtUtils::Config;
use ExtUtils::Helpers 0.007 qw/split_like_shell detildefy make_executable/;
use ExtUtils::Manifest 'maniread';
use ExtUtils::InstallPaths;
use File::Spec::Functions qw/catfile catdir abs2rel /;
use Getopt::Long 2.36 qw/GetOptionsFromArray/;
use Parse::CPAN::Meta;
use version ();

use ExtUtils::Builder::Planner 0.016;
use ExtUtils::Builder::Util qw/get_perl unix_to_native_path/;
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

my @options = qw/install_base=s install_path=s% installdirs=s destdir=s prefix=s config=s% uninst:1 verbose:1 dry_run:1 pureperl_only|pureperl-only:1 create_packlist=i jobs=i allow_mb_mismatch:1/;

sub get_config {
	my ($meta_name, @arguments) = @_;
	my %options;
	GetOptionsFromArray($_, \%options, @options) or die "Could not parse arguments" for @arguments;

	$options{$_} = detildefy($options{$_}) for grep { exists $options{$_} } qw/install_base destdir prefix/;
	if ($options{install_path}) {
		$_ = detildefy($_) for values %{ $options{install_path} };
	}
	$options{config} = ExtUtils::Config->new($options{config});
	$options{install_paths} = ExtUtils::InstallPaths->new(%options, dist_name => $meta_name);

	return %options;
}

sub Build_PL {
	my ($args, $env) = @_;

	my $meta = CPAN::Meta->load_file('META.json', { lazy_validation => 0 });

	my @env = defined $env->{PERL_MB_OPT} ? split_like_shell($env->{PERL_MB_OPT}) : ();
	my %options = get_config($meta->name, [ @{$args} ], [ @env ]);

	my $planner = ExtUtils::Builder::Planner->new;

	$planner->create_phony('code', 'config');
	$planner->create_phony('manify', 'config');
	$planner->create_phony('dynamic');
	$planner->create_phony('pure_all', 'code', 'manify', 'dynamic');
	$planner->create_phony('build', 'pure_all');

	$planner->load_extension('ExtUtils::Builder::CPAN::Tool');
	$planner->add_delegate('meta', sub { $meta });

	for my $variable (qw/config install_paths verbose uninst jobs pureperl_only/) {
		$planner->add_delegate($variable, sub { $options{$variable} });
	}

	my @meta_fragments;
	$planner->add_delegate('add_meta', sub {
		my (undef, @fragments) = @_;
		push @meta_fragments, @fragments;
	});

	my $core = $planner->new_scope;
	$core->load_extension('Dist::Build::Core');

	my @blibs = map { catfile('blib', $_) } qw/lib arch bindoc libdoc script bin/;
	$core->mkdir($_) for @blibs;
	$core->create_phony('config', @blibs);
	$core->lib_dir('lib');
	$core->add_seen(unix_to_native_path($_)) for sort keys %{ maniread() };

	$core->tap_harness('test', dependencies => [ 'pure_all' ], test_dir => 't');
	$core->install('install', dependencies => [ 'pure_all' ], install_map => $options{install_paths}->install_map);

	for my $file (glob 'planner/*.pl') {
		$planner->new_scope->run_dsl($file);
	}

	$core->autoclean;

	my $plan = $planner->materialize;

	mkdir '_build' if not -d '_build';
	save_json(catfile(qw/_build graph/), $serializer->serialize_plan($plan));
	save_json(catfile(qw/_build params/), [ $args, \@env ]);

	my $metahash = $meta->as_struct;
	if (@meta_fragments) {
		require CPAN::Meta::Merge;
		my $merger = CPAN::Meta::Merge->new(default_version => '2');
		$metahash = $merger->merge($metahash, @meta_fragments);
	}
	$metahash->{dynamic_config} = 0;
	my $mymeta = CPAN::Meta->create($metahash, { lazy_validation => 0 });
	$mymeta->save('MYMETA.json');

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

version 0.025

=head1 DESCRIPTION

C<Dist::Build> is a Build.PL implementation. Unlike L<Module::Build::Tiny> it is extensible, unlike L<Module::Build> it uses a build graph internally which makes it easy to combine different customizations. It's typically extended by adding a C<.pl> script in C<planner/>. E.g.

 load_extension("Dist::Build::ShareDir");
 dist_sharedir('share', 'Foo-Bar');
 
 load_extension("Dist::Build::XS");
 load_extension("Dist::Build::XS::Alien");
 add_xs(
   alien         => 'foo',
   extra_sources => [ glob 'src/*.c' ],
 );

=head1 PLUGINS

=over 4

=item * L<Dist::Build::XS>

This plugin enables one to compile XS modules. It has a range of options, and a series of extensions that add to its capabilities.

=over 4

=item * L<Dist::Build::XS::Alien>

This is used to link to an L<Alien|Alien::Base> library.

=item * L<Dist::Build::XS::Conf>

This wraps L<ExtUtils::Builder::Conf|ExtUtils::Builder::Conf> to detect headers, libraries and features.

=item * L<Dist::Build::XS::Import>

This can be used to import headers and flags as exported by L<Dist::Build::XS::Export|Dist::Build::XS::Export>.

=item * L<Dist::Build::XS::PkgConfig>

This adds flags for a given library as configured in its pkgconfig file.

=item * L<Dist::Build::XS::WriteConstants>

This integrates L<ExtUtils::Constant|ExtUtils::Constant> into the C<add_xs> command.

=back

=item * L<Dist::Build::ShareDir>

This allows one to install sharedirs

=item * L<Dist::Build::XS::Export>

This allows one to export headers and flags, to be imported by L<Dist::Build::XS::Import|Dist::Build::XS::Import>

=item * L<Dist::Build::DynamicPrereqs>

This allows one to dynamically evaluate dependencies.

=item * L<Dist::Build::Core>

This module contains all commands used for the base actions of the module.

=back

=head1 DELEGATES

All the usual delegates of the L<ExtUtils::Builder::CPAN::Tool> are defined on your L<planner|ExtUtils::Builder::Planner>, and additionally C<install_paths>.

=over 4

=item * meta

A L<CPAN::Meta|CPAN::Meta> object representing the C<META.json> file.

=item * distribution

The name of the distribution

=item * version

The version of the distribution

=item * main_module

The main module of the distribution.

=item * release_status

The release status of the distribution (e.g. C<'stable'>).

=item * perl_path

The path to the perl executable.

=item * config

The L<ExtUtils::Config|ExtUtils::Config> object for this build

=item * install_paths

The L<ExtUtils::InstallPaths|ExtUtils::InstallPaths> object for this build.

=item * is_os(@os_names)

This returns true if the current operating system matches any of the listed ones.

=item * is_os_type($os_type)

This returns true if the type of the OS matches C<$os_type>. Legal values are C<Unix>, C<Windows> and C<VMS>.

=item * verbose

The value of the C<verbose> command line argument.

=item * uninst

The value of the C<uninst> command line argument.

=item * jobs

The value of the C<jobs> command line argument.

=item * pureperl_only

The value of the C<pureperl_only> command line argument.

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
