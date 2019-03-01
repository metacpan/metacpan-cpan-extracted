package  # private package
    TestUA;

sub new {
    return bless {}, shift;
}

sub get {
    my ($ua, $url) = @_;

    my $error = q~HTTP/1.1 500 Internal Server Error
Content-Length: 21
Server: nginx
Date: Mon, 25 Feb 2019 15:04:37 GMT
Content-Type: text/plain
Connection: keep-alive

Internal Server Error
~;

     my $epublisher = q~HTTP/1.1 200 OK
Connection: keep-alive
Content-Disposition: attachment; filename=epublisher.pod
Server: nginx
Content-Type: application/octet-stream
Content-Length: 5632
Set-Cookie: plack_session=1551107060.11834%3ABQoDAAAAAQoCZW4AAAAYdHVybmFyb3VuZC5pMThuLmxhbmd1YWdl%3A318133c1d65f272af9e793495f0eebb084ed2d66; path=/; expires=Mon, 25-Feb-2019 15:54:20 GMT
Date: Mon, 25 Feb 2019 15:04:20 GMT

=head1 NAME

EPublisher
~;

     my $pdl = do{ local $/; <DATA> };

     my $response = $error;
     if ( $url =~ m{pdl}i ) {
         $response = $pdl;
     }
     elsif ( $url =~ m{epublisher}i ) {
         $response = $epublisher;
     }

     my ($header, $body)   = split /\n\n/, $response, 2;
     my ($status, $reason) = $header =~ m{HTTP/1\.1 \s+ ([0-9]+) \s+ ([^\n]+)}x;

     my $data = {
         status  => $status,
         content => $body,
         url     => $url,
         reason  => $reason,
     };

     return $data;
}

1;

__DATA__
HTTP/1.1 200 OK
Connection: keep-alive
Content-Disposition: attachment; filename=pdl.pod
Server: nginx
Content-Type: application/octet-stream
Content-Length: 5632
Set-Cookie: plack_session=1551107060.11834%3ABQoDAAAAAQoCZW4AAAAYdHVybmFyb3VuZC5pMThuLmxhbmd1YWdl%3A318133c1d65f272af9e793495f0eebb084ed2d66; path=/; expires=Mon, 25-Feb-2019 15:54:20 GMT
Date: Mon, 25 Feb 2019 15:04:20 GMT

=head1 NAME

PDL

=head1 INCLUDES

    /js/jquery.flot.min.js

=head1 JAVASCRIPT

    $('.test').after('<div class="plot hidden" style="margin-top:1em;width:600px;height:300px;"></div>');
    $.plot($('.plot'), []);

=head1 HANDLER

    (function(data) {
        var plot = $(form).children('.plot').first();
        $(plot).removeClass('hidden');
        if (data.result.constructor == Object && data.result.plot) {
            $.plot($(plot), data.result.plot);
        }
        else {
            $(plot).addClass('hidden');
            $.plot($(plot), []);
        }
    })(data);

=head1 MODULES

    PDL

=head1 PREAMBLE

    use PDL::LiteF;

    use Scalar::Util 'looks_like_number';

    sub plot {
        my @datasets = @_;

        my @output_datasets;
        for my $dataset (@datasets) {

            # promote to hashref
            unless (eval { ref $dataset eq 'HASH' }) {
                $dataset = {data => $dataset};
            }

            # 1D piddle
            if (eval { $dataset->{data}->isa('PDL') }) {
                $dataset->{data} =
                  [$dataset->{data}->sequence, $dataset->{data}];
            }

            # promote two piddles
            if (    eval { $dataset->{data}->[0]->isa('PDL') }
                and eval { $dataset->{data}->[1]->isa('PDL') })
            {
                my ($x, $y) = @{$dataset->{data}};
                my $data = _unroll($x->cat($y)->xchg(0, 1));
                $dataset->{data} = $data;
            }

            # promote a 1D list
            if (not ref $dataset->{data}->[0]) {
                my $x = 0;
                my @pairs;
                for my $y (@{$dataset->{data}}) {
                    if (!defined $y) {
                        $x--;
                        push @pairs, undef;
                        next;
                    }

                    push @pairs, [$x++, $y];
                }
                $dataset->{data} = \@pairs;
            }

            unless (eval { _validate_data($dataset->{data}) }) {
                print STDERR "Plot Error: $@";
                return {};
            }

            push @output_datasets, $dataset;
        }

        return +{plot => \@output_datasets};
    }

    sub _unroll {
        my $pdl = shift;
        if ($pdl->ndims > 1) {
            return [map { _unroll($_) } $pdl->dog];
        }
        else {
            return [$pdl->list];
        }
    }

    sub _validate_data {
        my $data = shift;

        die "data must be an arrayref or PDL\n"
          unless eval { ref $data eq 'ARRAY' };
        _validate_point($_) for @$data;

        return 1;
    }

    sub _validate_point {
        my ($point) = @_;
        return if !defined $point;
        die "points must be pairs\n" unless @$point == 2;
        for my $num (@$point) {
            die "non numeric point ($num)\n" unless looks_like_number $num;
        }
    }

=head1 ABSTRACT

An introduction to the PDL extension to Perl.

=head1 DESCRIPTION

This tutorial is an introduction to the Perl Data Language (PDL) which is an array-oriented mathematical module for Perl. The official PDL website is L<http://pdl.perl.org>.

=head1 TUTORIAL

=head2 Simple Plotting

This tutorial uses a custom javascript plotting system built on the Flot library (L<http://code.google.com/p/flot/>). The plotting interface provided by C<perltuts.com> is still under heavy development and may change. 

The C<plot> command accepts a list of datasets to be plotted. Valid datasets include a simple arrayref of y values (x values will be generated),

    plot([1, 2, 3]);

... an arrayref of x-y points

    plot([[1,1],[3,9],[5,25],[7,49]]);

... a 1D PDL object containing y values

    plot(pdl(1,2,3));

... or an arrayref of 1D PDL objects of x and y values respectively

    plot([pdl(1,3,5,7),pdl(1,9,25,49)]);

=head2 PDL Object Constructors

When using PDL one creates and manipulates PDL object, whimsically called I<piddles>. These objects represent an array of arbitrary dimensionality and unlike most of Perl, of a certain numerical datatype.

A PDL object may be created using the C<pdl> command, which converts a Perl array structure to a PDL.

    my $pdl = pdl([[1,2,3],[4,5,6],[7,8,9]]);

To see what the PDL object contains, since PDL overloads stringification, simply print it out. To get other information, the C<info> method is also useful.

    my $pdl = pdl([[1,2,3],[4,5,6],[7,8,9]]);
    say $pdl;
    say $pdl->info;

Many of the other PDL contstructor functions take the dimensionality as their argument. For example C<sequence> creates a PDL whose values increment for each element.

    # create a 5x5 PDL
    my $pdl = sequence 5,5;
    say $pdl;

Other such constructors are C<zeros>, C<ones>, C<xvals>, C<yvals>, C<zvals>, and C<rvals>. The first two are obvious, creating a PDL filled with 0 or 1. The next three create a PDL of a given dimensionality, but whose values are taken from their x, y, or z component respectively. C<rvals> creates a PDL whose values are the "distance" from the center of the PDL (or whichever other center you specify).

=head3 Exercise

Create a three dimensional PDL using any of the above constructors and print out its information using the C<info> method.

    my $pdl = ...;
    say $pdl->info;
    __TEST__
    like($stdout, qr/\[\d+,\d+,\d+\]/,"Should print out information on a 3D piddle");

=head1 AUTHOR

Joel Berger, C<joel.a.berger@gmail.com>

