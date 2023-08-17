package Lab::GenericSignals;
$Lab::GenericSignals::VERSION = '3.881';
#ABSTRACT: Signal handling

use v5.20;

use warnings;
use strict;

use sigtrap 'handler' => \&abort_all, qw(normal-signals error-signals);

sub abort_all {
    foreach my $object ( @{Lab::Generic::OBJECTS} ) {
        $object->abort();
    }
    @{Lab::Generic::OBJECTS} = ();
    exit;
}

END {
    abort_all();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::GenericSignals - Signal handling

=head1 VERSION

version 3.881

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2014       Andreas K. Huettel
            2015       Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2019       Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
