package Duadua::Parser::Bot::GooglebotMisc;
use strict;
use warnings;

sub try {
    my ($class, $d) = @_;

    return unless $d->_contain('Google');

    if ( $d->_contain('Googlebot-Image') ) {
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

    if ( $d->_contain('Googlebot-News') ) {
        return {
            name   => 'Googlebot-News',
            is_bot => 1,
        };
    }

    if ( $d->_contain('Googlebot-Video') ) {
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

    if ( $d->_contain('Storebot-Google') ) {
        my $h = {
            name   => 'Storebot-Google',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!Storebot-Google/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return Duadua::Util->set_os($d, $h)
    }

    if ( $d->_contain('Google-InspectionTool') ) {
        my $h = {
            name   => 'Google-InspectionTool',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!Google-InspectionTool/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return Duadua::Util->set_os($d, $h)
    }

    if ( $d->_prefix('GoogleOther-') ) {
        my ($type) = ($d->ua =~ m!^GoogleOther-(Image|Video)/!);
        $type ||= 'UNKNOWN';
        my $h = {
            name   => "GoogleOther-$type",
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^Google-.+/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }
    elsif ( $d->_contain('GoogleOther') ) {
        my $h = {
            name   => 'GoogleOther',
            is_bot => 1,
        };

        if ($d->ua eq 'GoogleOther') {
            return $h;
        }

        return Duadua::Util->set_os($d, $h);
    }

    if ( $d->_prefix('FeedFetcher-Google') ) {
        return {
            name   => 'FeedFetcher-Google',
            is_bot => 1,
        };
    }

    if ( $d->_contain(' AppEngine-Google;') || $d->_contain('AppEngine-Google; ') ) {
        return {
            name   => 'AppEngine-Google',
            is_bot => 1,
        };
    }

    if ( $d->_contain(' Google-Site-Verification') ) {
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

    if ( $d->_contain(' Google Page Speed Insights') ) {
        my $h = {
            name   => 'Google Page Speed Insights',
            is_bot => 1,
        };

        return Duadua::Util->set_os($d, $h);
    }

    if ( $d->_prefix('GoogleProducer;') ) {
        return {
            name   => 'GoogleProducer',
            is_bot => 1,
        };
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
