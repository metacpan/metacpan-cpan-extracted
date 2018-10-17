# -*-cperl-*-
#
# IPC::Queue::Duplex - Filesystem based request / response queue
# Copyright (c) Ashish Gulhati <ipc-qd at hash.neo.tc>
#
# $Id: lib/IPC/Queue/Duplex.pm v1.009 Tue Oct 16 21:48:32 PDT 2018 $

package IPC::Queue::Duplex;

use warnings;
use strict;
use File::Temp;
use File::Copy qw(cp);
use IPC::Queue::Duplex::Job;
use Fcntl qw(:flock);

our ( $VERSION ) = '$Revision: 1.009 $' =~ /\s+([\d\.]+)/;

sub new {
  my ($class, %args) = @_;
  return unless $args{Dir} and -d $args{Dir};
  bless { Dir => $args{Dir} }, $class;
}

sub add {
  my ($self, $jobstr) = @_;
  return unless $jobstr;
  my $job = File::Temp->new( DIR => $self->{Dir}, SUFFIX => '.iqd');
  print $job "$jobstr\n";
#  $job->unlink_on_destroy(0);
  $job->close; my $filename = $job->filename; $filename =~ s/\.iqd/.job/;
  cp($job->filename,$filename);
  bless { File => $filename }, 'IPC::Queue::Duplex::Job';
}

sub addfile {
  my ($self, $filename, $jobstr) = @_;
  return unless $filename and $jobstr;
  my $filetemp = $filename; $filetemp .= '.iqdtmp';
  open JOBFILE, ">$filetemp";
  print JOBFILE "$jobstr\n";
  close JOBFILE;
  rename $filetemp, $filename;
  bless { File => $filename }, 'IPC::Queue::Duplex::Job';
}

sub get {
  my $self = shift;
  my $filework = '';
  while (1) {
    my $filename; my $oldestage;
    foreach my $file (glob("$self->{Dir}/*.job")) {
      if( !defined($filename) or -M $file > $oldestage ) {
	$filename = $file;
	$oldestage = -M $file;
      }
    }
    last unless $filename;
    next unless -e $filename;
    open(my $jobfh, "+<", $filename);
    close $jobfh, next unless flock($jobfh, LOCK_EX | LOCK_NB);
    $filework = $filename; $filework =~ s/\.job/.wrk/;
    close $jobfh, last if rename $filename,$filework;
  }
  if ($filework) {
    open (JOB, $filework);
    my $jobstr = <JOB>; chomp $jobstr;
    close JOB;
    return bless { File => $filework, Request => $jobstr }, 'IPC::Queue::Duplex::Job';
  }
  return undef;
}

sub getresponse {
  my $self = shift;
  my ($filename, $filefin);
  while (1) {
    my $oldestage;
    foreach my $file (glob("$self->{Dir}/*.fin")) {
      if( !defined($filename) or -M $file > $oldestage ) {
	$filename = $file;
	$oldestage = -M $file;
      }
    }
    last unless $filename;
    next unless -e $filename;
    open(my $jobfh, "+<", $filename);
    close $jobfh, next unless flock($jobfh, LOCK_EX | LOCK_NB);
    $filefin = $filename; $filefin =~ s/\.fin/.rsp/;
    close $jobfh, last if rename $filename,$filefin;
  }
  if ($filefin) {
    open (JOBFIN, $filefin);
    my $response = <JOBFIN>; chomp $response;
    close JOBFIN; unlink $filefin;
    return bless { File => $filename, Response => $response }, 'IPC::Queue::Duplex::Job';
  }
  return undef;
}

1; # End of IPC::Queue::Duplex

=head1 NAME

IPC::Queue::Duplex - Filesystem based request / response queue

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

Creates and returns a new IPC::Queue::Duplex object. Requires one
named parameter:

=over

Dir - The directory that will contain the queue for this object. It's
important to use a unique directory per queue,

=back

=head2 add

Adds a job to the queue and returns an IPC::Queue::Duplex::Job
object. A single aregument is required, the job request as a string.

=head2 get

Gets a job from the queue and returns an IPC::Queue::Duplex::Job
object. Returns undef if there is no job waiting.

=head2 addfile

Adds a job to the queue, with an explicitly provided filename, and
returns an IPC::Queue::Duplex::Job object. Two arguments are required:
the filename to use for the job, and the job request string, in that
order.

=head2 getresponse

Get a response from the queue. Normally a requester would hold on to
their job object and get the response by calling the response method
on that object. However, a requester can can also handle responses
asynchronously and call this method to get the next waiting response
instead. Returns an IPC::Queue::Duplex::Job object, or undef if there
is no response on the queue.

=head1 AUTHOR

Ashish Gulhati, C<< <ipc-qd at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ipc-queue-duplex at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPC-Queue-Duplex>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPC::Queue::Duplex

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
