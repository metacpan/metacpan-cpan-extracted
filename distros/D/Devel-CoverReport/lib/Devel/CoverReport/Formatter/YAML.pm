# Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/

package Devel::CoverReport::Formatter::YAML;

use strict;
use warnings;

our $VERSION = "0.05";

use base 'Devel::CoverReport::Formatter';

use Carp::Assert::More qw( assert_defined );
use English qw( -no_match_vars );
use Params::Validate qw( :all );
use YAML::Syck 1.05 qw( DumpFile );

=encoding UTF-8

=head1 DESCRIPTION

Store L<Devel::CoverReport> reports as YAML data dumps - readable by both: humans, and machines.

=head1 WARNING

Consider this module to be an early ALPHA. It does the job for me, so it's here.

This is my first CPAN module, so I expect that some things may be a bit rough around edges.

The plan is, to fix both those issues, and remove this warning in next immediate release.

=head1 API

=over

=item process_report_start

=item process_table_start

=item process_row

=item process_summary

=item process_table_end

=item process_report_end

=item process_formatter_end

See: L<Devel::CoverReport::Formatter>.

=back

=cut

sub process_report_start { # {{{
    my ( $self, $report ) = @_;

    $self->{'Instance'}->{'metadata'} = {
        title   => $report->{'title'},
        version => $VERSION,
    };

    return;
} # }}}

sub process_table_start { # {{{
    my ( $self, $report, $table ) = @_;

    my %current_table = (
        label         => $table->{'label'},
        rows          => [],
        summary       => [],
        headers       => $table->get_headers(),
        headers_order => $table->get_headers_order(),
    );

    # Open the table:
    push @{ $self->{'Instance'}->{'data'}->{'tables'} }, \%current_table;

    $self->{'Instance'}->{'current_table'} = \%current_table;

    return;
} # }}}

sub process_row { # {{{
    my ( $self, $report, $table, $row ) = @_;

    $self->_process_in_row($report, $table, $row, 'rows');

    return;
} # }}}

sub process_summary { # {{{
    my ( $self, $report, $table, $summary ) = @_;

    $self->_process_in_row($report, $table, $summary, 'summary');

    return;
} # }}}

sub _process_in_row { # {{{
    my ( $self, $report, $table, $row, $_target ) = @_;

    push @{ $self->{'Instance'}->{'current_table'}->{$_target} }, $row;

    return;
} # }}}

sub process_report_end { # {{{
    my ( $self, $report ) = @_;

    assert_defined($self->{'basedir'},    'Missing basedir!');
    assert_defined($report->{'basename'}, 'Missing basename!');

    my $report_filename = $self->{'basedir'} . q{/} . $report->{'basename'} . q{.yml};

    DumpFile($report_filename, { metadata=>$self->{'Instance'}->{'metadata'}, data=>$self->{'Instance'}->{'data'} });

    $self->{'Instance'} = undef;

    return $report_filename;
} # }}}

1;

=head1 LICENCE

Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)

This is free software. It is licensed, and can be distributed under the same terms as Perl itself.

For more, see my website: http://bs502.pl/

=cut

# vim: fdm=marker

