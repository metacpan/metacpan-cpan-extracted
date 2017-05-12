package FASTAParse;

# | PACKAGE | FASTAParse
# | AUTHOR  | Todd Wylie
# | EMAIL   | perldev@monkeybytes.org

use version; $VERSION = qv('0.0.3');
use warnings;
use strict;
use Carp;
use IO::File;

# --------------------------------------------------------------------------
# N E W  (class CONSTRUCTOR)
# ==========================================================================
# USAGE      : FASTAParse->new();
# PURPOSE    : constructor for class
# RETURNS    : object handle
# PARAMETERS : none
# COMMENTS   : FASTA object.
# --------------------------------------------------------------------------
sub new {
    my $class = shift;

    my $self  = {
        _id          => '',
        _descriptors => [],
        _comments    => [],
        _sequence    => [],
    };

    bless($self, $class);
    return($self);
}


# --------------------------------------------------------------------------
# L O A D  F A S T A  (method)
# ==========================================================================
# USAGE      : FASTAParse->load_FASTA();
# PURPOSE    : loads a chunk of FASTA into the class
# RETURNS    : none
# PARAMETERS : fasta => ''
# THROWS     : croaks if no FASTA attribute or bad FASTA header
# COMMENTS   : The user sould be passing a chunk of text (scalar) to
#            : this method which represents 1 FASTA entry... from the
#            : > symbol to the end of the sequence; includes line
#            : returns.
# EXAMPLE    : Example format:
#            : >gi|55416189|gb|AAV50056.1| NADH dehydrogenase subunit 1 [Dasyurus hallucatus]
#            : ;Taken from nr GenBank
#            : MFTINLLIYIIPILLAVAFLTLIERKMLGYMQFRKGPNIVGPYGLLQPFADAVKLFTKEPLRPLTSSISIFIIAPILALT
#            : IALTIWTPLPMPNTLLDLNLGLIFILSLSGLSVYSILWSGWASNSKYALIGALRAVAQTISYEVSLAIILLSIMLINGSF
#            : TLKTLSITQENLWLIITTWPLAMMWYISTLAETNRAPFDLTEGESELVSGFNVEYAAGPFAMFFLAEYANIIAMNAITTI
#            : LFLGPSLTPNLSHLNTLSFMLKTLLLTMVFLWVRASYPRFRYDQLMHLLWKNFLPMTLAM
# --------------------------------------------------------------------------
sub load_FASTA {
    my ($class, %arg) = @_;

    # Check incoming FASTA format:
    if (!$arg{fasta})       { croak "load_FASTA needs FASTA attribute" }
    if ($arg{fasta} !~ />/) { croak "no FASTA header found for input"  }

    # Parse sequence and load the FASTA object:
    my @lines = split( /\n/, $arg{fasta} );
    foreach my $line (@lines) {
        if ($line =~ /^>\S+/) {
            # Header line:
            my ($id, $descriptions)   = $line =~ /^>(\S+)\s*(.*)/;
            $class->{_id}             = $id;
            if (defined$descriptions) {
                @{$class->{_descriptors}} = split( /\cA/, $descriptions );
            }
        }
        elsif ($line =~ /^;\s*(.+)/) {
            # Comment lines:
            push( @{$class->{_comments}}, $1 );
        }
        else {
            # Sequence lines:
            $line =~ s/\s+//g;
            unless( $line eq "" ) { push( @{$class->{_sequence}}, $line ) }
        }
    }
    return($class);
}


# --------------------------------------------------------------------------
# F O R M A T  F A S T A  (method)
# ==========================================================================
# USAGE      : $fasta->format_FASTA();
# PURPOSE    : Manually populate the FASTA class.
# RETURNS    : none
# PARAMETERS : id          => '' # REQUIRED
#            : sequnce     => '' # REQUIRED
#            : comments    => []
#            : descriptors => []
#            : cols        => ''
# COMMENTS   : A user may manually load a FASTA object. Only ID and SEQUENCE
#            : are required, all others are optional. The SEQUENCE attribute
#            : should be a flat, single line scalar value (i.e., a single
#            : string of sequence).
# --------------------------------------------------------------------------
sub format_FASTA {
    my ($class, %arg) = @_;

    # Format the incoming sequence. Sequence must be single line,
    # flatten sequence string. Check incoming FASTA format first:
    if (!$arg{sequence}) { croak "format_FASTA needs SEQUENCE attribute" }
    if (!$arg{id}      ) { croak "format_FASTA needs ID attribute"       }
    my $columns = defined $arg{cols} ? $arg{cols} : 60;  # Default is 60 cols.

    # If incoming sequence is multi-part, join them before breaking
    # into FASTA lines:
    delete( $class->{_sequence} );
    my $fasta  = join( "", $arg{sequence} );
    my $length = length( $fasta );
    my $pos    = 0;
    my $lines  = int( $length / $columns) + 1;
    for (my $i = 1; $i <= $lines; $i++) {
        my $line = substr( $fasta, $pos, $columns );
        push( @{$class->{_sequence}}, $line );
        $pos = $pos + $columns;
    }

    # Descriptions, comments, etc.
    $class->{_id} = $arg{id};
    if (defined @{$arg{comments}}) {
        @{$class->{_comments}} = @{$arg{comments}};
    }
    if (defined @{$arg{descriptors}}) {
        @{$class->{_descriptors}} = @{$arg{descriptors}};
    }

    return( $class );
}


# --------------------------------------------------------------------------
# D U M P  F A S T A  (method)
# ==========================================================================
# USAGE      : $fasta->dump_FASTA();
# PURPOSE    : Accessor to dump the FASTA class into text.
# RETURNS    : scalar (chunk of FASTA text)
# PARAMETERS : none
# --------------------------------------------------------------------------
sub dump_FASTA {
    my $class = shift;

    # Dump the class in scalar context:
    my $returnable;
    if (defined $class->{_id}) {
        my $descriptors = join( "\cA", @{$class->{_descriptors}} );  # ^A delimiter
        $returnable = ">$class->{_id} $descriptors\n";
        foreach my $comment ( @{$class->{_comments}} ) {
            $returnable .= ";$comment\n";
        }
        foreach my $sequence ( @{$class->{_sequence}} ) {
            $returnable .= "$sequence\n";
        }
    }
    else {
        croak "ID is missing from the object";
    }

    return( $returnable );
}


# --------------------------------------------------------------------------
# S A V E   F A S T A  (method)
# ==========================================================================
# USAGE      : $fasta->save_FASTA( save => '' );
# PURPOSE    : Accessor to save the FASTA entry to a file.
# RETURNS    : none
# PARAMETERS : save => ''
# --------------------------------------------------------------------------
sub save_FASTA {
    my ($class, %arg)  = @_;

    if (!$arg{save}) { croak "save_FASTA needs SAVE attribute" }

    # Save the class information to a file:
    my $save = new IO::File ">>$arg{save}" or croak "could not save to file $arg{save}";
    my $returnable;
    if (defined $class->{_id}) {
        my $descriptors = join( "\cA", @{$class->{_descriptors}} );  # ^A delimiter
        $returnable = ">$class->{_id} $descriptors\n";
        foreach my $comment ( @{$class->{_comments}} ) {
            $returnable .= ";$comment\n";
        }
        foreach my $sequence ( @{$class->{_sequence}} ) {
            $returnable .= "$sequence\n";
        }
    }
    else {
        croak "ID is missing from the object";
    }
    print $save "$returnable";

    return($class);
}


# --------------------------------------------------------------------------
# P R I N T  (method)
# ==========================================================================
# USAGE      : $fasta->print();
# PURPOSE    : Accessor to print the FASTA class to STDOUT.
# RETURNS    : none
# PARAMETERS : none
# --------------------------------------------------------------------------
sub print {
    my $class = shift;

    # Print the class to STDOUT:
    my $printable;
    if (defined $class->{_id}) {
        my $descriptors = join( "\cA", @{$class->{_descriptors}} );  # ^A delimiter
        $printable = ">$class->{_id} $descriptors\n";
        foreach my $comment ( @{$class->{_comments}} ) {
            $printable .= ";$comment\n";
        }
        foreach my $sequence ( @{$class->{_sequence}} ) {
            $printable .= "$sequence\n";
        }
        print $printable;
    }
    else {
        croak "ID is missing from the object";
    }

    return( $class );
}


# --------------------------------------------------------------------------
# I D  (method)
# ==========================================================================
# USAGE      : $fasta->id();
# PURPOSE    : Accessor to retrieve the FASTA ID.
# RETURNS    : scalar
# PARAMETERS : none
# --------------------------------------------------------------------------
sub id {
    my $class = shift;
    if (defined $class->{_id}) {
        return( $class->{_id} );
    }
    else {
        croak "ID does not exist in object";
    }
}


# --------------------------------------------------------------------------
# S E Q U E N C E  (method)
# ==========================================================================
# USAGE      : $fasta->sequence();
# PURPOSE    : Accessor to retrieve the FASTA sequence.
# RETURNS    : scalar
# PARAMETERS : none
# --------------------------------------------------------------------------
sub sequence {
    my $class = shift;
    if (defined $class->{_sequence} ) {
        my $sequence = join(  "", @{$class->{_sequence}} );
        return( $sequence );
    }
    else {
        croak "SEQUENCE does not exist in object";
    }
}


# --------------------------------------------------------------------------
# D E S C R I P T O R S  (method)
# ==========================================================================
# USAGE      : $fasta->descriptors();
# PURPOSE    : Accessor to retrieve the FASTA descriptors.
# RETURNS    : array reference
# PARAMETERS : none
# --------------------------------------------------------------------------
sub descriptors {
    my $class = shift;
    return( \@{$class->{_descriptors}} );
}


# --------------------------------------------------------------------------
# C O M M E N T S  (method)
# ==========================================================================
# USAGE      : $fasta->comments();
# PURPOSE    : Accessor to retrieve the FASTA comments.
# RETURNS    : array reference
# PARAMETERS : none
# --------------------------------------------------------------------------
sub comments {
    my $class = shift;
    return( \@{$class->{_comments}} );
}


1; # End of module.

__END__


=head1 NAME

FASTAParse - A light-weight parsing module for handling FASTA formatted sequence within larger perl applications.


=head1 VERSION

This document describes FASTAParse version 0.0.3


=head1 SYNOPSIS

    # Manually creating a FASTA object:
    use FASTAParse;
    my $fasta = FASTAParse->new();
    $fasta->format_FASTA(
                         id          => 'example_0.0.1',
                         sequence    => 'ACGTCTCTCTCGAGAGGAGAGCTTCTCTCTAGGAGAG',
                         descriptors => ['Fake example sequence.', 'nucleotide'],
                         comments    => ['sequence is for illustration only'],
                         );
    $fasta->print();

    # Loading a FASTA object from a block of captured text:
    use FASTAParse;
    my $text = "
    >gi|55416189|gb|AAV50056.1| NADH dehydrogenase subunit 1 [Dasyurus hallucatus]
    ;Taken from nr GenBank
    MFTINLLIYIIPILLAVAFLTLIERKMLGYMQFRKGPNIVGPYGLLQPFADAVKLFTKEPLRPLTSSISIFIIAPILALT
    IALTIWTPLPMPNTLLDLNLGLIFILSLSGLSVYSILWSGWASNSKYALIGALRAVAQTISYEVSLAIILLSIMLINGSF
    TLKTLSITQENLWLIITTWPLAMMWYISTLAETNRAPFDLTEGESELVSGFNVEYAAGPFAMFFLAEYANIIAMNAITTI
    LFLGPSLTPNLSHLNTLSFMLKTLLLTMVFLWVRASYPRFRYDQLMHLLWKNFLPMTLAM
    ";
    my $fasta = FASTAParse->new();
    $fasta->load_FASTA( fasta => $text );
    my $id          = $fasta->id();
    my $sequence    = $fasta->sequence(); # Flat sequence.
    my @descriptors = @{ $fasta->descriptors() };



=head1 DESCRIPTION

FASTAParse is pretty simple in that it does one of two things: 1) loads a FASTA object from a chunk of text; 2) formats a FASTA object given explicit user input. See SYNOPSIS for example code for both functions. Once populated, individual sections of the FASTA entry may be pulled from the object. For further information on FASTA format, please see:

 http://en.wikipedia.org/wiki/Fasta_format
 http://blast.wustl.edu/doc/FAQ-Indexing.html


=head1 INTERFACE

=head2 new


new: Class constructor for FASTA.

    use FASTAParse;
    my $fasta = FASTAParse->new();


=head2 load_FASTA

load_FASTA: Method to populate the FASTA class with information. The "fasta" attribute passed to this method should be a chunk of FASTA text for a single entry. The text should retain all of the FASTA formatting, including the > header tag, line returns, ^A seperators, etc.

    $fasta->load_FASTA( fasta => $text );


=head2 format_FASTA

format_FASTA: Method to manually populate the FASTA class. Only ID and SEQUENCE are required. The SEQUENCE attribute should be a single, non-gapped line of text. The COLS attribute may be set to alter the column which line-wraps occur; default will be 60, 0 indicates no wrapping, and >80 is not recommeded as a general practice. The COMMENTS attribute is provided for placement after the header line: one or more comments, distinguished by a semi-colon at the beginning of the line, may occur. Most databases and bioinformatics applications do not recognize these comments so their use is discouraged, but they are part of the official format.

    $fasta->format_FASTA(
                         id          => 'example_0.0.1',
                         sequence    => 'ACGTCTCTCTCGAGAGGAGAGCTTCTCTCTAGGAGAG',
                         descriptors => ['Fake example sequence.', 'nucleotide'],
                         comments    => ['sequence is for illustration only'],
                         cols        => '75',
                         );


=head2 dump_FASTA

dump_FASTA: Method to dump the FASTA object back into a text chunk, retaining formatting. Returns a scalar.

    my $dumped = $fasta->dump_FASTA();


=head2 save_FASTA

dump_FASTA: Method to save the FASTA entry to a specified file, retaining formatting. Multiple calls to the same file will concatenate entries in the file.

    $fasta->save_FASTA( save => '/tmp/revised.fa' );


=head2 print

print: Method to print the object's contents in standard FASTA format to STDOUT.

    $fasta->print();


=head2 id

id: Accessor method to return the (scalar) FASTA ID.

    my $id = $fasta->id();


=head2 sequence

sequence: Accessor method to returen the (scalar) FASTA sequence. Sequence is returned as a single, non-gapped string.

    my $sequence = $fasta->sequence();


=head2 descriptors

descriptors: Accessor method to return an array reference to the list of descriptors in the FASTA object. Incoming FASTA text should have multi-part descriptors seperated by the ^A character on a single header line. As taken from http://blast.wustl.edu/doc/FAQ-Indexing.html

 A compound definition is a concatenation of multiple component
 definitions, each separated from the next by a single Control-A
 character (sometimes symbolized ^A; hex 0x01; or ASCII SOH [start of
 header]). Compound definitions are frequently seen
 (quasi-non-redundant) databases, where multiple instances of the
 exact same sequence are replaced by a single instance of the sequence
 with a concatenated definition line.

    my $descriptors_aref = $fasta->descriptors();


=head2 comments

comments: Accessor method to return an array reference to the list of comments in the FASTA object. Incoming FASTA text should have multi-part comments on their own lines, starting with the ; character. After the header line, one or more comments, distinguished by a semi-colon at the beginning of the line, may occur. Most databases and bioinformatics applications do not recognize these comments so their use is discouraged, but they are part of the official format.

    my $comments_aref = $fasta->comments();



=head1 CONFIGURATION AND ENVIRONMENT

FASTAParse requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-fastaparse@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Todd Wylie

C<< <perldev@monkeybytes.org> >>

L<< http://www.monkeybytes.org >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006, Todd Wylie C<< <perldev@monkeybytes.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perlartistic.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 NOTE

This software was written using the latest version of GNU Emacs, the
extensible, real-time text editor. Please see
L<http://www.gnu.org/software/emacs> for more information and download
sources.
