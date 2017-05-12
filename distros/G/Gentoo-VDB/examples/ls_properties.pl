#!perl
use strict;
use warnings;

use Gentoo::VDB;
use Data::Dump qw(pp);
use Term::ANSIColor qw( colored );
use Text::Wrap qw( wrap );
my $vdb = Gentoo::VDB->new();
for my $package ( sort $vdb->packages( { in => 'dev-perl' } ) ) {
    my @props = sort { $a->{label} cmp $b->{label} }
      grep { $_->{type} =~ /\A(string|number|timestamp|use-list|dependencies|keywords|licenses|url-list|bytecount)\z/ }
      $vdb->properties( { for => $package } );

    printf "%s:\n", colored(['green'], $package );
    for my $property (@props) {
        local $Text::Wrap::huge = 'overflow';
        local $Text::Wrap::columns = 100;
        printf " %s: %s\n", colored(['yellow'],sprintf '%20s', $property->{label}), wrap('',' ' x 23, $vdb->get_property($property));
    }
}
