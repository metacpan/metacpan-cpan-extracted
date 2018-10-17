# -*-cperl-*-
#
# IPC::Queue::Duplex::Job - An IPC::Queue::Duplex job
# Copyright (c) Ashish Gulhati <ipc-qd at hash.neo.tc>
#
# $Id: lib/IPC/Queue/Duplex/Job.pm v1.009 Tue Oct 16 21:48:32 PDT 2018 $

package IPC::Queue::Duplex::Job;

use Time::HiRes qw(usleep);

sub new {
  my ($class, %args) = @_;
  bless { %args }, $class;
}

sub finish {
  my ($self, $result) = @_;
  my $filefin = $self->{File}; $filefin =~ s/\.wrk/.fin/;
  open (RESULT, ">$self->{File}");
  print RESULT "$result\n";
  close RESULT;
  rename $self->{File}, $filefin;
}

sub response {
  my $self = shift;
  my $filefin = my $fileiqd = $self->{File}; $filefin =~ s/\.job/.fin/; $fileiqd =~ s/\.job/.iqd/;
  while (!-f $filefin) {
    usleep 10000;
  }
  open (RESPONSE, $filefin);
  my $response = <RESPONSE>;
  close $filefin;
  if ($response) {
    unlink $filefin; unlink $fileiqd;
    chomp $response;
    return $response;
  }
  else {
    print STDERR "DEBUG: $filefin\n";
  }
}

sub delete {
  unlink shift->{File};
}

1; # End of IPC::Queue::Duplex

=head1 NAME

IPC::Queue::Duplex::Job - An IPC::Queue::Duplex job

=head1 VERSION

 $Revision: 1.009 $
 $Date: Tue Oct 16 21:48:32 PDT 2018 $

=head1 SYNOPSIS

    (Enqueuer)

    use IPC::Queue::Duplex;

    my $client = new IPC::Queue::Duplex (Dir => $dir);
    my $job = $client->add($jobstr);
    my $response = $job->response;

    (Worker)

    use IPC::Queue::Duplex;

    my $server = new IPC::Queue::Duplex (Dir => $dir);
    my $job = $server->get:
    process_job($job);
    $job->finish($result);

=head1 METHODS

=head2 new

Not intended to be called directly. Use an IPC::Queue::Duplex object
to create jobs.

=head2 finish

A job worker calls this method with a single argument, a string
containing the result of the job. This marks the job finished and
returns the result to the requester.

=head2 response

A requester calls this method with no arguments after placing a job on
the queue. It returns the result of the job when it's available.

=head2 delete

Deletes this job from the queue. No arguments.

=head1 AUTHOR

Ashish Gulhati, C<< <ipc-qd at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ipc-queue-duplex at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPC-Queue-Duplex>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPC::Queue::Duplex::Job

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IPC-Queue-Duplex>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IPC-Queue-Duplex>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IPC-Queue-Duplex>

=item * Search CPAN

L<http://search.cpan.org/dist/IPC-Queue-Duplex/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) Ashish Gulhati.

This software package is Open Software; you can use, redistribute,
and/or modify it under the terms of the Open Artistic License 2.0.

Please see L<http://www.opensoftwr.org/oal20.txt> for the full license
terms, and ensure that the license grant applies to you before using
or modifying this software. By using or modifying this software, you
indicate your agreement with the license terms.
