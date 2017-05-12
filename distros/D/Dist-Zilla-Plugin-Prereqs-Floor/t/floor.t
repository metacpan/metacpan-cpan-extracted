use 5.006;
use strict;
use warnings;
use Test::More 0.96;

use Dist::Zilla::Tester;
use Path::Tiny;
use CPAN::Meta;

require Dist::Zilla; # for VERSION

my $root       = 'corpus/DZ';
my $dz_version = int( Dist::Zilla->VERSION );

{
    my $tzil = Dist::Zilla::Tester->from_config( { dist_root => $root }, );
    $tzil->chrome->logger->set_debug(1);
    ok( $tzil, "created test dist" );

    $tzil->build_in;
    my $build_dir = path( $tzil->tempdir->subdir('build') );

    my $meta    = CPAN::Meta->load_file( $build_dir->child("META.json") );
    my $prereqs = $meta->effective_prereqs;

    my $run_req = {
        "File::Basename" => 2, # set by floor
        "File::Spec"     => 3, # ignored by floor
        "strict"         => 0, # ignored by floor
        "warnings"       => 0, # ignored by floor
    };

    my $got;

    $got = $prereqs->requirements_for(qw/runtime requires/)->as_string_hash;
    is_deeply( $got, $run_req, "runtime requires" ) or diag explain $got;

    my $test_req = {
        "IO::File"   => 1.16,  # higher than floor
        "Test::More" => 0.46,  # set by floor
    };

    $got = $prereqs->requirements_for(qw/test requires/)->as_string_hash;
    is_deeply( $got, $test_req, "test requires" ) or diag explain $got;

    my $test_rec = { "Path::Tiny" => 0.052 }; # set by floor

    $got = $prereqs->requirements_for(qw/test recommends/)->as_string_hash;
    is_deeply( $got, $test_rec, "test recommends" ) or diag explain $got;
}

done_testing;
#
# This file is part of Dist-Zilla-Plugin-Prereqs-Floor
#
# This software is Copyright (c) 2015 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
