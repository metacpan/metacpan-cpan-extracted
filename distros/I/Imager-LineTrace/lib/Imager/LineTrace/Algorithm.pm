package Imager::LineTrace::Algorithm;
use 5.008001;
use strict;
use warnings;

# コード中のコメントは、左下を原点として記述している
sub search {
    my ( $pixels_ref, $opt ) = @_;
    my $ignore = ( exists $opt->{ignore} ) ? $opt->{ignore} : 0;
    my $limit = ( exists $opt->{limit} ) ? $opt->{limit} : 1024;

    my $w = scalar(@{$pixels_ref->[0]});
    my $h = scalar(@{$pixels_ref});

    my @figures = ();
    my $y0 = 0;
    foreach my $point_number (1..$limit) {
        my ( $x, $y ) = ( -1, -1 );

        for (my $iy=$y0; $iy<$h; $iy++) {
            my $i = 0;
            #say "iy = $iy";
            foreach my $val (@{$pixels_ref->[$iy]}) {
                if ( $val != $ignore ) {
                    #say "here!!!!!!!!!!!!!";
                    $x = $i;
                    $y = $iy;
                    last;
                }
                $i++;
            }

            last if 0 <= $y;
            $y0 = $iy + 1;
        }

        if ( $y < 0 ) {
            last;
        }

        my $x0 = $x;
        my $y0 = $y;
        my $trace_value = $pixels_ref->[$y][$x];

        # 探索開始点は図形の左下なので、
        # 上方向と繋がってなければ閉じていないと判断できる
        my $is_close = 0;
        if ( $x0 < ($w - 1) and $y0 < ($h - 1) ) {
            if ( $pixels_ref->[$y][$x + 1] == $trace_value
             and $pixels_ref->[$y + 1][$x] == $trace_value ) {
                $is_close = 1;
            }
        }

        if ( $is_close ) {
            # 最後の探索が開始点に到達できるように残しておく
        }
        else {
            # 閉じた図形ではないので、探索済みの処理をする
            $pixels_ref->[$y][$x] = $ignore;
        }

        my @points = ( [$x, $y] );
        my $search_comp = 0;
        while ( not $search_comp ) {
            my $number_of_points = scalar( @points );

            # 右方向に探索
            if ( ($x + 1) < $w and $pixels_ref->[$y][$x + 1] == $trace_value ) {
                while ( $pixels_ref->[$y][$x + 1] == $trace_value ) {
                    $x++;
                    $pixels_ref->[$y][$x] = $ignore;
                    last if $w <= ($x + 1);
                }

                push @points, [ $x, $y ];
            }

            # 上方向に探索
            if ( ($y + 1) < $h and $pixels_ref->[$y + 1][$x] == $trace_value ) {
                while ( $pixels_ref->[$y + 1][$x] == $trace_value ) {
                    $y++;
                    $pixels_ref->[$y][$x] = $ignore;
                    last if $h <= ($y + 1);
                }

                push @points, [ $x, $y ];
            }

            # 左方向に探索
            if ( 0 < ($x - 1) and $pixels_ref->[$y][$x - 1] == $trace_value ) {
                while ( $pixels_ref->[$y][$x - 1] == $trace_value ) {
                    $x--;
                    $pixels_ref->[$y][$x] = $ignore;
                    last if ($x - 1) < 0;
                }

                push @points, [ $x, $y ];
            }

            # 下方向に探索
            if ( 0 < ($y - 1) and $pixels_ref->[$y - 1][$x] == $trace_value ) {
                while ( $pixels_ref->[$y - 1][$x] == $trace_value ) {
                    $y--;
                    $pixels_ref->[$y][$x] = $ignore;
                    last if ($y - 1) < 0;
                }

                push @points, [ $x, $y ];
            }

            # 探索前と頂点を比較することで完了したか判定
            if ( $number_of_points == scalar(@points) ) {
                if ( $is_close ) {
                    my ( $p1, $p2 ) = @points[0,-1];
                    if ( $p1->[0] == $p2->[0] and $p1->[1] == $p2->[1] ) {
                        # 開始点と終点が同じなので、終点を取り除いて探索終了
                        pop @points;
                        $search_comp = 1;
                    }
                    else {
                        # 閉じていないことが判明したので、開始点から再探索
                        $is_close = 0;
                        @points = reverse @points;
                        $pixels_ref->[$y0][$x0] = $ignore;
                        ( $x, $y ) = ( $x0, $y0 );
                    }
                }
                else {
                    $search_comp = 1;
                }
            }
        }

        push @figures, +{
            points    => \@points,
            is_closed => $is_close,
            value     => $trace_value
        };
    }

    return \@figures;
}

1;
__END__

=encoding utf-8

=head1 NAME

Imager::LineTrace::Algorithm - Line trace algorithm

=head1 SYNOPSIS

    use Imager::LineTrace::Algorithm;

    my @pixels = Imager::LineTrace::Figure->new(
        [ 1, 1, 1 ],
        [ 1, 0, 1 ],
        [ 1, 1, 1 ]
    );

    my %args = ( ignore => 0 );
    my $figures_ref = Imager::LineTrace::Algorithm::search( \@pixels, \%args );

=head1 DESCRIPTION

Trace algorithm for Imager::LineTracer.

RETURN DATA

    # $figures_ref is ARRAY reference.
    my $figures_ref = Imager::LineTrace::Algorithm::search( \@pixels, \%args );

    # $figure_ref is HASH reference.
    my $figure_ref = $figures_ref->[0];

    # $figure_ref->{points} is ARRAY reference.
    foreach my $point (@{$figure_ref->{points}}) {
        printf( "x = %d, y = %d\n", $point->[0], $point->[1] );
    }

    # Traced pixel value.
    print $figure_ref->{value}, "\n";

    # Figure is closed.
    print $figure_ref->{is_closed}, "\n";

=head1 LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

neko E<lt>techno.cat.miau@gmail.comE<gt>

=cut
