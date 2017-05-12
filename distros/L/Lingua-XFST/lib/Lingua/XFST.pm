package Lingua::XFST;

use strict;
use warnings;

use Lingua::XFST::Network;
use Lingua::XFST::Privates qw//;

our $VERSION = '0.1';

our $context;

BEGIN {
    $context = Lingua::XFST::Privates::initialize_cfsm();
    # Turn off verbose mode.
    $context->{interface}{general}{verbose} = 0;
}

END {
    Lingua::XFST::Privates::reclaim_cfsm($context);
}

1;

__END__

=head1 NAME

Lingua::XFST - Perl bindings for the Xerox FSM libraries


=head1 VERSION

This document describes Lingua::XFST version 0.1


=head1 SYNOPSIS

    use Lingua::XFST;

    my $net = Lingua::XFST::Network->new(file => $filename); # Load network in file $filename
    my $strings = $net->apply_up($string);           # Strings from applying up
    my $strings = $net->apply_down($string);         # Strings from applying down


=head1 DESCRIPTION

This module wraps the XFST C library and provides a Perl object interface to
it. Currently only the bare minimum of functionality is provided, but more is
coming. The only interface supported is the network class, which can be
applied to strings in both directions.

For detailed documentation of the network class, see L<Lingua::XFST::Network>.
The brave (and/or desperate) seeking more functionality can access the
SWIG-generated interface via L<Lingua::XFST::Privates>; see that file for
details.


=head1 BUGS & LIMITATIONS

No known bugs yet. The biggest limitation is the sheer lack of functionality.


=head1 SEE ALSO

L<Lingua::XFST::Network>, L<Lingua::XFST::Privates>


=head1 AUTHOR

Arne SkjE<aelig>rholt C<< <arnsholt@gmail.com> >>


=head1 LICENSE & COPYRIGHT

Copyright (c) 2011, Arne SkjE<aelig>rholt C<< <arnsholt@gmail.com> >>. All
rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.
