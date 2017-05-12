use strict;
use Test::More;
use MIME::Lite;
use MIME::Lite::Generator;

sub trim($) {
	my $str = shift;
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	$str;
}

for my $encoding (qw/BINARY 8BIT 7BIT QUOTED-PRINTABLE BASE64/) {
	my $msg = MIME::Lite->new(
		From     => 'me@myhost.com',
		To       => 'you@yourhost.com',
		Cc       => 'some@other.com, some@more.com',
		Subject  => 'Helloooooo!',
		Encoding => $encoding,
		Data     => "Привет мир!\n"
	);

	my $generator = MIME::Lite::Generator->new($msg);
	my $gen_data = '';
	my $i = 0;
	while (my $str = $generator->get()) {
		$gen_data .= $$str;
		$i++;
	}

	is(trim $gen_data, trim $msg->as_string, 'simple msg - ' . $encoding);
	ok($i > 1, 'simple msg generated in several iterations - ' . $encoding);
}

for my $encoding (qw/BINARY 8BIT 7BIT QUOTED-PRINTABLE BASE64/) {
	my $msg = MIME::Lite->new(
		From     => 'me@myhost.com',
		To       => 'you@yourhost.com',
		Cc       => 'some@other.com, some@more.com',
		Subject  => 'Не мы такие, жизнь такая...',
		Encoding => $encoding,
		Data     => "я узнал\r\nчто у меня\r\nесть огромная семья\r\nи тропинка и лесок\r\nв поле каждый колосок\r\n"
	);
	
	my $generator = MIME::Lite::Generator->new($msg);
	my $gen_data = '';
	while (my $str = $generator->get()) {
		$gen_data .= $$str;
	}

	is(trim $gen_data, trim $msg->as_string, 'msg with utf8 subject - ' . $encoding);
}

for my $encoding (qw/BINARY 8BIT 7BIT QUOTED-PRINTABLE BASE64/) {
	my $msg = MIME::Lite->new(
		From    => 'root@home.fata-flow.ru',
		To      => 'root@fata-flow.ru',
		Subject => 'Hello world',
		Type    => 'multipart/mixed'
	);

	$msg->attach(Type => 'TEXT', Data => 'Hello sht!!!');
	$msg->attach(Path => __FILE__, Disposition => 'attachment', Encoding => $encoding);

	my $generator = MIME::Lite::Generator->new($msg);
	my $gen_data = '';
	while (my $str = $generator->get()) {
		$gen_data .= $$str;
	}

	is(trim $gen_data, trim $msg->as_string, 'msg with attachment - ' . $encoding);
}

for my $encoding (qw/BINARY 8BIT 7BIT QUOTED-PRINTABLE BASE64/) {
	my $msg = MIME::Lite->new(
		From    => 'root@home.fata-flow.ru',
		To      => 'root@fata-flow.ru',
		Subject => 'Hello world',
		Type    => 'multipart/mixed'
	);

	$msg->attach(Type => 'TEXT', Data => 'Hello sht!!!');
	$msg->attach(Path => __FILE__, Disposition => 'attachment', Encoding => $encoding);
	$msg->attach(MIME::Lite->new(
		Type =>'text/html',
		Data =>'<H1>Hello</H1>',
	));
	
	my $generator = MIME::Lite::Generator->new($msg);
	my $gen_data = '';
	while (my $str = $generator->get()) {
		$gen_data .= $$str;
	}

	is(trim $gen_data, trim $msg->as_string, 'msg with attachment and prepared part - ' . $encoding);
}

done_testing;
