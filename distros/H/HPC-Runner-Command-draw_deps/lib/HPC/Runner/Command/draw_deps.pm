package HPC::Runner::Command::draw_deps;

our $VERSION = '3.0.0';

=head1 HPC::Runner::Command::draw_deps

Call the hpcrunner.pl draw_deps command

=cut

use MooseX::App::Command;
use Algorithm::Dependency::Source::HoA;
use Algorithm::Dependency::Ordered;
use Data::Dumper;
use GraphViz2;

extends 'HPC::Runner::Command';

with 'HPC::Runner::Command::Utils::Base';
with 'HPC::Runner::Command::Utils::Log';
with 'HPC::Runner::Command::submit_jobs::Utils::Scheduler';

command_short_description 'Draw out a job dependency tree';
command_long_description
'This command parses your input file, verifies your schedule, and draws out a dependency diagram.';

=head2 Attributes

=head2 Subroutines

=cut

sub BUILD {
    my $self = shift;

    $self->gen_load_plugins;
}

sub execute {
    my $self = shift;

    $self->parse_file_slurm();
    $self->iterate_schedule();
}

=head3 schedule_jobs

Use Algorithm::Dependency to schedule the jobs

We are overriding this method to produce our dependency trees

=cut

sub schedule_jobs {
    my $self = shift;

    my $source =
      Algorithm::Dependency::Source::HoA->new( $self->graph_job_deps );

    my $dep = Algorithm::Dependency::Ordered->new(
        source   => $source,
        selected => []
    );

    my ($graph) = GraphViz2->new(
        edge   => { color    => 'grey' },
        global => { directed => 1 },
        graph  => { rankdir => 'BT' },
        node   => { shape => 'oval' },
    );

    $graph -> dependency(data => $dep );

    my($format)      =  'svg';

    $graph -> run(format => $format, output_file => "dependency.hpc.$format" );

    exit 0;
}

1;

__END__

=encoding utf-8

=head1 NAME

HPC::Runner::Command::draw_deps - Draw out the dependency trees of HPC::Runner::Command files

=head1 SYNOPSIS

  use HPC::Runner::Command::draw_deps;

  hpcrunner.pl draw_deps --infile job_file.in

=head1 DESCRIPTION

HPC::Runner::Command::draw_deps - Draw out the dependency trees of HPC::Runner::Command files using GraphViz2.

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Jillian Rowe

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
