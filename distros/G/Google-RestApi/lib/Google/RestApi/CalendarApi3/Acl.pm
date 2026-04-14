package Google::RestApi::CalendarApi3::Acl;

our $VERSION = '2.2.1';

use Google::RestApi::Setup;

use parent 'Google::RestApi::SubResource';

sub new {
  my $class = shift;
  state $check = signature(
    bless => !!0,
    named => [
      calendar => HasApi,
      id       => Str, { optional => 1 },
    ],
  );
  return bless $check->(@_), $class;
}

sub _uri_base { 'acl' }
sub _parent_accessor { 'calendar' }
sub _resource_name { 'ACL' }

sub create {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      role        => Str,
      scope_type  => Str,
      scope_value => Str, { optional => 1 },
      _extra_     => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  my %content = (
    role  => delete $p->{role},
    scope => {
      type => delete $p->{scope_type},
    },
  );
  $content{scope}{value} = delete $p->{scope_value} if defined $p->{scope_value};

  DEBUG(sprintf("Creating ACL rule on calendar '%s'", $self->calendar()->calendar_id()));
  my $result = $self->calendar()->api(
    uri     => 'acl',
    method  => 'post',
    content => \%content,
  );
  return ref($self)->new(calendar => $self->calendar(), id => $result->{id});
}

sub get {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      fields => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);

  $self->require_id('get');

  my %params;
  $params{fields} = $p->{fields} if defined $p->{fields};

  return $self->api(params => \%params);
}

sub update {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      role    => Str,
      _extra_ => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  $self->require_id('update');

  my %content = (
    role => delete $p->{role},
  );

  DEBUG(sprintf("Updating ACL rule '%s' on calendar '%s'", $self->{id}, $self->calendar()->calendar_id()));
  return $self->api(
    method  => 'patch',
    content => \%content,
  );
}

sub delete {
  my $self = shift;

  $self->require_id('delete');

  DEBUG(sprintf("Deleting ACL rule '%s' from calendar '%s'", $self->{id}, $self->calendar()->calendar_id()));
  return $self->api(method => 'delete');
}

sub acl_id { shift->{id}; }
sub calendar { shift->{calendar}; }

1;

__END__

=head1 NAME

Google::RestApi::CalendarApi3::Acl - ACL (Access Control) object for Google Calendar.

=head1 SYNOPSIS

 # Get an ACL rule
 my $acl = $calendar->acl(id => 'rule_id');
 my $details = $acl->get();

 # Create a new ACL rule
 my $new_acl = $calendar->acl()->create(
   role        => 'reader',
   scope_type  => 'user',
   scope_value => 'user@example.com',
 );

 # Update ACL rule
 $acl->update(role => 'writer');

 # Delete ACL rule
 $acl->delete();

=head1 DESCRIPTION

Represents an access control rule on a Google Calendar. Supports creating,
reading, updating, and deleting ACL rules.

=head1 METHODS

=head2 create(role => $role, scope_type => $type, scope_value => $value)

Creates a new ACL rule. Required parameters:

=over

=item * role: 'none', 'freeBusyReader', 'reader', 'writer', 'owner'

=item * scope_type: 'default', 'user', 'group', 'domain'

=item * scope_value: Email address or domain (optional for 'default' type)

=back

=head2 get(fields => $fields)

Gets ACL rule details. Requires ACL ID.

=head2 update(role => $role)

Updates the ACL rule role. Requires ACL ID.

=head2 delete()

Deletes the ACL rule. Requires ACL ID.

=head2 acl_id()

Returns the ACL rule ID.

=head2 calendar()

Returns the parent Calendar object.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
