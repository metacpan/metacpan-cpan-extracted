package HTML::EditableTable::Vertical;

@ISA = qw(HTML::EditableTable);

use strict;
use warnings;
use Carp qw(confess);

=head1 NAME

HTML::EditableTable::Vertical

=head1 VERSION

Version 0.21

=cut

our $VERSION = '0.21';

=head1 SYNOPSIS

Implementation of the EditableTable class for the construction of 'Vertical' Tables, where the first column of the table presents the header. See L<HTML::EditableTable> for documentation.

=cut

# makeTable is the 'abstract virtual' method that must be implemented by a derivative of HTML::EditableTable

sub makeTable {

    my $self = shift @_;

    my $data = $self->{'data'}; # data is a hash of values for a single dataset or an hashes of hashes for the multi-column case
    my $fields = $self->{'tableFields'};
    my $mode = $self->{'editMode'};

    my $title = undef;
    my $tabindex = undef;
    my $headingOrder = undef;

    if (exists $self->{'title'}) {
	$title = $self->{'title'};
    }
    
    if (exists $self->{'tabindex'}) {
	$tabindex = $self->{'tabindex'};
    }

    if (exists $self->{'sortOrder'}) {
	$headingOrder = $self->{'sortOrder'}; # optional array fieldsifing heading order for multi column case
    }

    if (!$data || !$fields || !$mode) {
      confess "Missing requirement for table, throwing exception";
    }
    
    # determine case by probing $data

    my @dataKeys = keys %$data;
    
    my $case;
    my $datasetCount;
    my $datasets = {};
    my @datasetHeaders = ();
	

    if (ref($data->{$dataKeys[0]}) eq 'HASH') {

	$datasets = $data;
	$datasetCount = scalar(keys %$data);
	if ($headingOrder) { @datasetHeaders = @$headingOrder; }
	else { @datasetHeaders = sort keys %$data; }
		
    }
    else {
	# cast the single hash case to the multi column case
	$datasets = {'1' => $data };
	$datasetCount = 1;
	@datasetHeaders = ('1');
    }

    my $tableAttributes = $self->getTableTagAttributes();
    print "\n<table $tableAttributes>\n";

    # optional title
	    
    if ($title) {

	my $colCount = $datasetCount + 1;

	print "<tr><th colspan=$colCount>" . $title . "</th></tr>\n";
    }	

    # headers for multi-column case

    if (scalar(@datasetHeaders) > 1) {
	
	print "<tr>";
	print "<td></td>";
	
	foreach my $datasetName (@datasetHeaders) {
	    print "<th>" . $datasetName . "</th>";
	}
	
	print "</tr>\n";
    }

    foreach my $row (@$fields) {
	
	my @oneSpec = ();
	push @oneSpec, $row;

	# set the first column flag, which will be reset in staticTableRow();

	$self->{'vtableFirstColumn'} = 1;

	print "<tr>";

	foreach my $datasetName (@datasetHeaders) {

	    my $data = $datasets->{$datasetName};

	    unless($self->{'suppressUndefinedFields'} && !defined($data->{$row->{'dbfield'}})) {
		$self->staticTableRow($data, \@oneSpec);
	    }
	}

	print "</tr>\n";
    }   

    print "</table>";    
}

=head1 COPYRIGHT & LICENSE

Copyright 2010 Freescale Semiconductor, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::EditableTable::Vertical
