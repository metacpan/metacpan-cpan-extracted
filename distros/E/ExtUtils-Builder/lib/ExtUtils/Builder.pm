package ExtUtils::Builder;
$ExtUtils::Builder::VERSION = '0.019';
use strict;
use warnings;

1;

#ABSTRACT: An overview of the foundations of the ExtUtils::Builder Plan framework

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder - An overview of the foundations of the ExtUtils::Builder Plan framework

=head1 VERSION

version 0.019

=head1 DESCRIPTION

This document describes the foundations of the ExtUtils::Builder Plan framework, including Actions, Nodes and Plans.

=head1 OVERVIEW

=head2 Action basics

Actions are the cornerstone of the ExtUtils::Builder framework. They provide an interface between build tools (e.g. L<ExtUtils::MakeMaker|ExtUtils::MakeMaker>, L<Module::Build|Module::Build>, ...) and building extensions. This allows producing and consuming sides to be completely independent from each other. It is a flexible abstraction around pieces of work, this work can be a piece of perl code, an external command, a mix of those or possibly other things.

An action can be consumed in many ways.

=over 4

=item * execute(%args)

This is often the simplest way of dealing with an action. It simple performs the action immediately, and will throw an exception on failure.

=item * to_command(%opts)

This converts the action into a list of commands to be executed. The elements of this list are arrayrefs to that can each be executed using along these lines:

 for my $command ($work->to_command) {
   system(@$command);
 }

It can take two optional named arguments: C<perl> for the path to perl, and C<config> for an L<ExtUtils::Config> object used the find the current perl.

=item * to_code()

This converts the action into a list of strings to be C<eval>ed in order to execute them. This can be useful when you want to serialize the work that is to be done but don't want to force it to shell out.

=item * to_code_hash()

This converts the action into a hash that can be used to create a new L<ExtUtils::Builder::Action::Code>.

=item * flatten()

This will return all primitive actions involved in this action. It may return C<$self>, it may return an empty list.
On L<composite|ExtUtils::Builder::Action::Composite> actions, C<flatten> can be called to retrieve the constituent actions, C<flatten> is guaranteed to only return primitive actions.

=item * preference(@options)

If a consumer can consume actions in more than one way, the C<preference> method can be used to choose between options. This function expects a list of options out of C<code>, C<command>, C<execute> and C<flatten>. You probably want to flatten your action first, as different constituents may have different preferences.

 for my $action ($work->flatten) {
   my $preference = $self->preference('code', 'command');
   push @serialized, ($preference eq 'code')
     ? [ eval => $action->to_code ] 
     : [ exec => $action->to_command ];
 }

=back

=head2 Primitives

On primitive actions, all serialization methods will return a single item list. There are two types of of primitive actions shipped with this dist: L<Command|ExtUtils::Builder::Command> and L<Code|ExtUtils::Builder::Code>. Commands are essentially an abstraction around a call to an external command, Codes are an abstraction around a piece of Perl code. While these are all implementing the same interfaces, they have their own (hopefully obvious) preferences on how to be treated. C<flatten> is just an identity operator for primitive actions.

=head2 Composites

Composite actions are actions that may consist out of multiple actions (though in some cases they may contain only one or even zero actions). C<flatten> will return all its constituents. C<execute>, C<to_code> and C<to_command> will all call their respective method on all those values. C<preference> is of little use, and will always prefer to flatten when given that option.

=head3 Nodes

Nodes are composite Actions. Nodes are a simple class with three attributes:

=over 4

=item * target

This is the filename of the result of this build step.

=item * dependencies

This is an unordered set of zero or more files that must be build (and must be up-to-date) before the target is build.

=item * actions

This is a sequence of zero or more actions that must be performed to build the target. 

=back

Essentially, a Node is equivalent to entry in a Makefile

=head2 Plans

Plans are the equivalent of a (piece of a) Makefile. They are a bunch of nodes that should interconnect. It has one attribute.

=over 4

=item * nodes

This is a hash mapping (target) names to nodes. 

=back

The C<run> method will perform a topological sort much like C<make>. It will check which steps are necessary and skip the ones which are not.

=head1 RATIONALE

Writing extensions for various build tools can be a daunting task. This module tries to abstract steps of build processes into reusable building blocks for creating platform and build system agnostic executable descriptions of work.

=head1 USAGE

 package Frobnicator;
 use ExtUtils::Builder::Action::Code;

 ...

 sub add_plans { 
     my ($self, $planner) = @_;
     my $action = ExtUtils::Builder::Action::Code->new(
         code => ...,
     );
     $planner->create_node(
         target => 'frob',
         actions => [ $action ],
     );
     $planner->create_node(
         target => 'pure_all',
         dependencies => [ 'frob' ],
         phony => 1,
     );
 }
 ...

=head2 Makefile.PL

 use ExtUtils::MakeMaker;
 use ExtUtils::Builder::MakeMaker;
 ...
 WriteMakeFile(
   NAME => 'Foo',
   VERSION => 0.001,
   ...,
 );

 sub MY::make_plans {
   my ($self, $planner) = @_;
   Frobnicator->add_plans($planner);
 }

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
