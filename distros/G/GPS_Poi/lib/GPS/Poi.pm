package GPS::Poi;
use strict;
use Class::Std::Utils;
our $VERSION = '0.01';

{ 
    my %file_of ;
    my @ref_entry_of; 
    sub new{
        my ($class,$arg_ref) =@_;
        my $new_object =bless anon_scalar(),$class;
        
         $file_of{ident $new_object}= $arg_ref->{file}||'NULL';
        return $new_object;
    }

    sub DESTROY {
      my ($self)=@_;
      delete $file_of{ident $self};
    }
    
    sub parse  {

    my ($self,$arg_ref) =@_;
    $file_of{ident $self}= $arg_ref->{file} if exists $arg_ref->{file} ; 
     
    return 0 if $file_of{ident $self} eq 'NULL' ;
    (open my $input, '<',$file_of{ident $self}) ||return 0 ;
    while ($input) {
        read ($input,$a,1);
        my $code = unpack "C" ,$a;
        last unless defined $code ;
        if ($code== 0 or $code ==2) 
 	    {
	      read ($input,$a,4);
	      my $long= unpack "V",$a;
	      my $total= $long-5;
	      read ($input,$a,$total);
	      my ($longitude,$latitude,$chaine_c)= unpack "VVa*",$a;
              $longitude = $longitude / 100000.000000; 
              $longitude =sprintf ("%.6f",$longitude);
              my $i =length ($longitude);
	      for ($i;$i < 13 ;$i++) {
     	        $longitude = "0".$longitude   ;
              }
	      $latitude = $latitude/ 100000.000000; 
              $latitude =sprintf ("%.6f",$latitude);
              my $i =length ($latitude);
	      for ($i;$i < 13 ;$i++) {
     	        $latitude = "0".$latitude   ;
              }
	      my $chaine=substr($chaine_c,0,-1);
              my $entry = GPS::Poi::Entry->new ({ 'code' =>$code ,
                                            'label' => $chaine,
                                             'long' => $longitude,
                                             'lat' => $latitude ,
					  });
              push @ref_entry_of,$entry;
             } else
                { last; 
                }
            } 
   
close $input;
    return ($#ref_entry_of + 1) ;

}
sub clear_list  {
     my ($self)=@_;
     @ref_entry_of=(); 
 }


sub all_as_list  {
     my ($self)=@_;
  my @tmp; 
    for my $entry  (@ref_entry_of) {
  push @tmp,$entry->as_list;
   

     }

     return @tmp;
}
sub dump_list  {
     my ($self)=@_;
  my @tmp; 
    for my $entry  (@ref_entry_of) {
  push @tmp,$entry->as_print;
   

     }
my $a= join "\n" ,@tmp ; 
     return "$a\n";
}

    sub DESTROY {
      my ($self)=@_;
      delete $file_of{ident $self};
      undef @ref_entry_of;
}
}

package GPS::Poi::Entry;
use strict;
use Class::Std::Utils;
our $VERSION = '0.01';
{ 
    my %label_of;
    my %long_of;
    my %lat_of;
    my %code_of; 
sub new {
        my ($class,$arg_ref) =@_;
        my $new_object =bless anon_scalar(),$class;
         $label_of{ident $new_object}= $arg_ref->{label}||'NULL';
         $long_of{ident $new_object}= $arg_ref->{long}||'NULL';
         $lat_of{ident $new_object}= $arg_ref->{lat}||'NULL';
         $code_of{ident $new_object}= $arg_ref->{code}||'NULL';
         return $new_object;
    }
sub as_list {
     my ($self)=@_;
     my @tmp=  ($label_of{ident $self}, $long_of{ident $self} ,$lat_of{ident $self} ,$code_of{ident $self});
     return \@tmp;
}
sub as_print {
     my ($self)=@_;
     my $a = "$long_of{ident $self}  Lg - $lat_of{ident $self} Lt - $label_of{ident $self} - $code_of{ident $self}";
     return $a;
}

    sub DESTROY {
      my ($self)=@_;
      delete $label_of{ident $self};
      delete $long_of{ident $self};
      delete $lat_of{ident $self};
      delete $code_of{ident $self};
    }
}


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

GPS::Poi - Perl extension for 'ov2' file extension of POI (Point of Interrest ) for tomtom GPS 

=head1 SYNOPSIS

  use GPS::Poi;
  my $poi = GPS::Poi->new();
  my $nb = $poi->parse({file => 'myfile.ov2' });
  my  @list = $poi->all_as_list();
  my  $dump = $poi->dump_list();
  print $dump;


=head1 DESCRIPTION

GPS::Poi is a Perl module who  provides a variety of low- and high-level methods for parsing  'ov2' extention file of POI (Point of Interrest ). 'ov2' is Tomtom GPS format . Tomtom is trade mark .

=head1 METHODS

=head2 new [ ({file =>/myfile.ov2}) ]

  The file paremters is optional

=head2 parse [ ({file =>/myfile.ov2}) ]
 
  The file paremters is optional ONLY if it was already supplied with new method.
  This method return the number of file record or 0 if error.

=head2  all_as_list 

  Return array of each record in the same order of file.
  Each item is like this : (Label,long,lat,code)   

=head2 dump_list
  
  Return a string who can be printable : eg

000002.394520  Lg - 000048.818100 Lt - Ivry sur Seine - 2
000002.394200  Lg - 000048.825190 Lt - Bercy - 2
000002.345520  Lg - 000048.784400 Lt - Hay les Roses - 2

=head2 clear_list

  Clear the current list.
 
=head1 TODO 

This module can only read ov2 file , I must add write,merge methods. Add implementation of type 3 record

=head1 SEE ALSO

=over 4

=item tomtom.com
 
=item try  ./test.pl demo.ov2 in 'eg' directory

=back

=head1 AUTHOR

Eric GERMAN, E<lt>germanlinux@yahoo.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Eric German

    This package is under the GNU General Public License, Version 2.
      
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
