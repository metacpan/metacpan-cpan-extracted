package Duadua::Parser::Browser::GoogleChrome;
use strict;
use warnings;
use Duadua::Util;

sub try {
    my ($class, $d) = @_;

    return if $d->_contain('http');
    return if $d->_contain('oogle');
    return if $d->_contain(' OPR/') || $d->_contain(' Vivaldi/');
    return if $d->_contain('Browser/');
    return if $d->_contain('QtWebEngine');

    if ( $d->_contain('Chrome/') && $d->_contain('AppleWebKit/') && $d->_contain('Safari/') ) {
        my $h = {
            name => 'Google Chrome',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!Chrome/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return Duadua::Util->set_os($d, $h);
    }

    if ( $d->_contain_mozilla && $d->_contain('AppleWebKit/')
        && ($d->_contain('CrMo/') || $d->_contain('CriOS/')) ) {
        my $h = {
            name => 'Google Chrome',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!Cr(?:Mo|iOS)/([\d.]+)!);
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
