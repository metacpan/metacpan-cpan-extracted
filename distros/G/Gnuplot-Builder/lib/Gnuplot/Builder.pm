package Gnuplot::Builder;
use strict;
use warnings;
use parent qw(Exporter);
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Dataset;
use Gnuplot::Builder::Process;

our $VERSION = "0.31";

our @EXPORT = our @EXPORT_OK = qw(gscript gfunc gfile gdata ghelp gwait);

sub gscript {
    return Gnuplot::Builder::Script->new(@_);
}

sub gfunc {
    return Gnuplot::Builder::Dataset->new(@_);
}

sub gfile {
    return Gnuplot::Builder::Dataset->new_file(@_);
}

sub gdata {
    return Gnuplot::Builder::Dataset->new_data(@_);
}

sub ghelp {
    my (@help_args) = @_;
    return Gnuplot::Builder::Process->with_new_process(do => sub {
        my $writer = shift;
        $writer->("help");
        foreach my $arg (@help_args) {
            $writer->(" $arg");
        }
        $writer->("\n");
    });
}

sub gwait {
    return Gnuplot::Builder::Process->wait_all();
}

1;
__END__

=pod

=head1 NAME

Gnuplot::Builder - object-oriented gnuplot script builder

=head1 SYNOPSIS

    use Gnuplot::Builder;
    
    my $script = gscript(grid => "y", mxtics => 5, mytics => 5);
    $script->setq(
        xlabel => 'x values',
        ylabel => 'y values',
        title  => 'my plot'
    );
    $script->define('f(x)' => 'sin(x) / x');
    
    print $script->plot(
        gfile('result.dat',
              using => '1:2:3', title => "'Measured'", with => "yerrorbars"),
        gfunc('f(x)', title => "'Theoretical'", with => "lines")
    );
    
    gwait();


=head1 DESCRIPTION

L<Gnuplot::Builder> is a gnuplot script builder. Its advantages include:

=over

=item *

B<Object-oriented>. Script settings are encapsulated in a L<Gnuplot::Builder::Script> object,
and dataset parameters are in a L<Gnuplot::Builder::Dataset> object.
It eliminates global variables, which gnuplot uses extensively.

=item *

B<Thin>. L<Gnuplot::Builder> just builds a script text and streams it into a gnuplot process.
Its behavior is extremely predictable and easy to debug.

=item *

B<Hierarchical>. L<Gnuplot::Builder::Script> and L<Gnuplot::Builder::Dataset> objects support
prototype-based inheritance, just like JavaScript objects.
This is useful for hierarchical configuration.

=item *

B<Interactive>. L<Gnuplot::Builder> works well both in batch scripts and in interactive shells.
Use L<Devel::REPL> or L<Reply> or whatever you like instead of the plain old gnuplot interative shell.

=item *

B<Parallel>. L<Gnuplot::Builder>'s policy is "one gnuplot process for one plot".
You can run more than one gnuplot processes in parallel to boost the plotting through-put.

=back

=head1 USAGE GUIDE

L<Gnuplot::Builder> module is meant to be used in interactive shells.
It exports some easy-to-type functions by default.

For batch scripts, I recommend using L<Gnuplot::Builder::Script> and L<Gnuplot::Builder::Dataset> directly.
These modules are purely object-oriented, and won't mess up your namespace.

=head2 For Windows Users

Batch scripts using L<Gnuplot::Builder> are fine in Windows.

In interactive shells, plot windows might not persist when you use regular L<Gnuplot::Builder>.
As a workaround, try L<Gnuplot::Builder::Wgnuplot>.

=head2 Plot Windows

L<Gnuplot::Builder> supports plots in interactive windows.
See L</CONFIGURATION FOR PLOT WINDOWS> for known issues about that.

=head2 Debugging

Because L<Gnuplot::Builder> is a very thin module,
it does not guarantee to build valid gnuplot scripts.
You need to debug your script when you got an invalid script.
See L</DEBUGGING TIPS> for detail.

=head1 EXPORTED FUNCTIONS

L<Gnuplot::Builder> exports the following functions by default.

=head2 $script = gscript(@script_options)

Create a script object. It's just an alias for C<< Gnuplot::Builder::Script->new(...) >>.
See L<Gnuplot::Builder::Script> for detail.

=head2 $dataset = gfunc($funcion_spec, @dataset_options)

Create a dataset object representing a function, such as "sin(x)" and "f(x)".
It's just an alias for C<< Gnuplot::Builder::Dataset->new(...) >>.
See L<Gnuplot::Builder::Dataset> for detail.

=head2 $dataset = gfile($filename, @dataset_options)

Create a dataset object representing a data file.
It's just an alias for C<< Gnuplot::Builder::Dataset->new_file(...) >>.
See L<Gnuplot::Builder::Dataset> for detail.

=head2 $dataset = gdata($inline_data, @dataset_options)

Create a dataset object representing a data file.
It's just an alias for C<< Gnuplot::Builder::Dataset->new_data(...) >>.
See L<Gnuplot::Builder::Dataset> for detail.

=head2 $help_message = ghelp(@help_args)

Run the gnuplot "help" command and return the help message.
C<@help_args> is the arguments for the "help" command. They are joined with white spaces.

    ghelp("style data");
    
    ## or you can say
    
    ghelp("style", "data");

=head2 gwait()

Wait for all gnuplot processes to finish.
It's just an alias for C<< Gnuplot::Builder::Process->wait_all() >>.

=head1 CONFIGURATION FOR PLOT WINDOWS

L<Gnuplot::Builder> supports plots in interactive windows (terminals
such as "x11", "windows" etc). However, plot windows are very tricky,
so you might have to configure L<Gnuplot::Builder> in advance.

=head2 Design Goals

In terms of plot windows, L<Gnuplot::Builder> aims to achieve the following goals.

=over

=item *

Plotting methods should return immediately, without waiting for plot windows to close.

=item *

Plot windows should persist even after the Perl process using L<Gnuplot::Builder> exits.

=item *

Plot windows should be fully interactive. It should allow zooming and clipping etc.

=back

=head2 Configuration Patterns and Their Problems

The best configuration to achieve the above goals depends on
your platform OS, version of your gnuplot, the terminal to use and the libraries it uses.
Unfortunately there is no one-size-fits-all solution.

If you use Windows, just use L<Gnuplot::Builder::Wgnuplot>.

Otherwise, you have two configuration points.

=over

=item persist mode

Whether or not gnuplot's "persist" mode is used.
This is configured by C<@Gnuplot::Builder::Process::COMMAND> variable.

    @Gnuplot::Builder::Process::COMMAND = qw(gnuplot);           ## persist OFF
    @Gnuplot::Builder::Process::COMMAND = qw(gnuplot --persist); ## persist ON

By default, it's ON.

=item pause mode

Whether or not "pause mouse close" command is used.
This is configured by C<$Gnuplot::Builder::Process::PAUSE_FINISH> variable.

    $Gnuplot::Builder::Process::PAUSE_FINISH = 0; ## pause OFF
    $Gnuplot::Builder::Process::PAUSE_FINISH = 1; ## pause ON

By default, it's OFF.

=back

The above configurations can be set via environment variables.
See L<Gnuplot::Builder::Process> for detail.
Note that B<< the default values for these configurations may be changed in future releases. >>

I recommend "persist: OFF, pause: ON" B<< unless you use "qt" terminal with gnuplot 4.6.5 or below >>.
This makes a fully functional plot window whose process gracefully exits
when you close the window.

If you use "qt" terminal with gnuplot 4.6.5 or below,
use "persist: ON, pause: OFF".
This is because, as of gnuplot 4.6.5, "qt" terminal doesn't respond to the "pause" command,
leading to a never-ending process.
This process-leak can be dangerous, so the "pause" mode is OFF by default.
This bug is fixed in gnuplot 4.6.6.

The default setting "persist: ON, pause: OFF" doesn't cause process-leak in all environments I tested.
However, plot windows of "x11" or "qt" terminals in "persist" mode lack interactive functionality
such as zooming and clipping.
This is gnuplot's limitation in "persist" mode.
"wxt" terminal may be unstable (it crashes or freezes) in some environments.

=head1 DEBUGGING TIPS

Plotting methods of L<Gnuplot::Builder::Script> returns the output from the gnuplot process.
Always show the return value, because it contains an error message when something is wrong.

    my $script = Gnuplot::Builder::Script->new();
    ## my $script = gscript();   ## same
    
    print $script->plot("sin(x)");

Sometimes you need to peek the script text written to the gnuplot process.
To do that, run your program with L<Gnuplot::Builder::Tap> loaded.

    $ perl -MGnuplot::Builder::Tap your_program.pl

Or you can set C<$Gnuplot::Builder::Process::TAP> variable. See L<Gnuplot::Builder::Process> for detail.

=head2 Common Errors

=over

=item *

Quote string literals explicitly.

    $script->set(xlabel => 'hogehoge');   ## NG!
    $script->set(xlabel => '"hogehoge"'); ## OK
    $script->setq(xlabel => 'hogehoge');  ## OK

=item *

Arrange dataset options in valid order.

    $dataset = gfile('data.txt', with => "linespoints", using => "1:3"); ## NG!
    $dataset = gfile('data.txt', using => "1:3", with => "linespoints"); ## OK

=back

=head1 REPOSITORY

L<https://github.com/debug-ito/Gnuplot-Builder>

=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/debug-ito/Gnuplot-Builder/issues>.

Although I prefer Github, non-Github users can use CPAN RT
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Gnuplot-Builder>.
Please send email to C<bug-Gnuplot-Builder at rt.cpan.org> to report bugs
if you do not have CPAN RT account.


=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>

=head1 CONTRIBUTORS

=over

=item *

Moritz Grosch (LittleFox)

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

