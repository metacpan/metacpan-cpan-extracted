package Event::RPC::AuthPasswdHash;

use strict;
use Carp;

sub get_passwd_href             { shift->{passwd_href}                  }
sub set_passwd_href             { shift->{passwd_href}          = $_[1] }

sub new {
    my $class = shift;
    my ($passwd_href) = @_;

    my $self = bless {
        passwd_href => $passwd_href,
    };
    
    return $self;
}

sub check_credentials {
    my $self = shift;
    my ($user, $pass) = @_;
    return $pass eq $self->get_passwd_href->{$user};
}

1;
