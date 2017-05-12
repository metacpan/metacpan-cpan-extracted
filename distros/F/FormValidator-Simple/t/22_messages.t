use strict;
use Test::More tests => 25;
BEGIN{ use_ok("FormValidator::Simple") }
use CGI;

my $data = {
    DEFAULT => {
        data4 => {
            DEFAULT => 'input data4',    
        },
    },
    test => {
        data1 => {
            NOT_BLANK => 'input data1',
            INT       => 'input integer for data1',
            LENGTH    => 'data1 has wrong length',
        },
        data2 => {
            DEFAULT => 'default error for data2',
        },
        data3 => {
            NOT_BLANK => 'input data3',
        },
    },
};

FormValidator::Simple->set_messages( $data );

my $q = CGI->new;
$q->param( data1 => 'hoge' );
$q->param( data2 => '123'  );
$q->param( data3 => ''     );
$q->param( data4 => ''     );

my $r = FormValidator::Simple->check( $q => [
    data1 => [qw/NOT_BLANK INT/, [qw/LENGTH 0 3/] ],
    data2 => [qw/NOT_BLANK ASCII/, [qw/LENGTH 5/]],
    data3 => [qw/NOT_BLANK/], 
    data4 => [qw/NOT_BLANK/],
] );

my $messages = $r->messages('test');
is($messages->[0], 'input integer for data1');
is($messages->[1], 'data1 has wrong length');
is($messages->[2], 'default error for data2');
is($messages->[3], 'input data3');
is($messages->[4], 'input data4');

# check that messages on object don't trash class messages
my $fvs = FormValidator::Simple->new;

is_deeply(FormValidator::Simple->messages->{_data}, $data);

# set your own
my $objdata = {
  object => {
    object1 => {
      NOT_BLANK => 'not blank for object1',
    },
    object2 => {
      LENGTH => 'length wrong for object2',
    },
  }
};

# object has its messages
$fvs->set_messages( $objdata );
is_deeply($fvs->messages->{_data}, $objdata);

# class should be int tact
is_deeply(FormValidator::Simple->messages->{_data}, $data);

my $oq = CGI->new;
$oq->param( object1 => ''       );
$oq->param( object2 => 'abcdef' );

my $or = $fvs->check( $oq => [
    object1 => [ [qw/NOT_BLANK/] ],
    object2 => [ [qw/LENGTH 1 2/] ],
] );

my $omessages = $or->messages('object');
is($omessages->[0], 'not blank for object1');
is($omessages->[1], 'length wrong for object2');

my $field_messages = $or->field_messages('object');
is(scalar @{ $field_messages->{object1} }, 1);
is(scalar @{ $field_messages->{object2} }, 1);
is($field_messages->{object1}[0], 'not blank for object1');
is($field_messages->{object2}[0], 'length wrong for object2');

# make sure the class version still works:
my $nr = FormValidator::Simple->check( $q => [
  data1 => [qw/NOT_BLANK INT/, [qw/LENGTH 0 3/] ],
  data2 => [qw/NOT_BLANK ASCII/, [qw/LENGTH 5/] ],
  data3 => [qw/NOT_BLANK/],
  data4 => [qw/NOT_BLANK/],
] );

my $nmessages = $nr->messages('test');
is($nmessages->[0], 'input integer for data1');
is($nmessages->[1], 'data1 has wrong length');
is($nmessages->[2], 'default error for data2');
is($nmessages->[3], 'input data3');
is($nmessages->[4], 'input data4');

my $nfmessages = $nr->field_messages('test');
is($nfmessages->{data1}[0], 'input integer for data1');
is($nfmessages->{data1}[1], 'data1 has wrong length');
is($nfmessages->{data2}[0], 'default error for data2');
is($nfmessages->{data3}[0], 'input data3');
is($nfmessages->{data4}[0], 'input data4');

