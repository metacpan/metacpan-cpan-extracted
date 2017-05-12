use I22r::Translate;
use Test::More;
use lib 't';

# exercise I22r::Translate with a trivial backend

I22r::Translate->config(
    'Test::Backend::Reverser' => {
	ENABLED => 1,
	filter => [ 'Literal' ],
    }
);

my $r = I22r::Translate->translate_string(
    src => 'en', dest => 'ko', text => 'some unprotected text',
    return_type => 'hash' );
ok( $r, 'translate_string: got result');
ok( $r->{TEXT} eq 'txet detcetorpnu emos', 'translated string is reversed' );
ok( $r->{OTEXT} eq 'some unprotected text', 'original string is intact' );

my $s = I22r::Translate->translate_string(
   src => 'ab', dest => 'cd', text => 'some {{protected}} text',
   return_type => 'hash' );
ok( $s, 'translate_string: got 2nd result' );
ok( $s->{TEXT} =~ /txet/ && $s->{TEXT} =~ /emos/,
    'parts of translated string was reversed' );
ok( $s->{TEXT} =~ /protected/, 'protected part of string not reversed' );
use Data::Dumper;
ok( $s->{OTEXT} eq 'some {{protected}} text', 'original string intact' );

##################################################################

%I22r::Translate::config = ();
%Test::Backend::Reverser::config = ();

I22r::Translate->config(
    filter => [ 'Literal' ],
    'Test::Backend::Reverser' => {
	ENABLED => 1,
    }
);

$r = I22r::Translate->translate_string(
    src => 'en', dest => 'ko', text => 'some unprotected text',
    return_type => 'object' );
ok( $r, 'translate_string: got result');
ok( $r->text eq 'txet detcetorpnu emos', 'translated string is reversed' );
ok( $r->otext eq 'some unprotected text', 'original string is intact' );

$s = I22r::Translate->translate_string(
   src => 'ab', dest => 'cd', text => 'some {{protected}} text',
   return_type => 'object' );
ok( $s, 'translate_string: got 2nd result' );
ok( $s->text =~ /txet/ && $s->text =~ /emos/,
    'parts of translated string was reversed' );
ok( $s->text =~ /protected/, 'protected part of string not reversed' );
ok( $s->otext eq 'some {{protected}} text', 'original string intact' );

##################################################################

%I22r::Translate::config = ();
%Test::Backend::Reverser::config = ();

I22r::Translate->config(
    'Test::Backend::Reverser' => {
	ENABLED => 1,
    },
    return_type => 'object'
);

$r = I22r::Translate->translate_string(
    src => 'en', dest => 'ko', text => 'some unprotected text',
    filter => [ 'Literal' ] );
ok( $r, 'translate_string: got result');
ok( $r->text eq 'txet detcetorpnu emos', 'translated string is reversed' );
ok( $r->otext eq 'some unprotected text', 'original string is intact' );

$s = I22r::Translate->translate_string(
    src => 'ab', dest => 'cd', text => 'some {{protected}} text',
    filter => [ 'Literal' ] );
ok( $s, 'translate_string: got 2nd result' );
ok( $s->text =~ /txet/ && $s->text =~ /emos/,
    'parts of translated string was reversed' );
ok( $s->text =~ /protected/, 'protected part of string not reversed' );
ok( $s->otext eq 'some {{protected}} text', 'original string intact' );


done_testing();
