package Markdown::Pod::Handler;
# ABSTRACT: Parser module to convert from markdown to POD

use strict;
use warnings;

our $VERSION = '0.007';

use Markdent::Types;

use namespace::autoclean;
use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::Params::Validate qw( validated_list validated_hash );
use List::Util;

with 'Markdent::Role::EventsAsMethods';

has encoding => (
    is      => 'ro',
    isa     => t('Str'),
    default => q{},
);

has _output => (
    is       => 'ro',
    isa      => t('OutputStream'),
    required => 1,
    init_arg => 'output',
);

#  Default width for horizontal rule
#
our $HORIZONTAL_RULE_WIDTH = 80;

my $link_buf;
my $code_buf;
my $tble_buf;
my @tble = ( [] );
my @blockquotes;
my @list_type;

use constant {
    STACK_LINK     => 1,
    STACK_CODE     => 2,
    STACK_TBLE     => 3,
    STACK_STRONG   => 4,
    STACK_EMPHASIS => 5,
};

my @style_stack;

my $list_depth = 0;

sub _stream {
    my ( $self, @params ) = @_;
    print { $self->_output } @params;
}

sub start_document {
    my $self = shift;

    $self->_stream( '=encoding ' . $self->encoding . "\n\n" ) if $self->encoding;
}

sub end_document { }

sub text {
    my $self = shift;
    my ($text) = validated_list( \@_, text => { type => 'Str' } );

    if (@style_stack) {
        # This allows the end_link() handler to know that *some* text was inside
        # it. So if one has [`text`](http://example.org/), the end_code()
        # handler will output the code to the stream before the end_link()
        # finishes.
        $link_buf->{text} = '' if grep { $_ == STACK_LINK } @style_stack;

        if ( $style_stack[-1] == STACK_LINK ) {
            $link_buf->{text} = $text;
        }
        elsif ( $style_stack[-1] == STACK_CODE ) {
            $code_buf->{text} = $text;
        }
        elsif ( $style_stack[-1] == STACK_TBLE ) {
            $tble_buf->{text} = $text;
        }
        else {
            # another kind of style that does not require storing state
            $self->_stream($text);
        }
    }
    else {
        $self->_stream($text);
    }
}

sub start_header {
    my $self = shift;
    my ($level) = validated_list( \@_, level => { type => 'HeaderLevel' }, );

    $self->_stream("\n=head$level ");
}

sub end_header {
    my $self = shift;
    my ($level) = validated_list( \@_, level => { type => 'HeaderLevel' }, );

    $self->_stream("\n");
}

sub start_paragraph {
    my $self = shift;
}

sub end_paragraph {
    my $self = shift;

    $self->_stream("\n");
}

sub start_link {
    my $self = shift;
    my %p    = validated_hash(
        \@_,
        uri            => { type => 'Str' },
        title          => { type => 'Str', optional => 1 },
        id             => { type => 'Str', optional => 1 },
        is_implicit_id => { type => 'Bool', optional => 1 },
    );

    delete @p{ grep { !defined $p{$_} } keys %p };

    push @style_stack, STACK_LINK;
    $link_buf->{uri} = $p{uri};
    $self->_stream('L<');
}

sub end_link {
    my $self = shift;

    if ( $link_buf && exists $link_buf->{text} ) {
        $self->_stream("$link_buf->{text}|$link_buf->{uri}>");
    }
    else {
        $self->_stream("$link_buf->{uri}>");
    }

    pop @style_stack;
    $link_buf = undef;
}

sub start_strong {
    my $self = shift;

    push @style_stack, STACK_STRONG;
    $self->_stream('B<');
}

sub end_strong {
    my $self = shift;

    pop @style_stack;
    $self->_stream('>');
}

sub start_emphasis {
    my $self = shift;

    push @style_stack, STACK_EMPHASIS;
    $self->_stream('I<');
}

sub end_emphasis {
    my $self = shift;

    pop @style_stack;
    $self->_stream('>');
}

sub preformatted {
    my $self = shift;
    my ($text) = validated_list( \@_, text => { type => 'Str' }, );

    chomp $text;
    $text =~ s/^/    /gsm;
    $self->_stream( $text, "\n\n" );
}

sub start_blockquote {
    my $self = shift;

    $self->_stream("=over 2\n\n");
}

sub end_blockquote {
    my $self = shift;

    $self->_stream("=back\n\n");
}

sub start_unordered_list {
    my $self = shift;

    $self->_stream("\n") if $list_depth;
    $list_depth++;
    $self->_stream("=over\n\n");
}

sub end_unordered_list {
    my $self = shift;

    $list_depth--;
    $self->_stream("=back\n\n");
}

sub start_ordered_list {
    my $self = shift;

    $self->_stream("\n") if $list_depth;
    $list_depth++;
    $self->_stream("=over\n\n");
}

sub end_ordered_list {
    my $self = shift;

    $list_depth--;
    $self->_stream("=back\n\n");
}

sub start_list_item {
    my $self = shift;
    my %p = validated_hash( \@_, bullet => { type => 'Str' }, );

    $self->_stream("=item $p{bullet}\n\n");
}

sub end_list_item {
    my $self = shift;

    $self->_stream("\n\n");
}

sub start_code {
    my $self = shift;
    #  Start buffering this snippet
    push @style_stack, STACK_CODE;
    $code_buf = {};
}

sub end_code {
    my $self = shift;
    my $text = $code_buf->{'text'};
    if ( $text =~ /\n/m ) {
        #  Multi-line. Probably code block
        #
        $text =~ s/^(.*)$/ $1/mg;
        $self->_stream($text);
    }
    else {
        #  Single line
        #
        if ( $text =~ /[<>]/ ) {
            # this is so that extra angle brackets are not used unless necessary
            my @all_angle     = $text =~ /(<+|>+)/g;
            my @all_angle_len = map { length $_ } @all_angle;
            my $longest       = List::Util::max @all_angle_len;

            my $start_angle = "<" x ( $longest + 2 );
            my $end_angle   = ">" x ( $longest + 2 );
            $self->_stream("C$start_angle $text $end_angle");
        }
        else {
            $self->_stream("C<$text>");
        }
    }
    pop @style_stack;
    $code_buf = undef;
}

sub code_block {
    my $self = shift;
    my ($code) = validated_list(
        \@_,
        code     => { type => 'Str' },
        language => { type => 'Str', optional => 1 }
    );
    $code =~ s/^(.*)$/ $1/mg;
    $self->_stream("\n$code\n");
}

sub image {
    my $self = shift;
    my %p    = validated_hash(
        \@_,
        alt_text       => { type => 'Str' },
        uri            => { type => 'Str', optional => 1 },
        title          => { type => 'Str', optional => 1 },
        id             => { type => 'Str', optional => 1 },
        is_implicit_id => { type => 'Bool', optional => 1 },
    );

    delete @p{ grep { !defined $p{$_} } keys %p };

    my $alt_text = exists $p{alt_text} ? qq|alt="$p{alt_text}"| : q{};

    my $attr = exists $p{title} ? $p{title} : q{};
    my $attr_text = q{};
    while ( $attr =~ s/(\S+)="(.*?)"// ) {
        $attr_text .= qq{ $1="$2"};
    }
    while ( $attr =~ /(\S+)=(\S+)/g ) {
        $attr_text .= qq{ $1="$2"};
    }

    $self->_stream(qq|=for html <img src="$p{uri}" $alt_text$attr_text />|);
}

sub start_html_tag {
    my $self = shift;
    my ( $tag, $attributes ) = validated_list(
        \@_,
        tag        => { type => 'Str' },
        attributes => { type => 'HashRef' },
    );
}

sub end_html_tag {
    my $self = shift;
    my ( $tag, $attributes ) = validated_list( \@_, tag => { type => 'Str' }, );
}

sub html_tag {
    my $self = shift;
    my ( $tag, $attributes ) = validated_list(
        \@_,
        tag        => { type => 'Str' },
        attributes => { type => 'HashRef' },
    );

    my $attributes_str = q{};
    $attributes_str = join q{ },
        map { qq|$_="$attributes->{$_}"| } sort keys %$attributes;
    if ( $tag =~ /^br$/i ) {
        $self->_stream(qq|<$tag $attributes_str />\n|);
    }
    else {
        $self->_stream(qq|<$tag $attributes_str />|);
    }
}

sub html_block {
    my $self = shift;
    my ($html) = validated_list( \@_, html => { type => 'Str' }, );

    chomp $html;
    $self->_output()->print(
        <<"END_HTML"

=begin html

$html

=end html

END_HTML
    );
}

sub line_break {
    my $self = shift;
    $self->_stream("\n\n");
}

sub html_entity {
    my $self = shift;
    my ($entity) = validated_list( \@_, entity => { type => 'Str' } );

    $self->_stream("E<$entity>");
}

# Added A.Speer
sub horizontal_rule {
    my $self = shift;
    $self->_stream( ( '=' x $HORIZONTAL_RULE_WIDTH ) . "\n" );
}

sub auto_link {
    my $self = shift;
    my ($uri) = validated_list( \@_, uri => { type => 'Str' } );
    $self->_stream("L<$uri>");
}

sub html_comment_block {
    my $self = shift;
    # Stub
}

sub start_table {
    my $self = shift;
    # Stub
}

sub start_table_body {
    my $self = shift;
    # Stub
}

sub start_table_row {
    my $self = shift;
    # Stub
}

sub start_table_cell {
    my $self = shift;
    push @style_stack, STACK_TBLE;
    $tble_buf = {};
}

sub end_table {
    my $self = shift;
    eval {
        require Text::Table::Tiny;
        1;
    }
        || die('unable to load Text::Table::Tiny - please make sure it is installed !');
    my $table =
        Text::Table::Tiny::table( rows => \@tble, separate_rows => 0, header_row => 0 );
    #  Indent so table appears as POD code. Open to other suggestions
    $table =~ s/^(.*)/  $1/mg;
    $table .= "\n";
    #  Safety in case parser skips end-cell - which it seems to do sometimes
    pop @style_stack;
    $tble_buf = undef;
    $self->_stream($table);
}

sub end_table_body {
    my $self = shift;
    #  Safety
    pop @style_stack;
    $tble_buf = undef;
}

sub end_table_row {
    my $self = shift;
    push @tble, [];
    #  Safety
    pop @style_stack;
    $tble_buf = undef;
}

sub end_table_cell {
    my $self = shift;
    push @{ $tble[$#tble] }, $tble_buf->{'text'};
    #  Stop buffering table text
    pop @style_stack;
    $tble_buf = undef;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdown::Pod::Handler - Parser module to convert from markdown to POD

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    my $handler = Markdown::Pod::Handler->new(
        encoding => $encoding,
        output   => $fh,
    );
    
    my $parser = Markdent::Parser->new(
        dialect => $dialect,
        handler => $handler,
    );

=head1 DESCRIPTION

This module is a handler of L<Markdent> Markdown parser.
It converts Markdown to POD.

=head1 ATTRIBUTES

=head2 markdown

markdown text

=head2 encoding

encoding to use

=head1 METHODS

=head2 new

create Markdown::Pod::Handler object

=head2 markdown_to_pod

convert markdown text to POD text

=for Pod::Coverage STACK_CODE
    STACK_EMPHASIS
    STACK_LINK
    STACK_STRONG
    STACK_TBLE
    auto_link
    code_block
    end_blockquote
    end_code
    end_document
    end_emphasis
    end_header
    end_html_tag
    end_link
    end_list_item
    end_ordered_list
    end_paragraph
    end_strong
    end_table
    end_table_body
    end_table_cell
    end_table_row
    end_unordered_list
    horizontal_rule
    html_block
    html_comment_block
    html_entity
    html_tag
    image
    line_break
    preformatted
    start_blockquote
    start_code
    start_document
    start_emphasis
    start_header
    start_html_tag
    start_link
    start_list_item
    start_ordered_list
    start_paragraph
    start_strong
    start_table
    start_table_body
    start_table_cell
    start_table_row
    start_unordered_list
    text

=head1 SEE ALSO

=over

=item *

L<Markdent>

=item *

L<Pod::Markdown>

=item *

L<Text::MultiMarkdown>, L<Text::Markdown>

=back

=head1 AUTHOR

김도형 - Keedi Kim <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
