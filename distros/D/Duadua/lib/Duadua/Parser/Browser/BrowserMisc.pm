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
    elsif ( $d->_prefix('Lynx/') ) {
        my $h = {
            name => 'Lynx',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^Lynx/([\d.a-z]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }
    elsif ( $d->_contain(' EzLynx/') ) {
        my $h = {
            name => 'EzLynx',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!EzLynx/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return Duadua::Util->set_os($d, $h);
    }
    elsif ( $d->_contain('w3m/') ) {
        my $h = {
            name => 'w3m',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^w3m/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }
    elsif ( $d->_contain(' Konqueror/') ) {
        my $h = {
            name => 'Konqueror',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! Konqueror/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return Duadua::Util->set_os($d, $h);
    }
    elsif ( $d->_prefix('OmniWeb/')
            || ($d->_contain(' OmniWeb/') && $d->_contain_mozilla) ) {
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
    elsif ( $d->_contain(' QtWebEngine/') && $d->_contain_mozilla ) {
        my $h = {
            name => 'QtWebEngine',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! QtWebEngine/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return Duadua::Util->set_os($d, $h);
    }
    elsif ( $d->_contain(' UBrowser/') && $d->_contain('Win') ) {
        my $h = {
            name => 'UBrowser',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! UBrowser/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return Duadua::Util->set_os($d, $h);
    }
    elsif ( $d->_contain(' MZBrowser/') && $d->_contain('UWS') ) {
        my $h = {
            name => 'MZBrowser',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! MZBrowser/([\d.\-]+)!);
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
