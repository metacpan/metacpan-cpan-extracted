package Device::Firewall::PaloAlto::Test::SecPolicy;
$Device::Firewall::PaloAlto::Test::SecPolicy::VERSION = '0.1.8';
use strict;
use warnings;
use 5.010;

use parent qw(Device::Firewall::PaloAlto::JSON);

use overload 'bool' => 'bool_overload';

# VERSION
# PODNAME
# ABSTRACT: A Palo Alto rulebase test result.


sub _new {
    my $class = shift;
    my ($api_response) = @_;
    my %result;

    return $api_response unless $api_response;

    %result = %{ $api_response->{result} };

    # If there are no keys, we've hit the default deny. We set 
    # a pseudo-name and an action
    if (!%result) {
        $result{rules}{entry}{__DEFAULT_DENY__}{action} = 'deny';
        $result{rules}{entry}{__DEFAULT_DENY__}{index} = -1;
    }


    # Pull the rulename from the hash key
    my $rule_name = (keys %{ $result{rules}{entry} })[0];
    $result{rules}{entry}{$rule_name}{rule_name} = $rule_name;

    return bless $result{rules}{entry}{$rule_name}, $class;
}


sub rulename { return $_[0]->{rule_name} };


sub action { return $_[0]->{action} }


sub index { return $_[0]->{index} + 0 }

sub bool_overload { $_[0]->{action} eq 'allow' };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Test::SecPolicy - A Palo Alto rulebase test result.

=head1 VERSION

version 0.1.8

=head1 SYNOPSIS

    use Test::More;
    my $result = $fw->test->secpolicy( ... );

    # Object returns true or false in boolean context depending on whether the
    # flow was allowed / denied through the firewall.
    ok( $result, "Flow allowed");

=head1 DESCRIPTION

=head1 METHODS

=head2 rulename

Returns the rulename that the flow matched against. If the flow matched the default deny at the end of the policy,
the rule name is '__DEFAULT_DENY__'

=head2 action

The action that the policy would have taken on the flow. Can be either 'allow' or 'deny'

=head2 index

The index of the policy that the flow matched against.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
