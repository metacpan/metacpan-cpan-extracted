package Duadua::Util;
use strict;
use warnings;

sub set_os {
    my ($class, $d, $h) = @_;

    if ( $d->_contain('Win') && ($d->_contain('Win32') || $d->_contain('Windows')) ) {
        $h->{is_windows} = 1;
    }
    elsif ( $d->_contain('Android') ) {
        $h->{is_android} = 1;
        $h->{is_linux}   = 1; # Android is Linux also.
    }
    elsif ( $d->_contain('iPhone') ) {
        $h->{is_ios} = 1;
    }
    elsif ( $d->_contain('iP') && ($d->_contain('iPad') || $d->_contain('iPod')) ) {
        $h->{is_ios} = 1;
    }
    elsif ( $d->_contain('Mac') && ($d->_contain('Macintosh') || $d->_contain('Mac OS')) ) {
        $h->{is_ios} = 1;
    }
    elsif ( $d->_contain(' CrOS ') ) {
        $h->{is_chromeos} = 1;
    }
    elsif ( $d->_contain('Linux') ) {
        $h->{is_linux} = 1;
    }

    return $h;
}

sub ordering_match {
    my ($class, $d, $list) = @_;

    my $pre = 0;
    for my $word (@{$list}) {
        my $position = index($d->ua, $word);
        return 0 if $position < $pre;
        $pre = $position;
    }

    return 1; # Match!
}

1;

__END__

=encoding UTF-8

=head1 NAME

Duadua::Util - Utilities of Duadua


=head1 Export Functions

=head2 name($hash, $name)

Set name

=head2 bot($hash)

Set bot

=head2 ios($hash)

Set iOS

=head2 android($hash)

Set Android

=head2 linux($hash)

Set Linux

=head2 windows($hash)

Set Windows

=head2 version($hash, $version_string)

Set version string

=head2 set_os($d_obj, $hash)

Detect OS from $d_obj, then return result as $hash.

=head2 ordering_match($d_obj, $list)

The detector wether elements of $list are matching with User-Agent string in order.


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

C<Duadua> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut

1;
