package HPC::Runner::Threads;

use IPC::Open3;
use IO::Select;
use Symbol;
use Data::Dumper;
use Parallel::ForkManager;
use Log::Log4perl qw(:easy);
use DateTime;
use DateTime::Format::Duration;
use Cwd;
use Moose;
use Moose::Util::TypeConstraints;

extends 'HPC::Runner';

with 'MooseX::Getopt';
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

=head1 NAME

HPC::Runner::Threads - Job submission using threads

=head1 VERSION

Version 0.01

=cut

our $VERSION = '2.35';

=head1 SYNOPSIS

Use Parallel::ForkManager to run arbitrary bash commands

=head1 Attributes

=cut

=head2 twait

How frequently to test for a thread having exited the queue in seconds. Defaults to once every 60 seconds. If your jobs are very fast, you may want to decrease this number, or vice versa if they are very long.

=cut

has 'twait' => (
    is => 'rw',
    isa => 'Int',
    lazy => 1,
    required => 1,
    default => 60,
    documentation => q{How frequently to test for a thread having exited the queue in seconds. Defaults to once every 60 seconds.}
);

=head2 threads

This uses Parallel::ForkManager to deploy the threads. If you wish to use something else you must redefine it here.

=cut

has 'threads' => (
    traits  => ['NoGetopt'],
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        return new Parallel::ForkManager($self->procs);
    }
);

=head1 SUBROUTINES/METHODS

=head2 go

This is the main application. It starts the logging, build the threads, parses the file, runs the commands, and finishes logging.

=cut

sub go {
    my $self = shift;

    my $dt1 = DateTime->now();

    $self->prepend_logfile("MAIN_");
    $self->log($self->init_log);

    #Threads specific
    build_threads($self);

    $self->parse_file_threads;
    #End threads specific

    my $dt2 = DateTime->now();
    my $duration = $dt2 - $dt1;
    my $format = DateTime::Format::Duration->new(
        pattern => '%Y years, %m months, %e days, %H hours, %M minutes, %S seconds'
    );

    $self->log->info("Total execution time ".$format->format_duration($duration));
}

=head2 parse_file_threads

Parse the file of commands and send each command off to the queue.

#TODO
#Merge mce/threads subroutines

=cut


sub parse_file_threads{
    my $self = shift;

    my $fh = IO::File->new( $self->infile, q{<} ) or $self->log->fatal("Error opening file  ".$self->infile."  ".$!); # even better!

    my $cmd;
    while(<$fh>){
        my $line = $_;
        next unless $line;
        next unless $line =~ m/\S/;
        next if $line =~ m/^#/;

        if($self->has_cmd){
            $self->add_cmd($line);
            if($line =~ m/\\$/){
                next;
            }
            else{
                $self->log->info("Enqueuing command:\n".$self->cmd);
                $self->run_command_threads;
                $self->clear_cmd;
                $self->inc_counter;
            }
        }
        else{
            $self->cmd($line);
            if($line =~ m/\\$/){
                next;
            }
            elsif( $self->match_cmd(qr/^wait$/) ){
                $self->log->info("Beginning command:\n".$self->cmd);
                $self->log->info("Waiting for all children to exit...");
                $self->clear_cmd;
                $self->threads->wait_all_children;
                $self->log->info("All children are out of the pool!");
                $self->inc_counter;

            }
            else{
                $self->log->info("Enqueuing command:\n".$self->cmd);
                $self->run_command_threads;
                $self->clear_cmd;
                $self->inc_counter;
            }
        }
    }

    $self->threads->wait_all_children;

}

=head2 build_threads

This is the command to build the threads. To change this just add a build_threads method in your script.

    $self->threads->run_on_wait(
        sub {
            $self->log->debug("** Queue full. Waiting for one process to end ...");
        },
        $self->twait,
    );

or

    package Main;
    extends 'HPC::Runner::Threads';

    sub build_threads {

        $self->threads->run_on_wait(
            sub {
                $self->log->debug("** This is my custom message");
            },
            $self->twait,
        );
    }

=cut

sub build_threads{
    my $self = shift;

    $self->threads->run_on_wait(
        sub {
            $self->log->debug("** Queue full. Waiting for one process to end ...");
        },
        $self->twait,
    );
}

1;


=head1 See Also

L<Parallel::ForkManager>, L<HPC::Runner::GnuParallel>

=head1 AUTHOR

Jillian Rowe, C<< <jillian.e.rowe at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-runner-init at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HPC-Runner-Threads>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HPC::Runner::Threads


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HPC-Runner-Threads>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HPC-Runner-Threads>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HPC-Runner-Threads>

=item * Search CPAN

L<http://search.cpan.org/dist/HPC-Runner-Threads/>

=back

=head1 Acknowledgements

This module was originally developed at and for Weill Cornell Medical
College in Qatar within ITS Advanced Computing Team. With approval from
WCMC-Q, this information was generalized and put on github, for which
the authors would like to express their gratitude.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Weill Cornell Medical College Qatar.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
