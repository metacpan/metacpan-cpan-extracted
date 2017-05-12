package Kwiki::Edit::SubEtha;
$Kwiki::Edit::SubEtha::VERSION = '0.02';

use strict;
use warnings;
use Kwiki::Edit '-Base';
use mixin 'Kwiki::Installer';

=head1 NAME

Kwiki::Edit::SubEtha - SubEthaEdit Plugin for Kwiki

=head1 VERSION

This document describes version 0.02 of Kwiki::Edit::SubEtha, released
July 27, 2004.

=head1 SYNOPSIS

A live SubEthaKwiki is available at L<http://wiki.oreillynet.com/oscon/>
for the duration of O'Reilly Open Source Convention 2004.

=head1 DESCRIPTION

=head2 SubEtha Machine

You need OS X 10.3 or above, with I<UI Scripting> enabled; see
L<http://www.apple.com/applescript/uiscripting/01.html> for instructions
on how to enable it.

Tweak the configuration constants in F<script/subethakwiki.pl> and run it.
It will do several things every 15 seconds:

 * force an autosave
 * svn up
 * check for each "A edits/*", set TTL
 * open the documents in SubEthaEdit and share them
 * svn ci
 * check for each "M pages/*" and refresh their TTL
 * for pages that has TTL expired, close the document, record it.
 * svn rm edits/* those pages.
 * svn ci
 * loop

Note that the SubEthaEdit window will pop out constantly; currently, you
really need a dedicated machine to do this.

=head2 Kwiki Machine

First, install the B<Kwiki::Archive::SVK> plugin, run F<index.cgi>
once, then share the repository located at F<kwiki_path/plugin/archive>
using F<svnserve> or WebDAV, and make it accessible form the SubEtha machine.

Now install the B<Kwiki::Edit::SubEtha> plugin.  For nonshared (normal)
pages, the user will see:

 * provides an "Edit" item as normal.
 * for OSX people, an additional "SubEthaEdit" button:
 ** shows a page explaining what's it about
 ** explain the rules
 ** offer a link that, when clicked, does "svk mkdir edits/Pagename"
 ** and redirects to see://hostname/PageName/

For shared (subetha-editable) pages, the user will see:

 * a "Lock" item explaining it's being locked by SubEthaEdit
 * for OSX people, a "SubEthaEdit" button that just links to see://see_url.

=cut

const class_title => 'SubEtha Edit';
const cgi_class => 'Kwiki::Edit::SubEtha::CGI';
const config_file => 'edit.yaml';

sub register {
    my $registry = shift;
    super;
    $registry->add(action => 'edit_see_share');
    $registry->add(action => 'edit_see_start');
    $registry->add(action => 'edit_see_locked');
    $registry->add(toolbar => 'edit_see_share_button', 
                   template => 'edit_see_share_button.html',
                   show_for => ['display'],
                  );
}

sub screen_title {
    (screen_title => $self->pages->current->id)
}

sub edit_see_share {
    $self->render_screen(
        content_pane => 'edit_see_share_content.html',
        $self->screen_title,
    );
}

sub edit_see_locked {
    $self->render_screen(
        locked => 1,
        content_pane => 'edit_see_share_content.html',
        $self->screen_title,
    );
}

sub edit_see_start {
    $self->share_page;
    $self->render_screen(
        content_pane => 'edit_see_start_content.html',
        $self->screen_title,
    );
}

sub is_shared {
    my $page = $self->pages->current;

    my $handle = $self->hub->load_class('archive')->svk_handle($self);
    my $fs = ($handle->{xd}->find_repos('//', 1))[2]->fs;
    my $root = $fs->revision_root($fs->youngest_rev);

    return($root->check_path("/edits/".$page->id) != $SVN::Node::none);
}

sub share_page {
    my $page = $self->pages->current;

    my $handle = $self->hub->load_class('archive')->svk_handle($self);
    my $fs = ($handle->{xd}->find_repos('//', 1))[2]->fs;
    my $txn = $fs->begin_txn($fs->youngest_rev);
    my $root = $txn->root;
    my $lock = "/edits/".$page->id;

    if ($root->check_path($lock) == $SVN::Node::none) {
        my $pool = SVN::Pool->new_default;
        $root->make_dir($lock, $pool);
        $txn->commit;
        $pool->clear;
    }
}

sub is_macosx {
    $ENV{HTTP_USER_AGENT}
      and $ENV{HTTP_USER_AGENT} =~ /Mac OS X|Mac_PowerPC/;
}

package Kwiki::Edit::SubEtha::CGI;
use base 'Kwiki::Edit::CGI';

1;

package Kwiki::Edit::SubEtha;

__DATA__

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>,
Brian Ingerson E<lt>INGY@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2004 by
Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>,
Brian Ingerson E<lt>INGY@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
__config/edit.yaml__
edit_save_button_text: SAVE
edit_preview_button_text: PREVIEW
default_content: Enter your own page content here.
see_url: see://kwiki.org

__template/tt2/edit_button.html__
<!-- BEGIN edit_button.html -->
[% IF hub.load_class('edit').is_shared %]
<a href="[% script_name %]?action=edit_see_locked&page_id=[% page_uri %]"
title="This Page Locked for SubEthaEdit">
[% INCLUDE edit_see_locked_button_icon.html %]
</a>
[% ELSE %]
[% rev_id = hub.revisions.revision_id %]
<a href="[% script_name %]?action=edit&page_id=[% page_uri %][% IF rev_id %]&revision_id=[% rev_id %][% END %]" accesskey="e" title="Edit This Page">
[% INCLUDE edit_button_icon.html %]
</a>
[% END %]
<!-- END edit_button.html -->

__template/tt2/edit_button_icon.html__
<!-- BEGIN edit_book_button_icon.html -->
Edit
<!-- END edit_book_button_icon.html -->

__template/tt2/edit_contention.html__
<!-- BEGIN edit_contention.html -->
<div class="error">
<p>
While you were editing this page somebody else saved changes to
it. You need to start over and apply your changes to the latest
copy of the page.
</p>
<p>
You may also get this message if you saved some changes and then used
your browser's back button to return to the Edit screen and make more
changes. Always use the Kwiki Edit button to get to the Edit screen.
</p>
</div>
<!-- END edit_contention.html -->

__template/tt2/edit_content.html__
<!-- BEGIN edit_content.html -->
<script language="JavaScript" type="text/JavaScript"><!--
function clear_default_content(content_box) {
    if (content_box.value == '[% default_content %]') {
        content_box.value = '';
    }
}
--></script>
[% IF button == edit_preview_button_text %]
[% preview_content %]
<hr />
[% END %]
<form method="POST">
<input type="submit" name="button" value="[% edit_save_button_text %]" />
<input type="submit" name="button" value="[% edit_preview_button_text %]" />
<br />
<br />
<input type="hidden" name="action" value="edit" />
<input type="hidden" name="page_id" value="[% page_uri %]" />
<input type="hidden" name="page_time" value="[% page_time %]" />
<textarea name="page_content" rows="25" cols="80" onfocus="clear_default_content(this)">
[%- page_content -%]
</textarea>
</form>
<!-- END edit_content.html -->

__template/tt2/edit_see_share_button.html__
[% IF hub.load_class('edit').is_macosx %]
<!-- BEGIN edit_see_share_button.html -->
[% IF hub.edit.is_shared %]
<a href="[% see_url %]" title="Join SubEthaEdit in Progress">
[% INCLUDE edit_see_join_button_icon.html %]
</a>
[% ELSE %]
[% IF page_name != hub.config.main_page %]
<a href="[% script_name %]?action=edit_see_share&page_id=[% page_uri %]" title="Edit This Page with SubEthaEdit">
[% INCLUDE edit_see_share_button_icon.html %]
</a>
[% END %]
[% END %]
<!-- END edit_button.html -->
[% END %]
__template/tt2/edit_see_share_button_icon.html__
<!-- BEGIN edit_see_share_button_icon.html -->
SubEtha Edit
<!-- END edit_see_share_button_icon.html -->

__icons/gnome/template/edit_see_share_button_icon.html__
<!-- BEGIN edit_see_share_button_icon.html -->
<img src="icons/gnome/image/edit_see_share.png" alt="SubEtha Edit" />
<!-- END edit_see_share_button_icon.html -->

__template/tt2/edit_see_share_content.html__
<!-- BEGIN edit_see_share_content.html -->
[% IF locked %]
<p>
<b>This page has been temporarily locked for use in SubEthaEdit.</b>
</p>
[% ELSE %]
<form action="[% script_name %]" method="POST">
<p>
Click
    <input type="hidden" name="action" value="edit_see_start" />
    <input type="hidden" name="page_id" value="[% page_id %]" />
    <input type="submit" value="Share this page" />
to start using SubEthaEdit to edit this page.
</p>
</form>
[% END %]

<p>
SubEthaEdit is a collaborative text editor that allows many authors to
edit a single document at the same time. In the past, OSCON attendees
have found it to be a great way to take &#40;and pass&#41; notes
together. 
</p>

<h2>Getting SubEthaEdit</h2>

<p>
Unfortunately, SubEthaEdit is only available for Mac OS X 10.3 or newer.
Here at OSCON, we&#39;re using SubEthaEdit 2.0. If you don&#39;t already
have version 2.0 installed, you can download a copy from the
authors&#39; website, 
<a href="http://codingmonkeys.de/subethaedit/">codingmonkeys.de</a>.
</p>

<h2>Editing this page</h2>
<p>
Once you&#39;ve got SubEthaEdit installed, just 
<a href="[% see_url %]">click here to connect</a>. Every update you
make to the page in SubEthaEdit will be posted to the kwiki within a
minute. If you don&#39;t touch the page in SubEthaEdit for 3 minutes or
so, you&#39;ll need to check it out for editing again.
</p>

<h2>If you can&#39;t run SubEthaEdit</h2>

<p>
Unfortunately, SubEthaEdit isn&#39;t useful for everyone. After about
three minutes of non-activity, this page will unlock itself for regular
web based Kwiki editing.
</p>

<h2>No, it&#39;s not Open Source</h2>

<p>
SubEthaEdit is free for non-commercial use, but it isn&#39;t Open Source
Software. To our knowledge, there aren&#39;t yet any usable Open Source
tools that do what SubEthaEdit does. If you know of any, please update
the <a href="[% script_name %]?SubEthaKwiki">SubEthaKwiki</a> page on this
wiki and we&#39;ll do what we can to add support for them.
</p>
<!-- END edit_see_share_content.html -->

__icons/gnome/image/edit_see_share.png__
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAABGdBTUEAANbY1E9YMgAAABl0RVh0
U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAGAUExURXXTaamWAxRzAUSaNFmmTQqZADe5
LLrBwnWbfWWdamimbMdqAZumocvV0ki2QimqGiqXGJpcCTCcKbLiqkjMN7PisC+UKZPbikZRCN7i
5K5qAjarKaLcnOHl536phl6bY/Hy9I7agr/Mx0azOPb3+EahP1HEP47WiV+sV+rrtKfjnsrO0Ets
CeGfArNyJ/DswzSOLdKvlWONLNXOy4fPjNbY29nY10+bQs6cApy1pGtzWMCPS4nXgMHNyViuUFyj
XTbJJ3+EAx9LJ8HnxTRNNT5mDqRcF3PAdmO3UK7BtbjFwLHbq86nYqDZm/v487fdtPz9/SA5H2xx
F4uBVi6uI3M4BD+fO67gqeTm6GpWACqMKIPUd/v36T6TPMKridi2gIujmGnRWuvt75eJBkDILhOo
COfMhebTnoGKh3ekfdDW2Z/glNvX1NvZ2ESPQ8Dou1eXWtGrAFvJUe/x8mKRRLblvC+BGjmNQKqI
VFDFQF/MT1qaPdacVMvFwnvNff///zRLv2wAAACAdFJOU///////////////////////////////
////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////8AOAVLZwAAAONJ
REFUeNpiqAcB2UxOpXoIYAARCrEMwhpeKmbWPjEQAd6QaG9fA64SRgtrP7CApJC4jbJdvrN7Mrch
WKCeQ4CftSjcv9TIrRYsoJLHyspaxiIqyswOMUNJOlFahzGShYETaoucmnh1oS63RLksVICzSt3D
UUqQKQvqjpwgPhlfE3MBNk+IQK6elGudqJYYnyIXRCAuPV5QIkyIwy47LAkkEBGsr1kTyhSVpaqo
bAsS4HEKTqtgcpBmD2OolAMKSLoEWhnzpIrwJwiJpIgV1zNoZ5gG1Ety2hd4WcrLcxTXAwQYAOmM
S5YliFNiAAAAAElFTkSuQmCC
__template/tt2/edit_see_join_button_icon.html__
<!-- BEGIN edit_see_join_button_icon.html -->
SubEtha Join
<!-- END edit_see_join_button_icon.html -->

__icons/gnome/template/edit_see_join_button_icon.html__
<!-- BEGIN edit_see_join_button_icon.html -->
<img src="icons/gnome/image/edit_see_join.png" alt="SubEtha Join" />
<!-- END edit_see_join_button_icon.html -->

__icons/gnome/image/edit_see_join.png__
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1AcaBCwNiHYgvQAAA4pJREFUeNpVke9PlAUAgJ/3F8ed
3E8O7hCICE9pq0AgRQZzkqwil7VqbBFfDNuUL33pQ7bSxZeYLFdNYiHNiulmNfskrRbNMFBCcwoT
5YDTuwOOu+MOOOR47717+9Bc6/kDnj3bIwAUFhZmdXZ2drW0tLyr6zqPyGQyaJpGNBpFVVU0TUPP
pPF9/x6no5dJBjLIAwMDksfj6QoGgx2alkKSZAD8fj+iKCIIAgApTePLoT5KZ0Zoa7pBW1Li0z/c
CA6HQ+7v7/9M07SjtbW12Gy2/xWoqoqu6/Rc6uP38EnObI/zxbSMaX8HRc4SJIvFoodCIa/H43nd
ZrPlWK02BEEgmUzi9/sxGAwoksDl707wUfUMK1b4esTCrB5DsKpILpdLmJqaSrjd7pzbC1MNvd7T
wvCtEZ4t2kVxURFk0kz0v8OrdUNk58HbY3bajh6nztPA+aELSHa7XTAajcKEz8t43ZXWN5qbxZqn
dtL17SkWIkv4fuymsXoQMRcme+FsiY5UJOPf9DE6NYYMIAiCrphNCWwJwqkFgqkAQec0+fUvECmr
56vRqzRdXGNyGtb8MjdtXuZDC2yaU0h2ux0AYVNYXYls7PPJs8XDY9ewluVQs7WSEkcZ44k0iYE7
fFgikNqrsGdmP/eXH2Bq2PxPYH+s1LFU4Tu27FreoiUzSL/GmZv3s7NqF9dXbmK1tjJXFKD8RTv+
8ruYKwWcBgtSLBYjFothqrQdNL+28daeHRUUDAbp3a2jnI/Qo95Am1M4vLcdb2AO05MK24we8rMK
cGe5ER89T2yJV9lzrbjEYmqKJdQRcIug/azwfvUxJEnEKedj1nMoMTxOoWErsmj4V/DxK03FzaFo
YzoiUprzBOmD7XxSt5sPXspCe1nDaMgmLy8PV64Lo2hmPZ1i8IcrBKIBxOPth4zbLUs/HTCmK5ST
cyyFI5isCgura5RXPcPTNdtYjIfJczpRdRVZlJgJ3KPVdAjv9UVELTy5r+HIgarnPj9Fh+Lg0ptn
6O7uoX7leTaim9icZkaXryErCuupBKuZOMn0Q9wFLhQ1G/Hs7QdHTpy7ip7xYanfwXxjhnSjhsNp
ZzERIZDyM7wxhKqm2EivM5u8R9gUpu9i/5352OKKpMqpbyb+CqzO/Xnrt96JpWj88MNiJRfunwvN
hgsXresFUWF+I4z4SxajkVFmPXeJCSsEx2N/a7kp4z+g+IjGesMdrwAAAABJRU5ErkJggg==
__template/tt2/edit_see_locked_button_icon.html__
<!-- BEGIN edit_see_locked_button_icon.html -->
Locked
<!-- END edit_see_locked_button_icon.html -->

__template/tt2/edit_see_start_content.html__
<!-- BEGIN edit_see_start_content.html -->
<p>
The page will be shared in SubEthaEdit within a few seconds.
</p>
<ul>
    <li><a href="[% see_url %]"><strong>Launch SubEthaEdit</strong></a></li>
</ul>
<p>
Go back to <a href="index.cgi?[% page_uri %]">[% page_name %]</a>.
</p>
<!-- END edit_see_start_content.html -->

__icons/gnome/template/edit_see_locked_button_icon.html__
<!-- BEGIN edit_see_locked_button_icon.html -->
<img src="icons/gnome/image/edit_see_locked.png" alt="Locked" />
<!-- END edit_see_locked_button_icon.html -->

__icons/gnome/image/edit_see_locked.png__
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQBAMAAADt3eJSAAAABGdBTUEAALGPC/xhBQAAACpQTFRF
////WFhYMDAwoKCgAAAAw8PDgIAAwMAA3Nzc/////9yogICAQEAAQAAAoh/d5QAAAAF0Uk5TQDY6
mfYAAAABYktHRACIBR1IAAAACXBIWXMAAAsLAAALCwFtBIS3AAAAB3RJTUUH0AkcAS8jeIwf8QAA
AGBJREFUeJxjYGBgEBRkAAPGZmMFMENUSNEQzBBWYNwEZkjDGIIOjFvAapVUziiBVIslh7aWiYAY
q8rT00AMtVnlZWCG6ozWYGMoIxTMcIaJuAIZZiCGG0wXi84hpUsODAAocBffVy0YyAAAAABJRU5E
rkJggg==
