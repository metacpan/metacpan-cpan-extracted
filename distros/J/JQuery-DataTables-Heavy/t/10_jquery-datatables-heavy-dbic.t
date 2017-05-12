#/usr/bin/env perl
use lib '.';
use t::Utils;
use Test::More;
use Test::Exception;
use Test::Mock::Guard qw(mock_guard);

BEGIN{
    use_ok('JQuery::DataTables::Heavy::DBIC');
}

{
    my $guard1 = mock_guard( 'DBIx::Class::Schema', { new => sub { bless {} => shift}});
    my $guard2 = mock_guard( 'DBIx::Class::ResultSet', { new => sub { bless {} => shift}});
    my $dbh = DBIx::Class::Schema->new;
    my $rs = DBIx::Class::ResultSet->new;

    subtest 'new' => sub {
        throws_ok { JQuery::DataTables::Heavy::DBIC->new } qr/dbh,\sparam,\stable/, 'required params';
        throws_ok { JQuery::DataTables::Heavy::DBIC->new({
                    dbh => bless({}, 'dbh'),
                    table => 'table',
                    param => {},
                })}  qr/DBIx::Class::Schema/, q{'dbh' validation};
        throws_ok { JQuery::DataTables::Heavy::DBIC->new({
                    dbh => $dbh,
                    table => 'table',
                    param => 'param',
                })}  qr/HashRef/, q{'param' validation};
    };

    my $attr = {
        param => {},
        dbh   => $dbh,
        table => $rs,
    };

    test__hashed_has_many($attr, ['hoge'], { hoge => 'hoge' });
    test__hashed_has_many($attr, 
        ['hoge', { foo => 'bar'}, {fuga => ['a', 'b', { c => 'd'} ]} ],
        {
            hoge => 'hoge',
            'foo.bar' => {foo => 'bar'},
            'fuga.a'  => {fuga => 'a'},
            'fuga.b'  =>{fuga => 'b'},
            'fuga.c.d' => { fuga => { c => 'd'}},
        },
    );
    {
        my $guard3 = mock_guard( 'JQuery::DataTables::Heavy::DBIC', { where_fields => sub {['hoge.col1', 'fuga.col2']}});
        test__generate_prefetch_clause_for_where_clause($attr, ['hoge'], 'hoge');
        test__generate_prefetch_clause_for_where_clause($attr, 
            ['hoge', { foo => 'bar'}, {fuga => ['a', 'b', { c => 'd'} ]} ],
            'hoge',
        );
    }
    {
        my $guard3 = mock_guard( 'JQuery::DataTables::Heavy::DBIC', { where_fields => sub {['hoge.col1', 'fuga.a.col2', 'fuga.b.col3']}});
        test__generate_prefetch_clause_for_where_clause($attr, 
            ['hoge', { foo => 'bar'}, {fuga => ['a', 'b', { c => 'd'} ]} ],
            [{fuga => ['a', 'b']}, 'hoge'],
        );
    }
    {
        my $guard3 = mock_guard( 'JQuery::DataTables::Heavy::DBIC', { where_fields => sub {['hoge.col1', 'fuga.a.col2', 'fuga.b.col3', 'fuga.c.d.col4']}});
        test__generate_prefetch_clause_for_where_clause($attr,
            ['hoge', { foo => 'bar'}, {fuga => ['a', 'b', { c => 'd'} ]} ],
            [{fuga => ['a', 'b', { c => 'd'}]}, 'hoge'],
        );
    }
    {
        my $guard3 = mock_guard( 'JQuery::DataTables::Heavy::DBIC', { where_fields => sub {['hoge.col1', 'fuga.c.d.col4']}});
        test__generate_prefetch_clause_for_where_clause($attr,
            ['hoge', { foo => 'bar'}, {fuga => ['a', 'b', { c => 'd'} ]} ],
            [{fuga => { c => 'd'}}, 'hoge'],
        );
    }
    t::Utils->base_test(
        JQuery::DataTables::Heavy::DBIC->new($attr),
        'v1_9.dat',
    );
}

sub test__generate_prefetch_clause_for_where_clause {
    my ($attr, $has_many, $result) = @_;
    $attr->{has_many} = $has_many;
    my $dt = JQuery::DataTables::Heavy::DBIC->new($attr);
    is_deeply($dt->_generate_prefetch_clause_for_where_clause, $result, '_generate_prefetch_clause_for_where_clause') or diag explain $dt->_generate_prefetch_clause_for_where_clause;
}
sub test__hashed_has_many {
    my ($attr, $has_many, $result) = @_;
    $attr->{has_many} = $has_many;
    my $dt = JQuery::DataTables::Heavy::DBIC->new($attr);
    is_deeply($dt->_hashed_has_many, $result, '_hashed_has_many') or diag explain $dt->_hashed_has_many;

}

done_testing;
