package Gnuplot::Builder::Wgnuplot;
use strict;
use warnings;
use Exporter ();
use Gnuplot::Builder 0.11 ();
use Gnuplot::Builder::Process;

sub import {
    my $class = shift;
    @Gnuplot::Builder::Process::COMMAND = qw(gnuplot_builder_tempfile_wrapper wgnuplot -persist);
    Gnuplot::Builder->export_to_level(1, $class, @_);
}


1;
__END__

=pod

=head1 NAME

Gnuplot::Builder::Wgnuplot - wrap wgnuplot with gnuplot_builder_tempfile_wrapper

=head1 SYNOPSIS

    ## use Gnuplot::Builder;         ## instead of Gnuplot::Builder...
    use Gnuplot::Builder::Wgnuplot;  ## use this in Windows interactive session.
    
    my $script = gscript(terminal => "windows");
    $script->plot("sin(x)", "cos(x)");


=head1 DESCRIPTION

L<Gnuplot::Builder::Wgnuplot> is a drop-in replacement (or strictly speaking, a wrapper) for L<Gnuplot::Builder>.
It loads L<Gnuplot::Builder> and sets

    @Gnuplot::Builder::Process::COMMAND = qw(gnuplot_builder_tempfile_wrapper wgnuplot -persist)

This means it changes the back-end to "wgnuplot" and script text is given to it as a temporary file.

Note that if you use L<Gnuplot::Builder::Wgnuplot>, you cannot get diagnostic messages from plotting methods such as C<plot()>.
This is because "wgnuplot" does not use pipes at all and C<gnuplot_builder_tempfile_wrapper> discards the output in the first place.

=head2 Why Do I Need This?

It seems "wgnuplot" is the only implementation in Windows platform that can handle persistent plot windows correctly.

Use this module if and only if you are on Windows and you want to plot graphs in interactive plot windows
(i.e. use "windows" or "wxt" terminals).


=head1 CAVEAT

As of gnuplot 4.6, "wgnuplot" has a bug that it turns into a never-ending zombie process
if it does not create a plot window.

This means if you call C<ghelp()>, "wgnuplot" process persists even after you close the help window.
To terminate the process, you have to use the Task Manager.

=over

=item *

L<http://sourceforge.net/p/gnuplot/bugs/1335/>

=item *

L<http://sourceforge.net/p/gnuplot/bugs/1343/>

=back

=head1 FUNCTIONS

L<Gnuplot::Builder::Wgnuplot> exports just the same functions as L<Gnuplot::Builder>.

=head1 SEE ALSO

=over

=item *

L<Gnuplot::Builder>

=item *

L<Gnuplot::Builder::TempFile>

=back

=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=cut
