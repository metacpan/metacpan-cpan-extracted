#!/usr/bin/env perl 

use t::setup;
use_ok my $MODULE = __TEST_PACKAGE__;

use Capture::Tiny qw(capture);

my $EXPORTER_VERSION = Exporter->VERSION();
my $IMPORT_EXCEPTION = qr/Can't continue after import errors/;
my $IMPORT_WARNING   = qr/is not defined in \S+::EXPORT_TAGS/;

run_tests();

sub happy_import_tests {

    my @proxies = qw(
        Carp
        Cwd
        Data::Dump
        File::Basename
        Scalar::Util
    );

    my @submodules = qw(
        assert
        carp
        debug
        foreign
        list
        misc
        objects
        overload
        package
        paths
        syntax
    );

    my @mods = (all => @submodules, @proxies);

    for my $tag (map ":$_", @mods) {
        ok(eval { $MODULE->import("$tag"); 1 }, "use $MODULE qw($tag);")
            || diag "couldn't import $tag from $MODULE: $@";
    }

}


sub evil_vars_tests {
    my @evil_vars = qw(
        $VERSION 
        @ISA 
        @INC 
        @EXPORTS
    );

    for my $var (@evil_vars) { 
        ok !eval { $MODULE->import($var); 1 }   => "cannot import evil var $var";
        like $@ => $IMPORT_EXCEPTION            => "importing evil sub $var throws $IMPORT_EXCEPTION";
    }
}

sub evil_subs_tests {

    my $subs_mod = "FindApp::Subs";
    require_ok($subs_mod);

    my %on_stop_list = map { $_ => 1 }qw(
        debugging
        tracing
    );

    my @evil_subs = grep !$on_stop_list{$_} => do {
        no strict "refs";
        @{ $subs_mod . "::EXPORT_OK" };
    };

    my $evil_sub_have = @evil_subs;
    my $evil_sub_want = 100;
    cmp_ok $evil_sub_have, ">", $evil_sub_want   => "found enough evil subs: $evil_sub_have > $evil_sub_want";

    for my $func (@evil_subs) { 
        ok !eval { $MODULE->import($func); 1 }  => "cannot import evil sub $func";
        like $@ => $IMPORT_EXCEPTION            => "importing evil sub $func throws $IMPORT_EXCEPTION";
        ok !defined &$func                      => "evil sub undefined &$func";
    }

}

sub evil_tags_tests {

    my @evil_tags = qw(
        asfasfkljhasdf
        34094603
        isn't
        ^@$
        PACKAGE
    );
    push @evil_tags, "\cCControl-C\cC";

    # Up through Exporter v5.68, it had a noxious annoyance
    # that's compensated for below.
RIDICULOUS:
    for my $tag (@evil_tags) { 
        my($stdout, $stderr, $ok) = capture { 
            ok !eval{ $MODULE->import(":$tag"); 1 } 
                => "died per expectation on :$tag import";
            like $@ => ($EXPORTER_VERSION > 5.68 
                        ? $IMPORT_WARNING 
                        : $IMPORT_EXCEPTION)
                => "failed to import bogus tag :$tag";
            1;
        };
        ok $ok, "captured any ridiculous leakage ok";
        cmp_ok($stdout, "eq", q(), "stdout is clean after attempted import of evil tag $tag");
        if ($EXPORTER_VERSION > 5.68) {
            cmp_ok($stderr, "eq", q(), "no stderr after import of evil tag $tag under good Exporter version");
        }
        else  {
            like $stderr, $IMPORT_WARNING,
                => "caught ridiculous export warning turned exception turned stderr leakage importing evil tag $tag";
        }
    }

}

__END__
