package Duadua::Parser::Bot::HatenaBot;
use strict;
use warnings;
use Duadua::Util;

sub try {
    my ($class, $d) = @_;

    return if index($d->ua, 'Hatena') == -1;

    if ( index($d->ua, 'Hatena Antenna/') > -1 ) {
        my $h = {
            name   => 'Hatena Antenna',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^Hatena Antenna/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }
    elsif ( index($d->ua, 'Hatena Pagetitle Agent/') > -1 ) {
        my $h = {
            name   => 'Hatena Pagetitle Agent',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^Hatena Pagetitle Agent/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }
    elsif ( index($d->ua, 'Hatena Star UserAgent/') > -1 ) {
        my $h = {
            name   => 'Hatena Star UserAgent',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^Hatena Star UserAgent/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }
    elsif ( index($d->ua, 'Hatena-Favicon/') > -1 ) {
        my $h = {
            name   => 'Hatena-Favicon',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^Hatena-Favicon/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }
    elsif ( index($d->ua, 'Hatena::') > -1 && $d->ua =~ m!^(Hatena::[a-zA-Z:]+)/!) {
        my $h = {
            name   => $1,
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^Hatena::[a-zA-Z:]+/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }
    elsif ( index($d->ua, 'HatenaBookmark/') > -1 ) {
        my $h = {
            name   => "HatenaBookmark",
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^HatenaBookmark/([\d.]+)!);
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
