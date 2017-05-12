package Kwiki::TypeKey;
use strict;

use Kwiki::UserName '-Base';
use mixin 'Kwiki::Installer';

our $VERSION = 0.08;

const class_id => 'user_name';
const class_title => 'Kwiki with TypeKey authentication';
const css_file => 'user_name.css';
const cgi_class => 'Kwiki::TypeKey::CGI';

field -package => 'Kwiki::PageMeta', 'edit_by_icon';

sub register {
    my $registry = shift;
    $registry->add(preload => 'user_name');
    $registry->add(action  => "return_typekey");
    $registry->add(action  => "logout_typekey");
    $registry->add(hook    => "page_metadata:sort_order", post => 'sort_order_hook');
    $registry->add(hook    => "page_metadata:update", post => 'update_hook');
}

sub sort_order_hook {
    my $hook = pop;
    return $hook->returned, 'edit_by_icon';
}

sub update_hook {
    my $meta = $self->hub->pages->current->metadata;
    $meta->edit_by_icon($self->hub->users->current->icon);
}

sub return_typekey {
    my %cookie = map { ($_ => scalar $self->cgi->$_) } qw(email name nick ts sig);
    $cookie{icon} = $self->fetch_icon($cookie{name});
    $self->hub->cookie->write(typekey => \%cookie);
    $self->redirect("?" . $self->cgi->page);
}

sub fetch_icon {
    my $name = shift;

    # WWW::Blog::Metadata is slow. Go easy with regexp.
    my $ua = LWP::UserAgent->new;
    my $res = $ua->get("http://profile.typekey.com/$name/");
    if ($res->is_success) {
        return ($res->content =~ m!<div class="photo">\n\s*<img src="(.*?)"!s)[0];
    }
    return;
}

sub logout_typekey {
    $self->hub->cookie->write(typekey => {}, { -expires => "-3d" });
    $self->render_screen(content_pane => 'logout_typekey.html');
}

package Kwiki::TypeKey::CGI;
use Kwiki::CGI '-Base';

cgi 'email';
cgi 'name';
cgi 'nick';
cgi 'ts';
cgi 'sig';
cgi 'page';

package Kwiki::TypeKey;

1;

__DATA__

=head1 NAME

Kwiki::TypeKey - Kwiki TypeKey integration

=head1 SYNOPSIS

  > $EDITOR plugins
  # Kwiki::UserName <- If you use it, comment it out
  Kwiki::TypeKey
  Kwiki::Edit::TypeKeyRequired <- Optional: If you don't allow anonymous writes
  > $EDITOR config.yaml
  users_class: Kwiki::Users::TypeKey
  tk_token:    YOUR_TYPEKEY_TOKEN
  script_name: http://www.example.com/kwiki/index.cgi <- needs absURI
  > kwiki -update

=head1 DESCRIPTION

Kwiki::TypeKey is a Kwiki User Authentication module to use TypeKey
authentication. You need a valid TypeKey token registered at http://www.typekey.com/

=head1 TODO

=over 4

=item *

Now this plugin stores TypeKey response query to cookie store and verifies the data in every request to avoid spoofed cookie. It means every time it issues GET request to TypeKey servers (with If-Modified-Since) and do some crypto calculation, which should be avoided. We need a patch for Authen::TypeKey.

=item *

Integration with C<edit_by> link: (e.g. Kwiki::RecentChanges)

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Authen::TypeKey> L<Kwiki::Edit::RequireUserName> L<Kwiki::Users::Remote>

=cut

__css/user_name.css__
div #user_name_title {
  font-size: small;
  float: right;
}
__template/tt2/user_name_title.html__
<!-- BEGIN user_name_title.html -->
<div id="user_name_title">
<em>[% IF hub.users.current.name -%]
(You are <a href="http://profile.typekey.com/[% hub.users.current.name %]/">[% hub.users.current.nick | html %]</a>: <a href="[% script_name %]?action=logout_typekey">Logout</a>)
[%- ELSE -%]
[%- USE tk = url("https://www.typekey.com/t/typekey/login") -%]
(Not Logged In: <a href="[% back = script_name _ "?action=return_typekey&page=" _ hub.cgi.page_name; tk(t=tk_token, v="1.1", _return=back, need_email=0) %]">Login via TypeKey</a>)
[%- END %]
</em>
</div>
<!-- END user_name_title.html -->
__template/tt2/logout_typekey.html__
<!-- BEGIN logout_typekey.html -->
<p>You've now successfully logged out.</p>
<!-- END logout_typekey.html -->
__template/tt2/recent_changes_content.html__
<table class="recent_changes">
[% FOR page = pages %]
[% SET tk_username = page.metadata.edit_by;
   SET tk_icon = page.metadata.edit_by_icon %]
<tr>
    <td class="page_name">[% page.kwiki_link %]</td>
    <td class="edit_by_icon" style="text-align: right">[% IF tk_icon %]<img class="edit-by-icon" src="[% tk_icon %]" height="24" style="vertical-align:middle" align="right" />[% END %]</td>
    <td class="edit_by_left"><a href="http://profile.typekey.com/[% tk_username %]/">[% tk_username %]</a></td>
    <td class="edit_time">[% page.edit_time %]</td>
</tr>
[% END %]
</table>
__theme/basic/template/tt2/theme_title_pane.html__
<div id="title_pane">
  <h1>
[% IF hub.users.current.icon %]<a href="[% script_name %]?"><img src="[% hub.users.current.icon %]" height="36" style="vertical-align: middle; border: 0" /></a>[% END -%]
  [% screen_title || self.class_title %]
  </h1>
</div>
