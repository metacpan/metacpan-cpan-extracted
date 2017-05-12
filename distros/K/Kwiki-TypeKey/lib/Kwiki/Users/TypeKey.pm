package Kwiki::Users::TypeKey;
use strict;
use Authen::TypeKey;

our $VERSION = 0.05;
use Kwiki::Users '-Base';

const class_id    => "users";
const class_title => "Kwiki users from TypeKey authentication";
const user_class  => "Kwiki::User::TypeKey";

sub init {
    $self->hub->config->add_file('typekey.yaml');
    return unless $self->is_in_cgi;
    io($self->plugin_directory)->mkdir;
}

sub current {
    return $self->{current} = shift if @_;
    return $self->{current} if defined $self->{current};
    $self->{current} = $self->new_user();
}

sub new_user {
    $self->user_class->new();
}

package Kwiki::User::TypeKey;
use base qw(Kwiki::User);
use Encode;

field 'email';
field 'name';
field 'nick';
field 'ts';
field 'icon';

sub set_user_name {
    return unless $self->is_in_cgi;
    my $name = '';
    my $cookie = $self->hub->cookie->jar->{typekey};
    $cookie && $cookie->{sig} or return;

    $self->validate_sig($cookie) or return;
    for my $key (qw(email name nick ts icon)) {
	$self->$key( decode_utf8($cookie->{$key}) ); # we need to decode it back to Unicode
    }
}

sub validate_sig {
    my $data = shift;

    # Kwiki::CGI adds utf-8 flags to all the values
    for my $key (keys %$data) {
        utf8::encode($data->{$key}) if defined $data->{$key};
    }

    require CGI;
    my $q = CGI->new({ %$data });
    my $tk = Authen::TypeKey->new();
    $tk->key_cache($self->hub->config->tk_key_cache);
    $tk->token($self->hub->config->tk_token);
    $tk->skip_expiry_check(1);
    my $res = $tk->verify($q) or warn $tk->errstr;
    $res;
}

package Kwiki::Users::TypeKey;
1;

__DATA__

__config/typekey.yaml__
tk_token: PUT YOUR TOKEN HERE
tk_key_cache: plugin/users/keycache.txt
