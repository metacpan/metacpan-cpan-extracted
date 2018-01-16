package MarpaX::Languages::PowerBuilder::SRJ;
use base qw(MarpaX::Languages::PowerBuilder::base);
#a SRJ parser by Nicolas Georges

#helper methods

#retrieve pbd entries
sub pbd                         { @{$_[0]->value->{pbd}} }
#retrieve object entries
sub obj                         { @{$_[0]->value->{obj}} }

#build and executable options
sub executable_name             { $_[0]->value->{exe}[0] }
sub application_pbr             { $_[0]->value->{exe}[1] }
sub prompt_for_overwrite        { $_[0]->value->{exe}[2] }
sub rebuild_type		        { $_[0]->value->{exe}[3] ? 'full' : 'incremental' }
sub rebuild_type_int	        { $_[0]->value->{exe}[3] }
sub windows_classic_style       { $_[0]->value->{exe}[4] ? 0 : 1 }
sub new_visual_style_controls   { $_[0]->value->{exe}[4] }

#code generation options
#TODO: find meaning of {cmp}[3, 5 and 7]
sub build_type			        { $_[0]->value->{cmp}[0] ? 'machinecode' : '' }	#empty is for pcode
sub build_type_int		        { $_[0]->value->{cmp}[0] }
sub with_error_context          { $_[0]->value->{cmp}[1] }
sub with_trace_information      { $_[0]->value->{cmp}[2] }
sub optimisation                { qw(speed space none)[ $_[0]->value->{cmp}[4] ] // '?' }
sub optimisation_int            { $_[0]->value->{cmp}[4] }
sub enable_debug_symbol         { $_[0]->value->{cmp}[6] }

#manifest information
sub manifest_type               { qw(none embedded external)[$_[0]->value->{man}[0]] // '?' }
sub manifest_type_int           { $_[0]->value->{man}[0] }
sub execution_level             { $_[0]->value->{man}[1] }
sub access_protected_sys_ui     { $_[0]->value->{man}[2] ? 'true' : 'false' }
sub access_protected_sys_ui_int { $_[0]->value->{man}[2] }
sub manifestinfo_string         { 
	#this string is usable in orcascript for the manifestinfo argument of the 'set exeinfo property' command
	my $self = shift;
	
	my $manifest = join ';', @{ $self->value->{man} };
	$manifest =~ s/1$/true/ or $manifest =~ s/0$/false/;
	
	return $manifest;
}

#others
sub product_name                { $_[0]->value->{prd}[0] }
sub company_name                { $_[0]->value->{com}[0] }
sub description                 { $_[0]->value->{des}[0] }
sub copyright                   { $_[0]->value->{cpy}[0] }
sub product_version_string      { $_[0]->value->{pvs}[0] }
sub product_version_number      { join('.', @{ $_[0]->value->{pvn} }) }
sub product_version_numbers     { @{ $_[0]->value->{pvn} } }
sub file_version_string         { $_[0]->value->{fvs}[0] }
sub file_version_number         { join('.', @{ $_[0]->value->{fvn} }) }
sub file_version_numbers        { @{ $_[0]->value->{fvn} } }

#Grammar action methods
sub project {
	my ($ppa, $items) = @_;
	
    my %attrs;
	ITEM:
	for(@$items){
		my $item = $_->[0];
		my ($name, @children) = @$item;
		if($name =~ /^(PBD|OBJ)$/i){
			push @{$attrs{$name}}, \@children;
		}
		else{
			$attrs{$name} = \@children;
		}
	}
	
 	return \%attrs;
}

sub compiler{
	my ($ppa, $ary) = @_;
	
	return [ cmp => @$ary ];
}

sub string {
	my ($ppa, $str) = @_;
	return $str;
}

sub integer {
	my ($ppa, $int) = @_;
	return $int;
}

1;
