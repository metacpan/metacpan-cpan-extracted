package HPC::Runner::Slurm;

use File::Path qw(make_path remove_tree);
use File::Temp qw/ tempfile tempdir /;
use IO::File;
use IO::Select;
use Cwd;
use IPC::Open3;
use Symbol;
use Template;
use Log::Log4perl qw(:easy);
use DateTime;
use Data::Dumper;
use List::Util qw/shuffle/;

use Moose;
use namespace::autoclean;
extends 'HPC::Runner::Scheduler';
with 'MooseX::SimpleConfig';

# For pretty man pages!
$ENV{TERM}='xterm-256color';
our $VERSION = '2.58';

=head1 NAME

HPC::Runner::Slurm - Job Submission to Slurm

=head1 SYNOPSIS

Please see the indepth documentation at L<HPC::Runner::Usage>.

    package Main;
    extends 'HPC::Runner::Slurm';

    Main->new_with_options(infile => '/path/to/commands');

This module is a wrapper around sbatch and can be used to submit arbirtary bash commands to slurm.

It has two levels of management. The first is the main sbatch command, and the second is the actual job, which runs commands in parallel, controlled by HPC::Runner::Threads or HPC::Runner::MCE.

It supports job dependencies. Put in the command 'wait' to tell slurm that some job or jobs depend on some other jobs completion. Put in the command 'newnode' to tell HPC::Runner::Slurm to submit the job to a new node.

The only necessary option is the --infile.

=head2 Submit Script

    cmd1
    cmd2 && cmd3
    cmd4 \
    --option cmd4 \
    #Tell HPC::Runner::Slurm to put in some job dependencies.
    wait
    cmd5
    #Tell HPC::Runner::Slurm to pass things off to a new node, but this job doesn't depend on the previous
    newnode
    cmd6

=head2 get_nodes

Get the nodes from sinfo if not supplied

If the nodelist is supplied partition must be supplied

=cut

sub BUILD {
    my $self = shift;
    $self->logname('slurm_logs');
    $self->log($self->init_log);
}

#sub get_nodes{
    #my($self) = @_;

    #$DB::single=2;
##    #Fix - had this backwards
    #return if $self->slurm_decides;

    #if($self->nodelist && !$self->partition){
        #print "If you define a nodelist you must define a partition!\n";
        #die;
    #}

    #my @s = `sinfo -r`;
    #my $href;

    #foreach my $s (@s) {
        #my @nodes = ();
        #my $noderef = [];
        #next if $s =~ m/^PARTITION/i;
        #my @t = ($s =~ /(\S+)/g);
        #$t[0] =~ s/\*//g;
        #next unless $t[1] =~ m/up/;

        #my $nodes = $t[5];

        ##list of nodes
        #if($nodes =~ m/\[/){
            #my($n) = ($nodes =~ m/\[(\S+)\]/g);
            #my @n = split(",", $n);

            #foreach my $nt (@n) {
                #if($nt =~ m/-/){
                    #my(@m) = ($nt =~ m/(\d+)-(\d+)/g);
                    #push(@$noderef, ($m[0]..$m[1]));
                #}
                #else{
                    #my($m) = ($nt =~ m/(\d+)/g);
                    #push(@$noderef, $m);
                #}
            #}
        #}
        #else{ #only one node
            #my($m) = ($nodes =~ m/(\d+)/g);
            #push(@$noderef, $m);
        #}

        #if(exists $href->{$t[0]}){
            #my $aref = $href->{$t[0]};
            #push(@$aref, @$noderef) if $noderef;
            #$href->{$t[0]} = $aref;
        #}
        #else{
##        $href->{$t[0]} = \@nodes;
            #$href->{$t[0]} = $noderef;
        #}
    #}

##Got the nodes lets find out which partition has the most nodes
##Unless we already have a defined partition, then we don't care

    #my $holder = 0;
    #my $bpart;

    #while(my($part, $nodes) = each %{$href}){
        #next unless $nodes;
        #next unless ref($nodes) eq "ARRAY";

        #@$nodes = map { $part.$_ } @$nodes;

        #if(scalar @$nodes > $holder){
            #$holder = scalar @$nodes;
            #$bpart = $part;
        #}
    #}

    ##Allow for user defined partition and/or partition/nodelist
    ##Also randomize nodelist so we quit hammering the first node
    #$DB::single=2;

    #if($self->partition && $self->nodelist){
        #$DB::single=2;
        #return;
    #}
    #elsif($self->partition){
        #$DB::single=2;
        #my @shuffle = shuffle @{$href->{$self->partition}};
##        $self->nodelist($href->{$self->partition});
        #$self->nodelist(\@shuffle);
        #return;
    #}

    #$self->partition($bpart);
##    $self->nodelist($href->{$bpart});
    #my @shuffle = shuffle @{$href->{$bpart}};
    #$self->nodelist(\@shuffle);
#}



=head2 submit_slurm()

Submit jobs to slurm queue using sbatch.

This subroutine was just about 100% from the following perlmonks discussions. All that I did was add in some logging.

http://www.perlmonks.org/?node_id=151886
You can use the script at the top to test the runner. Just download it, make it executable, and put it in the infile as

perl command.pl 1
perl command.pl 2
#so on and so forth

=cut

sub submit_slurm{
    my $self = shift;

    my ($infh,$outfh,$errfh);
    $errfh = gensym(); # if you uncomment this line, $errfh will
    # never be initialized for you and you
    # will get a warning in the next print
    # line.
    my $cmdpid;
    eval{
        $cmdpid = open3($infh, $outfh, $errfh, "sbatch ".$self->slurmfile);
    };
    die $@ if $@;

    my $sel = new IO::Select; # create a select object
    $sel->add($outfh,$errfh); # and add the fhs

    my($stdout, $stderr, $jobid);

    while(my @ready = $sel->can_read) {
        foreach my $fh (@ready) { # loop through them
            my $line;
            # read up to 4096 bytes from this fh.
            my $len = sysread $fh, $line, 4096;
            if(not defined $len){
                # There was an error reading
                #$self->log->fatal("Error from child: $!");
                $self->log_main_messages('fatal', "Error from child: $!");
            } elsif ($len == 0){
                # Finished reading from this FH because we read
                # 0 bytes.  Remove this handle from $sel.
                $sel->remove($fh);
                next;
            } else { # we read data alright
                if($fh == $outfh) {
                    $stdout .= $line;
                    #$self->log->info($line);
                    $self->log_main_messages('debug', $line)
                } elsif($fh == $errfh) {
                    $stderr .= $line;
                    #$self->log->error($line);
                    $self->log_main_messages('error', $line);
                } else {
                    #$self->log->fatal("Shouldn't be here!\n");
                    $self->log_main_messages('fatal', "Shouldn't be here!");
                }
            }
        }
    }

    waitpid($cmdpid, 1);
    my $exitcode = $?;

    ($jobid) = $stdout =~ m/Submitted batch job (\d.*)$/ if $stdout;
    if(!$jobid){
        print "No job was submitted! Please check to make sure you have loaded modules shared and slurm!\nFull error is:\t$stderr\n$stdout\nEnd Job error";
        print "Submit scripts will be written, but will not be submitted to the queue. Please look at your files in ".$self->outdir." for more information\n";
        $self->submit_to_slurm(0);
    }
    else{
        push(@{$self->jobref->[-1]}, $jobid);
        print "Submitting job ".$self->slurmfile."\n\tWith Slurm jobid $jobid\n";
    }
}

=head1 AUTHOR

Jillian Rowe, C<< <jillian.e.rowe at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-runner-init at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HPC-Runner-Slurmm>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HPC::Runner::Slurm


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HPC-Runner-Slurm>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HPC-Runner-Slurm>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HPC-Runner-Slurm>

=item * Search CPAN

L<http://search.cpan.org/dist/HPC-Runner-Slurm/>

=back

=head1 Acknowledgements

Before Version 2.41

This module was originally developed at and for Weill Cornell Medical
College in Qatar within ITS Advanced Computing Team. With approval from
WCMC-Q, this information was generalized and put on github, for which
the authors would like to express their gratitude.

As of Version 2.41:

This modules continuing development is supported by NYU Abu Dhabi in the Center for Genomics and Systems Biology.
With approval from NYUAD, this information was generalized and put on bitbucket, for which
the authors would like to express their gratitude.


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Weill Cornell Medical College in Qatar.

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

__PACKAGE__->meta->make_immutable;
#use namespace::autoclean;

1;
