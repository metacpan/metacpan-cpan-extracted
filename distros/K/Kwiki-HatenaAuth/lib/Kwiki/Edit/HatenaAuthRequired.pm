package Kwiki::Edit::HatenaAuthRequired;
use strict;
our $VERSION = 0.01;

use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';

const class_id => 'EditHatenaAuthRequired';
const class_title => 'Require HatenaAuth to edit';

sub register {
    my $registry = shift;
    $registry->add(action   => 'edit_noHatenaAuth');
    $registry->add(hook => 'edit:edit', pre => 'require_hatenaauth');
}

sub require_hatenaauth {
    my $hook = pop;
    my $req  = $self->hub->load_class('EditHatenaAuthRequired');
    my $page = $self->pages->current;
    if (! $req->have_HatenaAuth && ! $req->is_skip ) {
        my $page_uri = $page->uri;
        $hook->cancel();            # don't bother calling Kwiki::Edit::edit
        return $self->redirect("action=edit_noHatenaAuth&page_name=$page_uri");
    }
}

sub have_HatenaAuth {
    return defined $self->hub->users->current->name;
}

sub edit_noHatenaAuth {
    return $self->render_screen(
        content_pane => 'edit_noHatenaAuth.html',
    );
}

sub is_skip {
    my $pages = $self->hub->config;
    foreach (@{ $self->hub->config->hatenaauth_required_pages }) {
        return 1 if $_ eq $self->pages->current->id;
    }
    return 0;
}
1;

__DATA__

__template/tt2/edit_noHatenaAuth.html__
<!-- BEGIN edit_noHatenaAuth.html -->
<div class="error">
<p>
This web site does not allow anonymous editing.
Please <a href="[% hub.load_class('user_name').uri_to_login -%]">Login via HatenaAuth</a> first.
</p>
<p>
</p>
</div>
<!-- END edit_noHatenaAuth.html -->
__template/tt2/edit_button.html__
<!-- BEGIN edit_button.html -->
[% IF hub.pages.current.is_writable && (hub.users.current.name || hub.load_class('EditHatenaAuthRequired').is_skip) %]
[% rev_id = hub.have_plugin('revisions') ? hub.revisions.revision_id : 0 %]
<a href="[% script_name %]?action=edit&page_name=[% page_uri %][% IF rev_id %]&revision_id=[% rev_id %][% END %]" accesskey="e" title="Edit This Page">
[% INCLUDE edit_button_icon.html %]
</a>
[% END %]
<!-- END edit_button.html -->
__config/hatenaauth_required.yaml__
hatenaauth_required_pages:
- skip page name
- skip page name
