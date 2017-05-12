package Elive::Entity::Report;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;

extends 'Elive::Entity';

use Elive::Entity::Role;

__PACKAGE__->entity_name('Report');
__PACKAGE__->collection_name('Reports');

has 'reportId' => (is => 'rw', isa => 'Int', required => 1);
__PACKAGE__->primary_key('reportId');

has 'name' => (is => 'rw', isa => 'Str',
	      documentation => 'report name');
__PACKAGE__->_alias(reportName => 'name', freeze => 1);

has 'description' => (is => 'rw', isa => 'Str',
	      documentation => 'report description');
__PACKAGE__->_alias(reportDescription => 'description', freeze => 1);

has 'xml' => (is => 'rw', isa => 'Str',
	      documentation => 'report content');
__PACKAGE__->_alias(reportDefinition => 'xml', freeze => 1);

has 'role' => (is => 'rw', isa => 'Elive::Entity::Role',
               documentation => 'default user role',
               coerce => 1);

has 'parentId' => (is => 'rw', isa => 'Int');

has 'ownerId' => (is => 'rw', isa => 'Str');
__PACKAGE__->_alias(reportOwner => 'ownerId', freeze => 1);

=head1 NAME

Elive::Entity::Report - Elluminate Report entity instance class

=head1 DESCRIPTION

This is the entity class for server side reports. These are visible
on the Elluminate server under the 'Reports' tab.

Please note that the C<list> method (C<listReports> command) does not return the body
of the report. The report object needs to be refetched via the C<retrieve> method.

For example, the following code snippet exports all reports for a site:

    my $reports = Elive::Entity::Report->list;
    my @report_ids = map {$_->reportId} @$reports;

    foreach my $report_id (@report_ids) {

	#
	# listed objects don't have the report body, refetch them.
	#

        my $rpt = Elive::Entity::Report->retrieve( $report_id );

	my $name = $rpt->name;
	$name =~ s/[^\w]//g; # sanitise
	my $export_file = "/tmp/report_${reportId}_${name}.xml";

	open (my $dump_fh, '>', $export_file)
	    or die "unable to open $export_file: $!";
	print $dump_fh $rpt->xml;
	close ($dump_fh);

    }

=cut

=head1 METHODS

=cut

sub BUILDARGS {
    my $class = shift;
    my $spec = shift;
    my %opt = @_;

    die "usage: $class->new(\$hashref)"
	unless Elive::Util::_reftype($spec) eq 'HASH';

    my %args = %$spec;

    $args{ownerId} ||= do {

	my $connection = $opt{connection} || $class->connection
	    or die "not connected";

	$connection->login->userId;
    };

    return \%args;
}

=head2 list

    my $all_reports = Elive::Entity::Report->list();

List reports.

Note: This command does not return the body of the report (C<xml> property).

=cut

=head2 retrieve

    my $report = Elive::Entity::Report->retrieve( $report_id );
    my $report_xml = $report->xml;

Retrieves a report, including the body of the report (C<xml> property).

=cut

=head2 insert

The C<insert> method is not available for reports.

=cut

sub insert {
    my ($class, $_spec, %opt) = @_;

    my $insert_data = $class->BUILDARGS($_spec, %opt);

    $opt{command} ||= 'addReport';

    return $class->SUPER::insert( $class->_freeze($insert_data), %opt);
}

=head2 update

The C<update> method is not available for reports.

=cut

sub update {
    my ($self, $_spec, %opt) = @_;

    my $update_data;
    $update_data = $self->BUILDARGS($_spec, %opt)
	if $_spec;
    #
    # always need to supply these fields to the update command,
    # whether or not they've actually changed.
    #
    my %changed;
    @changed{$self->is_changed, 'name','description','xml', 'ownerId'} = undef;

    return $self->SUPER::update($update_data, %opt, changed => [keys %changed]);
}

=head2 delete

    my $report = Elive::Entity::Report->retrieve( $report_id );
    $report->delete if $report;

Deletes a report.

=cut

sub delete {
    #
    # response seems to be returned as true/false rather than a record.
    # hence the need to roll our own
    #
    my ($self, %opt) = @_;

    my $som = $self->connection->call('deleteReport' 
				      => %{$self->_freeze({reportId => $self->reportId})
				      });

    my $results = $self->_get_results($som, $self->connection);
    #
    # this command responds with true/false, rather than a report record.
    #
    my $deleted = $results && $results->[0];

    return $self->_deleted($deleted);
}

1;
