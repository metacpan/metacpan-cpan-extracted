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
    elsif ( $d->_contain('Yeti/')
            && $d->_contain('+http://') && $d->_contain('naver.') ) {
        $h = {
            name   => 'Naver Yeti',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!Yeti/([\d.]+)!);
            $h->{version} = $version if $version;
        }
    }
    elsif ( $d->_contain(' proximic;') ) {
        $h = {
            name   => 'Comscore crawler',
            is_bot => 1,
        };
    }
    elsif ( $d->_contain(' Daum/') ) {
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
    elsif ( $d->_contain('MixnodeCache/') ) {
        $h = {
            name   => 'mixnode.com',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!^MixnodeCache/([\d.]+)!);
            $h->{version} = $version if $version;
        }
    }
    elsif ( $d->_contain('SearchAtlas.com ') ) {
        $h = {
            name   => 'SearchAtlas.com',
            is_bot => 1,
        };
    }
    elsif ( $d->_contain('ltx71') ) {
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
    elsif ( $d->_contain(' FlipboardProxy/') ) {
        $h = {
            name   => 'FlipboardProxy',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! FlipboardProxy/([\d.]+)!);
            $h->{version} = $version if $version;
        }
    }
    elsif ( $d->_contain(' BuiltWith/') ) {
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
    elsif ( $d->_contain(' zgrab/') ) {
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
    elsif ( $d->_contain(' RyowlEngine/') ) {
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
    elsif ( $d->_contain(' DataXu/') ) {
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
    elsif ( $d->_contain('istellabot/') ) {
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
    elsif ( $d->_contain(' Cincraw/') ) {
        $h = {
            name   => 'Cincraw',
            is_bot => 1,
        };

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m! Cincraw/([\d.]+)!);
            $h->{version} = $version if $version;
        }
    }
    elsif ( $d->_contain('KOCMOHABT ') ) {
        $h = {
            name   => 'KOCMOHABT',
            is_bot => 1,
        };
    }
    elsif ( $d->_contain('Hexometer') ) {
        $h = {
            name   => 'Hexometer',
            is_bot => 1,
        };
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
