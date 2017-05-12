package Mail::Action::RequestTest;

use strict;
use warnings;

use base 'Test::Class';

use Test::More;

sub module   { 'Mail::Action::Request' }
sub subclass { 'Mail::Action::RequestSub' }

sub default_headers
{
    return
    {
        Cc             => [],
        'Delivered-to' => [],
        From           => [ 'me@home' ],
        Subject        => [ 'Hi there' ],
        To             => [],
    };
}

sub message
{
    return <<'END_HERE';
From: me@home
To: you@house
Subject: Hi there

Hello!

Bye for now!
END_HERE
}

sub startup :Test( startup => 2 )
{
    my $self   = shift;
    my $module = $self->module();

    use_ok( $module );
    can_ok( $module, 'new' );
}

sub setup :Test( setup )
{
    my $self     = shift;
    my $module   = $self->module();
    $self->{req} = $module->new( $self->message() );
}

sub test_new :Test
{
    my $self   = shift;
    my $module = $self->module();
    isa_ok( $self->{req}, $module );
}

sub test_message :Test( 2 )
{
    my $self    = shift;
    my $message = $self->{req}->message();

    isa_ok( $message, 'Email::MIME' );
    like( $message->body_raw(), qr/Hello!.*Bye for now!/s,
        'message() should return Email::MIME containing raw message' );
}

sub test_headers :Test
{
    my $self = shift;
    is_deeply( $self->{req}->headers(), $self->default_headers(),
        'headers() should return hashref of parsed message headers' );
}

sub test_new_override_defaults :Test( 2 )
{
    my $self        = shift;
    my $module      = $self->module();
    my $headers     = $self->default_headers();
    $headers->{foo} = 'bar';

    my $req         = $module->new( $self->message(),
        headers => { foo => 'bar' });

    is_deeply( $req->headers(), $headers,
        'additional arguments to new() should augment default headers' );

    $req            = $module->new( $self->message(), recipient => 'a@b.to' );

    is_deeply( $req->recipient(), 'a@b.to',
        'additional arguments to new() should overwrite defaults' );
}

1;
