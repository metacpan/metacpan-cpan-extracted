use Import::Box -as => 't2', 'Test2::Bundle::Extended';

t2->ok(!Import::Box->can('ok'), "Import::Box can() does not give false positives");
t2->ok(Import::Box->can('import'), "Import::Box can() still works");
t2->ok(t2->can('ok'), "can() on the object t2() returns gives us the function");

t2->done_testing;
