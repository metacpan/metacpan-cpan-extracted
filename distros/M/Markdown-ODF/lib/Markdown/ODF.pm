package Markdown::ODF;

use strict;
use warnings;
use utf8;

use Carp qw/confess/;
use Moo;
use Markdown::Parser;
use Markdown::Parser::Document;
use ODF::lpOD;

our $VERSION = '0.01';

{
    # Silence warnings from ODF package
    package ODF::lpOD::Element;
    sub DESTROY {}
}

=head1 NAME

Markdown::ODF - Create ODF documents from Markdown

=head1 SYNOPSIS

  use Markdown::ODF;

  my $convert = Markdown::ODF->new;

  # Optionally use PDF document directly
  my $odf  = $convert->odf;
  my $meta = $odf->meta;
  $meta->set_title("Title for converted document");

  # Optionally set default paragraph style for document
  my $default = odf_create_style(
    'paragraph',
    area     => 'text',
    language => 'en',
    country  => 'GB',
    size     => '11pt',
    font     => 'Arial',
  );
  $odf->insert_style($default, default => TRUE);

  # Add content
  $convert->add_markdown("My markdown with some **bold text**");

=head1 DESCRIPTION

This module converts Markdown to ODF text documents. The ODF document is
accessed using the L</"odf"> method which returns a L<ODF::lpOD> object
allowing further manipulation of the document.

=head1 METHODS

=cut

=head2 odf

Returns the L<ODF::lpOD> object used for the ODF document.

=cut

has odf => (
    is => 'lazy',
);

sub _build_odf
{   my $self = shift;

    my $odf = odf_new_document('text');
    my $meta = $odf->meta;

    $meta->set_title("New Title");
    $meta->set_modification_date;
    $meta->set_creator('Andy');

    $odf->insert_style(
        odf_create_style('text', name => "bold", weight => 'bold')
    );
    $odf->insert_style(
        odf_create_style('text', name => "italic", style => 'italic')
    );

    $odf->insert_style(
        odf_create_style(
            'paragraph',
            name            => 'Activ Paragraph',
            parent          => 'Standard',
            'margin bottom' => '0.5cm',
        )
    );
    $odf->insert_style(
        odf_create_style(
            'paragraph',
            name            => 'Activ Paragraph List',
            parent          => 'Standard',
            'margin bottom' => '0.5cm',
            'style:contextual-spacing' => "true", # Only spacing after list, not between items
        )
    );

    my $ls = odf_create_style('list', name => "ordered");
    $ls->set_level_style(
        1,
        type    => 'number',
        format  => '1',
        suffix  => '. '
    );
    $odf->insert_style($ls);

    $ls = odf_create_style('list', name => "unordered");
    my $c = '•';
    utf8::encode($c);
    $ls->set_level_style(
         1, type => 'bullet', character => $c
    );
    $odf->insert_style($ls);

    $odf;
}

=head2 add_markdown($markdown)

Add markdown content as a paragraph to the current ODF page.

=cut

sub add_markdown
{   my ($self, $md) = @_;
    my $parser = Markdown::Parser->new;
    my $doc = $parser->parse($md);
    $self->_print($doc);
}

has _stack => (
    is      => 'ro',
    default => sub { [] },
);

has _all_text => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { [] },
    clearer => 1,
);

=head2 current_element

Returns the most recent L<ODF::lpOD::Element> that has been written to the document.

=cut

has current_element => (
    is => 'rwp',
);

sub _para
{   my ($self, %options) = @_;
    my @s; my $pos = 0;
    my $text = '';
    my $to_add;
    my $list = $options{list};
    my $header = $options{header};
    foreach my $item (@{$self->_all_text})
    {
        $text .= $item->{text};
        push @s, {
            offset => $pos,
            length => length $item->{text},
            style  => $item->{styles},
            link => $item->{link},
        };
        $pos += length $item->{text};
    }
    return if $text =~ /^\s*$/; # Do not print empty paragraphs
    utf8::encode($text);
    my $e;
    if ($header)
    {
        $header->set_text($text);
        $e = $header;
    }
    else {
        $e = odf_paragraph->create(
            text    => $text,
            style   => $list ? "Activ Paragraph List" : "Activ Paragraph",
        );
    }
    foreach my $s (@s)
    {
        foreach my $ss (@{$s->{style}})
        {
            if ($ss eq 'bold')
            {
                $e->set_span(
                    offset => $s->{offset},
                    length => $s->{length},
                    style  => 'bold',
                );
            }
            elsif ($ss eq 'emphasis')
            {
                $e->set_span(
                    offset => $s->{offset},
                    length => $s->{length},
                    style  => 'italic',
                );
            }
            elsif ($ss eq 'list')
            {
            }
            elsif ($ss eq 'listnum')
            {
            }
            elsif ($ss eq 'link')
            {
                $e->set_hyperlink(
                    offset => $s->{offset},
                    length => $s->{length},
                    url => $s->{link},
                );
            }
            elsif ($ss eq 'listitem')
            {
                my $item = $list->add_item;
                $item->append_element($e);
                $to_add = $list;
                return;
            }
            else {
                confess "Unknown style: $ss";
            }
        }
    }
    $to_add ||= $e;
    $self->append_element($to_add);
}

=head2 append_element($element)

Add a ODF::lpOD::Element to the current document and update L</"current_element()">.

=cut

sub append_element
{   my ($self, $element) = @_;
    $self->current_element ? $self->current_element->insert_element($element, position => NEXT_SIBLING) : $self->odf->body->insert_element($element);
    $self->_set_current_element($element);
    $self;
}

sub _print
{   my ($self, $item, %options) = @_;

    if (!$item->isa('Markdown::Parser::Text'))
    {
        my $ref = ref $item;
        $ref =~ s/^Markdown::Parser:://;
        my $has_style; my $list = $options{list};
        my $header = $options{header}; my $link;
        if ($ref eq 'List')
        {
            $list = odf_list->create(style => $item->order ? 'ordered' : 'unordered');
            $self->append_element($list);
        }
        elsif ($ref eq 'Header')
        {
            $header = odf_heading->create(
                level   => $item->level,
                style   => "Heading_20_".$item->level,
            );
        }
        elsif ($ref =~ /^(Emphasis|Bold|List|ListItem|Link)$/)
        {
            push @{$self->_stack}, lc $ref;
            $has_style = 1;
            $link = $item->url if $ref eq 'Link';
        }
        $item->children->for(sub{
            my ($i, $item2) = @_;
            $self->_print($item2, list => $list, header => $header, last => $i == $item->children->size && ($ref eq 'Paragraph' || $ref eq 'Header' || $ref eq 'ListItem'), link => $link);
            return 1;
        });
        pop @{$self->_stack} if $has_style;
    }
    else {
        my $text = $item->text or return;

        $text =~ s/\s+$// if $options{list} && $options{last};
        if ($text !~ /^\s+$/)
        {
            push @{$self->_all_text}, {
                text => $text,
                styles => [@{$self->_stack}],
                link => $options{link},
            };
        }
        if ($text =~ s/\n$// || $options{last})
        {
            # Print para
            $self->_para(%options);
            $self->_clear_all_text;
        }
    }

}

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2022 Amtivo Group

This program is free software, licensed under the MIT licence.

=cut

1;
