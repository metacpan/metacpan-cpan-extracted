use Test::More tests => 2;

use HTML::TreeBuilderX::ASP_NET;
use HTML::Element;

{
	eval { HTML::TreeBuilderX::ASP_NET->new->press };
	ok ( $@, "Won't work naked" );
}

{
	eval { HTML::TreeBuilderX::ASP_NET->new({ element=>HTML::Element->new('a') })->press };
	like ( $@, qr/<form>/, 'Needs parent form tag' );
}

1;
