package Feed::PhaseCheck;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(compare_feeds);

# ABSTRACT: Finds the relative time delay between two feed segments.

=head1 NAME

Feed::PhaseCheck

Finds the relative time delay between two feed segments.

Accomplished by shifting one feed relative to the other and then computing the error (absolute difference).

The shift that yields the lowest error corresponds to the relative delay between he two input feeds.

The output consists of the delay found, and the error in delayed point.

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use Feed::PhaseCheck qw(compare_feeds);
    my $sample = {
        "1451276654" => "1.097655",
        "1451276655" => "1.09765",
        #...
        "1451276763" => "1.0976",
        "1451276764" => "1.097595"
    };
    my $compare_to = {
        "1451276629" => "1.09765",
        "1451276630" => "1.09764916666667",
        #...
        "1451276791" => "1.097595",
        "1451276792" => "1.097595"
    };
    my $max_delay_check = 30;    # seconds
    my ($errors,$delay_with_min_err) = compare_feeds($sample,$compare_to,$max_delay_check);

=cut

=head1 METHODS

=head2 compare_feeds

=cut

sub compare_feeds {
    my $sample          = shift;
    my $main            = shift;
    my $max_delay_check = shift || 0;

    if ($max_delay_check !~ /^\d+$/) {
        return;
    }

    if (ref $sample ne 'HASH' || scalar keys %$sample < 2) {
        return;
    }

    if (ref $main ne 'HASH' || scalar keys %$main < 2) {
        return;
    }

    my @main_epoches = sort keys %$main;
    foreach (@main_epoches) {
        if (int($_) != $_ || abs($main->{$_}) != $main->{$_}) {
            return;
        }
    }

    my @sample_epoches = sort keys %$sample;
    foreach (@sample_epoches) {
        if (int($_) != $_ || abs($sample->{$_}) != $sample->{$_}) {
            return;
        }
    }

    if ($sample_epoches[0] < $main_epoches[0] || $sample_epoches[-1] > $main_epoches[-1]) {
        return;
    }

    my %main  = %$main;
    my %error = ();
    my ($min_error, $delay_for_min_error);
    my $delay1 = $sample_epoches[0] - $main_epoches[0] < $max_delay_check   ? $sample_epoches[0] - $main_epoches[0]   : $max_delay_check;
    my $delay2 = $main_epoches[-1] - $sample_epoches[-1] < $max_delay_check ? $main_epoches[-1] - $sample_epoches[-1] : $max_delay_check;
    for (my $delay = -$delay1; $delay <= $delay2; $delay++) {
        $error{$delay} = 0;
        foreach my $epoch (@sample_epoches) {
            my $sample_epoch = $epoch - $delay;
            if (!defined $main{$sample_epoch}) {
                for (my $i = 1; $i < scalar keys @main_epoches; $i++) {
                    if ($main_epoches[$i] > $sample_epoch) {
                        $main{$sample_epoch} = _interpolate(
                            $main_epoches[$i - 1],
                            $main{$main_epoches[$i - 1]},
                            $main_epoches[$i], $main{$main_epoches[$i]},
                            $sample_epoch
                        );
                        last;
                    }
                }
            }
            $error{$delay} += ($main{$sample_epoch} - $sample->{$epoch})**2;
        }
        if (!defined $min_error || $error{$delay} < $min_error) {
            $min_error           = $error{$delay};
            $delay_for_min_error = $delay;
        }
        # $error{$delay} =~ s/(\d{8}).+?e/$1e/;
    }

    return (\%error, $delay_for_min_error);
}

sub _interpolate {
    my ($x1, $y1, $x2, $y2, $x) = @_;
    my $y = $y1 + ($x - $x1) * ($y2 - $y1) / ($x2 - $x1);
    return $y;
}

=head1 AUTHOR

Maksym Kotielnikov, C<< <maksym at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-feed-phasecheck at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Feed-PhaseCheck>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Feed::PhaseCheck


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Feed-PhaseCheck>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Feed-PhaseCheck>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Feed-PhaseCheck>

=item * Search CPAN

L<http://search.cpan.org/dist/Feed-PhaseCheck/>

=back


=head1 ACKNOWLEDGEMENTS



=cut

1;    # End of Feed::PhaseCheck
