#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN {
    use_ok('Locale::Maketext::Lexicon::Slurp');
}

use Path::Class;

my $t_dir;
BEGIN { $t_dir = Path::Class::file( __FILE__ )->parent };

{
	package Foo::I18N;
	use base 'Locale::Maketext';

	use Locale::Maketext::Lexicon {
        en => [ Slurp => [ $t_dir->subdir("files", "en"), regex => qr{(^|/)(hello|cat)$} ] ],
        de => [ Slurp => [ $t_dir->subdir("files", "de"), regex => qr{(^|/)(hello|cat)$} ] ],
        es => [ Slurp => [ $t_dir->subdir("files", "de"), files => "*ll*" ] ],
        ru => [ Slurp => [ $t_dir->subdir("files"), files => ::file("de","*ll*") ] ],
        pt => [ Slurp => [ $t_dir->file("files","de","*at") ] ],
        zh => [ Slurp => [ $t_dir->subdir("files"), files => [ ::file("en","hello"), ::file("de","cat") ] ] ],
        he => [ Slurp => [ files => [ $t_dir->file("files","de","cat"), $t_dir->file("files","en","hello") ] , filter => sub { 1 } ] ],
        # this mode is broken
        '*' => [ Slurp => $t_dir->file("files","others","*","foo")->stringify ],
    };
}

my $en = Foo::I18N->get_handle("en");
my $de = Foo::I18N->get_handle("de");

ok( $en, "handle" );
ok( $de, "handle" );

like( $en->maketext( "hello" ), qr/^hello$/, "hello" );
like( $de->maketext( "hello" ), qr/^hallo$/, "hello" );

like( $en->maketext( "cat" ), qr/^cat$/, "cat" );
like( $de->maketext( "cat" ), qr/^katze$/, "cat" );

ok( !eval{ $en->maketext("dog") }, "no dog" );
ok( !eval{ $de->maketext("dog") }, "no dog" );

like( eval { Foo::I18N->get_handle("es")->maketext("hello") }, qr/^hallo$/, "glob in dir" );
is( eval { Foo::I18N->get_handle("es")->maketext("cat") }, undef, "glob in dir" );
is( eval { Foo::I18N->get_handle("ru")->maketext("hello") }, undef, "glob in dir" );
like( eval { Foo::I18N->get_handle("ru")->maketext("de/hello") }, qr/^hallo$/, "glob in dir" );

like( eval { Foo::I18N->get_handle("pt")->maketext("cat") }, qr/^katze$/, "just a glob" );

like( eval { Foo::I18N->get_handle("zh")->maketext("de/cat") }, qr/^katze$/, "explicit files under dir" );
like( eval { Foo::I18N->get_handle("zh")->maketext("en/hello") }, qr/^hello$/, "explicit files under dir" );
is( eval { Foo::I18N->get_handle("zh")->maketext("cat") }, undef, "explicit files under dir" );

like( eval { Foo::I18N->get_handle("he")->maketext("cat") }, qr/^katze$/, "explicit files" );
like( eval { Foo::I18N->get_handle("he")->maketext("hello") }, qr/^hello$/, "explicit files" );

{
    local $TODO = "L::M::L is weird about this";
    close STDERR;

    like( eval { Foo::I18N->get_handle("fr")->maketext("foo") }, qr/^foo_fr$/, "magic lang globbing" );
    like( eval { Foo::I18N->get_handle("fr")->maketext("foo") }, qr/^foo_fr$/, "magic lang globbing" );
    like( eval { Foo::I18N->get_handle("fi")->maketext("bar") }, qr/^bar_fi$/, "magic lang globbing" );
    like( eval { Foo::I18N->get_handle("fi")->maketext("bar") }, qr/^bar_fi$/, "magic lang globbing" );
}
