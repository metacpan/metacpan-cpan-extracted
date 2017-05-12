use strict;
use warnings;

use Test::More tests => 23;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;
our $counter;

$w->element( 'Textfield', 'foo' );
$w->element( 'Textfield', 'bar' );

my $constraint = $w->constraint( 'CallbackOnce', 'foo', 'bar' )
    ->callback( sub { $counter++; return 1 if $_[0] && $_[1] } );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'yada',
            bar => 'nada',
        } );

    local $counter = 0;

    my $f = $w->process($query);

    is( $counter, 1, 'callback only called once' );

    is( $f->param('foo'), 'yada' );
    is( $f->param('bar'), 'nada' );

    ok( !$f->errors, 'no errors' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => '',
            bar => 'nada',
        } );

    local $counter = 0;

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
    ok( $f->errors('bar'), 'bar has errors' );

    is( $counter, 1, 'callback only called once' );
}

# Multiple Valid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => [ 'bar', 'yada' ],
            bar => 'nada',
        } );

    local $counter = 0;

    my $f = $w->process($query);

    ok( $f->valid('foo'), "Valid" );
    ok( $f->valid('bar'), "Valid" );

    my @results = $f->param('foo');
    is( $results[0], 'bar',  "Multiple valid values" );
    is( $results[1], 'yada', "Multiple valid values" );

    is( $counter, 1, 'callback only called once' );
}

# Multiple Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => [ '', '' ] } );

    local $counter = 0;

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
    ok( $f->errors('bar'), 'bar has errors' );

    is( $counter, 1 );
}

# Display one error on multiple failure
{
    $constraint->render_errors(qw/ foo /);

    my $query = HTMLWidget::TestLib->mock_query( { foo => [ '', '' ] } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
    ok( $f->errors('bar'), 'bar has errors' );

    ok( !$f->valid('foo'), 'foo is not valid' );
    ok( !$f->valid('bar'), 'bar is not valid' );
}

# Display both errors (explicitly) on multiple failure
{
    $constraint->render_errors(qw/ foo bar /);
    my $query = HTMLWidget::TestLib->mock_query( { foo => [ '', '' ] } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
    ok( $f->errors('bar'), 'bar has errors' );

    ok( !$f->valid('foo'), 'foo is not valid' );
    ok( !$f->valid('bar'), 'bar is not valid' );
}
