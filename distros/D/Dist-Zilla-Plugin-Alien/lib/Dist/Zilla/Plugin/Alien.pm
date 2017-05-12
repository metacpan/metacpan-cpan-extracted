package Dist::Zilla::Plugin::Alien;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Use Alien::Base with Dist::Zilla
$Dist::Zilla::Plugin::Alien::VERSION = '0.023';
use Moose;
extends 'Dist::Zilla::Plugin::ModuleBuild';
with 'Dist::Zilla::Role::PrereqSource', 'Dist::Zilla::Role::FileGatherer', 'Dist::Zilla::Role::MetaProvider';


use URI;

has name => (
	isa => 'Str',
	is => 'rw',
	lazy_build => 1,
);
sub _build_name {
	my ( $self ) = @_;
	my $name = $self->zilla->name;
	$name =~ s/^Alien-//g;
	return $name;
}

has bins => (
	isa => 'Str',
	is => 'rw',
	predicate => 'has_bins',
);

has split_bins => (
	isa => 'ArrayRef',
	is => 'rw',
	lazy_build => 1,
);
sub _build_split_bins { $_[0]->has_bins ? [split(/\s+/,$_[0]->bins)] : [] }

has repo => (
	isa => 'Str',
	is => 'rw',
	required => 1,
);

has repo_uri => (
	isa => 'URI',
	is => 'rw',
	lazy_build => 1,
);
sub _build_repo_uri {
	my ( $self ) = @_;
	URI->new($self->repo);
}

has pattern_prefix => (
	isa => 'Str',
	is => 'rw',
	lazy_build => 1,
);
sub _build_pattern_prefix {
	my ( $self ) = @_;
	return $self->name.'-';
}

has pattern_version => (
	isa => 'Str',
	is => 'rw',
	lazy_build => 1,
);
sub _build_pattern_version { '([\d\.]+)' }

has pattern_suffix => (
	isa => 'Str',
	is => 'rw',
	lazy_build => 1,
);
sub _build_pattern_suffix { '\\.tar\\.gz' }

has pattern => (
	isa => 'Str',
	is => 'rw',
	lazy_build => 1,
);
sub _build_pattern {
	my ( $self ) = @_;
	join("",
		$self->pattern_prefix.
		$self->pattern_version.
		$self->pattern_suffix
	);
}

has exact_filename => (
	isa => 'Str',
	is  => 'rw',
);

has build_command => (
	isa => 'ArrayRef[Str]',
	is => 'rw',
);

has install_command => (
	isa => 'ArrayRef[Str]',
	is => 'rw',
);

has test_command => (
	isa => 'ArrayRef[Str]',
	is => 'rw',
);

has isolate_dynamic => (
	isa => 'Int',
	is => 'rw',
);

has autoconf_with_pic => (
	isa => 'Int',
	is => 'rw',
);

has inline_auto_include => (
	isa => 'ArrayRef[Str]',
	is => 'rw',
	default => sub { [] },
);

has msys => (
        isa => 'Int',
        is  => 'rw',
);

has bin_requires => (
        isa => 'ArrayRef[Str]',
        is  => 'rw',
        default => sub { [] },
);

sub _bin_requires_hash {
	my($self) = @_;
	my %bin_requires = map { /^\s*(.*?)\s*=\s*(.*)\s*$/ ? ($1 => $2) : ($_ => 0) } @{ $self->bin_requires };
	\%bin_requires;
}

has helper => (
	isa => 'ArrayRef[Str]',
	is  => 'rw',
	default => sub { [] },
);

sub _helper_hash {
	my($self) = @_;
	my %helper = map { /^\s*(.*?)\s*=\s*(.*)\s*$/ ? ($1 => $2) : ($_ => '') } @{ $self->helper };
	\%helper;
}

has env => (
	isa => 'ArrayRef[Str]',
	is => 'rw',
	default => sub { [] },
);

sub _env_hash {
	my($self) = @_;
	my %env = map {
	  /^\s*(.*?)\s*=\s*(.*)\s*$/ 
	    ? ($1 => $2) 
	    : $self->log_fatal("Please specify a value for $_")
	  } @{ $self->env };
	\%env;
}

has stage_install => (
	isa => 'Int',
	is  => 'rw',
);

has provides_cflags => (
	isa => 'Str',
	is  => 'rw',
);

has provides_libs => (
	isa => 'Str',
	is  => 'rw',
);

has version_check => (
	isa => 'Str',
	is  => 'rw',
);

# multiple build/install commands return as an arrayref
around mvp_multivalue_args => sub {
  my ($orig, $self) = @_;
  return ($self->$orig, 'build_command', 'install_command', 'test_command', 'inline_auto_include', 'bin_requires', 'helper', 'env');
};

sub register_prereqs {
	my ( $self ) = @_;

	my $ab_version = '0.002';

	if(defined $self->isolate_dynamic || defined $self->autoconf_with_pic || grep /(?<!\%)\%c/, @{ $self->build_command || [] }) {
		$ab_version = '0.005';
	}

	if(@{ $self->inline_auto_include } || @{ $self->bin_requires } || defined $self->msys) {
		$ab_version = '0.006';
	}
	
	if(defined $self->stage_install) {
		$ab_version = '0.016';
	}
	
	if(@{ $self->helper } || grep /(?<!\%)\%\{([a-zA-Z_][a-zA-Z_0-9]+)\}/, @{ $self->build_command || [] }, @{ $self->install_command || [] }, @{ $self->test_command || [] } ) {
		$ab_version = '0.020';
	}

	if(@{ $self->env } || grep /(?<!\%)\%X/, @{ $self->build_command || [] }, @{ $self->install_command || [] }, @{ $self->test_command || [] } ) {
		$ab_version = '0.027';
	}

	$self->zilla->register_prereqs({
			type  => 'requires',
			phase => 'configure',
		},
		'Alien::Base::ModuleBuild' => $ab_version,
		'File::ShareDir' => '1.03',
		@{ $self->split_bins } > 0 ? ('Path::Class' => '0.013') : (),
	);
	$self->zilla->register_prereqs({
			type  => 'requires',
			phase => 'runtime',
		},
		'Alien::Base' => $ab_version,
		'File::ShareDir' => '1.03',
		@{ $self->split_bins } > 0 ? ('Path::Class' => '0.013') : (),
	);
}

has "+mb_class" => (
	default => 'Alien::Base::ModuleBuild',
);

after gather_files => sub {
	my ( $self ) = @_;

	my $template = <<'__EOT__';
#!/usr/bin/env perl
# PODNAME: {{ $bin }}
# ABSTRACT: Command {{ $bin }} of {{ $dist->name }}

$|=1;

use strict;
use warnings;
use File::ShareDir ':ALL';
use Path::Class;

my $abs = file(dist_dir('{{ $dist->name }}'),'bin','{{ $bin }}')->cleanup->absolute;

exec($abs, @ARGV) or print STDERR "couldn't exec {{ $bin }}: $!";

__EOT__

	for (@{$self->split_bins}) {
		my $content = $self->fill_in_string(
			$template,
			{
				dist => \($self->zilla),
				bin => $_,
			},
		);

		my $file = Dist::Zilla::File::InMemory->new({
			content => $content,
			name => 'bin/'.$_,
			mode => 0755,
		});

		$self->add_file($file);
	}
};

around module_build_args => sub {
	my ($orig, $self, @args) = @_;
	my $pattern = $self->pattern;
	my $exact_filename = $self->exact_filename;

	my $bin_requires = $self->_bin_requires_hash;
	my $helper       = $self->_helper_hash;
	my $env          = $self->_env_hash;

	return {
		%{ $self->$orig(@args) },
		alien_name => $self->name,
		alien_repository => {
			protocol => $self->repo_uri->scheme eq 'file'
				? 'local'
				: $self->repo_uri->scheme,
			host => $self->repo_uri->can('port') # local files do not have port
				? ( $self->repo_uri->default_port == $self->repo_uri->port
					? $self->repo_uri->host
					: $self->repo_uri->host_port )
				: '',
			location => $self->repo_uri->path,
			# NOTE Not using a compiled regex here for serialisation
			# in case it adds flags not in older versions of perl.
			# In particular, the compiled regex was adding the u
			# modifier, but then getting serialised as
			# (?^u:$pattern) which fails to parse under perl less
			# than v5.014.
			defined $exact_filename ? (exact_filename => $exact_filename) : (pattern => "^$pattern\$"),
		},
		(alien_build_commands => $self->build_command)x!! $self->build_command,
		(alien_install_commands => $self->install_command)x!! $self->install_command,
		(alien_test_commands => $self->test_command)x!! $self->test_command,
		(alien_inline_auto_include => $self->inline_auto_include)x!! $self->inline_auto_include,
		defined $self->autoconf_with_pic ? (alien_autoconf_with_pic => $self->autoconf_with_pic) : (),
		defined $self->isolate_dynamic ? (alien_isolate_dynamic => $self->isolate_dynamic) : (),
		defined $self->msys ? (alien_msys => $self->msys) : (),
		defined $self->stage_install ? (alien_stage_install => $self->stage_install) : (),
		defined $self->provides_libs ? (alien_provides_libs => $self->provides_libs) : (),
		defined $self->version_check ? (alien_version_check => $self->version_check) : (),
		defined $self->provides_cflags ? (alien_provides_cflags => $self->provides_cflags) : (),
		%$bin_requires ? ( alien_bin_requires => $bin_requires ) : (),
		%$helper ? ( alien_helper => $helper ): (),
		%$env ? ( alien_env => $env ) : (),
	};
};

sub _is_dynamic_config {
	my($self) = @_;
	%{ $self->_bin_requires_hash } || $self->msys || @{ $self->build_command || [] } == 0 || grep /(?<!\%)\%c/, @{ $self->build_command || [] };
}

sub metadata {
	my($self) = @_;
	$self->_is_dynamic_config ? { dynamic_config => 1 } : {};
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::Alien - Use Alien::Base with Dist::Zilla

=head1 VERSION

version 0.023

=head1 SYNOPSIS

In your I<dist.ini>:

  name = Alien-myapp

  [Alien]
  repo = http://myapp.org/releases
  bins = myapp myapp_helper
  # the following parameters are based on the dist name automatically
  name = myapp
  pattern_prefix = myapp-
  pattern_version = ([\d\.]+)
  pattern_suffix = \.tar\.gz
  pattern = myapp-([\d\.]+)\.tar\.gz

  # commands used to build (optional)
  build_command = %c --prefix=%s
  # ...

  # commands uses to install (optional)
  install_command = make install

=head1 DESCRIPTION

This is a simple wrapper around Alien::Base, to make it very simple to
generate a distribution that uses it. You only need to make a module like
in this case Alien::myapp which extends Alien::Base and additionally a url
that points to the path where the downloadable .tar.gz of the application
or library can be found. For more informations about the parameter, please
checkout also the L<Alien::Base> documentation. The I<repo> paramter is
automatically taken apart to supply the procotol, host and other parameters
for L<Alien::Base>.

B<Warning>: Please be aware that L<Alien::Base> uses L<Module::Build>, which
means you shouldn't have L<Dist::Zilla::Plugin::MakeMaker> loaded. For our
case, this means, you can't just easily use it together with the common
L<Dist::Zilla::PluginBundle::Basic>, because this includes it. As alternative
you can use L<Dist::Zilla::PluginBundle::Alien> which is also included in this
distribution.

=head1 ATTRIBUTES

=head2 repo

The only required parameter, defines the path for the packages of the product
you want to alienfy. This must not include the filename.

To indicate a local repository use the C<file:> scheme:

   # located in the base directory
   repo = file:.

   # located in the inc/ directory relative to the base
   repo = file:inc

=head2 pattern

The pattern is used to define the filename to be expected from the repo of the
alienfied product. It is set together out of I<pattern_prefix>,
I<pattern_version> and I<pattern_suffix>. I<pattern_prefix> is by default
L</name> together with a dash.

=head2 exact_filename

Instead of providing a pattern you may use this to set the exact filename.

=head2 bins

A space or tab seperated list of all binaries that should be wrapped to be executable
from the perl environment (if you use perlbrew or local::lib this also
guarantees that its available via the PATH).

=head2 name

The name of the Alien package, this is used for the pattern matching filename.
If none is given, then the name of the distribution is used, but the I<Alien->
is cut off.

=head2 build_command

The ordered sequence of commands used to build the distribution (passed to the
C<alien_build_commands> option). This is optional.

  # configure then make
  build_command = %c --prefix=%s
  build_command = make

=head2 install_command

The ordered sequence of commands used to install the distribution (passed to the
C<alien_install_commands> option). This is optional.

  install_command = make install

=head2 test_command

The ordered sequence of commands used to test the distribution (passed to the
C<alien_test_commands> option).  This is optional, and not often used.

  test_command = make check

=head2 isolate_dynamic

If set to true, then dynamic libraries will be isolated from the static libraries
when C<install_type=share> is used.  This is recommended for XS modules where
static libraries are more reliable.  Dynamic libraries (.dll, .so, etc) are still
available and can easily be used by FFI modules.

  isolate_dynamic = 1

Usage of this attribute will bump the requirement of L<Alien::Base> up to 0.005
for your distribution.

=head2 autoconf_with_pic

If set to true (the default), then C<--with-pic> will be passed to autoconf style
C<configure> scripts.  This usually enables position independent code which is
desirable if you are using static libraries to build XS modules.  Usually, if the
autoconf does not recognize C<--with-pic> it will ignore it, but some C<configure>
scripts which are not managed by autoconf may complain and die with this option.

  ; only if you know configure will die with --with-pic
  autoconf_with_pic = 0

Usage of this attribute will bump the requirement of L<Alien::Base> up to 0.005
for your distribution.

=head2 inline_auto_include

List of header files to automatically include (see L<Inline::C#auto_include>) when
the Alien module is used with L<Inline::C> or L<Inline::CPP>.

=head2 msys

Force the use of L<Alien::MSYS> when building on Windows.  Normally this is only
done if L<Alien::Base::ModuleBuild> can detect that you are attempting to use
an autotools style C<configure> script.

=head2 bin_requires

Require the use of a binary tool Alien distribution.  You can optionally specify
a version using the equal C<=> sign.

 [Alien]
 bin_requires = Alien::patch
 bin_requires = Alien::gmake = 0.03

=head2 stage_install

If set to true, Alien packages are installed directly into the blib
directory by the `./Build' command rather than to the final location during the
`./Build install` step.

=head2 helper

Defines helpers.  You can specify the content of the helper (which will be evaluated
in L<Alien::Base::ModuleBuild> during the build/install step) using the equal C<=> sign.

 [Alien]
 helper = mytool = '"mytool --foo --bar"'

=head2 provides_cflags

Sets the C<alien_provides_cflags> property for L<Alien::Base::ModuleBuild>.

=head2 provides_libs

Sets the C<alien_provides_libs> property for L<Alien::Base::ModuleBuild>.

=head2 version_check

Sets the C<alien_version_check> property for L<Alien::Base::ModuleBuild>.

=head2 env

Sets the C<alien_env> property for L<Alien::Base::ModuleBuild>.  You can specify
the content of the environment using the equal C<=> sign.  Note that values
are interpolated, and allow variables and helpers.

 [Alien]
 helper = path = 'require Config;$Config{path_sep}$ENV{PATH}'
 ; sets PATH to /extra/path:$PATH on UNIX, /extra/path;$PATH on Windows
 env = PATH = /extra/path%{path}
 ; sets FOO to 1
 env = FOO = 1

There is no default value, so this is illegal:

 [Alien]
 ; won't build!
 env = FOO

Note that setting an environment variable to the empty string (C<''>) is not
portable.  In particular it will work on Unix as you might expect, but in
Windows it will actually unset the environment variable, which may not be
what you intend.

 [Alien]
 ; works but not consistent
 ; over all platforms
 env = FOO =

=head1 InstallRelease

The method L<Alien::Base> is using would compile the complete Alien 2 times, if
you use it in combination with L<Dist::Zilla::Plugin::InstallRelease>. One time
at the test, and then again after release. With a small trick, you can avoid
this. You can use L<Dist::Zilla::Plugin::Run> to add an additional test which
installs out of the unpacked distribution for the testing:

  [Run::Test]
  run_if_release = ./Build install

This will do the trick :). Be aware, that you need to add this plugin after
I<[ModuleBuild]>. You can use L<Dist::Zilla::PluginBundle::Author::GETTY>,
which directly use this trick in the right combination.

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
