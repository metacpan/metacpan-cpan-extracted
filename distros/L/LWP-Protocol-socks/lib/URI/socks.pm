##############################
package URI::socks;
require URI::http;
use URI::Escape;
#URI::implementor(socks => 'URI::http');
our @ISA = qw(URI::http);

# [RT 48172] Adding user/pass functionality
sub user {
    my $self = shift;

    my $userinfo = $self->userinfo();
    my($user) = split(/:/, $userinfo);
    uri_unescape($user);
}

sub pass {
    my $self = shift;

    my $userinfo = $self->userinfo();
    my(undef, $pass) = split(/:/, $userinfo);
    uri_unescape($pass);
}

1;

__END__

=head1 NAME

URI::Socks - support for socks://host:port

=head1 AUTHOR

Sheridan C Rawlins E<lt>F<sheridan.rawlins@yahoo.com>E<gt>
