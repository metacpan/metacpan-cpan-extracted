#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Lite;

BEGIN {
    eval "require Devel::Declare::Parser";
    Test::More->import( skip_all => "Devel::Declare::Parser version >= 0.017 is required for -magic" )
        unless $Devel::Declare::Parser::VERSION gt '0.016';
}

our $CLASS;

BEGIN {
    $CLASS = 'Exporter::Declare::Magic';
    require_ok $CLASS;
}

{

    package Export::Stuff;
    use Exporter::Declare::Magic;
    use Fennec::Lite;

    BEGIN {
        can_ok( __PACKAGE__, qw/
                exports
                default_exports
                import_options
                import_arguments
                export_tag
                export
                gen_export
                default_export
                gen_default_export
                parsed_exports
                parsed_default_exports
                parser
                /
        );
    }

    sub a    { 'a' }
    sub b    { 'b' }
    sub c    { 'c' }
    sub meth { return @_ }

    our $X = 'x';
    our $Y = 'y';
    our $Z = 'z';

    exports qw/ $Y b /;
    default_exports qw/ $X a /;
    import_options qw/xxx yyy/;
    import_arguments qw/ foo bar /;
    export_tag vars => qw/ $X $Y /;
    export_tag subs => qw/ a b /;

    export $Z;
    export c;
    export baz { 'baz' } export eexport export { return @_ }

    my $gen = 0;
    gen_export gexp {
        my $out = $gen++;
        sub { $out }
    }
    gen_default_export defgen {
        my $out = $gen++;
        sub { $out }
    }
}

tests magic_tag => sub {
    # This tests that the magic tag brings in the magic methods as well as the
    # default which is a nested tag.
    can_ok(
        'Export::Stuff', qw/
            export gen_export default_export gen_default_export parser
            parsed_exports parsed_default_exports import exports default_exports
            import_options import_arguments export_tag
            /
    );
};

tests generator => sub {
    Export::Stuff->import(qw/gexp/);
    is( gexp(), 0, "Generated first" );
    Export::Stuff->import(qw/defgen/);
    is( defgen(), 1, "Generated second" );
    Export::Stuff->import( defgen => {-as => 'blah'} );
    is( blah(), 2, "Generated again" );
};

tests tags_options_and_exports => sub {
    is_deeply(
        [sort keys %{Export::Stuff->export_meta->exports}],
        [sort qw/ $Y &b $X &a &Stuff $Z &c &baz &gexp &defgen &eexport /],
        "All exports accounted for"
    );
    is_deeply(
        [sort @{Export::Stuff->export_meta->export_tags->{default}}],
        [sort qw/ $X a defgen /],
        "Default Exports"
    );
    is_deeply(
        [sort @{Export::Stuff->export_meta->export_tags->{all}}],
        [sort qw/ $Y &b $X &a &Stuff $Z &c &baz &gexp &defgen &eexport /],
        "All Exports"
    );
    is_deeply(
        Export::Stuff->export_meta->options,
        {
            xxx => 1,
            yyy => 1,
        },
        "Options"
    );
    is_deeply(
        Export::Stuff->export_meta->arguments,
        {
            foo    => 1,
            bar    => 1,
            prefix => 1,
            suffix => 1,
        },
        "Arguments"
    );

    is_deeply(
        Export::Stuff->export_meta->export_tags,
        {
            alias => ['Stuff'],
            vars  => [qw/ $X $Y /],
            subs  => [qw/ a b /],
            # These are checked elsware
            default => Export::Stuff->export_meta->export_tags->{'default'},
            all     => Export::Stuff->export_meta->export_tags->{all}
        },
        "Extra tags"
    );
};

tests magic_import => sub {

    package MyMagic;
    use strict;
    use warnings;
    use Exporter::Declare::Magic qw/-all/;
    use Fennec::Lite;

    sub xxx { 'xxx' }

    can_ok( __PACKAGE__, qw/
            exports
            default_exports
            import_options
            import_arguments
            export_tag
            export
            gen_export
            default_export
            gen_default_export
            parsed_exports
            parsed_default_exports
            parser
            /
    );

    lives_ok { export a b {} } "export magic";
    lives_ok {
        export b => sub { };
        export c => \&xxx;
        export 'xxx';
    }
    "export magic non-interfering";

    is( __PACKAGE__->export_meta->exports_get('xxx'), \&xxx, "export added" );
};

tests magic_import_args => sub {

    package MyMagic2;
    use strict;
    use warnings;
    use Exporter::Declare::Magic '-default', '-prefix' => "magic_", '!export';
    use Fennec::Lite;

    can_ok( __PACKAGE__, qw/
            magic_exports
            magic_default_exports
            magic_import_options
            magic_import_arguments
            magic_export_tag
            magic_gen_export
            magic_default_export
            magic_gen_default_export
            magic_parsed_exports
            magic_parsed_default_exports
            magic_parser
            /
    );
    ok( !__PACKAGE__->can('export'),       "export() was excluded" );
    ok( !__PACKAGE__->can('magic_export'), "magic_export() was excluded" );
};

run_tests;
done_testing;
