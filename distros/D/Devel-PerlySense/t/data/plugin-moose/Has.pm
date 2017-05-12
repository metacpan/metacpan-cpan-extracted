=head1 NAME

Has - Fake class with Moose style has syntax

=cut

use strict;
package Has;
use Moose;


has timeBareword => (is => "rw");

has "timeQuoted" => (
    is  => "rw",
    isa => "Int",
);

has "timeQuotedComma", (is => "rw");



has ["timeList1", "timeList2"] => (
    is => "rw",
);

has [ qw/ timeQwList1 timeQwList2 / ] => (
    is => "ro",
);

has [ qw/ qw timeQwList3 / ] => (
    is => "ro",
);

has q/timeSingleQuoted/ => ();



has "+timePlus" => (is => "rw");



1;





#EOF
