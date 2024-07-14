package Duadua::Parser::Bot::AdIdxBot;
use strict;
use warnings;

sub try {
    my ($class, $d) = @_;

    if ( $d->_contain('adidxbot/')
            && $d->_contain('+http://www.bing.com/bingbot.htm')
                && $d->_contain_mozilla ) {
        my $h = _set_property($d, 'AdIdxBot');

        if ($d->opt_version) {
            my ($version) = ($d->ua =~ m!adidxbot/([\d.]+)!);
            $h->{version} = $version if $version;
        }

        return $h;
    }
}

sub _set_property {
    my ($d, $name) = @_;

    my $h = {
        name   => $name,
        is_bot => 1,
    };

    if ( $d->_contain('Windows') ) {
        $h->{is_windows} = 1;
    }
    elsif ( $d->_contain('iPhone') ) {
        $h->{is_ios} = 1;
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
