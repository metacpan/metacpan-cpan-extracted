#
# This file is part of HTML-Zoom-Parser-HTML-Parser
#
# This software is copyright (c) 2013 by Matthew Phillips.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package HTML::Zoom::Parser::HTML::Parser;
{
  $HTML::Zoom::Parser::HTML::Parser::VERSION = '1.130810';
}
# ABSTRACT: Glue to power HTML::Zoom with HTML::Parser

use strictures 1;
use base qw(HTML::Zoom::SubObject);

use HTML::TokeParser;
use HTML::Entities;


sub html_to_events {
    my ($self, $text) = @_;
    my @events;
    _toke_parser($text => sub {
        push @events, $_[0];
    });
    return \@events;
}

sub html_to_stream {
    my ($self, $text) = @_;
    return $self->_zconfig->stream_utils
                ->stream_from_array(@{$self->html_to_events($text)});
}

sub _toke_parser {
    my ($text, $handler) = @_;

    my $parser = HTML::TokeParser->new(\$text) or return $!;
    # HTML::Parser downcases by default

    while (my $token = $parser->get_token) {
        my $type = shift @$token;

        # we break down what we emit to stream handler by type
        # start tag
        if ($type eq 'S') {
            my ($tag, $attr, $attrseq, $text) = @$token;
            my $in_place = delete $attr->{'/'}; # val will be '/' if in place
            $attrseq = [ grep { $_ ne '/' } @$attrseq ] if $in_place;
            if (substr($tag, -1) eq '/') {
                $in_place = '/';
                chop $tag;
            }

            $handler->({
              type => 'OPEN',
              name => $tag,
              attrs => $attr,
              is_in_place_close => $in_place,
              attr_names => $attrseq,
              raw => $text,
            });

            # if attr '/' exists, assume an inplace close, and emit a CLOSE as well
            if ($in_place) {
                $handler->({
                    type => 'CLOSE',
                    name => $tag,
                    raw => '', # don't emit $text for raw, match builtin behavior
                    is_in_place_close => 1,
                });
            }
        }

        # end tag
        if ($type eq 'E') {
            my ($tag, $text) = @$token;
            $handler->({
                type => 'CLOSE',
                name => $tag,
                raw => $text,
                # is_in_place_close => 1  for br/> ??
            });
        }

        # text
        if ($type eq 'T') {
            my ($text, $is_data) = @$token;
            $handler->({
                type => 'TEXT',
                raw => $text
            });
        }

        # comment
        if ($type eq 'C') {
            my ($text) = @$token;
            $handler->({
                type => 'SPECIAL',
                raw => $text
            });
        }

        # declaration
        if ($type eq 'D') {
            my ($text) = @$token;
            $handler->({
                type => 'SPECIAL',
                raw => $text
            });
        }

        # process instructions
        if ($type eq 'PI') {
            my ($token0, $text) = @$token;
        }
    }
}

sub html_escape { encode_entities($_[1]) }

sub html_unescape { decode_entities($_[1]) }

1;

__END__
=pod

=head1 NAME

HTML::Zoom::Parser::HTML::Parser - Glue to power HTML::Zoom with HTML::Parser

=head1 VERSION

version 1.130810

=head1 SYNOPSIS

    my $zoom = HTML::Zoom->new( {
        zconfig => {
            parser => 'HTML::Zoom::Parser::HTML::Parser'
        }
    } );

    $zoom->from_html($template); # etc ...

=head1 DESCRIPTION

This module provides a bridge to HTML::Parser to be used with HTML::Zoom. You may want to use this over Parser::BuiltIn for improved handling of malformed html. There could potentially be a performance boost from HTML::Parser's XS bits, though I've not benchmarked.

Using this Parser over BuiltIn should require no different usage with HTML::Zoom.

=head1 SEE ALSO

=over 4

=item *

L<HTML::Zoom>

=item *

L<HTML::Parser>

=back

=head1 AUTHOR

Matthew Phillips <mattp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Matthew Phillips.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

