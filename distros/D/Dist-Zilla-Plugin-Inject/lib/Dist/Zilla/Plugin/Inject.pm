package Dist::Zilla::Plugin::Inject;
BEGIN {
  $Dist::Zilla::Plugin::Inject::VERSION = '0.001';
}

# ABSTRACT: Inject into a CPAN::Mini mirror

use Class::Load qw(load_class);
use Try::Tiny qw(try catch);
use Moose;
use Moose::Util::TypeConstraints;
use File::Temp qw();

with 'Dist::Zilla::Role::Releaser';

has 'remote_server' => (
	is        => 'ro',
	isa       => 'Str',
	predicate => 'is_remote',
);

has 'config_file' => (
	is        => 'ro',
	isa       => 'Str',
);

has 'author_id' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has 'module' => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub {
		my $name = $_[0]->zilla->name;
		$name =~ s/\-/\:\:/g;
		return $name;
	},
);

has 'injector' => (
	is      => 'ro',
	isa     => subtype( 'Object' => where { $_->isa('CPAN::Mini::Inject') or $_->isa('CPAN::Mini::Inject::Remote') } ),
	lazy    => 1,
	default => sub 
	{
		my $self = shift;
		my $i;
		if ($self->is_remote)
		{
			load_class('CPAN::Mini::Inject::Remote');
			$i = CPAN::Mini::Inject::Remote->new( remote_server => $self->remote_server );
		}
		else
		{
			load_class('CPAN::Mini::Inject');
			$i = CPAN::Mini::Inject->new;
			$i->parsecfg($self->config_file);
		}
		return $i;
	},
);

sub release {
	my ($self, $archive) = @_;

	my $i = $self->injector;
	
	my %add_options;

	if ($self->is_remote)
	{
		# CPAN::Mini::Inject::Remote API
		%add_options = (
			module_name => $self->module, 
			author_id   => $self->author_id, 
			version     => $self->zilla->version, 
			file_name   => $archive->stringify,
		);
	}
	else
	{
		# CPAN::Mini::Inject API
		%add_options = (
			module   => $self->module, 
			authorid => $self->author_id, 
			version  => $self->zilla->version, 
			file     => $archive->stringify,
		);
	}

	try 
	{
		$i->add(%add_options);
		$self->log("Added " . $self->module . " to repository");
		$i->inject;
		$self->log("Injected " . $self->module . " into CPAN::Mini mirror");
	} 
	catch 
	{
		chomp;
		$self->log_fatal($_);
	};
}

1;


__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::Inject - Inject into a CPAN::Mini mirror

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # in your dist.ini
  [Inject]
  author_id = EXAMPLE

  # injection is triggered at the release stage
  dzil release

=head1 DESCRIPTION

C<Dist::Zilla::Plugin::Inject> is a release-stage plugin that will inject your distribution into a local or remote L<CPAN::Mini> mirror.

=head1 CONFIGURATION

=head2 Author ID

The only mandatory setting that C<Dist::Zilla::Plugin::Inject> requires is the author id that will be used when injecting the module (C<author_id>).

=head2 Injecting into a local repository

C<Dist::Zilla::Plugin::Inject> uses L<CPAN::Mini::Inject> to inject your distribution into a local L<CPAN::Mini> mirror. Thus, you need to have L<CPAN::Mini::Inject> configured on your machine first. L<CPAN::Mini::Inject> looks for its configuration file in a number of predefined locations (see its docs for details), or you can specify an explicit location via the C<config_file> setting in your C<dist.ini>, e.g.:

  [Inject]
  author_id = EXAMPLE
  config_file = /home/example/.mcpani

=head2 Injecting into a remote repository

If you supply a C<remote_server> setting in your C<dist.ini>, C<Dist::Zilla::Plugin::Inject> will try to inject your distribution into a remote mirror via L<CPAN::Mini::Inject::Remote>. A configured L<CPAN::Mini::Inject::Server> must respond to the address specified in C<remote_server>, e.g.:

  [Inject]
  author_id = EXAMPLE
  remote_server = http://mcpani.example.com/

=for stopwords Shangov

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

