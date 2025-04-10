package ExtUtils::Builder::AutoDetect::C;
$ExtUtils::Builder::AutoDetect::C::VERSION = '0.028';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

use Carp 'croak';
use ExtUtils::Config 0.007;
use ExtUtils::Helpers 0.027 'split_like_shell';
use File::Spec::Functions 'catfile';
use Perl::OSType 'is_os_type';

sub _split_conf {
	my ($config, $name) = @_;
	return split_like_shell($config->get($name));
}

sub _make_command {
	my ($self, $shortname, $argument, $command, %options) = @_;
	my $module = "ExtUtils::Builder::$shortname";
	require_module($module);
	my @command = ref $command ? @{$command} : split_like_shell($command);
	return $module->new($argument => \@command, %options);
}

sub _is_gcc {
	my ($config, $cc, $opts) = @_;
	return $config->get('gccversion') || $cc =~ / ^ g(?: cc | [+]{2} ) /ix;
}

sub _filter_args {
	my ($opts, @names) = @_;
	return map { $_ => $opts->{$_} } grep { exists $opts->{$_} } @names;
}

sub _get_compiler {
	my ($self, $opts) = @_;
	my $os = $opts->{config}->get('osname');
	my $cc = $opts->{config}->get('cc');
	my ($module, %extra) = is_os_type('Unix', $os) || _is_gcc($opts->{config}, $cc, $opts) ? 'Unixy' : is_os_type('Windows', $os) ? ('MSVC', language => 'C') : croak 'Your platform is not supported yet';
	my %args = _filter_args($opts, qw/language type/);
	$args{cccdlflags} = [ _split_conf($opts->{config}, 'cccdlflags') ];
	return ("Compiler::$module", cc => $cc, %extra, %args);
}

sub require_module {
	my $module = shift;
	(my $filename = "$module.pm") =~ s{::}{/}g;
	require $filename;
	return $module;
}

sub add_compiler {
	my ($self, $planner, %opts) = @_;
	my $as = $opts{as} // 'compile';
	return $planner->add_delegate($as, sub {
		my ($planner, $from, $to, %extra) = @_;
		my %args = (%opts, %extra);
		my $compiler = $self->_make_command($self->_get_compiler(\%args));

		$args{profiles} = [ delete $args{profile} ] if $args{profile} and not $args{profiles};
		if (my $profiles = $args{profiles}) {
			for my $profile (@$profiles) {
				if (not ref($profile)) {
					$profile =~ s/ \A @ /ExtUtils::Builder::Profile::/xms;
					require_module($profile);
				}
				$profile->process_compiler($compiler, \%args);
			}
		}

		if (my $include_dirs = $args{include_dirs}) {
			$compiler->add_include_dirs($include_dirs);
		}
		if (my $defines = $args{defines}) {
			$compiler->add_defines($defines);
		}
		if (my $extra = $args{extra_args}) {
			$compiler->add_argument(value => $extra);
		}

		my $node = $compiler->compile($from, $to, %args);
		$planner->add_node($node);
	});
}

sub _unix_flags {
	my ($self, $opts) = @_;
	return $opts->{lddlflags} if defined $opts->{lddlflags};
	my $lddlflags = $opts->{config}->get('lddlflags');
	my $optimize = $opts->{config}->get('optimize');
	$lddlflags =~ s/ ?\Q$optimize// if not $self->{auto_optimize};
	my %ldflags = map { ($_ => 1) } _split_conf($opts->{config}, 'ldflags');
	my @lddlflags = grep { not $ldflags{$_} } split_like_shell($lddlflags);
	my @cc = _split_conf($opts->{config}, 'ccdlflags');
	return (cc => \@cc, lddlflags => \@lddlflags )
}

sub _get_linker {
	my ($self, $opts) = @_;
	my $os = $opts->{config}->get('osname');
	my %args = _filter_args($opts, qw/type export language/);
	my $cc = $opts->{config}->get('cc');
	my $ld = $opts->{config}->get('ld');
	my $eff_ld = $args{type} eq 'executable' ? $cc : $ld;
	my ($module, $link, %opts) =
		$args{type} eq 'static-library' ? ('Ar', $opts->{config}->get('ar')) :
		$os eq 'darwin' ? ('Mach::GCC', $eff_ld) :
		_is_gcc($opts->{config}, $ld, $opts) ?
		$os eq 'MSWin32' ? ('PE::GCC', $cc) : ('ELF::GCC', $eff_ld) :
		$os eq 'aix' ? ('XCOFF', $cc) :
		is_os_type('Unix', $os) ? ('ELF', $eff_ld, $self->_unix_flags($opts)) :
		$os eq 'MSWin32' ? ('PE::MSVC', $ld) :
		croak 'Linking is not supported yet on your platform';
	return ("Linker::$module", ld => $link, %opts, %args);
}

sub add_linker {
	my ($self, $planner, %opts) = @_;
	my $as = $opts{as} // 'link';
	return $planner->add_delegate($as, sub {
		my ($planner, $from, $to, %extra) = @_;
		my %args = (%opts, %extra);
		my $linker = $self->_make_command($self->_get_linker(\%args));

		$args{profiles} = [ delete $args{profile} ] if $args{profile} and not $args{profiles};
		if (my $profiles = $args{profiles}) {
			for my $profile (@$profiles) {
				if (ref($profile)) {

				} else {
					$profile =~ s/ \A @ /ExtUtils::Builder::Profile::/xms;
					require_module($profile);
					$profile->process_linker($linker, \%args);
				}
			}
		}

		if (my $library_dirs = $args{library_dirs}) {
			$linker->add_library_dirs($library_dirs);
		}
		if (my $libraries = $args{libraries}) {
			$linker->add_libraries($libraries);
		}
		if (my $extra_args = $args{extra_args}) {
			$linker->add_argument(ranking => 85, value => [ @{$extra_args} ]);
		}

		my $node = $linker->link($from, $to, %args);
		$planner->add_node($node);
	});
}

sub add_methods {
	my ($class, $planner, %opts) = @_;

	$opts{config} //= $planner->can('config') ? $planner->config : ExtUtils::Config->new;
	$opts{type} //= 'executable';

	my $as_compiler = delete $opts{as_compiler};
	$class->add_compiler($planner, %opts, as => $as_compiler);

	my $as_linker = delete $opts{as_linker};
	$class->add_linker($planner, %opts, as => $as_linker);

	my $o = $opts{config}->get('_o');
	$planner->add_delegate('obj_file', sub {
		my ($planner, $file, $dir) = @_;
		my $filename = "$file$o";
		return defined $dir ? catfile($dir, $filename) : $filename;
	});

	my $dlext = $opts{config}->get('dlext');

	$planner->add_delegate('loadable_file', sub {
		my ($planner, $file, $dir) = @_;
		my $filename = "$file.$dlext";
		return defined $dir ? catfile($dir, $filename) : $filename;
	});

	my $so = $opts{config}->get('so');
	$planner->add_delegate('library_file', sub {
		my ($planner, $file, $dir) = @_;
		my $filename = "$file.$so";
		return defined $dir ? catfile($dir, $filename) : $filename;
	});

	my $exe = $opts{config}->get('_exe');
	$planner->add_delegate('exe_file', sub {
		my ($planner, $file, $dir) = @_;
		my $filename = "$file$exe";
		return defined $dir ? catfile($dir, $filename) : $filename;
	});

	return;
}

1;

#ABSTRACT: compiler configuration, derived from perl's configuration

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::AutoDetect::C - compiler configuration, derived from perl's configuration

=head1 VERSION

version 0.028

=head1 SYNOPSIS

 my $planner = ExtUtils::Builder::Planner->new;
 $planner->load_extension('ExtUtils::Builder::AutoDetect::C', '0.001',
	profiles => ['@Perl'],
	type     => 'loadable-object',
 );
 $planner->compile('foo.c', 'foo.o', include_dirs => ['.']);
 $planner->link([ 'foo.o' ], 'foo.so', libraries => ['foo']);
 my $plan = $planner->materialize;
 $plan->run(['foo.so']);

=head1 DESCRIPTION

This module is a L<ExtUtils::Builder::Planner::Extension|ExtUtils::Builder::Planner::Extension> that facilitates compiling object.

=head1 METHODS

=head2 add_methods(%options)

This adds two delegate methods to the planner, C<compile> and C<link>. It takes named arguments that will be prefixed to the named arguments for all delegate calls. In practice, it's mainly useful with the C<config>, C<profile> and C<type> arguments.

If your C<$planner> has a C<config> delegate, that will be used as default value for C<config>.

This is usually not called directly, but through L<ExtUtils::Builder::Planner|ExtUtils::Builder::Planner>'s C<load_extension> method.

=head2 link(\@sources, $target, %options)

=over 4

=item type

This works the same as with C<compile>.

=item config

This works the same as with C<compile>.

=item profile

This works the same as with C<compile>.

=item libraries

A list of libraries to link to. E.g. C<['z']>.

=item library_dirs

A list of directories to find libraries in. E.g. C<['/opt/my-app/lib/']>.

=item extra_args

A list of additional arguments to the linker.

=back

=head1 DELEGATES

=head2 compile($source, $target, %options)

This compiles C<$source> to C<$target>. It takes the following optional arguments:

=over 4

=item type

The type of the final product. This must be one of:

=over 4

=item * executable

An executable to be run. This is the default.

=item * static-library

A static library to link against.

=item * dynamic-library

A dynamic library to link against.

=item * loadable-object

A loadable extension. On most platforms this is the same as a dynamic library, but some (Mac) make a distinction between these two.

=back

=item config

A Perl configuration to take hints from, must be an C<ExtUtils::Config> compatible object.

=item profiles

A list of profile that can be used when compiling and linking. One profile comes with this distribution: C<'@Perl'>, which sets up the appropriate things to compile/link with C<libperl>.

=item include_dirs

A list of directories to add to the include path, e.g. C<['include', '.']>.

=item define

A hash of preprocessor defines, e.g. C<< {DEBUG => 1, HAVE_FEATURE => 0 } >>

=item extra_args

A list of additional arguments to the compiler.

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
