#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'HTML::Object' ) || BAIL_OUT( 'Unable to load HTML::Object' );
    use_ok( 'HTML::Object::Element' ) || BAIL_OUT( 'Unable to load HTML::Object::Element' );
};

use strict;
use warnings;

can_ok( 'HTML::Object::Element', 'address' );
can_ok( 'HTML::Object::Element', 'all_attr' );
can_ok( 'HTML::Object::Element', 'all_attr_names' );
can_ok( 'HTML::Object::Element', 'as_html' );
can_ok( 'HTML::Object::Element', 'as_string' );
can_ok( 'HTML::Object::Element', 'as_text' );
can_ok( 'HTML::Object::Element', 'as_trimmed_text' );
can_ok( 'HTML::Object::Element', 'as_xml' );
can_ok( 'HTML::Object::Element', 'attr' );
can_ok( 'HTML::Object::Element', 'attributes' );
can_ok( 'HTML::Object::Element', 'attributes_sequence' );
can_ok( 'HTML::Object::Element', 'checksum' );
can_ok( 'HTML::Object::Element', 'children' );
can_ok( 'HTML::Object::Element', 'class' );
can_ok( 'HTML::Object::Element', 'clone' );
can_ok( 'HTML::Object::Element', 'clone_list' );
can_ok( 'HTML::Object::Element', 'close' );
can_ok( 'HTML::Object::Element', 'close_tag' );
can_ok( 'HTML::Object::Element', 'column' );
can_ok( 'HTML::Object::Element', 'content' );
can_ok( 'HTML::Object::Element', 'content_array_ref' );
can_ok( 'HTML::Object::Element', 'content_list' );
can_ok( 'HTML::Object::Element', 'delete' );
can_ok( 'HTML::Object::Element', 'delete_content' );
can_ok( 'HTML::Object::Element', 'delete_ignorable_whitespace' );
can_ok( 'HTML::Object::Element', 'depth' );
can_ok( 'HTML::Object::Element', 'descendants' );
can_ok( 'HTML::Object::Element', 'destroy' );
can_ok( 'HTML::Object::Element', 'destroy_content' );
can_ok( 'HTML::Object::Element', 'detach' );
can_ok( 'HTML::Object::Element', 'detach_content' );
can_ok( 'HTML::Object::Element', 'dump' );
can_ok( 'HTML::Object::Element', 'eid' );
can_ok( 'HTML::Object::Element', 'end' );
can_ok( 'HTML::Object::Element', 'extract_links' );
can_ok( 'HTML::Object::Element', 'find_by_attribute' );
can_ok( 'HTML::Object::Element', 'find_by_tag_name' );
can_ok( 'HTML::Object::Element', 'has_children' );
can_ok( 'HTML::Object::Element', 'id' );
can_ok( 'HTML::Object::Element', 'insert_element' );
can_ok( 'HTML::Object::Element', 'internal' );
can_ok( 'HTML::Object::Element', 'is_closed' );
can_ok( 'HTML::Object::Element', 'is_empty' );
can_ok( 'HTML::Object::Element', 'is_valid_attribute' );
can_ok( 'HTML::Object::Element', 'is_void' );
can_ok( 'HTML::Object::Element', 'left' );
can_ok( 'HTML::Object::Element', 'line' );
can_ok( 'HTML::Object::Element', 'lineage' );
can_ok( 'HTML::Object::Element', 'lineage_tag_names' );
can_ok( 'HTML::Object::Element', 'look' );
can_ok( 'HTML::Object::Element', 'look_down' );
can_ok( 'HTML::Object::Element', 'look_up' );
can_ok( 'HTML::Object::Element', 'looks_like_html' );
can_ok( 'HTML::Object::Element', 'modified' );
can_ok( 'HTML::Object::Element', 'new_attribute' );
can_ok( 'HTML::Object::Element', 'new_closing' );
can_ok( 'HTML::Object::Element', 'new_document' );
can_ok( 'HTML::Object::Element', 'new_element' );
can_ok( 'HTML::Object::Element', 'new_from_lol' );
can_ok( 'HTML::Object::Element', 'new_parser' );
can_ok( 'HTML::Object::Element', 'new_text' );
can_ok( 'HTML::Object::Element', 'normalize_content' );
can_ok( 'HTML::Object::Element', 'offset' );
can_ok( 'HTML::Object::Element', 'original' );
can_ok( 'HTML::Object::Element', 'parent' );
can_ok( 'HTML::Object::Element', 'pos' );
can_ok( 'HTML::Object::Element', 'pindex' );
can_ok( 'HTML::Object::Element', 'postinsert' );
can_ok( 'HTML::Object::Element', 'preinsert' );
can_ok( 'HTML::Object::Element', 'push_content' );
can_ok( 'HTML::Object::Element', 'replace_with' );
can_ok( 'HTML::Object::Element', 'replace_with_content' );
can_ok( 'HTML::Object::Element', 'reset' );
can_ok( 'HTML::Object::Element', 'right' );
can_ok( 'HTML::Object::Element', 'root' );
can_ok( 'HTML::Object::Element', 'same_as' );
can_ok( 'HTML::Object::Element', 'set_checksum' );
can_ok( 'HTML::Object::Element', 'splice_content' );
can_ok( 'HTML::Object::Element', 'tag' );
can_ok( 'HTML::Object::Element', 'traverse' );
can_ok( 'HTML::Object::Element', 'unshift_content' );

my $p = HTML::Object->new;
my $doc = $p->parse_file( './t/test.html' ) || BAIL_OUT( $p->error );
my $body = $doc->look_down( _tag => 'body' )->first;
SKIP:
{
    if( !defined( $body ) )
    {
        skip( 'cannot find body', 3 );
    }
    my $divs = $body->look_down( _tag => 'div', { max_level => 1 });
    diag( "Error looking down: ", $body->error ) if( !defined( $divs ) );
    is( $divs->length, 2, 'total divs found directly under body' );
    is( $divs->first->attr( 'class' ), 'container', 'first div' );
    is( $divs->last->id, 'testToggle', 'last div' );
    $divs = $body->look_down( _tag => 'div' );
    is( $divs->length, 7, 'number of divs found everywhere' );
};

done_testing();

__END__

