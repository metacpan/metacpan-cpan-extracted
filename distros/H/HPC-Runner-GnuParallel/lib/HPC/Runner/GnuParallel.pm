#!/usr/bin/env perl

package HPC::Runner::GnuParallel;

our $VERSION = '0.07';

use DateTime;
use DateTime::Format::Duration;

use Moose;
#extends 'HPC::Runner';
#extends 'HPC::Runner::MCE';
extends qw(HPC::Runner HPC::Runner::MCE);

#with 'MooseX::Getopt';
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';

=encoding utf-8

=head1 NAME

HPC::Runner::GnuParallel - Run arbitrary bash commands using GNU parallel. Can be used on its own or as a part of HPC::Runner::Slurm.

=head1 SYNOPSIS


  package Main;

  use Moose;

  extends 'HPC::Runner::GnuParallel';

  Main->new_with_options()->go;

  1;

Run straight as :

  cat stuff.cmd | parallelparser.pl | parallel --joblog `pwd`/runtasks.log --gnu -N 1 -q  gnuparallelrunner.pl --command `echo {}` --outdir `pwd`/gnulogs/ --seq {#}

  Where stuff.cmd is a file with the commands you need run.

  Or as a part or HPC::Runner::Slurm distro.


=head1 DESCRIPTION

HPC::Runner::GnuParallel is a part of a suite of tools to make HPC easy.

=head1 Attributes

=head2 using_gnuparallel

Indicate whether or not to use gnu parallel

=cut

has 'using_gnuparallel' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
    required => 0,
);

=head2 infile

disable infile and read directly from the stream

=cut

has '+infile' => (
    required => 0,
);

has 'command' => (
    required => 1,
    isa => 'Str',
    is => 'rw',
);


has 'seq' => (
    is => 'rw',
    isa => 'Int',
    default => 1,
);

=head2 go

Initialize MCE things and use HPC::Runner to parse and exec commands

=cut

sub go{
    my $self = shift;

    my $dt1 = DateTime->now();

    $self->logname('gnuparallel');

    $self->prepend_logfile("MAIN_");
    $self->log($self->init_log);

    $self->parse_file_gnuparallel;

    $DB::single=2;

    my $dt2 = DateTime->now();
    my $duration = $dt2 - $dt1;
    my $format = DateTime::Format::Duration->new(
        pattern => '%Y years, %m months, %e days, %H hours, %M minutes, %S seconds'
    );

    $self->log->info("Total execution time ".$format->format_duration($duration));
    return;
}

=head2 parse_file_gnuparallel

Parse the file of commands and send each command off to the queue.

=cut

sub parse_file_gnuparallel{
    my $self = shift;

    $self->cmd($self->command);

    $DB::single=2;

    $self->counter($self->seq);
    $self->run_command_mce;
    $self->clear_cmd;
}


1;

__END__


=head1 Acknowledgements

Before version 0.05

This module was originally developed at and for Weill Cornell Medical
College in Qatar within ITS Advanced Computing Team. With approval from
WCMC-Q, this information was generalized and put on github, for which
the authors would like to express their gratitude.

As of version 0.05:

This modules continuing development is supported by NYU Abu Dhabi in the Center for Genomics and Systems Biology.
With approval from NYUAD, this information was generalized and put on bitbucket, for which
the authors would like to express their gratitude.

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2015- Weill Cornell Medical College in Qatar

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
