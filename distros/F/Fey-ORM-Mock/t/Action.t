use strict;
use warnings;

use Test::Exception;
use Test::More;

use Fey::ORM::Mock::Action;

{

    package Foo;

    use Moose;
}

{
    my $insert = Fey::ORM::Mock::Action->new_action(
        action => 'insert',
        class  => 'Foo',
        values => {},
    );

    ok(
        $insert->is_insert(),
        'is_insert is true for insert'
    );
    ok(
        !$insert->is_update(),
        'is_update is false for insert'
    );
    ok(
        !$insert->is_delete(),
        'is_delete is false for insert'
    );
}

{
    my $update = Fey::ORM::Mock::Action->new_action(
        action => 'update',
        class  => 'Foo',
        pk     => {},
        values => {},
    );

    ok(
        !$update->is_insert(),
        'is_insert is flase for update'
    );
    ok(
        $update->is_update(),
        'is_update is true for update'
    );
    ok(
        !$update->is_delete(),
        'is_delete is false for update'
    );
}

{
    my $delete = Fey::ORM::Mock::Action->new_action(
        action => 'delete',
        class  => 'Foo',
        pk     => {},
    );

    ok(
        !$delete->is_insert(),
        'is_insert is flase for delete'
    );
    ok(
        !$delete->is_update(),
        'is_update is false for delete'
    );
    ok(
        $delete->is_delete(),
        'is_delete is true for delete'
    );
}

done_testing();
