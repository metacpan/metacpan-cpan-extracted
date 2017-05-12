package Kwiki::Formatter::Emphasis;

use warnings;
use strict;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';
our $VERSION = '0.01';

const class_title => 'Emphasis';
const class_id => 'wikiemphasis';

sub register {
        my $registry = shift;
        $registry->add(preload => $self->class_id);
        $registry->add(hook => 'formatter:all_phrases',
                post => 'add_emphasis_to_list',
        );
}

sub init {
        super;
        my $formatter = $self->hub->load_class('formatter');
        $formatter->table->{emphasis} = 'Kwiki::Formatter::Emphasis::Phrase';
        $formatter->table->{em} = 'Kwiki::Formatter::Italicize';
}

sub add_emphasis_to_list {
        return [('emphasis', @{$_[-1]->returned})];
}

package Kwiki::Formatter::Emphasis::Phrase;
use Spoon::Base -Base;
use Kwiki ':char_classes';
use base 'Spoon::Formatter::Phrase';

const formatter_id => 'emphasis';
const pattern_start => qr/(^|(?<=[^$ALPHANUM]))\~(?=\S[^\~]*\~(?=\W|\z))/;
const pattern_end => qr/\~(?=[^$ALPHANUM]|\z)/;
const html_start => "<em>";
const html_end => "</em>";

package Kwiki::Formatter::Italicize;
use Spoon::Base -Base;
use base 'Spoon::Formatter::Phrase';
use Kwiki ':char_classes';
const formatter_id => 'em';
const pattern_start => qr/(^|(?<=[^$ALPHANUM]))\/(?=\S[^\/]*\/(?=\W|\z))/;
const pattern_end => qr/\/(?=[^$ALPHANUM]|\z)/;
const html_start => "<i>";
const html_end => "</i>";

package Kwiki::Formatter::Emphasis;
1; # End of Kwiki::Formatter::Emphasis
__DATA__
=head1 NAME

Kwiki::Formatter::Emphasis - Will add new syntax for emphasizing text and
fix a bug in the Kwiki core that will make the built-in italic syntax actually
italicize the text.

=head1 SYNOPSIS

        ~foo~

Produces <em>foo</em>

        /foo/

Produces <i>foo</i>

=head1 AUTHOR

Eric Anderson, C<< <eric at cordata.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 CorData, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See http://www.perl.com/perl/misc/Artistic.html
