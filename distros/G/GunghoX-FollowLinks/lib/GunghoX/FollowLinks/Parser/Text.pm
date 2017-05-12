# $Id: /mirror/perl/GunghoX-FollowLinks/trunk/lib/GunghoX/FollowLinks/Parser/Text.pm 39011 2008-01-16T15:31:39.350176Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package GunghoX::FollowLinks::Parser::Text;
use strict;
use warnings;
use base qw(GunghoX::FollowLinks::Parser);

sub new
{
    my $class = shift;
    $class->SUPER::new( content_type => 'text/plain', @_ );
}

sub parse
{
    my ($self, $c, $response) = @_;

    my $base = $response->request->uri;
    my $content = $response->content;

    my $count = 0;
    while ( $content =~ m{\b(?:[^:/?#]+:)?(?://[^/?#]*)?[^?#]*(?:\?[^#]*)?(?:#.*?))\b}gsm ) {
        my $uri = URI->new_abs( $1, $base );
        $self->apply_filters($c, $uri);
        if ($self->follow_if_allowed( $c, $response, $uri )) {
            $count++;
        }
    }
    return $count;
}

1;

__END__

=head1 NAME

GunghoX::FollowLinks::Parser::Text - Parse URLs Out Of Plain Text

=head1 SYNOPSIS

  my $parser = GunghoX::FollowLinks::Parser::Text->new(
    rules => [
      ...
    ]
  );
  my $count = $parser->parse($text);

=head1 DESCRIPTION

Parses text, looking for URLs.

=head1 METHODS

=head1 new

=head1 parse

=cut