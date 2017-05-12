package Gnuplot::Builder::Tap;
use strict;
use warnings;

sub import {
    require Gnuplot::Builder::Process;
    $Gnuplot::Builder::Process::TAP = sub {
        print $_[2] if $_[1] eq "write";
    };
}

1;
__END__

=pod

=head1 NAME

Gnuplot::Builder::Tap - tap the IPC between Gnuplot::Builder and the gnuplot process

=head1 SYNOPSIS

    $ perl -MGnuplot::Builder::Tap your_gnuplot_builder_script.pl

=head1 DESCRIPTION

L<Gnuplot::Builder::Tap> taps the IPC between L<Gnuplot::Builder> and the gnuplot process,
and it dumps the data written to the process to STDOUT.
This is useful for debugging.

The tap is made by L<Gnuplot::Builder::Tap>'s C<import()> method,
so you can enable the tap by C<-M> perl option (See L</SYNOPSIS>).

=head1 CLASS METHOD

=head2 Gnuplot::Builder::Tap->import()

Called when you C<< use Gnuplot::Builder::Tap >>.

It sets C<$Gnuplot::Builder::Process::TAP> package variable,
so all data written to gnuplot processes are dumped to STDOUT.

=head1 POSSIBLE CHANGES IN FUTURE

Current version of C<import()> method takes no argument,
but in future it may take arguments to configure how to tap the IPC.

Current version of L<Gnuplot::Builder::Tap> is NOT a pragma,
so effect of C<import()> method is global.
In future, it may become a pragma, i.e., the effect of C<import()> (and C<unimport()>) methods may be confined in the lexical block.

=head1 SEE ALSO

=over

=item *

L<Gnuplot::Builder::Process>

=item *

L<perlrun>

=back

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
