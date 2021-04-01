#! perl


use Test2::V0;

use Hash::Wrap ();

my $HAS_LVALUE;

BEGIN {

    $HAS_LVALUE = $] ge '5.01600';
}


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
    qr/cannot mix -copy and -clone/,
    'copy + clone'
);

like(
    dies {
        Hash::Wrap->import( { -base => 1, -class => 1 } )
    },
    qr/cannot mix -base and -class/,
    'base + class'
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


{

    package My::StandAlone::Class;

    use Hash::Wrap ( { -base => 1, -undef => 1 } );

}

is( My::StandAlone::Class->new( { } )->b, undef, "standalone class" );

{

    package My::Test::No::Sub;

    use Hash::Wrap ( { -class => 'My::Test::No::Sub::Class', -new => 1, -as => undef, -undef => 1 } );

}

is( My::Test::No::Sub::Class->new( { } )->b, undef, "standalone class" );
{ no warnings 'once';
  is ( *My::Test::No::Sub::wrap_hash{CODE}, undef, "stopping import of wrap_hash works" );
}

{
    package My::Test::ClassName;

    use Hash::Wrap ( { -class => '-caller', -new => 1, -as => 'wrapit', -undef => 1 } );

}

ref_ok( *My::Test::ClassName::wrapit{CODE}, 'CODE', "standalone class" );
isa_ok( My::Test::ClassName::wrapit(), [ 'My::Test::ClassName::wrapit' ], '-class => -caller' );

SKIP: {
    skip( ":lvalue support requires perl 5.16 or later" )
      unless $HAS_LVALUE;

    {
        package My::Import::Default::LValue;

        use if $HAS_LVALUE, 'Hash::Wrap', ( { -base => 1, -lvalue => 1 } );
    }

    is( $My::Import::Default::LValue::meta->{-lvalue}, 1, "lvalue");
}

done_testing;
