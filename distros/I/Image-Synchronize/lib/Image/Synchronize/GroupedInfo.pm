package Image::Synchronize::GroupedInfo;

use warnings;
use strict;

use v5.10.0;

use overload '""' => \&stringify;

use Carp;

=head1 NAME

Image::Synchronize::GroupedInfo - a data collection in support of Image::Synchronize

=cut

=head1 METHODS

=head2 new

  $egi = new Image::Synchronize::GroupedInfo;

Create a new instance of the class.

=cut

sub new {
  my ($class) = @_;
  return bless {}, $class;
}

=head2 set

  $egi->set($tag, $value);
  $egi->set($group, $tag, $value);

Associated the C<$value> with the C<$tag> and (optionally) C<$group>.
The C<$group> and C<$tag> must be scalars, but the C<$value> may be of
any type.  Returns C<$egi>.

=cut

sub set {
  my $self = shift;
  my ( $group, $tag, $value );
  if ( scalar(@_) == 3 ) {
    ( $group, $tag, $value ) = @_;
  }
  elsif ( scalar(@_) == 2 ) {
    ( $tag, $value ) = @_;
  }
  else {
    croak "Expected tag and value, or group, tag, and value.";
  }
  if ( defined $value ) {
    $self->{$tag}->{ $group // '' } = $value;
  }
  else {    # delete
    if ( defined $group ) {
      $self->delete( $group, $tag );
    }
    else {
      $self->delete($tag);
    }
  }
  return $self;
}

=head2 get_context

  $value = $egi->get_context($group, $tag);

  # get_context value from preferred group
  $value = $egi->get_context($tag);

  # list context: also return group name
  ($group, $value) = $egi->get_context($group, $tag);
  ($group, $value) = $egi->get_context($tag);

Returns the value for the specified C<$tag> in the specified C<$group>
or in the preferred group.  In list mode, returns the group and the
value.  Returns C<undef> if the value is undefined or if there is no
value for that tag and group.

=cut

sub get_context {
  my ($self) = shift;
  my ( $group, $tag );
  if ( scalar(@_) == 2 ) {
    ( $group, $tag ) = @_;
  }
  elsif ( scalar(@_) == 1 ) {
    ($tag) = @_;
  }
  else {
    croak "Expected tag, or group and tag.";
  }
  return unless exists $self->{$tag};
  if ( defined $group ) {
    return
      wantarray ? ( $group, $self->{$tag}->{$group} ) : $self->{$tag}->{$group};
  }
  else {
    # look for groups in descending order of preference
    foreach my $group ( '', 'XMP', 'EXIF', 'File' ) {
      my $v = $self->{$tag}->{$group};
      if ( defined $v ) {
        return wantarray ? ( $group, $v ) : $v;
      }
    }

    # otherwise return value for lexicographically first group
    my $g = ( sort keys %{ $self->{$tag} } )[0];
    return wantarray ? ( $g, $self->{$tag}->{$g} ) : $self->{$tag}->{$g};
  }
}

=head2 get

  $value = $egi->get($group, $tag);

  # get value from preferred group
  $value = $egi->get($tag);

Returns the value for the specified C<$tag> in the specified C<$group>
or in the preferred group.  Returns C<undef> if the value is undefined
or if there is no value for that tag and group.

Is like L</get_context> but always returns just the value.

=cut

sub get {
  my $v = get_context(@_);
  return $v;
}

=head2 delete

  $egi->delete($tag);
  $egi->delete($group, $tag);

Deletes data associated with the C<$tag>.  If the C<$group> is
specified, then deletes the tag's data for that group only.  Otherwise
deletes the tag's data for any group.  Returns C<$egi>.

=cut

sub delete {
  my ($self) = shift;
  my ( $group, $tag );
  if ( scalar(@_) == 2 ) {
    ( $group, $tag ) = @_;
  }
  elsif ( scalar(@_) == 1 ) {
    ($tag) = @_;
  }
  else {
    croak "Expected tag, or group and tag.";
  }
  if ( defined $group ) {
    delete $self->{$tag}->{$group};
  }
  else {
    delete $self->{$tag};
  }
  return $self;
}

=head2 tags

  @tags = $egi->tags;

Returns a list of all tags for which a value was specified.

=cut

sub tags {
  my ($self) = @_;
  return sort keys %{$self};
}

=head2 groups

  @groups = $egi->groups($tag);

Returns a list of all groups for which a value was specified for the
C<$tag>.

=cut

sub groups {
  my ( $self, $tag ) = @_;
  return () unless exists $self->{$tag};
  return sort keys %{ $self->{$tag} };
}

=head2 stringify

  $text = $egi->stringify;
  $text = "$egi";

Returns a text version of the contents of C<$egi>.

=cut

sub stringify {
  my ( $self, $prefix ) = @_;
  $prefix //= '';
  my @text;
  foreach my $tag ( $self->tags ) {
    foreach my $group ( $self->groups($tag) ) {
      my $key = $tag;
      $key .= " ($group)" if $group;
      push @text,
        $prefix . sprintf( '%-35s : ', $key ) . $self->get( $group, $tag );
    }
  }
  return join( "\n", @text );
}

1;
