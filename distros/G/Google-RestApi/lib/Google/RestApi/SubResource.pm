package Google::RestApi::SubResource;

our $VERSION = '2.2.2';

use Google::RestApi::Setup;

sub api {
  my $self = shift;
  my %p = @_;
  my $uri = $self->_uri_base();
  $uri .= "/$self->{id}" if $self->{id};
  $uri .= "/$p{uri}" if $p{uri};
  delete $p{uri};
  my $accessor = $self->_parent_accessor();
  return $self->$accessor()->api(%p, uri => $uri);
}

sub require_id {
  my ($self, $method) = @_;
  LOGDIE $self->_resource_name() . " ID required for $method()" unless $self->{id};
  return;
}

sub _resource_name {
  my $self = shift;
  my $class = ref($self) || $self;
  $class =~ /([^:]+)$/;
  return $1;
}

sub _uri_base { LOGDIE ref(shift) . " must override _uri_base()"; }
sub _parent_accessor { LOGDIE ref(shift) . " must override _parent_accessor()"; }

1;

__END__

=head1 NAME

Google::RestApi::SubResource - Base class for Google API sub-resources.

=head1 DESCRIPTION

SubResource provides a common base class for API sub-resource modules
(Comment, Reply, Permission, Event, Label, etc.). It eliminates
duplicated C<api()> methods by providing a generic URI builder that
assembles C<_uri_base() + /$id + /$child_uri> and delegates to the
parent object's C<api()>.

Subclasses must override two methods:

=over

=item * C<_uri_base()> - returns the URI path segment (e.g. C<'comments'>, C<'events'>)

=item * C<_parent_accessor()> - returns the accessor name for the parent object (e.g. C<'file'>, C<'calendar'>)

=back

See L<Google::RestApi/Chained API Calls> for a walkthrough of how the
chained C<api()> delegation works.

=head1 METHODS

=head2 api(%args)

Generic URI builder. Assembles the URI from C<_uri_base()>, the object's
ID (if set), and any child C<uri> passed in C<%args>. Delegates to the
parent object's C<api()> via the accessor returned by C<_parent_accessor()>.

=head2 _resource_name()

Returns the short class name (e.g. C<'Comment'>, C<'TaskList'>). Used
in error messages from C<require_id()>. Override if the default derived
name is not suitable (e.g. Acl overrides to C<'ACL'>).

=head2 _uri_base()

Pure virtual. Subclass must return the URI path segment for this resource.

=head2 _parent_accessor()

Pure virtual. Subclass must return the method name that accesses the
parent object.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
