package Escape::Houdini;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Perl API to Houdini, a zero-dependency C web escaping library
$Escape::Houdini::VERSION = '0.3.1';
use strict;
use warnings;

use parent qw/ DynaLoader Exporter /;

our %EXPORT_TAGS = (
    all => [ qw/ escape_html unescape_html escape_xml
        escape_uri escape_url escape_href
        unescape_uri unescape_url
        escape_js unescape_js
        / ],
    html => [ qw/ escape_html unescape_html /],
    uri => [ qw/ escape_uri unescape_uri /],
    url => [ qw/ escape_url unescape_url /],
    js  => [ qw/ escape_js unescape_js /],
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

__PACKAGE__->bootstrap;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Escape::Houdini - Perl API to Houdini, a zero-dependency C web escaping library

=head1 VERSION

version 0.3.1

=head1 SYNOPSIS

    use Escape::Houdini ':all';

    my $escaped = escape_html( '<foo>' );
    # $escaped is now '&lt;foo&gt;'

=head1 DESCRIPTION

I<Escape::Houdini> is a wrapper around the zero-depedency, minimalistic
web escaping C library L<Houdini|https://github.com/vmg/houdini>.

This version of I<Escape::Houdini> has been built against
the commit
L<https://github.com/vmg/houdini/commit/3e2a78a2399bf3f58253c435278df6daf0e41740>
of Houdini.

=head1 FUNCTIONS

=head2 escape_html( $text )

    escape_html( '<body class="foo">' ); # => '&lt;body class=&quot;foo&quot;&gt;'

=head2 unescape_html( $text )

    unescape_html( "&lt;body&gt;" ); # => '<body>'

=head2 escape_xml( $text )

    escape_xml( "<foo>" ); # => '&lt;foo&gt;'

=head2 escape_uri( $text )

=head2 unescape_uri( $text )

=head2 escape_url( $text )

    escape_url("http://foo.com/meh"); # => 'http%3A%2F%2Ffoo.com%2Fmeh'

=head2 unescape_url( $text )

    unescape_url('http%3A%2F%2Ffoo.com%2Fmeh'); # => "http://foo.com/meh"

=head2 escape_href( $text )

=head2 escape_js( $text )

    escape_js( "foo\nbar" ); # => 'foo\nbar'

=head2 unescape_js( $text )

    escape_js( 'foo\nbar' ); # => "foo\nbar"

=head1 EXPORTS

I<Escape::Houdini> doesn't export any function by default. Functions can be
exported individually, or via the following tags:

    | tag   | exported functions         |
    |-------|----------------------------|
    | :all  | all o' them                |
    | :html | escape_html, unescape_html |
    | :uri  | escape_uri, unescape_uri   |
    | :url  | escape_url, unescape_url   |
    | :js   | escape_js, unescape_js     |

=head1 SEE ALSO

Houdini (natch) - L<https://github.com/vmg/houdini>

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2014, 2013 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
