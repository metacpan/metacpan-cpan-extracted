package Devel::StatProfiler::Html;

use strict;
use warnings;

use Devel::StatProfiler::Report;

sub process {
    my (%opts) = @_;
    my $report = Devel::StatProfiler::Report->new(
        flamegraph      => 1,
        sources         => 1,
        mixed_process   => 1,
    );

    my %state;
    for my $f (@{$opts{files}}) {
        my $r = Devel::StatProfiler::Reader->new($f);
        my ($process_id) = @{$r->get_genealogy_info};
        if (my $process_state = $state{$process_id}) {
            $r->set_reader_state(delete $process_state->{reader_state});
        }
        eval {
            $report->add_trace_file($r);

            1;
        } or do {
            my $error = $@ || "Zombie error";

            warn sprintf "Error reading trace file '%s': %s'", $f, $error;
        };
        $report->map_source($process_id);
        $state{$process_id}->{reader_state} = $r->get_reader_state
    }

    return $report;
}

sub process_and_output {
    my (%opts) = @_;
    my $report = process(%opts);
    my $diagnostics = $report->output($opts{output});

    for my $diagnostic (@$diagnostics) {
        print STDERR $diagnostic, "\n";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::StatProfiler::Html

=head1 VERSION

version 0.56

=head1 AUTHORS

=over 4

=item *

Mattia Barbon <mattia@barbon.org>

=item *

Steffen Mueller <smueller@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Mattia Barbon, Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
