use Import::Box -as => 't2', 'Test2::Bundle::Extended';

t2->ok(!Import::Box->isa('Tx'), "Import::Box isa() does not give false positives");

t2->isa_ok('Import::Box', ['Import::Box'], "Import::Box isa() still works");

t2->isa_ok(t2(), [qw/Import::Box/], "isa does not defer to the stash");

t2->done_testing;
