package Kwiki::Users::HatenaAuth;
use strict;

our $VERSION = 0.01;
use Kwiki::Users '-Base';

const class_id    => "users";
const class_title => "Kwiki users from HatenaAuth authentication";
const user_class  => "Kwiki::User::HatenaAuth";

sub init {
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

package Kwiki::User::HatenaAuth;
use base qw(Kwiki::User);

field 'name';
field 'image_url';
field 'thumbnail_url';

sub set_user_name {
    return unless $self->is_in_cgi;
    my $cookie = $self->hub->cookie->jar->{hatenaauth};
    $cookie && $cookie->{name} or return;
    for my $key (qw(name image_url thumbnail_url)) {
        $self->$key($cookie->{$key});
    }
}

package Kwiki::Users::HatenaAuth;
1;

__DATA__

