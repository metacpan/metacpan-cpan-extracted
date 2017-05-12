package HTML::TreeBuilder::LibXML;
use strict;
use warnings;
our $VERSION = '0.26';
use Carp ();
use base 'HTML::TreeBuilder::LibXML::Node';
use XML::LibXML;
use 5.008001;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub new_from_content {
    my $class = shift;
    my $self  = $class->new;
    for my $content (@_) {
        $self->parse($content);
    }
    $self->eof;

    return $self;
}

sub new_from_file {
    my $class = shift;
    my $self  = $class->new;
    $self->parse_file(@_);
    return $self;
}

my $PARSER;
sub _parser {
    unless ($PARSER) {
        $PARSER = XML::LibXML->new();
        $PARSER->recover(1);
        $PARSER->recover_silently(1);
        $PARSER->keep_blanks(0);
        $PARSER->expand_entities(1);
        $PARSER->no_network(1);
    }
    $PARSER;
}

sub parse {
    my ($self, $html) = @_;
    $self->{_content} .= $html;
}

sub parse_content {
    my $self = shift;
    $self->parse($_[0]);
    $self->eof;
}

sub parse_file {
    my $self = shift;
    open (my $fh, '<', $_[0]) or die "Can't open $_[0]: $!\n";
    my $content = do { local $/;  <$fh> };
    $self->parse_content($content);
}

sub eof {
    my ($self, ) = @_;
    $self->{_content} = ' ' if defined $self->{_content} && $self->{_content} eq ''; # HACK
    $self->{_implicit_html} = 1 unless $self->{_content} =~ /<html/i; # TODO find a better way to know that implicit <html> was inserted
    $self->{_implicit_doctype} = 1 unless $self->{_content} =~ /<!DOCTYPE/i;
    my $doc = $self->_parser->parse_html_string($self->{_content});
    $self->{node} = $self->_documentElement($doc);
}

sub _documentElement {
    my($self, $doc) = @_;
    return $doc->documentElement || do {
        my $elem = $doc->createElement("html");
        $elem->appendChild($doc->createElement("body"));
        $elem;
    };
}

sub elementify {
    bless shift, 'HTML::TreeBuilder::LibXML::Node';
}

sub guts {
    my ($self, $destructive) = @_;

    my @out = $self->{_implicit_html} ? map { $_->nonBlankChildNodes } $self->{node}->findnodes('/html/head | /html/body')
                                      : $self->{node};

    if ($destructive && @out > 0) {
        my $doc = XML::LibXML->createDocument;
        if (!$self->{_implicit_doctype} && (my $dtd = $out[0]->ownerDocument->internalSubset)) {
            $doc->createInternalSubset( $dtd->getName, $dtd->publicId, $dtd->systemId );
        }
        $doc->setDocumentElement($out[0]); # 1st child
        $out[0]->addSibling($_) foreach @out[1..$#out];
    }
        
    return map { HTML::TreeBuilder::LibXML::Node->new($_) } @out if wantarray;    # one simple normal case.
    return unless @out;
    
    my $doc = XML::LibXML->createDocument;
    if (!$self->{_implicit_doctype} && (my $dtd = $out[0]->ownerDocument->internalSubset)) {
        $doc->createInternalSubset( $dtd->getName, $dtd->publicId, $dtd->systemId );
    }

    if (@out == 1) {
        $doc->adoptNode($out[0]);
        $doc->setDocumentElement($out[0]);        
        return HTML::TreeBuilder::LibXML::Node->new($out[0]);    
    }    
    
    my $div = $doc->createElement('div'); # TODO put the _implicit flag somewhere, to be compatible with HTML::TreeBuilders
    $doc->setDocumentElement($div);    
    $div->appendChild($_) for @out;
    
    return HTML::TreeBuilder::LibXML::Node->new($div);    
}

sub disembowel {
    my ($self) = @_;
    $self->guts(1);
}

sub replace_original {
    require HTML::TreeBuilder::XPath;

    my $orig = HTML::TreeBuilder::XPath->can('new');

    no warnings 'redefine';
    *HTML::TreeBuilder::XPath::new = sub {
        HTML::TreeBuilder::LibXML->new();
    };

    if (defined wantarray) {
        return HTML::TreeBuilder::LibXML::Destructor->new(
            sub { *HTML::TreeBuilder::XPath::new = $orig } );
    }
    return;
}

# The HTML::TreeBuilder has this method and it is needed to us for web-scraper module
sub store_comments { }
sub ignore_unknown { }

package # hide from cpan
    HTML::TreeBuilder::LibXML::Destructor;

sub new {
    my ( $class, $callback ) = @_;
    bless { cb => $callback }, $class;
}

sub DESTROY {
    my $self = shift;
    $self->{cb}->();
}

1;
__END__

=encoding utf-8

=head1 NAME

HTML::TreeBuilder::LibXML - HTML::TreeBuilder and XPath compatible interface with libxml

=head1 SYNOPSIS

    use HTML::TreeBuilder::LibXML;

    my $tree = HTML::TreeBuilder::LibXML->new;
    $tree->parse($html);
    $tree->eof;

    # $tree and $node compatible to HTML::Element
    my @nodes = $tree->findvalue($xpath);
    for my $node (@nodes) {
        print $node->tag;
        my %attr = $node->all_external_attr;
    }

    HTML::TreeBuilder::LibXML->replace_original(); # replace HTML::TreeBuilder::XPath->new

=head1 DESCRIPTION

HTML::TreeBuilder::XPath is libxml based compatible interface to
HTML::TreeBuilder, which could be slow for a large document.

HTML::TreeBuilder::LibXML is drop-in-replacement for HTML::TreeBuilder::XPath.

This module doesn't implement all of HTML::TreeBuilder and
HTML::Element APIs, but enough methods are defined so modules like
Web::Scraper work.

=head1 BENCHMARK

This is a benchmark result by tools/benchmark.pl

        Web::Scraper: 0.26
        HTML::TreeBuilder::XPath: 0.09
        HTML::TreeBuilder::LibXML: 0.01_01

                     Rate  no_libxml use_libxml
        no_libxml  5.45/s         --       -94%
        use_libxml 94.3/s      1632%         --

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

Tatsuhiko Miyagawa E<lt>miyagawa@cpan.orgE<gt>

Masahiro Chiba

=head1 THANKS TO

woremacx++
http://d.hatena.ne.jp/woremacx/20080202/1201927162

id:dailyflower

=head1 SEE ALSO

L<HTML::TreeBuilder>, L<HTML::TreeBuilder::XPath>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
