#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use Scalar::Util 'blessed', 'refaddr';

use lib "$FindBin::Bin/../../lib";

use JSORB;
use JSORB::Dispatcher::Path;
use JSORB::Server::Simple;
use JSORB::Server::Traits::WithStaticFiles;
use JSORB::Client::Compiler::Javascript;

use KiokuDB;
use KiokuDB::Backend::Serialize::JSPON::Collapser;

{
    package Person;
    use Moose;
    use MooseX::AttributeHelpers;

    has ['first_name', 'last_name'] => (is => 'rw', isa => 'Str');
    has 'age'      => (is => 'rw', isa => 'Int');
    has 'spouse'   => (is => 'rw', isa => 'Person');

    has ['mother', 'father'] => (
        is        => 'ro',
        isa       => 'Person',
        weak_ref  => 1,
        trigger   => sub {
            my ($self, $parent) = @_;
            $parent->add_child($self);
        }
    );

    has 'children' => (
        metaclass => 'Collection::Array',
        is        => 'rw',
        isa       => 'ArrayRef[Person]',
        default   => sub { [] },
        provides  => {
            'push' => 'add_child'
        }
    );

    has 'car' => (is => 'rw', isa => 'Car');

    package Car;
    use Moose;

    has 'owner' => (
        is       => 'rw',
        isa      => 'Person',
        weak_ref => 1,
        trigger  => sub {
            my ($self, $owner) = @_;
            $owner->car($self);
        }
    );

    has [ 'make', 'model', 'vin' ] => (is => 'rw');
}

my $db = KiokuDB->connect("hash");

my $s = $db->new_scope;

my $homer = Person->new(first_name => 'Homer', last_name => 'Simpson', age => 35);
my $marge = Person->new(first_name => 'Marge', last_name => 'Simpson', age => 32, spouse => $homer);
$homer->spouse($marge);

my $minivan = Car->new(make => 'Toyota', model => 'Sienna', vin => '12345abcdefghijklmno', owner => $marge);
my $volvo   = Car->new(make => 'Volvo', model => 'Sedan', vin => '12345abcdefghijklmno', owner => $homer);

my %parents = (father => $homer, mother => $marge);

my @children = (
    Person->new(first_name => 'Bart',  last_name => 'Simpson', age => 11, %parents),
    Person->new(first_name => 'Lisa',  last_name => 'Simpson', age => 9,  %parents),
    Person->new(first_name => 'Magie', last_name => 'Simpson', age => 1,  %parents),
);

my ($homer_id) = $db->txn_do(sub {
    $db->store( $homer );
});

my $ns = JSORB::Namespace->new(
    name     => 'KiokuDB',
    elements => [
        JSORB::Interface->new(
            name       => 'Navigator',
            procedures => [
                JSORB::Procedure->new(
                    name  => 'lookup',
                    body  => sub {
                        my $id  = shift || $homer_id;
                        my $obj = $db->lookup($id);
                        KiokuDB::Backend::Serialize::JSPON::Collapser
                            ->new
                            ->collapse_jspon(
                                $db->live_objects->object_to_entry(
                                    $obj
                                )
                            );
                    },
                    spec  => [ 'Str' => 'HashRef' ]
                )
            ]
        )
    ]
);

JSORB::Client::Compiler::Javascript->new->compile(
    namespace => $ns,
    to        => [ $FindBin::Bin, 'KiokuDB.js' ]
);

JSORB::Server::Simple->new_with_traits(
    traits     => [
        'JSORB::Server::Traits::WithDebug',
        'JSORB::Server::Traits::WithStaticFiles',
    ],
    doc_root   => [ $FindBin::Bin, '..', '..' ],
    dispatcher => JSORB::Dispatcher::Path->new(
        namespace => $ns,
    )
)->run;

1;
