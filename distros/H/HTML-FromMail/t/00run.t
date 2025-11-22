# try to load all modules for the syntax check
use Test::More;

use_ok 'HTML::FromMail::Default::HTMLifiers';
use_ok 'HTML::FromMail::Default::Previewers';

SKIP: {
	eval { require Template::Magic };
	skip 'Template::Magic not installed', 1 if $@;

	use_ok 'HTML::FromMail::Format::Magic';
}

use_ok 'HTML::FromMail::Format::OODoc';
use_ok 'HTML::FromMail::Format';
use_ok 'HTML::FromMail::Head';
use_ok 'HTML::FromMail::Object';
use_ok 'HTML::FromMail::Page';
use_ok 'HTML::FromMail::Field';
use_ok 'HTML::FromMail::Message';
use_ok 'HTML::FromMail';

done_testing;
