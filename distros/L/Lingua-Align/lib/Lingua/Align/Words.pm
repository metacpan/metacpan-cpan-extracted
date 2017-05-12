package Lingua::Align::Words;
#---------------------------------------------------------------------------    
# Copyright (C) 2009 Jörg Tiedemann                                             
# jorg.tiedemann@lingfil.uu.se
#                                                                               
# This program is free software; you can redistribute it and/or modify          
# it under the terms of the GNU General Public License as published by          
# the Free Software Foundation; either version 2 of the License, or             
# (at your option) any later version.                                           
#                                                                               
# This program is distributed in the hope that it will be useful,               
# but WITHOUT ANY WARRANTY; without even the implied warranty of                
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                 
# GNU General Public License for more details.                                  
#                                                                               
# You should have received a copy of the GNU General Public License             
# along with this program; if not, write to the Free Software                   
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA     
#---------------------------------------------------------------------------    
#
# 
#

use 5.005;
use strict;

use vars qw(@ISA);
@ISA = qw(Lingua::Align::Trees);


sub print_link_matrix{
    my $self=shift;
    my ($srcwords,$trgwords,$links)=@_;
    my @trgchar=();
    my $maxTrgLen=0;
    foreach (0..$#{$trgwords}){
	@{$trgchar[$_]}=split(//,$$trgwords[$_]);
	if ($#{$trgchar[$_]}>$maxTrgLen){$maxTrgLen=$#{$trgchar[$_]};}
    }
    foreach my $t (0..$#{$trgwords}){print STDERR '--';}
    print STDERR "-|--\n";
    foreach my $s (0..$#{$srcwords}){
	foreach my $t (0..$#{$trgwords}){
	    my $sid=$s+1;my $tid=$t+1;
	    if (exists $$links{$sid.' '.$tid}){
		if ($$links{$sid.' '.$tid} eq 'S'){
		    print STDERR ' *';
		}
		else{print STDERR ' O';}
	    }
	    else{print STDERR '  ';}
	}
	print STDERR ' | ',$$srcwords[$s],"\n";
    }
    foreach my $t (0..$#{$trgwords}){print STDERR '--';}
    print STDERR "-|--\n";
#    for (my $x=$maxTrgLen;$x>=0;$x--){
    foreach my $x (0..$maxTrgLen){
	foreach my $t (0..$#{$trgwords}){
	    printf STDERR "%2s",$trgchar[$t][$x];
	}
	print STDERR "\n";
    }
    print STDERR "\n\n";
}




sub compare_link_matrix{
    my $self=shift;
    my ($srcwords,$trgwords,$links1,$links2)=@_;
    my @trgchar=();
    my $maxTrgLen=0;

    my ($countS,$countP,$countZ,$countD,$countMS,$countMP,$countWS,$countWP)=
	(0,0,0,0,0,0,0,0);

    foreach (0..$#{$trgwords}){
	@{$trgchar[$_]}=split(//,$$trgwords[$_]);
	if ($#{$trgchar[$_]}>$maxTrgLen){$maxTrgLen=$#{$trgchar[$_]};}
    }
    foreach my $t (0..$#{$trgwords}){print STDERR '--';}
    print STDERR "-|--\n";
    foreach my $s (0..$#{$srcwords}){
	foreach my $t (0..$#{$trgwords}){
	    my $sid=$s+1;my $tid=$t+1;

	    if (exists $$links1{$sid.' '.$tid}){
		if ($$links1{$sid.' '.$tid} eq 'S'){
		    if (exists $$links2{$sid.' '.$tid}){
			if ($$links2{$sid.' '.$tid} eq 'S'){
			    print STDERR ' S';
			    $countS++;
			}
			else{
			    print STDERR ' z';
			    $countZ++;
			}
		    }
		    else{
			print STDERR ' *';
			$countWS++;
		    }
		}
		elsif (exists $$links2{$sid.' '.$tid}){
		    if ($$links2{$sid.' '.$tid} eq 'P'){
			print STDERR ' P';
			$countP++;
		    }
		    else{
			print STDERR ' d';
			$countD++;
		    }
		}
		else{
		    print STDERR ' +';
		    $countWP++;
		}
	    }
	    elsif (exists $$links2{$sid.' '.$tid}){
		if ($$links2{$sid.' '.$tid} eq 'P'){
		    print STDERR ' ·';
			$countMP++;
		}
		else{
		    print STDERR ' -';
		    $countMS++;
		}
	    }
	    else{print STDERR '  ';}
	}
	print STDERR ' | ',$$srcwords[$s],"\n";
    }
    foreach my $t (0..$#{$trgwords}){print STDERR '--';}
    print STDERR "-|--\n";
#    for (my $x=$maxTrgLen;$x>=0;$x--){
    foreach my $x (0..$maxTrgLen){
	foreach my $t (0..$#{$trgwords}){
	    printf STDERR "%2s",$trgchar[$t][$x];
	}
	print STDERR "\n";
    }
    print STDERR "\n";

    printf STDERR "  %2d x %s",$countS,"(S) .... proposed = gold = S\n";
    printf STDERR "  %2d x %s",$countP,"(P) .... proposed = gold = P\n";

    printf STDERR "  %2d x %s",$countZ,"(z) .... proposed = P, gold = S (ok!)\n";
    printf STDERR "  %2d x %s",$countD,"(d) .... proposed = S, gold = P (ok!)\n";

    if ($countWS){print STDERR '! ';}else{print STDERR '  ';}
    printf STDERR "%2d x %s",$countWS,"(*) .... proposed = S, gold = not aligned (wrong!)\n";
    if ($countWP){print STDERR '! ';}else{print STDERR '  ';}
    printf STDERR "%2d x %s",$countWP,"(+) .... proposed = P, gold = not aligned (wrong!)\n";
    if ($countMS){print STDERR '! ';}else{print STDERR '  ';}
    printf STDERR "%2d x %s",$countMS,"(-) .... proposed = not aligned, gold = S (missing!)\n";
    printf STDERR "  %2d x %s",$countMP,"(·) .... proposed = not aligned, gold = P (missing!)\n\n";

    print "total: ",$countS+$countP+$countZ+$countD," correct, ";
    print $countMS+$countMP," missing, ";
    print $countWS+$countWP," wrong\n";

    my $nrA=$countS+$countP+$countZ+$countD+$countWS+$countWP;
    my $nrS=$countS+$countZ+$countMS;
    my $interAP=$countS+$countP+$countZ+$countD;
    my $interAS=$countS+$countZ;

    my $precision=$interAP/$nrA;
    my $recall=$interAS/$nrS;
    my $AER=1-($interAP+$interAS)/($nrA+$nrS);

    $self->{COUNTS}++;
    $self->{nrA}+=$nrA;
    $self->{nrS}+=$nrS;
    $self->{interAP}+=$interAP;
    $self->{interAS}+=$interAS;

    $self->{alignP}+=$precision;
    $self->{alignR}+=$recall;
    $self->{AER}+=$AER;

    printf "this sentence: precision = %5.4f",$precision;
    printf ", recall = %5.4f",$recall;
    printf ", AER = %5.4f\n",$AER;

    printf "      average: precision = %5.4f",$self->{alignP}/$self->{COUNTS};
    printf ", recall = %5.4f",$self->{alignR}/$self->{COUNTS};
    printf ", AER = %5.4f\n",$self->{AER}/$self->{COUNTS};

    printf "        total: precision = %5.4f",$self->{interAP}/$self->{nrA};
    printf ", recall = %5.4f",$self->{interAS}/$self->{nrS};
    printf ", AER = %5.4f\n\n",
    1-($self->{interAP}+$self->{interAS})/($self->{nrA}+$self->{nrS});

    

}

1;

__END__

=head1 NAME

Lingua::Align::Words - Module for word alignment

=head1 SYNOPSIS

=head1 DESCRIPTION

This module essentially inherits everything from tree alignment but adds some tools which are specific to word alignment.

=head1 SEE ALSO

=head1 AUTHOR

Joerg Tiedemann

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
