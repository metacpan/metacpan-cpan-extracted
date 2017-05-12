package HTML::StripScripts::LibXML;
use strict;

use vars qw($VERSION);
$VERSION = '0.12';

=head1 NAME

HTML::StripScripts::LibXML - XSS filter -  outputs a LibXML Document or DocumentFragment

=head1 SYNOPSIS

  use HTML::StripScripts::LibXML();

  my $hss = HTML::StripScripts::LibXML->new(

       {
           Context => 'Document',       ## HTML::StripScripts configuration
           Rules   => { ... },
       },

       strict_comment => 1,             ## HTML::Parser options
       strict_names   => 1,

  );

  $hss->parse_file("foo.html");
  $xml_doc = $hss->filtered_document;

  OR

  $xml_doc = $hss->filter_html($html);

=head1 DESCRIPTION

This class provides an easy interface to C<HTML::StripScripts>, using
C<HTML::Parser> to parse the HTML, and returns an XML::LibXML::Document
or XML::LibXML::DocumentFragment.

See L<HTML::Parser> for details of how to customise how the raw HTML is parsed
into tags, and L<HTML::StripScripts> for details of how to customise the way
those tags are filtered. This module is a subclass of
L<HTML::StripScripts::Parser>.

=cut

=head1 DIFFERENCES FROM HTML::StripScripts

=over

=item CONTEXT

HTML::StripScripts::LibXML still allows you to specify the C<Context> of the
HTML (Document, Flow, Inline, NoTags). If C<Context> is C<Document>, then it
returns an C<XML::LibXML::Document> object, otherwise it returns an
C<XML::LibXML::DocumentFragment> object.

=item TAG CALLBACKS

HTML::StripScripts allows you to use tag callbacks, for instance:

   $hss = HTML::StripScripts->new({
       Rules => { a => \&a_callback }
   });

   sub a_callback {
        my ($filter,$element)  = @_;
        # where $element = {
        #          tag      => 'a',
        #          attr     => { href => '/index.html' },
        #          content  => 'Go to <b>Home</b> page',
        #       }
        return 1;
    }

HTML::StripScripts::LibXML still gives you tag callbacks,  but they look like
this:

   sub a_callback {
        my ($filter,$element)  = @_;
        # where $element = {
        #          tag      => 'a',
        #          attr     => { href => '/index.html' },
        #          children => [
        #                        XML::LibXML::Text -->    'Go to ',
        #                        XML::LibXML::Element --> 'b'
        #                           with child Text -->   'Home',
        #                        XML::LibXML::Text -->    ' page',
        #                      ],
        #       }
        return 1;
    }

=item SUBCLASSING

The subs C<output>, C<output_start> and C<output_end> are not called.  Instead,
this module uses C<output_stack_entry> which handles the tag callback, (and
depending on the result of the tag callback) creates an element and adds
its child nodes. Then it adds the element to the list of children for the
parent tag.

=back

=head1 CONSTRUCTORS

=over

=item new ( {CONFIG}, [PARSER_OPTIONS]  )

Creates a new C<HTML::StripScripts::LibXML> object.

See L<HTML::StripScripts::Parser> for details.

=back

=cut

use base 'HTML::StripScripts::Parser';
use XML::LibXML();
use HTML::Entities();

#===================================
sub output_start_document {
#===================================
    my ($self) = @_;
    $self->{_hsxXML} = XML::LibXML::Document->new();
    return;
}

#===================================
sub output_end_document {
#===================================
    my ($self)   = @_;
    my $top      = $self->{_hssStack}[0];
    my $document = delete $self->{_hsxXML};

    if ( $top->{CTX} ne 'Document' ) {
        $document = $document->createDocumentFragment();
    }

    foreach my $child ( @{ $top->{CHILDREN} } ) {
        $document->addChild($child);
    }
    $top->{CONTENT} = $document;
    return;
}

#===================================
sub output_start { }
*output_end         = \&output_start;
*output_declaration = \&output_start;
*output_process     = \&output_start;
*output             = \&output_start;
#===================================

#===================================
sub output_text {
#===================================
    my ( $self, $text ) = @_;
    HTML::Entities::decode_entities( $text);
    utf8::upgrade($text);
    push @{ $self->{_hssStack}[0]{CHILDREN} },
        $self->{_hsxXML}->createTextNode($text);
    return;
}

#===================================
sub output_comment {
#===================================
    my ( $self, $comment ) = @_;
    $comment =~ s/^\s*<!--//g;
    $comment =~ s/-->\s*$//g;
    push @{ $self->{_hssStack}[0]{CHILDREN} },
        $self->{_hsxXML}->createComment($comment);
    return;
}

#===================================
sub output_stack_entry {
#===================================
    my ( $self, $tag ) = @_;

    my %entry;
    $tag->{CHILDREN} ||= [];
    @entry{qw(tag attr children)} = @{$tag}{qw(NAME ATTR CHILDREN)};

    if ( my $tag_callback = $tag->{CALLBACK} ) {
        $tag_callback->( $self, \%entry )
            or return;
    }

    if ( my $tagname = $entry{tag} ) {
        my $element = $self->{_hsxXML}->createElement($tagname);
        my $attrs   = $entry{attr};
        foreach my $name ( sort keys %$attrs ) {
            $element->setAttribute( $name => $attrs->{$name} );
        }
        unless ( $tag->{CTX} eq 'EMPTY' ) {
            foreach my $children ( @{ $entry{children} } ) {
                $element->addChild($children);
            }
        }
        push @{ $self->{_hssStack}[0]{CHILDREN} }, $element;
    }
    else {
        push @{ $self->{_hssStack}[0]{CHILDREN} }, @{ $entry{children} };
    }
    $tag->{CHILDREN} = [];
}

=head1 BUGS AND LIMITATIONS

=over

=item API - BETA

This is the first draft of this module, and currently there are no configuration
options for the XML. I would welcome feedback from XML users as to how I could
improve the interface.

For this reason, the API may change.

=item REPORTING BUGS

Please report any bugs or feature requests to
bug-html-stripscripts-libxml@rt.cpan.org, or through the web interface at
L<http://rt.cpan.org>.

=back

=head1 SEE ALSO

L<HTML::Parser>, L<HTML::StripScripts::Parser>,
L<HTML::StripScripts::Regex>

=head1 AUTHOR

Clinton Gormley E<lt>clint@traveljury.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 Clinton Gormley.  All Rights Reserved.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

