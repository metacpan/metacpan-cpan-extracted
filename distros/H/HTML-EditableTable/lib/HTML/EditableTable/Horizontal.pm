package HTML::EditableTable::Horizontal;

@ISA = qw(HTML::EditableTable);

use strict;
use warnings;
use Carp qw(confess);

=head1 NAME

HTML::EditableTable::Horizontal

=head1 VERSION

Version 0.21

=cut

our $VERSION = '0.21';

=head2 'Protected' Virtual Methods

=cut

# makeTable is the 'abstract virtual' method that must be implemented by a derivative of HTML::EditableTable

sub makeTable {

    my $self = shift @_;

    my $data = $self->{'data'};
    my $spec = $self->{'tableFields'};
    my $mode = $self->{'editMode'};
    
    my $sortHeader = undef;
    
    if (exists $self->{'sortHeader'}) {
	$sortHeader = $self->{'sortHeader'};
    }

    if (!$data || !$spec || !$mode) {
      confess("Missing requirement for table, throwing exception");
    }
    
    my $tableAttributes = $self->getTableTagAttributes();
    print "\n<table $tableAttributes>\n";
    
    unless (exists $self->{'noheader'}) {
	$self->staticTableHeader($spec, $mode, $sortHeader);
    }
    
    print "\n";
    
    if (ref($data) eq 'ARRAY') {
      
      # autodetermine rowspan drivers and call setRowspanDriver() from the first row of data      
      if(scalar(@$data)) {
	foreach my $dbfield (keys %{$data->[0]}) {
	  if (ref($data->[0]->{$dbfield}) eq 'ARRAY') {
	    push @{$self->{variableRowspanDriver}}, $dbfield;
	  }
	}
      }
      
      foreach my $row (@$data) {
	
	if (exists $self->{variableRowspanDriver}) {
	  
	  my $maxRowspanSubcount = 0;
	  
	  for (my $j = 0; $j < scalar(@{$self->{variableRowspanDriver}}); $j++) {	    
	    if (ref($row->{$self->{variableRowspanDriver}->[$j]}) eq 'ARRAY') {	      
	      my $nextRowspanSubcount = scalar(@{$row->{$self->{variableRowspanDriver}->[$j]}});

	      if ($nextRowspanSubcount > $maxRowspanSubcount) { 
		$maxRowspanSubcount = $nextRowspanSubcount;
	      }
	    }
	  }
	  
	  for (my $i = 0; $i < $maxRowspanSubcount; $i++) {
	    print "<tr>";
	    $self->staticTableRow($row, $spec, $maxRowspanSubcount, $i);
	    print "</tr>\n\n";
	  }
	}
	else {
	  print "<tr>";
	  $self->staticTableRow($row, $spec);
	  print "</tr>\n\n";
	}
      }
    }
    elsif (ref($data) eq 'HASH') {
            
      # autodetermine rowspan drivers and call setRowspanDriver() from the first row of data      
      
      my ($key, $row) = each %$data;
      
      if($row) {
	foreach my $dbfield (keys %$row) {
	  if (ref($row->{$dbfield}) eq 'ARRAY') {
	    push @{$self->{variableRowspanDriver}}, $dbfield;
	  }
	}
      }
      
      if ( my $so = $self->{'sortOrder'}) {
	
	foreach my $rowKey (sort { my $aPos; my $bPos; for ($aPos = 0; $aPos < scalar(@$so); $aPos++) { if ($so->[$aPos] eq $a) { last; } } for ($bPos = 0; $bPos < scalar(@$so); $bPos++) { if ($so->[$bPos] eq $b) { last; } } $aPos <=> $bPos; } keys %$data) {

	  my $row = $data->{$rowKey};
	  	  
	  if (exists $self->{variableRowspanDriver}) {
	    
	    my $maxRowspanSubcount = 0;
	    
	    for (my $j = 0; $j < scalar(@{$self->{variableRowspanDriver}}); $j++) {	    
	      if (ref($row->{$self->{variableRowspanDriver}->[$j]}) eq 'ARRAY') {	      
		my $nextRowspanSubcount = scalar(@{$row->{$self->{variableRowspanDriver}->[$j]}});
		
		if ($nextRowspanSubcount > $maxRowspanSubcount) { 
		  $maxRowspanSubcount = $nextRowspanSubcount;
		}
	      }
	    }
	    
	    for (my $i = 0; $i < $maxRowspanSubcount; $i++) {
	      print "<tr>";
	    $self->staticTableRow($row, $spec, $maxRowspanSubcount, $i);
	      print "</tr>\n\n";
	    }
	  }
	  else {
	    print "<tr>";
	    $self->staticTableRow($row, $spec);
	    print "</tr>\n\n";
	  }	  
	}   	
      }
      else {
	foreach my $rowKey (sort keys %$data) {
	  print "<tr>";
	  $self->staticTableRow($data->{$rowKey}, $spec);
	  print "</tr>\n";
	}
      }	
    }
    
    else {
      confess "data must by a hash or array reference, not a " . ref($data);
    }
        
    print "</table>\n";  
}

sub staticTableHeader {
  
    my $self = shift @_;

    my $spec = $self->{'tableFields'};
    my $mode = $self->{'editMode'};

    my $sortHeader = undef;
    my $orderBy = undef;
    
    if (exists $self->{'sortHeader'}) {

      # each click causes sort to revserse
      
      $orderBy  = 'orderByAsc';
      
      if (CGI::param('orderByAsc')) {	
	$orderBy = 'orderByDesc';
      }      
      
      $sortHeader = $self->{'sortHeader'};
    }

    print "<tr>";

    foreach my $colSpec (@$spec) {
	
	next if (exists $colSpec->{'viewOnly'} && $mode eq 'edit');
	next if (exists $colSpec->{'editOnly'} && $mode eq 'view');
	
	if ($colSpec->{'formElement'} && ($colSpec->{'formElement'} eq 'deleteRowButton')) {
	    print "<th>" . "<input type=button value='add row' onClick=\"addData()\">" . "</th>";
	}
	elsif (!exists($colSpec->{'label'})) {
	    print "<th>" . "<i>label missing</i>" . "</th>";
	}
	else {
	    if ($sortHeader && exists $colSpec->{'dbfield'}) {
		print "<th>" . "<a href=" . $sortHeader . $orderBy . "=" . $colSpec->{'dbfield'} . ">" . $colSpec->{'label'} . "</a>";
	    }
	    else {
		
		if (exists $colSpec->{'tooltip'}) { 
		    print "<th tooltip=\"" . $colSpec->{'tooltip'} . "\" onmouseover=\"Tooltip.schedule(this, event);\">" . $colSpec->{'label'};
		}
		else {
		    print "<th>" . $colSpec->{'label'};
		}
	    }
	    
	    if ($mode eq 'edit' && exists $colSpec->{'jsClearColumnOnEdit'}) {
		print "<br>";

		my $name = $colSpec->{'dbfield'};
		
		if (exists $colSpec->{'rowspanArrayKey'}) {
		    $name = $colSpec->{'rowspanArrayKey'}
		}
		
		print "<input type=button value='clear column' onClick=\"clearColumnOnEdit('$name');\">";
		
	    }
	    
	    print "</th>";
	    
	}
    }
    print "</tr>\n";   
}


=head1 SYNOPSIS

Implementation of EditableTable for the 'horizontal' case, where the first row presents the data header.  There are no public methods in this class.  See L<HTML::EditableTable> for documentation.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Freescale Semiconductor, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of HTML::EditableTable::Horizontal
