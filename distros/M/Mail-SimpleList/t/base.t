#! perl -T

use strict;
use warnings;

use File::Copy;
use Mail::Header;
use Mail::Action::Request;

use Test::More tests => 113;
use Test::Exception;
use Test::MockObject;

my $mock    = Test::MockObject->new();
$mock->fake_module( 'Mail::Mailer',           new => sub { $mock }    );

use_ok( 'Mail::SimpleList' ) or exit;
can_ok( 'Mail::SimpleList', 'new' );

my $request = Mail::Action::Request->new( <<END_MESSAGE );
Subject: *Foo*
From: me\@here
To: you\@there

END_MESSAGE

my $ml = Mail::SimpleList->new( 'aliases', Request => $request );

isa_ok( $ml,            'Mail::SimpleList'  );
{
	# AUTOLOAD() will not be called if UNIVERSAL has our isa()

	isa_ok( $ml->request(),   'Mail::Action::Request' );
}
isa_ok( $ml->storage(), 'Mail::SimpleList::Aliases' );

$mock->set_always( storage => $mock    );

can_ok( $ml, 'parse_alias' );
my $result;

can_ok( $ml, 'find_command' );
$request->store_header( 'Subject', [''] );

ok(! $ml->find_command(), 'find_command() should return false lacking subject');

$request->store_header( 'Subject', [ '*FOO*' ] );
ok(! $ml->find_command(), '... or invalid command' );

for my $command (qw( help new unsubscribe ))
{
	$request->store_header( 'Subject', [ '*' . uc( $command) . '*' ] );
	$result = $ml->find_command();
	ok( $result, "... but true for valid command '$command'" );
	is( $result, "command_$command", '... with proper method name' );
}

can_ok( $ml, 'process' );
my $process = \&Mail::SimpleList::process;
$mock->set_series( find_command => 0, 'command_foo' )
	 ->set_true( 'command_foo' )
	 ->set_series( handle_command => 0, 1 )
	 ->set_series( fetch_address => 0, 0, 1 )
	 ->set_true( 'reject' )
	 ->set_true( 'deliver' )
	 ->clear();

$request->store_header( 'X-MSL-Seen', [ 1 ] );

$mock->set_always( request => $request );
$result = $ml->$process();
ok( ! $result,                'process() should return if in a mail loop' );

$request->store_header( 'X-MSL-Seen', [ 0 ] );

my ($method, $args);
$mock->$process();
is( $mock->next_call( 2 ), 'find_command','...otherwise checking for command' );
$method = $mock->next_call();
isnt( $method, 'command_foo',             '... not calling it if absent' );

$mock->clear();
$result = $mock->$process();
$method = $mock->next_call( 3 );
is( $method, 'command_foo',               '... but calling it if it is' );

$mock->clear();
$result = $mock->$process();
is( $mock->next_call( 3 ), 'fetch_address', '... looking for alias' );
$method = $mock->next_call();
is( $method, 'reject',                    '... rejecting with no valid alias' );

$mock->clear();
$result = $mock->$process();

is( $mock->next_call( 4 ), 'deliver',     '... delivering if alias is okay' );

can_ok( $ml, 'deliver' );

my $body = [];
$request = Mail::Action::Request->new( <<'END_MESSAGE' );
To: to@home
From: from@home
Subject: Simple explanation
Cc: nonsml@host
Delivered-To: to@home

Longer explanation.
END_MESSAGE

$ml = Mail::SimpleList->new( 'aliases', Request => $request );

$mock->set_true( 'open' )
	 ->set_true( 'close' )
	 ->set_always( members => [qw( foo bar baz )] )
	 ->set_series( expires => 100, time() + 100, 0 )
	 ->mock( print => sub { @$body = @_ } )
	 ->set_always( request => $request )
	 ->clear();

my $mock_alias = Test::MockObject->new()
	->set_always( members => [qw( baz bar foo )] )
	->set_series( 'auto_add'  => 1, 0      )
	->set_always( description => undef     )
	->set_always( name        => 'my name' )
	->set_true( 'add' );

my @ata;
{
	local (*Mail::SimpleList::add_to_alias, *Mail::SimpleList::can_deliver);
	*Mail::SimpleList::add_to_alias  = sub { push @ata, [ @_ ] };

	my $cd;
	*Mail::SimpleList::can_deliver   = sub {
		my ($self, $alias, $message) = @_;
		unless ($cd++)
		{
			$request = Mail::Action::Request->new( <<'END_MESSAGE' );
To: from@home
From: to@home
Delivered-To: from@home
Subject: Simple explanation

Some message.
END_MESSAGE
			$message->{Body} = 'Longer explanation.';
			$ml->{Request}   = $request;
		}
		return $cd > 1;
	};
	$result = $ml->deliver( $mock_alias );
	ok( $cd,                  'deliver() should check deliverability' );
	ok( ! $result,            '... returning false if it cannot be delivered' );

 	my ($method, $args) = $mock->next_call();
	is( $method, 'open',                           '... opening message' );
	like( $args->[1]{To},    qr/\bfrom\@home\b/,   '... to sender' );
	is( $args->[1]{Subject}, 'Simple explanation', '... with failure subject' );

	($method, $args) = $mock->next_call();
	is( $method,    'print',                       '... printing message' );
	is( $args->[1], 'Longer explanation.',         '... about failure' );

	$mock->clear();
	$request = Mail::Action::Request->new( <<'END_MESSAGE' );
To: to@host, <sml@snafu>
From: from@home
Cc: nonsml@host
Subject: some message
Delivered-To: to@host

body
END_MESSAGE

	$ml              = Mail::SimpleList->new( 'aliases', Request => $request );

	my $mock_aliases = Test::MockObject->new();
	{
		local *Mail::SimpleList::storage;
		*Mail::SimpleList::storage = sub { $mock_aliases };
		$mock_aliases->set_true( 'save' );
		$result = $ml->deliver( $mock_alias );
	}
	ok( $result,              '... true otherwise' );
	($method, $args) = $mock_aliases->next_call();
	is( $method, 'save',      '... saving alias' );

	# now try it without auto-add
	$result = $ml->deliver( $mock_alias );

	# and with alias description
	$mock_alias->set_always( description => 'this is my list' );
	$result = $ml->deliver( $mock_alias );
}

like( "@$body", qr/\n-- \nTo unsubscribe:/, '... adding unsubscribe message' );

($method, $args) = $mock->next_call();
is( $method, 'open',                        '... opening message' );
is_deeply( $args->[1]{Bcc},
	[qw( baz bar foo )],                    '... blind cc-ing list recipients');
is( "@{ $ata[0] }", "$ml $mock_alias sml\@snafu nonsml\@host",
                                            '... adding copied addys to list');

is( $args->[1]{'List-Id'},
	'<my name.list-id.host>',               '... setting list id without desc');

($method, $args) = $mock->next_call( 6 );
is( @ata, 1, '... not adding addresses without auto-add' );
like( $args->[1]{Cc}, qr/\bnonsml\@host\b/, '... keeping Cc without auto-add' );
is( $args->[1]{'List-Id'}, '"this is my list" <my name.list-id.host>',
	                                        '... setting list id with desc' );
ok( ! exists $args->[1]{'Delivered-to'}, 
	                                        '... removing Delivered-To header');

can_ok( $ml, 'reject' );
throws_ok { $ml->reject() }
	qr/Invalid alias/,                      'reject() should throw error';
cmp_ok( $!, '==', 100,                      '... setting ERRNO to REJECTED' );
throws_ok { $ml->reject( 'my explanation' ) }
	qr/my explanation/,                     '... using explanation if given';

# found in Mail::Action
can_ok( $ml, 'process_body' );
$mock_alias->set_always( 'attributes', { expires => 1 } )
	       ->set_true( 'expires' )
		   ->mock( add => sub { my $self = shift; $self->{members} = [ @_ ] } )
		   ->set_true( 'owner' )
		   ->set_true( 'description' )
	       ->clear();

$request = Mail::Action::Request->new( <<'END_MESSAGE' );
To: to@host, sml@snafu
From: from@home
Cc: nonsml@host
Subject: some message
Delivered-To: to@host

Expires: 7d

my@ddress
your@ddress
END_MESSAGE

$ml     = Mail::SimpleList->new( 'aliases', Request => $request );
$result = $ml->process_body( $mock_alias );

($method, $args) = $mock_alias->next_call( 2 );
is( $method,    'expires',   'process_body() should handle Expires directive' );
is( $args->[1], '7d',        '... setting expiration time' );

# the real add() ignores blank lines
is_deeply( $result,
	[ '', 'my@ddress', 'your@ddress' ],
	                         '... returning remaining body lines' );

can_ok( $ml, 'generate_alias' );
my $mock_aliases = Test::MockObject->new();
$mock_aliases->set_series( exists => 1, 0, 1, 0 );

{
	local $ml->{Storage} = $mock_aliases;
	my $id               = $ml->generate_alias( 123 );
	isnt( $id, 123,   'generate_alias() should generate a fresh id' );

	my $time             = sprintf '%x', reverse time();
	$id                  = $ml->generate_alias();
	ok( $id,          '... generating a new id by default' );
	isnt( $id, $time, '... even if called in the same second' );
}

can_ok( $ml, 'post_address' );
{
	$request->store_header( To => [ Email::Address->parse( 'alias@host' ) ] );

	my $post = $ml->post_address( 'foobar' );
	is( $post, 'alias+foobar@host',
		'post_address() should return postable address' );
}

can_ok( $ml, 'command_new' );
my $aliases = { 'foo@bar.com' => 1, 'baz@host' => 1 };

$mock->clear();
$request = Mail::Action::Request->new( <<END_MESSAGE );
Subject: *new*
From: xpou\@snafu.org
To: sml+21\@snafu.org
Delivered-To: sml+21\@snafu.org

@{[ join( "\n", keys %$aliases ) ]}
END_MESSAGE

$ml = Mail::SimpleList->new( 'aliases', Request => $request );

my @save;
{
	local (*Mail::SimpleList::Aliases::save, *Mail::SimpleList::notify);
	*Mail::SimpleList::Aliases::save  = sub { push @save, @_ };
	*Mail::SimpleList::notify = sub {};
	$result = $ml->command_new();
}

ok( $result,                          'command_new() should return new alias' );
my $members = [ sort @{ $result->members() } ];
is_deeply( $members, [ sort qw( xpou@snafu.org foo@bar.com baz@host ) ],
                                      '... populating alias list from body' );

($method, $args) = $mock->next_call();
is( $method, 'open',                  '... and should reply' );
is( $args->[1]{To}, 'xpou@snafu.org', '... to sender' );

($method, $args) = $mock->next_call();
my $regex = qr/Mailing list created.+Post to sml\+(.+)\@snafu/;
like( $args->[1], $regex,              '... with list address');

my ($alias_id) = $args->[1] =~ $regex;

can_ok( $ml, 'command_clone' );
$mock->clear();
$mock->set_true( 'ata' )
	 ->set_false( 'name' )
	 ->set_always( attributes => {} )
	 ->set_always( members => [qw( me you him her )] );

$mock_aliases->set_always( fetch  => $mock )
	         ->set_always( create => $mock )
	         ->set_true( 'save' )
			 ->mock( exists => sub { $_[1] eq $alias_id } )
			 ->clear();

$request = Mail::Action::Request->new( <<END_MESSAGE );
From: new\@owner
Subject: *clone* alias+$alias_id\@host
To: alias\@host

Expire: 7d
END_MESSAGE

$ml = Mail::SimpleList->new( 'aliases', Request => $request );
$mock->set_always( request => $request );

{
	local *Mail::SimpleList::add_to_alias;
	*Mail::SimpleList::add_to_alias = sub { shift; $mock->ata( @_ ) };
	local $ml->{Storage} = $mock_aliases;
	$result              = $ml->command_clone();
}

ok( $result,                      'command_clone() should create a new alias' );

($method, $args) = $mock_aliases->next_call();
is( $method, 'fetch',             '... fetching alias to clone' );
is( $args->[1], $alias_id,        '... from subject' );

($method, $args) = $mock_aliases->next_call();
is( $method, 'create',            '... creating a new alias' );
isnt( $args->[1], $alias_id,      '... not using the old id' );

($method, $args) = $mock_aliases->next_call( 3 );
is( $method, 'save',              '... saving alias' );

is_deeply( $result->members(),
	[qw( me you him her )],       '... cloning members' );
ok( $result->expires(),           '... and processing directives' );

can_ok( $ml, 'command_help' );

can_ok( $ml, 'command_unsubscribe' );

$mock->set_always( fetch_address => $mock_alias )
	 ->set_always( save => 'saved' )
	 ->set_true( 'reply' )
	 ->mock( remove_address => sub { $ml->remove_address( @_[1, 2] ) } )
	 ->clear();

$request->store_header( From => [ Email::Address->parse( 'foo@bar' ) ] );

$mock_alias->mock( remove_address => sub { return delete $_[0]->{$_[1]} });
%$mock_alias = map { $_ => 1 } qw( boo@far baz@bar quux@bar );

my $unsub = \&Mail::SimpleList::command_unsubscribe;
$unsub->( $mock );

is( $mock->next_call(),
	'fetch_address',            'command_unsubscribe() should fetch alias' );
is( keys %$mock_alias, 3,       '... removing nothing if sender not in alias' );

($method, $args) = $mock->next_call( 2 );
is( $method, 'reply',           '... replying to sender' );
is( $args->[2],
	'Unsubscribe unsuccessful for foo@bar.  Check the address.',
	                            '... with a failure message' );

$request->store_header( From => [ Email::Address->parse( 'baz@bar' ) ] );

$result = $unsub->( $mock );
ok( ! exists $mock_alias->{'baz@bar'},
	'... removing the address from the alias if the sender is in the list' );
($method, $args) = $mock->next_call( 4 );
is( $method, 'save',            '... saving alias' );
is( $args->[1], $mock_alias,    '... with the proper object' );

can_ok( $ml, 'notify' );
$mock->set_true( 'open' )
	 ->set_true( 'print' )
	 ->set_true( 'close' )
	 ->clear();

$mock_alias->set_always( owner => 'owner' )
		   ->set_series( description => 'my desc' )
	       ->clear();

$ml->notify( $mock_alias, 54321, 'foo', 'bar' );
is( $mock_alias->next_call(), 'owner',       'notify() should get owner' );
is( $mock_alias->next_call(), 'description', '... and description' );

for my $address (qw( foo bar ))
{
	($method, $args) = $mock->next_call();
	is( $method, 'open', 'notify() should open mail' );
	is_deeply( $args->[1], {
		From         => 'owner',
		To           => $address,
		'Reply-To'   => 54321,
		Subject      => 'Added to alias 54321',
		'X-MSL-Seen' => 1,
	}, '... sending from owner to address replying to list with subject');

	($method, $args) = $mock->next_call();
	is( $method, 'print',                       '... printing message body' );
	like( $args->[1],
		qr/subscribed to alias 54321 by owner/, '... a subscription message' );
	like( $args->[2], qr/my desc/,              '... and the description' );
	$mock->next_call();
}

can_ok( $ml, 'add_to_alias' );
my $alias = Mail::SimpleList::Alias->new();
$mock->set_true( 'notify' )
	 ->clear();

$result = Mail::SimpleList::add_to_alias($mock, $alias, 54321, qw(foo bar baz));
is_deeply( $alias->members(),
	[qw( foo bar baz )],         'add_to_alias() should add members to alias' );
ok( $result,                     '... returning true if members are added' );

($method, $args) = $mock->next_call();

is( $method, 'notify',           '... calling notify()' );
is_deeply( $args, [$mock, $alias, 54321, qw( foo bar baz )],
								  '... with alias, id, and added addresses' );

$result = Mail::SimpleList::add_to_alias(
	$mock, $alias, 54321, qw(foo bar baz) );
ok( ! $result,                    '... returning false with no members added' );
isnt( $mock->next_call(), 
	'notify',                     '... and not notifying then' );

can_ok( $ml, 'can_deliver' );
$mock_alias->set_series( expires => 0, 100, time() + 100 )
	       ->set_false( 'closed' )
	       ->clear();

my $message = { From => 'from', To => 'To' };

ok( $ml->can_deliver( $mock_alias, $message ),
	                    'can_deliver() should return true with no expiration' );
ok( ! $ml->can_deliver( $mock_alias, $message ),
	                    '... false if alias is expired' );
is( $message->{To},
	'from',             '... returning to sender' );
is( $message->{Subject},
	'Alias expired',    '... with an expiration subject' );
is( $message->{Body}, 'This alias has expired.',
	                    '... and body' );
ok( $ml->can_deliver( $mock_alias, $message ),
	                    '... returning true if alias is not expired' );

$mock_alias->set_false( 'expires' )
	       ->set_series( closed => 0, 1, 1 )
		   ->set_always( members => [ 'me', 'you' ] )
		   ->clear();

$message->{From} = 'me';
ok( $ml->can_deliver($mock_alias, $message ),
	                                    '... true unless alias is closed' );
ok( $ml->can_deliver( $mock_alias, $message ),
	                                    '... or if closed and sender on alias');

$message->{From} = 'she';
ok( ! $ml->can_deliver( $mock_alias, $message ),
	                                    '... false otherwise' );

is( $message->{To}, 'she', '... returning to sender' );
is( $message->{Subject}, 'Alias closed', '... a closed subject' );
is( $message->{Body}, 'This alias is closed to non-members.', '... and body' );

END
{
	1 while unlink 'new_aliases';
}
