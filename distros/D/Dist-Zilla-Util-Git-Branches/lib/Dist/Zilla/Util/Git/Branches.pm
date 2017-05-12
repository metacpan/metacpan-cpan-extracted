use strict;
use warnings;

package Dist::Zilla::Util::Git::Branches;
BEGIN {
  $Dist::Zilla::Util::Git::Branches::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Util::Git::Branches::VERSION = '0.001000';
}

# ABSTRACT: Extract branches from Git


use Moose;
use MooseX::LazyRequire;

has 'zilla' => ( is => ro =>, isa => Object =>, lazy_required => 1 );
has 'git'   => ( is => ro =>, isa => Object =>, lazy_build    => 1 );
has 'refs'  => ( is => ro =>, isa => Object =>, lazy_build    => 1 );

sub _build_git {
  my ($self) = @_;
  require Dist::Zilla::Util::Git::Wrapper;
  return Dist::Zilla::Util::Git::Wrapper->new( zilla => $self->zilla );
}

sub _build_refs {
  my ($self) = @_;
  require Dist::Zilla::Util::Git::Refs;
  return Dist::Zilla::Util::Git::Refs->new( git => $self->git );
}

sub _to_branch {
  my ( $self, $ref ) = @_;
  require Dist::Zilla::Util::Git::Branches::Branch;
  return Dist::Zilla::Util::Git::Branches::Branch->new_from_Ref($ref);
}

sub _to_branches {
  my ( $self, @refs ) = @_;
  return map { $self->_to_branch($_) } @refs;
}


sub branches {
  my ( $self, ) = @_;
  return $self->get_branch(q[**]);
}


sub get_branch {
  my ( $self, $name ) = @_;
  return $self->_to_branches( $self->refs->get_ref( 'refs/heads/' . $name ) );
}

sub _current_sha1 {
  my ($self)          = @_;
  my (@current_sha1s) = $self->git->rev_parse('HEAD');
  if ( scalar @current_sha1s != 1 ) {
    require Carp;
    Carp::confess('Fatal: rev_parse HEAD returned != 1 values');
  }
  return shift @current_sha1s;
}

sub _current_branch_name {
  my ($self) = @_;
  my (@current_names) = $self->git->rev_parse( '--abbrev-ref', 'HEAD' );
  if ( scalar @current_names != 1 ) {
    require Carp;
    Carp::confess('Fatal: rev_parse --abbrev-ref HEAD returned != 1 values');
  }
  return shift @current_names;
}


sub current_branch {
  my ( $self, ) = @_;
  my ($ref) = $self->_current_branch_name;
  return if not $ref;
  return if $ref eq 'HEAD';    # Weird special case.
  my (@items) = $self->get_branch($ref);
  return shift @items if @items == 1;
  require Carp;
  Carp::confess( 'get_branch(' . $ref . ') returned multiple values. Cannot determine current branch' );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::Git::Branches - Extract branches from Git

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

This module aims to do what you want when you think you want to parse the output of

    git branch

Except it works the right way, and uses

    git for-each-ref

So

    use Dist::Zilla::Util::Git::Branches;

    my $branches = Dist::Zilla::Util::Git::Branches->new(
        zilla => $self->zilla
    );
    for my $branch ( $branches->branches ) {
        printf "%s %s", $branch->name, $branch->sha1;
    }

=head1 METHODS

=head2 C<branches>

Returns a C<::Branch> object for each local branch.

=head2 get_branch

Get branch info about master

    my $branch = $branches->get_branch('master');

Note: This can easily return multiple values.

For instance, C<branches> is implemented as

    my ( @branches ) = $branches->get_branch('**');

Mostly, because the underlying mechanism is implemented in terms of L<< C<fnmatch(3)>|fnmatch(3) >>

If the branch does not exist, or no branches match the expression, C<< get_branch >>  will return an empty list.

So in the top example, C<$branch> is C<undef> if C<master> does not exist.

=head2 C<current_branch>

Returns a C<::Branch> object if currently on a C<branch>, C<undef> otherwise.

    my $b = $branches->current_branch;
    if ( defined $b ) {
        printf "Currently on: %s", $b->name;
    } else {
        print "Detached HEAD";
    }

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
