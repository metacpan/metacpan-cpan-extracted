# copy from Kwiki::HatenaAuth.
package Kwiki::LivedoorAuth;
use strict;
use WebService::Livedoor::Auth;
use URI::Escape qw(uri_escape_utf8);

use Kwiki::UserName '-Base';
use mixin 'Kwiki::Installer';

our $VERSION = '0.01';

const class_id => 'user_name';
const class_title => 'Kwiki with LivedoorAuth authentication';
const css_file => 'user_name.css';
const cgi_class => 'Kwiki::LivedoorAuth::CGI';

field -package => 'Kwiki::PageMeta', 'edit_by_icon';

sub register {
    my $registry = shift;
    $registry->add(preload => 'user_name');
    $registry->add(action  => "return_livedoorauth");
    $registry->add(action  => "logout_livedoorauth");
}

sub return_livedoorauth {
    my $auth  = $self->livedoor_api_auth;
    my %input = map { ($_ => scalar $self->cgi->$_) } qw(app_key userhash token t v userdata sig);
    my $user  = $auth->validate_response(\%input);
    use Data::Dumper;
    if ($user) {
        $self->hub->cookie->write(livedoorauth => { name => $auth->get_livedoor_id($user) });
    }
    $self->redirect('?' . uri_escape_utf8($self->cgi->userdata));
}

sub logout_livedoorauth {
    $self->hub->cookie->write(livedoorauth => {}, { -expires => "-3d" });
    $self->render_screen(content_pane => 'logout_livedoorauth.html');
}

sub livedoor_api_auth {
    WebService::Livedoor::Auth->new({
        app_key => $self->hub->config->livedoorauth_key,
        secret  => $self->hub->config->livedoorauth_secret,
    });
}
sub uri_to_login {
    my $page_name = $self->hub->cgi->page_name;
    utf8::encode($page_name) if utf8::is_utf8($page_name);
    $self->livedoor_api_auth->uri_to_login( perms => 'id', userdata => $page_name )->as_string;
}

package Kwiki::LivedoorAuth::CGI;
use Kwiki::CGI '-Base';

cgi 'app_key';
cgi 'userhash';
cgi 'token';
cgi 't';
cgi 'v';
cgi 'userdata';
cgi 'sig';

package Kwiki::LivedoorAuth;

1;

__DATA__

=head1 NAME

Kwiki::LivedoorAuth - Kwiki LivedoorAuth integration

=head1 SYNOPSIS

  > $EDITOR plugins
  # Kwiki::UserName <- If you use it, comment it out
  Kwiki::LivedoorAuth
  Kwiki::Edit::LivedoorAuthRequired <- Optional: If you don't allow anonymous writes
  > $EDITOR config.yaml
  users_class: Kwiki::Users::LivedoorAuth
  livedoorauth_key: PUT YOUR KEY HERE
  livedoorauth_secret: PUT YOUR SECRET KEY HEAR
  > kwiki -update

=head1 DESCRIPTION

Kwiki::LivedoorAuth is a Kwiki User Authentication module to use LivedoorAuth
authentication. You need a valid LivedoorAuth API KEY registered at L<http://auth.livedoor.com/>

CallBack URL is 'BASE_URL'?action=return_livedoorauth

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

inspired by L<Kwiki::TypeKey>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WebService::Livedoor::Auth>, L<Kwiki::Edit::RequireUserName>, L<Kwiki::Users::Remote>

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
(You are [% hub.users.current.name | html %]: <a href="[% script_name %]?action=logout_livedoorauth">Logout</a>)
[%- ELSE -%]
(Not Logged In: <a href="[% hub.load_class('user_name').uri_to_login %]">Login via LivedoorAuth</a>)
[%- END %]
</em>
</div>
<!-- END user_name_title.html -->
__template/tt2/logout_livedoorauth.html__
<!-- BEGIN logout_livedoorauth.html -->
<p>You've now successfully logged out.</p>
<!-- END logout_livedoorauth.html -->
__config/livedoorauth.yaml__
livedoorauth_key: PUT YOUR KEY HERE
livedoorauth_secret: PUT YOUR SECRET KEY HEAR
