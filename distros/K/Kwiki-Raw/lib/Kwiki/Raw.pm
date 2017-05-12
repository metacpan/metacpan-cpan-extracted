package Kwiki::Raw;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';

const class_id             => 'raw';
const cgi_class            => 'Kwiki::Raw::CGI';

our $VERSION = '0.02';

sub register {
    my $registry = shift;
    $registry->add(action => 'raw');
    $registry->add(toolbar => 'raw_button',
                   template => 'raw_button.html',
                   show_for => 'display',
               );
}

sub raw {
    if ($self->cgi->page_name) {
        $self->hub->headers->content_type('text/plain');
        $self->hub->pages->new_from_name($self->cgi->page_name)->content;
    } else {
        $self->render_screen(
            error_msg => 'raw requires page_name',
        );
    }
}

package Kwiki::Raw::CGI;
use Kwiki::CGI -base;

cgi page_name => -utf8;

package Kwiki::Raw

__DATA__

=head1 NAME

Kwiki::Raw - Provide an action to retrieve the raw wikitext of a page

=head1 DESCRIPTION

Sometimes it is handy to view the wiki source of a page, without
going through the hassle of loading the edit pane. This lets you
do that. Any page content is viewable. If the page does not exist,
an empty response is provided (this may change in the future).

Note: it appears that this plugin may override the controls that
Kwiki::PagePrivacy provides, so if you are using that plugin, don't
use this one. 

=head1 AUTHORS

Chris Dent, <cdent@burningchrome.com>

=head1 SEE ALSO

L<Kwiki>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, Chris Dent

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__template/tt2/raw_button.html__
<!-- BEGIN raw_button -->
<a href="[% script_name %]?action=raw;page_name=[% page_name %]" title="Raw
Wikitext">
[% INCLUDE raw_button_icon.html %]
</a>
<!-- END raw_button -->
__template/tt2/raw_button_icon.html__
Raw
