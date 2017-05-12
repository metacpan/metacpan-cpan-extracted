use utf8;
use lib lib => 't/lib';

use Test::More;
use Test::Name::FromLine;

use FormValidator::Simple::Plugin::MyRules;

subtest basic => sub {
	ok +FormValidator::Simple::Plugin::MyRules->NUMBER(100);
	ok +FormValidator::Simple::Plugin::MyRules->NUMBER("100");
	ok !+FormValidator::Simple::Plugin::MyRules->NUMBER("a");

	ok +FormValidator::Simple::Plugin::MyRules->STR_MAX("12345", 5);
	ok !+FormValidator::Simple::Plugin::MyRules->STR_MAX("12345", 4);
	ok +FormValidator::Simple::Plugin::MyRules->STR_MAX("あああああ", 5);
	ok !FormValidator::Simple::Plugin::MyRules->STR_MAX("あああああ", 4);
};

subtest api => sub {
	use CGI;
	use FormValidator::Simple qw(MyRules);

	my $q = CGI->new;
	$q->param( foo => 'bar' );

	my $result = FormValidator::Simple->check( $q => [
		foo => [ ['STR_MAX', 2 ] ],
	]);

	ok $result->has_error;
	is $result->error('foo')->[0], 'STR_MAX';
};

done_testing;
