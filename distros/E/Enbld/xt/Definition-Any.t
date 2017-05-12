#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Enbld::Definition;

use FindBin;

my @def_list = qw/
 apache apr autoconf automake cmake emacs git groff hello
 libevent libidn libtool mysql nginx nodejs pcre perl pkgconfig python
 rakudostar ruby scala tmux tree vim wget zsh openssl/;

# aprutil not added, because of fail....TODO

for my $def ( @def_list ) {

    local $ENV{PERL_ENBLD_HOME} = File::Temp->newdir;

    Enbld::Home->initialize;
    Enbld::Home->create_build_directory;
    Enbld::Logger->rotate( Enbld::Home->log );

    my $target = Enbld::Target->new( $def );
    my $installed = eval { $target->install };

    chdir $FindBin::Bin;

    ok( $installed, "build $def" ) or diag( $@ );
}

done_testing();
