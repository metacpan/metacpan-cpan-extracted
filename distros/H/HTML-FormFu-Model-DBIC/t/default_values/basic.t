use strict;
use warnings;
use Test::More tests => 31;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/default_values/basic.yml');

my $schema = new_schema();

my $rs = $schema->resultset('Master');

# filler row

$rs->create( { text_col => 'filler', } );

# row we're going to use

$rs->create( {
        text_col       => 'a',
        password_col   => 'b',
        checkbox_col   => 'foo',
        select_col     => '2',
        radio_col      => 'yes',
        radiogroup_col => '3',
        array_col      => [qw(one two)],
        date_col       => '2006-12-31 00:00:00'
    } );

{
    my $row = $rs->find(2);

    $form->model->default_values($row);

    my $fs = $form->get_element;

    is( $fs->get_field('id')->render_data->{value},           2 );
    is( $fs->get_field('text_col')->render_data->{value},     'a' );
    is( $fs->get_field('password_col')->render_data->{value}, undef );

    my $checkbox = $fs->get_field('checkbox_col')->render_data;

    is( $checkbox->{value},               'foo' );
    is( $checkbox->{attributes}{checked}, 'checked' );

    # accessing undocumented HTML::FormFu internals below
    # may break in the future

    my $select = $fs->get_field('select_col')->render_data;

    is( $select->{options}[0]{value}, 1 );
    ok( !exists $select->{options}[0]{attributes}{selected} );

    is( $select->{options}[1]{value},                2 );
    is( $select->{options}[1]{attributes}{selected}, 'selected' );

    is( $select->{options}[2]{value}, 3 );
    ok( !exists $select->{options}[2]{attributes}{selected} );

    my @radio = map { $_->render_data } @{ $form->get_fields('radio_col') };

    is( $radio[0]->{value},               'yes' );
    is( $radio[0]->{attributes}{checked}, 'checked' );

    is( $radio[1]->{value}, 'no' );
    ok( !exists $radio[1]->{attributes}{checked} );

    my @rg_option
        = @{ $fs->get_field('radiogroup_col')->render_data->{options} };

    is( $rg_option[0]->{value}, 1 );
    ok( !exists $rg_option[0]->{attributes}{checked} );

    is( $rg_option[1]->{value}, 2 );
    ok( !exists $rg_option[1]->{attributes}{checked} );

    is( $rg_option[2]->{value},               3 );
    is( $rg_option[2]->{attributes}{checked}, 'checked' );

    # column is inflated
    # my $ary_col = $fs->get_field('array_col')->default;
    # isa_ok( $ary_col, 'ARRAY' );
    my $ary_col = $fs->get_field('array_col')->render_data;

    is( $ary_col->{options}[0]{value},               'one' );
    is( $ary_col->{options}[0]{attributes}{checked}, 'checked' );

    is( $ary_col->{options}[1]{value},               'two' );
    is( $ary_col->{options}[1]{attributes}{checked}, 'checked' );

    is( $ary_col->{options}[2]{value}, 'three' );
    ok( !exists $ary_col->{options}[2]{attributes}{checked} );

    # column is inflated
    my $date = $fs->get_field('date_col')->default;

    isa_ok( $date, 'DateTime' );

    is( $date->day,   '31' );
    is( $date->month, '12' );
    is( $date->year,  '2006' );
}

