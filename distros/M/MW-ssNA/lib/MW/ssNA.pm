package MW::ssNA;

use 5.006;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(ssNA);

=head1 NAME

MW::ssNA - Perl extension to calculate molecular weight of ssDNA or ssRNA.

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';


=head1 SYNOPSIS

	use MW::ssNA;
	my @foo = ssNA("input_filename","option");
	# option : 'd'-DNA, 'r'-RNA, 'cd'-total count of ATGC in DNA, 'cr'-total count of AUGC in RNA
	foreach(@foo) { print;}


=cut


sub ssNA {
	my $input=$_[0];
	my $choice=$_[1];
	my $flag11=0;
	my ($flag,$count,$A,$T,$G,$C,$ssdna);
	my ($x,$a1,$a2,$a3,$a4,$tu);
	if ($choice eq 'd')
	{
	$a1=313.2;
	$a2=304.2;
	$a3=329.2;
	$a4=289.2;
	$tu='T';
	}
	elsif ($choice eq 'r')
	{ 
	$a1=329.2;
	$a2=306.2;
	$a3=345.2;
	$a4=305.2;
	$tu='U';
	}
	elsif ($choice eq 'cd') {$flag11=1;$tu='T';}
	elsif ($choice eq 'cr') {$flag11=1;$tu='U';}
	else {print "Invalid option!";exit;}
	open(ID,"$input") or die "Could not open $input: $!";;
	$flag=$count=0;
	while(<ID>)
	{
	chomp $_;
	if(eof)
	{
	$A+=()=$_=~/A/g; $T+=()=$_=~/$tu/g; $G+=()=$_=~/G/g; $C+=()=$_=~/C/g;
	$count++;
	$flag=1;
	}
	if ($_=~/^>/ || $flag == 1)
	{
	if($count!=0)
	{
	$ssdna=($A*$a1)+($T*$a2)+($G*$a3)+($C*$a4);
	if ($flag11 == 1) { print "$x\t A=$A\t$tu=$T\tC=$C\tG=$G\n"; }
	else {print "$x\tMW : $ssdna\n";}
	$A=$T=$G=$C='';
	}
	$x=$_;
	next;
	}
	$A+=()=$_=~/A/g; $T+=()=$_=~/$tu/g; $G+=()=$_=~/G/g; $C+=()=$_=~/C/g;
	$count++;
	}

}
=head1 AUTHOR

SHANKAR M, C<< <msinfopl at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<msinfopl at gmail.com>

=head1 ACKNOWLEDGEMENTS

Saravanan S E and Sabarinathan Radhakrishnan, for all their valuable thoughts and care. 

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Shankar M.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=cut

1; # End of MW::ssNA
