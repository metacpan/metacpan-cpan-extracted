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
    use_ok( 'HTML::Object::DOM::Element::Table' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM::Element::Table' );
    use_ok( 'HTML::Object::DOM::Element::TableCaption' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM::Element::TableCaption' );
};

can_ok( 'HTML::Object::DOM::Element::Table', 'caption' );
can_ok( 'HTML::Object::DOM::Element::Table', 'createCaption' );
can_ok( 'HTML::Object::DOM::Element::Table', 'createTBody' );
can_ok( 'HTML::Object::DOM::Element::Table', 'createTFoot' );
can_ok( 'HTML::Object::DOM::Element::Table', 'createTHead' );
can_ok( 'HTML::Object::DOM::Element::Table', 'deleteCaption' );
can_ok( 'HTML::Object::DOM::Element::Table', 'deleteRow' );
can_ok( 'HTML::Object::DOM::Element::Table', 'deleteTFoot' );
can_ok( 'HTML::Object::DOM::Element::Table', 'deleteTHead' );
can_ok( 'HTML::Object::DOM::Element::Table', 'insertRow' );
can_ok( 'HTML::Object::DOM::Element::Table', 'rows' );
can_ok( 'HTML::Object::DOM::Element::Table', 'tBodies' );
can_ok( 'HTML::Object::DOM::Element::Table', 'tbodies' );
can_ok( 'HTML::Object::DOM::Element::Table', 'tFoot' );
can_ok( 'HTML::Object::DOM::Element::Table', 'tfoot' );
can_ok( 'HTML::Object::DOM::Element::Table', 'tHead' );
can_ok( 'HTML::Object::DOM::Element::Table', 'thead' );

my $html = <<EOT;
<!doctype html>
<html>
    <head><title>Demo</title></head>
    <body>
        <table>
            <caption>Some table</caption>
            <thead>
                <tr><th>col 1</th><th>col 2</th><th>col 3</th></tr>
            </thead>
            <colgroup span="3"></colgroup>
            <tbody>
                <tr><td>cell 1.1</td><td>cell 1.2</td><td rowspan="2">cell 1.3</td></tr>
                <tr><td>cell 2.1</td><td>cell 2.2</td></tr>
                <tr><td>cell 3.1</td><td colspan="2">cell 3.2</td></tr>
            </tbody>
            <tfoot>
                <tr><td colspan="3">Footer</td></tr>
            </tfoot>
        </table>
    </body>
</html>
EOT

my $p = HTML::Object::DOM->new;
my $doc = $p->parse_data( $html ) || BAIL_OUT( $p->error );
my $table = $doc->getElementsByTagName( 'table' )->first;
my $caption = $table->caption;
isa_ok( $caption => 'HTML::Object::DOM::Element::TableCaption', 'caption' );
is( $caption->textContent, 'Some table', 'caption->textContent' );
# Since it exists already, it should return the same object as above
my $caption2 = $table->createCaption;
is( $caption2, $caption, 'createCaption' );
is( $table->tbodies->length, 1, 'tbodies before change' );
my $body = $table->tbodies->first;
isa_ok( $body => 'HTML::Object::DOM::Element::TableSection', 'tbodies' );
is( $body->rows->length, 3, 'tbody->rows->length' );
my $row = $table->insertRow;
isa_ok( $row => 'HTML::Object::DOM::Element::TableRow', 'insertRow' );
is( $table->rows->length, 6, 'insertRow (2)' );
is( $table->tbodies->[0]->rows->length, 4, 'tbodies->[0]->rows->length' );
# XXX
# $table->debug(4);
my $body2 = $table->createTBody;
isa_ok( $body2 => 'HTML::Object::DOM::Element::TableSection', 'createTBody' );
is( $table->tbodies->length, 2, 'tbodies after change' );
my $foot = $table->createTFoot;
is( $foot, $table->tfoot, 'createTFoot' );
my $head = $table->createTHead;
is( $head, $table->thead, 'createTHead' );
my $removed_caption = $table->deleteCaption;
is( $removed_caption, $caption, 'deleteCaption' );
is( $table->caption, undef, 'deleteCaption (table->caption)' );
my $rows = $table->rows;
isa_ok( $rows => 'HTML::Object::DOM::Collection', 'rows' );
is( $rows->length, 6, 'number of rows' );
my $old_row = $table->deleteRow(-3);
diag( $table->error ) if( !defined( $old_row ) );
isa_ok( $old_row => 'HTML::Object::DOM::Element::TableRow' );
is( $old_row->as_string, q{<tr><td>cell 3.1</td><td colspan="2">cell 3.2</td></tr>}, 'deleteRow (2)' );
is( $table->rows->length, 5, 'number of rows after deleteRow' );
my $removed_foot = $table->deleteTFoot;
isa_ok( $removed_foot, 'HTML::Object::DOM::Element::TableSection', 'deleteTFoot' );
is( $removed_foot, $foot, 'deleteTFoot (2)' );
is( $table->rows->length, 4, 'deleteTFoot (table->rows->length)' );
my $removed_head = $table->deleteTHead;
isa_ok( $removed_head, 'HTML::Object::DOM::Element::TableSection', 'deleteTHead' );
is( $removed_head, $head, 'deleteTHead (2)' );
is( $table->rows->length, 3, 'deleteTHead (table->rows->length)' );

subtest 'caption' => sub
{
    my $new = HTML::Object::DOM::Element::TableCaption->new;
    $new->textContent = "New caption";
    $table->caption = $new;
    is( $table->caption, $new, 'table->caption' );
};

subtest 'row' => sub
{
    my $rows = $body->rows;
    my $row = $rows->first;
    isa_ok( $row => 'HTML::Object::DOM::Element::TableRow', 'first row' );
    is( $row->rowIndex, 1, 'rowIndex' );
    is( $row->sectionRowIndex, 1, 'sectionRowIndex' );
    my $cells = $row->cells;
    isa_ok( $cells => 'HTML::Object::DOM::Collection', 'cells collection' );
    my $size = $cells->length;
    is( $size, 3, 'cells->length' );
    my $cell = $row->insertCell;
    isa_ok( $cell => 'HTML::Object::DOM::Element::TableCell' );
    $size = $cells->length;
    is( $size, 4, 'insertCell' );
    my $cells2 = $row->cells;
    is( $addr2, $addr, 'cells collection' );
    is( $cells->length, $cells2->length, 'cells->length comparison; same object' );
    is( $cell->cellIndex, 3, 'cellIndex' );
    my $cell3 = $cells->index(2);
    is( $cell3->rowspan, 2, 'cell->rowspan' );
};

# diag( $doc->as_string );

done_testing();

__END__

