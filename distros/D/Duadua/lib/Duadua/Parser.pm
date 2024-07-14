package Duadua::Parser;
use strict;
use warnings;
use Duadua::Util;

my $BLANK_UA = {
    name => 'UNKNOWN',
};

sub parse {
    my ($class, $d) = @_;

    my $index_mozilla = index($d->ua, 'Mozilla/');
    if ($index_mozilla == 0) {
        $d->{_contain_mozilla_top} = 1;
        $d->{_contain_mozilla} = 1;
    } elsif ($index_mozilla > 0) {
        $d->{_contain_mozilla} = 1;
    }

    for my $m (@{$d->parsers}) {
        if ( my $res = $m->try($d) ) {
            return $res;
        }
    }

    # Blank or '-'
    if ($d->ua eq '' || $d->ua eq '-') {
        return $BLANK_UA;
    }

    if ( my $browser = $class->_detect_general_browser($d) ) {
        return $browser;
    }

    if ( my $bot = $class->_detect_general_bot($d) ) {
        return $bot;
    }

    return $BLANK_UA;
}

sub _detect_general_browser {
    my ($class, $d) = @_;

    if ( index($d->ua, 'rowser') > 0 && $d->_prefix('Mozilla/') ) {
        if ( $d->ua =~ m![^a-zA-Z]([a-zA-Z]+[bB]rowser)/([\d.]+)! ) {
            my %h = %{$BLANK_UA};
            ($h{name}, $h{version}) = ($1, $2);
            return Duadua::Util->set_os($d, \%h);
        }
    }
}

sub _detect_general_bot {
    my ($class, $d) = @_;

    my %h = %{$BLANK_UA};

    if ( $d->_contain('https://') || $d->_contain('http://') ) {
        $h{is_bot} = 1;
        if ( !$d->_contain('Mozilla/') && $d->ua =~ m!^([^/;]+)/(v?[\d.]+)! ) {
            my ($name, $version) = ($1, $2);
            $h{name}    = $name;
            $h{version} = $version;
        }
        elsif ( $d->ua =~ m![\s\(]([^(/\s:;]+(?:bot|crawl|crawler|spider|fetcher))/(v?[\d.]+)!i ) {
            my ($name, $version) = ($1, $2);
            $h{name}    = $1;
            $h{version} = $version;
        }
        elsif ( $d->ua =~ m!([a-zA-Z0-9\-\_\.\!]+(?:bot|crawler))!i ) {
            $h{name} = $1;
        }

        return \%h;
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Duadua::Parser - Parser of Duadua


=head1 METHODS

=head2 parse($d_obj)

Do parse


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

C<Duadua> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
