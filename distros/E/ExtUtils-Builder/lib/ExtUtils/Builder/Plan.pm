package ExtUtils::Builder::Plan;
$ExtUtils::Builder::Plan::VERSION = '0.002';
use strict;
use warnings;

use Carp ();
use Scalar::Util ();

sub new {
	my ($class, %args) = @_;
	return bless {
		nodes => $args{nodes} || {}
	}, $class;
}

sub node {
	my ($self, $name) = @_;
	return $self->{nodes}{$name};
}

sub nodes {
	my $self = shift;
	return @{$self->{nodes}}{ $self->node_names };
}

sub node_names {
	my $self = shift;
	return sort keys %{ $self->{nodes} };
}

sub _node_sorter {
	my ($self, $name, $callback, $seen, $loop) = @_;
	Carp::croak("$name has a circular dependency, aborting!\n") if exists $loop->{$name};
	return if $seen->{$name}++;
	if (my $node = $self->{nodes}{$name}) {
		local $loop->{$name} = 1;
		$self->_node_sorter($_, $callback, $seen, $loop) for $node->dependencies;
		$callback->($name, $node);
	} elsif (not -e $name) {
		Carp::confess("Node $name doesn't exist")
	}
	return;
}

sub run {
	my ($self, $targets, %options) = @_;

	my @targets = ref($targets) ? @{$targets} : $targets;
	my (%seen, %loop);
	my $run_node = sub {
		my ($name, $node) = @_;
		return if not $node->phony and -e $name and sub { -d or -M $name <= -M or return 0 for sort $node->dependencies; 1 }->();
		$node->execute(%options);
	};
	$self->_node_sorter($_, $run_node, \%seen, \%loop) for @targets;
	return;
}

sub merge {
	my ($self, $other) = @_;
	Carp::croak('Right side of merge is not a Plan') if not $other->isa(__PACKAGE__);
	my $double = join ', ', grep { $other->{nodes}{$_} } keys %{ $self->{nodes} };
	Carp::croak("Found key(s) $double on both sides of merge") if $double;
	my %nodes = (%{ $self->{nodes} }, %{ $other->{nodes} });
	return ref($self)->new(nodes => [ values %nodes ]);
}

sub phonies {
	my ($self) = @_;
	return sort map { $_->target } grep { $_->phony } values %{ $self->{nodes} };
}

1;

# ABSTRACT: An ExtUtils::Builder Plan

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Plan - An ExtUtils::Builder Plan

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 package Frobnicate;
 sub plan {
     my %nodes = ...;
     return ExtUtils::Builder::Plan->new(
         nodes => \%nodes,
     );
 }

 my $plan = Frobnicate->plan(@args);
 
 # various consumption methods
 $plan->run('foo');
 say $_->target for $plan->nodes;

=head1 DESCRIPTION

An object of this class describes a process. It contains one or more nodes. This is enough to describe whole building processes, in fact its C<run> method is a tiny C<make> engine.

=head1 ATTRIBUTES

=head2 nodes

This is the set of all nodes in this plan.

=head1 METHODS

=head2 run($target, %options)

This runs the process. Similar to C<make>, it checks for each node if it is necessary to run, and if not skips it. C<$target> may either be a single string or an array ref of strings for the targets to run.

=head2 node($target)

Returns the node for the specified C<$target>.

=head2 node_names()

Returns the names of all the nodes.

=head2 merge($other)

This merges this plan with another, and returns the new plan. Each entry may only exist on one side of the merge.

=head2 phonies()

This returns the names of all phony targets.

=for Pod::Coverage new

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
