package Markdent::Role::HTMLStream;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.26';

use HTML::Entities qw( encode_entities );
use Markdent::CheckedOutput;
use Markdent::Types qw(
    HeaderLevel Str Bool HashRef
    TableCellAlignment PosInt
    OutputStream
);
use MooseX::Params::Validate qw( validated_list validated_hash );

use Moose::Role;

with 'Markdent::Role::EventsAsMethods';

requires qw( start_document end_document );

has _output => (
    is       => 'ro',
    isa      => OutputStream,
    required => 1,
    init_arg => 'output',
);

has _encodable_entities => (
    is       => 'ro',
    isa      => Str,
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

sub start_header {
    my $self = shift;
    my ($level) = validated_list(
        \@_,
        level => { isa => HeaderLevel },
    );

    $self->_stream_start_tag( 'h' . $level );
}

sub end_header {
    my $self = shift;
    my ($level) = validated_list(
        \@_,
        level => { isa => HeaderLevel },
    );

    $self->_stream_end_tag( 'h' . $level );
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

sub code_block {
    my $self = shift;
    my ( $code, $language ) = validated_list(
        \@_,
        code     => { isa => Str },
        language => { isa => Str, optional => 1 },
    );

    $self->_stream_start_tag('pre');

    my %class = $language ? ( class => 'language-' . $language ) : ();
    $self->_stream_start_tag( 'code', \%class );

    $self->_stream_text($code);

    $self->_stream_end_tag('code');
    $self->_stream_end_tag('pre');
}

sub preformatted {
    my $self = shift;
    my ($text) = validated_list( \@_, text => { isa => Str }, );

    $self->_stream_start_tag('pre');
    $self->_stream_start_tag('code');
    $self->_stream_text($text);
    $self->_stream_end_tag('code');
    $self->_stream_end_tag('pre');
}

sub start_paragraph {
    my $self = shift;

    $self->_stream_start_tag('p');
}

sub end_paragraph {
    my $self = shift;

    $self->_stream_end_tag('p');
}

sub start_table {
    my $self = shift;
    my ($caption) = validated_list(
        \@_,
        caption => { isa => Str, optional => 1 },
    );

    $self->_stream_start_tag('table');

    if ( defined $caption && length $caption ) {
        $self->_stream_start_tag('caption');
        $self->_stream_text($caption);
        $self->_stream_end_tag('caption');
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

sub start_table_cell {
    my $self = shift;
    my ( $alignment, $colspan, $is_header ) = validated_list(
        \@_,
        alignment      => { isa => TableCellAlignment, optional => 1 },
        colspan        => { isa => PosInt },
        is_header_cell => { isa => Bool },
    );

    my $tag = $is_header ? 'th' : 'td';

    my %attr;
    $attr{style} = "text-align: $alignment"
        if $alignment;

    $attr{colspan} = $colspan
        if $colspan != 1;

    $self->_stream_start_tag( $tag, \%attr );
}

sub end_table_cell {
    my $self = shift;
    my ($is_header) = validated_list(
        \@_,
        is_header_cell => { isa => Bool },
    );

    $self->_stream_end_tag( $is_header ? 'th' : 'td' );
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

sub auto_link {
    my $self = shift;
    my ($uri) = validated_list(
        \@_,
        uri => { isa => Str, optional => 1 },
    );

    $self->_stream_start_tag( 'a', { href => $uri } );
    $self->_stream_text($uri);
    $self->_stream_end_tag('a');
}

sub start_link {
    my $self = shift;
    my %p    = validated_hash(
        \@_,
        uri            => { isa => Str },
        title          => { isa => Str, optional => 1 },
        id             => { isa => Str, optional => 1 },
        is_implicit_id => { isa => Bool, optional => 1 },
    );

    delete @p{ grep { !defined $p{$_} } keys %p };

    $self->_stream_start_tag(
        'a', {
            href => $p{uri},
            exists $p{title} ? ( title => $p{title} ) : (),
        },
    );
}

sub end_link {
    my $self = shift;

    $self->_stream_end_tag('a');
}

sub line_break {
    my $self = shift;

    $self->_stream_start_tag('br');
}

sub text {
    my $self = shift;
    my ($text) = validated_list( \@_, text => { isa => Str }, );

    $self->_stream_text($text);
}

sub start_html_tag {
    my $self = shift;
    my ( $tag, $attributes ) = validated_list(
        \@_,
        tag        => { isa => Str },
        attributes => { isa => HashRef },
    );

    $self->_stream_start_tag( $tag, $attributes );
}

sub html_comment_block {
    my $self = shift;
    my ($text) = validated_list(
        \@_,
        text => { isa => Str },
    );

    $self->_stream_raw( '<!--' . $text . '-->' . "\n" );
}

sub html_comment {
    my $self = shift;
    my ($text) = validated_list(
        \@_,
        text => { isa => Str },
    );

    $self->_stream_raw( '<!--' . $text . '-->' );
}

sub html_tag {
    my $self = shift;
    my ( $tag, $attributes ) = validated_list(
        \@_,
        tag        => { isa => Str },
        attributes => { isa => HashRef },
    );

    $self->_stream_start_tag( $tag, $attributes );
}

sub end_html_tag {
    my $self = shift;
    my ($tag) = validated_list(
        \@_,
        tag => { isa => Str },
    );

    $self->_stream_end_tag($tag);
}

sub html_entity {
    my $self = shift;
    my ($entity) = validated_list( \@_, entity => { isa => Str }, );

    $self->_stream_raw( '&' . $entity . ';' );
}

sub html_block {
    my $self = shift;
    my ($html) = validated_list( \@_, html => { isa => Str }, );

    $self->_output()->print($html);
}

sub image {
    my $self = shift;
    my %p    = validated_hash(
        \@_,
        alt_text       => { isa => Str },
        uri            => { isa => Str, optional => 1 },
        title          => { isa => Str, optional => 1 },
        id             => { isa => Str, optional => 1 },
        is_implicit_id => { isa => Bool, optional => 1 },
    );

    delete @p{ grep { !defined $p{$_} } keys %p };

    $self->_stream_start_tag(
        'img', {
            src => $p{uri},
            ( exists $p{alt_text} ? ( alt   => $p{alt_text} ) : () ),
            ( exists $p{title}    ? ( title => $p{title} )    : () ),
        },
    );
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
        map { $self->_attribute( $_, $attr->{$_} ) } keys %{$attr};
}

sub _attribute {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

    return $key unless defined $value;

    return join '=', $key,
        q{"}
        . encode_entities(
        $value,
        $self->_encodable_entities,
        ) . q{"};
}

1;

# ABSTRACT: A role for handlers which generate HTML

__END__

=pod

=head1 NAME

Markdent::Role::HTMLStream - A role for handlers which generate HTML

=head1 VERSION

version 0.26

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

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
