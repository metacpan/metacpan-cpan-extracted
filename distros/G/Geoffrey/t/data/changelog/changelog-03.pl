[{
        author  => 'Mario Zieschang',
        id      => '003.03-maz',
        entries => [{
                action => 'view.add',
                as =>
                    'SELECT "user".guest, "user".pass, "user".salt, "user".locale, "user".last_login, "user".mail, "user".client, "user".flag, "user".active, "user".name, company.name AS company, client.id FROM client, company, "user" WHERE client.id = company.id AND company.id = "user".id AND "user".id = client.id',
                name => 'view_client',
            }]
    },
    {
        author  => 'Mario Zieschang',
        id      => '003.04-maz',
        entries => [{action => 'sql.add', as => 'SELECT * FROM "user"'}]
    },
    {
        author  => 'Mario Zieschang',
        id      => '003.05-maz',
        entries => [{
                action => 'table.alter',
                name   => '"user"',
                alter  => [
                    {action => 'column.add',  type => 'integer', name => 'drop_tes',},
                    {action => 'column.drop', type => 'integer', name => 'drop_tes',}]}]
    },
    {
        author  => 'Mario Zieschang',
        id      => '003.06-maz',
        entries => [
            {action => 'table.add',  name => 'drop_table_test', template => 'tpl_std_client_re',},
            {action => 'table.drop', name => 'drop_table_tes',}]
    },
    {
        author  => 'Mario Zieschang',
        id      => '003.07-maz',
        entries => [{
                action   => 'table.add',
                name     => 'add_foreign_test',
                columns  => [{type => 'integer', name => 'player',}],
                template => 'tpl_std_client_re',
            }]
    },
    {
        author  => 'Mario Zieschang',
        id      => '003.08-maz',
        entries => [{
                action => 'constraint.alter',
                name   => 'add_foreign_test',
                alter  => [
                    {action => 'foreign_key.add', refcolumn => 'id', name => 'player1', reftable => 'tea',}]}
        ]
    },
    {
        author  => 'Mario Zieschang',
        id      => '003.09-maz',
        entries => [{action => 'table.drop', name => 'add_foreign_tes',}]
    },
    {
        author  => 'Mario Zieschang',
        id      => '003.10-maz',
        entries => [{
                action   => 'table.add',
                name     => 'add_unique_test',
                columns  => [{type => 'integer', name => 'player',}],
                template => 'tpl_std_client_re',
            }]
    },
    {
        author  => 'Mario Zieschang',
        id      => '003.11-maz',
        entries => [{
                action => 'table.alter',
                name   => 'add_unique_test',
                alter  => [{
                        action  => 'constraint.unique.add',
                        name    => 'add_unique_test_id_player1',
                        columns => ["id", "player1"]}]}]
    },
    {
        author  => 'Mario Zieschang',
        id      => '003.12-maz',
        entries => [{action => 'table.drop', name => 'add_unique_tes',}]
    },
    {
        author  => 'Mario Zieschang',
        id      => '003.13-maz',
        entries => [{
                action  => 'table.add',
                columns => [
                    {lenght => 50,        type => 'varchar',        name    => 'cent_nam',},
                    {type   => 'integer', name => 'decimal_places', notnull => 1},
                    {lenght => 10,        type => 'varchar',        name    => 'currency_ke',},
                    {lenght => 10,        type => 'varchar',        name    => 'symbo',}
                ],
                template => 'tpl_std',
                name     => 'currencie',
            },
            {
                table  => 'currencies',
                values => [
                    ['Euro',       'cent',   3, 'EUR', '\u20ac'],
                    ['Dollar',     'Cent',   3, 'USD', '$'],
                    ['Swiss fran', 'Rappen', 2, 'CHF', 'CHF']
                ],
                columns => ['name', 'currency_key', 'decimal_places', 'cent_name', 'symbol'],
                type    => 'inser',
            }]}]
