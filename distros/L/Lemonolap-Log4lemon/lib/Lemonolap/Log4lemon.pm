package Lemonolap::Log4lemon ;
use strict;
our $VERSION = '0.03';
sub can_field {
my $self = shift;
return ( 'date','time','node','source','url','response','size','referer','agent','vhost','uid');

}
sub get_line {

	my $line = shift;
chomp ($line);
my @tab = split /HTTP/ , $line;
(my $filler,my $machine,my $source)  = $tab[0]=~/.+(\d\d:\d\d\s?)(.+) logger: ([^ ]+)/;  
(my  $date,my $hour)  =$tab[0]=~ /\[([^:]+)(.+)\]/ ;
 $date =~ s/Nov/11/;
 $date =~ s/Dec/12/;
 $date =~ s/Jan/01/;
 $date =~ s/Feb/02/;
 $date =~ s/Mar/03/;
 $date =~ s/Apr/04/;
 $date =~ s/May/05/;
 $date =~ s/Jun/06/;
 $date =~ s/Jui/07/;
 $date =~ s/Aug/08/;
 $date =~ s/Sep/09/;
 $date =~ s/Oct/10/;
$date=~ s/\///g;
my $zdate= substr($date,4,4).substr($date,2,2).substr($date,0,2);


$hour =~ s/^://;
$hour =~ s/ .+$//;
$hour=~ s/://g;
(my $url)  =$tab[0]=~ /.+\"\w+\s(.+?) $/ ;
(my $uid) = $tab[0]=~ /uid=([^ ]+)/ ; 
my @tab2 = split /"/, $tab[1];
(my $response,my  $weight) = $tab2[1]=~ /(\d\d\d) (\d+)/;
($response) =$tab2[1]=~ /(\d\d\d)/ unless $response;
my $referer= $tab2[2];
undef $referer if $referer=~ /-$/;
my $client= $tab2[4];
my $vhost = $tab2[7];
$vhost=~ s/ //g;
return ($zdate,$hour,$machine,$source,$url,$response,$weight,$referer,$client,$vhost,$uid);





}	
sub get_field_by_name{
my $self = shift;
my %args= @_;
my $separator =$args{separator}||'|';
if ($args{header}) {
my @t =$self->can_field();
if ( $args{'fields'} )  {
    my @tab =@{$args{fields} } ;
@t =@tab;
 }
my $l = join $separator, @t;
return $l ;

}
my $FILE =$self->{handler};
my $line = <$FILE> ;
 unless ($line ) {

	close $FILE;
       return undef;
}       
my @fline = get_line($line);
if ( $args{'fields'} )  {
    my @a =$self->can_field();
    my %tmp;
    foreach (@a) {
	my $value = shift @fline ;
	$tmp{$_} = $value;
    }
    my @tab =@{$args{fields} } ;
    my @tt;
 foreach (@tab) {
     my $name =$_;
if (lc ($name) eq 'date:aaaa') {
  $tmp{$name} = substr($tmp{date},0,4); 
  }  
if (lc ($name) eq 'date:mm') {
  $tmp{$name} = substr($tmp{date},4,2); 
  }  
if (lc ($name) eq 'date:dd') {
  $tmp{$name} = substr($tmp{date},6,2); 
  }  
if (lc ($name) eq 'time:hh') {
  $tmp{$name} = substr($tmp{time},0,2); 
  }  
if (lc ($name) eq 'time:mm') {
  $tmp{$name} = substr($tmp{time},2,2); 
  }  
if (lc ($name) eq 'time:se') {
  $tmp{$name} = substr($tmp{time},4,2); 
  }  

     push @tt , $tmp{$name} ;

}  
    return join $separator,@tt;

} else 
{ return  join $separator ,@fline ;}


}	

sub get_field_by_label{
my $self = shift;
my %args= @_;
my $separator =$args{separator}||'|';
if ($args{header}) {
my @t =$self->can_field();
if ( $args{'label'} )  {
    my @tab =@{$args{label} } ;
@t =@tab;
 }

my $l = join $separator, @t;
return $l ;

}
my $FILE =$self->{handler};
my $line = <$FILE> ;
 unless ($line ) {

	close $FILE;
       return undef;
}       
my @fline = get_line($line);
if ( $args{'label'} )  {
    my @a =$self->can_field();
    my %tmp;
    foreach (@a) {
	my $value = shift @fline ;
	$tmp{$_} = $value;
    }
    my @tab =@{$args{fields} } ;
    my @tt;
 foreach (@tab) {
# mapping 
 my  $name = $self->{mapping}{$_} ;
if (lc ($name) eq 'date:aaaa') {
  $tmp{$name} = substr($tmp{date},0,4); 
  }  
if (lc ($name) eq 'date:mm') {
  $tmp{$name} = substr($tmp{date},4,2); 
  }  
if (lc ($name) eq 'date:dd') {
  $tmp{$name} = substr($tmp{date},6,2); 
  }  
if (lc ($name) eq 'time:hh') {
  $tmp{$name} = substr($tmp{time},0,2); 
  }  
if (lc ($name) eq 'time:mm') {
  $tmp{$name} = substr($tmp{time},2,2); 
  }  
if (lc ($name) eq 'time:se') {
  $tmp{$name} = substr($tmp{time},4,2); 
  }  

   push @tt , $tmp{$name} ;

}  
    return join $separator,@tt;

} else 
{ return  join $separator ,@fline ;}


}	

sub apply {
my $self =shift;
my %args = @_;
my $file_in = $args{infile};
my $file_out = $args{outfile};
$self->{file_in} =$file_in unless $self->{file_in};
$self->{file_out} =$file_out unless $self->{file_out};

$self->{header} =$args{header};
my $FILE ;
my $FILEOUT;
open ( $FILE,"< $file_in") || die "$file_in $!\n";
open ( $FILEOUT,"> $file_out") || die "$file_out $!\n";
$self->{handler} =$FILE;
if ($self->{header} ) {
my $separator =$args{separator}||'|';
my @t =$self->can_field();
my $l = join $separator, @t;
print  $FILEOUT "$l\n";
}
 while (my $l =$self->get_field_by_name() ) {
	print $FILEOUT "$l\n" ; 
 }
    close $FILE;
    close $FILEOUT;
}

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
sub set_label {
my $self =shift;
my %args = @_;
foreach (keys %args) {
    $self->{mapping}{$_} =$args{$_} ;
     $self->{mapping}{$args{$_}} =$_ ;
}
return 1;

}
1;
__END__

=head1 NAME

    Lemonolap::Log4lemon - Perl extension for Lemonolap  framework
  

=head1 SYNOPSIS

 use Lemonolap::Log4lemon;
 my $f =Lemonolap::Log4lemon->new('file' => "/tmp/lemonldap.log",);
 print $f->can_field,"\n";
 print $f->get_field_by_name(header => 1),"\n";
 $f->set_label('source' => 'adresse IP' );
 while ($l =$f->get_field_by_name(fields =>['time','date:aaaa','uid']) ) {
	print "$l\n" ; 
 }



=head1 DESCRIPTION

This module is a logs formater . It parses lemonldap logs into flat file with separator .
 
The lemonldap framework is a web SSO server apache . This log is like :

 LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" \"%{forensic-id}n\" %v"

 the %v (virtual host name ) at the end of line is the only difference with combined format apache log

=head1 Methods

=head2 new->(file => /path_file) ;

 Path of log file . This file MUST exits . 
 
=head2 can_field () ;

 return the list of supported field  

=head2 get_field (header => 1,
                  fields => [f1,F2..] );

 return  a string with fields or names of colomns (no both) .  
 If fields is ometted  , return a list like can_field


=head2 get_label (header => 1,
                  fields => [f1,F2..] );

 Like get_field but uses symbolics names (labels) instead  names


=head2 set_label (
                  'fieldname' => 'myname');

 Set symbolic name for field .

=head2 time and date

A parser MUST return date and time (format aaaammjj and hhmmss )  
 but you can get only aaaa or mm or dd by this syntax :
  date:aaaa
  date:mm
  date:dd
 
 and so for time : time:hh time:mm time:se


=head1 SEE ALSO

Lemonldap
http://lemonldap.sourceforge.net/

Lemonolap
http://lemonolap.sourceforge.net/

Lemonolap::Formatelog 



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






