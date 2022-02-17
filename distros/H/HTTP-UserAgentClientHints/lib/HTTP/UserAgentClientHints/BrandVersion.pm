package HTTP::UserAgentClientHints::BrandVersion;
use strict;
use warnings;
use HTTP::UserAgentClientHints::Util;

sub new {
    my ($class, $raw_brand_version) = @_;

    bless {
        _parsed_brand_version => $class->_parse_brand_version($raw_brand_version),
    }, $class;
}

sub brands {
    my $self = shift;

    return [keys %{$self->{_parsed_brand_version}}];
}

sub brand_version {
    my $self = shift;

    return {%{$self->{_parsed_brand_version}}};
}

sub _parse_brand_version {
    my ($self, $raw_brand_version) = @_;

    my @pairs = split /,\s*/, $raw_brand_version;

    my %brand_version;
    for my $pair (@pairs) {
        my ($brand, $version) = map { HTTP::UserAgentClientHints::Util->strip_quote($_) } split /;\s*v=/, $pair;
        $brand_version{$brand} = $version;
    }

    return \%brand_version;
}

1;

__END__

=encoding UTF-8

=head1 NAME

HTTP::UserAgentClientHints::BrandVersion - To Handle Sec-CH-UA values of User Agent Client Hints


=head1 SYNOPSIS

    use HTTP::UserAgentClientHints;

    my $sec_ch_ua = q|" Not A;Brand";v="09", "Chromium";v="98", "Google Chrome";v="97.1"|;
    my $brand_version = HTTP::UserAgentClientHints::BrandVersion->new($sec_ch_ua);


=head1 DESCRIPTION

HTTP::UserAgentClientHints::BrandVersion is the module which gives you a utility to handle Sec-CH-UA values of User Agent Client Hints (UA-CH)


=head1 METHODS

=head2 new($sec_ch_ua)

The constructor. The $sec_ch_ua string is required.

=head2 brands

To get brands list as array ref.

    my $brands = $brand_version->brands;

NOTE that the order of the list is not specific. Please sort if you want.

=head2 brand_version

To get a hash of brand and version pair.

    $brand_version->brand_version->{Chromium}; # 98

=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

C<HTTP::UserAgentClientHints::BrandVersion> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
