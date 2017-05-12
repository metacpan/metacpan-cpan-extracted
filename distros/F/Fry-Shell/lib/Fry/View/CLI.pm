package Fry::View::CLI;
use base 'Fry::Base';
use strict;

#our ($o); 
sub setup {}
sub view ($@) { 
	my ($cls,@data) = @_;
	no strict 'refs'; 
	#print $o->Var('fh'),":\n";
	print { $cls->Var('fh') } "@data" ;
}
sub list ($@) {
	my ($cls,@lines) = @_;
	my ($i,$output);

	for (@lines) {
		$i++;
		$output .=  "$i: " ; #if ($class->_flag->{menu});
		$output .=  "$_\n";	
	}
	$cls->view($output);
}
sub hash ($\%\%) {
	my ($cls,$data,$opt) = @_;
	my $output;
	#uninit s///
	no warnings;

	#while (my ($k,$v) = each %$data) {
	for my $k (($opt->{sort}) ? sort keys %$data : keys %$data) {
		$output .= "$k: ";
		#$v =~ s/^|$/'/g if ($opt->{quote});
		$data->{$k} =~ s/^/'/g if ($opt->{quote});
		$data->{$k} =~ s/$/'/g if ($opt->{quote});
		$output .= $data->{$k}."\n";
	}
	$cls->view($output);
}
sub arrayOfArrays($@) {
	my ($cls,@data) = @_;
	my $output;
	for my $row (@data) {
		$output .= join($cls->Var('field_delimiter'),@$row) . "\n";
	}
	$cls->view($output);
}
sub file ($$$) {
	my ($cls,$file,$data,$options) = @_;
	open (FILE,'>',$file) or do {warn("Couldn't open filehandle for file $file");return };
	my $oldfh = $cls->Var('fh');
	$cls->setVar(fh=>'FILE');
	$cls->view($data);
	close FILE;
	$cls->setVar(fh=>$oldfh);
}
sub objAoH_dt ($@) {
	my ($cls,$data,$col) = @_;
	my $output;
	my $i;

	for my $row  (@$data) {
		if ($cls->Flag('menu')) { $i++; $output .= "$i: "; }
		$output .= join ($cls->Var('field_delimiter'),map {$row->$_} @$col) ."\n" ;
	}
	return $output;
}
sub objAoH ($@) { $_[0]->view(shift->objAoH_dt(@_)); }
	#my ($cls,$data,$col) = @_;
1;

__END__	

=head1 NAME

Fry::View::CLI - Default View plugin for Fry::Shell displaying to the commandline.

=head1 CLASS METHODS



=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
