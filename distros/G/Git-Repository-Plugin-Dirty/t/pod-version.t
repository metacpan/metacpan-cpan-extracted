#!perl

use Test::More;
plan skip_all => 'POD tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::Pod 1.14';
plan skip_all => 'Test::Pod v1.14 required for testing POD' if $@;
eval 'use Pod::Simple::SimpleTree 3.28';
plan skip_all => 'Pod::Simple::SimpleTree v3.28 required for testing POD version' if $@;
eval 'use Module::Want 0.5';
plan skip_all => 'Module::Want v0.5 required for testing POD version' if $@;

my $ns_regex = Module::Want::get_ns_regexp();

for my $pod ( all_pod_files() ) {

    my $version_section;
    my $next = 0;
    for my $section ( @{ Pod::Simple::SimpleTree->new->parse_file($pod)->root } ) {
        next unless ref($section) eq 'ARRAY';

        if ($next) {
            $version_section = $section->[2];
            last;
        }

        if ( $section->[0] =~ m/head[0-9]/ && $section->[2] eq 'VERSION' ) {
            $next = 1;
        }
    }

    if ( defined $version_section ) {
        if ( $version_section =~ m/This document describes ($ns_regex) version (\S+)/ ) {
            my ( $ns, $ver ) = ( $1, $2 );
            if ( Module::Want::have_mod($ns) ) {
                my $cur = $ns->VERSION;
                is( $cur, $ver, "$pod VERSION line has the same version as $ns" );
            }
            else {
                ok( 0, "Could not load $ns to find version:\n\t$@" );
            }
        }
        else {
            like( $version_section, qr/This document describes $ns_regex version \S+/, "VERSION section has the correct text" );
        }
    }
    else {
        ok( 1, "No VERSION section" );
    }
}

done_testing;
