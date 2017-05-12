package Lingua::POSAlign;

use strict;
use Data::Dumper;
use List::Util qw(max);

our $VERSION = '0.01';

our %penalty = qw(
		  MD -1
		  NN -7
		  NNS -7
		  VBN -7
		  RB -1
		  IN -6 
		  CC -6 
		  TO -1
		  VBP -7
		  JJ -1
		  VB -7
		  VBD -7
		  VBG -7
		  VBZ -7
		  DT -2
		  PRP -1
		  );

sub penalty($) {
    $penalty{shift()} || -2;
}

sub _init_table {
    my $self = shift;
    my ($a, $b) = @_;
    foreach my $i (0..@$a){
	foreach my $j (0..@$b){
	    $self->{table}[$i][$j] = 0;
	}
    }
}

use constant _GAP_ => '--';

sub score {
    my ($a, $b) = @_;
    if( $a eq _GAP_ ){
	return penalty $b;
    }
    elsif($b eq _GAP_){
	return penalty $a;
    }
    elsif($a eq $b){
	return 7;
    }
    else {
	return -2;
    }
}

sub _run_alignment {
    my $self = shift;
    my ($a, $b) = @_;
    my $T = $self->{table};
    foreach my $i (0..$#$a){
        foreach my $j (0..$#$b){
	    $T->[$i][$j]
		= max(
		      0,
		      $T->[$i-1][$j-1]+score($a->[$i], $b->[$j]),
		      $T->[$i-1][$j]+score($a->[$i], _GAP_),
		      $T->[$i][$j-1]+score(_GAP_, $b->[$j]),
		      );
	}
    }
}


sub dump_table {
    my $self = shift;
    my $table = $self->{table};
    for my $i (0..$#{$table}-1){
	printf(join(q/ /, map{"%3s"} 0..$#{$table->[$i]}-1), @{$table->[$i]});
	print $/;
    }
}

sub dump_alignment {
    my $self = shift;
    my $align = $self->{align};
    my @a = map{$_->[0]} @{$self->{align}};
    my @b = map{$_->[1]} @{$self->{align}};
    printf(join(q/ /, map{"%3s"} @{$self->{align}}), @a);
    print $/;
    printf(join(q/ /, map{"%3s"} @{$self->{align}}), @b);
    print $/;
}

sub _pair {
    my ($a, $b, $i, $j, $r) = @_;
    my ($va, $vb) = (
		     (!$r->[0][$i] ? $a->[$i] : _GAP_),
		     (!$r->[1][$j] ? $b->[$j] : _GAP_)
		    );
    $r->[0][$i] =1 if $va ne _GAP_;
    $r->[1][$j] =1 if $vb ne _GAP_;

    [$va, $vb];
}


sub _backtrace {
    my $self = shift;
    my ($a, $b) = @_;
    my $T = $self->{table};
    my @stack;
    my $i = $#$a;
    my $j = $#$b;
    my $r;

    while($i>=0 && $j>=0){
#	print "$i $j\n";
	if(($i>0 && $j>0) && ($a->[$i] eq $b->[$j])){
	    unshift @stack, _pair($a,$b,$i,$j,$r);
	    $r->[0][$i] =1 ;
	    $r->[1][$j] =1 ;
	    $i--;
	    $j--;
	}
	elsif($i>0 && $j>0){
	    if($T->[$i-1][$j] >= $T->[$i][$j-1]){
		unshift @stack, [$a->[$i], _GAP_];
		$i--;
	    }
	    elsif($T->[$i-1][$j] < $T->[$i][$j-1]){
		unshift @stack, [_GAP_, $b->[$j]];
		$j--;
	    }
	}
	elsif ($i ==0 && $j ==0){
	    if(($a->[$i] eq $b->[$j])){
		unshift @stack, _pair($a,$b,$i,$j,$r);
		$r->[0][$i] =1 ;
		$r->[1][$j] =1 ;
	    }
	    else{
		unshift @stack, [$a->[$i], _GAP_];
		unshift @stack, [_GAP_, $b->[$j]];
	    }
	    $i--;
	    $j--;
	}
	else {
	    if($i == 0){
		if(($a->[$i] eq $b->[$j])){
		    unshift @stack, _pair($a,$b,$i,$j,$r);
		    $r->[0][$i] =1 ;
		    $r->[1][$j] =1 ;
		    $j--;
		}
		else {
		    unshift @stack, [_GAP_, $b->[$j]];
		    $j--;
		}
	    }
	    elsif($j==0){
                if(($a->[$i] eq $b->[$j])){
		    unshift @stack, _pair($a,$b,$i,$j,$r);
		    $r->[0][$i] =1 ;
		    $r->[1][$j] =1 ;

                    $i--;
		}
		else {
		    unshift @stack, [$a->[$i], _GAP_];
		    $i--;
		}
	    }
	}
    }
    $self->{align} = \@stack;
}

sub total_score {
    my $self = shift;
    return $self->{total_score} if defined $self->{total_score};
    my$s;
    foreach my $i (@{$self->{align}}){
#	print "($i->[0], $i->[1]) => ".score($i->[0], $i->[1])."\n";
	$s+=score($i->[0], $i->[1]);
    }
    $s;
}

sub _clear {
    my $self = shift;
    $self->{table} = [];
    $self->{align} = [];
    $self->{total_score} = undef;
}

sub alignment { $_[0]->{align} }

sub align {
    my $self = shift;
    my ($a, $b) = @_;
#    print Dumper $a, $b;
    $self->_clear();
    $self->_init_table($a, $b);
    $self->_run_alignment($a, $b);
    $self->_backtrace($a, $b);
#    print Dumper $self;
}

sub new {
    bless {
	table => [],
    }, shift;
}

1;

__END__

=head1 NAME

Lingua::POSAlign - Local alignment tool for POS tags

=head1 DESCRIPTION

This modules enable you to make pairwise alignments between any two
POS tag sequences.


    use Lingua::POSAlign;

    my $n = new Lingua::POSAlign;

    $n->align([qw(DT MD VB VBN)],
	      [qw(DT NNS VBP VBN)]);

    $a = $n->alignment; # Return the alignment result

    $n->total_score;    # Return the total score linearly
                        # and pairwisely summed up pairwise
                        # scores


    $n->dump_table;     # Dump alignment table to STDOUT
    $n->dump_alignment; # Dump alignment diagram to STDOUT

If you need to modify the gap penalty table, use B<%Lingua::POSAlign::penalty> and B<penalty()>;
override B<score()> if you need to define your own scoring function.

=head1 THE AUTHOR

Yung-chung Lin (a.k.a. xern) E<lt>xern@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut
