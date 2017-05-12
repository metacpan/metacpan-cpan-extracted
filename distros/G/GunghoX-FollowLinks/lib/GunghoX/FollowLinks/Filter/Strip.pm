# $Id: /mirror/perl/GunghoX-FollowLinks/trunk/lib/GunghoX/FollowLinks/Filter/Strip.pm 40582 2008-01-29T13:53:00.542283Z daisuke  $

package GunghoX::FollowLinks::Filter::Strip;
use strict;
use warnings;
use base qw(GunghoX::FollowLinks::Filter);
use URI;

my @fields = qw(strip_fragment strip_query strip_userinfo);
__PACKAGE__->mk_accessors($_) for @fields;

sub new
{
    my $class = shift;
    my %args  = @_;

    foreach my $key (@fields) {
        $args{$key} = exists $args{$key} ? $args{$key} : 1;
    }
    $class->SUPER::new(%args);
}

sub apply
{
    my ($self, $c, $uri) = @_;

    $c->log->debug("[FILTER] Removing " . 
        join(', ',
            map { $self->$_ ? "$_=YES" : "$_=NO" } @fields
        )
    );

    $uri->fragment(undef) if $uri->can('fragment') && $self->strip_fragment;
    $uri->query(undef)    if $uri->can('query') && $self->strip_query;
    $uri->userinfo(undef) if $uri->can('userinfo') && $self->strip_userinfo;
}

1;