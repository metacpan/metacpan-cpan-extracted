use strict;
use warnings;
use Test2::V0;

use IO::Async::Pg::Util qw(convert_placeholders);

subtest 'no placeholders' => sub {
    my ($sql, $bind) = convert_placeholders('SELECT * FROM users', {});
    is $sql, 'SELECT * FROM users', 'SQL unchanged';
    is $bind, [], 'no bind values';
};

subtest 'single named placeholder' => sub {
    my ($sql, $bind) = convert_placeholders(
        'SELECT * FROM users WHERE id = :id',
        { id => 42 }
    );
    is $sql, 'SELECT * FROM users WHERE id = $1', 'placeholder converted';
    is $bind, [42], 'bind value extracted';
};

subtest 'multiple named placeholders' => sub {
    my ($sql, $bind) = convert_placeholders(
        'SELECT * FROM users WHERE name = :name AND age > :age',
        { name => 'Alice', age => 21 }
    );
    is $sql, 'SELECT * FROM users WHERE name = $1 AND age > $2', 'placeholders converted';
    is $bind, ['Alice', 21], 'bind values in order of appearance';
};

subtest 'repeated placeholder' => sub {
    my ($sql, $bind) = convert_placeholders(
        'SELECT * FROM t WHERE a = :foo AND b = :bar AND c = :foo',
        { foo => 1, bar => 2 }
    );
    is $sql, 'SELECT * FROM t WHERE a = $1 AND b = $2 AND c = $1', 'repeated placeholder reuses number';
    is $bind, [1, 2], 'only unique values in bind array';
};

subtest 'placeholder with underscore' => sub {
    my ($sql, $bind) = convert_placeholders(
        'SELECT * FROM users WHERE user_id = :user_id',
        { user_id => 123 }
    );
    is $sql, 'SELECT * FROM users WHERE user_id = $1', 'underscore in placeholder name';
    is $bind, [123], 'bind value';
};

subtest 'placeholder at end of statement' => sub {
    my ($sql, $bind) = convert_placeholders(
        'UPDATE users SET active = :active',
        { active => 1 }
    );
    is $sql, 'UPDATE users SET active = $1', 'placeholder at end';
    is $bind, [1], 'bind value';
};

subtest 'numeric placeholder values' => sub {
    my ($sql, $bind) = convert_placeholders(
        'INSERT INTO t (a, b, c) VALUES (:a, :b, :c)',
        { a => 1, b => 2.5, c => 0 }
    );
    is $sql, 'INSERT INTO t (a, b, c) VALUES ($1, $2, $3)', 'placeholders converted';
    is $bind, [1, 2.5, 0], 'numeric values preserved';
};

subtest 'undef value' => sub {
    my ($sql, $bind) = convert_placeholders(
        'UPDATE users SET name = :name WHERE id = :id',
        { name => undef, id => 1 }
    );
    is $sql, 'UPDATE users SET name = $1 WHERE id = $2', 'placeholders converted';
    is $bind, [undef, 1], 'undef preserved in bind array';
};

subtest 'string with colon that is not a placeholder' => sub {
    my ($sql, $bind) = convert_placeholders(
        q{SELECT '10:30' AS time, id FROM t WHERE name = :name},
        { name => 'test' }
    );
    is $sql, q{SELECT '10:30' AS time, id FROM t WHERE name = $1}, 'colon in string preserved';
    is $bind, ['test'], 'only actual placeholder extracted';
};

subtest 'cast syntax preserved' => sub {
    my ($sql, $bind) = convert_placeholders(
        'SELECT :val::integer',
        { val => 42 }
    );
    is $sql, 'SELECT $1::integer', 'PostgreSQL cast syntax preserved';
    is $bind, [42], 'bind value';
};

subtest 'empty hash' => sub {
    my ($sql, $bind) = convert_placeholders(
        'SELECT 1',
        {}
    );
    is $sql, 'SELECT 1', 'SQL unchanged';
    is $bind, [], 'empty bind array';
};

subtest 'positional placeholders pass through' => sub {
    my ($sql, $bind) = convert_placeholders(
        'SELECT * FROM users WHERE id = $1',
        {}
    );
    is $sql, 'SELECT * FROM users WHERE id = $1', 'positional placeholder unchanged';
    is $bind, [], 'no bind values';
};

done_testing;
