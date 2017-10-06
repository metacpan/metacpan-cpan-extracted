#! perl


use Test2::V0;

use Hash::Wrap ();


like(
    dies {
        Hash::Wrap->import( 'not_exported' )
    },
    qr/not_exported is not exported/,
    'not exported'
);

like(
    dies {
        Hash::Wrap->import( { -bad_option => 1 } )
    },
    qr/unknown option/,
    'bad option'
);

like(
    dies {
        Hash::Wrap->import( { -copy => 1, -clone => 1 } )
    },
    qr/cannot mix/,
    'copy + clone'
);

{
    package My::Import::Default;

    use Hash::Wrap;
}

ref_ok( *My::Import::Default::wrap_hash{CODE}, 'CODE', "default import" );

{
    package My::Import::As;

    use Hash::Wrap ( { -as => 'foo' } );

}

ref_ok( *My::Import::As::foo{CODE}, 'CODE', "rename" );

{
    package My::Import::CloneNoRename;

    use Hash::Wrap ( { -clone => 1 } );

}
ref_ok( *My::Import::CloneNoRename::wrap_hash{CODE},
    'CODE', "clone, no rename" );


SKIP: {
    skip( ":lvalue support requires perl 5.16 or later" )
      if $] lt '5.016000';

    {
        package My::Import::Default::LValue;

        use if $] ge '5.01600', 'Hash::Wrap',  ( { -lvalue => 1 } );
    }

    isa_ok(
        My::Import::Default::LValue::wrap_hash( {} ),
        ['Hash::Wrap::Class::LValue'],
        "default w/ lvalue"
    );

    {
        package My::Import::Bad::LValue;

        use parent 'Hash::Wrap::Base';
    }

    like(
        dies {
            Hash::Wrap->import(
                { -class => 'My::Import::Bad::LValue', -lvalue => 1 } )
        },
        qr/does not add ':lvalue'/,
        'bad lvalue class'
    );


    {
        package My::Import::Good::LValue;

        use if $] ge '5.01600', parent => 'Hash::Wrap::Class::LValue';
    }

    ok(
        lives {
            Hash::Wrap->import( {
                    -class  => 'My::Import::Good::LValue',
                    -lvalue => 1
                } )
        },
        'good lvalue class'
    ) or note $@;


}

done_testing;
