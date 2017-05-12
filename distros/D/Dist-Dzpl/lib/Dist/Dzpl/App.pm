package Dist::Dzpl::App;

use strict;
use warnings;

use Dist::Dzpl;

sub run {
    my $self = shift;
    my $dzpl = shift;
    my @arguments = @_;

    unless ( @arguments ) {
        print <<_END_;
$0: Nothing to do, try

    dzpl build
    dzpl test
    dzpl release
    dzpl dzil ...

_END_
        return;
    }

    $dzpl ||= Dist::Dzpl->from_file; # For now, load from the (current) working directory
    $dzpl->run( @arguments );
}

1;
