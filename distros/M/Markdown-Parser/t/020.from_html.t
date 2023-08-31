#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Markdown::Parser' ) || BAIL_OUT( 'Cannot load Markdown::Parser' );
    use_ok( 'HTML::Object' ) || BAIL_OUT( 'Cannot load HTML::Object' );
};

use strict;
use warnings;

my $text = <<EOT;
Hello,

<p>
This is <a href="https://example.org/some/where/">somewhere</a> nice to <code>code</code>, but <del>not to be lazy</del>, but <ins>instead be productive</ins>.
</p>

<div>
And this would be as-is.
</div>
EOT

my $p = Markdown::Parser->new( debug => 0 );
# my $phtml = HTML::Object->new( debug => $DEBUG );
my $phtml = HTML::Object->new;
my $html = $phtml->parse_data( $text ) || die( "Error parsing HTML: ", $phtml->error );
isa_ok( $html => 'HTML::Object::Element' );
my $doc = $p->from_html( $html ) || die( $p->error );
isa_ok( $doc => 'Markdown::Parser::Document' );
diag( $doc->as_markdown ) if( $DEBUG );
my $expected = <<EOT;
Hello,


This is [somewhere](https://example.org/some/where/) nice to `code`, but ~~not to be lazy~~, but ++instead be productive++.



<div>
And this would be as-is.
</div>
EOT
my $result = $doc->as_markdown;
is( $result => $expected );
# my $pod = $doc->as_pod;
# diag( $pod ) if( $DEBUG );
    
done_testing();

__END__

