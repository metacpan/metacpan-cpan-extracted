#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM' );
    use_ok( 'HTML::Object::DOM::Element::Title' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM::Element::Title' );
};

can_ok( 'HTML::Object::DOM::Element::Title', 'text' );

my $html = <<EOT;
<!DOCTYPE html>
<html>
    <head>
        <title>Hello world! <span class="highlight">Isn't this wonderful</span> really?</title>
    </head>
    <body></body>
</html>
EOT

my $p = HTML::Object::DOM->new;
my $doc = $p->parse_data( $html ) || BAIL_OUT( $p->error );
# $doc->getElementsByTagName( 'title' )->first->debug(4);
my $title = $doc->title;
is( $title, 'Hello world!  really?', 'document->title' );
my $t = $doc->getElementsByTagName( 'title' )->first;
isa_ok( $t => 'HTML::Object::DOM::Element::Title' );
is( $t->children->length, 3, 'title->children->length' );
is( $t->text, 'Hello world!  really?', 'title->text' );
# $t->debug(4);
$t->text = q{This should<br />not work};
is( $t->text, 'Hello world!  really?', 'title only accepts text, space and comment' );
is( $t->error->message, 'Values provided for title text contains data other tan text or space. You can provide text, space including HTML::Object::DOM::Text and HTML::Object::DOM::Space objects', 'title->error' );

done_testing();

__END__

