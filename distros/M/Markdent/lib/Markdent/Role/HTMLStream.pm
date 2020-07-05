package Markdent::Role::HTMLStream;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.37';

use HTML::Entities qw( encode_entities );
use Markdent::CheckedOutput;
use Markdent::Types;
use Params::ValidationCompiler qw( validation_for );

use Moose::Role;

with 'Markdent::Role::EventsAsMethods';

requires qw( start_document end_document );

has _output => (
    is       => 'ro',
    isa      => t('OutputStream'),
    required => 1,
    init_arg => 'output',
);

has _encodable_entities => (
    is       => 'ro',
    isa      => t('Str'),
    default  => q{<>&"\x00-\x09\x11\x12\x14-\x1f},
    init_arg => 'encodable_entities',
);

override BUILDARGS => sub {
    my $self = shift;

    my $args = super();

    my $output = $args->{output};

    # This will blow up soon if there's no output.
    return $args unless $output;

    # If the user supplied a non IO::Handle object we won't wrap it.
    return $args if blessed $output && !$output->isa('IO::Handle');

    $args->{output} = Markdent::CheckedOutput->new($output);

    return $args;
};

{
    my $validator = validation_for(
        params => [
            level => { type => t('HeaderLevel') },
        ],
        named_to_list => 1,
    );

    sub start_header {
        my $self = shift;
        my ($level) = $validator->(@_);

        $self->_stream_start_tag( 'h' . $level );
    }
}

{
    my $validator = validation_for(
        params => [
            level => { type => t('HeaderLevel') },
        ],
        named_to_list => 1,
    );

    sub end_header {
        my $self = shift;
        my ($level) = $validator->(@_);

        $self->_stream_end_tag( 'h' . $level );
    }
}

sub start_blockquote {
    my $self = shift;

    $self->_stream_start_tag('blockquote');
}

sub end_blockquote {
    my $self = shift;

    $self->_stream_end_tag('blockquote');
}

sub start_unordered_list {
    my $self = shift;

    $self->_stream_start_tag('ul');
}

sub end_unordered_list {
    my $self = shift;

    $self->_stream_end_tag('ul');
}

sub start_ordered_list {
    my $self = shift;

    $self->_stream_start_tag('ol');
}

sub end_ordered_list {
    my $self = shift;

    $self->_stream_end_tag('ol');
}

sub start_list_item {
    my $self = shift;

    $self->_stream_start_tag('li');
}

sub end_list_item {
    my $self = shift;

    $self->_stream_end_tag('li');
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

        $self->_stream_start_tag('pre');

        my %class = $language ? ( class => 'language-' . $language ) : ();
        $self->_stream_start_tag( 'code', \%class );

        $self->_stream_text($code);

        $self->_stream_end_tag('code');
        $self->_stream_end_tag('pre');
    }
}

{
    my $validator = validation_for(
        params => [
            text => { type => t('Str') },
        ],
        named_to_list => 1,
    );

    sub preformatted {
        my $self = shift;
        my ($text) = $validator->(@_);

        $self->_stream_start_tag('pre');
        $self->_stream_start_tag('code');
        $self->_stream_text($text);
        $self->_stream_end_tag('code');
        $self->_stream_end_tag('pre');
    }
}

sub start_paragraph {
    my $self = shift;

    $self->_stream_start_tag('p');
}

sub end_paragraph {
    my $self = shift;

    $self->_stream_end_tag('p');
}

{
    my $validator = validation_for(
        params => [
            caption => {
                type     => t('Str'),
                optional => 1,
            },
        ],
        named_to_list => 1,
    );

    sub start_table {
        my $self = shift;
        my ($caption) = $validator->(@_);

        $self->_stream_start_tag('table');

        if ( defined $caption && length $caption ) {
            $self->_stream_start_tag('caption');
            $self->_stream_text($caption);
            $self->_stream_end_tag('caption');
        }
    }
}

sub end_table {
    my $self = shift;

    $self->_stream_end_tag('table');
}

sub start_table_header {
    my $self = shift;

    $self->_stream_start_tag('thead');
}

sub end_table_header {
    my $self = shift;

    $self->_stream_end_tag('thead');
}

sub start_table_body {
    my $self = shift;

    $self->_stream_start_tag('tbody');
}

sub end_table_body {
    my $self = shift;

    $self->_stream_end_tag('tbody');
}

sub start_table_row {
    my $self = shift;

    $self->_stream_start_tag('tr');
}

sub end_table_row {
    my $self = shift;

    $self->_stream_end_tag('tr');
}

{
    my $validator = validation_for(
        params => [
            alignment => {
                type     => t('TableCellAlignment'),
                optional => 1,
            },
            colspan        => { type => t('PositiveInt') },
            is_header_cell => { type => t('Bool') },
        ],
        named_to_list => 1,
    );

    sub start_table_cell {
        my $self = shift;
        my ( $alignment, $colspan, $is_header ) = $validator->(@_);

        my $tag = $is_header ? 'th' : 'td';

        my %attr;
        $attr{style} = "text-align: $alignment"
            if $alignment;

        $attr{colspan} = $colspan
            if $colspan != 1;

        $self->_stream_start_tag( $tag, \%attr );
    }
}

{
    my $validator = validation_for(
        params => [
            is_header_cell => { type => t('Bool') },
        ],
        named_to_list => 1,
    );

    sub end_table_cell {
        my $self = shift;
        my ($is_header) = $validator->(@_);

        $self->_stream_end_tag( $is_header ? 'th' : 'td' );
    }
}

sub start_emphasis {
    my $self = shift;

    $self->_stream_start_tag('em');
}

sub end_emphasis {
    my $self = shift;

    $self->_stream_end_tag('em');
}

sub start_strong {
    my $self = shift;

    $self->_stream_start_tag('strong');
}

sub end_strong {
    my $self = shift;

    $self->_stream_end_tag('strong');
}

sub start_code {
    my $self = shift;

    $self->_stream_start_tag('code');
}

sub end_code {
    my $self = shift;

    $self->_stream_end_tag('code');
}

{
    my $validator = validation_for(
        params => [
            uri => { type => t('Str') },
        ],
        named_to_list => 1,
    );

    sub auto_link {
        my $self = shift;
        my ($uri) = $validator->(@_);

        $self->_stream_start_tag( 'a', { href => $uri } );
        $self->_stream_text($uri);
        $self->_stream_end_tag('a');
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
            is_implicit_id => {
                type     => t('Bool'),
                optional => 1,
            },
        }
    );

    sub start_link {
        my $self = shift;
        my %p    = $validator->(@_);

        delete @p{ grep { !defined $p{$_} } keys %p };

        $self->_stream_start_tag(
            'a', {
                href => $p{uri},
                exists $p{title} ? ( title => $p{title} ) : (),
            },
        );
    }
}

sub end_link {
    my $self = shift;

    $self->_stream_end_tag('a');
}

sub line_break {
    my $self = shift;

    $self->_stream_start_tag('br');
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

        $self->_stream_text($text);
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

        $self->_stream_start_tag( $tag, $attributes );
    }
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

        $self->_stream_raw( '<!--' . $text . '-->' . "\n" );
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

        $self->_stream_raw( '<!--' . $text . '-->' );
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

        $self->_stream_start_tag( $tag, $attributes );
    }
}

{
    my $validator = validation_for(
        params => [
            tag => { type => t('Str') },
        ],
        named_to_list => 1,
    );

    sub end_html_tag {
        my $self = shift;
        my ($tag) = $validator->(@_);

        $self->_stream_end_tag($tag);
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

        $self->_stream_raw( '&' . $entity . ';' );
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

        $self->_output()->print($html);
    }
}

{
    my $validator = validation_for(
        params => {
            alt_text => { type => t('Str') },
            uri      => {
                type     => t('Str'),
                optional => 1,
            },
            title => {
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

        delete @p{ grep { !defined $p{$_} } keys %p };

        $self->_stream_start_tag(
            'img', {
                src => $p{uri},
                ( exists $p{alt_text} ? ( alt   => $p{alt_text} ) : () ),
                ( exists $p{title}    ? ( title => $p{title} )    : () ),
            },
        );
    }
}

sub horizontal_rule {
    my $self = shift;

    $self->_stream_start_tag('hr');
}

sub _stream_start_tag {
    my $self = shift;
    my $tag  = shift;
    my $attr = shift;

    $self->_output->print(
              '<'
            . $tag
            . (
            keys %{$attr}
            ? q{ } . $self->_attributes($attr)
            : q{}
            )
            . '>'
    );
}

sub _stream_end_tag {
    my $self = shift;
    my $tag  = shift;

    $self->_output->print( '</' . $tag . '>' );
}

sub _stream_text {
    my $self = shift;

    $self->_output->print(
        encode_entities(
            shift,
            $self->_encodable_entities,
        )
    );
}

sub _stream_raw {
    my $self = shift;

    $self->_output->print(shift);
}

sub _attributes {
    my $self = shift;
    my $attr = shift;

    return join q{ },
        map { $self->_attribute( $_, $attr->{$_} ) }
        sort { $a cmp $b } keys %{$attr};
}

sub _attribute {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

    return $key unless defined $value;

    return join '=', $key,
        q{"} . encode_entities(
        $value,
        $self->_encodable_entities,
        ) . q{"};
}

1;

# ABSTRACT: A role for handlers which generate HTML

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent::Role::HTMLStream - A role for handlers which generate HTML

=head1 VERSION

version 0.37

=head1 DESCRIPTION

This role implements most of the code needed for event receivers which
generate a stream of HTML output based on those events.

=head1 REQUIRED METHODS

This role requires that consuming classes implement two methods, C<<
$handler->start_document() >> and C<< $handler->end_document() >>.

=head1 ROLES

This role does the L<Markdent::Role::EventsAsMethods> and
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
