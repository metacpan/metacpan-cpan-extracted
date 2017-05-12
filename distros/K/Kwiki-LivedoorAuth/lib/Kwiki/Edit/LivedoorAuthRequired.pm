package Kwiki::Edit::LivedoorAuthRequired;
use strict;
our $VERSION = 0.01;

use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';

const class_id => 'EditLivedoorAuthRequired';
const class_title => 'Require LivedoorAuth to edit';

sub register {
    my $registry = shift;
    $registry->add(action   => 'edit_noLivedoorAuth');
    $registry->add(hook => 'edit:edit', pre => 'require_livedoorauth');
}

sub require_livedoorauth {
    my $hook = pop;
    my $req  = $self->hub->load_class('EditLivedoorAuthRequired');
    my $page = $self->pages->current;
    if (! $req->have_LivedoorAuth && ! $req->is_skip ) {
        my $page_uri = $page->uri;
        $hook->cancel();            # don't bother calling Kwiki::Edit::edit
        return $self->redirect("action=edit_noLivedoorAuth&page_name=$page_uri");
    }
}

sub have_LivedoorAuth {
    return defined $self->hub->users->current->name;
}

sub edit_noLivedoorAuth {
    return $self->render_screen(
        content_pane => 'edit_noLivedoorAuth.html',
    );
}

sub is_skip {
    my $pages = $self->hub->config;
    return $pages->can('livedoorauth_required_pages');
    foreach (@{ $pages->livedoorauth_required_pages }) {
        return 1 if $_ eq $self->pages->current->id;
    }
    return 0;
}
1;

__DATA__

__template/tt2/edit_noLivedoorAuth.html__
<!-- BEGIN edit_noLivedoorAuth.html -->
<div class="error">
<p>
This web site does not allow anonymous editing.
Please <a href="[% hub.load_class('user_name').uri_to_login -%]">Login via LivedoorAuth</a> first.
</p>
<p>
</p>
</div>
<!-- END edit_noLivedoorAuth.html -->
__template/tt2/edit_button.html__
<!-- BEGIN edit_button.html -->
[% IF hub.pages.current.is_writable && (hub.users.current.name || hub.load_class('EditLivedoorAuthRequired').is_skip) %]
[% rev_id = hub.have_plugin('revisions') ? hub.revisions.revision_id : 0 %]
<a href="[% script_name %]?action=edit&page_name=[% page_uri %][% IF rev_id %]&revision_id=[% rev_id %][% END %]" accesskey="e" title="Edit This Page">
[% INCLUDE edit_button_icon.html %]
</a>
[% END %]
<!-- END edit_button.html -->
__config/livedoorauth_required.yaml__
livedoorauth_required_pages:
- skip page name
- skip page name
