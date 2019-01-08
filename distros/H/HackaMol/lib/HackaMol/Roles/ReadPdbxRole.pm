package HackaMol::Roles::ReadPdbxRole;
$HackaMol::Roles::ReadPdbxRole::VERSION = '0.051';
# ABSTRACT: parse PDBx/mmCIF files
use Moose::Role;
use HackaMol::PeriodicTable qw(_element_name _trim _qstring_num);
use Math::Vector::Real;
use Carp;

requires 'readline_func';

sub read_cif_info {
    # EXPERIMENTAL: use with caution, getting to work, then need to refactor to min DRY
    my $self    = shift;
    my $fh      = shift;
    my $info    = shift;
    my $in_loop = 0;
    my $atom_site_position = 0;

    while (<$fh>) {

        # set loop flag if loop is open
        if (/^loop_/) {
            $in_loop = 1;
        }
        if ( /^#/ && $in_loop ) {
            $in_loop = 0;
        }

        if (/^_pdbx_database_status.recvd_initial_deposition_date\s+(\S+)/) {
            $info->{deposition_date} = $1;
        }
        if (/^_pdbx_audit_revision_history.revision_date\s*(\S+)?/) {
            my $revision_date = $1;
            if ($in_loop) {
                while ( my $line = <$fh> ) {

                    if ( $line =~ /^\#/ ) {
                        $in_loop = 0;
                        last;
                    }

                    chomp($line);

                    ($revision_date) = $line =~ /.+(\d{4}\-\d{2}\-\d{2})/;
                }
            }
            $info->{last_revision_date} = $revision_date;
        }
        if (/^_pdbx_struct_assembly_gen.asym_id_list\s*(\S+)?/){
			my @asym_list;
            if ($1){
                @asym_list = split /\s*,\s*/, $1;
            }
            else {
            	while (my $line = <$fh>){
					chomp($line);
                    last if $line =~ /^(;\s*$|#)/;
					if( $line =~ /^;/ ){
						@asym_list = split /\s*,\s*/, $line;
					}
					@asym_list = split /\s*,\s*/, $line;
				}

            }
            $info->{auth_asym_id_list}{$_} = 0 foreach @asym_list; # use hash to connect with entities?
        } 
    # this works for 3j7p and others but not using for now because not needed by me   
    #   if (/^_struct_conn.id\s*$/) {
    #       die "assumed loop exception" unless $in_loop;
    #       my @labels = ("_struct_conn.id");

    #       while ( my $line = <$fh> ) {
    #           if ( $line =~ /^(_struct\S+)/ ) {
    #               push @labels, $1;
    #               next;
    #           }
    #           if ( $line =~ /^#/ ) {
    #               $in_loop = 0;
    #               last;
    #           }

    #           chomp($line);

    #           # watch out for things like 'C-U MISPAIR' in 3j7p
	#   		$line = _quote_hack($line);
    #           my @tokens = split /\s+/, $line;

    #           # suck up lines until @tokens == @lables
    #           while ( scalar(@tokens) < scalar(@labels) ) {
    #               my $next_line = <$fh>;
    #               chomp($next_line);
	#   			$next_line = _quote_hack($next_line);
    #               push @tokens, split /\s+/, $next_line;
    #           }
    #           die "too many tokens! [@labels] [@tokens] " if scalar(@tokens) != scalar(@labels);
	#   	    next unless ($tokens[0] =~ /disulf/);	
    #           my $connect;
    #           foreach my $i ( 1 .. $#labels ) {
    #               next if ( $tokens[$i] eq '.' || $tokens[$i] eq '?' );
    #               $connect->{ $labels[$i] } = _unhack_quote($tokens[$i]);
    #           }
    #           $info->{connect}{ $tokens[0] } = $connect;

    #       }
    #   }
        if (/^_entity_poly.entity_id\s*(\d+)?/) {
            chomp;
            # suck up the entity sequences, do it until # if in a loop
            my $entity_id = $1;

            if ($entity_id) {
                die "should not be in loop..." if $in_loop;
                my $seq;
                my $seq_can;
                while ( my $line = <$fh> ) {
                    chomp($line);
                    if ( $line =~ /^_entity_poly\.pdbx_seq_one_letter_code\s+(\S+)?\s*$/ )
                    {
                        if ($1){
                            $seq = $1;
                        }
                        else {
                            while (my $next_line = <$fh>){
                                chomp $next_line;
                                last if $next_line =~ /^;\s*$/;
                                $seq .= $next_line;
                            }
                        }
                    }

                    if ( $line =~ /^_entity_poly\.pdbx_seq_one_letter_code_can\s+(\S+)?\s*$/ )
                    {   
                        if ($1){ 
                            $seq_can = $1;
                        }
                        else {
                            while (my $next_line = <$fh>){
                                chomp $next_line;
                                last if $next_line =~ /^;\s*$/;
                                $seq_can .= $next_line;
                            }
                        }
                    }
                    
                    last if $line =~ /^#/;
                    
                }
                $seq =~ s/[;'"]//g;
                $seq_can =~ s/[;'"]//g;
                $info->{entity}{$entity_id}{'_entity_poly.pdbx_seq_one_letter_code'} = $seq;
                $info->{entity}{$entity_id}{'_entity_poly.pdbx_seq_one_letter_code_can'} = $seq_can;
            }
            else {
                die "expected loop exception" unless ($in_loop);
                # we are in a loop
                my @labels = ($_); 
                #my @labels = ("_entity_poly.entity_id");
				# TODO FACTOR OUT DRY
            	while ( my $line = <$fh> ) {
                	if ( $line =~ /^(_entity_poly.\S+)/ ) {
                    	push @labels, $1;
                    	next;
                	}
                	if ( $line =~ /^\#/ ) {
                    	$in_loop = 0;
                    	last;
               	 	}
                	chomp($line);
                    $line =  _quote_hack($line);
                	my @tokens = split /\s+/, $line;
                	# suck up lines until @tokens == @lables
                	while ( scalar(@tokens) < scalar(@labels) ) {
                        my $next_line = <$fh>;
                        $next_line = _quote_hack ($next_line);
						chomp $next_line;
                        my $seq;
                        if( $next_line =~ /^;/ ){
                            $seq .= $next_line; 
                            while (my $seq_line = <$fh>){
								chomp($seq_line);
                                #$seq_line = _quote_hack($seq_line);
                                last if $seq_line =~ /;\s*$/;
                                $seq .= $seq_line;
                            }
                            $tokens[$#tokens+1] = $seq;
                        }
                        else {

                    	        push @tokens, split /\s+/, $next_line;
                        }
                	}
                    
                	die "too many tokens! [@labels] [@tokens]" if scalar(@tokens) != scalar(@labels);

                	my $entity;
                	foreach my $i ( 1 .. $#labels ) {
                    	next if ( $tokens[$i] eq '.' || $tokens[$i] eq '?' );
                    	($entity->{ $labels[$i] } = _unhack_quote($tokens[$i])) =~ s/[;'"]//g;
                	}
                	$info->{entity}{ $tokens[0] } = $entity;
				}

        #       $pdbx_seq_one_letter_code = 0;
        #       while ( my $line = <$fh> ) {
        #           chomp($line);
        #           if ( $line =~ /^(\d+)\s/ ) {
        #               $pdbx_seq_one_letter_code = 1;
        #               $entity_id                = $1;
        #               next;
        #           }
        #           if ($pdbx_seq_one_letter_code) {
        #               if ( $line =~ /^;$/ )
        #               {    # taking the first sequence that ends with ^;\n
        #                   $pdbx_seq_one_letter_code = 0;
        #                   next;
        #               }
        #               $seq = $line;
        #               $seq =~ s/(\s|;)//g;
        #               $info->{entity}{$entity_id} .= $seq;
        #           }
        #           if ( $line =~ /^\#/ ) {
        #               $in_loop = 0;
        #               last;
        #           }
        #       }
            }
        }
        if (/^_struct_keywords.text\s*(?:\'?(.+)\'?)?\s*$/) {
            if ($1){
                $info->{keywords} = $1;
            }
            else {
                while (my $line = <$fh>){
                    chomp($line);
                    last if $line =~ /^#/;
                    $info->{keywords} .= $line
                }
            }
            $info->{keywords} =~ s/^;|;$|['"]|\s+$//g;
        }
        if (/^_exptl\.(\S+)\s*(?:\'(.+)\')?/){ # 2ah8 changes order
            if ($1 eq 'method'){
                $info->{exp_method} = $2;
            }
            elsif ($in_loop){
                my @labels = ($_);
                my $exptl = {};
                while (my $line = <$fh>){
           	     	if ( $line =~ /^(_exptl\S+)/ ) {
                    	push @labels, $1;
                    	next;
                	}

					if ( $line =~ /^\#/ ) {
                        $in_loop = 0;
                        last;
                    }
                    chomp($line);
                    $line =  _quote_hack($line);
                    my @tokens = split /\s+/, $line;
                    die "too many tokens! [@labels] [@tokens]" if scalar(@tokens) != scalar(@labels);

                    foreach my $i (0 .. $#labels){
                        push @{$exptl->{$labels[$i]}},$tokens[$i]
                    }
                }
               
                $info->{exp_method} = join ';', map {
                                                     my $str = _unhack_quote($_); 
                                                     $str =~ s/['"]//g; $str  } @{$exptl->{'_exptl.method'}};
            }
            else {
                while (my $line = <$fh>){
                    last if $line =~ /^#/;
                    if ($line =~ /^_exptl\.method\s+(?:\'(.+)\')?/) {
                        die "unable to parse exp_method" unless($1);
                        $info->{exp_method} = $1;
                        last;
                    }
                    
                }
            }
        }
        if (/^_refine_hist\.d_res_high\s+(\d+\.\d+)/) {
            $info->{resolution} = sprintf("%s",$1);
        }
        if (/^_em_3d_reconstruction.resolution\s+(\d+\.\d+)/) {
            $info->{resolution} = $1;
        }
        if (/^_citation.pdbx_database_id_DOI\s+(\S+)/) {
            $info->{doi} = $1;
        }
        if (/^_atom_site.group_PDB/){
            $atom_site_position = $. - 2 ;
            $info->{fh_position_atom_site} = $atom_site_position ;
        }
    }
   
    # move $fh to atom_site_position
    seek ($fh, 0, 0 );
    $. = 0;
    my $LINE;
    do { $LINE = <$fh> } until $. == $atom_site_position || eof;

    return $info;
}

sub _quote_hack {
    # watch out for things like 'C-U MISPAIR' in 3j7p
    my $line = shift;
    my @q_strs = $line =~ /['"](?:[^"'\\]++|\\.)*+["']/g; # via man perlre 
    foreach my $q_str (@q_strs){
        (my $hack_str = $q_str) =~ s/(\s+)/__HACK__/g;
        $line =~ s/$q_str/$hack_str/; 
    }
    return $line;
}

sub _unhack_quote {
    # watch out for things like 'C-U MISPAIR' in 3j7p
    my $line = shift;
    $line =~ s/__HACK__/ /g ;
    return $line;
}

sub read_cif_atoms {

    # merge atoms here???
    my $self = shift;
    my ( $atoms, $models, $count_check ) = $self->_read_cif_atoms(@_);
    my @sets;
    foreach my $model_num ( @{$models} ) {
        push @sets, [ grep { $_->model_num == $model_num } @$atoms ];
    }
    wantarray ? return @sets : return $sets[0];
}

my %line_parser_dp = (
    'def' => sub {
        my (
            $record_name, $serial,       $element,      $name,
            $altloc,      $res_name,     $chain_id,     $entity_id,
            $res_id,      $icod,         $x,            $y,
            $z,           $occ,          $B,            $charge,
            $auth_seq_id, $auth_comp_id, $auth_asym_id, $auth_atom_id,
            $model_num
        ) = split;

        $element = ucfirst( lc($element) );
        my $xyz = V( $x, $y, $z );

        my $atom = HackaMol::Atom->new(
            name         => $name,
            record_name  => $record_name,
            serial       => $serial,
            chain        => $chain_id,
            symbol       => $element,
            coords       => [$xyz],
            occ          => $occ * 1,
            bfact        => $B * 1,
            resname      => $res_name,
            resid        => $res_id,
            auth_seq_id  => $auth_seq_id,
            auth_comp_id => $auth_comp_id,
            auth_asym_id => $auth_asym_id,
            auth_atom_id => $auth_atom_id,
            entity_id    => $entity_id,
            model_num    => $model_num,
        );
        $atom->altloc($altloc) if ( $altloc ne '.' );
        $atom->icode($icod)    if ( $icod ne '?' );
        return ($atom, $model_num);
    },
    'esd' => sub {
        my (
            $record_name, $serial,       $element,      $name,
            $altloc,      $res_name,     $chain_id,     $entity_id,
            $res_id,      $icod,         $x,            $y,
            $z,           $occ,          $B, 
            undef, undef, undef, undef, undef, # ignor esd for now
            $charge,
            $auth_seq_id, $auth_comp_id, $auth_asym_id, $auth_atom_id,
            $model_num
        ) = split;

        $element = ucfirst( lc($element) );
        my $xyz = V( $x, $y, $z );

        my $atom = HackaMol::Atom->new(
            name         => $name,
            record_name  => $record_name,
            serial       => $serial,
            chain        => $chain_id,
            symbol       => $element,
            coords       => [$xyz],
            occ          => $occ * 1,
            bfact        => $B * 1,
            resname      => $res_name,
            resid        => $res_id,
            auth_seq_id  => $auth_seq_id,
            auth_comp_id => $auth_comp_id,
            auth_asym_id => $auth_asym_id,
            auth_atom_id => $auth_atom_id,
            entity_id    => $entity_id,
            model_num    => $model_num,
        );
        $atom->altloc($altloc) if ( $altloc ne '.' );
        $atom->icode($icod)    if ( $icod ne '?' );
        return ($atom, $model_num);
    },

);

sub _read_cif_atoms {

    # read pdb file and generate list of Atom objects
    # no model branching
    my $self = shift;
    my $fh   = shift;
    my @atoms;
    my %track_models;

    my @expected_labels = (
        "_atom_site.group_PDB",#            (record_name)   _atom_site.group_PDB           
        "_atom_site.id",#                   (serial)        _atom_site.id                 
        "_atom_site.type_symbol",#          (element)       _atom_site.type_symbol        
        "_atom_site.label_atom_id",#        (name)          _atom_site.label_atom_id      
        "_atom_site.label_alt_id",#         (altloc)        _atom_site.label_alt_id       
        "_atom_site.label_comp_id",#        (res_name)      _atom_site.label_comp_id      
        "_atom_site.label_asym_id",#        (chain_id)      _atom_site.label_asym_id      
        "_atom_site.label_entity_id",#      (entity_id)     _atom_site.label_entity_id    
        "_atom_site.label_seq_id",#         (res_id)        _atom_site.label_seq_id      
        "_atom_site.pdbx_PDB_ins_code",#    (icod)          _atom_site.pdbx_PDB_ins_code  
        "_atom_site.Cartn_x",#              (x)             _atom_site.Cartn_x            
        "_atom_site.Cartn_y",#              (y)             _atom_site.Cartn_y            
        "_atom_site.Cartn_z",#              (z)             _atom_site.Cartn_z            
        "_atom_site.occupancy",#            (occ)           _atom_site.occupancy          
        "_atom_site.B_iso_or_equiv",#       (B)             _atom_site.B_iso_or_equiv     
        "_atom_site.pdbx_formal_charge",#   (charge)       #_atom_site.Cartn_x_esd            #       
        "_atom_site.auth_seq_id",#          (auth_seq_id)  #_atom_site.Cartn_y_esd            #
        "_atom_site.auth_comp_id",#         (auth_comp_id) #_atom_site.Cartn_z_esd            #
        "_atom_site.auth_asym_id",#         (auth_asym_id) #_atom_site.occupancy_esd          #
        "_atom_site.auth_atom_id",#         (auth_atom_id) #_atom_site.B_iso_or_equiv_esd     #
        "_atom_site.pdbx_PDB_model_num",#   (model_num)    #_atom_site.pdbx_formal_charge 
                                                           #_atom_site.auth_seq_id        
    );                                                     #_atom_site.auth_comp_id       
                                                           #_atom_site.auth_asym_id       
                                                           #_atom_site.auth_atom_id       
                                                           #_atom_site.pdbx_PDB_model_num 
                                 
    # look for the labels to determine order of attrs
    my $site_type = 'def'; # 'esd' 
    LABEL: while (<$fh>){
        if (/^_atom_site.Cartn_x_esd/){
            $site_type = 'esd';
            last;
        }
        last if (/^_atom_site.pdbx_PDB_model_num/);

        if (/^_atom_site.group_PDB/){
            my $i = 1;
            while (my $line = <$fh>){
                die "labels out of order $. $line $expected_labels[$i]" unless $line =~ /$expected_labels[$i]\s?/;
                last if ($line =~ /^_atom_site.B_iso_or_equiv/);
                $i++;
            }
        }
    }

    while (<$fh>) {
        if ( $self->has_readline_func ) {
            next if $self->readline_func->($_) eq 'PDB_SKIP';
        }

        last if (/^#/); # this works in combination with order search above

        if (/^(?:HETATM|ATOM)\s/) {
            my ($atom, $model_num) = $line_parser_dp{$site_type}->($_); 
            $track_models{$model_num}++;
            push @atoms, $atom;
        }
    }

    my %model_atom_count = reverse %track_models;

    if ( keys(%model_atom_count) > 1 ) {
        warn "atom number inconsistencies in models. use third return value\n";
    }

    return ( \@atoms, [ sort { $a <=> $b } keys %track_models ],
        \%model_atom_count );
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

HackaMol::Roles::ReadPdbxRole - parse PDBx/mmCIF files

=head1 VERSION

version 0.051

=head1 SYNOPSIS

   my @atoms = HackaMol->new
                       ->read_cif_atoms("some.cif");

=head1 DESCRIPTION

The HackaMol::Roles::ReadPdbxRole provides methods (such as read_cif_atoms for building HM atoms) for pulling information from PDBx/mmcif.
More info available in cif and more attributes are populated than via ReadPdbRole.

=head1 METHODS

=head2 read_pdb_atoms

One argument: the filehandle
Returns a list of HackaMol::Atom objects.

The implementation differs from the PDB parser in how models are handled.  Each atom tracks the model number through the model_num attribute;
the read_pdb_atoms adds configurations to each subsequent atom into t (with identical metadata) as model number increases. Still considering the
best way to handle this.

=head1 SEE ALSO

=over 4

=item *

L<HackaMol>

=item *

L<HackaMol::Atom>

=item *

L<HackaMol::Roles::MolReadRole>

=item *

L<Protein Data Bank|http://pdb.org>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
