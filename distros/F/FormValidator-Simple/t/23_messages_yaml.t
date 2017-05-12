use strict;
use Test::More tests => 9;
BEGIN{ use_ok("FormValidator::Simple") }
use CGI;
my $conf_file = "t/conf/messages.yml";
FormValidator::Simple->set_messages($conf_file);

my $q = CGI->new;
$q->param( data1 => 'hoge' );
$q->param( data2 => '123'  );
$q->param( data3 => ''     );

my $r = FormValidator::Simple->check( $q => [
    data1 => [qw/NOT_BLANK INT/, [qw/LENGTH 0 3/] ],
    data2 => [qw/NOT_BLANK ASCII/, [qw/LENGTH 5/]],
    data3 => [qw/NOT_BLANK/], 
] );

my $messages = $r->messages('test');
is($messages->[0], 'input integer for data1');
is($messages->[1], 'data1 has wrong length');
is($messages->[2], 'default error for data2');
is($messages->[3], 'input data3');


FormValidator::Simple->set_message_format('<p>%s</p>');
my $messages2 = $r->messages('test');
is($messages2->[0], '<p>input integer for data1</p>');
is($messages2->[1], '<p>data1 has wrong length</p>');
is($messages2->[2], '<p>default error for data2</p>');
is($messages2->[3], '<p>input data3</p>');

