[
    {
        author  => 'Mario Zieschang',
        id      => '002.01-maz',
        entries => [
            {
                action  => 'table.add',
                name    => '"user"',
                columns => [
                    {
                        default => 'current',
                        lenght  => 255,
                        type    => 'varchar',
                        name    => 'mail',
                        notnull => 1
                    },
                    {
                        default => 'current',
                        type    => 'timestamp',
                        name    => 'last_login'
                    },
                    {
                        type => 'char',
                        name => 'locale'
                    },
                    {
                        default => 'current',
                        lenght  => 255,
                        type    => 'varchar',
                        name    => 'salt',
                        notnull => 1
                    },
                    {
                        default => 'current',
                        lenght  => 255,
                        type    => 'varchar',
                        name    => 'pass',
                        notnull => 1
                    }
                ],
                template => 'tpl_std_client_ref'
            },
            {
                action  => 'table.add',
                name    => 'player',
                columns => [
                    {
                        default => 'current',
                        lenght  => 255,
                        type    => 'varchar',
                        name    => 'surname',
                        notnull => 1
                    }
                ],
                template => 'tpl_std_company_ref'
            }
        ]
    },
    {
        author  => 'Mario Zieschang',
        id      => '002.02-maz',
        entries => [
            {
                action  => 'table.add',
                name    => 'team',
                columns => [
                    {
                        notnull    => 1,
                        type       => 'integer',
                        name       => 'player1',
                        foreignkey => {
                            refcolumn => 'id',
                            reftable  => 'player'
                        }
                    },
                    {
                        notnull    => 1,
                        type       => 'integer',
                        name       => 'player2',
                        foreignkey => {
                            refcolumn => 'id',
                            reftable  => 'player'
                        }
                    }
                ],
                template => 'tpl_std_company_ref'
            },
            {
                action  => 'table.add',
                name    => 'match_player',
                columns => [
                    {
                        notnull    => 1,
                        type       => 'integer',
                        name       => 'player1',
                        foreignkey => {
                            refcolumn => 'id',
                            reftable  => 'player'
                        }
                    },
                    {
                        notnull    => 1,
                        type       => 'integer',
                        name       => 'player2',
                        foreignkey => {
                            refcolumn => 'id',
                            reftable  => 'player'
                        }
                    },
                    {
                        type => 'integer',
                        name => 'player1_ht1'
                    },
                    {
                        default => 0,
                        type    => 'integer',
                        name    => 'player1_ht2',
                        notnull => 1
                    },
                    {
                        type => 'integer',
                        name => 'player2_ht1'
                    },
                    {
                        default => 0,
                        type    => 'integer',
                        name    => 'player2_ht2',
                        notnull => 1
                    },
                    {
                        type => 'integer',
                        name => 'duration'
                    }
                ],
                template => 'tpl_std_company_ref'
            },
            {
                action  => 'table.add',
                name    => 'match_team',
                columns => [
                    {
                        notnull    => 1,
                        type       => 'integer',
                        name       => 'team1',
                        foreignkey => {
                            refcolumn => 'id',
                            reftable  => 'team'
                        }
                    },
                    {
                        notnull    => 1,
                        type       => 'integer',
                        name       => 'team2',
                        foreignkey => {
                            refcolumn => 'id',
                            reftable  => 'team'
                        }
                    },
                    {
                        type => 'integer',
                        name => 'team1_ht1'
                    },
                    {
                        default => 0,
                        type    => 'integer',
                        name    => 'team1_ht2',
                        notnull => 1
                    },
                    {
                        type => 'integer',
                        name => 'team2_ht1'
                    },
                    {
                        default => 0,
                        type    => 'integer',
                        name    => 'team2_ht2',
                        notnull => 1
                    },
                    {
                        type => 'integer',
                        name => 'duration'
                    }
                ],
                template => 'tpl_std_company_ref'
            },
            {
                action => 'constraint.index.add',
                table  => 'match_team',
                column => 'id',
                using  => 'btree',
                name   => 'index_test'
            },
            {
                action => 'table.alter',
                name   => '"user"',
                alter  => [
                    {
                        action => 'column.add',
                        type   => 'integer',
                        name   => 'guest'
                    }
                ]
            }
        ]
    }
]
