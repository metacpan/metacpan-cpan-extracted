package ExtUtils::Builder::BuildTools::FromPerl;
$ExtUtils::Builder::BuildTools::FromPerl::VERSION = '0.035';
use strict;
use warnings;

use parent 'ExtUtils::Builder::BuildTools::Base';

use Carp 'croak';
use ExtUtils::Config 0.007;
use ExtUtils::Builder::Util 0.018 qw/require_module split_like_shell/;
use Perl::OSType 'is_os_type';

sub _is_gcc {
	my ($config, $cc, $opts) = @_;
	return $config->get('gccversion') || $cc =~ / ^ (?: gcc | g[+]{2} | clang (?: [+]{2} ) ) /ix;
}

my %gpp_map = (
	'cc' => 'c++',
	'gcc' => 'g++',
	'clang' => 'clang++',
);
my %is_gpp = reverse %gpp_map;

sub make_compiler {
	my ($self, $opts) = @_;
	my $os = $opts->{config}->get('osname');
	my $raw_cc = $opts->{config}->get('cc');
	my ($cc, @cc_extra) = ref $raw_cc ? @{$raw_cc} : split_like_shell($raw_cc);
	my ($module, %command) = is_os_type('Unix', $os) || _is_gcc($opts->{config}, $cc) ? 'Unixy' : is_os_type('Windows', $os) ? ('MSVC', language => 'C') : croak 'Your platform is not supported yet';
	$command{$_} = $opts->{$_} for grep { exists $opts->{$_} } qw/language type/;
	$command{cccdlflags} = [ split_like_shell($opts->{config}->get('cccdlflags')) ];
	my $module_name = "ExtUtils::Builder::Compiler::$module";

	my $language = $opts->{language} // 'C';
	if (uc $language eq 'C++') {
		if ($module_name->isa('ExtUtils::Builder::Compiler::Unixy')) {
			push @{ $command{extra_flags} }, qw/-xc++/ if _is_gcc($opts->{config}, $cc);
			$cc = $gpp_map{$cc} // croak "Don't know C++ compiler for $cc" unless $is_gpp{$cc};
		} elsif (!$module_name->isa('ExtUtils::Builder::Compiler::MSVC')) {
			croak "Can't find C++ compiler for your platform"
		}
	} elsif (uc $language ne 'C') {
		croak "Unknown language $language";
	}

	require_module($module_name);
	return $module_name->new(cc => [$cc, @cc_extra], %command);
}

sub _unix_flags {
	my ($self, $opts) = @_;
	return $opts->{lddlflags} if defined $opts->{lddlflags};
	my $lddlflags = $opts->{config}->get('lddlflags');
	my $optimize = $opts->{config}->get('optimize');
	$lddlflags =~ s/ ?\Q$optimize// if not $opts->{auto_optimize};
	my %ldflags = map { ($_ => 1) } split_like_shell($opts->{config}->get('ldflags'));
	my @lddlflags = grep { not $ldflags{$_} } split_like_shell($lddlflags);
	return (lddlflags => \@lddlflags )
}

sub make_linker {
	my ($self, $opts) = @_;
	my $os = $opts->{config}->get('osname');
	my $raw_cc = $opts->{config}->get('cc');
	my ($cc, @cc_extra) = ref $raw_cc ? @{$raw_cc} : split_like_shell($raw_cc);
	my $raw_ld = $opts->{config}->get('ld');
	my ($ld, @ld_extra) = ref $raw_ld ? @{$raw_ld} : split_like_shell($raw_ld);
	my ($eff_ld, @eff_extra) = ($opts->{type} eq 'executable') ? ($cc, @cc_extra) : ($ld, @ld_extra);
	my ($module, $link, $extra, %command) =
		$opts->{type} eq 'static-library' ? ('Ar', $opts->{config}->get('ar')) :
		$os eq 'darwin' ? ('Mach::GCC', $eff_ld, \@eff_extra) :
		_is_gcc($opts->{config}, $ld) ?
		$os eq 'MSWin32' ? ('PE::GCC', $cc, \@cc_extra) : ('ELF::GCC', $eff_ld, \@eff_extra) :
		$os eq 'aix' ? ('XCOFF', $cc, \@cc_extra) :
		is_os_type('Unix', $os) ? ('ELF::Any', $eff_ld, \@eff_extra, $self->_unix_flags($opts)) :
		$os eq 'MSWin32' ? ('PE::MSVC', $ld, \@ld_extra) :
		croak 'Linking is not supported yet on your platform';
	$command{$_} = $opts->{$_} for grep { exists $opts->{$_} } qw/exports language type/;
	my $module_name = "ExtUtils::Builder::Linker::$module";

	my $language = $opts->{language} // 'C';
	if (uc $language eq 'C++') {
		my $prefix = 'ExtUtils::Builder::Linker:';
		if ($module->isa("$prefix:ELF::GCC") || $module->isa("$prefix:Mach::GCC") || $module->isa("$prefix:PE::GCC")) {
			$link = $gpp_map{$link} // croak "Don't know C++ compiler for $link" unless $is_gpp{$link};
		} elsif (!$module->isa("$prefix:PE::MSVC") && !$module->isa("$prefix:Ar")) {
			croak "Can't find C++ linker for your platform"
		}
	} elsif (uc $language ne 'C') {
		croak "Unknown language $language";
	}

	require_module($module_name);
	return $module_name->new(ld => [ $link, @{$extra} ], %command);
}

sub add_methods {
	my ($class, $planner, %opts) = @_;

	$opts{config} //= $planner->can('config') ? $planner->config : ExtUtils::Config->new;
	my $os = $opts{config}->get('osname');
	my $lib_prefix = is_os_type('Unix', $os) ? 'lib' : '';

	$class->SUPER::add_methods($planner,
		object_file         => '%s' . $opts{config}->get('_o'),
		library_file        => "$lib_prefix%s." . $opts{config}->get('so'),
		static_library_file => "$lib_prefix%s" . $opts{config}->get('_a'),
		loadable_file       => '%s.' . $opts{config}->get('dlext'),
		executable_file     => '%s' . $opts{config}->get('_exe'),
		%opts,
	);

	# backwards compatability
	$planner->add_delegate('obj_file', sub {
		my ($this, @args) = @_;
		return $this->object_file(@args);
	});

	return;
}

1;

#ABSTRACT: compiler configuration, derived from perl's configuration

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::BuildTools::FromPerl - compiler configuration, derived from perl's configuration

=head1 VERSION

version 0.035

=head1 SYNOPSIS

 my $planner = ExtUtils::Builder::Planner->new;
 $planner->load_extension('ExtUtils::Builder::BuildTools::FromPerl', 0.034,
	 config => $config,
 );
 my $foo_o = $planner->object_name('foo');
 $planner->compile('foo.c', $foo_o, include_dirs => ['.']);
 my $foo_exe = $planner->executable_name('foo');
 $planner->link([ 'foo.o' ], $foo_exe, libraries => ['foo']);
 my $plan = $planner->materialize;
 $plan->run($foo_exe);

=head1 DESCRIPTION

This module is a L<ExtUtils::Builder::Planner::Extension|ExtUtils::Builder::Planner::Extension> that facilitates compiling object. It takes one named argument: C<config>, an L<ExtUtils::Config> (compatible) object.

=head1 METHODS

=head2 add_methods(%options)

This adds two delegate methods to the planner, C<compile> and C<link>. It takes named arguments that will be prefixed to the named arguments for all delegate calls. In practice, it's mainly useful with the C<config>, C<profile> and C<type> arguments.

If your C<$planner> has a C<config> delegate, that will be used as default value for C<config>.

This is usually not called directly, but through L<ExtUtils::Builder::Planner|ExtUtils::Builder::Planner>'s C<load_extension> method.

=head1 DELEGATES

It inherits the following delegates from L<ExtUtils::Builder::BuildTools::Base>.

=over 4

=item compile($source, $target, %options)

=item link(\@sources, $target, %options)

=item object_file($basename, $dir = undef)

=item library_file($basename, $dir = undef)

=item static_library_file($basename, $dir = undef)

=item loadable_file($basename, $dir = undef)

=item executable_file($basename, $dir = undef)

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
