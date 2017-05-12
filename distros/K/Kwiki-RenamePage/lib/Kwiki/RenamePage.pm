package Kwiki::RenamePage;

use warnings;
use strict;

=head1 NAME

Kwiki::RenamePage - Better Names for Misnamed Kwiki Pages

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Moves content of OldPage to NewName, replacing it with the message, "This page has moved to NewName." Text in other pages which could have been a link to OldPage is changed to link to NewName, but with the old text left parenthesized as, "(Old name: OldPage)".

=cut

use Kwiki::Plugin '-Base';
use mixin 'Kwiki::NewPage';
use mixin 'Kwiki::Installer';

=head1 class_id

Unmodifiable Class id accessor

=cut

const class_id => 'rename_page';

=head1 cgi_class

Unmodifiable Class class accessor

=cut

const cgi_class => 'Kwiki::RenamePage::CGI';

=head1 screen_template

unmodifiable screen_template accessor

=cut

const screen_template =>  'rename_page_content.html';

=head1 old_page_name

Modifiable old_page_name accessor

=cut

field 'old_page_name';

=head1 old_page_content

Modifiable old_page_content accessor

=cut

field 'old_page_content';

# field 'page_time';

=head1 METHODS

=over 8

=item B<register>

Plug the plugin in.

=cut

sub register {
    my $registry = shift;
    $registry->add( action => 'rename_page' );
    $registry->add( toolbar => 'rename_page_button',
    			template => 'rename_page_button.html' );
}

=item B<rename_page>

Rename the page.

=cut

sub rename_page {
    my $page = $self->pages->current;
    my $old_name = $self->cgi->old_page_name;
    my $new_name      = $self->cgi->new_page_name;
    $self->old_page_name( $self->cgi->page_name );
    my $error_msg = '';
    my $page_uri;
    if ( $self->cgi->button ) {
        $error_msg = $self->check_page_name or do {
	    my $old_page = $self->pages->new_from_name( $old_name );
            my $new_page = $self->pages->new_from_name( $new_name );
            return $self->redirect( $new_page->uri )
              unless $new_page->is_writable;
	    my $current = $self->pages->current($old_page);
	    my $yanked_content  = $current->content;
	    $current->content("This page has moved to $new_name.");
	    if ( $current->modified_time != $self->cgi->page_time )
	    {
		    return("action=edit_contention;page_name=$current->uri");
	    }
            $current->update->store;
	    my $link = qr/$old_name/;
	    for my $page ( $self->pages->all )
	    {
		    # my $current = $self->pages->current($page);
		    my $content  = $page->content;
		    $content =~ s/$old_name/$new_name (Old name: $old_name)/g;
		    $page->content($content);
		    $page->update->store;
	    }
            $current = $self->pages->current($new_page);
            $current->content($yanked_content);
            $current->update->store;
	    return $self->redirect($current->uri);
          }
    }
    return $self->render_screen( error_msg => $error_msg ) if $error_msg;
    return $self->render_screen( old_page_name => $self->old_page_name, 
    				page_time => $page->modified_time);
}

package Kwiki::RenamePage::CGI;
use Kwiki::CGI '-base';

cgi 'new_page_name';
cgi 'old_page_name';
cgi 'page_name';
cgi 'page_time';

1;

package Kwiki::RenamePage;

=back

=head1 AUTHOR

Dr Bean, C<< <drbean, then an at sign, cpan, a dot, and finally org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-kwiki-renamepage at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Kwiki::RenamePage>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Kwiki::RenamePage

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Kwiki::RenamePage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Kwiki::RenamePage>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Kwiki::RenamePage>

=item * Search CPAN

L<http://search.cpan.org/dist/Kwiki::RenamePage>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Kwiki::RenamePage

__DATA__

__template/tt2/rename_page_button.html__
<!-- BEGIN rename_page_button.html -->
[% IF hub.pages.current.is_writable %]
[% rev_id = hub.have_plugin('revisions') ? hub.revisions.revision_id : 0 %]
<a href="[% script_name %]?action=rename_page;page_name=[% page_uri %][% IF rev_id %];revision_id=[% rev_id %][% END %]" accesskey="R" title="Rename Page">
[% INCLUDE rename_page_button_icon.html %]
</a>
[% END %]
<!-- END rename_page_button.html -->
__template/tt2/rename_page_button_icon.html__
<!-- BEGIN rename_page_button_icon.html -->
Rename
<!-- END rename_page_button_icon.html -->
__template/tt2/rename_page_content.html__
<!-- BEGIN rename_page_content.html -->
[% screen_title = 'Rename Page' %]
<form method="post">
<p>Enter a new page name for this page.</p>
<p>OLD NAME: [% self.old_page_name %]</p>
<p>NEW NAME: <input type="text" size="20" maxlength="30" name="new_page_name" value="[% new_page_name %]" />
<input type="submit" name="button" value="RENAME" /></p>
<br />
<br />
<span class="error">[% error_msg %]</span>
<input type="hidden" name="action" value="rename_page">
<input type="hidden" name="old_page_name" value="[% old_page_name %]">
<input type="hidden" name="page_time" value="[% page_time %]">
</form>
<pre>


</pre>
<!-- END rename_page_content.html -->
