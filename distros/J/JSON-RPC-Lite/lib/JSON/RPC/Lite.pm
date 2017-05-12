package JSON::RPC::Lite;
use strict;
use warnings;

use version; our $VERSION = version->declare("v1.0.0");

use JSON::RPC::Spec;
use Plack::Request;

sub import {
    my $pkg    = caller(0);
    my $rpc    = JSON::RPC::Spec->new;
    my $method = sub ($$) {
        $rpc->register(@_);
    };
    no strict 'refs';
    *{"${pkg}::method"}      = $method;
    *{"${pkg}::as_psgi_app"} = sub {
        return sub {
            my $req    = Plack::Request->new(@_);
            my $body   = $rpc->parse($req->content);
            my $header = ['Content-Type' => 'application/json'];
            if (length $body) {
                return [200, $header, [$body]];
            }
            return [204, [], []];
        };
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC::Lite - Simple Syntax JSON RPC 2.0 Server Implementation

=head1 SYNOPSIS

    # app.psgi
    use JSON::RPC::Lite;
    method 'echo' => sub {
        return $_[0];
    };
    method 'empty' => sub {''};
    as_psgi_app;

    # run
    $ plackup app.psgi

=head1 DESCRIPTION

JSON::RPC::Lite is sinatra-ish style JSON RPC 2.0 Server Implementation.

=head1 FUNCTIONS

=head2 method

    method 'method_name1' => sub { ... };
    method 'method_name2' => sub { ... };

register method

=head2 as_psgi_app

    as_psgi_app;

run as PSGI app.

=head1 LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

nqounet E<lt>mail@nqou.netE<gt>

=cut
