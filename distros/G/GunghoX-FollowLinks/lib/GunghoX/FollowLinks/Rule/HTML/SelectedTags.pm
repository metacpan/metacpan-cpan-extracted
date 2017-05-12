# $Id: /mirror/perl/GunghoX-FollowLinks/trunk/lib/GunghoX/FollowLinks/Rule/HTML/SelectedTags.pm 8893 2007-11-10T14:30:51.466577Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package GunghoX::FollowLinks::Rule::HTML::SelectedTags;
use strict;
use warnings;
use base qw(GunghoX::FollowLinks::Rule);

__PACKAGE__->mk_accessors($_) for qw(tags);

sub apply
{
    my ($self, $c, $response, $url, $attrs) = @_;

    my $tags = $self->tags || [];
    my $tag = $attrs->{tag} || '';

    foreach my $want (@$tags) {
        return &GunghoX::FollowLinks::Rule::FOLLOW_ALLOW if $tag eq $want;
    }
    return &GunghoX::FollowLinks::Rule::FOLLOW_DENY;
}

1;

__END__

=head1 NAME

GunghoX::FollowLinks::Rule::HTML::SelectedTags - Follow Only On Selected Tags

=head1 SYNOPSIS

  GunghoX::FollowLinks::Rule::HTML::SelectedTags->new(
    tags => [ 'a', 'img' ]
  );

=head1 METHODS

=head2 apply($c, $response, $url, { tag => $tag, attrs => $attrs })

=cut