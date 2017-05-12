use I22r::Translate;
use Test::More;
use lib 't';

$input = {
    foo => 'some {{protected}} text',
    bar => 'text with <a href="http://bar.com/">HTML</a> text',
    baz => 'phrase with <b>{{protected}}</b> text and HTML'
};


I22r::Translate->config(
    'Test::Backend::Reverser' => {
	ENABLED => 1,
	filter => [ 'Literal', 'HTML' ],
    }
);

my %r = I22r::Translate->translate_hash(
    src => 'en', dest => 'ko', text => $input );

ok( 0 != keys %r, 'translate_hash: got result' );
ok( $r{foo} =~ /txet .*protected.* emos/,
    'string with protected text' );
ok( $r{bar} =~ /txet.*bar.com.*LMTH.*htiw txet/,
    'string with HTML tags and attributes' );
ok( $r{bar} =~ m{<a href="http://bar.com/">},
    'HTML attributes preserved' );
ok( $r{baz} =~ /LMTH dna txet.*protected.*htiw esarhp/,
    'string with HTML and protected text' );
ok( $r{baz} =~ m{<b>.*protected.*</b>},
    'HTML tags preserved' );

##################################################################

%I22r::Translate::config = ();
$Test::Backend::Reverser::config = { };

I22r::Translate->config(
    filter => [ 'HTML', 'Literal' ],
    'Test::Backend::Reverser' => {
	ENABLED => 1,
    }
);

%r = I22r::Translate->translate_hash(
    src => 'en', dest => 'ko', text => $input );

ok( 0 != keys %r, 'translate_hash: got result' );
ok( $r{foo} =~ /txet .*protected.* emos/,
    'string with protected text' );
ok( $r{bar} =~ /txet.*bar.com.*LMTH.*htiw txet/,
    'string with HTML tags and attributes' );
ok( $r{bar} =~ m{<a href="http://bar.com/">},
    'HTML attributes preserved' );
ok( $r{baz} =~ /LMTH dna txet.*protected.*htiw esarhp/,
    'string with HTML and protected text' );
ok( $r{baz} =~ m{<b>.*protected.*</b>},
    'HTML tags preserved' );


##################################################################

%I22r::Translate::config = ();
$Test::Backend::Reverser::config = { };

I22r::Translate->config(
    filter => [ 'HTML' ],
    'Test::Backend::Reverser' => {
	ENABLED => 1,
	filter => [ 'Literal' ],
    }
);

%r = I22r::Translate->translate_hash(
    src => 'en', dest => 'ko', text => $input );

ok( 0 != keys %r, 'translate_hash: got result' );
ok( $r{foo} =~ /txet .*protected.* emos/,
    'string with protected text' );
ok( $r{bar} =~ /txet.*bar.com.*LMTH.*htiw txet/,
    'string with HTML tags and attributes' );
ok( $r{bar} =~ m{<a href="http://bar.com/">},
    'HTML attributes preserved' );
ok( $r{baz} =~ /LMTH dna txet.*protected.*htiw esarhp/,
    'string with HTML and protected text' );
ok( $r{baz} =~ m{<b>.*protected.*</b>},
    'HTML tags preserved' );


##################################################################

%I22r::Translate::config = ();
$Test::Backend::Reverser::config = { };

I22r::Translate->config(
    'Test::Backend::Reverser' => {
	ENABLED => 1,
	filter => [ 'Literal' ],
    }
);

%r = I22r::Translate->translate_hash(
    src => 'en', dest => 'ko', text => $input,
    filter => [ 'HTML' ] );

ok( 0 != keys %r, 'translate_hash: got result' );
ok( $r{foo} =~ /txet .*protected.* emos/,
    'string with protected text' );
ok( $r{bar} =~ /txet.*bar.com.*LMTH.*htiw txet/,
    'string with HTML tags and attributes' );
ok( $r{bar} =~ m{<a href="http://bar.com/">},
    'HTML attributes preserved' );
ok( $r{baz} =~ /LMTH dna txet.*protected.*htiw esarhp/,
    'string with HTML and protected text' );
ok( $r{baz} =~ m{<b>.*protected.*</b>},
    'HTML tags preserved' );


##################################################################

%I22r::Translate::config = ();
$Test::Backend::Reverser::config = { };

I22r::Translate->config(
    filter => [ 'Literal' ],
    'Test::Backend::Reverser' => {
	ENABLED => 1,
    }
);

%r = I22r::Translate->translate_hash(
    src => 'en', dest => 'ko', text => $input,
    filter => [ 'HTML' ] );

ok( 0 != keys %r, 'translate_hash: got result' );
ok( $r{foo} =~ /txet .*protected.* emos/,
    'string with protected text' );
ok( $r{bar} =~ /txet.*bar.com.*LMTH.*htiw txet/,
    'string with HTML tags and attributes' );
ok( $r{bar} =~ m{<a href="http://bar.com/">},
    'HTML attributes preserved' );
ok( $r{baz} =~ /LMTH dna txet.*protected.*htiw esarhp/,
    'string with HTML and protected text' );
ok( $r{baz} =~ m{<b>.*protected.*</b>},
    'HTML tags preserved' );



done_testing();
