package Exobrain::Agent::Twitter;
use Moose::Role;
use Net::Twitter;
use Method::Signatures;
use Date::Manip::Date;

our $VERSION = '1.04'; # VERSION
# ABSTRACT: Provides common functions for twitter components

with 'Exobrain::Agent';

sub component_name { "Twitter" }

has twitter => (
    is => 'ro',
    isa => 'Net::Twitter',
    lazy => 1,
    builder => '_build_twitter',
);

method _build_twitter() {
    my $config = $self->config;

    return Net::Twitter->new(
        traits   => [qw(API::RESTv1_1)],
        consumer_key        => $config->{consumer_key},
        consumer_secret     => $config->{consumer_secret},
        access_token        => $config->{access_token},
        access_token_secret => $config->{access_token_secret},
        ssl                 => 1,
    );
}

method tags(Str $text) {
    my @tags;

    while ($text =~ m{\#(?<tag>\w+)}g) {
        push @tags, $+{tag};
    }
    
    return @tags;
}

method to_epoch(Str $timestamp) {
    my $dmd = Date::Manip::Date->new;
    $dmd->parse($timestamp) and die "Can't parse $timestamp";
    return $dmd->printf("%s");
}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Twitter - Provides common functions for twitter components

=head1 VERSION

version 1.04

=for Pod::Coverage component_name

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
