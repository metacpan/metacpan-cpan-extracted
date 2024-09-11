package ExtUtils::Builder::Node;
$ExtUtils::Builder::Node::VERSION = '0.012';
use strict;
use warnings;

use parent qw/ExtUtils::Builder::Action::Composite/;

use Carp 'croak';

sub new {
	my ($class, %args) = @_;
	croak('Attribute target is not defined') if not $args{target};
	$args{actions} = [ map { $_->flatten } @{ $args{actions} || [] } ];
	$args{dependencies} ||= [];
	$args{type} ||= delete $args{phony} ? 'phony' : 'file';
	return $class->SUPER::new(%args);
}

sub flatten {
	my $self = shift;
	return @{ $self->{actions} };
}

sub target {
	my $self = shift;
	return $self->{target};
}

sub dependencies {
	my $self = shift;
	return @{ $self->{dependencies} };
}

sub type {
	my $self = shift;
	return $self->{type};
}

sub phony {
	my $self = shift;
	return $self->{type} eq 'phony';
}

sub mergeable {
	my $self = shift;
	return $self->{type} eq 'phony' && !@{ $self->{actions} };
}

sub newer_than {
	my ($self, $mtime) = @_;
	return 1 if $self->{type} eq 'phony';
	return -d $self->{target} || (-e _ && $mtime <= -M _);
}

1;

# ABSTRACT: An ExtUtils::Builder Node

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Node - An ExtUtils::Builder Node

=head1 VERSION

version 0.012

=head1 SYNOPSIS

 ExtUtils::Builder::Node->new(
     target       => $target_name,
     dependencies => \@dependencies,
     actions      => \@actions,
 );

=head1 DESCRIPTION

A node is the equivalent of a makefile entry. In essence it boils down to its three attributes: C<target> (the name of the target), C<dependencies>(the names of the dependencies) and C<actions>. A Node is a L<composite action|ExtUtils::Builder::Action::Composite>, meaning that in can be executed or serialized as a whole.

=head1 ATTRIBUTES

=head2 target

The target filename of this node.

=head2 dependencies

The (file)names of the dependencies of this node.

=head2 actions

A list of L<actions|ExtUtils::Builder::Action> for this node.

=head2 type

This must be one of C<file> or C<phony>. In the latter case the target will not be represented on the filesystem.

=head2 phony

B<Deprecated>.

Instead, pass C<< type => 'phony' >>

=head1 METHODS

=head2 mergeable

This returns true if a node is mergeable, i.e. it's phony and has no actions.

=for Pod::Coverage flatten
execute
to_command
to_code
newer_than

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
