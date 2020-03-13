package Duadua::Parser::Browser::BrowserMisc;
use strict;
use warnings;
use Duadua::Util;

sub try {
    my ($class, $d) = @_;

    if ( $d->ua eq 'lynx' ) {
        return {
            name => 'Lynx',
        };
    }
    elsif ( index($d->ua, 'Lynx/') == 0 ) {
        my $h = {
            name => 'Lynx',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^Lynx/([\d.a-z]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }
    elsif ( index($d->ua, ' EzLynx/') > -1 ) {
        my $h = {
            name => 'EzLynx',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!EzLynx/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return Duadua::Util->set_os($d, $h);
    }
    elsif ( index($d->ua, 'w3m/') > -1 ) {
        my $h = {
            name => 'w3m',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^w3m/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }
    elsif ( index($d->ua, ' Konqueror/') > -1 ) {
        my $h = {
            name => 'Konqueror',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! Konqueror/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return Duadua::Util->set_os($d, $h);
    }
    elsif ( index($d->ua, 'OmniWeb/') == 0
            || (index($d->ua, ' OmniWeb/') > -1 && index($d->ua, 'Mozilla/') > -1) ) {
        my $h = {
            name   => 'OmniWeb',
            is_ios => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!OmniWeb/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }
    elsif ( index($d->ua, ' QtWebEngine/') > -1 && index($d->ua, 'Mozilla/') > -1 ) {
        my $h = {
            name => 'QtWebEngine',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! QtWebEngine/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return Duadua::Util->set_os($d, $h);
    }
    elsif ( index($d->ua, ' UBrowser/') > -1 && index($d->ua, 'Win') > -1 ) {
        my $h = {
            name => 'UBrowser',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! UBrowser/([\d.]+)!);
            $h->{version} = $version if $version;
        }

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
