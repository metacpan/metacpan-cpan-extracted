package HTML::Grabber;
{
  $HTML::Grabber::VERSION = '0.7';
}

# ABSTRACT: jQuery style DOM traversal/manipulation

use strict;
use warnings;

use Moose;
use HTML::Selector::XPath qw(selector_to_xpath);
use XML::LibXML qw(:libxml);

my $parser = XML::LibXML->new;
$parser->recover(1);

has nodes => (
    traits   => ['Array'],
    isa      => 'ArrayRef[XML::LibXML::Node]',
    writer   => '_nodes',
    required => 1,
    default  => sub { [] },
    handles  => {
        nodes       => 'elements',
        length      => 'count',
    },
);

=head1 NAME

HTML::Grabber

=head1 SYNOPSIS

    use HTML::Grabber;
    use LWP::Simple;

    my $dom = HTML::Grabber->new( html => get('http://twitter.com/ned0r') );

    $dom->find('.tweet-content')->each(sub {
        my $body = $_->find('.tweet-text')->text;
        my $when = $_->find('.js-tweet-timestamp')->attr('data-time');
        my $link = $_->find('.js-permalink')->attr('href');
        print "$body $when (link: $link)\n";
    });

=head1 DESCRIPTION

HTML::Grabber provides a jQuery style interface to HTML documents. This makes
parsing and manipulating HTML documents trivially simple for those people
familiar with L<http://jquery.com>.

It uses L<XML::LibXML> for DOM parsing/manipulation and
L<HTML::Selector::XPath> for converting CSS expressions into XPath.

=head1 AUTHOR

Martyn Smith <martyn@dollyfish.net.nz>

=head1 SELECTORS

All selectors are CSS. They are internally converted to XPath using
L<HTML::Selector::XPath>. If some creative selector you're trying isn't working
as expected, it may well be worth checking out the documentation for that
module to see if it's supported.

=head1 METHODS

=head2 BUILD

=cut

sub BUILD {
    my ($self, $args) = @_;

    if ( exists $args->{html} ) {
        my $dom = $parser->parse_html_string($args->{html}, { suppress_warnings => 1, suppress_errors => 1 });
        $self->_nodes([$dom]);
    }
}

=head2 find( $selector )

Get descendants of each element in the current set of matched elements,
filtered by a selector.

=cut
sub find {
    my ($self, $selector) = @_;

    my $xpath = selector_to_xpath($selector, root => './');

    my @nodes;
    foreach my $node ( $self->nodes ) {
        push @nodes, $node->findnodes($xpath);
    }
    return $self->new(
        nodes => [uniq(@nodes)],
    );
}

=head2 prev( [ $selector ] )

Get the immediately preceding sibling of each element in the set of matched
elements, optionally filtered by a selector.

=cut
sub prev {
    my ($self, $selector) = @_;

    my @nodes;
    foreach my $node ( $self->nodes ) {
        my $prev = $node;
        do {
            $prev = $prev->previousSibling;
        } while $prev and $prev->nodeType != XML_ELEMENT_NODE;
        push @nodes, $prev if $prev;
    }
    my $return = $self->new(
        nodes => [uniq(@nodes)],
    );
    return $return->filter($selector) if $selector;
    return $return;
}

=head2 next( [ $selector ] )

Get the immediately preceding sibling of each element in the set of matched
elements, optionally filtered by a selector.

=cut
sub next {
    my ($self, $selector) = @_;

    my @nodes;
    foreach my $node ( $self->nodes ) {
        my $next = $node;
        do {
            $next = $next->nextSibling;
        } while $next and $next->nodeType != XML_ELEMENT_NODE;
        push @nodes, $next if $next;
    }
    my $return = $self->new(
        nodes => [uniq(@nodes)],
    );
    return $return->filter($selector) if $selector;
    return $return;
}

=head2 filter( $selector )

Reduce the set of matched elements to those that match the selector

=cut

sub filter {
    my ($self, $selector) = @_;

    my $xpath = selector_to_xpath($selector, root => '..');

    my @nodes;

    foreach my $node ( $self->nodes ) {
        push @nodes, $node if grep { $node->isSameNode($_) } $node->findnodes($xpath);
    }

    return $self->new(
        nodes => [uniq(@nodes)],
    );
}

=head2 text_filter( $match )

Filter the current set of matched elements to those that contain the text
specified by $match. If you prefer, $match can also be a Regexp

=cut
sub text_filter {
    my ($self, $match) = @_;

    my $regexp = $match;
    $regexp = qr/\Q$regexp\E/ unless UNIVERSAL::isa($regexp, 'Regexp');

    my @nodes;
    foreach my $node ( $self->nodes ) {
        push @nodes, $node if $node->findvalue('.') =~ $match;
    }
    return $self->new(
        nodes => [uniq(@nodes)],
    );
}

=head2 parent()

Get the parent of each element in the current set of matched elements

=cut
sub parent {
    my ($self) = @_;

    my @nodes;
    foreach my $node ( $self->nodes ) {
        push @nodes, $node->parentNode if $node->parentNode;
    }
    return $self->new(
        nodes => [uniq(@nodes)],
    );
}

=head2 text()

Get the combined text contents of each element in the set of matched elements,
including their descendants.

=cut
sub text {
    my ($self) = @_;

    return join('', map { $_->findvalue('.') } shift->nodes);
}

=head2 text_array()

Return text for each element as a list

=cut
sub text_array {
    my ($self) = @_;

    return map { $_->findvalue('.') } shift->nodes;
}

=head2 html()

Return the HTML of the currently matched elements

=cut
sub html {
    my ($self) = @_;

    return join('', map { $_->toString } shift->nodes);
}

=head2 html_array()

Return the HTML each element as a list

=cut
sub html_array {
    my ($self) = @_;

    return map { $_->toString } shift->nodes;
}

=head2 remove()

Removes the matched nodes from the DOM tree returning them

=cut
sub remove {
    my ($self) = @_;

    foreach my $node ( $self->nodes ) {
        next unless $node->parentNode;
        $node->parentNode->removeChild($node);
    }

    return $self;
}

=head2 attr( $attribute )

Get the value of an attribute for the first element in the set of matched
elements.

=cut
sub attr {
    my ($self, $attr) = @_;

    my ($node) = $self->nodes;

    return unless $node;

    return $node->findvalue("./\@$attr");
}

=head2 each

Execute a sub for each matched node

=cut
sub each {
    my ($self, $sub) = @_;

    foreach my $node ( $self->nodes ) {
        local $_ = $self->new(nodes => [$node]);
        $sub->($_);
    }
}

=head2 map

Execute a sub for each matched node returning a list containing the result of
each sub

=cut
sub map {
    my ($self, $sub) = @_;

    my @results;

    foreach my $node ( $self->nodes ) {
        local $_ = $self->new(nodes => [$node]);
        push @results, $sub->($_);
    }

    return @results;
}

=head1 CLASS METHODS

=head2 uniq( @nodes )

Internal method for taking a list of L<XML::LibXML::Element>s and returning a
unique list

=cut

sub uniq {
    my (@nodes) = @_;
    my %seen;

    my @unique;

    foreach my $node ( @nodes ) {
        push @unique, $node unless $seen{$node->nodePath}++;
    }

    return @unique;
}

__PACKAGE__->meta->make_immutable;

1;
