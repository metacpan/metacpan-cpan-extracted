package Duadua::Parser::Bot::GooglebotMisc;
use strict;
use warnings;

sub try {
    my ($class, $d) = @_;

    return unless index($d->ua, 'Google') > -1;

    if ( index($d->ua, 'Googlebot-Image') > -1 ) {
        my $h = {
            name   => 'Googlebot-Image',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^Googlebot-Image/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }

    if ( index($d->ua, 'Googlebot-News') > -1 ) {
        return {
            name   => 'Googlebot-News',
            is_bot => 1,
        };
    }

    if ( index($d->ua, 'Googlebot-Video') > -1 ) {
        my $h = {
            name   => 'Googlebot-Video',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^Googlebot-Video/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }

    if ( index($d->ua, 'FeedFetcher-Google') == 0 ) {
        return {
            name   => 'FeedFetcher-Google',
            is_bot => 1,
        };
    }

    if ( index($d->ua, ' AppEngine-Google;') > -1 || index($d->ua, 'AppEngine-Google; ') > -1 ) {
        return {
            name   => 'AppEngine-Google',
            is_bot => 1,
        };
    }

    if ( index($d->ua, ' Google-Site-Verification') > -1 ) {
        my $h = {
            name   => 'Google-Site-Verification',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! Google-Site-Verification/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }

    if ( index($d->ua, ' Google Page Speed Insights') > -1 ) {
        my $h = {
            name   => 'Google Page Speed Insights',
            is_bot => 1,
        };

        return Duadua::Util->set_os($d, $h);
    }
}

1;

__END__

=head1 METHODS

=head2 try

Do parse


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

C<Duadua> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
