#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Lite;
use aliased 'Exporter::Declare::Meta';
use aliased 'Exporter::Declare::Specs';
use aliased 'Exporter::Declare::Export::Sub';
use aliased 'Exporter::Declare::Export::Variable';

our $CLASS;
our @IMPORTS;
BEGIN {
    @IMPORTS = qw/
        export gen_export default_export gen_default_export import export_to
        exports default_exports reexport import_options import_arguments
        export_tag
    /;

    $CLASS = "Exporter::Declare";
    require_ok $CLASS;
    $CLASS->import( '-alias', @IMPORTS );
}

sub xxx {'xxx'}

tests package_usage => sub {
    can_ok( $CLASS, 'export_meta' );
    can_ok( __PACKAGE__, @IMPORTS, 'Declare' );
    can_ok( __PACKAGE__, 'export_meta' );

    is( Declare(), $CLASS, "Aliased" );

    is_deeply(
        [ sort( Declare()->exports )],
        [ sort map {"\&$_" } @IMPORTS, 'Declare' ],
        "Export list"
    );

    is_deeply(
        [ sort( Declare()->default_exports )],
        [ sort qw/
            exports default_exports import import_options import_arguments
            export_tag default_export export gen_export gen_default_export
        /],
        "Default Exports"
    );
};

{
    package Export::Stuff;
    use Exporter::Declare;

    sub a    { 'a'       }
    sub b    { 'b'       }
    sub c    { 'c'       }
    sub meth { return @_ }

    our $X = 'x';
    our $Y = 'y';
    our $Z = 'z';

    exports qw/ $Y b /;
    default_exports qw/ $X a /;
    import_options qw/xxx yyy/;
    import_arguments qw/ foo bar /;
    export_tag vars => qw/ $X $Y @P /;
    export_tag subs => qw/ a b /;

    export '$Z';
    export '@P' => [ 'a', 'x' ];
    export 'c';
    export baz => sub { 'baz' };

    my $gen = 0;
    gen_export gexp => sub { my $out = $gen++; sub { $out }};
    gen_default_export defgen => sub { my $out = $gen++; sub { $out }};
}

tests generator => sub {
    Export::Stuff->import(qw/gexp/);
    is( gexp(), 0, "Generated first" );
    Export::Stuff->import(qw/defgen/);
    is( defgen(), 1, "Generated second" );
    Export::Stuff->import( defgen => { -as => 'blah' });
    is( blah(), 2, "Generated again" );
};

tests tags_options_and_exports => sub {
    is_deeply(
        [ sort keys %{ Export::Stuff->export_meta->exports }],
        [ sort qw/ $Y &b $X &a &Stuff $Z &c &baz &gexp &defgen @P /],
        "All exports accounted for"
    );
    is_deeply(
        [ sort @{ Export::Stuff->export_meta->export_tags->{default} }],
        [ sort qw/ $X a defgen /],
        "Default Exports"
    );
    is_deeply(
        [ sort @{ Export::Stuff->export_meta->export_tags->{all} }],
        [ sort qw/ $Y &b $X &a &Stuff $Z &c &baz &gexp &defgen @P /],
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
            foo => 1,
            bar => 1,
            prefix => 1,
            suffix => 1,
        },
        "Arguments"
    );

    is_deeply(
        Export::Stuff->export_meta->export_tags,
        {
            alias => [ 'Stuff' ],
            vars => [qw/ $X $Y @P /],
            subs => [qw/ a b /],
            # These are checked elsware
            default => Export::Stuff->export_meta->export_tags->{'default'},
            all => Export::Stuff->export_meta->export_tags->{all}
        },
        "Extra tags"
    );

    isa_ok( Export::Stuff->export_meta->exports_get( '@P' ), 'ARRAY' );
    is_deeply(
        [@{ Export::Stuff->export_meta->exports_get( '@P' ) }],
        [ 'a', 'x' ],
        "\@P Is what we expect"
    );
};

run_tests;
done_testing;
