package ExtUtils::Builder::Compiler;
$ExtUtils::Builder::Compiler::VERSION = '0.004';
use strict;
use warnings;

use ExtUtils::Builder::Action::Command;
use ExtUtils::Builder::Node;

use base qw/ExtUtils::Builder::ArgumentCollector ExtUtils::Builder::Binary/;

sub new {
	my ($class, %args) = @_;
	my $cc = $args{cc};
	$cc = [ $cc ] if not ref $cc;
	my $self = bless {
		cc           => $cc,
		include_dirs => [],
		defines      => [],
	}, $class;
	$self->_init(%args);
	return $self;
}

sub _init {
	my ($self, %args) = @_;
	$self->ExtUtils::Builder::ArgumentCollector::_init(%args);
	$self->ExtUtils::Builder::Binary::_init(%args);
	return;
}

sub compile_flags;

sub cc {
	my $self = shift;
	return @{ $self->{cc} };
}

sub add_include_dirs {
	my ($self, $dirs, %opts) = @_;
	my $ranking = $self->fix_ranking($self->default_include_ranking, $opts{ranking});
	push @{ $self->{include_dirs} }, map { { ranking => $ranking, value => $_ } } @{ $dirs };
	return;
}

sub default_include_ranking {
	return 30;
}

sub add_defines {
	my ($self, $defines, %opts) = @_;
	my $ranking = $self->fix_ranking($self->default_define_ranking, $opts{ranking});
	push @{ $self->{defines} }, map { { key => $_, ranking => $ranking, value => $defines->{$_} } } keys %{ $defines };
	return;
}

sub default_define_ranking {
	return 40;
}

sub collect_arguments  {
	my ($self, @args) = @_;
	return ($self->SUPER::collect_arguments, $self->compile_flags(@args));
}

sub compile {
	my ($self, $from, $to, %opts) = @_;
	my @argv = $self->arguments($from, $to, %opts);
	my $main = ExtUtils::Builder::Action::Command->new(command => [ $self->cc, @argv ]);
	my @mkdir   = $opts{mkdir} ? ExtUtils::Builder::Action::Function->new(
		module    => 'File::Path',
		function  => 'make_path',
		exports   => 'explicit',
		arguments => [ File::Basename::dirname($to) ],
	) : ();
	my $deps = [ $from, @{ $opts{dependencies} || [] } ];
	return ExtUtils::Builder::Node->new(target => $to, dependencies => $deps, actions => [$main]);
}

1;

# ABSTRACT: Portable compilation

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Compiler - Portable compilation

=head1 VERSION

version 0.004

=head1 METHODS

=head2 new(%options)

=over 4

=back

=head2 add_include_dirs($dirs, %options)

=head2 add_defines($defines, %options)

=head2 compile($source, $target, %options)

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
