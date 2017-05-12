package Lemonolap::Filter4lemon;

use strict;
our $VERSION = '0.02';


# Preloaded methods go here.
sub new {
my $class =shift;
my %args = @_;
my $self;
$self=\%args;;
bless $self,$class;
return $self;
}

sub set_output {
	my $self =shift;
	$self->{file_out} = shift;
       return 1;
}       

sub apply {
my $self =shift;
my %args = @_;
my $file_in = $args{infile};
my $file_out = $args{outfile};
$self->{file_in} =$file_in;
$self->{file_out} =$file_out;
$self->{header} =$args{header};
my $FILE ;
my $FILEOUT;
open ( $FILE,"< $file_in") || die "$file_in $!\n";
open ( $FILEOUT,"> $file_out") || die "$file_out $!\n";
my %vhost;
my $line;
if ($self->{header} ) {
$line = readline($FILE);
chomp($line);
}


while (my $l = <$FILE>) {
	chomp($l);
    my @tab = split /\|/,$l;
$vhost{$tab[9]}++;

} 
close $FILE;
foreach (keys %vhost) {
delete $vhost{$_}  if $vhost{$_} < 10;

}
open ( $FILE,"< $file_in") || die "$file_in $!\n";
if ($self->{header} ) {
$line = readline($FILE);
chomp($line);
print $FILEOUT  "$line\n"; 
}
while (my $l =  <$FILE>) {
	chomp($l);
    my @tab = split /\|/ ,$l;
next unless $vhost{$tab[9]};
substr($tab[1],4,2) = "00";
my $l =join '|' ,@tab; 
print $FILEOUT "$l\n";
} 
close $FILE;
close $FILEOUT;

return 1 ;

}


1;
__END__

=head1 NAME

Lemonolap::Filter4lemon - Perl extension for lemonolap datawarehouse
=head1 SYNOPSIS

use Lemonolap::Filter4lemon;
Lemonolap::Filter4lemon->apply ('infile' => 'phase1.log',
                                 'outfile'=> 'phase2.log',
                                 'header' => 1);
  
This module is not used  directly , you must use Lemonolap::filter4lemon which is a wrapper (Lemonolap::Wrapperolap).

  see man's pages Lemonolap::Wrapperolap 

  

=head1 DESCRIPTION

  This module is a logs filter . It parses lemonldap logs issued form Lemonolap::Formatlog .
  It deletes  incompled lines and set the second of time at '00'

=head2 EXPORT

None by default.

=head2 Methods 

apply ('infile' => 'phase1.log',
       'outfile'=> 'phase2.log',
       'header' => 1);

 
 Sends on output file  the  filtered file
 if 'header'  is true the first line is inchanged (colomns heads)  
 

=head1 SEE ALSO

Lemonldap
http://lemonldap.sourceforge.net/

Lemonolap
http://lemonolap.sourceforge.net/

Lemonolap::Log4lemon 

Lemonolap::Filter4lemon

Lemonolap::Wrapperolap 

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2004 by Eric German , E<lt>germanlinux@yahoo.frE<gt>

 Lemonldap originaly written by Eric german who decided to publish him in 2003
 under the terms of the GNU General Public License version 2.

 This package is under the GNU General Public License, Version 2.
 The primary copyright holder is Eric German.
 Portions are copyrighted under the same license as Perl itself.

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; version 2 dated June, 1991.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 A copy of the GNU General Public License is available in the source tree;
 if not, write to the Free Software Foundation, Inc.,
 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


=cut
