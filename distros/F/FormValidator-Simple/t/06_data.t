use strict;
use Test::More tests => 9;

BEGIN{ use_ok("FormValidator::Simple::Data") }

use CGI;

my $q = CGI->new;
$q->param('key1' => 'val1');
$q->param('key2' => 'val2');
$q->param('key3' => 'val3_1', 'val3_2' );

my $data = FormValidator::Simple::Data->new($q);
isa_ok($data, "FormValidator::Simple::Data");

my $val1 = $data->param(['key1']);
is( scalar(@$val1), 1  );
is( $val1->[0], 'val1' );

my $val2 = $data->param(['key3']);
is( $val2->[0][0], 'val3_1' );
is( $val2->[0][1], 'val3_2' );

my $val3 = $data->param(['key1','key2']);
is( scalar(@$val3), 2   );
is( $val3->[0], 'val1' );
is( $val3->[1], 'val2' );
