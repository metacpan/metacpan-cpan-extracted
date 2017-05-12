use 5.006;    # our
use strict;
use warnings;

package Git::Wrapper::Plus::Ref::Branch;

our $VERSION = '0.004011';

# ABSTRACT: A Branch object

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY




























use Moo qw( extends );
extends 'Git::Wrapper::Plus::Ref';

our @CARP_NOT;









## no critic (ProhibitMixedCaseSubs)
sub new_from_Ref {
  my ( $class, $source_object ) = @_;
  if ( not $source_object->can('name') ) {
    require Carp;
    return Carp::croak("Object $source_object does not respond to ->name, cannot Ref -> Branch");
  }
  my $name = $source_object->name;
  ## no critic ( Compatibility::PerlMinimumVersionAndWhy )
  if ( $name =~ qr{\Arefs/heads/(.+\z)}msx ) {
    return $class->new(
      git  => $source_object->git,
      name => $1,
    );
  }
  require Carp;
  Carp::croak("Path $name is not in refs/heads/*, cannot convert to Branch object");
}







sub refname {
  my ($self) = @_;
  return 'refs/heads/' . $self->name;
}

















## no critic (ProhibitBuiltinHomonyms)

sub delete {
  my ( $self, $params ) = @_;
  if ( $params->{force} ) {
    return $self->git->branch( '-D', $self->name );
  }
  return $self->git->branch( '-d', $self->name );

}











sub move {
  my ( $self, $new_name, $params ) = @_;
  if ( not defined $new_name or not length $new_name ) {
    require Carp;
    ## no critic (ProhibitLocalVars)
    local @CARP_NOT = __PACKAGE__;
    Carp::croak(q[Move requires a defined argument to move to, with length >= 1 ]);
  }
  if ( $params->{force} ) {
    return $self->git->branch( '-M', $self->name, $new_name );
  }
  return $self->git->branch( '-m', $self->name, $new_name );
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Plus::Ref::Branch - A Branch object

=head1 VERSION

version 0.004011

=head1 SYNOPSIS

    use Git::Wrapper::Plus::Ref::Branch;

    my $branch = Git::Wrapper::Plus::Ref::Branch->new(
        git => $git_wrapper,
        name => 'master'
    );
    $branch->refname                                 # refs/heads/master
    $branch->sha1                                    # deadbeefbadf00da55c0ffee
    $branch->delete                                  # git branch -d master
    $branch->delete({ force => 1 });                 # git branch -D master
    $branch->move('alternative');                    # git branch -m master alternative
    $branch->move('alternative', { force => 1 });    # git branch -M master alternative

=head1 METHODS

=head2 C<new_from_Ref>

Convert a Plus::Ref to a Plus::Ref::Branch

    my $branch_object = $class->new_from_Ref( $ref_object );

=head2 C<refname>

Returns C<name>, in the form C<< refs/heads/B<< <name> >> >>

=head2 C<sha1>

Returns the C<SHA1> of the branch tip.

=head2 C<delete>

    $branch->delete(); # git branch -d $branch->name

    $branch->delete({ force => 1 }); # git branch -D $branch->name

Note: C<$branch> will of course still exist after this step.

=head2 C<move>

    $branch->move($new_name); # git branch -m $branch->name, $new_name

    $branch->move($new_name, { force => 1 }); # git branch -M $branch->name $new_name

Note: C<$branch> will of course, still exist after this step

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Git::Wrapper::Plus::Ref::Branch",
    "interface":"class",
    "inherits":"Git::Wrapper::Plus::Ref"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
