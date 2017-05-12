package Markdown::TOC;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

sub new {
    my ($class, %params) = @_;

    my $self = { %params };
    $self->{_lines} = [];
    return bless $self, $class;
}

sub process {
    my ($self, $markdown) = @_;

    return '' unless $markdown;

    my $header_sharp_re = qr/^ (\#+) \s* (.+) $/xm;
    my $header_underline_re = qr/ ^ (.+) \n ([-=]+) $/xm;

    while ( $markdown =~ /(?:$header_sharp_re|$header_underline_re)/gc ) {
        if ( $1 && $2 ) {
            $self->_sharp_header($1, $2);
        }
        else {
            $self->_underline_header($3, $4);
        }
    }

    my $delimeter = $self->{delimeter} || '';
    return join $delimeter => @{$self->{_lines}};
}


sub _sharp_header {
    my ($self, $sharp, $text) = @_;

    my $level = length($sharp);
    $self->_header($text, $level);
}

sub _underline_header {
    my ($self, $text, $underline) = @_;

    my $level = $underline =~ /=/ ? 1 : 2;
    $self->_header($text, $level);
}

sub _header {
    my ($self, $text, $level) = @_;

    # Just to notify about a header
    if ( my $listener = $self->{listener} ) {
        $listener->($text, $level);
    }

    if ( my $full_line_handler = $self->{raw_handler} ) {
        my $text  = $full_line_handler->($text, $level);
        $self->_append($text);
        return;
    }
    
    my $anchor = $self->_get_anchor($text, $level);
    my $order_number;
    my $full_order;

    if ( my $order_handler = $self->{order_handler} ) {
        $order_number = $order_handler->($text, $level);
    }
    else {
        $full_order = $self->_order_number($text, $level);
        $order_number = join '.' => @$full_order;
        $order_number = "$order_number. ";
    }

    my $formatted;
    if ( my $formatter = $self->{handler} ) {
        # User decided to take care of the format only - we are ok with that
        $formatted = $formatter->( 
            text => $text,
            anchor => $anchor,
            order_formatted => $order_number,
            order => $full_order,
            level => $level,
        );
    }
    else {
        my $order_number = '';
        if ($anchor) {
            $formatted = qq{<h$level>$order_number<a href="#$anchor">$text</a></h$level>};
        }
        else {
            $formatted = qq{<h$level>$order_number$text</h$level>};
        }
    }
    $self->_append($formatted);
}


sub _order_number {
    my ($self, $text, $level) = @_;

    my $last_header_level = $self->{_orders}->{last_header_level} || $level;
    $self->{_orders}->{last_header_level} = $level;

    if ($last_header_level > $level) {
        $self->{_orders}->{$last_header_level}->{last_order} = 0;
    }
    my $order = $self->{_orders}->{$level}->{last_order} || 0;
    $order++;
    $self->{_orders}->{$level}->{last_order} = $order;

    my @full_order = ();
    for ( 1 .. $level ) {
        push @full_order, $self->{_orders}->{$_}->{last_order} || 1;
    }
    return \@full_order;
}

sub _get_anchor {
    my ($self, $text, $level) = @_;

    if (my $anchor_handler = $self->{anchor_handler}) {
        my $anchor = $anchor_handler->($text, $level);
        return $anchor;
    }
    return '';
}


sub _append {
    my ($self, $text) = @_;

    push @{$self->{_lines}}, $text;
}

1;

__END__

=encoding utf-8

=head1 NAME

Markdown::TOC - Create a table of contents from markdown

=head1 SYNOPSIS

    use Markdown::TOC;

    my $toc = Markdown::TOC->new(handler => sub {
        my %params = @_;

        return '+' x $params{level} . ' ' . $params{text};
    });

    my $md = q{
    # header1 

    some text

    ## header 2

    some another text
    
    };

    my $toc_html = $toc->process;

=head1 DESCRIPTION

Markdown::TOC is a simple module for building table of contents of markdown files.
The module itself produces a very simple and rather ugly table of contents, it is
supposed to be used with handlers to provide a nice custom-formatted toc.

=head1 METHODS

=head2 new

    my $toc = Markdown::Toc->new(
        handler => sub { ... },
        order_handler => sub { ... },
        anchor_handler => sub { ... },

        delimeter => "\n"
    )

Creates a new TOC processor.

    delimeter - is used for final strings concatenations, an empty string by default.

All handlers are described below.

=head2 process 

Produces formatted TOC from the provided markdown content.

    $toc->process($md);

=head1 HANDLERS

When a header is discovered, an event is fired. So several handlers could be defined to take care
of actual formatting.

=head2 raw_handler

Takes half-raw data and takes care of all formatting. Accepts C<$text> - text content of a header
and C<$level> - header level

    my $toc = Markdown::TOC->new(raw_handler => sub {
        my ($text, $level) = @_;
        # Do something about that
    });

=head2 handler

Takes processed data, like text, level, determined order and an anchor for a header.
    
    my $toc = Markdown::TOC->new(handler => sub{
        my (%param) = @_;

        my $text = $param{text};
        my $anchor = $param{anchor};
        my $order_formatted = $param{order_formatted};
        my $order = $param{order}; # an array like [1, 2, 1], where the first element contains first level number and so on
    
        # format text and give it away
    });

=head2 anchor_handler

Takes C<$text> and C<$level> and returns an anchor for a header link
(If we want the link in toc to point on the header. Or somewhere else)

    my $toc = Markdown::TOC->new(anchor_handler => sub {
        my ($text, $level) = @_;
        my $anchor = $text;
        # getting rid of all spaces..
        $anchor =~ s/\s+/_/g;
        return $anchor;
    });

=head2 order_handler 

Takes C<$text> and C<$level> and returns a formatted order mark for our future table of contents.

    my $toc = Markdown::TOC->new(sub {
        my ($text, $level) = @_;
        return 42;
    });

If this handler and C<handler> were specified, the result from the callback is passed as order_formatted
parameter.


=head2 listener 

Like raw_handler, but returns nothing.

    my $table = [];
    my $toc = Markdown::TOC->new(listener => sub {
        my ($text, $level) = @_;
        push @$table, {text => $text, level => $level};
    });

=head1 LICENSE

Copyright (C) Polina Shubina.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Polina Shubina E<lt>925043@gmail.comE<gt>

=cut

