#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Moose;
use Test::Exception;
use Test::Deep;

use lib 't/lib';

our $es;
do 'es.pl';

use_ok 'TypeTest' || print 'Bail out';

my $model = new_ok( 'TypeTest', [ es => $es ], 'Model' );

isa_ok my $tm = $model->typemap, 'Elastic::Model::TypeMap::Base';

note '';
note "Flation for TypeTest::Objects";

does_ok my $class = $model->class_for('TypeTest::Objects'),
    'Elastic::Model::Role::Doc';

my $meta = $class->meta;

note '';

my ( $de, $in );

## OBJECTS ##

{
    ( $de, $in ) = flators('object');

    # deflate method
    my $bar = bless { bar => 1 }, 'Bar';
    sub Bar::deflate { return { foo => 1 } }
    sub Bar::inflate { return { bar => 1 } }

    cmp_deeply $de->($bar), { Bar => { foo => 1 } },
        'Deflate object: deflator';
    cmp_deeply $in->( { Bar => { foo => 1 } } ), $bar,
        'Inflate object: deflator';

    # no deflate method
    throws_ok sub { $de->( bless {}, 'Foo' ) },
        qr/does not provide a deflate/,
        'Deflate object: no_deflator';
}

## DOCS ##

{
    my $doc_class = $model->class_for('Foo::User');
    my $saved     = $doc_class->new(
        name  => 'John',
        email => 'john@foo.com',
        uid   => Elastic::Model::UID->new_from_store( {
                _index   => 'foo',
                _type    => 'user',
                _id      => 1,
                _version => 1
            }
        ),
    );

    my $unsaved = $doc_class->new(
        name  => 'John',
        email => 'john@foo.com',
        uid   => Elastic::Model::UID->new(
            index => 'foo',
            type  => 'user',
            id    => 1,
        )
    );

    test_doc_attr(
        'doc',
        {   email => "john\@foo.com",
            name  => "John",
            lazy  => 'lazy',
            uid   => { id => 1, index => "foo", type => "user" },
        }
    );

    test_doc_attr( 'doc_none',
        { uid => { id => 1, index => "foo", type => "user" } } );

    test_doc_attr(
        'doc_name',
        {   name => "John",
            uid  => { id => 1, index => "foo", type => "user" },
        }
    );

    test_doc_attr(
        'doc_exname',
        {   email => "john\@foo.com",
            lazy  => 'lazy',
            uid   => { id => 1, index => "foo", type => "user" },
        }
    );

#===================================
    sub test_doc_attr {
#===================================
        my ( $attr, $deflated ) = @_;

        ( $de, $in ) = flators($attr);

        cmp_deeply $de->($saved), $deflated, "Deflate $attr: saved";

        isa_ok my $inflated = $in->($deflated),
            $doc_class,
            "Inflate $attr: saved";

        ok $inflated->_can_inflate, "Inflate $attr: can_inflate";

        isa_ok my $uid = $inflated->uid,
            'Elastic::Model::UID',
            "Inflate $attr: uid";

        cmp_methods $uid,
            [
            index      => 'foo',
            type       => 'user',
            id         => 1,
            version    => undef,
            from_store => 1
            ],
            "Inflate $attr: uid methods";

        throws_ok sub { $de->($unsaved) },
            qr/Cannot deflate UID as it not saved/,
            "Deflate $attr: unsaved";
    }
}

## MOOSE ##

{
    my $moose_obj = Moose::One->new(
        name         => 'one',
        two          => Moose::Two->new( foo => 'two' ),
        custom       => 'foo',
        custom_class => 10,
    );

    test_moose_attr(
        'moose',
        { name => 'one', two => { foo => 'two' } },
        $moose_obj

    );

    test_moose_attr( 'moose_none', {}, bless {}, 'Moose::One' );

    test_moose_attr(
        'moose_name',
        { name => 'one' },
        bless { name => 'one' }, 'Moose::One'
    );

    test_moose_attr(
        'moose_exname',
        { two => { foo => 'two' } },
        bless { two => bless { foo => 'two' }, 'Moose::Two' }, 'Moose::One'
    );

#===================================
    sub test_moose_attr {
#===================================
        my ( $attr, $deflated, $inflated ) = @_;

        ( $de, $in ) = flators($attr);

        cmp_deeply $de->($moose_obj), $deflated, "Deflate $attr";
        cmp_deeply $in->($deflated),  $inflated, "Inflate $attr";
    }
}

## NON-MOOSE ##

{

    note '';
    note "Flation: non_moose_attr";

    ok my $attr = $meta->find_attribute_by_name('non_moose_attr'),
        "Has attr: non_moose_attr";

    throws_ok sub { $tm->find_deflator($attr) }, qr/No deflator found/,
        "Deflator: non_moose_attr";
    throws_ok sub { $tm->find_inflator($attr) }, qr/No inflator found/,
        "Inflator: non_moose_attr";
}

## NOT-DEFINED ##
{
    note '';
    note 'Flation: not_defined_attr';
    ok my $attr = $meta->find_attribute_by_name('not_defined_attr'),
        "Has attr: not_defined_attr";

    throws_ok sub { $tm->find_deflator($attr) }, qr/No deflator found/,
        "Deflator: not_defined_attr";
    throws_ok sub { $tm->find_inflator($attr) }, qr/No inflator found/,
        "Inflator: not_defined_attr";

}

## OTHER ##
{
    note '';
    note 'Flation: custom_attr';

    ( $de, $in ) = flators('custom');
    cmp_deeply $de->(20), 40, "Deflate custom";
    cmp_deeply $in->(50), 25, "Inflate custom";

    note '';
    note 'Flation: custom_class_attr';

    ( $de, $in ) = flators('custom_class');
    cmp_deeply $de->(20),  80, "Deflate custom class";
    cmp_deeply $in->(100), 25, "Inflate custom class";

    note '';
    note 'Flation: no_tc_attr';

    ( $de, $in ) = flators('no_tc');
    cmp_deeply $de->(20), 20, "Deflate no tc";
    cmp_deeply $in->(20), 20, "Inflate no tc";
}

done_testing;

#===================================
sub flators {
#===================================
    my $name = shift;
    $name .= '_attr';

    note '';
    note "Flation: $name";

    ok my $attr = $meta->find_attribute_by_name($name), "Has attr: $name";
    return unless $attr;

    ok my $de = $tm->find_deflator($attr), "Deflator: $name";
    ok my $in = $tm->find_inflator($attr), "Inflator: $name";
    return ( $de, $in );
}

1;
