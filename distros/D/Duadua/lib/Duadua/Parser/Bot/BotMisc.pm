package Duadua::Parser::Bot::BotMisc;
use strict;
use warnings;
use Duadua::Util;

sub try {
    my ($class, $d) = @_;

    my $h;

    if ( $d->ua eq 'ia_archiver' ) {
        $h = {
            name   => 'Internet Archive',
            is_bot => 1,
        };
    }
    elsif ( index($d->ua, 'Yeti/') > -1
            && index($d->ua, '+http://') > -1 && index($d->ua, 'naver.') > -1 ) {
        $h = {
            name   => 'Naver Yeti',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!Yeti/([\d.]+)!);
            $h->{version} = $version if $version;
        }
    }
    elsif ( index($d->ua, ' proximic;') > -1 ) {
        $h = {
            name   => 'Comscore crawler',
            is_bot => 1,
        };
    }
    elsif ( index($d->ua, ' Daum/') > -1 ) {
        $h = {
            name   => 'Daum',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! Daum/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        $h = Duadua::Util->set_os($d, $h);
    }
    elsif ( index($d->ua, 'MixnodeCache/') > -1 ) {
        $h = {
            name   => 'mixnode.com',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^MixnodeCache/([\d.]+)!);
            $h->{version} = $version if $version;
        }
    }
    elsif ( index($d->ua, 'SearchAtlas.com ') > -1 ) {
        $h = {
            name   => 'SearchAtlas.com',
            is_bot => 1,
        };
    }
    elsif ( index($d->ua, 'ltx71') > -1 ) {
        $h = {
            name   => 'ltx71',
            is_bot => 1,
        };
    }
    elsif ( $d->ua eq 'The Knowledge AI' ) {
        $h = {
            name   => 'The Knowledge AI',
            is_bot => 1,
        };
    }
    elsif ( index($d->ua, ' FlipboardProxy/') > -1 ) {
        $h = {
            name   => 'FlipboardProxy',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! FlipboardProxy/([\d.]+)!);
            $h->{version} = $version if $version;
        }
    }
    elsif ( index($d->ua, ' BuiltWith/') > -1 ) {
        $h = {
            name   => 'BuiltWith',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! BuiltWith/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        $h = Duadua::Util->set_os($d, $h);
    }
    elsif ( index($d->ua, ' zgrab/') > -1 ) {
        $h = {
            name   => 'ZGrab',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! zgrab/([\d.x]+)!);
            $h->{version} = $version if $version;
        }

        $h = Duadua::Util->set_os($d, $h);
    }
    elsif ( index($d->ua, ' RyowlEngine/') > -1 ) {
        $h = {
            name   => 'RyowlEngine',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! RyowlEngine/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        $h = Duadua::Util->set_os($d, $h);
    }
    elsif ( index($d->ua, ' DataXu/') > -1 ) {
        $h = {
            name   => 'DataXu',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! DataXu/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        $h = Duadua::Util->set_os($d, $h);
    }
    elsif ( index($d->ua, 'istellabot/') > -1 ) {
        $h = {
            name   => 'istellabot',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^istellabot/([t\d.]+)!);
            $h->{version} = $version if $version;
        }

        $h = Duadua::Util->set_os($d, $h);
    }
    elsif ( index($d->ua, ' Cincraw/') > -1 ) {
        $h = {
            name   => 'Cincraw',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! Cincraw/([\d.]+)!);
            $h->{version} = $version if $version;
        }
    }

    return $h;
}

1;

__END__

=encoding UTF-8

=head1 METHODS

=head2 try

Do parse


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

C<Duadua> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
