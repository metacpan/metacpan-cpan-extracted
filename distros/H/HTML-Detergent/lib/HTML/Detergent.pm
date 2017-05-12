package HTML::Detergent;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use Scalar::Util ();
use URI          ();
use XML::LibXML  ();
use XML::LibXSLT ();
use XML::LibXML::LazyBuilder qw(DOM E);

use HTML::Detergent::Config qw(Config);

has config => (
    is       => 'ro',
    isa      => Config,
    coerce   => 1,
    required => 1,
);

has xml_parser => (
    is      => 'ro',
    isa     => 'XML::LibXML',
    default => sub { XML::LibXML->new(recover => 2) },
    lazy    => 1,
);

# has html_parser => (
#     is      => 'ro',
#     isa     => 'HTML::HTML5::Parser',
#     default => sub { require HTML::HTML5::Parser; HTML::HTML5::Parser->new },
#     lazy    => 1,
# );

has xpc => (
    is      => 'ro',
    isa     => 'XML::LibXML::XPathContext',
    default => sub {
        my $xpc = XML::LibXML::XPathContext->new;
        $xpc->registerNs('html' => 'http://www.w3.org/1999/xhtml');
        return $xpc;
    },
);



# XXX huh
my %LINKS = (
    head       => { profile  => 1, },
    script     => { src      => 1, },
    a          => { href     => 1, },
    area       => { href     => 1, },
    link       => { href     => 1, },
    form       => { action   => 1, },
    blockquote => { cite     => 1, },
    q          => { cite     => 1, },
    ins        => { cite     => 1, },
    del        => { cite     => 1, },
    frame      => { src      => 1,
                    longdesc => 1, },
    iframe     => { src      => 1,
                    longdesc => 1, },
    img        => { src      => 1,
                    longdesc => 1,
                    usemap   => 1, },
    object     => { data     => 1,
                    classid  => 1,
                    codebase => 1,
                    usemap   => 1, },
    input      => { src      => 1,
                    usemap   => 1, },
);

# turn aforementioned into a single xpath statement
my $LINKXP = join('|', map {
    sprintf('//html:%s[%s]', $_, join('|', map { "\@$_" } keys %{$LINKS{$_}} ))
} keys %LINKS);

=head1 NAME

HTML::Detergent - Clean the gunk off an HTML document

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use HTML::Detergent;

    my $scrubber = HTML::Detergent->new($config);

    # $input can be a string, GLOB reference, or XML::LibXML::Document

    my $doc = $scrubber->process($input, $uri);

=head1 DESCRIPTION

L<HTML::Detergent> is for isolating the main content of an HTML page,
stripping it of navigation, visual design, and other ancillary content.

The main purpose of this module is to aid in the migration of web
content from one content management system to another. It is also
useful for preparing HTML resources for automated content inventories.

The module currently has no heuristics for determining the main
content of a page. It works instead by assuming prior knowledge of the
layout, given in the configuration by an XPath expression that
uniquely isolates the container node. That node is then lifted into a
new document, along with the contents of the C<E<lt>headE<gt>>, and
returned by the L</process> method. To accommodate multiple layouts on
a site, the module can be initialized to match multiple XPath
expressions. If further processing is necessary, an expression can be
associated with an XSLT stylesheet, which is assumed to produce an
entire document, thus overriding the default behaviour.

After the new document is generated and before it is returned by
L</process>, it is possible to inject C<E<lt>linkE<gt>> and
C<E<lt>metaE<gt>> elements into the C<E<lt>headE<gt>>. This enables
the inclusion of metadata and the re-association of the main content
with links that represent aspects of the page which have been removed
(e.g. navigation, copyright statement, etc.). In addition, if the
page's URI is supplied to the L</process> method, the
C<E<lt>baseE<gt>> element is either added or rewritten to reflect it,
and the URI attributes in the body are rewritten relative to the base.
Otherwise they are left alone.

The document returned is an L<XML::LibXML::Document> object using the
XHTML namespace, C<http://www.w3.org/1999/xhtml>, but does not profess
to validate against any particular schema. If DTD declarations
(including the empty C<E<lt>!DOCTYPE htmlE<gt>> recommended in HTML5)
are desired, they can be added on afterward. Likewise, the object can
be converted from XML into HTML using L<XML::LibXML::Document/toStringHTML>.

=head1 METHODS

=head2 new %CONFIG | \%CONFIG | $CONFIG

Initialize the processor, either with a list of configuration
parameters, a HASH reference thereof, or an L<HTML::Detergent::Config>
object. Below are the valid parameters:

=over 4

=item match

This is an ARRAY reference of XPath expressions to try against the
document, in order of preference. Entries optionally may be
two-element ARRAY references themselves, the second element being a
URL where an XSLT stylesheet may be found.

    match => [ '/some/xpath/expression',
               [ '/other/expr', '/url/of/transform.xsl' ],
             ],

=item link

This is a HASH reference where the keys correspond to C<rel>
attributes and the values to C<href> attributes of C<E<lt>linkE<gt>>
elements. If the values are ARRAY references, they will be processed
in document order. C<rel> attributes will be sorted lexically. If a
callback is supplied instead, the caller expects a result of the same
form.

    link => { rel1 => 'href1', rel2 => [ qw(href2 href3) ] },

    # or

    link => \&_link_cb,

=item meta

This is a HASH reference where the keys correspond to C<name>
attributes and the values to C<content> attributes of
C<E<lt>metaE<gt>> elements. If the values are ARRAY references, they
will be processed in document order. C<name> attributes will be sorted
lexically. If a callback is supplied instead, the caller expects a
result of the same form.

    meta => { name1 => 'content1',
              name2 => [ qw(content2 content3) ] },

    # or

    meta => \&_meta_cb,

=item callback

These callbacks will be passed into the internal L<XML::LibXSLT>
processor. See L<XML::LibXML::InputCallback> for details.

    callback => [ \&_match_cb, \&_open_cb, \&_read_cb, \&_close_cb ],

    # or

    callback => $icb, # isa XML::LibXML::InputCallback

=back

=cut

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    return $class->$orig(config => $_[0]) if ref $_[0];

    my %p = @_;
    $class->$orig(config => \%p);
};

my %SHEET;

sub BUILD {
    my $self = shift;

    my $xslt = XML::LibXSLT->new;
    my $icb = $self->config->callback;
    $xslt->input_callbacks($icb) if $icb;

    # cache stylesheets
    for my $uri ($self->config->stylesheets) {
        $SHEET{$uri} ||= $xslt->parse_stylesheet_file($uri);
        #$SHEET{$uri} ||= $sheet;
    }
}

=head2 process $INPUT [, $URI, $CONFIG ]

Processes C<$INPUT>, which may be a string, GLOB reference, or
L<XML::LibXML::Document> object. Returns an L<XML::LibXML::Document>
object with the changes mentioned in the L</DESCRIPTION>.

=cut

sub process {
    my ($self, $input, $uri, @rest) = @_;

    if (my $ref = ref $input) {
        if (Scalar::Util::reftype($input) eq 'GLOB') {
            require HTML::HTML5::Parser;
            my $p = HTML::HTML5::Parser->new(no_cache => 1);
            $input = eval { $p->parse_fh($input) };
            Carp::croak("Failed to parse X(HT)ML input: $@") if $@;
        }
        elsif (Scalar::Util::blessed($input)
              and $input->isa('XML::LibXML::Document')) {
            # do nothing
        }
        else {
            Carp::croak("Don't know what to do with reference type $ref");
        }
    }
    else {
        require HTML::HTML5::Parser;
        my $p = HTML::HTML5::Parser->new(no_cache => 1);
        $input = eval { $p->parse_string($input) };
        Carp::croak("Failed to parse X(HT)ML input: $@") if $@;
    }

    my $xpc = $self->xpc;
    my $doc;
    for my $xpath ($self->config->matches) {
        #warn $xpath;

        #warn substr($input->toString, 0, 100);

        my @body = $xpc->findnodes($xpath, $input);
        #warn scalar @body;
        @body or next;

        if (my $uri = $self->config->stylesheet($xpath)) {
            #warn $uri;
            $doc = $SHEET{$uri}->transform($input);
        }
        else {
            my @head = map { $_->cloneNode(1) }
                $xpc->findnodes('/html:html/html:head/*', $input);

            @body = map { $_->cloneNode(1) } @body;

            $doc = DOM E html => { xmlns => 'http://www.w3.org/1999/xhtml' },
                (E head => {}, @head), (E body => {}, @body);
        }

        last if $doc;
    }

    return $input unless $doc;

    # don't do this if not an HTML doc
    if (my ($head) = $xpc->findnodes('/html:html/html:head', $doc)) {
        my ($firstl) = $xpc->findnodes('html:link', $head);
        my $links = $self->config->links;
        for my $k (keys %$links) {
            for my $v (@{$links->{$k}}) {
                # XXX abridge this
                my $link = $doc->createElementNS
                    ('http://www.w3.org/1999/xhtml', 'link');
                $link->setAttribute(rel  => $k);
                $link->setAttribute(href => $v);
                if ($firstl) {
                    $head->insertBefore($link, $firstl);
                }
                else {
                    $head->appendChild($link);
                }
            }
        }

        my $meta  = $self->config->metadata;
        my ($firstm) = $xpc->findnodes('html:link', $head);
        for my $k (keys %$meta) {
            for my $v (@{$meta->{$k}}) {
                # XXX abridge this
                my $meta = $doc->createElementNS
                    ('http://www.w3.org/1999/xhtml', 'meta');
                $meta->setAttribute(name    => $k);
                $meta->setAttribute(content => $v);
                if ($firstm) {
                    $head->insertBefore($meta, $firstm);
                }
                else {
                    $head->appendChild($meta);
                }
            }
        }

        # XXX should this even be part of it?

        # do base set/url rewrite
        if (defined $uri) {
            # make sure it's a URI object
            $uri = URI->new($uri) unless ref $uri;

            # start in this position
            my $olduri = $uri;

            # try to find a <base> element
            my ($base) = $xpc->findnodes('html:base[1]', $head);
            if ($base) {
                # rewrite the old base
                $olduri = URI->new($base->getAttribute('href'));
            }
            else {
                # make a new one if none found
                $base = $doc->createElementNS
                    ('http://www.w3.org/1999/xhtml', 'base');
                $head->appendChild($base);
            }

            # set base to the new URI
            $base->setAttribute(href => $uri);

            # now traverse the document looking for URI-like attributes
            for my $node ($xpc->findnodes($LINKXP, $doc)) {
                my $t = $LINKS{$node->localName};
                for my $u (keys %$t) {
                    if (defined (my $a = $node->getAttribute($u))) {
                        # absolute against the old uri, relative to
                        # the new one
                        $a = URI->new_abs($a, $olduri);
                        $a = $a->rel($uri);
                        $node->setAttribute($u, $a);
                    }
                }
            }
        }
    }

    $doc;
}


=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-detergent at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Detergent>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Detergent

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Detergent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-Detergent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-Detergent>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-Detergent/>

=back

=head1 SEE ALSO

=over 4

=item L<XML::LibXML>

=item L<XML::LibXSLT>

=item L<HTML::HTML5::Parser>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

__PACKAGE__->meta->make_immutable;
no Moose;

1; # End of HTML::Detergent
