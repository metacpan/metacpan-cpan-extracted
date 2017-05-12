#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;
use Test::Deep;

use lib 't/lib';

our $es;
do 'es.pl';

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
isa_ok my $index = $model->namespace('myapp')->index, 'Elastic::Model::Index';
isa_ok my $domain = $model->domain('myapp'), 'Elastic::Model::Domain';
isa_ok my $bulk = $model->bulk( size => 10 ), 'Elastic::Model::Bulk';

ok $index->create, 'Create index myapp';
my @users = map { $domain->new_doc( user => $_ ) } (
    { id => 1, user => 'one' },
    { id => 2, user => 'two' },
    { id => 3, user => 'three' },
    { id => 4, user => 'four' },
);

$bulk->save($_) for @users;
$bulk->commit;

for ( 1 .. 2 ) {
    $domain->get( user => $_ )->touch->save;
}

my ( $conflicts, $errors, $error );

test_bulk( on_conflict => \&on_conflict, on_error => \&on_error );
ok $conflicts== 2 && $errors == 0 && !$error,
    'on_conflict: 2 conflicts, 0 errors, no error';

test_bulk( on_error => \&on_error );
ok $conflicts== 0 && $errors == 2 && !$error,
    'on_error: 0 conflicts, 2 errors, no error';

test_bulk();
ok $conflicts== 0 && $errors == 0 && $error,
    'no handler: 0 conflicts, 0 errors, has error';

#===================================
sub test_bulk {
#===================================
    my %args = @_;
    $conflicts = 0;
    $errors    = 0;
    my $bulk = $model->bulk( size => 10, %args );

    # version conflict
    $bulk->save( $users[0] );

    # version no conflict
    $bulk->overwrite( $users[1] );

    # exists conflict
    $bulk->save( $domain->new_doc( user => { id => 3, name => 'three' } ) );

    # exists no conflict
    $bulk->overwrite(
        $domain->new_doc( user => { id => 4, name => 'four' } ) );

    eval { $bulk->commit };
    $error = $@;
}

#===================================
sub on_conflict {
#===================================
    my ( $old, $new ) = @_;
    $conflicts++;
}

#===================================
sub on_error {
#===================================
    my ( $old, $error ) = @_;
    $errors++;
}

## DONE ##

done_testing;

__END__
