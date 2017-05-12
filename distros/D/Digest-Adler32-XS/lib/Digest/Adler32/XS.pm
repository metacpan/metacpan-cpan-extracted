package Digest::Adler32::XS;

use warnings;
use strict;

our $VERSION = '0.03';

use base qw(Digest::base DynaLoader);

bootstrap Digest::Adler32::XS;

sub new {
    my $class = shift;
    if (ref $class) {
        $$class = 1;  # reset
        return $class;
    }
    my $adler_state = 1;
    return bless \$adler_state, $class;
}

sub clone {
    my $self = shift;
    my $adler_state = $$self;
    return bless \$adler_state, ref($self);
}
    
sub add {
    my ($self, @args) = @_;
    my $current = $$self;
    for my $buf (@args) {
        $current = adler32($current, $buf);
    }
    $$self = $current;
    return $self;
}

sub digest {
    my $self = shift;
    my $digest = pack("N", $$self);
    $$self = 1;  # reset
    return $digest;
}

bootstrap Digest::Adler32::XS;

1;

__END__

=head1 NAME

Digest::Adler32::XS - Generate Adler32 digests efficiently

=head1 SYNOPSIS

    use Digest::Adler32::XS;
    my $digest = Digest::Adler32::XS->new();

    # add stuff
    $digest->add($some_data);
    $digest->addfile(*STDIN);

    # get digest
    print "Adler32: ", $digest->hexdigest, "\n";
    
=head1 DESCRIPTION

This module is a more efficient version of L<Digest::Adler32|Digest::Adler32>, 
and conforms to the same API. The digest calculations are performed 
internally in C for performance. Benchmarks show that this module typically
performance 300 times faster than Digest::Adler32. 

=head1 SEE ALSO

RFC 1950, which defines the Adler-32 checksum algorithm:
http://www.faqs.org/rfcs/rfc1950.html

Another implementation of Adler-32 is provided in the
L<Digest::Adler32|Digest::Adler32> module.

=head1 AUTHOR AND COPYRIGHT

Parts of this library were derived from the code for libxdiff, by
Davide Libenzi E<lt>davidel@xmailserver.orgE<gt>. Tests were derived from
those for L<Digest::Adler32|Digest::Adler32>. Other parts are 
Copyright 2004, Geoff Richards E<lt>qef@laxan.comE<gt> and were derived 
from L<Algorithm::GDiffDelta>.

Module author: Stuart Watt E<lt>swatt@infobal.comE<gt>

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 2.1 of the License, or (at
your option) any later version. A copy of the license is available at:
http://www.gnu.org/copyleft/lesser.html

=cut
