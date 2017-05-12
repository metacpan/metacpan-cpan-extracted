package FASTAid;

use version; $VERSION = qv('0.0.4');

=head1 NAME

FASTAid - index a FASTA sequence database for fast random-access sequence retrieval

=head1 VERSION

This document describes FASTAid version 0.0.3


=head1 SYNOPSIS

    use FASTAid qw( create_index retrieve_entry );

    my $FASTA_file = 'lots_of_seqs.fa';

    # index the file of FASTA seqs
    create_index($FASTA_file);

    # retrieve one or more FASTA seqs from the file
    my $seq_array_ref = retrieve_entry($FASTA_file, 'NM_00204', 'AA23456');

    foreach my $seq ( @{$seq_array_ref} ) {

        ...do something with each FASTA sequence...
    }


=head1 DESCRIPTION

FASTAid indexes files containing FASTA sequence records and allows quick
random-access retrieval of one or more FASTA sequences.

FASTAid writes the index to a file with the suffix '.fec'.


=head1 DIAGNOSTICS

=over

=item C<< could not open FASTA file >>

A file could not be opened. Probably the path you supplied is incorrect or the permissions
are incorrect.

=item C<< There is already an entry ID >>

The same identifier appears more than once in the FASTA file you supplied. This is a fatal
error because FASTAid uses the identifier to index the position of the sequence.

=item C<< Cannot write FASTAid index >>

The index could not be written. This is a file system error, so probably you don't have
permissions to write in the directory.

=item C<< Must supply at least one ID >>

No identifiers were supplied as arguments to retrieve_entry. Since FASTAid uses the 
identifier as the lookup, it can't retrieve an entry without an identifier.

=item C<< Entry ID = <id> not found! >>

An identifier could not be found in the index. This is a warning, not a fatal error,
because if other identifiers are supplied to retrieve_entry, those sequences will be
returned even if others fail.

There are two common causes for this error: either the index is out of date and the
identifier doesn't exist in the index, or the identifier was misspelled when attempting
the lookup.

=back

=head1 DEPENDENCIES

L<version>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-FASTAid@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

 Jarret Glasscock C<< <glasscock_cpan@mac.com> >>
 Dave Messina C<< <dave-pause@davemessina.net> >>


=head1 ACKNOWLEDGMENTS

 This software was developed at the Genome Sequencing Center at Washington
 University, St. Louis, MO.


=head1 COPYRIGHT

 Copyright (C) 2004-6 Glasscock, Messina. All Rights Reserved.


=head1 DISCLAIMER

 This software is provided "as is" without warranty of any kind.


=cut


# PRAGMAS
use strict;
use warnings;

# INCLUDES
use Carp;


=head2 create_index

Usage	 : create_index(my_fasta_file) or die "index was not created";
Function : creates a byte index file representing positions of FASTA formatted entries.
Returns  : returns true upon success of index creation, false upon failure
Args     : a single argument, the path to a FASTA file

=cut

sub create_index {
    my ($fasta) = @_;
    my $index = $fasta . '.fec';

    my ( %data, $begin, $id );
    open( DB, $fasta )
        or croak( qq{could not open FASTA file $fasta:\n}, qq{$!\n} );

    # record offsets of records in perl database
    while (<DB>) {
        if ( /^>(\S+)/) {
            $id    = $1;
            $begin = tell(DB) - length($_);
			if ( defined $data{$id} ) {
	            croak "There is already an entry ID = $id\n";
	        }
			else { $data{$id} = "$begin" }
	    }
    }
    close DB;

	# test for empty index
	return 0 if (scalar (keys %data) == 0);

    # Write out index
    open( OUT, ">$index" )
        or croak( qq{Cannot write FASTAid index $index:\n}, qq{$!\n} );
    foreach my $key ( sort { $a cmp $b } keys %data ) {
        print OUT $key, " ", $data{$key}, "\n";
    }
    close OUT;

    return 1;
}

=head2 retrieve_entry

Usage	 : my $array_ref = retrieve_entry(FASTA_file_path, identifier1, identifier2, ..);
Function : retrieves FASTA sequence given index and identifier(s).
Returns  : returns a reference to an array of FASTA entries
Args     : FASTA_file_path, identifier1, identifier2, ..

=cut

sub retrieve_entry {
    my ( $fasta, @ids ) = @_;

	# make sure we have IDs to retrieve
	croak "Must supply at least one ID" if scalar @ids == 0;

    my @seqs;    # where we store the FASTAs we're returning

    # Get the INDEX into an array so we can easily work with it
    my ( @IND1, @IND2 );
    my $index = $fasta . '.fec';

    open( INDEX, $index )
        or croak( qq{cannot open FASTAid index $index:\n}, qq{$!\n} );
    while (<INDEX>) {
        if ( $_ =~ /^(\S+)\s+(\S+)$/ ) {
            push @IND1, $1;
            push @IND2, $2;
        }
    }
    close INDEX;

    # Get the FASTA file into an index before each $id is looked for
    open( DB, "$fasta" )
        or croak( qq{cannot open FASTA file $fasta:\n}, qq{$!\n} );

    foreach my $id (@ids) {
        my ( $low, $high ) = ( 0, @IND1 - 1 );
        my $seq;    # the FASTA we're returning

        my $try;
        TRY:
        while ( $low <= $high ) {
            $try = int( ( $low + $high ) / 2 );    # middle
            $low = $try + 1, next TRY if $IND1[$try] lt $id;
            $high = $try - 1, next TRY if $IND1[$try] gt $id;
            last;                                  # found it!!!
        }

        # translate this back to the corresponding value
        # in the byte index portion of lookup
        my $trans_try = $IND2[$try];

        # go to the offset in the FASTA file
        if ( $trans_try >= 0 && $IND1[$try] eq $id ) {
            seek DB, $trans_try, 0;    # position the file pointer there
            my $def = <DB>;            # defline is first line
            $seq = $def;               # put the defline into our
                                       # return string

            ENTRY:
            while (<DB>) {             # save the other lines
                last ENTRY if $_ =~ /^>/;
                $seq .= $_;
            }

            # add the seq to the array we're returning
            push @seqs, $seq;
        }
        else {
            carp "Entry ID = $id not found!\n";
        }
    }

    # send back an array of FASTA sequences
    return \@seqs;
}

1;
