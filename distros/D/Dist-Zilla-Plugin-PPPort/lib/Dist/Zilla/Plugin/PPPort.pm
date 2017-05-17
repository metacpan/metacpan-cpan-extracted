package Dist::Zilla::Plugin::PPPort;
# vi:noet:sts=2:sw=2:ts=2
$Dist::Zilla::Plugin::PPPort::VERSION = '0.008';
use Moose;
with qw/Dist::Zilla::Role::FileGatherer Dist::Zilla::Role::PrereqSource Dist::Zilla::Role::AfterBuild/;
use Moose::Util::TypeConstraints 'enum';
use MooseX::Types::Perl qw(StrictVersionStr);
use MooseX::Types::Stringlike 'Stringlike';
use Devel::PPPort 3.23;
use File::Spec::Functions 'catdir';
use File::pushd 'pushd';

has style => (
	is  => 'ro',
	isa => enum(['MakeMaker', 'ModuleBuild']),
	default => 'MakeMaker',
);

has filename => (
	is      => 'ro',
	isa     => Stringlike,
	lazy    => 1,
	coerce  => 1,
	default => sub {
		my $self = shift;
		if ($self->style eq 'MakeMaker') {
			return 'ppport.h';
		}
		elsif ($self->style eq 'ModuleBuild') {
			my @module_parts = split /-/, $self->zilla->name;
			return catdir('lib', @module_parts[0 .. $#module_parts - 1], 'ppport.h');
		}
		else {
			confess 'Invalid style for XS file generation';
		}
	}
);

has version => (
	is      => 'ro',
	isa     => StrictVersionStr,
	default => '3.23',
);

sub gather_files {
	my $self = shift;
	Devel::PPPort->VERSION($self->version);
	require Dist::Zilla::File::InMemory;
	$self->add_file(Dist::Zilla::File::InMemory->new(
		name => $self->filename,
		content => Devel::PPPort::GetFileContents($self->filename),
		encoding => 'ascii',
	));
	return;
}

sub after_build {
	my ($self, $args) = @_;
	my $build_root = $args->{build_root};

	my $wd = pushd $build_root;

	my $filename = $self->filename;

	my $perl_prereq = $self->zilla->prereqs->cpan_meta_prereqs
		->merged_requirements([ qw(configure build runtime test) ], ['requires'])
		->requirements_for_module('perl') || '5.006';

	if ($self->logger->get_debug) {
		chomp(my $out = `$^X $filename --compat-version=$perl_prereq`);
		$self->log_debug($out) if $out;
	}
	else {
		chomp(my $out = `$^X $filename --compat-version=$perl_prereq --quiet`);
		$self->log_debug($out) if $out;
	}
}

sub register_prereqs {
	my $self = shift;
	$self->zilla->register_prereqs({ phase => 'develop' }, 'Devel::PPPort' => $self->version);
	return;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

#ABSTRACT: PPPort for Dist::Zilla

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PPPort - PPPort for Dist::Zilla

=head1 VERSION

version 0.008

=head1 SYNOPSIS

In your dist.ini

 [PPPort]
 filename = ppport.h ;default

=head1 DESCRIPTION

This module adds a PPPort file to your distribution. By default it's called C<ppport.h>, but you can name differently.

=head1 ATTRIBUTES

=head2 style

This affects the default value for the C<filename> attribute. It must be either C<MakeMaker> or C<ModuleBuild>, the former being the default.

=head2 filename

The filename of the ppport file. It defaults to F<ppport.h> if C<style> is C<MakeMaker>, and something module specific if C<style> is C<Module::Build>.

=head2 version

This describes the minimal version of Devel::PPPort required for this module. It currently defaults to C<3.23>.

=for Pod::Coverage gather_files
register_prereqs
after_build
=end

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
