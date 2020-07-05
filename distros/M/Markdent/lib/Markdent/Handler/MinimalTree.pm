package Markdent::Handler::MinimalTree;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.37';

use Markdent::Types;
use Params::ValidationCompiler qw( validation_for );
use Specio::Declare;
use Tree::Simple;

use Moose;
use MooseX::SemiAffordanceAccessor;

with 'Markdent::Role::EventsAsMethods';

my $tree_simple_type = object_isa_type('Tree::Simple');
has tree => (
    is      => 'ro',
    isa     => $tree_simple_type,
    default => sub {
        Tree::Simple->new( { type => 'document' }, Tree::Simple->ROOT() );
    },
    init_arg => undef,
);

has _current_node => (
    is       => 'rw',
    isa      => t( 'Maybe', of => $tree_simple_type ),
    init_arg => undef,
);

sub start_document {
    my $self = shift;

    $self->_set_current_node( $self->tree() );
}

sub end_document {
    my $self = shift;

    $self->_set_current_node(undef);
}

{
    my $validator = validation_for(
        params        => [ level => { type => t('HeaderLevel') } ],
        named_to_list => 1,
    );

    sub start_header {
        my $self = shift;
        my ($level) = $validator->(@_);

        my $header
            = Tree::Simple->new( { type => 'header', level => $level } );
        $self->_current_node()->addChild($header);

        $self->_set_current_node($header);
    }
}

sub end_header {
    my $self = shift;

    $self->_set_current_up_one_level();
}

sub start_blockquote {
    my $self = shift;

    my $bq = Tree::Simple->new( { type => 'blockquote' } );
    $self->_current_node()->addChild($bq);

    $self->_set_current_node($bq);
}

sub end_blockquote {
    my $self = shift;

    $self->_set_current_up_one_level();
}

sub start_unordered_list {
    my $self = shift;

    my $bq = Tree::Simple->new( { type => 'unordered_list' } );
    $self->_current_node()->addChild($bq);

    $self->_set_current_node($bq);
}

sub end_unordered_list {
    my $self = shift;

    $self->_set_current_up_one_level();
}

sub start_ordered_list {
    my $self = shift;

    my $bq = Tree::Simple->new( { type => 'ordered_list' } );
    $self->_current_node()->addChild($bq);

    $self->_set_current_node($bq);
}

sub end_ordered_list {
    my $self = shift;

    $self->_set_current_up_one_level();
}

{
    my $validator = validation_for(
        params        => [ bullet => { type => t('Str') } ],
        named_to_list => 1,
    );

    sub start_list_item {
        my $self = shift;
        my ($bullet) = $validator->(@_);

        my $list_item
            = Tree::Simple->new( { type => 'list_item', bullet => $bullet } );
        $self->_current_node()->addChild($list_item);

        $self->_set_current_node($list_item);
    }
}

sub end_list_item {
    my $self = shift;

    $self->_set_current_up_one_level();
}

{
    my $validator = validation_for(
        params        => [ text => { type => t('Str') } ],
        named_to_list => 1,
    );

    sub preformatted {
        my $self = shift;
        my ($text) = $validator->(@_);

        my $pre_node
            = Tree::Simple->new( { type => 'preformatted', text => $text } );
        $self->_current_node()->addChild($pre_node);
    }
}

{
    my $validator = validation_for(
        params => [
            code     => { type => t('Str') },
            language => {
                type     => t('Str'),
                optional => 1,
            },
        ],
        named_to_list => 1,
    );

    sub code_block {
        my $self = shift;
        my ( $code, $language ) = $validator->(@_);

        my $code_block_node = Tree::Simple->new(
            {
                type     => 'code_block',
                code     => $code,
                language => $language,
            }
        );

        $self->_current_node()->addChild($code_block_node);
    }
}

sub start_paragraph {
    my $self = shift;

    my $para = Tree::Simple->new( { type => 'paragraph' } );
    $self->_current_node()->addChild($para);

    $self->_set_current_node($para);
}

sub end_paragraph {
    my $self = shift;

    $self->_set_current_up_one_level();
}

{
    my $validator = validation_for(
        params => {
            caption => {
                type     => t('Str'),
                optional => 1,
            },
        },
    );

    sub start_table {
        my $self = shift;
        my %p    = $validator->(@_);

        my $para = Tree::Simple->new( { type => 'table', %p } );
        $self->_current_node()->addChild($para);

        $self->_set_current_node($para);
    }
}

sub end_table {
    my $self = shift;

    $self->_set_current_up_one_level();
}

sub start_table_header {
    my $self = shift;

    my $para = Tree::Simple->new( { type => 'table_header' } );
    $self->_current_node()->addChild($para);

    $self->_set_current_node($para);
}

sub end_table_header {
    my $self = shift;

    $self->_set_current_up_one_level();
}

sub start_table_body {
    my $self = shift;

    my $para = Tree::Simple->new( { type => 'table_body' } );
    $self->_current_node()->addChild($para);

    $self->_set_current_node($para);
}

sub end_table_body {
    my $self = shift;

    $self->_set_current_up_one_level();
}

sub start_table_row {
    my $self = shift;

    my $para = Tree::Simple->new( { type => 'table_row' } );
    $self->_current_node()->addChild($para);

    $self->_set_current_node($para);
}

sub end_table_row {
    my $self = shift;

    $self->_set_current_up_one_level();
}

{
    my $validator = validation_for(
        params => {
            alignment => {
                type     => t('TableCellAlignment'),
                optional => 1,
            },
            colspan        => { type => t('PositiveInt') },
            is_header_cell => { type => t('Bool') },
        },
    );

    sub start_table_cell {
        my $self = shift;
        my %p    = $validator->(@_);

        my $para = Tree::Simple->new( { type => 'table_cell', %p } );
        $self->_current_node()->addChild($para);

        $self->_set_current_node($para);
    }
}

sub end_table_cell {
    my $self = shift;

    $self->_set_current_up_one_level();
}

sub start_emphasis {
    my $self = shift;

    $self->_start_markup_node('emphasis');
}

sub end_emphasis {
    my $self = shift;

    $self->_set_current_up_one_level();
}

sub start_strong {
    my $self = shift;

    $self->_start_markup_node('strong');
}

sub end_strong {
    my $self = shift;

    $self->_set_current_up_one_level();
}

sub start_code {
    my $self = shift;

    $self->_start_markup_node('code');
}

sub end_code {
    my $self = shift;

    $self->_set_current_up_one_level();
}

{
    my $validator = validation_for(
        params => {
            uri => {
                type     => t('Str'),
                optional => 1,
            },
        },
    );

    sub auto_link {
        my $self = shift;
        my %p    = $validator->(@_);

        my $link_node = Tree::Simple->new( { type => 'auto_link', %p } );
        $self->_current_node()->addChild($link_node);
    }
}

{
    my $validator = validation_for(
        params => {
            uri   => { type => t('Str') },
            title => {
                type     => t('Str'),
                optional => 1,
            },
            id => {
                type     => t('Str'),
                optional => 1,
            },
            is_implicit_id => { type => t('Bool') },
        },
    );

    sub start_link {
        my $self = shift;
        my %p    = $validator->(@_);

        delete @p{ grep { !defined $p{$_} } keys %p };

        $self->_start_markup_node( 'link', %p );
    }
}

sub end_link {
    my $self = shift;

    $self->_set_current_up_one_level();
}

sub line_break {
    my $self = shift;

    my $break_node = Tree::Simple->new( { type => 'line_break' } );

    $self->_current_node()->addChild($break_node);
}

{
    my $validator = validation_for(
        params => [
            text => { type => t('Str') },
        ],
        named_to_list => 1,
    );

    sub text {
        my $self = shift;
        my ($text) = $validator->(@_);

        my $text_node
            = Tree::Simple->new( { type => 'text', text => $text } );
        $self->_current_node()->addChild($text_node);
    }
}

{
    my $validator = validation_for(
        params => [
            tag        => { type => t('Str') },
            attributes => { type => t('HashRef') },
        ],
        named_to_list => 1,
    );

    sub start_html_tag {
        my $self = shift;
        my ( $tag, $attributes ) = $validator->(@_);

        my $tag_node = Tree::Simple->new(
            {
                type       => 'start_html_tag',
                tag        => $tag,
                attributes => $attributes,
            }
        );

        $self->_current_node()->addChild($tag_node);

        $self->_set_current_node($tag_node);
    }
}

sub end_html_tag {
    my $self = shift;

    $self->_set_current_up_one_level();
}

{
    my $validator = validation_for(
        params => [
            text => { type => t('Str') },
        ],
        named_to_list => 1,
    );

    sub html_comment_block {
        my $self = shift;
        my ($text) = $validator->(@_);

        my $html_node = Tree::Simple->new(
            { type => 'html_comment_block', text => $text } );
        $self->_current_node()->addChild($html_node);
    }
}

{
    my $validator = validation_for(
        params => [
            text => { type => t('Str') },
        ],
        named_to_list => 1,
    );

    sub html_comment {
        my $self = shift;
        my ($text) = $validator->(@_);

        my $html_node
            = Tree::Simple->new( { type => 'html_comment', text => $text } );
        $self->_current_node()->addChild($html_node);
    }
}

{
    my $validator = validation_for(
        params => [
            tag        => { type => t('Str') },
            attributes => { type => t('HashRef') },
        ],
        named_to_list => 1,
    );

    sub html_tag {
        my $self = shift;
        my ( $tag, $attributes ) = $validator->(@_);

        my $tag_node = Tree::Simple->new(
            {
                type       => 'html_tag',
                tag        => $tag,
                attributes => $attributes,
            }
        );

        $self->_current_node()->addChild($tag_node);
    }
}

{
    my $validator = validation_for(
        params => [
            entity => { type => t('Str') },
        ],
        named_to_list => 1,
    );

    sub html_entity {
        my $self = shift;
        my ($entity) = $validator->(@_);

        my $html_node
            = Tree::Simple->new(
            { type => 'html_entity', entity => $entity } );
        $self->_current_node()->addChild($html_node);
    }
}

{
    my $validator = validation_for(
        params => [
            html => { type => t('Str') },
        ],
        named_to_list => 1,
    );

    sub html_block {
        my $self = shift;
        my ($html) = $validator->(@_);

        my $html_node
            = Tree::Simple->new( { type => 'html_block', html => $html } );
        $self->_current_node()->addChild($html_node);
    }
}

{
    my $validator = validation_for(
        params => {
            alt_text => { type => t('Str') },
            uri      => { type => t('Str') },
            title    => {
                type     => t('Str'),
                optional => 1,
            },
            id => {
                type     => t('Str'),
                optional => 1,
            },
            is_implicit_id => {
                type     => t('Bool'),
                optional => 1,
            },
        },
    );

    sub image {
        my $self = shift;
        my %p    = $validator->(@_);

        my $image_node = Tree::Simple->new( { type => 'image', %p } );
        $self->_current_node()->addChild($image_node);
    }
}

sub horizontal_rule {
    my $self = shift;

    my $hr_node = Tree::Simple->new( { type => 'horizontal_rule' } );
    $self->_current_node()->addChild($hr_node);
}

sub _start_markup_node {
    my $self = shift;
    my $type = shift;

    my $markup = Tree::Simple->new( { type => $type, @_ } );
    $self->_current_node()->addChild($markup);

    $self->_set_current_node($markup);
}

sub _set_current_up_one_level {
    my $self = shift;

    $self->_set_current_node( $self->_current_node()->getParent() );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A Markdent handler which builds a tree

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent::Handler::MinimalTree - A Markdent handler which builds a tree

=head1 VERSION

version 0.37

=head1 DESCRIPTION

This class implements an event receiver which in turn builds a tree using
L<Tree::Simple>.

It is primarily intended for use in testing.

=head1 METHODS

This class provides the following methods:

=head2 Markdent::Handler::MinimalTree->new(...)

This method creates a new handler.

=head2 $mhmt->tree()

Returns the root tree for the document.

=head1 ROLES

This class does the L<Markdent::Role::EventsAsMethods> and
L<Markdent::Role::Handler> roles.

=head1 BUGS

See L<Markdent> for bug reporting details.

Bugs may be submitted at L<https://github.com/houseabsolute/Markdent/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Markdent can be found at L<https://github.com/houseabsolute/Markdent>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
