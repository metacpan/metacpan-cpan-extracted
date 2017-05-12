package Lemonolap::Wrapperolap;
use strict;
use XML::Simple;
our $VERSION = '0.01';
sub new {
my $class =shift;
my %args = @_;
my $file = $args{config};
my $self;
my $config= XMLin ($file);
$self->{file} =$file;
$self->{config} =  $config;
$self->{workflow}= $args{workflow};

bless $self,$class;
return $self;

}
sub get_file_in {
    my $self =shift;
    my $phase =$self->{phase};
    return $self->{config}->{$phase}->{file_in};

}
sub get_file_out {
    my $self =shift;
    my $phase =$self->{phase};
    return $self->{config}->{$phase}->{file_out};

}

sub get_handler {
    my $self =shift;
    my $phase =$self->{phase};
     return $self->{config}->{$phase}->{handler};
}

sub get_config {
    my $self =shift;
    my $phase =$self->{phase};
    return $self->{config}->{$phase};

}
sub set_phase {
   my $self =shift;
   $self->{phase} = shift;
   return 1;
}
sub run {
    my $self =shift;
my %args = @_;

    my @tab = @{$self->{workflow}};

my $header =$args{header}; 
foreach (@tab)  {
$self->set_phase($_);
my $file = $self->get_file_in;
my $handler= $self->get_handler;
my $sortie =$self->get_file_out;
eval "use $handler;";
my $hook =$handler->new (%args);
$hook->set_output($sortie);
$hook->apply(infile =>$file,
                outfile =>$sortie,
                header =>$header ) ;
}
return 1;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lemonolap::Wrapperolap  - Perl extension for Lemonolap  framework

=head1 SYNOPSIS

use Lemonolap::Wrapperolap
my $wrapper = Lemonolap::Wrapperolap->new (config => "myxml.xml" );
foreach ('format','filter')  {
$wrapper->set_phase($_);
my $file = $wrapper->get_file_in;
my $handler= $wrapper->get_handler;
my $sortie =$wrapper->get_file_out;
eval "use $handler;";
my $hook= $handler->new();
$hook->set_output($sortie);
$hook->apply(infile =>$file,
                outfile =>$sortie,
                header =>'1' ) ;
}




__END__ 


 or  easier : 


use Lemonolap::Wrapperolap;
my $wrapper = Lemonolap::Wrapperolap->new (config => "myxml.xml",
                                           workflow => ['format','filter']
                                               );
$wrapper->run (header =>1 );





__END__ 



  and myxml.xml is like this 

  <lemonolap>
	<format id="format1"
		file_in="extract.log"
		handler="Lemonolap::Log4lemon"
                file_out="phase1.log" 
	        />
	<filter id="filter1" 
		file_in="phase1.log"
	        file_out="phase2.log" 
	        handler="Lemonolap::Filter4lemon"
	       />	
  </lemonldap>	



=head1 DESCRIPTION

This module is a logs wrapper  . It reads  lemonldap logs and applies somes mofications 
 

=head1 Methods

=head2 new->(config => /path_file_xml) ;

 Path of XML  file . This file MUST exits . 

=head2 set_phase ('name_of_phase') ;

 set phase , this operation MUST be done BEFORE all other methods (except new)   
 
=head2 get_file () ;

 return the file read from xml config   

=head2 get_handler ();

 return  a string with module name  

=head2 get_config;

 return a reference of hash config 

=head2 run (config => my_xml_config,
            workflow =>[phase,..]         ) 

Process all phase scheduled in workflow


=head1 SEE ALSO

Lemonldap
http://lemonldap.sourceforge.net/

Lemonolap
http://lemonolap.sourceforge.net/

Lemonolap::Log4lemon 

Lemonolap::Filter4lemon

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
