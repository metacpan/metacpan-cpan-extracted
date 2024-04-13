# PODNAME: Finance::Dogecoin::Utils::NodeRPC
# ABSTRACT: make authenticated RPC to a Dogecoin Core node

use Object::Pad;

use strict;
use warnings;

class Finance::Dogecoin::Utils::NodeRPC {
    use Mojo::UserAgent;
    use Mojo::JSON 'decode_json';

    field $ua   :param;
    field $auth :param;
    field $url  :param;

    sub BUILDARGS( $class, %args ) {
        $args{ua} //= Mojo::UserAgent->new;
        unless ($args{auth}) {
            if ($args{user} && $args{password}) {
                $args{auth} = "$args{user}:$args{password}";
            } elsif ($args{user} && $args{auth_file}) {
                my $auth = decode_json( $args{auth_file}->slurp_utf8 );
                $args{password} = $auth->{$args{user}} if exists $auth->{$args{user}};
            }
        }

        $args{auth}  = "$args{user}:$args{password}";
        $args{url} //= 'http://localhost:22555';

        return %args;
    }

    method call_method( $method, @params ) {
        my $res = $ua->post(
            Mojo::URL->new($url)->userinfo( $auth ),
            json => { jsonrpc => '1.0', id => 'Perl RPCAuth', method => $method, params => \@params }
        )->res;

        return $res->json if $res->is_success;

        if (! defined $res->is_error) {
            warn "RPC server not available\n";
        } elsif ($res->code == 403) {
            warn "Auth to Dogecoin RPC failed\n";
        } else {
            return $res->json;
        }

        return {};
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Dogecoin::Utils::NodeRPC - make authenticated RPC to a Dogecoin Core node

=head1 VERSION

version 1.20240413.0031

=head1 SYNOPSIS

Class representing a Dogecoin Core node on which to perform RPC.

=head1 COPYRIGHT

Copyright (c) 2022-2024 chromatic

=head1 AUTHOR

chromatic

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2024 by chromatic.

This is free software, licensed under:

  The MIT (X11) License

=cut
