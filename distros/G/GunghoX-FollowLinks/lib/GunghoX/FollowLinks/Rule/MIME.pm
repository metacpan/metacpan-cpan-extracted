# $Id: /mirror/perl/GunghoX-FollowLinks/trunk/lib/GunghoX/FollowLinks/Rule/MIME.pm 8922 2007-11-12T03:06:00.677781Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package GunghoX::FollowLinks::Rule::MIME;
use strict;
use warnings;
use base qw(GunghoX::FollowLinks::Rule);
use MIME::Types;
use GunghoX::FollowLinks::Rule qw(FOLLOW_ALLOW FOLLOW_DENY FOLLOW_DEFER);

__PACKAGE__->mk_accessors($_) for qw(types mime unknown);

sub new
{
    my $class = shift;
    my %args  = @_;

    $class->next::method(action => FOLLOW_ALLOW, @_, mime => MIME::Types->new);
}

sub apply
{
    my ($self, $c, $response, $url, $attrs) = @_;

    my $mime = $self->mime->mimeTypeOf( $url );

    if (! defined $mime) {
        $c->log->debug("MIME type of $url is unknown");
        return ($self->unknown || FOLLOW_DEFER);
    }

    my @types = $self->types || [];
    foreach my $type (@types) {
        return $self->action  if $mime->type eq $type;
    }
    return FOLLOW_DENY;
}

1;

__END__

=head1 NAME

GunghoX::FollowLinks::Rule::MIME - Follow Based On MIME Type

=head1 SYNOPSIS

  use GunghoX::FollowLinks::Rule::MIME;

  # Allow matched, deny unmatched, defer unknown
  my $rule = GunghoX::FollowLinks::Rule::MIME->new(
    types => [ qw(text/html text/plain) ]
  );

  # Deny unmatched, but allow if unknown
  my $rule = GunghoX::FollowLinks::Rule::MIME->new(
    unknown => FOLLOW_ALLOW,
    types   => [ qw(text/html) ]
  );

  # Only allow matched (deny unmatched, deny unknown)
  my $rule = GunghoX::FollowLinks::Rule::MIME->new(
    unknown => FOLLOW_DENY,
    types   => [ qw(text/html) ]
  );

=head1 DESCRIPTION

Rule::MIME allows you to use the file name extensions to guess the MIME type
of a link, and decided to follow or not based on the type

=head1 METHODS

=head2 new

=head2 apply

=cut
