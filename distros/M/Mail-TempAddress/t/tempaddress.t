#!/usr/bin/perl -w

BEGIN
{
    chdir 't' if -d 't';
    use lib '../lib', '../blib/lib', 'lib';
}

use strict;

use FakeIn;
use IO::File;
use Mail::Action::Request;

use Test::More tests => 97;
use Test::MockObject;
use Test::Exception;

my $mock      = Test::MockObject->new();
my $mock_in   = Test::MockObject->new();
my $mock_head = Test::MockObject->new();

$mock->fake_module( 'Mail::Mailer',   new => sub ($@) { $mock } );

my $mock_addys = Test::MockObject->new();
$mock_addys->fake_module( 'Mail::TempAddress::Addresses',
    new => sub { $mock_addys } );

my $module = 'Mail::TempAddress';
use_ok( $module ) or exit;

can_ok( $module, 'new' );
throws_ok { $module->new() } qr/No address directory provided/,
    'new() should throw error without address parameter';

my $fh  = FakeIn->new( 'From: some@guy', 'To: you@server', 'my', 'lines' );
my $mta = $module->new( 'addresses', $fh );
isa_ok( $mta, $module );

my ($method, $args) = $mock_in->next_call();
is( $mta->request->header( 'From' )->address(), 'some@guy',
    '... using data from passed-in filehandle' );

{
    local *STDIN;

    my $stdin = IO::File->new_tmpfile();
    my $pos   = $stdin->getpos();
    $stdin->print( map { "$_\n" }
        'From: another@guy', 'To: you@server', qw( my more lines ) );
    $stdin->setpos( $pos );

    *STDIN    = $stdin;
    $mta      = $module->new( 'addresses' );
}

is( $mta->request->recipient()->address(), 'you@server',
    '... or standard input without a filehandle' );

my $new_adds = bless {}, 'Mail::TempAddress::Addresses';
$mta = $module->new( 'addresses', Addresses => $new_adds, Request => ' ' );
is( $mta->storage(),
    $new_adds,           '... accepting different Address object, if given' );

my $request = Mail::Action::Request->new( "From: me\@here\nTo: you\@there\n" );
$mta        = $module->new( 'addresses', Request => $request );
is( $mta->request(),
    $request,             '... accepting different Request object, if given' );

can_ok( $module, 'storage' );
{
    local *Test::MockObject::isa;
    *Test::MockObject::isa = sub {
        my $self = shift;
        return $self->SUPER::isa( @_ ) unless $self == $mock_addys;
        return $_[0] eq 'Mail::TempAddress::Addresses';
    };

    isa_ok( $mta->storage(), 'Mail::TempAddress::Addresses',
        'addresses() should return object that' );
}

can_ok( $module, 'request' );

$mta = $module->new( 'addresses', Request => $request );

isa_ok( $mta->request(), 'Mail::Action::Request',
    'request() should return something that' );

can_ok( $module, 'message' );

isa_ok( $mta->message(), 'Email::MIME',
    'message() should return something that' );

can_ok( $module, 'find_command' );

$request->store_header( 'Subject', ['*new*'] );

my $result = $mta->find_command();
($method, $args) = $mock->next_call();

is( $result,    'command_new',
    'find_command() should return command sub name if it exists' );

$request->store_header( 'Subject', ['*foo*'] );

$result = $mta->find_command();
is( $result,    '',            '... but not if command does not' );

$request->store_header( 'Subject', ['new'] );

$result = $mta->find_command();
is( $result,    undef,         '... or if no command found' );

can_ok( $module, 'fetch_address' );

$request = Mail::Action::Request->new( <<'END_MESSAGE' );
From: me@home
To: to@address

hi
END_MESSAGE

$mta = $module->new( 'addresses', Request => $request );

$mock_addys->mock( exists => sub { $_[1] eq 'to' })
           ->set_always( fetch  => 'fetched' );

$result = $mta->fetch_address();

is( $result, 'fetched', 'fetch_address() should return fetched Address' );

$request = Mail::Action::Request->new( <<'END_MESSAGE' );
From: me@home
To: you@address
Delivered-To: bob@address

hi
END_MESSAGE

$mta = $module->new( 'addresses', Request => $request );

$result = $mta->fetch_address();
is( $result,     undef,     '... but only if address exists' );

$request = Mail::Action::Request->new( <<'END_MESSAGE' );
From: me@home
To: you@address
Delivered-To: to+your@address

hi
END_MESSAGE

$mta = $module->new( 'addresses', Request => $request );

my @result = $mta->fetch_address();
is( $result[0],  'fetched', '... returning fetched Address' );
is( $result[1],  'your',    '... and key, if key exists' );

can_ok( $module, 'deliver' );

$mock->set_true( 'open' )
     ->set_true( 'print' )
     ->set_true( 'close' )
     ->clear();

$request = Mail::Action::Request->new( <<'END_MESSAGE' );
From: from@ddress
To: to@host
Foo: bar
Subject: my subject

my
body
lines
END_MESSAGE

$mta = $module->new( 'addresses', Request => $request );

my $mock_addy = Test::MockObject->new();
$mock_addy->set_always( add_sender  => 'send_key' )
          ->set_always( owner       => 'to@ddy'   )
          ->set_always( name        => 'my_name'  )
          ->set_always( expires     => 0          )
          ->set_series( description => '', 'my desc' );

$mock_addys->set_true( 'save' )
           ->clear();

lives_ok { $mta->deliver( $mock_addy ) }
    'deliver() should throw no exception with no expiration date';

($method, $args) = $mock_addy->next_call();
is( $method,           'expires',          '... checking for expiration' );

($method, $args) = $mock_addy->next_call();
is( $method,           'add_sender',       '... adding sender to address' );
is( $args->[1],        'from@ddress',      '... using the From address' );

($method, $args) = $mock_addy->next_call();
is( $method,           'description',      '... checking for description' );

($method, $args) = $mock->next_call();
is( $method,           'open',             '... sending message' );
my %args = %{ $args->[1] };
is( $args{Subject},    'my subject',       '... preserving Subject' );
is( $args{From},       'from@ddress',      '... retaining From address' );
is( $args{To}[0],      'to@ddy',           '... setting To address properly' );
is( $args{'Reply-To'}, 'to+send_key@host', '... adding key in Reply-To header');
is( $args{Foo},        'bar',              '... preserving other headers' );

isnt( $args{'X-MTA-Description'}, 'my desc',
    '... not adding header for blank description' );

($method, $args) = $mock_addys->next_call();
is( $method,           'save',             '... saving' );
is( $args->[1],        $mock_addy,         '... address' );
is( $args->[2],        'my_name',          '... by name' );

$mock_addy->set_always( expires => time() - 500 );
throws_ok { $mta->deliver( $mock_addy ) } qr/Invalid address/,
    '... throwing exception if address has expired';

$mock->clear();
$mock_addy->set_always( expires => time() + 1000 );
lives_ok { $mta->deliver( $mock_addy ) }
    '... but not with expiration date set in future';

($method, $args) = $mock->next_call();
is( $method,           'open',             '... sending message' );
%args = %{ $args->[1] };
is( $args{'X-MTA-Description'}, 'my desc',
    '... adding header for address description' );

can_ok( $module, 'respond' );

$request = Mail::Action::Request->new( <<'END_MESSAGE' );
From: from@ddress
To: foobar@host
Foo: bar
Subject: message

my
body
text
END_MESSAGE

$mta = $module->new( 'addresses', Request => $request );

$mock_addy->set_series( get_sender => 'some@sender' )
          ->set_always( name       => 'foobar' )
          ->clear();

$mock->clear();

$mta->respond( $mock_addy, 'key' );

($method, $args) = $mock_addy->next_call();
is( $method,         'get_sender',  'respond() should get sender from Address');
is( $args->[1],      'key',         '... by key' );

($method, $args) = $mock->next_call();
%args = %{ $args->[1] };
is( $method,          'open',            '... opening a message' );
is( $args{To},        'some@sender',     '... responding to keyed sender' );
is( $args{From},      'foobar@host',     '... setting From address correctly' );
is( $args{Subject},   'message',         '... copying Subject header' );

($method, $args) = $mock->next_call();
shift @$args;
is( "@$args",         "my\nbody\ntext",  '... and adding body' );

throws_ok { $mta->respond( $mock_addy, 'nokey' ) } qr/No sender for 'nokey'/,
    '... throwing an exception unless sender is found';

can_ok( $module, 'process' );
my $process = \&Mail::TempAddress::process;
$mock->set_series( find_command  => 'command_foo', 0 )
     ->set_always( command_foo   => 'food' )
     ->set_series( fetch_address => 'addy', 0 )
     ->set_always( deliver       => 'delivered' )
     ->set_always( '-request'    => $request )
     ->set_true( 'reject' )
     ->set_true( 'respond' )
     ->clear();

$result = $process->( $mock );

($method, $args) = $mock->next_call();
is( $method, 'find_command',     'process() should look for command' );
is( $mock->next_call(),
    'command_foo',               '... calling it if present' );
is( $result, 'food',             '... returning results' );

$mock->clear();
$result = $process->( $mock );

($method, $args) = $mock->next_call( 2 );
isnt( $method,  'command_foo',   '... but not calling it if absent' );
is( $method,    'fetch_address', '... fetching address' );

($method, $args) = $mock->next_call();
is( $method,    'deliver',       '... delivering message, if address exists' );
is( $args->[1], 'addy',          '... passing address' );
is( $result,    'delivered',     '... returning result' );

$mock->clear();
$process->( $mock );

($method, $args) = $mock->next_call( 3 );
is( $method,    'reject',        '... rejecting unless address exists' );

my @addresses = (([ 'address', 'key' ]) x 2, [ 'address' ]);
$mock->mock( fetch_address => sub { @{ shift @addresses } } );

$process->( $mock );

($method, $args) = $mock->next_call( 3 );
is( $method,    'respond',       '... responding to sender if a key exists' );
is( $args->[1], 'address',       '... passing address' );
is( $args->[2], 'key',           '... and key' );

$mock->mock( respond => sub { die "Respond!\n" } )
     ->mock( deliver => sub { die "Deliver!\n" } )
     ->clear();

$process->( $mock );
($method, $args) = $mock->next_call( 4 );
is( $method,    'reject',        '... calling reject() if responding fails' );
is( $args->[1], "Respond!\n",    '... with the error message' );

$process->( $mock );
($method, $args) = $mock->next_call( 4 );
is( $method,    'reject',        '... calling reject() if delivering fails' );
is( $args->[1], "Deliver!\n",    '... with the error message' );

can_ok( $module, 'process_body' );

$request = Mail::Action::Request->new( <<'END_MESSAGE' );
From: me@here
To: you@there
Subject: who cares

foo: bar
bar: b\@z
quux: qAAx
END_MESSAGE

$mta = $module->new( 'address', Request => $request );

$mock_addy->set_always( attributes => { foo => 1, quux => 1 } )
          ->clear();

for my $att (qw( foo bar quux ))
{
    $mock_addy->mock( $att => sub
    {
        my $self      = shift;
        $self->{$att} = shift if @_;
        $self->{$att};
    });
}

$mta->process_body( $mock_addy );
is(   $mock_addy->foo(),  'bar',
    'process_body() should set directives found in message body' );
is(   $mock_addy->quux(), 'qAAx',
    '... for all directives found in body' );
isnt( $mock_addy->bar(), 'b@z',
    '... but only if they are Address directives' );

can_ok( $module, 'reply' );
{
    my $mock_mm = Test::MockObject->new();
    $mock_mm->set_always( mm_new => $mock_mm  )
            ->set_true( 'open' )
            ->set_true( 'print' )
            ->set_true( 'close' );

    local *Mail::Mailer::new;
    *Mail::Mailer::new = sub { shift; $mock_mm->mm_new( @_ ) };

    my $headers = { To => 'someone', From => 'someone else' };
    my @body    = qw( foo bar  );

    $mta->reply( $headers, @body );
    $method = $mock_mm->next_call();
    is( $method, 'mm_new',           'reply() should create new Mail::Mailer' );

    ($method, $args) = $mock_mm->next_call();
    is( $method, 'open',             '... opening a new message' );
    is_deeply( $args->[1], $headers, '... with passed headers' );

    ($method, $args) = $mock_mm->next_call();
    is( $method, 'print',            '... and printing' );
    shift @$args;
    is_deeply( $args, \@body,        '... passed body lines' );

    ($method, $args) = $mock_mm->next_call();
    is( $method, 'close',            '... and closing the message' );
}

can_ok( $module, 'command_new' );
{
    my $mock_rep = Test::MockObject->new();
    $mock_rep->set_true( 'reply' );
    local (*Mail::TempAddress::reply, *Mail::TempAddress::process_body);
    *Mail::TempAddress::reply = sub
    {
        shift;
        $mock_rep->reply( @_ );
    };

    *Mail::TempAddress::process_body = sub
    {
        shift;
        $mock->pb( @_ );
    };

    $request = Mail::Action::Request->new( <<'END_MESSAGE' );
From: from@ddress
To: to@ddress
Delivered-To: to@address
Subject: hi!

hi
END_MESSAGE

    $mta = $module->new( 'addresses', Request => $request );

    $mock->clear();

    my $mock_addy = Test::MockObject->new();
    $mock_addys->set_always( generate_address => 'generated' )
               ->set_always( create => $mock_addy )
               ->set_true( 'save' )
               ->clear();

    $mock->set_true( 'pb' );

    $mta->command_new();

    ($method, $args) = $mock_addys->next_call();
    is( $method,    'create',
        'command_new() should create a new Address object' );
    is( $args->[1], 'from@ddress',      '... passing from address' );

    ($method, $args) = $mock_addys->next_call();
    is( $method,    'generate_address', '... generating a new address' );

    ($method, $args) = $mock->next_call();
    is( $method,    'pb',               '... processing body' );
    is( $args->[1], $mock_addy,         '... sending new Address object' );

    ($method, $args) = $mock_addys->next_call();
    is( $method,    'save',             '... saving' );
    is( $args->[1], $mock_addy,         '... Address object' );
    is( $args->[2], 'generated',        '... with address name' );

    ($method, $args) = $mock_rep->next_call();
    is( $method,    'reply',            '... sending a reply' );
    is_deeply( $args->[1], {
        To      => 'from@ddress',
        From    => 'to@address',
        Subject => 'Temporary address created',
    },                                  '... with the right headers' );
    like( $args->[2], qr/A new temporary address has been created/,
                                        '... and a message body' );
    like( $args->[2],
        qr/generated\@address/,         '... and the generated address' );
}

can_ok( $module, 'reject' );
throws_ok { $mta->reject() } qr/Invalid address/,
    'reject() should throw invalid address error by default';
throws_ok { $mta->reject( 'error' ) } qr/error/,
    '... or using the provided error message';
is( $! + 0, 100, '... setting $! properly' );
