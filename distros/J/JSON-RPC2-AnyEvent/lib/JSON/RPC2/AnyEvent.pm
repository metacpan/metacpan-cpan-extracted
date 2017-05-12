package JSON::RPC2::AnyEvent;

our $VERSION = "0.02";

use JSON::RPC2::AnyEvent::Server;

1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC2::AnyEvent - Yet-another, transport-independent and asynchronous JSON-RPC 2.0 implementation

=head1 SYNOPSIS

    use JSON::RPC2::AnyEvent::Server;

    my $srv = JSON::RPC2::AnyEvent::Server->new(
        hello => "[family_name, first_name]" => sub{
            my ($cv, $args, $original_args) = @_;
            my ($family, $given) = @$args;
            do_some_async_task(sub{
                # Done!
                $cv->send("Hello, $given $family!");
            });
        }
    );
    
    my $cv = $srv->dispatch({
        jsonrpc => "2.0",
        id      => 1,
        method  => 'hello',
        params  => [qw(Sogoru Kyo)],
    });
    my $res = $cv->recv;  # { jsonrpc => "2.0", id => 1, result => "Hello, Kyo Sogoru!" }
    
    my $cv = $srv->dispatch({
        jsonrpc => "2.0",
        id      => 2,
        method  => 'hello',
        params  => {first_name => 'Ryoko', family_name => 'Kaminagi'}  # You can pass a hash as well!
    });
    my $res = $cv->recv;  # { jsonrpc => "2.0", id => 2, result => "Hello, Ryoko Kaminagi!" }

    # For Notification Request, just returns undef.
    my $cv = $srv->dispatch({
        jsonrpc => "2.0",
        method  => "hello",
        params  => ["Misaki", "Shizuno"]
    });  # notification request when "id" is omitted.
    not defined $cv;  # true


=head1 DESCRIPTION

JSON::RPC2::AnyEvent is yet-another JSON-RPC 2.0 implementation. This module is very similar to L<JSON::RPC2> and
actually shares the main goals. That is, transport independent, asynchronous, and light-weight.
However, this module is designed so that it works with L<AnyEvent>, especially with L<AnyEvent::Handle>.


=head1 THINK SIMPLE

JSON::RPC2::AnyEvent considers JSON-RPC as simple as possible. For example, L<JSON::RPC2::Server> abstracts JSON-RPC
server as a kind of hash filter. Unlike L<JSON::RPC2::Server> accepts and outputs serialized JSON text,
L<JSON::RPC2::AnyEvent::Server> accepts and outputs Perl hash:

                         +----------+
                         |          |
                Inuput   | JSON-RPC |  Output
      request ---------->|  Server  |----------> response
    (as a hash)          |          |           (as a hash)
                         +----------+

Actually, it accepts any kind of Perl data (array, hash, and scalar!), then, outputs a JSON-like hash. Response hash can
be either of successful response or error response. Anyway, it's a hash!

What you need to do is just to make or retrieve a JSON-like data structure in some way, and input it into the server,
then, get the result as a hash.

Actually, JSON::RPC2::AnyEvent just treats Perl data structures instead of JSON, and has nothing to with serializing
Perl data or deserializing JSON text. This concept allows you to use JSON-RPC on any kind of transport layer.
In particular, this way is excellent with L<AnyEvent::Handle>, such as C<$h-E<gt>push_read(json =E<gt> sub{...})> and
C<$h-E<gt>push_write(json =E<gt> ...)>.

If you are interested in a "real" solution, you should look at L<JSON::RPC2::AnyEvent::Server::Handle>, which is an
example to use this module on stream protocol like TCP.


=head1 SEE ALSO

=over

=item L<JSON::RPC2::AnyEvent::Server>

=item L<JSON::RPC2::AnyEvent::Server::Handle>

=back


=head1 LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke (yet another) Maki E<lt>maki.daisuke@gmail.comE<gt>

=cut

