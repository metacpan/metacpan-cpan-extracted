use strict;
use warnings;
use Test::More;
use blib;

use Legba qw/lockable freezable/;

# === Lock tests ===

subtest 'lock prevents set' => sub {
    lockable('initial');
    is(lockable(), 'initial', 'value set before lock');

    Legba::_lock('lockable');
    ok(Legba::_is_locked('lockable'), '_is_locked returns true');

    eval { lockable('changed') };
    like($@, qr/locked/, 'set on locked slot croaks');
    is(lockable(), 'initial', 'value unchanged after failed set');

    eval { Legba::_set('lockable', 'changed') };
    like($@, qr/locked/, '_set on locked slot croaks');

    eval { Legba::_delete('lockable') };
    like($@, qr/locked/, '_delete on locked slot croaks');
};

subtest 'unlock allows set again' => sub {
    Legba::_unlock('lockable');
    ok(!Legba::_is_locked('lockable'), '_is_locked returns false after unlock');

    lockable('updated');
    is(lockable(), 'updated', 'set works after unlock');
};

# === Freeze tests ===

subtest 'freeze prevents set permanently' => sub {
    freezable('frozen_value');
    is(freezable(), 'frozen_value', 'value set before freeze');

    Legba::_freeze('freezable');
    ok(Legba::_is_frozen('freezable'), '_is_frozen returns true');

    eval { freezable('changed') };
    like($@, qr/frozen/, 'set on frozen slot croaks');
    is(freezable(), 'frozen_value', 'value unchanged after failed set');

    eval { Legba::_set('freezable', 'changed') };
    like($@, qr/frozen/, '_set on frozen slot croaks');

    eval { Legba::_delete('freezable') };
    like($@, qr/frozen/, '_delete on frozen slot croaks');
};

subtest 'frozen slot cannot be unlocked' => sub {
    eval { Legba::_unlock('freezable') };
    like($@, qr/frozen/, 'unlock on frozen slot croaks');

    eval { Legba::_lock('freezable') };
    like($@, qr/frozen/, 'lock on frozen slot croaks');
};

subtest 'frozen slot still readable' => sub {
    is(freezable(), 'frozen_value', 'get still works on frozen slot');
    is(Legba::_get('freezable'), 'frozen_value', '_get still works on frozen slot');
};

# === _clear respects lock/freeze ===

subtest '_clear skips locked and frozen' => sub {
    use Legba qw/clearable/;
    clearable('will_be_cleared');

    Legba::_clear();

    is(freezable(), 'frozen_value', 'frozen slot survives _clear');
    ok(!defined clearable(), 'unlocked slot cleared by _clear');
};

# === Edge cases ===

subtest 'lock/freeze on non-existent slot croaks' => sub {
    eval { Legba::_lock('nonexistent') };
    like($@, qr/non-existent/, 'lock on non-existent croaks');

    eval { Legba::_freeze('nonexistent') };
    like($@, qr/non-existent/, 'freeze on non-existent croaks');
};

subtest 'is_locked/is_frozen on non-existent returns false' => sub {
    ok(!Legba::_is_locked('nonexistent'), '_is_locked false for non-existent');
    ok(!Legba::_is_frozen('nonexistent'), '_is_frozen false for non-existent');
};

done_testing();
