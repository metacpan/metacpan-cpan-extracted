package Device::Firewall::PaloAlto::Op::GlobalCounters;
$Device::Firewall::PaloAlto::Op::GlobalCounters::VERSION = '0.1.9';
use strict;
use warnings;
use 5.010;

use parent qw(Device::Firewall::PaloAlto::JSON);

use Device::Firewall::PaloAlto::Op::GlobalCounter;
use Device::Firewall::PaloAlto::Errors qw(ERROR);


# VERSION
# PODNAME
# ABSTRACT: Palo Alto firewall global system counters


sub _new {
    my $class = shift;
    my ($api_return) = @_;

    my %counters = map { $_->{name} => Device::Firewall::PaloAlto::Op::GlobalCounter->_new($_) } @{$api_return->{result}{global}{counters}{entry}};

    return bless \%counters, $class;
}



sub name { return defined $_[0]->{$_[1]} ? $_[0]->{$_[1]} : ERROR("No such counter name", 0)  }


sub to_array { return values %{$_[0]} }




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Op::GlobalCounters - Palo Alto firewall global system counters

=head1 VERSION

version 0.1.9

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2

Returns a L<Device::Firewall::PaloAlto::Op::GlobalCounter> object based on the counter's name.

=head2 to_array

Returns an array of L<Device::Firewall::PaloAlto::Op::GlobalCounter> objects representing the global counters.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
