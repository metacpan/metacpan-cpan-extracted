package HackaMol::Roles::ReadPdbxRole;
$HackaMol::Roles::ReadPdbxRole::VERSION = '0.049';
# ABSTRACT: parse PDBx/mmCIF files
use Moose::Role;
use HackaMol::PeriodicTable qw(_element_name _trim _qstring_num);
use Math::Vector::Real;
use Carp;

requires 'readline_func';

sub read_cif_info {
    my $self    = shift;
    my $fh      = shift;
    my $info    = shift;
    my $in_loop = 0;

    while (<$fh>) {

        # set loop flag if loop is open
        if (/loop_/) {
            $in_loop = 1;
        }
        if ( /\#/ && $in_loop ) {
            $in_loop = 0;
        }

        if (/_pdbx_database_status.recvd_initial_deposition_date\s+(\S+)/) {
            $info->{deposition_date} = $1;
        }
        if (/_pdbx_audit_revision_history.revision_date\s*(\S+)?/) {
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
        if (/^_struct_conn.id\s*$/) {
            die "assumed loop exception" unless $in_loop;
            my @labels = ("_struct_conn.id");

            while ( my $line = <$fh> ) {
                if ( $line =~ /(_struct\S+)/ ) {
                    push @labels, $1;
                    next;
                }
                if ( $line =~ /^\#/ ) {
                    $in_loop = 0;
                    last;
                }

                chomp($line);
                my @tokens = split /\s+/, $line;

                # suck up lines until @tokens == @lables
                while ( scalar(@tokens) < scalar(@labels) ) {
                    my $next_line = <$fh>;
                    chomp($next_line);
                    push @tokens, split /\s+/, $next_line;
                }
                die "too many tokens!" if scalar(@tokens) != scalar(@labels);

                my $connect;
                foreach my $i ( 1 .. $#labels ) {
                    next if ( $tokens[$i] eq '.' || $tokens[$i] eq '?' );
                    $connect->{ $labels[$i] } = $tokens[$i];
                }
                $info->{connect}{ $tokens[0] } = $connect;

            }
        }
        if (/_entity_poly.entity_id\s*(\d+)?/) {

            # suck up the entity sequences, do it until # if in a loop
            my $entity_id = $1;

            #my $line = <$fh>;

            my $pdbx_seq_one_letter_code;
            my $seq;

            if ($entity_id) {
                die "should not be in loop..." if $in_loop;
                while ( my $line = <$fh> ) {
                    chomp($line);
                    if ( $line =~ /_entity_poly.pdbx_seq_one_letter_code\s*$/ )
                    {
                        $pdbx_seq_one_letter_code = 1;
                        next;
                    }

                    if ( $line =~ /_entity_poly.pdbx_seq_one_letter_code_can/ )
                    {
                        $pdbx_seq_one_letter_code = 0;
                        last;
                    }

                    if ($pdbx_seq_one_letter_code) {
                        $seq .= $line;
                    }
                }
                $seq =~ s/(\;|\s+)//g;
                $info->{entity}{$entity_id} = $seq;
            }
            else {
                # we are in a loop
                $pdbx_seq_one_letter_code = 0;
                while ( my $line = <$fh> ) {
                    chomp($line);
                    if ( $line =~ /^(\d+)\s/ ) {
                        $pdbx_seq_one_letter_code = 1;
                        $entity_id                = $1;
                        next;
                    }
                    if ($pdbx_seq_one_letter_code) {
                        if ( $line =~ /^;$/ )
                        {    # taking the first sequence that ends with ^;\n
                            $pdbx_seq_one_letter_code = 0;
                            next;
                        }
                        $seq = $line;
                        $seq =~ s/(\s|;)//g;
                        $info->{entity}{$entity_id} .= $seq;
                    }
                    if ( $line =~ /^\#/ ) {
                        $in_loop = 0;
                        last;
                    }
                }
            }
        }
        if (/_struct_keywords.text\s+\'(.+)\'/) {
            $info->{keywords} = $1;
        }
        if (/_exptl\.method\s+\'(.+)\'/) {
            $info->{exp_method} = $1;
        }
        if (/_refine_hist\.d_res_high\s+(\d+\.\d+)/) {
            $info->{resolution} = $1;
        }
        if (/_em_3d_reconstruction.resolution\s+(\d+\.\d+)/) {
            $info->{resolution} = $1;
        }
        if (/_citation.pdbx_database_id_DOI\s+(\S+)/) {
            $info->{doi} = $1;
        }
        last if (/_atom_site.group_PDB/);
    }

    #use Data::Dumper;
    #print Dumper $info;
    return $info;
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

sub _read_cif_atoms {

    # read pdb file and generate list of Atom objects
    # no model branching
    my $self = shift;
    my $fh   = shift;
    my @atoms;
    my %track_models;
    my $atom_line_flag = 0;    #this is needed to parse after atom coord loop

    while (<$fh>) {
        if ( $self->has_readline_func ) {
            next if $self->readline_func->($_) eq 'PDB_SKIP';
        }

# assuming order of columns, e.g.
#loop_
#_atom_site.group_PDB            (record_name)
#_atom_site.id                   (serial)
#_atom_site.type_symbol          (element)
#_atom_site.label_atom_id        (name)
#_atom_site.label_alt_id         (altloc)
#_atom_site.label_comp_id        (res_name)
#_atom_site.label_asym_id        (chain_id)
#_atom_site.label_entity_id      (entity_id)
#_atom_site.label_seq_id         (res_id)
#_atom_site.pdbx_PDB_ins_code    (icod)
#_atom_site.Cartn_x              (x)
#_atom_site.Cartn_y              (y)
#_atom_site.Cartn_z              (z)
#_atom_site.occupancy            (occ)
#_atom_site.B_iso_or_equiv       (B)
#_atom_site.pdbx_formal_charge   (charge)
#_atom_site.auth_seq_id          (auth_seq_id)
#_atom_site.auth_comp_id         (auth_comp_id)
#_atom_site.auth_asym_id         (auth_asym_id)
#_atom_site.auth_atom_id         (auth_atom_id)
#_atom_site.pdbx_PDB_model_num   (model_num)
#ATOM 1       N N   . PRO A   1 1   ? 393.230 1016.300 385.017 1.0 0.00 ? 1   PRO g8 N   1
        if (/^(?:HETATM|ATOM)/) {
            $atom_line_flag = 1;

            my (
                $record_name, $serial,       $element,      $name,
                $altloc,      $res_name,     $chain_id,     $entity_id,
                $res_id,      $icod,         $x,            $y,
                $z,           $occ,          $B,            $charge,
                $auth_seq_id, $auth_comp_id, $auth_asym_id, $auth_atom_id,
                $model_num
            ) = split;

            # ignore charge for now...

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
            $track_models{$model_num}++;
            push @atoms, $atom;
        }
        elsif ($atom_line_flag) {

            # stops reading cif after leaving the atom coordinate loop
            # leaves $. at that point; not done to save time
            last;
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

version 0.049

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
