package Geohash;
use strict;
use warnings;
our $VERSION = '0.04';

use Exporter 'import';
our @EXPORT_OK   = qw( ADJ_TOP ADJ_RIGHT ADJ_LEFT ADJ_BOTTOM );
our %EXPORT_TAGS = (adjacent => \@EXPORT_OK);

BEGIN {
    my @classes = qw( Geo::Hash::XS Geohash::backendPP );
    if (my $backend = $ENV{PERL_GEOHASH_BACKEND}) {
        if ($backend eq 'Geo::Hash') {
            @classes = qw( Geohash::backendPP );
        } elsif ($backend eq '+Geo::Hash') {
            @classes = qw( Geo::Hash );
        } else {
            @classes = ( $backend );
        }
    }

    local $@;
    my $class;
    for (@classes) {
        $class = $_;
        last if $class eq 'Geohash::backendPP';
        eval "use $class";## no critic
        last unless $@;
    }
    unless ($class eq 'Geohash::backendPP') {
        die $@ if $@;
    }

    sub backend_class { $class }

    no strict 'refs';
    *ADJ_RIGHT  = sub { &{"$class\::ADJ_RIGHT"} };
    *ADJ_LEFT   = sub { &{"$class\::ADJ_LEFT"} };
    *ADJ_TOP    = sub { &{"$class\::ADJ_TOP"} };
    *ADJ_BOTTOM = sub { &{"$class\::ADJ_BOTTOM"} };
}

sub new {
    my($class) = @_;
    my $backend = $class->backend_class->new;
    bless {
        backend => $backend,
    }, $class;
}


for my $method (qw/ encode decode decode_to_interval adjacent neighbors precision /) {
    my $code = sub {
        my $self = shift;
        $self->{backend}->$method(@_);
    };
    no strict 'refs';
    *{$method} = $code;
}


my @ENC     = qw(
    0 1 2 3 4 5 6 7 8 9 b c d e f g h j k m n p q r s t u v w x y z
);
my %ENC_MAP = map { $_ => 1 } @ENC;

sub _merge_strip_last_char {
    my($self, $geohash) = @_;
    my @results;

    if (length($geohash || '') < 2) {
        return ($geohash);
    }

    my($parent_geohash, $last_char) = $geohash =~ /^(.+)(.)$/;
    if ($last_char eq $ENC[0]) {
        $self->{cache}{$parent_geohash}{$last_char}++;
    } elsif ($last_char eq $ENC[-1]) {
        $self->{cache}{$parent_geohash}{$last_char}++;

        if (scalar(keys %{ $self->{cache}{$parent_geohash} }) == scalar(@ENC)) {
            push @results, $self->_merge_strip_last_char($parent_geohash);
        } else {
            push @results, map { "$parent_geohash$_" } keys %{ $self->{cache}{$parent_geohash} };
        }

        delete $self->{cache}{$parent_geohash};
    } else {
        if ($self->{cache}{$parent_geohash} && $ENC_MAP{$last_char}) {
            $self->{cache}{$parent_geohash}{$last_char}++;
        } else {
            push @results, $geohash;
        }
    }

    return @results;
}

sub merge {
    my $self = shift;
    my @geohashes = sort @_;

    $self->{cache}      = +{};
    my @results;
    for my $geohash (@geohashes) {
        push @results, $self->_merge_strip_last_char($geohash);
    }
    delete $self->{cache};

    sort @results;
}

sub split {
    my($self, $geohash) = @_;
    map { "$geohash$_" } @ENC;
}

sub validate {
    my($self, $geohash) = @_;
    $geohash && $geohash =~ /^[0123456789bcdefghjkmnpqrstuvwxyz]+$/;
}


{
    package Geohash::backendPP;
    use strict;
    use warnings;
    use parent 'Geo::Hash';
    use Carp;

    # https://github.com/yappo/Geo--Hash/tree/feature-geo_hash_xs
    use constant ADJ_RIGHT  => 0;
    use constant ADJ_LEFT   => 1;
    use constant ADJ_TOP    => 2;
    use constant ADJ_BOTTOM => 3;

    my @NEIGHBORS = (
        [ "bc01fg45238967deuvhjyznpkmstqrwx", "p0r21436x8zb9dcf5h7kjnmqesgutwvy" ],
        [ "238967debc01fg45kmstqrwxuvhjyznp", "14365h7k9dcfesgujnmqp0r2twvyx8zb" ],
        [ "p0r21436x8zb9dcf5h7kjnmqesgutwvy", "bc01fg45238967deuvhjyznpkmstqrwx" ],
        [ "14365h7k9dcfesgujnmqp0r2twvyx8zb", "238967debc01fg45kmstqrwxuvhjyznp" ]
    );

    my @BORDERS = (
        [ "bcfguvyz", "prxz" ],
        [ "0145hjnp", "028b" ],
        [ "prxz", "bcfguvyz" ],
        [ "028b", "0145hjnp" ]
    );

    sub adjacent {
        my ( $self, $hash, $where ) = @_;
        my $hash_len = length $hash;

        croak "PANIC: hash too short!"
            unless $hash_len >= 1;

        my $base;
        my $last_char;
        my $type = $hash_len % 2;

        if ( $hash_len == 1 ) {
            $base      = '';
            $last_char = $hash;
        }
        else {
            ( $base, $last_char ) = $hash =~ /^(.+)(.)$/;
            if ($BORDERS[$where][$type] =~ /$last_char/) {
                my $tmp = $self->adjacent($base, $where);
                substr($base, 0, length($tmp)) = $tmp;
            }
        }
        return $base . $ENC[ index($NEIGHBORS[$where][$type], $last_char) ];
    }

    sub neighbors {
        my ( $self, $hash, $around, $offset ) = @_;
        $around ||= 1;
        $offset ||= 0;

        my $last_hash = $hash;
        my $i = 1;
        while ( $offset-- > 0 ) {
            my $top  = $self->adjacent( $last_hash, ADJ_TOP );
            my $left = $self->adjacent( $top, ADJ_LEFT );
            $last_hash = $left;
            $i++;
        }

        my @list;
        while ( $around-- > 0 ) {
            my $max = 2 * $i - 1;
            $last_hash = $self->adjacent( $last_hash, ADJ_TOP );
            push @list, $last_hash;

            for ( 0..( $max - 1 ) ) {
                $last_hash = $self->adjacent( $last_hash, ADJ_RIGHT );
                push @list, $last_hash;
            }

            for ( 0..$max ) {
                $last_hash = $self->adjacent( $last_hash, ADJ_BOTTOM );
                push @list, $last_hash;
            }

            for ( 0..$max ) {
                $last_hash = $self->adjacent( $last_hash, ADJ_LEFT );
                push @list, $last_hash;
            }

            for ( 0..$max ) {
                $last_hash = $self->adjacent( $last_hash, ADJ_TOP );
                push @list, $last_hash;
            }
            $i++;
        }

        return @list;
    }
}

1;
__END__

=head1 NAME

Geohash - Great all in one Geohash library

=head1 SYNOPSIS

simple wrapper

    use Geohash;
    my $gh = Geohash->new();
    my $hash = $gh->encode( $lat, $lon );  # default precision = 32
    my $hash = $gh->encode( $lat, $lon, $precision );
    my ($lat, $lon) = $gh->decode( $hash );
    my ($lat_range, $lon_range) = $gh->decode_to_interval( $hash );
    my $precision = $gh->precision($lat, $lon);

compatible with Pure Perl and XS

    my $adjacent_hash = $gh->adjacent($hash, $where);
    my @list_of_geohashes = $gh->neighbors($hash, $around, $offset);

specific utilities of Geohash.pm

    my @list_of_merged_geohashes = $gh->merge(@list_of_geohashes);
    my @list_of_geohashes = $gh->split(@list_of_merged_geohashes);
    my $bool = $gh->validate( $geohash );

fource use pp

   BEGIN { $ENV{PERL_GEOHASH_BACKEND} = 'Geo::Hash' }
   use Geohash;

fource use xs

   BEGIN { $ENV{PERL_GEOHASH_BACKEND} = 'Geo::Hash::XS' }
   use Geohash;

=head1 DESCRIPTION

L<Geohash> can handle easily Geohash. Geohash uses L<Geo::Hash> or L<Geo::Hash::XS> as a backend module.
You can easy choose of Pure-Perl implement or XS implement.
In addition, we have also been added useful utility methods.

=head1 Why did you not used the name of Geo::Hash::Any?

Geohash official name is not I<Geo::Hash>. It should not be separated by I<::>. And I think of I<*::Any> namespace is not preferable.

I think so no problem with increasing the namespace if a namespace that can be used to implement and intuitive.

=head1 METHODS

=head2 $gh = Geohash->new()

=head2 $hash = $gh->encode($lat, $lon[, $precision])

Encodes the given C<$lat> and C<$lon> to a geohash. If C<$precision> is not
given, automatically adjusts the precision according the the given C<$lat>
and C<$lon> values.

If you do not want Geohash to spend time calculating this, explicitly
specify C<$precision>.

=head2 ($lat, $lon) = $gh->decode( $hash )

Decodes $hash to $lat and $lon

=head2 ($lat_range, $lon_range) = $gh->decode_to_interval( $hash )

Like C<decode()> but C<decode_to_interval()> decodes $hash to $lat_range and $lon_range. Each range is a reference to two element arrays which contains the upper and lower bounds.

=head2 $precision = $gh->precision($lat, $lon)

Returns the apparent required precision to describe the given latitude and longitude.

=head2 $adjacent_hash = $gh->adjacent($hash, $where)

Returns the adjacent geohash. C<$where> denotes the direction, so if you
want the block to the right of C<$hash>, you say:

    use Geohash qw(ADJ_RIGHT);

    my $gh = Geohash->new();
    my $adjacent = $gh->adjacent( $hash, ADJ_RIGHT );

=head2 @list_of_geohashes = $gh->neighbors($hash, $around, $offset)

Returns the list of neighbors (the blocks surrounding $hash)

=head2 @list_of_merged_geohashes = $gh->merge(@list_of_geohashes)

Merged with the larger area from geohash list. And remove duplicated geohash in @list_of_geohashes.

    my @list = $gh->merge(qw/
        c2b25ps0 c2b25ps1 c2b25ps2 c2b25ps3 c2b25ps4 c2b25ps5 c2b25ps6 c2b25ps7 c2b25ps8 c2b25ps9
        c2b25psb c2b25psc c2b25psd c2b25pse c2b25psf c2b25psg c2b25psh c2b25psj c2b25psk c2b25psm
        c2b25psn c2b25psp c2b25psq c2b25psr c2b25pss c2b25pst c2b25psu c2b25psv c2b25psw c2b25psx
        c2b25psy c2b25psz
    /);
    is($list[0], 'c2b25ps');

=head2 @list_of_geohashes = $gh->split(@list_of_merged_geohashes)

geohash splitter.

    my @list = $gh->split('c2b25ps');
    is_deeply(\@list, [ qw/
        c2b25ps0 c2b25ps1 c2b25ps2 c2b25ps3 c2b25ps4 c2b25ps5 c2b25ps6 c2b25ps7 c2b25ps8 c2b25ps9
        c2b25psb c2b25psc c2b25psd c2b25pse c2b25psf c2b25psg c2b25psh c2b25psj c2b25psk c2b25psm
        c2b25psn c2b25psp c2b25psq c2b25psr c2b25pss c2b25pst c2b25psu c2b25psv c2b25psw c2b25psx
        c2b25psy c2b25psz
    / ]);

=head2 $bool = $gh->validate($geohash)

Verify correct as geohash.

    ok($gh->validate('c2b25ps0');
    ok(not $gh->validate('a'); # can not use 'a'
    ok(not $gh->validate(); # required option

=head1 CONSTANTS

=head2 ADJ_LEFT, ADJ_RIGHT, ADJ_TOP, ADJ_BOTTOM

Used to specify the direction in C<adjacent()>

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

L<Geo::Hash>, L<Geo::Hash::XS>,
L<http://en.wikipedia.org/wiki/Geohash>, L<http://geohash.org/>

=head1 THANKS TO

dirkus, tokuhirom, nipotan

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
