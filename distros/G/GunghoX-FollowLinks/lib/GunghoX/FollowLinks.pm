# $Id: /mirror/perl/GunghoX-FollowLinks/trunk/lib/GunghoX/FollowLinks.pm 40585 2008-01-29T15:58:05.363572Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package GunghoX::FollowLinks;
use strict;
use warnings;
use base qw(Gungho::Component);
use Class::Null;
use Gungho::Util;
our $VERSION = '0.00006';

__PACKAGE__->mk_classdata($_) for qw(follow_links_parsers follow_link_log);

sub setup
{
    my $c = shift;
    $c->next::method();

    my $config = $c->config->{follow_links};

    $c->follow_links_parsers( {} );
    foreach my $parser_config (@{ $config->{parsers} }) {
        my $module = $parser_config->{module};
        my $pkg    = Gungho::Util::load_module($module, 'GunghoX::FollowLinks::Parser');
        my $obj    = $pkg->new( %{ $parser_config->{config} } );

        $obj->register( $c );
    }

    $c;
}

sub follow_links
{
    my ($c, $response) = @_;

    eval {
        my $content_type = $response->content_type;
        my $parser =
            $c->follow_links_parsers->{ $content_type } ||
            $c->follow_links_parsers->{ 'DEFAULT' } 
        ;
        if ($parser) {
            $c->log->debug( "Parsing links for " . $response->request->uri );
            $parser->parse( $c, $response );
        }
    };
    warn if $@;
}

1;

__END__

=head1 NAME

GunghoX::FollowLinks - Automatically Follow Links Within Responses

=head1 SYNOPSIS

  follow_links:
    parsers:
      - module: HTML
        config:
          rules:
            - module: HTML::SelectedTags
              config:
                tags:
                  - a
            - module: MIME
              config:
                types:
                  - text/html
      - module: Text
        config:
          rules:
            - module: URI
              config:
                match:
                  - host: ^example\.com
                    action: FOLLOW_ALLOW

  package MyHandler;
  sub handle_response
  {
    my ($self, $c, $req, $res) = @_;
    $c->follow_links($res);
  }

=head1 DESCRIPTION

The most common action that a crawler takes is to follow links on a page.
This module helps you with that task.

=head1 METHODS

=head2 setup

=head2 follow_links

Parses the given HTTP::Response/Gungho::Response object and dispatches the
appropriate parser from its content-type.

For each URL found, Automatically dispatches the rules given to the parser,
and if the rules match, the URL is sent to Gungho-E<gt>send_request.

Returns the number of matches found.
              
=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
