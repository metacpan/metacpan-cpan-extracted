#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;
use Test::Deep;
use Scalar::Util qw(refaddr);

use lib 't/lib';

our $es;
do 'es.pl';

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
ok my $ns = $model->namespace('myapp'), 'Got ns';

ok $ns->index('myapp')->create, 'Create index myapp';

isa_ok my $domain = $model->domain('myapp'), 'Elastic::Model::Domain',
    'Got domain myapp';

isa_ok my $u1
    = $domain->create(
    user => { id => 1, name => 'Clint', email => 'clint@foo' } ),
    'MyApp::User', 'Create U1';
isa_ok my $u2 = $domain->get( user => 1 ), 'MyApp::User', 'Get U2';
ok refaddr $u1 ne refaddr $u2, 'U1 and U2 are separate objects';

is $u1->name('John'), 'John', 'Set U1.name to John';
ok $u1->save, 'U1 updated';
is $u2->name(), 'Clint', 'U2.name is Clint';
is $u1->uid->version, 2, 'U1 has version 2';
is $u2->uid->version, 1, 'U2 has version 1';

is $u2->email('john@foo'), 'john@foo', 'Set U2.email to john@foo';
eval { $u2->save };

throws_ok sub { $u2->save }, qr/\[Conflict\]/,
    'Save U2 throws conflict error';
ok $u2->save( on_conflict => \&on_conflict ), 'On conflict with diff version';

# Conflicts with new docs

isa_ok my $u3 = $domain->new_doc( user => { id => 1, name => 'Bob' } ),
    'MyApp::User', 'U3';
throws_ok sub { $u3->save }, qr/DocumentAlreadyExistsException/,
    'Error saving existing UID';
ok $u3->save( on_conflict => \&on_conflict_2 ), 'On_conflict with new doc';
ok $u3->overwrite, 'Overwrite new doc';
is $u3->uid->version, 4, 'U3 has version 4';

#===================================
sub on_conflict {
#===================================
    my ( $old, $new ) = @_;
    is $old->has_changed, 1, 'Old has changed';
    is $old->has_changed('email'), 1,  'Old email has changed';
    is $old->has_changed('name'),  '', 'Old name has not changed';
    my $old_values = $old->old_values;
    cmp_deeply [ sort keys %$old_values ], [ 'email', 'timestamp' ],
        'Old values keys';
    is $new->has_changed(), '', 'New not changed';
    cmp_deeply $new->old_values, {}, 'New old values';

    is $old->uid->version, 1, 'Old is v1';
    is $new->uid->version, 2, 'New is v2';
    ok $old->overwrite, 'Overwrite';
    is $old->uid->version, 3, 'Old is v3';

}

#===================================
sub on_conflict_2 {
#===================================
    my ( $old, $new ) = @_;
    cmp_deeply( $old, $u3, 'Old version is U3' );
    cmp_deeply( $new->uid, $u2->uid ), 'New version is U2';
}

## DONE ##

done_testing;

__END__
