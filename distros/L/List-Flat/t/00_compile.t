use strict;
use Test::More 0.98;

use_ok $_ for qw(
  List::Flat
);

ok( !__PACKAGE__->can('flat'), 'module should not export flat() by default' );

ok( !__PACKAGE__->can('flat_f'),
    'module should not export flat_f() by default' );

ok( !__PACKAGE__->can('flat_r'),
    'module should not export flat_r() by default' );

my @combos = (
    { yes => q/flat/,          no => q/flat_f flat_r/ },
    { yes => q/flat_f/,        no => q/flat flat_r/ },
    { yes => q/flat_r/,        no => q/flat flat_f/ },
    { yes => q/flat flat_f/,   no => q/flat_r/ },
    { yes => q/flat flat_r/,   no => q/flat_f/ },
    { yes => q/flat_f flat_r/, no => q/flat/ },
);

my $count = 0;
foreach my $combo (@combos) {
    $count++;
    my $yes   = $combo->{yes};
    my $no    = $combo->{no};
    my @yeses = split( /\s+/, $yes );
    my @noes  = split( /\s+/, $no );
    my $pkg = "List::Flat::Test$count";
    eval "package $pkg; List::Flat->import(\@yeses)";
    
    print "# yes: @yeses no: @noes\n";

    foreach my $sub (@yeses) {
        main::ok( $pkg->can($sub),
            "module should export $sub when [$yes] requested" );
    }
    foreach my $sub (@noes) {
        main::ok( ! $pkg->can($sub),
            "module should not export $sub when [$no] requested" );
    }

}

package List::Flat::TestAll;

List::Flat->import(qw/flat flat_f flat_r/);

main::ok(
    (         __PACKAGE__->can('flat_f')
          and __PACKAGE__->can('flat_r')
          and __PACKAGE__->can('flat')
    ),
    'module should export flat(), flat_f(), and flat_r() when requested'
);

package main;

done_testing;

