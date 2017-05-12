=head1 NAME

Win32::Word::Writer::Table2 - Add tables to Word documents.

=head1 SYNOPSIS

Used by the Win32::Word::Writer module.


=cut
package Win32::Word::Writer::Table2;

use warnings;
use strict;





our $VERSION = '0.01';





use strict;
use Win32::OLE::Const;
use Data::Dumper;


=head1 PROPERTIES

=head2 oWriter

Win32::Word::Writer::Table2 object to write to.


=head2 alreadyCreatedRow

Whether a row have been created already.

Default: 0


=head2 createdColumnCount

The number of columns actually created in the table.

Default: 0


=head2 columnPos

Which column we're adding text to currently

=cut
use Class::MethodMaker new_with_init => "new", get_set => [ qw(
	oWriter
	alreadyCreatedRow
	createdColumnCount
	columnPos
)];





=head2 new(oWriter => Win32::Word::Writer $oWriter)

Create new table writer for $oWriter.


=head2 init()

Init the object after creation.


=cut
sub init {
	my $self = shift;
	my (%hParam) = @_;

	$self->createdColumnCount(0);
	$self->columnPos(0);
	$self->alreadyCreatedRow(0);
	$self->oWriter( $hParam{oWriter} ) or die(__PACKAGE__ . "->new() requires an oWriter parameter\n");

	return;
}





=head2 TableBegin()

Begin a new table.

Add a RowBegin() and a ColumnBegin() before adding
any text to the table.

=cut
sub TableBegin {
    my $self = shift;
    
	my $oTable = $self->oWriter->oDocument->Tables->Add(
			$self->oWriter->oSelection->Range,
			1, 1, 
			$self->oWriter->rhConst->{wdWord9TableBehavior},
			$self->oWriter->rhConst->{wdAutoFitContent},
			);
	$oTable->{PreferredWidthType} = $self->oWriter->rhConst->{wdPreferredWidthAuto};

	$self->alreadyCreatedRow(1);
	$self->createdColumnCount(1);
	$self->columnPos(1);

	return(1);
}





=head2 RowBegin()

Begin a new row in the table. Existing rows and columns are implicitly
closed first.

=cut
sub RowBegin {
    my $self = shift;

    if( ! $self->alreadyCreatedRow) {
		$self->oWriter->oSelection->InsertRowsBelow(1);
	}

	#Must set the AutoFitBehavior continously it seems, at least not just after creating the table 
	##todo: set wdAutoFitContent or wdAutoFitWindow depending on the 'table width="100%"' setting.
	$self->oWriter->oSelection->Tables(1)->AutoFitBehavior($self->oWriter->rhConst->{wdAutoFitContent});

	$self->alreadyCreatedRow(0);
	$self->columnPos(0);
	$self->createdColumnCount(1) if($self->createdColumnCount == 0);
	
	return(1);
}





=head2 ColumnBegin()

Begin a new column in the row. Existing columns are implicitly closed
first.

=cut
sub ColumnBegin {
	my $self = shift;

	if($self->columnPos > 0) {
		if($self->columnPos < $self->createdColumnCount) {
			$self->oWriter->oSelection->MoveRight( { Unit => $self->oWriter->rhConst->{wdCell} } );
		} else {
			$self->oWriter->oSelection->InsertColumnsRight();
			$self->createdColumnCount( $self->createdColumnCount + 1 );
		}
	}
	
	$self->columnPos( $self->columnPos + 1 );

	return(1);
}





=head2 TableEnd()

End the current table.

=cut
sub TableEnd {
    my $self = shift;
			#This may work badly if the edit isn't linear, but have moved to another place in the document
			#but this was the only way I could get it to work. Improvements welcome.
	$self->oWriter->oSelection->EndKey({Unit => $self->oWriter->rhConst->{wdStory}});

	return(1);
}





=head2 DESTROY

Release the oWriter

=cut
sub DESTROY {
    my $self = shift;
	$self->{oWriter} = undef;
}





=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-win32-word-document-writer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Word-Document>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut





1;





__END__
