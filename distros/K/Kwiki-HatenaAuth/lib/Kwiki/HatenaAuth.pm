package Kwiki::HatenaAuth;
use strict;
use Hatena::API::Auth;
use URI::Escape qw(uri_escape_utf8);

use Kwiki::UserName '-Base';
use mixin 'Kwiki::Installer';

our $VERSION = '0.04';

const class_id => 'user_name';
const class_title => 'Kwiki with HatenaAuth authentication';
const css_file => 'user_name.css';
const cgi_class => 'Kwiki::HatenaAuth::CGI';

field -package => 'Kwiki::PageMeta', 'edit_by_icon';

sub register {
    my $registry = shift;
    $registry->add(preload => 'user_name');
    $registry->add(action  => "return_hatenaauth");
    $registry->add(action  => "logout_hatenaauth");
    $registry->add(hook    => "page_metadata:sort_order", post => 'sort_order_hook');
    $registry->add(hook    => "page_metadata:update", post => 'update_hook');
}

sub sort_order_hook {
    my $hook = pop;
    return $hook->returned, 'edit_by_icon';
}

sub update_hook {
    return unless ref($self->hub->users->current) eq 'Kwiki::HatenaAuth';
    my $meta = $self->hub->pages->current->metadata;
    $meta->edit_by_icon($self->hub->users->current->thumbnail_url);
}

sub return_hatenaauth {
    my %input = map { ($_ => scalar $self->cgi->$_) } qw(cert);
    my $user = $self->hatena_api_auth->login($input{cert});
    if ($user) {
        my %cookie = map { ($_ => scalar $user->$_) } qw(name image_url thumbnail_url);
        $self->hub->cookie->write(hatenaauth => \%cookie);
    }
    $self->redirect('?' . uri_escape_utf8($self->cgi->page_name));
}

sub logout_hatenaauth {
    $self->hub->cookie->write(hatenaauth => {}, { -expires => "-3d" });
    $self->render_screen(content_pane => 'logout_hatenaauth.html');
}

sub hatena_api_auth {
    Hatena::API::Auth->new({
        api_key => $self->hub->config->hatenaauth_key,
        secret  => $self->hub->config->hatenaauth_secret,
    });
}
sub uri_to_login {
    my $page_name = $self->hub->cgi->page_name;
    utf8::encode($page_name) if utf8::is_utf8($page_name);
    $self->hatena_api_auth->uri_to_login( page_name => $page_name )->as_string;
}

package Kwiki::HatenaAuth::CGI;
use Kwiki::CGI '-Base';

cgi 'cert';
cgi 'page_name';

package Kwiki::HatenaAuth;

1;

__DATA__

=head1 NAME

Kwiki::HatenaAuth - Kwiki HatenaAuth integration

=head1 SYNOPSIS

  > $EDITOR plugins
  # Kwiki::UserName <- If you use it, comment it out
  Kwiki::HatenaAuth
  Kwiki::Edit::HatenaAuthRequired <- Optional: If you don't allow anonymous writes
  > $EDITOR config.yaml
  users_class: Kwiki::Users::HatenaAuth
  hatenaauth_key: PUT YOUR KEY HERE
  hatenaauth_secret: PUT YOUR SECRET KEY HEAR
  > kwiki -update

=head1 DESCRIPTION

Kwiki::HatenaAuth is a Kwiki User Authentication module to use HatenaAuth
authentication. You need a valid HatenaAuth API KEY registered at http://auth.hatena.ne.jp/

CallBack URL is 'BASE_URL'?action=return_hatenaauth

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

inspired by L<Kwiki::TypeKey>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Hatena::API::Auth> L<Kwiki::Edit::RequireUserName> L<Kwiki::Users::Remote>

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
(You are <a href="http://www.hatena.ne.jp/user?userid=[% hub.users.current.name %]/">[% hub.users.current.name | html %]</a>: <a href="[% script_name %]?action=logout_hatenaauth">Logout</a>)
[%- ELSE -%]
(Not Logged In: <a href="[% hub.load_class('user_name').uri_to_login %]">Login via HatenaAuth</a>)
[%- END %]
</em>
</div>
<!-- END user_name_title.html -->
__template/tt2/logout_hatenaauth.html__
<!-- BEGIN logout_hatenaauth.html -->
<p>You've now successfully logged out.</p>
<!-- END logout_hatenaauth.html -->
__template/tt2/recent_changes_content.html__
<table class="recent_changes">
[% FOR page = pages %]
[% SET username = page.metadata.edit_by;
   SET icon = page.metadata.edit_by_icon %]
<tr>
    <td class="page_name">[% page.kwiki_link %]</td>
    <td class="edit_by_icon" style="text-align: right">[% IF icon %]<img class="edit-by-icon" src="[% icon %]" width="16" height="16" style="vertical-align:middle" align="right" />[% END %]</td>
    <td class="edit_by_left"><a href="http://www.hatena.ne.jp/user?userid=[% username %]">[% username %]</a></td>
    <td class="edit_time">[% page.edit_time %]</td>
</tr>
[% END %]
</table>
__template/tt2/search_content.html__
<!-- BEGIN search_content -->
<table class="search">
[% FOR page = pages %]
[% SET username = page.metadata.edit_by;
   SET icon = page.metadata.edit_by_icon %]
<tr>
    <td class="page_name">[% page.kwiki_link %]</td>
    <td class="edit_by_icon" style="text-align: right">[% IF icon %]<img class="edit-by-icon" src="[% icon %]" width="16" height="16" style="vertical-align:middle" align="right" />[% END %]</td>
    <td class="edit_by_left"><a href="http://www.hatena.ne.jp/user?userid=[% username %]">[% username %]</a></td>
    <td class="edit_time">[% page.edit_time %]</td>
</tr>
[% END %]
</table>
<!-- END search_content -->
__template/tt2/list_pages_content.html__
[% BLOCK nav_block %]
<center>
[% FOREACH letter IN pages %]
   [% IF letter.value.size > 0 %]
    <big><a href="#[% letter.key %]">[% letter.key %]</a></big>
   [% END %]
[% END %]
[% END %]
</center>
[% PROCESS nav_block %]
<table class="list_pages">
[% FOREACH letter IN pages %]
 [% IF letter.value.size > 0 %]
 <tr>
 <td class="header" colspan="4"><a name="[%letter.key%]">[% letter.key %]</a></td>
 </tr>
   [% FOREACH page = letter.value %]
   [% SET username = page.metadata.edit_by;
      SET icon = page.metadata.edit_by_icon %]
       <tr>
       <td class="page_name">[% page.kwiki_link %]</td>
       <td class="edit_by_icon" style="text-align: right">[% IF icon %]<img class="edit-by-icon" src="[% icon %]" width="16" height="16" style="vertical-align:middle" align="right" />[% END %]</td>
       <td class="edit_by_left"><a href="http://www.hatena.ne.jp/user?userid=[% username %]">[% username %]</a></td>
       <td class="edit_time">[% page.edit_time %]</td>
       </tr>
   [% END %]
   <tr><td>&nbsp;</tr>
 [% END %]
[% END %]
</table>
<p>
[% PROCESS nav_block %]
<!-- END list_pages_content -->
__template/tt2/display_changed_by.html__
<!-- BEGIN display_changed_by -->
[% IF self.preferences.display_changed_by.value %]
[% page = hub.pages.current %]
[% SET username = page.metadata.edit_by;
   SET icon = page.metadata.edit_by_icon %]
<div style="background-color: #eee">
<em>
Last changed by <a href="http://www.hatena.ne.jp/user?userid=[% username %]">[% IF icon %]<img src="[% icon %]" border="0" width="16" height="16" />[% END %] [% username %]</a> at [% page.edit_time %]
</em>
</div>
[% END %]
<!-- END display_changed_by -->
__theme/basic/template/tt2/theme_title_pane.html__
<div id="title_pane">
  <h1>
[% IF hub.users.current.image_url %]<a href="[% script_name %]?"><img src="[% hub.users.current.image_url %]" height="36" style="vertical-align: middle; border: 0" /></a>[% END -%]
  [% screen_title || self.class_title %]
  </h1>
</div>
__config/hatenaauth.yaml__
hatenaauth_key: PUT YOUR KEY HERE
hatenaauth_secret: PUT YOUR SECRET KEY HEAR
