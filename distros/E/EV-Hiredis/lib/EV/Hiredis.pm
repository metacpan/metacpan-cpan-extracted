package EV::Hiredis;
use strict;
use warnings;

use EV;

BEGIN {
    use XSLoader;
    our $VERSION = '0.05';
    XSLoader::load __PACKAGE__, $VERSION;
}

sub new {
    my ($class, %args) = @_;

    my $loop = $args{loop} || EV::default_loop;
    my $self = $class->_new($loop);

    $self->on_error($args{on_error} || sub { die @_ });
    $self->on_connect($args{on_connect}) if $args{on_connect};

    if (exists $args{host}) {
        $self->connect($args{host}, defined $args{port} ? $args{port} : 6379);
    }
    elsif (exists $args{path}) {
        $self->connect_unix($args{path});
    }

    $self;
}

our $AUTOLOAD;

sub AUTOLOAD {
    (my $method = $AUTOLOAD) =~ s/.*:://;

    my $sub = sub {
        my $self = shift;
        $self->command($method, @_);
    };

    no strict 'refs';
    *$method = $sub;
    goto $sub;
}

1;

=head1 NAME

EV::Hiredis - Asynchronous redis client using hiredis and EV

=head1 SYNOPSIS

    use EV::Hiredis;
    
    my $redis = EV::Hiredis->new;
    $redis->connect('127.0.0.1');
    
    # or
    my $redis = EV::Hiredis->new( host => '127.0.0.1' );
    
    # command
    $redis->set('foo' => 'bar', sub {
        my ($res, $err) = @_;
    
        print $res; # OK
    
        $redis->get('foo', sub {
            my ($res, $err) = @_;
    
            print $res; # bar
    
            $redis->disconnect;
        });
    });
    
    # start main loop
    EV::run;

=head1 DESCRIPTION

EV::Hiredis is a asynchronous client for Redis using hiredis and L<EV> as backend.

This module connected to L<EV> with C-Level interface so that it runs faster.

=head1 ANYEVENT INTEGRATION

L<AnyEvent> has a support for EV as its one of backends, so L<EV::Hiredis> can be used in your AnyEvent applications seamlessly.

=head1 NO UTF-8 SUPPORT

Unlike other redis modules, this module doesn't support utf-8 string.

This module handle all variables as bytes. You should encode your utf-8 string before passing commands like following:

    use Encode;
    
    # set $val
    $redis->set(foo => encode_utf8 $val, sub { ... });
    
    # get $val
    $redis->get(foo, sub {
        my $val = decode_utf8 $_[0];
    });

=head1 METHODS

=head2 new(%options);

Create new L<EV::Hiredis> instance.

Available C<%options> are:

=over

=item * host => 'Str'

=item * port => 'Int'

Hostname and port number of redis-server to connect.

=item * path => 'Str'

UNIX socket path to connect.

=item * on_error => $cb->($errstr)

Error callback will be called when a connection level error occurs.

This callback can be set by C<< $obj->on_error($cb) >> method any time.

=item * on_connect => $cb->()

Connection callback will be called when connection successful and completed to redis server.

This callback can be set by C<< $obj->on_connect($cb) >> method any time.

=item * loop => 'EV::loop',

EV loop for running this instance. Default is C<EV::default_loop>.

=back

All parameters are optional.

If parameters about connection (host&port or path) is not passed, you should call C<connect> or C<connect_unix> method by hand to connect to redis-server.

=head2 connect($hostname, $port)

=head2 connect_unix($path)

Connect to a redis-server for C<$hostname:$port> or C<$path>.

on_connect callback will be called if connection is successful, otherwise on_error callback is called.

=head2 command($commands..., $cb->($result, $error))

Do a redis command and return its result by callback.

    $redis->command('get', 'foo', sub {
        my ($result, $error) = @_;

        print $result; # value for key 'foo'
        print $error;  # redis error string, undef if no error
    });

If any error is occurred, C<$error> presents the error message and C<$result> is undef.
If no error, C<$error> is undef and C<$result> presents response from redis.

NOTE: Alternatively all commands can be called via AUTOLOAD interface.

    $redis->command('get', 'foo', sub { ... });

is equivalent to:

    $redis->get('foo', sub { ... });

=head2 disconnect

Disconnect from redis-server. This method is usable for exiting event loop.

=head2 on_error($cb->($errstr))

Set new error callback to the instance.

=head2 on_connect($cb->())

Set new connect callback to the instance.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013 Daisuke Murase All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
