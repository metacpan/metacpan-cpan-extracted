# $Id: /mirror/perl/GunghoX-FollowLinks/trunk/lib/GunghoX/FollowLinks/Parser/HTML.pm 40584 2008-01-29T14:54:08.742000Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package GunghoX::FollowLinks::Parser::HTML;
use strict;
use warnings;
use base qw(GunghoX::FollowLinks::Parser);
use HTML::Parser;
use HTML::Tagset;
use URI;
use List::Util qw(shuffle);

__PACKAGE__->mk_accessors($_) for qw(parser);

sub new 
{
    my $class = shift;
    my $parser = HTML::Parser->new(
        start_h     => [ \&_start, "self,tagname,attr" ],
        report_tags => [ keys %HTML::Tagset::linkElements ],
    );
    return $class->next::method(
        content_type => 'text/html',
        @_,
        parser => $parser
    );
}

sub _start
{
    my ($self, $tag, $attr) = @_;

    my $links = $HTML::Tagset::linkElements{ $tag };
    $links = [ $links ] unless ref $links;

    my $container = $self->{ 'container' };
    my $c         = $self->{ 'context' };
    my $response  = $self->{ 'response' };
    my $base      = $response->request->uri;
    foreach my $link_attr (shuffle @$links) {
        next unless exists $attr->{ $link_attr };

        my $url = URI->new_abs( $attr->{ $link_attr }, $base );
        if ($container->follow_if_allowed( $c, $response, $url, { tag => $tag, attr => $attr } )) {
            $self->{ 'count' }++;
        }
    }
}

sub parse
{
    my ($self, $c, $response) = @_;

    my $parser = $self->parser;
    local $parser->{ 'response' }  = $response;
    local $parser->{ 'container' } = $self;
    local $parser->{ 'context' }   = $c;
    local $parser->{ 'count' }     = 0;
    $parser->parse( $response->content );
    $parser->eof;
    return $parser->{ 'count' };
}

1;

__END__

=head1 NAME

GunghoX::FollowLinks::Parser::HTML - FollowLinks Parser For HTML Documents

=head1 METHODS

=head2 new

=head2 parse

=cut