package ExtUtils::Builder::CPAN::Tool;
$ExtUtils::Builder::CPAN::Tool::VERSION = '0.019';
use 5.010;
use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

sub add_methods {
	my (undef, $planner, %args) = @_;

	$planner->add_delegate('config', sub {
		require ExtUtils::Config;
		state $config = ExtUtils::Config->new;
	});

	$planner->add_delegate('meta', sub {
		require CPAN::Meta;
		state $meta = CPAN::Meta->load_file('META.json');
	});

	$planner->add_delegate('distribution', sub {
		return $_[0]->meta->name;
	});
	$planner->add_delegate('release_status', sub {
		return $_[0]->meta->release_status;
	});
	$planner->add_delegate('version', sub {
		return version->new($_[0]->meta->version);
	});

	$planner->add_delegate('main_module', sub {
		state $main_module = do {
			my $distribution = $_[0]->distribution;
			$distribution =~ s/-/::/g;
			$distribution;
		};
	});

	$planner->add_delegate('perl_path', sub {
		require ExtUtils::Builder::Util;
		state $path = ExtUtils::Builder::Util::get_perl(config => $_[0]->config);
	});

	$planner->add_delegate($_, sub { !!0 }) for qw/verbose uninst pureperl_only/;
	$planner->add_delegate('jobs', sub { 1 });

	$planner->add_delegate('is_os', sub {
		my ($self, @wanted) = @_;
		return not not grep { $_ eq $^O } @wanted
	});
	$planner->add_delegate('is_os_type', sub {
		my ($self, $wanted) = @_;
		require Perl::OSType;
		return Perl::OSType::is_os_type($wanted);
	});

	$planner->add_delegate('new_planner', sub {
		my ($self, %options) = @_;
		my $config = $self->config;
		$config = $config->but($options{but}) if $options{but};
		require ExtUtils::Builder::Planner;
		my $inner = ExtUtils::Builder::Planner->new;
		$inner->add_delegate('config', sub { $config });
		return $inner;
	});
}

1;

# ABSTRACT: A base implementation for CPAN build scripts.

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::CPAN::Tool - A base implementation for CPAN build scripts.

=head1 VERSION

version 0.019

=head1 SYNOPSIS

 my $planner = ExtUtils::Builder::Planner->new;
 $planner->create_phony($_) for qw/code manify dynamic/;
 $planner->create_phony('all', qw/code manify dynamic/);
 $planner->load_extension('ExtUtils::Builder::CPAN::Tool');
 $planner->new_scope->run_dsl($_) for glob 'planner/*.pl';
 my $plan = $planner->materialize;
 $plan->run('all');

=head1 DESCRIPTION

This provides a base implementation of the CPAN build script protocol. Known specializations of this extension are L<Dist::Build> and L<ExtUtils::Builder::MakeMaker>. 

=head1 DELEGATES

=head2 config

The L<ExtUtils::Config|ExtUtils::Config> (or compatible) object for this build. 

=head2 meta

A L<CPAN::Meta|CPAN::Meta> object representing the metadata for this distribution. By default this will just load the F<META.json> in the current directory.

=head2 distribution

The name of the distribution

=head2 version

The version of the distribution (as a version object).

=head2 main_module

The main module of the distribution.

=head2 release_status

The release status of the distribution (e.g. C<'stable'>).

=head2 perl_path

The path to the perl executable.

=head2 is_os(@os_names)

This returns true if the current operating system matches any of the listed ones.

=head2 is_os_type($os_type)

This returns true if the type of the OS matches C<$os_type>. Legal values are C<Unix>, C<Windows> and C<VMS>.

=head2 verbose

The requested verbosity. By default this is a stub that always returns false.

=head2 uninst

The value of the C<uninst> command line argument. By default this is a stub that always returns false.

=head2 jobs

The requested number of jobs for this build. By default this is a stub that always returns C<1>.

=head2 pureperl_only

The value of the pureperl_only argument. By default this is a stub that always returns false.

=head2 new_planner.

This creates a new planner, sharing a configuration object with the current one.

=for Pod::Coverage add_methods

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
