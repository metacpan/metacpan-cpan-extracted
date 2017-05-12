use strict;
use warnings;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-WidgetValidator-Widget-PixivEmbedFeature.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More 'no_plan';
BEGIN { use_ok('HTML::WidgetValidator') };
{
	my $validator = HTML::WidgetValidator->new(widgets => ['PixivEmbedFeature']);
	{
		# good case
		my $html = '<iframe style="background:transparent;" width="380" height="168" frameborder="0" marginheight="0" marginwidth="0" scrolling="no" src="http://embed.pixiv.net/code.php?id=620544_7845e701b2591a12f48eb0f05f0043e6"></iframe>';
			ok(ref $validator, 'ref');
			ok($validator->isa('HTML::WidgetValidator'), 'isa');
		my $result  = $validator->validate($html);
			ok(defined $result, 'defined');
			ok(ref($result) eq 'HTML::WidgetValidator::Result', 'ref '.ref($result));
			is($result->code, $html, 'code');
			is($result->name, 'PixivEmbedFeature', 'name');
	}
	{
		# good case
		my $html = '<iframe style="" width="" height="" frameborder="" marginheight="" marginwidth="" scrolling="" src="http://embed.pixiv.net/code.php"></iframe>';
		my $result  = $validator->validate($html);
			is(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# bad case:iframe src
		my $html = '<iframe style="" width="" height="" frameborder="" marginheight="" marginwidth="" scrolling="" src="http://embed.pixiv.ne.jp/code.php"></iframe>';
		my $result  = $validator->validate($html);
			isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# bad case:iframe src
		my $html = '<iframe style="" width="" height="" frameborder="" marginheight="" marginwidth="" scrolling="" src="http://embed.pixiv.net/othercode.php"></iframe>';
		my $result  = $validator->validate($html);
			isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# bad case:background attr
		my $html = '<iframe style="background:#000;" width="" height="" frameborder="" marginheight="" marginwidth="" scrolling="" src="http://embed.pixiv.net/code.php"></iframe>';
		my $result  = $validator->validate($html);
			isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# bad case:background attr
		my $html = '<iframe style="background:url(http://any.net/any.resource);" width="" height="" frameborder="" marginheight="" marginwidth="" scrolling="" src="http://embed.pixiv.net/code.php"></iframe>';
		my $result  = $validator->validate($html);
			isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# bad case:other attr
		my $html = '<iframe style="" width="" height="" frameborder="" marginheight="" marginwidth="" scrolling="" src="http://embed.pixiv.net/code.php" name=""></iframe>';
		my $result  = $validator->validate($html);
			isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
	{
		# bad case:missing attr
		my $html = '<iframe width="" height="" frameborder="" marginheight="" marginwidth="" scrolling="" src="http://embed.pixiv.net/code.php" name=""></iframe>';
		my $result  = $validator->validate($html);
			isnt(ref $result, 'HTML::WidgetValidator::Result');
	}
}
__END__

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

