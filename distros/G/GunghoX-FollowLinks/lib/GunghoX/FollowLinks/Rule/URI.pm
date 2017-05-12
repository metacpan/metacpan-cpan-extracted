# $Id: /mirror/perl/GunghoX-FollowLinks/trunk/lib/GunghoX/FollowLinks/Rule/URI.pm 39010 2008-01-16T14:50:27.747072Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package GunghoX::FollowLinks::Rule::URI;
use strict;
use warnings;
use base qw(GunghoX::FollowLinks::Rule);
use GunghoX::FollowLinks::Rule qw(FOLLOW_ALLOW FOLLOW_DENY FOLLOW_DEFER);
use URI::Match;

__PACKAGE__->mk_accessors($_) for qw(match);

sub new
{
    my $class = shift;
    my %args  = @_;
    my $match = $args{match};
    foreach my $m (@$match) {
        my $action = $m->{action} || FOLLOW_ALLOW;
        if ($action eq 'FOLLOW_ALLOW') {
            $m->{action} = FOLLOW_ALLOW;
        } elsif ($action eq 'FOLLOW_DENY') {
            $m->{action} = FOLLOW_DENY;
        }
        if ($action eq 'FOLLOW_DEFER') {
            $m->{action} = FOLLOW_DEFER;
        }
    }
    $class->next::method(%args);
}

sub apply
{
    my ($self, $c, $response, $url, $attrs) = @_;

    my $match = $self->match;
    foreach my $m (@$match) {
        my %m = %$m;
        my $action = delete $m{action} || FOLLOW_ALLOW;
        my $nomatch = delete $m{action_nomatch};

        my @match_args;
        if ($m{url}) {
            @match_args = ($m{url});
        } else {
            @match_args = %m;
        }

        if ($url->match_parts(@match_args)) {
            return $action;
        }

        if (defined $nomatch) {
            return $nomatch;
        }
    }
    return &GunghoX::FollowLinks::Rule::FOLLOW_DEFER;
}

1;

__END__

=head1 NAME

GunghoX::FollowLinks::Rule::URI - Follow Dependig On URI

=head1 SYNOPSIS

  use GunghoX::FollowLinks::Rule qw(FOLLOW_ALLOW FOLLOW_DENY);
  use GunghoX::FollowLinks::Rule::URI;

  GunghoX::FollowLinks::Rule::URI->new(
    match => [
      { action => FOLLOW_DENY,  host => qr/^.+\.example\.org$/ },
      { action => FOLLOW_ALLOW, host => qr/^.+\.example\.com$/ },
      {
        action         => FOLLOW_ALLOW,
        action_nomatch => FOLLOW_DENY,
        host           => qr/^.+\.example\.net$/ }
      }
    ]
  );

=head1 DESCRIPTION

This is a rule that matches against a URL using URI::Match.

=head1 METHODS

=head2 new

=head2 apply

=cut
