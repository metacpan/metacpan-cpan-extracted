# -*- perl -*-

# t/03_address.t - check module for address handling

use Test::Most tests => 29 + 1;
use Test::NoWarnings;

use Mail::Builder;
use Email::Address;

my ($address1,$address2,$address3,$address4,$address5,$address6);

# Address 1
ok($address1 = Mail::Builder::Address->new('test@test.com'),'Create simple object');
isa_ok ($address1, 'Mail::Builder::Address');
is ($address1->email, 'test@test.com','Check email address');
is ($address1->name, undef,'Name not set');
is ($address1->comment, undef,'Comment not set');
is ($address1->serialize, 'test@test.com','Serialize email');
ok ($address1->name('This is a Test'),'Set new name');
is ($address1->serialize, '"This is a Test" <test@test.com>','Serialize email with name');

# Address 2
ok($address2 = Mail::Builder::Address->new('test@test.com','testname'),'Create simple object');
isa_ok ($address2, 'Mail::Builder::Address');
is ($address2->email, 'test@test.com','Check email address');
is ($address2->name, 'testname','Check name');

# Address 3
ok($address3 = Mail::Builder::Address->new('test@test.com','testname','comment'),'Create simple object');
isa_ok ($address3, 'Mail::Builder::Address');
is ($address3->email, 'test@test.com','Check email address');
is ($address3->name, 'testname','Check name');
is ($address3->comment, 'comment','Check name');
is ($address3->serialize, '"testname" <test@test.com> comment','Serialize email with name');

# Address 4
ok($address4 = Mail::Builder::Address->new( email => 'test@test.com' ),'Create simple object');
isa_ok ($address4, 'Mail::Builder::Address');
is ($address4->email, 'test@test.com','Check email address');

# Broken Address 1
throws_ok { Mail::Builder::Address->new( email => 'messed.up.@-address.comx' ) } qr/is not a valid e-mail address/,'Exception ok';

# Broken Address 2
throws_ok { Mail::Builder::Address->new( email => 'valid+except @space.com' ) } qr/is not a valid e-mail address/,'Exception ok';

# Local Address 1
$Mail::Builder::TypeConstraints::EMAILVALID{fqdn} = 0;
$Mail::Builder::TypeConstraints::EMAILVALID{tldcheck} = 0;
ok($address5 = Mail::Builder::Address->new( email => 'test@localhost' ),'Create local address');
isa_ok ($address5, 'Mail::Builder::Address');
is ($address5->email, 'test@localhost','Check email address');

# From Email::Address 1
my $email_address = Email::Address->new('Justin Testing', 'test@test.com');
ok($address6 = Mail::Builder::Address->new($email_address ),'Create address from Email::Address');
isa_ok ($address6, 'Mail::Builder::Address');
is ($address6->email, 'test@test.com','Check email address');