{
    templates => [
        {
            name    => 'tpl_minimal',
            columns => [
                {
                    default    => 'autoincrement',
                    notnull    => 1,
                    type       => 'integer',
                    primarykey => 1,
                    name       => 'id'
                },
                {
                    default => 1,
                    type    => 'bool',
                    name    => 'active'
                }
            ]
        },
        {
            name    => 'tpl_std',
            columns => [
                {
                    default => 'current',
                    type    => 'varchar',
                    name    => 'name',
                    notnull => 1
                },
                {
                    default => 'current',
                    type    => 'timestamp',
                    name    => 'flag',
                    notnull => 1
                }
            ],
            template => 'tpl_minimal'
        },
        {
            name    => 'tpl_std_client_ref',
            columns => [
                {
                    notnull    => 1,
                    type       => 'integer',
                    name       => 'client',
                    foreignkey => {
                        refcolumn => 'id',
                        reftable  => 'client'
                    }
                }
            ],
            template => 'tpl_std'
        },
        {
            name    => 'tpl_minimal_client_ref',
            columns => [
                {
                    notnull    => 1,
                    type       => 'integer',
                    name       => 'client',
                    foreignkey => {
                        refcolumn => 'id',
                        reftable  => 'client'
                    }
                }
            ],
            template => 'tpl_minimal'
        },
        {
            name    => 'tpl_std_company_ref',
            columns => [
                {
                    notnull    => 1,
                    type       => 'integer',
                    name       => 'company',
                    foreignkey => {
                        refcolumn => 'id',
                        reftable  => 'company'
                    }
                }
            ],
            template => 'tpl_std_client_ref'
        }
    ],
    changelogs => [ '01', '02', '03' ]
}
