package Kwiki::DatedAnnounce;
use strict;
use warnings;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';

our $VERSION = 0.01;

const class_title => 'Dated Announced';
const class_id => 'dated_announce';
const css_file => 'dated_announce.css';

sub register {
    my $registry = shift;
    $registry->add(wafl => dated => 'Kwiki::DatedAnnounce::Wafl');
}

package Kwiki::DatedAnnounce::Wafl;
use base 'Spoon::Formatter::WaflBlock';

sub to_html {
    my $string = $self->block_text;
    chomp $string;
    # XXX datespec should be better than epoch
    $string =~ s/^ datespec: \s* (\w+) \s* (\w+) \s* \n+//sx;

    my $datespec = $1 || 0;
    my $duration = $2 || 0;
    my $now = time;
    
    if (($now >= $datespec) &&
        (($duration == 0) || ($now <= $datespec + $duration))) {
           return "<div class='dated'>\n" .
                  $self->hub->formatter->text_to_html($string) .
                  "</div>\n";
    } else {
        return "\n";
    }
}

package Kwiki::DatedAnnounce;
1;

__DATA__

=head1 NAME 

Kwiki::DatedAnnounce - Create a date sensitive section of output

=head1 SYNOPSIS

 $ cd /path/to/kwiki
 $ kwiki -install Kwiki::DatedAnnounce

=head1 DESCRIPTION

This module allows you to wrap a section of wikitext to be displayed
only after a certain time for an optional number of seconds. For
example:

    .dated
    datespec: 1095056602 172800

    Hello, it's around Monday, September 13, 2004.
    .dated

datespec is two numbers representing the number of seconds since
the epoch and a duration in seconds. Duration defaults to zero if
none is provided. Zero means infinite duration. If the time of the
current display is within the window described by the datespec, the
content will be displayed.

=head1 CREDITS

This was my first plugin, trying to figure out what was going on.
I've pulled it out of the dusty corners to make it go with Kwiki::Test

=head1 AUTHORS

Chris Dent <cdent@burningchrome.com>

Based on Ian Langworth's L<Kwiki::VimMode>

=head1 SEE ALSO

L<Kwiki>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Chris Dent

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__css/dated_announce.css__
div.dated { background: #dddddd; }
