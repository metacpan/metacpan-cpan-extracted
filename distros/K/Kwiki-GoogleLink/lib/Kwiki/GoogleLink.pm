package Kwiki::GoogleLink;
use strict;
use warnings;
use Kwiki::Plugin '-Base';

our $VERSION = 0.01;

const class_title => 'Google Search Link';
const class_id => 'google_link';

sub register {
    my $registry = shift;
    $registry->add(wafl => google => 'Kwiki::GoogleLink::Wafl');
}

package Kwiki::GoogleLink::Wafl;
use Spoon::Formatter ();
use base 'Spoon::Formatter::WaflPhrase';

const google_search => 'http://www.google.com/search?q=';

sub html {
    my $search = $self->arguments;
    join('', 
         '<a href="', 
         $self->google_search,
         $self->uri_escape($search), '">',
         $self->html_escape($search), '</a>'
        );
}

1;

__DATA__

=head1 NAME 

Kwiki::GoogleLink - easy links to Google searches

=head1 SYNOPSIS

 $ cpan Kwiki::GoogleLink
 $ cd /path/to/kwiki
 $ echo "Kwiki::GoogleLink" >> plugins
 $ kwiki -update

=head1 DESCRIPTION

This was written as a demonstration of a plugin to add a new WAFL
phrase to the Kwiki formatting rules.

This plugin makes it quick and easy to add a Google search link to a
Kwiki page, for example:

    Search Google for: {google:Kwiki}

will be rendered as

    Search Google for: <a href="http://www.google.com/search?q=Kwiki">Kwiki</a>

This example can be used as the basis for custom shortcuts at your own
site.

=head1 AUTHORS

Michael Gray <mjg17@eng.cam.ac.uk>

=head1 SEE ALSO

L<Kwiki>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Michael Gray

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
