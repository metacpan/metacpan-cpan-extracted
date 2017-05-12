use strict;
use warnings;

use Test::More tests => 11;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new->method('post')->action('/foo/bar')->strict(1);

$w->element( 'Textfield', 'age' )->label('Age')->size(3);
$w->element( 'Textfield', 'name' )->label('Name')->size(60);
$w->element( 'Submit',    'ok' )->value('OK');

$w->constraint( 'Integer', 'age' )->message('No integer.');
$w->constraint( 'Maybe',   'ok' );

my $query = HTMLWidget::TestLib->mock_query( {
        age  => 'NaN',
        name => 'sri',
        foo  => 'blah',
        bar  => 'stuff',
        ok   => 'OK',
    } );

my $f = $w->process($query);

ok( $f->valid('ok'),     'Field ok is valid' );
ok( !$f->valid('name'),  'Field name is valid' );
ok( !$f->valid('age'),   'Field age is not valid' );
ok( !$f->valid('foo'),   'Field foo is not valid' );
ok( !$f->valid('other'), 'Field other is not valid' );

is( $f->params->{ok}, 'OK', 'Param name is accessible' );
ok( !$f->params->{name}, 'Param name is accessible' );

# is this correct here?
ok( !exists $f->params->{age}, 'Param age does not exist in params hash' );
is( $f->params->{age}, undef, 'Param age is undef' );
ok( !exists $f->params->{foo},   'Param foo is not in params hash' );
ok( !exists $f->params->{other}, 'Param other is not in params hash' );
