package Kwiki::Edit::TypeKeyRequired;
use strict;
our $VERSION = 0.05;

use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';

const class_id => 'EditTypeKeyRequired';
const class_title => 'Require TypeKey to edit';

sub register {
    my $registry = shift;
    $registry->add(action   => 'edit_noTypeKey');
    $registry->add(hook => 'edit:edit', pre => 'require_typekey');
}

sub require_typekey {
    my $hook = pop;
    my $req  = $self->hub->load_class('EditTypeKeyRequired');
    my $page = $self->pages->current;
    if (! $req->have_TypeKey) {
	my $page_uri = $page->uri;
	$hook->cancel();            # don't bother calling Kwiki::Edit::edit
	return $self->redirect("action=edit_noTypeKey&page_name=$page_uri");
    }
}

sub have_TypeKey {
    return defined $self->hub->users->current->name;
}

sub edit_noTypeKey {
    return $self->render_screen(
        content_pane => 'edit_noTypeKey.html',
    );
}

1;

__DATA__

__template/tt2/edit_noTypeKey.html__
<!-- BEGIN edit_noTypeKey.html -->
<div class="error">
<p>
This web site does not allow anonymous editing.
[%- USE tk = url("https://www.typekey.com/t/typekey/login") %]
Please <a href="[% back = script_name _ "?action=return_typekey&page=" _ hub.cgi.page_name; tk(t=tk_token, v="1.1", _return=back, need_email=0) %]">Login via TypeKey</a> first.
</p>
<p>
</p>
</div>
<!-- END edit_noTypeKey.html -->
__template/tt2/edit_button.html__
<!-- BEGIN edit_button.html -->
[% IF hub.pages.current.is_writable %]
[% rev_id = hub.have_plugin('revisions') ? hub.revisions.revision_id : 0 %]
<a href="[% script_name %]?action=edit&page_name=[% page_uri %][% IF rev_id %]&r
evision_id=[% rev_id %][% END %]" accesskey="e" title="Edit This Page">
[% INCLUDE edit_button_icon.html %]
</a>
[% END %]
<!-- END edit_button.html -->
