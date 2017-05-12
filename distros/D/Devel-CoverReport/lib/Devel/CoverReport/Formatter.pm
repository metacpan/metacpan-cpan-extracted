# Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/

package Devel::CoverReport::Formatter;

use strict;
use warnings;

our $VERSION = "0.05";

use Devel::CoverReport::Table;

use Carp::Assert::More qw( assert_defined assert_lacks );
use Params::Validate qw( :all );

=encoding UTF-8

=head1 DESCRIPTION

Base class for report formatters.

=head1 WARNING

Consider this module to be an early ALPHA. It does the job for me, so it's here.

This is my first CPAN module, so I expect that some things may be a bit rough around edges.

The plan is, to fix both those issues, and remove this warning in next immediate release.

=head1 API

=over

=item new

Constructor for report formatters derived from C<Devel::CoverReport::Formatter>.

=cut
sub new { # {{{
    my $class = shift;
    my %P = @_;
    validate(
        @_,
        {
            basedir => { type=>SCALAR },
        }
    );

    my $self = {
        reports => {},

        basedir => $P{'basedir'},

        # Place for the instance, to keep it's data.
        Instance => {},
    };

    bless $self, $class;

    if (not -d $self->{'basedir'}) {
        # FIXME: create whole path!!!
        mkdir $self->{'basedir'};
    }

    $self->process_formatter_start();

    return $self;
} # }}}

=item add_report

Open new report.

Parameters: $self + (HASH)
  code     - report codename, used to uniquely identify a report.
  basename - file, where report will be saved. Without extension.
  title    - short title for the report.
=cut
sub add_report { # {{{
    my $self = shift;
    my %report_params = @_;
    validate(
        @_,
        {
            code     => { type=>SCALAR },
            basename => { type=>SCALAR },
            title    => { type=>SCALAR },
        }
    );
    
    assert_defined($report_params{'code'},     'Report code must be given!');
    assert_defined($report_params{'basename'}, 'Report basename must be given!');
    assert_defined($report_params{'title'},    'Report title must be given!');
    
    assert_lacks($self->{'reports'}, $report_params{'code'}, 'Report (' . $report_params{'code'} . ') already exists!');

    # fixme: do not allow a report to be overwritten!

    $self->{'reports'}->{ $report_params{'code'} } = {
        tables       => {},
        tables_order => [],

        basename => $report_params{'basename'},
        title    => $report_params{'title'},
    };

    return $self->{'reports'}->{ $report_params{'code'} };
} # }}}

=item close_report

Close selected report, format it and write to disk.

Parameters: (ARRAY)
  $self
  $code - report's code.
=cut
sub close_report { # {{{
    my ( $self, $code ) = @_;
    
    assert_defined($code, 'Report code must be given!');
    assert_defined($self->{'reports'}->{$code}, 'No report:' . $code);

    $self->process_report_start($self->{'reports'}->{$code});

    foreach my $table_code (@{ $self->{'reports'}->{$code}->{'tables_order'} }) {
        my $table = $self->{'reports'}->{$code}->{'tables'}->{$table_code};

        $self->process_table_start($self->{'reports'}->{$code}, $table);

        foreach my $row (@{ $table->get_rows() }) {
            $self->process_row($self->{'reports'}->{$code}, $table, $row);
        }

        foreach my $row (@{ $table->get_summary() }) {
            $self->process_summary($self->{'reports'}->{$code}, $table, $row);
        }

        $self->process_table_end($self->{'reports'}->{$code}, $table);
    }

    my $report_filename = $self->process_report_end($self->{'reports'}->{$code});

    delete $self->{'reports'}->{$code};

    return $report_filename;
} # }}}

=item add_table

Add table to the report.

Parameters: (ARRAY)
  $self
  $report_code  - codename of the report, to which new table will be appended.
  $table_code   - table's codename, must be unique withing single report.
  $table_params - parameters for the C<Devel::CoverReport::Table> object.

Returns:
  $table_object - C<Devel::CoverReport::Table> object.
=cut
sub add_table { # {{{
    my ( $self, $report_code, $table_code, $table_params ) = @_;

    my $table = Devel::CoverReport::Table->new(%{ $table_params });

    # fixme: check if table created!

    $self->{'reports'}->{$report_code}->{'tables'}->{$table_code} = $table;

    push @{ $self->{'reports'}->{$report_code}->{'tables_order'} }, $table_code;

    return $table;
} # }}}

=item finalize

Clean-up formatter (flush what was not flushed yet, etc).

=cut
sub finalize { # {{{
    my ( $self ) = @_;

    $self->process_formatter_end();
    
    return;
} # }}}

=item process_formatter_start

This method should be overwritten - according to taste - in child classes.

=cut

sub process_formatter_start { }

=item process_report_start

This method should be overwritten - according to taste - in child classes.

=cut

sub process_report_start { }

=item process_table_start

This method should be overwritten - according to taste - in child classes.

=cut

sub process_table_start { }

=item process_row

This method should be overwritten - according to taste - in child classes.

=cut

sub process_row { }

=item process_summary

This method should be overwritten - according to taste - in child classes.

=cut

sub process_summary { }

=item process_table_end

This method should be overwritten - according to taste - in child classes.

=cut

sub process_table_end { }

=item process_report_end

This method should be overwritten - according to taste - in child classes.

=cut

sub process_report_end { }

=item process_formatter_end

This method should be overwritten - according to taste - in child classes.

=cut

sub process_formatter_end { }

1;

=back

=head1 LICENCE

Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)

This is free software. It is licensed, and can be distributed under the same terms as Perl itself.

For more, see my website: http://bs502.pl/

=cut

# vim: fdm=marker
