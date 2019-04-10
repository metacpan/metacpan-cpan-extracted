package Device::Firewall::PaloAlto::Op::GlobalCounter;
$Device::Firewall::PaloAlto::Op::GlobalCounter::VERSION = '0.1.5';
use strict;
use warnings;
use 5.010;

use parent qw(Device::Firewall::PaloAlto::JSON);

# VERSION
# PODNAME
# ABSTRACT: Palo Alto firewall global system counter


sub _new {
    my $class = shift;
    my ($counter_r) = @_;
    my %counter = %{$counter_r};

    # Change the rate and value to integers
    $counter{$_} += 0 foreach qw(rate value);

    return bless \%counter, $class;
}



sub name { return $_[0]->{name} }
sub rate { return $_[0]->{rate} }
sub value { return $_[0]->{value} }
sub severity { return $_[0]->{severity} }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Op::GlobalCounter - Palo Alto firewall global system counter

=head1 VERSION

version 0.1.5

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 name

Returns the name of the counter.

=head2 rate

Returns the current rate at which the counter is increasing

=head2 value

The current value of the counter.

=head2 severity

The severity of the counter.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
