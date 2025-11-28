package ExtUtils::Builder::Planner;
$ExtUtils::Builder::Planner::VERSION = '0.018';
use strict;
use warnings;

use Carp ();
use File::Basename;
use File::Spec;
use List::Util 1.45 ();
use Scalar::Util ();

use ExtUtils::Builder::Plan;
use ExtUtils::Builder::Node;
use ExtUtils::Builder::Util;

use ExtUtils::Builder::FileSet::Free;
use ExtUtils::Builder::FileSet::Filter;
use ExtUtils::Builder::FileSet::Subst;

my $class_counter = 0;

sub new {
	my $base_class = shift;
	my $all_files = ExtUtils::Builder::FileSet::Free->new;
	return $base_class->_new_scope($base_class, undef, {}, { 'all-files' => $all_files });
}

sub _new_scope {
	my ($self, $base_class, $outer, $nodes, $filesets) = @_;

	my $class = __PACKAGE__ . '::Anon_' . ++$class_counter;
	no strict 'refs';
	push @{ "$class\::ISA" }, $base_class;

	my $new = bless {
		nodes    => $nodes,
		filesets => $filesets
	}, $class;

	$new->add_delegate('self', sub { $new });
	$new->add_delegate('outer', sub { $outer });

	return $new;
}

sub new_scope {
	my ($self) = @_;
	return $self->_new_scope(ref($self), $self, $self->{nodes}, $self->{filesets});
}

sub add_node {
	my ($self, $node) = @_;
	my $target = $node->target;
	if (exists $self->{nodes}{$target}) {
		Carp::croak("Duplicate for target $target") if !$node->mergeable or !$self->{nodes}{$target}->mergeable;
		my @dependencies = List::Util::uniq($self->{nodes}{$target}->dependencies, $node->dependencies);
		my $new = ExtUtils::Builder::Node->new(target => $target, dependencies => \@dependencies, phony => 1);
		$self->{nodes}{$target} = $new;
	} else {
		$self->{nodes}{$target} = $node;
		$self->{filesets}{'all-files'}->add_input($target) if not $node->phony;
	}
	return $node->target;
}

sub create_node {
	my ($self, %args) = @_;
	my $node = ExtUtils::Builder::Node->new(%args);
	return $self->add_node($node);
}

sub create_phony {
	my ($self, $target, @dependencies) = @_;
	return $self->create_node(
		target       => $target,
		dependencies => \@dependencies,
		type         => 'phony',
	);
}

my $counter = 0;

sub _create_callback {
	my ($self, $add_to) = @_;
	return undef unless $add_to;
	my $this = $self;
	Scalar::Util::weaken($this);
	return sub {
		my ($entry) = @_;
		$this->create_phony($add_to, $entry);
	};
}

sub create_filter {
	my ($self, %args) = @_;
	my $set = ExtUtils::Builder::FileSet::Filter->new(
		condition => $args{condition},
		callback  => $self->_create_callback($args{add_to}),
	);
	my $on = $args{on} // 'all-files';
	my @sources = ref($on) eq 'ARRAY' ? @{$on} : $on;
	for my $source (@sources) {
		my $object = $self->{filesets}{$source} or die "No such source $source";
		$object->add_dependent($set);
	}
	my $name = $args{name} // 'filter-' . $counter++;
	$self->{filesets}{$name} = $set;
	return $name;
}

sub _make_pattern {
	my ($self, %options) = @_;
	if ($options{file}) {
		my $file = ExtUtils::Builder::Util::glob_to_regex($options{file});
		if ($options{dir}) {
			my $dir = ExtUtils::Builder::Util::native_to_unix_path($options{dir});
			return sub {
				my ($input) = @_;
				my $filename = ExtUtils::Builder::Util::native_to_unix_path($input);
				$filename =~ s{(?<!/)$}{/}ms;
				return if substr($filename, 0, length $options{dir}) ne $dir;
				return File::Basename::basename($filename) =~ $file;
			};
		} else {
			return sub {
				my ($filename) = @_;
				return File::Basename::basename($filename) =~ $file;
			};
		}
	} elsif ($options{dir}) {
		my $dir = ExtUtils::Builder::Util::native_to_unix_path($options{dir});
		return sub {
			my ($input) = @_;
			my $filename = ExtUtils::Builder::Util::native_to_unix_path($input);
			$filename =~ s{(?<!/)$}{/}ms;
			return substr($filename, 0, length $options{dir}) eq $options{dir};
		};
	} else {
		Carp::croak("Unknown pattern type");
	}
}

sub create_pattern {
	my ($self, %args) = @_;
	my $positive = $self->_make_pattern(%args);
	my $callback = $args{negate} ? sub { !$positive->($_[0]) } : $positive;
	return $self->create_filter(%args, condition => $callback);
}

sub create_subst {
	my ($self, %args) = @_;
	my $set = ExtUtils::Builder::FileSet::Subst->new(
		subst     => $args{subst},
		callback  => $self->_create_callback($args{add_to}),
	);
	my $on = $args{on} // 'all-files';
	my @sources = ref($on) eq 'ARRAY' ? @{$on} : $on;
	for my $source (@sources) {
		my $object = $self->{filesets}{$source} or die "No such source $source";
		$object->add_dependent($set);
	}
	my $name = $args{name} // 'subst-' . $counter++;
	$self->{filesets}{$name} = $set;
	return $name;
}

sub add_seen {
	my ($self, $entry) = @_;
	$self->{filesets}{'all-files'}->add_input($entry);
	return;
}

sub merge_plan {
	my ($self, $plan) = @_;
	$self->add_node($_) for $plan->nodes;
	return;
}

my $set_subname = eval { require Sub::Util; Sub::Util->VERSION('1.40'); \&Sub::Util::set_subname } // sub { $_[1] };

sub add_delegate {
	my ($self, $name, $sub) = @_;
	my $full_name = ref($self) . '::' . $name;
	no strict 'refs';
	no warnings 'redefine';
	*{$full_name} = $set_subname->($full_name, $sub);
	return;
}

sub load_extension {
	my ($self, $plannable, $version, %options) = @_;
	ExtUtils::Builder::Util::require_module($plannable);
	$plannable->VERSION($version) if $version;
	return $plannable->add_methods($self, %options);
}
*load_module = \&load_extension;

sub materialize {
	my $self = shift;
	my %nodes = %{ $self->{nodes} };
	return ExtUtils::Builder::Plan->new(nodes => \%nodes);
}

my %dsl_commands = (
	command  => \&ExtUtils::Builder::Util::command,
	code     => \&ExtUtils::Builder::Util::code,
	function => \&ExtUtils::Builder::Util::function,
);

sub run_dsl {
	my ($self, $filename) = @_;

	my $dsl_module = ref($self) . '::DSL';

	if (not defined &{ "$dsl_module\::AUTOLOAD" }) {
		no strict 'refs';
		*{ "$dsl_module\::AUTOLOAD" } = sub {
			my $name = our $AUTOLOAD;
			$name =~ s/.*:://;
			if (my $method = $self->can($name)) {
				my $delegate = $set_subname->($name, sub {
					$self->$method(@_);
				});
				*{ "$dsl_module\::$name" } = $delegate;
				goto &$delegate;
			}
			else {
				Carp::croak("No such subroutine $name");
			}
		};

		for my $name (keys %dsl_commands) {
			*{ "$dsl_module\::$name" } = $dsl_commands{$name} if not $dsl_module->can($name);
		}
	}

	my $path = File::Spec->rel2abs($filename);
	eval "package $dsl_module; my \$ret = do \$path; die \$@ if \$@; defined \$ret || !\$!" or die $@ // Carp::shortmess("Can't run $path: $!");
	return;
}

1;

# ABSTRACT: An ExtUtils::Builder Plan builder

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Planner - An ExtUtils::Builder Plan builder

=head1 VERSION

version 0.018

=head1 SYNOPSIS

 my $planner = ExtUtils::Builder::Planner->new;
 $planner->create_node(
     target       => 'foo',
     dependencies => [ 'bar' ],
     actions      => \@actions,
 );
 my $plan = $planner->materialize;

=head1 DESCRIPTION

A Planner is an object that creates a L<Plan|ExtUtils::Builder::Plan> that can be executed.

The primary objective of this class is to gather a set of nodes (triplets of target, dependencies and actions), that represent building graph. To aid building this graph, this modules provides filesets to filter and transform filenames. Delegates can be mixed into the planner to aid in building these nodes and filesets. Extensions are a collection of such delegates.

=head1 METHODS

=head2 add_node($node)

This adds an L<ExtUtils::Builder::Node|ExtUtils::Builder::Node> to the planner. It will also be added to the C<'all-files'> fileset if it's a file node.

=head2 create_node(%args)

This creates a new node and adds it to the planner using C<add_node>. It takes the same named arguments as C<ExtUtils::Builder::Node>.

=over 4

=item * target

The target of the node. This is mandatory.

=item * dependencies

The list of dependencies for this node.

=item * actions

The actions to perform to create or update this node.

=item * type

This marks the type of the node: C<file> or C<phony>, defaulting to the former.

=back

=head2 merge_plan($plan)

This merges all nodes of the plan to the planner.

=head2 add_delegate($name, $sub)

This adds C<$sub> as a helper method to this planner, with the name C<$name>.

=head2 create_phony($target, @dependencies)

This is a helper function that calls C<create_node> for a action-free phony target.

=head2 create_filter(%options)

This will filter an existing fileset based on a condition, and return the name of the new fileset.

=over 4

=item * condition

If this callback returns true the file will be included in the new filesets.

=item * on

this sets the input fileset, it defaults to c<'all-files'>.

=item * name

this sets the name of the new set, if none is given one will be generated.

=back

=head2 create_pattern(%options)

This is a wrapper for C<add_filter> for various common constructs. It takes several named options, at the moment at least one of C<file> or C<dir> is mandatory.

=over 4

=item * file

A unix glob pattern that each filename is compared to, e.g. C<'*.pm'>.

=item * dir

The directory under which files should be (e.g. C<'lib'>).

=item * negate

This negates all the match.

=item * on

this sets the input fileset, it defaults to C<'all-files'>.

=item * name

this sets the name of the new set, if none is given one will be generated.

=back

=head2 create_subst(%options)

This creates a new node based on the old one (source).

=over 4

=item * subst

This callback is called for all entries in the input set. It should do two things:

=over 4

=item 1. Return the name of the new target node.

=item 2. It should add a node to create the target from the source. The node should have source as its dependency.

=back

=item * on

this sets the input fileset, it defaults to c<'all-files'>.

=item * name

this sets the name of the new set, if none is given one will be generated.

=back

=head2 add_seen($filename)

This marks a file as existing on the filesystem by adding it to the C<'all-files'> fileset.

=head2 load_extension($extension, $version, %options)

This adds the delegate from the given module. If C<$version> is defined it will verify if the extension is at least that version.

C<load_module> is a depreciated alias for this function.

=head2 new_scope()

This opens a new scope on the planner. It return a child planner that shared the build tree state with its parent, but any delegated added to it will not be added to the parent.

=head2 run_dsl($filename)

This runs C<$filename> as a DSL file. This is a script file that includes Planner methods as functions. For example:

 use strict;
 use warnings;

 load_extension("Foo");

 add_foo("a.foo", "a.bar");

 create_subst(
     on    => create_pattern(file => '*.src'),
     subst => sub {
	     my ($source) = @_;
		 my $target = $source =~ s/\.src$//r;
         return create_node(
             target       => $target,
             dependencies => [ $source ],
             actions      => [
                command('convert', $target, $source),
                function(module => 'Foo', function => 'bar'),
                code(code => 'print "Hello World"'),
             ],
         );
     },
 );

This will also add C<command>, C<function> and C<code> helper functions that correspond to L<ExtUtils::Builder::Action::Command>, L<ExtUtils::Builder::Action::Function> and L<ExtUtils::Builder::Action::Code> respectively.

=head2 materialize()

This returns a new L<ExtUtils::Builder::Plan|ExtUtils::Builder::Plan> object based on the planner.

=head2 self()

This returns the planner.

=head2 outer()

This returns the planner matching the outer scope of the current planner object.

=for Pod::Coverage new
load_module

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
