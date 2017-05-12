package Lingua::Orthon;
use Math::MatrixReal;
use List::AllUtils qw(mesh);
use 5.006;
use strict;
use warnings;
our $VERSION = '0.02';

=pod

=head1 NAME

Lingua-Orthon - Various measures of orthographic relatedness between two letter strings

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

 use Lingua::Orthon 0.02;
 my $ortho = Lingua::Orthon->new();
 my $n = $ortho->index_identical('BANG', 'BARN');

=head1 DESCRIPTION

Lingua-Orthon - Various measures of orthographic relatedness between two letter strings

=head1 METHODS

=head2 new

 my $ortho = Lingua::Orthon->new();

Constructs/returns class object for accessing and passing params to other methods.

=cut

sub new {
	my ($class, %attribs) = @_;
	my $self = {};
	bless $self, $class;
    # $self->{'_proddat'} = _productivity_dat();
    # $self->{'_frqdat'} = _frequency_dat();
    my @lets = ('A'..'Z');
    my @nums = (0 .. 25);
    $self->{'_alphahash'} = { mesh(@lets, @nums ) };
	return $self;
}

=head3 are_orthons

Returns 0 or 1 if the two strings qualify as 1-mismatch (Coltheart-type) orthons: same size, and only one discrepancy by substitution (no additions, deletions or transpositions).

=cut

sub are_orthons {
    my $self = shift;
    return 0 if length($_[0]) != length($_[1]);
    return index_identical($self, $_[0], $_[1]) == length($_[0]) - 1 ? 1 : 0;
}

=head3 index_identical

 $val = $orthon->index_identical($w1, $w2);

Returns the number of letters that are both identical and in the same serial position. So for BANG and BARN, 2 would be returned, for B and A, ignoring the common N as it is the third letter in BANG, the fourth letter in BARN, and so not in the same serial position across these two words.

=cut

sub index_identical { # "Coltheart" orthons
    my $self = shift;
    
    my ($w1, $w2, $n, $i, $j) = (shift, shift, 0); # BENCHMARK: ~10%-25% faster than by list and separate decs
    for ($i = 0; $i < length($w1); $i++) {
         $n++ if substr($w1, $i, 1) eq (substr($w2, $i, 1) or last); # BENCHMARK: ~10%-20% faster than or by ||
         # run the length of the second word and see how many common letters anyway, and how many index positions apart:
         #my @cmn = ();
         #for ($j = 0; $i < length($w2); $j++) {
         #   if ( substr($w1, $i, 1) eq (substr($w2, $j, 1) or last) ) {
         #   
         #   }
         #}
    }
    return $n;
}

=head3 hdist

 $val = $orthon->hdist('String1', 'String2');

Return the Hamming Distance between two letter strings.

=cut

sub hdist {
     shift(@_);
     #String length is assumed to be equal
     return ($_[0] ^ $_[1]) =~ tr/\001-\255//; # thanks to: http://www.perlmonks.org/?node_id=500235
     #return length( $_[ 0 ] ) - ( ( $_[ 0 ] ^ $_[ 1 ] ) =~ tr[\0][\0] );
}

=head3 ldist

 $val = $orthon->ldist('String1', 'String2');

Return the Levenshtein Distance between two letter strings.

=cut

sub ldist {
    my ($self, $w1, $w2) = @_; # e.g. TAP, TAR
    
    my ($identity_cost, $addition_cost, $deletion_cost, $substitution_cost, $permutation_cost) = (0, 1, 1, 1, 1);
    my $refc = [$identity_cost, $deletion_cost, $addition_cost, $substitution_cost];
    
    return 0 if $w1 eq $w2; # Zero for total equality
    
    # The length of the other string if no length to this one:
    my $n1 = length($w1);
    my $n2 = length($w2);
	return $addition_cost * $n2 if !$n1; # $w2 is a complete addition to $w1
    return $deletion_cost * $n1 if !$n2; # $w2 is a complete deletion of $w1
    
    my $d_matrix = _load_matrix_weighted($self, $w1, $w2, $n1, $n2, $refc);
    return ref $d_matrix ? $d_matrix->element($n1+1, $n2+1) : $d_matrix;
    
    # add 1 to every element in the matrix: passed the element, the row index and the column index, i
    #$matrix = $matrix->each ( sub { (shift) + 1 } );
    #$new_matrix = $matrix->each_diag( \&function );
    
}

=head3 len_maxseq

 $val = $orthon->len_maxseq('String1', 'String2');

Return the length of the longest common subsequence between two letter strings. This subsequence is found by the C<lcss> method in L<String::LCSS_XS|String::LCSS_XS>.

=cut

sub len_maxseq {
    my ($self, $w1, $w2) = @_; # e.g. TAP, TAR
    require String::LCSS_XS;
    my @lcs = String::LCSS_XS::lcss($w1, $w2);
    return length($lcs[0]) || 0;
}

=head3 unique_abbrevs

 $val = $orthon->unique_abbrevs('String1', 'String2');

Return the number of unique abbreviations that can be made between two letter strings. This subsequence is found by the C<abbrev> method in L<Text::Abbrev|Text::Abbrev>.

=cut

sub unique_abbrevs {
    my ($self, $w1, $w2) = @_; # e.g. TAP, TAR
    require Text::Abbrev;
    my $href = Text::Abbrev::abbrev($w1, $w2);
    return scalar(keys(%{$href})) || 0;
}

=head3 myers_ukkonen 

 $val = $orthon->myers_ukkonen('String1', 'String2');

Return the Myers-Ukkonen distance between two letter strings, as found by the C<similarity> method in L<String::Similarity|String::Similarity>.

=cut

sub myers_ukkonen {
    my ($self, $w1, $w2) = @_; # e.g. TAP, TAR
    require String::Similarity;
    return String::Similarity::similarity($w1, $w2);
}

# private methods

sub _load_matrix_weighted { # without early out-clauses:
    my ($self, $w1, $w2, $n1, $n2, $refc) = @_;
    
    my $d_matrix = new Math::MatrixReal($n1+1, $n2+1);
    
    $d_matrix->assign(1, 1, 0);
    
    foreach (1 .. $n1) {$d_matrix->assign($_+1,1, $_*$refc->[1]);}
    foreach (1 .. $n2) {$d_matrix->assign(1,$_+1,$_*$refc->[1]);}

    for my $i (1 .. $n1) {
		my $w1_i = substr($w1, $i-1, 1);
		#print "before one inner row:\n", $d_matrix, "\n";
        for my $j(1 .. $n2) {
            my $w2_i = substr($w2, $j-1, 1);
            $d_matrix->assign($i+1, $j+1, # starts at column 2 row 2
                    &_min(
                        $d_matrix->element($i, $j+1) + _weight($self, $w1_i,'-' . $w2_i, $refc), # deletion
                        $d_matrix->element($i+1, $j) + _weight($self, '-' . $w1_i, $w2_i, $refc), # addition
                        $d_matrix->element($i, $j) + _weight($self, $w1_i, $w2_i, $refc) # substitution
                    ) 
             );
		}
        #print "after one inner row:\n", $d_matrix, "\n";
	}
    #print "final:\n", $d_matrix, "\n";
    return $d_matrix;
}

sub _weight {
	#the cost function
	my ($self, $w1_i, $w2_i, $refc) = @_;
    my $type = '_frqdat';
    my $apply = 0;
    
	if ($w1_i eq $w2_i) {        #print "identity $w1_i $w2_i\n";
		return $apply ? ($refc->[0]+1) * $self->{$type}->[$self->{'_alphahash'}->{$w1_i}] : 0; # cost for letter match
	}
    elsif ($w2_i =~ s/^\-//) {#print "deletion $w1_i $w2_i\n";
        # inversion of free-production for the lost letter: loss of the more familiar = less competition; makes the cost less, so "closer" distance
        my $prod = $apply ? $self->{$type}->[$self->{'_alphahash'}->{$w2_i}] : 1;
     	return $refc->[1] * 1/$prod; # cost for deletion
    }
    elsif ($w1_i =~ s/^\-//)  {         #print "addition $w1_i $w2_i\n";
        my $prod = $apply ? $self->{$type}->[$self->{'_alphahash'}->{$w1_i}] : 1;
        return $refc->[2] * 1/$prod; # cost for addition
	} 
    else { 	#print "mismatch $w1_i $w2_i\n";# $w1_i ne $w2_i
        my $prod = $apply ? $self->{$type}->[$self->{'_alphahash'}->{$w2_i}] / $self->{$type}->[$self->{'_alphahash'}->{$w1_i}] : 1;
        return $refc->[3] * $prod; # cost for letter mismatch
	}
}

sub _min {
	return $_[0] < $_[1]
		? $_[0] < $_[2] ? $_[0] : $_[2]
		: $_[1] < $_[2] ? $_[1] : $_[2];
}

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Lingua-Orthon-0.02 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-Orthon-0.02>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::Orthon


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Orthon-0.02>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-Orthon-0.02>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-Orthon-0.02>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-Orthon-0.02/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Roderick Garton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__DATA__