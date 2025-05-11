use v5.36;
use Test::More;
use FU::MultipartFormData;

# Example based on https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST
my $t = <<'_' =~ s/\n/\r\n/rg;
--delimiter12345
Content-Disposition: form-data; name="field1"
content-type: hello; charset=x

value1
--delimiter12345
Content-Type: text
Content-Disposition: form-data; filename="example.txt"; name=field2

value2
--delimiter12345
Content-Type: something; charset = " a b \\ c "
Content-Disposition: form-data; name = "field \"  name" ;filename= "月姫.jpg"


--delimiter12345--
_


my $l = FU::MultipartFormData->parse('multipart/form-data;boundary="delimiter12345"', $t);
is scalar @$l, 3;

my $v = $l->[0];
is $v->name, 'field1';
is $v->filename, undef;
is $v->mime, 'hello';
is $v->charset, 'x';
is $v->length, 6;
is $v->data, 'value1';

is $v->substr(4), 'e1';
is $v->substr(1, 2), 'al';
is $v->substr(-2, 1), 'e';
is $v->substr(-2, 5), 'e1';
is $v->substr(-100, 2), 'va';
is $v->substr(1, -3), 'al';

$v = $l->[1];
is $v->name, 'field2';
is $v->filename, 'example.txt';
is $v->mime, 'text';
is $v->charset, undef;
is $v->length, 6;
is $v->data, 'value2';

$v = $l->[2];
is $v->name, 'field "  name';
is $v->filename, "\x{6708}\x{59eb}.jpg";
is $v->mime, 'something';
is $v->charset, ' a b \ c ';
is $v->length, 0;
is $v->data, '';

done_testing;
