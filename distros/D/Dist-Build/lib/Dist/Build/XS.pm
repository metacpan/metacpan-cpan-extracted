package Dist::Build::XS;
$Dist::Build::XS::VERSION = '0.025';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/catfile curdir/;
use Text::ParseWords 'shellwords';

sub get_flags {
	my ($raw) = @_;
	return $raw if not defined($raw) or ref($raw);
	return [ shellwords($raw) ]
}

sub add_methods {
	my ($self, $planner, %args) = @_;

	$planner->add_delegate('add_xs', sub {
		my ($planner, %args) = @_;

		my $pureperl_only = $args{pureperl_only} // $planner->pureperl_only;
		die "Can't build xs files under --pureperl-only\n" if $pureperl_only;

		$planner = $planner->new_scope;

		my $config = $args{config} // $planner->config;

		$planner->load_extension('ExtUtils::Builder::ParseXS',              0.034, config => $config) unless $planner->can('parse_xs');
		$planner->load_extension('ExtUtils::Builder::BuildTools::FromPerl', 0.034, config => $config) unless $planner->can('compile');

		my $xs_base = $args{xs_base} // 'lib';
		my ($module_name, $xs_file);
		if (defined $args{module}) {
			$module_name = $args{module};
			$xs_file = $args{file} // catfile($xs_base, split /::/, $module_name) . '.xs';
		} elsif (defined $args{file}) {
			$xs_file = $args{file};
			$module_name = $planner->module_for_xs($xs_file, $xs_base);
		} else {
			$module_name = $planner->main_module;
			$xs_file = catfile($xs_base, split /::/, $module_name) . '.xs';
		}

		my $source_dir = dirname($xs_file);
		my $c_file;

		my $language = $args{language} // 'C';

		if ($xs_file =~ /\.c$/) {
			$c_file = $xs_file;
		} else {
			$c_file = $planner->c_file_for_xs($xs_file, $source_dir);

			if (my $typemap = $args{typemap}) {
				my @typemaps = ref $args{typemap} ? @{ $typemap } : $typemap;
				$_ = rel2abs($_) for @typemaps;
				$args{typemap} = \@typemaps;
			}
			my %parse_args;
			$parse_args{$_} = $args{$_} for grep { exists $args{$_} } qw/typemap versioncheck prototypes/;
			$parse_args{dependencies} = $args{xs_dependencies} if exists $args{xs_dependencies};
			$parse_args{hiertypes} = 1 if uc $language eq 'C++';

			$planner->parse_xs($xs_file, $c_file, %parse_args, module => $module_name);
		}

		my $o_file = $planner->obj_file(basename($c_file, '.c'), $source_dir);

		my $module_version = $args{version} // $planner->version;

		my %defines = (
			%{ $args{defines} // {} },
			VERSION    => qq/"$module_version"/,
			XS_VERSION => qq/"$module_version"/,
		);

		my $compiler_flags = get_flags($args{extra_compiler_flags});
		$planner->compile($c_file, $o_file,
			type         => 'loadable-object',
			profiles     => ['@Perl'],
			defines      => \%defines,
			include_dirs => [ dirname($xs_file), @{ $args{include_dirs} // [] } ],
			extra_args   => $compiler_flags,
			dependencies => $args{dependencies},
			language     => $language,
			standard     => $args{standard},
		);

		my @objects = $o_file;

		for my $source (@{ $args{extra_sources} }) {
			my %options = ref $source ? %{ $source } : (source => $source);
			my $dirname = dirname($options{source});
			my $object  = $options{object} // $planner->obj_file(basename($options{source}, '.c'), $dirname);
			my %defines = (%{ $args{defines} // {} }, %{ $options{defines} // {} });
			my @include_dirs = (@{ $args{include_dirs} // [] }, @{ $options{include_dirs} // [] });
			my @compiler_flags = (@{ $compiler_flags // [] }, @{ $options{flags} // [] });
			my @dependencies = (@{ $args{dependencies} // [] }, @{ $options{dependencies} // [] });
			my $standard = exists $options{standard} ? $options{standard} : $args{standard};
			$planner->compile($options{source}, $object,
				type         => 'loadable-object',
				profiles     => ['@Perl'],
				defines      => \%defines,
				include_dirs => \@include_dirs,
				extra_args   => \@compiler_flags,
				dependencies => \@dependencies,
				language     => $language,
				standard     => $standard,
			);
			push @objects, $object;
		}

		push @objects, @{ $args{extra_objects} } if $args{extra_objects};

		my $lib_file = $planner->extension_filename($module_name);
		$planner->link(\@objects, $lib_file,
			type         => 'loadable-object',
			profiles     => ['@Perl'],
			module_name  => $module_name,
			mkdir        => 1,
			extra_args   => get_flags($args{extra_linker_flags}),
			library_dirs => $args{library_dirs},
			libraries    => $args{libraries},
			language     => $language,
		);

		$planner->create_phony('dynamic', $lib_file);

		return $lib_file;
	});

	$planner->add_delegate('auto_xs', sub {
		my ($planner, %args) = @_;

		my $dir = delete $args{dir} // 'lib';
		my $xs_files = $planner->create_pattern(
			dir  => $dir,
			file => '*.xs'
		);
		my $so_files = $planner->create_subst(
			on => $xs_files,
			subst => sub {
				my ($source) = @_;
				$planner->add_xs(
					%args,
					xs_base => $dir,
					module  => undef,
					file    => $source,
				);
			},
		);
		return;
	});
}

1;

# ABSTRACT: An XS implementation for Dist::Build

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Build::XS - An XS implementation for Dist::Build

=head1 VERSION

version 0.025

=head1 SYNOPSIS

 # planner/xs.pl

 load_extension('Dist::Build::XS');
 add_xs(
   module        => 'Foo::Bar',
   extra_sources => [ glob 'src/*.c' ],
   libraries     => [ 'foo' ],
 );

=head1 DESCRIPTION

This module implements support for XS for Dist::Build.

=head1 METHODS

=head2 add_xs

This method takes the following named arguments, all optional:

=over 4

=item * module

The name of the module to be compiled. This defaults to C<$main_module> unless C<file> is given, in which case the name is derived from the path.

=item * version

The version of the module, defaulting to the dist version.

=item * file

The name of the XS file. By default it's derived from the C<$module_name>, e.g. C<lib/Foo/Bar.xs> for C<Foo::Bar>.

=item * defines

This hash contains defines for the C files. E.g. C<< { DEBUG => 1 } >>.

=item * include_dirs

A list of directories to add to the include path. For the xs file the directory it is in is automatically added to this list.

=item * extra_sources

A list of C files to compile with this module. Instead of just a name, entries can also be a hash with the following entries:

=over 4

=item * source

The name of the input file. Mandatory.

=item * object

The name of the object that will be compiled. Will be derive from the source name by default.

=item * include_dirs

An array containing additional include directories for this objects

=item * defines

A hash containing additional defines for this object.

=item * flags

An array containing additional flags for this compilation.

=item * dependencies

An array containing additional dependencies for this compilation.

=back

=item * extra_objects

A list of object files to link with the module.

=item * extra_compiler_flags

Additional flags to feed to the compiler. This can either be an array or a (shell-quoted) string.

=item * extra_sources

Extra C files to compile with this module.

=item * library_dirs

Extra libraries to find libraries in.

=item * libraries

Libraries to link to.

=item * extra_linker_flags

Additional flags to feed to the compiler. This can either be an array or a (shell-quoted) string.

=back

=head2 auto_xs

This method is like C<add_xs>, except that instead of taking C<module> or C<file> named arguments, it takes a C<dir> argument (defaulting to C<'lib'>). It will search that directory for all XS files, and build them with the other arguments passed to this function.

=head1 EXTENSIONS

Various extensions exist that modify the behavior of C<add_xs>. Among these are:

=over 4

=item * L<Dist::Build::XS::Import|Dist::Build::XS::Import>

This adds an C<import> argument to imports include directories and compilation flags exported by other modules using L<Dist::Build::XS::Export|Dist::Build::XS::Export>.

=item * L<Dist::Build::XS::WriteConstants|Dist::Build::XS::WriteConstants>

This adds a C<write_constants> argument, integrating L<ExtUtils::Constant|ExtUtils::Constant>.

=item * L<Dist::Build::XS::Alien|Dist::Build::XS::Alien>

This adds an C<alien> argument to link to libraries using L<Alien::Base|Alien::Base>.

=item * L<Dist::Build::XS::PkgConfig|Dist::Build::XS::PkgConfig>

This adds a C<pkg_config> argument to link to libraries using C<pkg-config> files.

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
