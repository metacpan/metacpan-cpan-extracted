package Markdown::phpBB::Handler;

# ABSTRACT: Turn Markdown into phpBB code

use 5.010;
use strict;
use warnings;

use Moose;
use Data::Dumper;

our $VERSION = '0.02'; # VERSION


with 'Markdent::Role::Handler';

has _cached    => (is => 'rw', isa => 'Str', default => '');

our $DEBUG = $ENV{MD2PHPBBDEBUG} || 0;


sub handle_event {
    my ($self, $event) = @_;

    $self->_add( $self->_text_for_event($event) || "");
    
    return;
}

sub _add {
    my ($self, $text) = @_;

    warn "$text\n" if $DEBUG;

    $self->_cached( $self->_cached . $text );
}


sub result {
    my ($self) = @_;

    my $cached = $self->_cached();

    $self->_cached(""); # Clear cache;

    # Fix tags on wrong lines
    $cached =~ s{\n\[/li\]}{[/li]\n}g;
    $cached =~ s{\n\[/size\]\[/b\]}{[/size][/b]\n}g;

    $cached =~ s{\s*$}{\n};                   # Remove trailing whitespace

    return $cached;

}

my %tag = (
    document       => [    "",                           ""             ],
    paragraph      => [    "",                           "\n"           ],
    emphasis       => [ qw([i]                           [/i])          ],
    strong         => [ qw([b]                           [/b])          ],
    unordered_list => [   "[list]\n",                   "[/list]\n"     ],
    ordered_list   => [   "[list type=decimal]\n",      "[/list]\n"     ],
    list_item      => [ qw([li]                          [/li] )        ],
    link           => [ qw([url]                         [/url])        ],
    header         => [   "[b][size]",                  "[/size][/b]\n" ],
    code           => [   "[font=courier]",             "[/font]"       ],
    blockquote     => [ qw([quote]                       [/quote])      ],
);

my @heading_size = (36, 24, 18, 14, 12);

sub _text_for_event {
    my ($self, $event) = @_;

    my $name  = $event->event_name;
    my $start = $event->is_start;

    if ($name eq 'text')            { return $event->text; }
    if ($name eq 'horizontal_rule') { return "[hr]\n\n"    }

    if ($name eq 'code_block')      { return "[code]".$event->code."[/code]" }
    if ($name eq 'preformatted')    { return "[code]".$event->text."[/code]" }

    if ($name eq 'start_link' ) {
        my $url = $event->uri;
        return "[url=$url]";
    }

    if ($name eq 'image') {
        my $url = $event->uri;
        return "[spoiler][img]$url\[/img][/spoiler]"
    }


    if ($name eq 'start_header') {
        my $level = $event->level;
        my $size  = $heading_size[$level-1];
        return "[b][size=${size}pt]"
    }

    $name =~ s/^(?:start|end)_//;
    if ($tag{$name}) { return $tag{$name}[$start ? 0 : 1]; }

    # Oh noes! Something went wrong.

    use Data::Dumper;
    warn "Unknown markdown event: ". $event->event_name . "\n\n" . Dumper { $event->kv_pairs_for_attributes };

    return;

}

1;

__END__

=pod

=head1 NAME

Markdown::phpBB::Handler - Turn Markdown into phpBB code

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use Markdent::Parser;
    use Markdown::phpBB::Handler;

    my $handler = Markdown::phpBB::Handler->new;

    my $parser = Markdent::Parser->new(
        handler => $handler,
        dialect => 'GitHub',  # optional
    );

    $parser->parse(markdown => $md);

    my $phpBB = $handler->reseult;

=head1 METHODS

=head2 handle_event

Called by L<Markdent::Parser>. Takes an event and processes it.

=head2 result

    my $phpbb = $handler->result;

Returns the final string in phpBB after conversion.

Note that in the current version, calling this also resets the handler
state, so subsequent calls with return an empty string. Patches welcome
to fix this.

=head1 DESSCRIPTION

This is a L<Markdent::Role::Handler> which produces phpBB / BBcode
from Markdown.

It will emit a warning (but will continue) if it encounters events
it does not understand. Patches are very welcome.

=head1 SEE ALSO

L<Markdown::phpBB>, L<md2phpbb>, L<phpbb2md>, L<Markdent>

=head1 BUGS

Plenty. In particular, calling C<result> a second time will return an
empty string.

Report them or fix them at
L<http://github.com/pjf/Markdown-phpBB/issues>.

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
