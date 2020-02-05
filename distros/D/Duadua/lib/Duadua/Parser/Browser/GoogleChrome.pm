package Duadua::Parser::Browser::GoogleChrome;
use strict;
use warnings;
use Duadua::Util;

sub try {
    my ($class, $d) = @_;

    return if index($d->ua, 'http') > -1;
    return if index($d->ua, 'oogle') > -1;
    return if index($d->ua, ' OPR/') > -1 || index($d->ua, ' Vivaldi/') > -1;
    return if index($d->ua, 'Browser/') > -1;
    return if index($d->ua, 'QtWebEngine') > -1;

    if ( index($d->ua, 'Chrome/') > -1 && index($d->ua, 'AppleWebKit/') > -1 && index($d->ua, 'Safari/') > -1 ) {
        my $h = {
            name => 'Google Chrome',
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!Chrome/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return Duadua::Util->set_os($d, $h);
    }

    if ( index($d->ua, 'Mozilla/') > -1 && index($d->ua, 'AppleWebKit/') > -1
        && (index($d->ua, 'CrMo/') > -1 || index($d->ua, 'CriOS/') > -1) ) {
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
