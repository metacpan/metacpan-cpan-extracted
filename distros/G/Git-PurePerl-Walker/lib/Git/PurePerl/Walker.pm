use 5.006;    # our
use strict;
use warnings;

package Git::PurePerl::Walker;

our $VERSION = '0.004001';

# ABSTRACT: Walk over a sequence of commits in a Git::PurePerl repo

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has );
use Path::Tiny qw();
use Module::Runtime qw( );
use Git::PurePerl::Walker::Types qw( GPPW_Repository GPPW_Methodish GPPW_Method GPPW_OnCommitish GPPW_OnCommit);
use namespace::autoclean;















has repo => (
  isa        => GPPW_Repository,
  is         => 'ro',
  lazy_build => 1,
);









































has _method => (
  init_arg => 'method',
  is       => 'ro',
  isa      => GPPW_Methodish,
  required => 1,
);










has 'method' => (
  init_arg   => undef,
  is         => 'ro',
  isa        => GPPW_Method,
  lazy_build => 1,
);





















































has '_on_commit' => (
  init_arg => 'on_commit',
  required => 1,
  is       => 'ro',
  isa      => GPPW_OnCommitish,
);










has 'on_commit' => (
  init_arg   => undef,
  isa        => GPPW_OnCommit,
  is         => 'ro',
  lazy_build => 1,
);









sub BUILD {
  my ( $self, ) = @_;
  $self->reset;
  return $self;
}





sub _build_repo {
  require Git::PurePerl;
  return Git::PurePerl->new( directory => Path::Tiny->cwd->stringify );
}





sub _build_method {
  my ($self)   = shift;
  my ($method) = $self->_method;

  if ( not ref $method ) {
    my $method_name = Module::Runtime::compose_module_name( 'Git::PurePerl::Walker::Method', $method );
    Module::Runtime::require_module($method_name);
    $method = $method_name->new();
  }
  return $method->for_repository( $self->repo );
}





sub _build_on_commit {
  my ($self)      = shift;
  my ($on_commit) = $self->_on_commit;

  if ( ref $on_commit and 'CODE' eq ref $on_commit ) {
    my $on_commit_name = 'Git::PurePerl::Walker::OnCommit::CallBack';
    my $callback       = $on_commit;
    Module::Runtime::require_module($on_commit_name);
    $on_commit = $on_commit_name->new( callback => $callback, );
  }
  elsif ( not ref $on_commit ) {
    my $on_commit_name = 'Git::PurePerl::Walker::OnCommit::' . $on_commit;
    Module::Runtime::require_module($on_commit_name);
    $on_commit = $on_commit_name->new();
  }
  return $on_commit->for_repository( $self->repo );
}









## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub reset {
  my $self = shift;
  $self->method->reset;
  $self->on_commit->reset;
  return $self;
}




























sub step {
  my $self = shift;

  $self->on_commit->handle( $self->method->current );

  if ( not $self->method->has_next ) {
    return;
  }

  $self->method->next;

  return 1;
}












sub step_all {
  my $self  = shift;
  my $steps = 1;
  while ( $self->step ) {
    $steps++;
  }
  return $steps;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::PurePerl::Walker - Walk over a sequence of commits in a Git::PurePerl repo

=head1 VERSION

version 0.004001

=head1 SYNOPSIS

	use Git::PurePerl::Walker;
	use Git::PurePerl::Walker::Method::FirstParent;

	my $repo = Git::PurePerl->new( ... );

	my $walker = Git::PurePerl::Walker->new(
		repo => $repo,
		method => Git::PurePerl::Walker::Method::FirstParent->new(
			start => $repo->ref_sha1('refs/heads/master'),
		),
		on_commit => sub {
			my ( $commit ) = @_;
			print $commit->sha1;
		},
	);

	$walker->step_all;

=head1 CONSTRUCTOR ARGUMENTS

=head2 repo

B<Mandatory:> An instance of L<< C<Git::PurePerl>|Git::PurePerl >> representing
the repository to work with.

=head2 method

B<Mandatory:> either a C<Str> describing a Class Name Suffix, or an C<Object>
that C<does>
L<<
C<Git::PurePerl::B<Walker::Role::Method>>|Git::PurePerl::Walker::Role::Method
>>.

If its a C<Str>, the C<Str> will be expanded as follows:

	->new(
		...
		method => 'Foo',
		...
	);

	$className = 'Git::PurePerl::Walker::Method::Foo'

And the resulting class will be loaded, and instantiated for you. ( Assuming of
course, you don't need to pass any fancy args ).

If you need fancy args, or a class outside the
C<Git::PurePerl::B<Walker::Method::>> namespace, constructing the object will
have to be your responsibility.

	->new(
		...
		method => Foo::Class->new(),
		...
	)

=head2 on_commit

B<Mandatory:> either a C<Str> that can be expanded in a way similar to that by
L<< C<I<method>>|/method >>, a C<CodeRef>, or an object that C<does> L<<
C<Git::PurePerl::B<Walker::Role::OnCommit>>|Git::PurePerl::Walker::Role::OnCommit
>>.

If passed a C<Str> it will be expanded like so:

	->new(
		...
		on_commit => $str,
		...
	);

	$class = 'Git::PurePerl::Walker::OnCommit::' . $str;

And the resulting class loaded and instantiated.

If passed a C<CodeRef>,
L<<
C<Git::PurePerl::B<Walker::OnCommit::CallBack>>|Git::PurePerl::Walker::OnCommit::CallBack
>> will be loaded and your C<CodeRef> will be passed as an argument.

	->new(
		...
		on_commit => sub {
			my ( $commit ) = @_;

		},
		...
	);

If you need anything fancier, or requiring an unusual namespace, you'll want to
construct the object yourself.

	->new(
		...
		on_commit => Foo::Package->new()
		...
	);

=head1 METHODS

=head2 reset

	$walker->reset();

Reset the walk routine back to the state it was before you walked.

=head2 step

Increments one step forward in the git history, and dispatches the object to the
C<OnCommit> handlers.

If there are more possible steps to take, it will return a true value.

	while ( $walker->step ) {
		/* Code to execute if walker has more items */
	}

This code is almost identical to:

	while(1) {
		$walker->on_commit->handle( $walker->method->current );

		last if not $walker->method->has_next;

		$walker->method->next;

		/*  Code to execute if walker has more items */
	}

=head2 step_all

	my $steps = $walker->step_all;

Mostly a convenience method to iterate until it can iterate no more, but without
you needing to wrap it in a while() block.

Returns the number of steps executed.

=head1 ATTRIBUTES

=head2 repo

=head2 method

=head2 on_commit

=head1 ATTRIBUTE GENERATED METHODS

=head2 repo

	# Getter
	my $repo = $walker->repo();

=head2 method

	# Getter
	my $method_object = $walker->method();

=head2 on_commit

	# Getter
	my $on_commit_object = $walker->on_commit();

=head1 PRIVATE ATTRIBUTES

=head2 _method

=head2 _on_commit

=head1 PRIVATE METHODS

=head2 _build_repo

=head2 _build_method

=head2 _build_on_commit

=head1 PRIVATE ATTRIBUTE GENERATED METHODS

=head2 _method

	# Getter
	my $methodish = $walker->_method();

=head2 _on_commit

	# Getter
	my $on_commitish => $walker->_on_commit();

=for Pod::Coverage BUILD

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
