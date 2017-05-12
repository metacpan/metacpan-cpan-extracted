package Mail::Action::Test;

use strict;
use warnings;

use base 'Test::Class';
use Test::More;
use Test::Exception;

use IO::File;
use Email::MIME;
use Email::MIME::Modifier;
use Test::MockObject;

# subclasses M::A to set a storage class
sub module  { 'Mail::Action::WithStorage' }
sub request { 'Mail::Action::Request' }

sub startup :Test( startup => 3 )
{
    my $self      = shift;
    my $module    = $self->module();

    use_ok( 'Mail::Action' );
    use_ok( $module );
    can_ok( $module, 'new' );

    # XXX: a bit of a hack here
    Test::MockObject->fake_module( 'Mail::Mailer',
        new => sub ($@) {$self->{mail}});
}

sub setup :Test( setup )
{
    my $self      = shift;
    my $module    = $self->module();
    my $req       = $self->request()->new( $self->message() );
    $self->{ma}   = $module->new( 'dir', Request => $req );
    $self->{mail} = Test::MockObject->new();
}

sub message
{
    return <<'END_HERE';
From: me@home
To: you@house
Subject: Hi there

Hello!

Well, bye.
END_HERE

}

sub new_exception :Test
{
    my $self   = shift;
    my $module = $self->module();
    throws_ok { $module->new() } qr/No address directory provided/,
        'new() should throw exception without address directory';
}

sub new_from_text :Test( 2 )
{
    my $self   = shift;
    my $module = $self->module();
    can_ok( $module, 'message' );
    my $ma     = $module->new( 'dir', $self->message() );

    like( $ma->message->body(), qr/Hello!/,
        'new() should set messsage from string given only two arguments' );
}

sub new_from_fh: Test( 3 )
{
    my $self    = shift;
    my $module  = $self->module();
    my $message = $self->message();
    my $fh      = IO::File->new_tmpfile();
    my $pos     = $fh->getpos();

    $fh->print( $message );
    $fh->setpos( $pos );

    my $ma   = $module->new( 'dir', $fh );
    like( $ma->message->body(), qr/Hello!/,
        'new() should set message body from filehandle, given two arguments' );

    $fh->setpos( $pos );
    my %options = ( Filehandle => $fh );
    $ma   = $module->new( 'dir', %options );
    like( $ma->message->body(), qr/Hello!/,
        '... or from filehandle, when passed as Filehandle option' );

    $options{Filehandle} = $message;
    $ma   = $module->new( 'dir', %options );
    like( $ma->message->body(), qr/Hello!/,
        '... or from string, when passed as Filehandle option (yow!)' );
}

sub new_with_storage :Test( 5 )
{
    my $self    = shift;
    my $module  = $self->module();
    my %options = ( Filehandle => $self->message() );

    can_ok( $module, 'storage' );

    my $ma      = $module->new( 'dir', %options );
    like( $ma->storage(), qr/^ST:/,
        'new() should default to storage_class() storage object' );

    is( $ma->storage(), 'ST: dir', '... passing address directory' );

    $options{Addresses} = 'addresses';
    $ma    = $module->new( 'dir', %options );
    is( $ma->storage(), 'addresses', '... or Addresses option' );

    $options{Storage} = 'storage';
    $ma    = $module->new( 'dir', %options );
    is( $ma->storage(), 'storage', '... preferring Storage option' );
}

sub new_from_stdin :Test( 1 )
{
    my $self      = shift;
    my $module    = $self->module();
    my $fh        = IO::File->new_tmpfile();
    my $pos       = $fh->getpos();
    $fh->print( $self->message() );
    $fh->setpos( $pos );

    local *STDIN  = $fh;
    my $ma        = $module->new( 'dir' );
    like( $ma->message->body(), qr/Hello!/,
        'new() should read from STDIN, given only one argument' );
}

sub fetch_address :Test( 4 )
{
    my $self   = shift;
    my $module = $self->module();

    can_ok( $module, 'fetch_address' );

    my $mock_store = Test::MockObject->new()
        ->set_series( exists => 0, 1, 1 )
        ->set_always( fetch  => 'addy'  );

    my $req = $self->request()->new( $self->message() );
    my $ma  = $module->new( 'dir', Storage => $mock_store, Request => $req );

    is( $ma->fetch_address(), undef,
        'fetch_address() should return undef unless address exists' );
    is( $ma->fetch_address(), 'addy',
        '... or existing address, in scalar context' );

    is_deeply( [ $ma->fetch_address() ], [qw( addy alias )],
        '... or address and alias, in list context' );
}

sub command_help :Test( 4 )
{
    my $self      = shift;
    my $module    = $self->module();
    can_ok( $module, 'command_help' );

    my $ma        = $self->{ma};
    my $mock_mail = $self->{mail};
    $mock_mail->set_true( 'open' )
        ->set_true( 'print' )
        ->set_true( 'close' );


    my $pod =<<END_HERE;
=head1 FOO

some text

=head1 USING LISTS

more text

=head1 DIRECTIVES

Yet More Text.

=head1 CREDITS

no one of consequence
END_HERE

    $ma->request->store_header( 'From', [ Email::Address->parse( 'some@here' ) ] );
    $ma->command_help( $pod, 'USING LISTS', 'DIRECTIVES' );

    my ($method, $args) = $mock_mail->next_call();
    is( $args->[1]{To},      'some@here',
        'command_help() should reply to sender' );
    is( $args->[1]{Subject}, $self->module() . ' Help',
        '... with appropriate subject' );
    ($method, $args) = $mock_mail->next_call();
    is( $args->[1],
        "USING LISTS\n\n    more text\n\nDIRECTIVES\n\n    Yet More Text.",
        '... with text extracted from passed-in POD' );
}

sub process_body :Test( 8 )
{
    my $self   = shift;
    my $module = $self->module();
    my $ma     = $self->{ma};

    can_ok( $module, 'process_body' );

    my $mock_store = Test::MockObject->new();
    $mock_store->set_always( attributes => { foo => 1, bar => 1 } )
        ->set_true( 'foo' )
        ->set_true( 'bar' )
        ->clear();

    $ma->message->body_set(
        "Foo: foo\nCar: vroom\nbaR: b a r\n\nMy: friend\nhi\n-- \nFOO: moo"
    );

    is_deeply( $ma->process_body( $mock_store ), [ '', 'My: friend', 'hi' ],
        'process_body() should return message without directives or sig' );
    my ($method, $args) = $mock_store->next_call( 2 );
    is( $method,    'foo',   '... calling directive found' );
    is( $args->[1], 'foo',   '... passing directive value found' );
    ($method, $args)    = $mock_store->next_call();
    isnt( $method,  'car',   '... not calling unknown directive' );
    is( $method,    'bar',   '... lowercasing directive name' );
    is( $args->[1], 'b a r', '... passing entire directive value found' );

    $ma->message->body_set();
    is_deeply( $ma->process_body( $mock_store ), [],
        '... returning empty list with no body' );
}

sub reply :Test( 6 )
{
    my $self      = shift;
    my $module    = $self->module();
    my $ma        = $self->{ma};
    my $mock_mail = $self->{mail}->set_true(qw( open print close ));

    can_ok( $module, 'reply' );

    $ma->reply( 'headers', 'body', 'lines' );
    my ($method, $args) = $mock_mail->next_call();
    is( $method,    'open',    'reply() should open a Mail::Mailer object' );
    is( $args->[1], 'headers', '... passing headers' );

    ($method, $args)    = $mock_mail->next_call();
    is( $method,    'print',               '... printing body' );
    is( "@$args", "$mock_mail body lines", '... all lines passed' );
    is( $mock_mail->next_call(), 'close',  '... closing message' );
}

sub find_command :Test( 5 )
{
    my $self   = shift;
    my $module = $self->module();
    my $ma     = $self->{ma};

    can_ok( $module, 'find_command' );

    is( $ma->find_command(), undef,
        'find_command() should return undef without a valid command' );
    $ma->request->store_header( 'Subject', [ '*help*' ] );
    is( $ma->find_command(), 'command_help',
        '... or the name of the command sub, if it exists' );
    $ma->request->store_header( 'Subject', [ '*hElP*' ] );
    is( $ma->find_command(), 'command_help',
        '... regardless of capitalization' );
    $ma->request->store_header( 'Subject', [ '*drinkME*' ] );
    is( $ma->find_command(), '',
        '... or an empty string if command does not match' );
}

sub copy_headers: Test( 4 )
{
    my $self   = shift;
    my $module = $self->module();
    my $ma     = $self->{ma};
    my $req    = $ma->request();

    can_ok( $module, 'copy_headers' );

    $req->store_header( 'Subject',      [ '*help*'    ] );
    $req->store_header( 'To',           [ 'you@house' ] );
    $req->store_header( 'From',         [ 'me@home'   ] );
    $req->store_header( 'From ',        [ 1           ] );
    $req->store_header( 'Cc',           [ 1           ] );
    $req->store_header( 'Content-type', [ ''          ] );

    my $result = $ma->copy_headers();

    isnt( $result, $ma->message()->{head},
        'copy_headers() should make a new hash' );
    is_deeply( $result,
        { From => 'me@home', Subject => '*help*', To => 'you@house', Cc => 1,
        'Content-type' => '', 'Delivered-to' => '' },
        '... cleaning header names' );
    ok( ! exists $result->{'From '}, '... removing mbox From header' );
}

package Mail::Action::WithStorage;

@Mail::Action::WithStorage::ISA = 'Mail::Action';

$INC{'Mail/Action/WithStorage.pm'} = 1;
sub storage_class { 'StorageTest' }
sub parse_alias   { 'alias' }

package StorageTest;

sub new { 'ST: ' . $_[1] };

1;
