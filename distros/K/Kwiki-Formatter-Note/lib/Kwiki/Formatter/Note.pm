package Kwiki::Formatter::Note;

use warnings;
use strict;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';
our $VERSION = '0.01';

const class_title => 'Wiki Note';
const class_id => 'wikinote';
const css_file => 'note.css';

sub register {
        my $registry = shift;
        $registry->add(preload => $self->class_id);
        $registry->add(hook => 'formatter:all_blocks',
                post => 'add_note_to_list',
        );
}

sub init {
        super;
        my $formatter = $self->hub->load_class('formatter');
        $formatter->table->{note} = 'Kwiki::Formatter::Note::Block';
}

sub add_note_to_list {
        return [('note', @{$_[-1]->returned})];
}

package Kwiki::Formatter::Note::Block;
use Spoon::Base -Base;
use base 'Spoon::Formatter::Block';

const formatter_id => 'note';
const pattern_block => qr/^NOTE:\s*(.+?)\s*\n/m;
const html_start => q{<table class="note"><tr><th>Note</th><td>};
const html_end => q{</td></tr></table>};

package Kwiki::Formatter::Note;
1; # End of Kwiki::Formatter::Note

__DATA__

=head1 NAME

Kwiki::Formatter::Note - Allows you to put "Notes" in your wiki.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This module will take a note and add special formatting so that the note will
stand out out on the page. Notes are common idioms in books and useful for
Wiki manuals.

In your wiki markup (the uppercase is important):

    NOTE: This is really important!

The HTML produced should be something like:

    <table class="note"><tr>
        <th>Note</th>
        <td>This is really important!</td>
    </tr></table>

With the default stylesheets this will look something like:

    |------|---------------------------|
    | Note | This is really important! |
    |______|___________________________|

=head1 AUTHOR

Eric Anderson, C<< <eric at cordata.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 CorData, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See http://www.perl.com/perl/misc/Artistic.html

=cut
__css/note.css__
.note {
        display: block;
        border: 1px solid black;
        border-collapse: collapse;
        margin: 2ex;
        /*margin-left: 15%;
        width: 50%;*/
}

.note th,
.note td {
        padding: 1em;
}

.note th {
        font-weight: bold;
        font-size: 14px;
        color: white;
        background-color: #999999;
}
