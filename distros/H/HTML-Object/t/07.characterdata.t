#!perl
BEGIN
{
    use strict;
    use warnings;
    use Test::More;
};

BEGIN
{
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( "Cannot load HTML::Object::DOM" );
    use_ok( 'HTML::Object::DOM::CharacterData' ) || BAIL_OUT( "Cannot load HTML::Object::DOM::CharacterData" );
    # We use Text to test CharacterData properties and methods, because it inherits from it and CharacterData is just an abstract class
    use_ok( 'HTML::Object::DOM::Text' ) || BAIL_OUT( "Cannot load HTML::Object::DOM::Text" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

can_ok( 'HTML::Object::DOM::CharacterData', 'after' );
can_ok( 'HTML::Object::DOM::CharacterData', 'appendData' );
can_ok( 'HTML::Object::DOM::CharacterData', 'before' );
can_ok( 'HTML::Object::DOM::CharacterData', 'data' );
can_ok( 'HTML::Object::DOM::CharacterData', 'deleteData' );
can_ok( 'HTML::Object::DOM::CharacterData', 'insertData' );
can_ok( 'HTML::Object::DOM::CharacterData', 'length' );
can_ok( 'HTML::Object::DOM::CharacterData', 'nextElementSibling' );
can_ok( 'HTML::Object::DOM::CharacterData', 'previousElementSibling' );
can_ok( 'HTML::Object::DOM::CharacterData', 'remove' );
can_ok( 'HTML::Object::DOM::CharacterData', 'replaceData' );
can_ok( 'HTML::Object::DOM::CharacterData', 'replaceWith' );
can_ok( 'HTML::Object::DOM::CharacterData', 'substringData' );

my $test_data = <<EOT;
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <title>data demo</title>
    </head>
    <body>
        <!-- This is an html comment !-->
        <output id="Result"></output>
    </body>
</html>
EOT

my $parser = HTML::Object::DOM->new;
my $doc = $parser->parse_data( $test_data ) || BAIL_OUT( $parser->error );

my $comment = $doc->body->childNodes->[1];
diag( "Comment found is '$comment'" ) if( $DEBUG );
isa_ok( $comment => 'HTML::Object::DOM::Comment' );
my $output = $doc->getElementById('Result');
$output->value = $comment->data;
# output content would now be: This is an html comment !
is( $output->as_text, q{ This is an html comment !}, 'data' );

done_testing();

__END__

