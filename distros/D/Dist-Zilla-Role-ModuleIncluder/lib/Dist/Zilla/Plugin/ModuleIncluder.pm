package Dist::Zilla::Plugin::ModuleIncluder;
$Dist::Zilla::Plugin::ModuleIncluder::VERSION = '0.008';
# vim: ts=4 sts=0 sw=0 noet
use version;
use Moose;
use MooseX::Types::Moose qw/ArrayRef Bool/;
use MooseX::Types::Perl 'VersionObject';
use MooseX::Types::Stringlike 'Stringlike';

with qw/Dist::Zilla::Role::ModuleIncluder Dist::Zilla::Role::FileGatherer/;

has module => (
	isa => ArrayRef[Stringlike],
	traits => ['Array'],
	handles => {
		modules => 'elements',
	},
	required => 1,
);

has blacklist => (
	isa => ArrayRef[Stringlike],
	traits => ['Array'],
	handles => {
		blacklisted_modules => 'elements',
	},
	default => sub { [] },
);

has background_perl => (
	is => 'ro',
	isa => VersionObject,
	default => sub { version->new('5.008001') },
	coerce => 1,
);

has only_deps => (
	is => 'ro',
	isa => Bool,
	default => 0,
);

around dump_config => sub
{
	my ($orig, $self) = @_;
	my $config = $self->$orig;

	my $data = {
		blessed($self) ne __PACKAGE__ ? ( version => __PACKAGE__->VERSION || '<self>' ) : (),
		module => [ $self->modules ],
		blacklist => [ $self->blacklisted_modules ],
		background_perl => $self->background_perl->stringify,
		only_deps => ($self->only_deps ? 1 : 0),
	};
	$config->{+__PACKAGE__} = $data;

	return $config;
};

sub gather_files {
	my ($self, $arg) = @_;
	$self->include_modules({ map { ($_ => $self->only_deps ) } $self->modules }, $self->background_perl, { blacklist => [ $self->blacklisted_modules ] });
	return;
}

sub mvp_multivalue_args {
	return qw/module blacklist/;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

#ABSTRACT: explicitly include modules into a distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ModuleIncluder - explicitly include modules into a distribution

=head1 VERSION

version 0.008

=head1 SYNOPSIS

In dist.ini:

 [ModuleIncluder]
 module = Foo
 module = Bar
 background_perl = 5.008001 #default value
 only_deps = 0 #default
 include_dependencies = 1 #default

=head1 DESCRIPTION

This module allows you to explicitly include a module and its dependencies in C<inc/>. At least one module must be given.

=over 4

=item * module

Add a module to be included. This option can be given more than once.

=item * background_perl

Set the background perl version. If the (appropriate version of the) module was present in that release of perl, it will be omitted from C<inc>. It defaults to 5.8.1.

=item * only_deps

Do not include the specified modules, only their dependencies. Note that it still includes the module if something else depends on it.

=item * blacklist

The name of a module to never include.  This option can be given more than once.

=back

=for Pod::Coverage gather_files
mvp_multivalue_args
=end

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
