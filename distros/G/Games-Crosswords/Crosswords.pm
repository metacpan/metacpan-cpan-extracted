package Games::Crosswords;
use 5.006;
use strict;
use warnings;
our $VERSION = '0.01';

sub isvalidtable($){
    caller eq __PACKAGE__ or die;
    my $len = 0;
    for my $l (grep {$_} split //, $_[0]){
	$len = length $l unless $len;
	return 0 unless $len == length $l;
    }
    $len;
}

sub new {
    isvalidtable $_[1]->{TABLE} or die "Table is not valid";
    bless{ _TABLE => $_[1]->{TABLE}, _LEXICON => $_[1]->{LEXICON} }, $_[0];
}

sub table {
    isvalidtable $_[1] or die "Table is not valid";
    $_[0]->{_TABLE} = $_[1];
}

sub lexicon { $_[0]->{_LEXICON} = $_[1] }

sub getdim($) {
    my @table = split /\n/, shift;
    my ($x) = length ($table[0]);
    my ($y) = scalar @table;
    return ($x, $y);
}

sub mklexarr {
    caller eq __PACKAGE__ or die;
    @{$_[0]->{_LEXICON_ARR}} = ();
    for my $o (qw/ACROSS DOWN/){
	for my $e (@{$_[0]->{_LEXICON}->{$o}}){
	    push @{$_[0]->{_LEXICON_ARR}}, [ $e->[0], $e->[1], $o, $e->[2], $e->[3] ];
	}
    }
}


sub genpuzzle   { _generate($_[0], 'puzzle', $_[1]) }
sub gensolution { _generate($_[0], 'solution', $_[1]) }

sub _generate {
    caller eq __PACKAGE__ or die;

    my $HEAD=<<HEAD;
\\documentclass[letterpaper]{article}
\\usepackage{texdraw}
\\begin{document}
\\begin{texdraw}
HEAD

    my $FOOT=<<FOOT;
\\end{texdraw}
\\end{document}
FOOT

    my %dim;
    @dim{qw/x y/} = getdim( $_[0]->{_TABLE});
    my $arr;
    my ($dx, $dy) = (0.9, 0.9);
    my $tex="\\drawdim{cm} \\linewd 0.03 ";

    my $i=0;
    for my $L (split /\n/, $_[0]->{_TABLE}){ @{$arr->[$i++]} = split //, $L }

    # draws the cells
    for(my $i=0; $i<$dim{y}; $i++){
	for(my $j=0; $j<$dim{x}; $j++){
	    $tex.="\\move(@{[$j*$dx]} -@{[$i*$dy]}) ";
	    $tex.="\\rlvec(0 -$dy) \\rlvec($dx 0) \\rlvec(0 $dy) \\rlvec(-$dx 0) ";
	    if( $arr->[$i]->[$j] eq '@' ){
		$tex.="\\lfill f:0.1 ";
	    }
	}
    }

    mklexarr($_[0]);

    if($_[1] eq 'puzzle'){
	$tex.="\\move(0 -@{[(1+$dim{y})*$dy ]}) \\htext{ACROSS} ";
	$tex.="\\move(7 -@{[(1+$dim{y})*$dy ]}) \\htext{DOWN} ";
	
	my $j=0;
	my $i=1;
	my %i;
	@i{qw/down across/} = qw/1 1/;
	my $sno=1;
	my %sno;
	
	for my $entry (
		       sort { $a->[0] <=> $b->[0] }
		       sort { $a->[1] <=> $b->[1] }
		       @{$_[0]->{_LEXICON_ARR}}
		       ){
	    
	    $sno = defined $sno{$entry->[0].q/./.$entry->[1]} ?
		$sno{$entry->[0].q/./.$entry->[1]} : $i;
	    
	    if($entry->[2] eq 'ACROSS'){
		$tex.="\\move(0 -@{[(1+($i{across})*0.5+$dim{y})*$dy]}) ";
		$tex.="\\small \\htext{$sno $entry->[3]} ";
		$i{across}++;
	    }
	    elsif($entry->[2] eq 'DOWN'){
		$tex.="\\move(7 -@{[(1+($i{down})*0.5+$dim{y})*$dy]}) ";
		$tex.="\\small \\htext{$sno $entry->[3]} ";
		$i{down}++;
	    }
	    
	    $tex.="\\move(@{[$entry->[1]*$dx + 0.1]} -@{[$entry->[0]*$dy + 0.4]}) ";
	    $tex.="\\htext{$sno} ";
	    
	    unless($sno{$entry->[0].q/./.$entry->[1]}){
		$sno{$entry->[0].q/./.$entry->[1]} = $i;
		$i++;
	    }
	}
	
    }
    elsif($_[1] eq 'solution'){
	for my$entry ( @{$_[0]->{_LEXICON_ARR}} ){
	    my $i=0;
	    for my $letter (split //, $entry->[4]){
		$tex .= $entry->[2] eq 'ACROSS' ?
		    "\\move(@{[($entry->[1]+$i++)*$dx + 0.2]} -@{[$entry->[0]*$dy + 0.65]}) " : "\\move(@{[$entry->[1]*$dx + 0.2]} -@{[($entry->[0]+$i++)*$dy + 0.65]}) " ;

		$tex.="\\LARGE \\htext{@{[uc$letter]}} ";
	    }

	}
    }

    if($_[2]){
	open F, '>', $_[2];
	print F $HEAD.$tex.$FOOT;
	close F;
    }
    else{
	$HEAD.$tex.$FOOT;
    }
}


1;
__END__
    
}

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Games::Crosswords - Crosswords Game

=head1 SYNOPSIS

  use Games::Crosswords;
  $c = Games::Crosswords->new({TABLE => blah, LEXICON => blah blah});
  $c->genpuzzle();

=head1 DESCRIPTION

This module helps users create crosswords and print output to a TEX file. Users can convert the TEX ouput to a ps or pdf file.

=head1 METHODS

=head2 new({TABLE => blah, LEXICON => blah blah})

To illustrate the parameters, it is better to use an example.

  TABLE => <<BLAH;
  @@@@.@
  @@@@.@
  @@....
  @@@@.@
  BLAH,


@ is for a block cell, and . for a blank one.


  LEXICON =>
  {
     DOWN =>
 	[
 	 [ 0, 4, 'The camel language', 'Perl' ],
 	 ],
     ACROSS =>
 	[
 	 [ 2, 2, 'The cool author', 'xern' ],
 	 ]
  }


The first two indicate the B<y-th row> and B<the x-th> column. Both of them count from 0. Then, the B<hint> follows. The last one is the B<answer> which is not necessary unless users invoke B<gensolution>.

=head2 table

Users may redefine the crosswords table.

=head2 lexicon

Users may redefine the lexicon data.

=head2 genpuzzle

Generates the puzzle. It prints the result to STDOUT unless given the file's name

=head2 gensolution

Generates the solution. It prints the result to STDOUT unless given the file's name

=head1 SEE ALSO

eg/puzzle.pl, eg/solution.pl

=head1 AUTHOR

xern <xern@cpan.org>

=head1 LICENSE

Released under The Artistic License

=cut
