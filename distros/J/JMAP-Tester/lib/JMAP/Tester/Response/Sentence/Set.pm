use v5.14.0;
package JMAP::Tester::Response::Sentence::Set 0.104;
# ABSTRACT: the kind of sentence you get in reply to a setFoos call

use Moo;
extends 'JMAP::Tester::Response::Sentence';

use Data::Dumper ();
use JMAP::Tester::Abort 'abort';

use namespace::clean;

#pod =head1 OVERVIEW
#pod
#pod A "Set" sentence is a kind of L<Sentence|JMAP::Tester::Response::Sentence>
#pod for representing C<foosSet> results.  It has convenience methods for getting
#pod out the data returned in these kinds of sentences.
#pod
#pod =method new_state
#pod
#pod This returns the C<newState> in the result.
#pod
#pod =method old_state
#pod
#pod This returns the C<newState> in the result.
#pod
#pod =cut

sub new_state { $_[0]->arguments->{newState} }
sub old_state { $_[0]->arguments->{oldState} }

#pod =method created
#pod
#pod This returns the hashref of data in the C<created> property.
#pod
#pod =method created_id
#pod
#pod   my $id = $set->created_id( $cr_id );
#pod
#pod This returns the id given to the object created for the given creation id.  If
#pod that creation id doesn't correspond to a created object, C<undef> is returned.
#pod
#pod =method created_creation_ids
#pod
#pod This returns the list of creation ids that were successfully created.  Note:
#pod this returns I<creation ids>, not object ids.
#pod
#pod =method created_ids
#pod
#pod This returns the list of object ids that were successfully created.
#pod
#pod =method not_created_ids
#pod
#pod This returns the list of creation ids that were I<not> successfully created.
#pod
#pod =method create_errors
#pod
#pod This returns a hashref mapping creation ids to error properties.
#pod
#pod =method updated_ids
#pod
#pod This returns a list of object ids that were successfully updated.
#pod
#pod =method not_updated_ids
#pod
#pod This returns a list of object ids that were I<not> successfully updated.
#pod
#pod =method update_errors
#pod
#pod This returns a hashref mapping object ids to error properties.
#pod
#pod =method destroyed_ids
#pod
#pod This returns a list of object ids that were successfully destroyed.
#pod
#pod =method not_destroyed_ids
#pod
#pod This returns a list of object ids that were I<not> successfully destroyed.
#pod
#pod =method destroy_errors
#pod
#pod This returns a hashref mapping object ids to error properties.
#pod
#pod =cut

sub as_set { $_[0] }

sub created { $_[0]->arguments->{created} // {} }

sub created_id {
  my ($self, $creation_id) = @_;
  return undef unless my $props = $self->created->{$creation_id};
  return $props->{id};
}

sub created_creation_ids {
  keys %{ $_[0]->created }
}

sub created_ids {
  map {; $_->{id} } values %{ $_[0]->created }
}

sub updated_ids   {
  my ($self) = @_;
  my $updated = $_[0]{arguments}{updated} // {};

  if (ref $updated eq 'ARRAY') {
    return @$updated;
  }

  return keys %$updated;
}

sub updated {
  my ($self) = @_;

  my $updated = $_[0]{arguments}{updated} // {};

  if (ref $updated eq 'ARRAY') {
    return { map {; $_ => undef } @$updated };
  }

  return $updated;
}

sub destroyed_ids { @{ $_[0]{arguments}{destroyed} } }

# Is this the best API to provide?  I dunno, maybe.  Usage will tell us whether
# it's right. -- rjbs, 2016-04-11
sub not_created_ids   { keys %{ $_[0]{arguments}{notCreated} }   }
sub not_updated_ids   { keys %{ $_[0]{arguments}{notUpdated} }   }
sub not_destroyed_ids { keys %{ $_[0]{arguments}{notDestroyed} } }

sub create_errors     { $_[0]{arguments}{notCreated}   // {} }
sub update_errors     { $_[0]{arguments}{notUpdated}   // {} }
sub destroy_errors    { $_[0]{arguments}{notDestroyed} // {} }

sub assert_no_errors {
  my ($self) = @_;

  my @errors;
  local $Data::Dumper::Terse = 1;

  if (keys %{ $self->create_errors }) {
    push @errors, "notCreated: " .  Data::Dumper::Dumper(
      $self->_strip_json_types( $self->create_errors )
    );
  }

  if (keys %{ $self->update_errors }) {
    push @errors, "notUpdated: " .  Data::Dumper::Dumper(
      $self->_strip_json_types( $self->update_errors )
    );
  }

  if (keys %{ $self->destroy_errors }) {
    push @errors, "notDestroyed: " .  Data::Dumper::Dumper(
      $self->_strip_json_types( $self->destroy_errors )
    );
  }

  return $self unless @errors;

  $self->sentence_broker->abort(
    "errors found in " . $self->name . " sentence",
    \@errors,
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Response::Sentence::Set - the kind of sentence you get in reply to a setFoos call

=head1 VERSION

version 0.104

=head1 OVERVIEW

A "Set" sentence is a kind of L<Sentence|JMAP::Tester::Response::Sentence>
for representing C<foosSet> results.  It has convenience methods for getting
out the data returned in these kinds of sentences.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 METHODS

=head2 new_state

This returns the C<newState> in the result.

=head2 old_state

This returns the C<newState> in the result.

=head2 created

This returns the hashref of data in the C<created> property.

=head2 created_id

  my $id = $set->created_id( $cr_id );

This returns the id given to the object created for the given creation id.  If
that creation id doesn't correspond to a created object, C<undef> is returned.

=head2 created_creation_ids

This returns the list of creation ids that were successfully created.  Note:
this returns I<creation ids>, not object ids.

=head2 created_ids

This returns the list of object ids that were successfully created.

=head2 not_created_ids

This returns the list of creation ids that were I<not> successfully created.

=head2 create_errors

This returns a hashref mapping creation ids to error properties.

=head2 updated_ids

This returns a list of object ids that were successfully updated.

=head2 not_updated_ids

This returns a list of object ids that were I<not> successfully updated.

=head2 update_errors

This returns a hashref mapping object ids to error properties.

=head2 destroyed_ids

This returns a list of object ids that were successfully destroyed.

=head2 not_destroyed_ids

This returns a list of object ids that were I<not> successfully destroyed.

=head2 destroy_errors

This returns a hashref mapping object ids to error properties.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
