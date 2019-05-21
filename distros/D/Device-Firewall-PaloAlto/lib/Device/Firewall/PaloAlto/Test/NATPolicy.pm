package Device::Firewall::PaloAlto::Test::NATPolicy;
$Device::Firewall::PaloAlto::Test::NATPolicy::VERSION = '0.1.6';
use strict;
use warnings;
use 5.010;

use parent qw(Device::Firewall::PaloAlto::JSON);

use overload 'bool' => 'bool_overload';

# VERSION
# PODNAME
# ABSTRACT: A Palo Alto NAT policy test result


sub _new {
    my $class = shift;
    my ($api_response) = @_;

    return bless $api_response, $class;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Test::NATPolicy - A Palo Alto NAT policy test result

=head1 VERSION

version 0.1.6

=head1 SYNOPSIS

    use Test::More;
    my $result = $fw->test->rulebase( ... );

    # Object returns true or false in boolean context depending on whether the
    # flow was allowed / denied through the firewall.
    ok( $result, "Flow allowed");

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
