package Fortran::Namelist;

our $VERSION = '0.10';

use Carp;
use Scalar::Util qw(looks_like_number);

our @nml_groups=();

sub new {
   my $class = shift;
   my %opt  = @_;
   my $self = {};
   $self->{nml} = {};
   $self->{groups} = []; 
   bless $self,$class;
   return $self->init(%opt);
}

sub init {
  my $self = shift;
  my %opt = (
     file => '',
     fh   => '',
     nml  => '',
     @_,
  );
  if ( $opt{nml} && ref $opt{nml} eq 'HASH' ) {
      $self->set( %{$opt{nml}} );
  }
  if ( $opt{file} || $opt{fh} ) {
      $self->load( %opt ) or croak "Error loading namelist\n";
  }
  return $self 
}

sub nml {
   my $self      = shift;
   my $grp_name  = shift ||'';
   my $var_name  = shift ||''; 
   ( $grp_name ) =  grep { lc $grp_name eq lc $_  } %{$self->{nml}};
   ( $var_name ) =  grep { lc $var_name eq lc $_  } %{$self->{nml}{$grp_name}};
   my $nml = $grp_name &&   $var_name ? $self->{nml}{$grp_name}{$var_name} :
             $grp_name && ! $var_name ? $self->{nml}{$grp_name}            :
                                        $self->{nml};
   return $nml
}
sub set {
   my $self = shift;
   my %opt = (
      @_,
   );
   if ( ! keys %opt  ) {
      return;
   }
   my $new = $self->read_group(%opt);
   my %seen; 
   my @grp_names = keys %{$self->{nml}};
   my (%hg,%hv,$grp,$gname);
   @hg{ map { lc } @grp_names }= @grp_names;
   foreach my $g ( keys %{$new} ){
      # create the group if doesn't exist
      if ( ! exists $hg{ lc $g } ) {
        $self->new_group( $g ,$new->{$g}); 
        
      }
      else {
        $gname = $hg{ lc $g};
        my $hlines = $self->parse_group($gname);
        my $grp = $self->group($gname);
        my @var_names =  keys %{$self->{nml}{ $gname }};
        @hv{ map { lc } @var_names }= @var_names;
        my $vars = [];
        %seen=();
        foreach my $h (  @$hlines  ) {
           ($vname) = keys %$h;
           my ($v) =  grep { lc $_ eq lc $vname } keys %{$new->{$g}};
           #$self->assign_hvar($gname,$vname,$h);
           #my $vval = $self->{nml}{$gname}{$vname};
           #push @{$vars},@{$self->new_vars($gname,$self->{nml}{$gname} ) };
           if ( $v ) {
             next if $seen{$v}++;
             my $hh = { $vname => {} };
             $hh->{$vname} = $new->{$g}{$v}; 
             $self->assign_hvar($gname,$vname,$hh );
           }
           #next if $seen{$vname}++;
           my ($idx,$val) = $self->unassign($self->{nml}{$gname}{$vname});
           my $j = 0;
           foreach my $i ( @$idx ) {
             my $line =  $self->write_var("$vname$i",$val->[$j++]);
             push @{$vars},$line;
           }
        }     
        foreach my $v ( grep { ! exists $hv{lc $_} } keys %{$new->{$g}} ) {
           my $h = { $v => $new->{$g}{$v} };
           push @$vars, @{$self->new_vars($gname,$h)};
        }     
        $grp->{vars}=$vars;
      }
   } 
   return
}

sub assign_hvar {
  my $self   = shift;
  my $gname  = shift;
  my $vname  = shift;
  my $h      = shift;
  my ($nidx,$nval) = ([],[]);
  ($nidx,$nval) = $self->unassign($h->{$vname});
  my $j=0;
  $self->{nml}{$gname}{$vname} = {} if ! exists $self->{nml}{$gname}{$vname}; 
  foreach my $ni ( @$nidx ) {
      $ni =~ s/^\(//;
      $ni =~ s/\)$//;
      my $ii = [split /,/,$ni];
      $self->assign($self->{nml}{$gname}{$vname},$ii,$nval->[$j++]);
   }
   return $self->{nml}{$gname}{$vname} 
}


sub read_group {
 my $self = shift;
 my %grp = @_;
 foreach my $v ( keys %grp ) {
    $grp{$v}= $self->fix_val( $grp{$v} );
 }
 return \%grp
}

sub fix_val {
   my $self = shift;
   my $val = shift;
   if ( ref ($val) eq 'HASH' ) {
      foreach my $k ( keys %$val ) {
         $val->{$k} = $self->fix_val( $val->{$k} );   
      }     
   }
   elsif ( ref $val eq 'ARRAY' ) {
    foreach my $v ( @$val ) {
       $v = trim($v);
       $v =~ s/^'//;
       $v =~ s/'$//;
       if ( ! looks_like_number($v) ) {
          $v = "'$v'" ;
       }
     }    
   }
   return $val
}
sub print {
    my $self = shift;
    my %opt = (
       group => '',
       file  => '',
       fh    => \*STDOUT,
       @_,
    );
    my $fh = $opt{fh};
    if ( $opt{file} ) {
       $fh = \*FILE;
       open( $fh ,'>', $opt{file} ) or
         croak "couldn't open file: $opt{file} $!\n"
    }
    my $groups = $self->{groups};
    foreach my $g ( @$groups ) {
       if ( exists $g->{comment} ) {
         print $fh "$g->{comment}\n";
         next;
       }
       next if $opt{group} && lc $opt{group} ne lc $g->{name};
       print $fh "$g->{ch_start}$g->{name}\n\n";
       foreach my $v ( @{$g->{vars}} ) {
           print $fh "$v\n";
       } 
       print $fh "\n$g->{ch_end}\n";
    } 
}


sub write_var {
  my $self = shift;
  my $lhs  = shift;
  my $rhs = shift;
  my $nl  = shift || 80;
  my @l;
  my $eq  = trim($lhs) ? '=' : ' ' ;
  $l[0]  = "   $lhs $eq ";
  my $line = '';
  my $lpad = ' 'x(length $l[0]); 
  my $sep = @$rhs > 1 ? ', ': '' ;
  my @r = @$rhs;
  while ( @r ) {
    my $v = shift @r;
    my $lvs=length( "$l[-1]$sep$v$sep");
    if ( @r ) {
       if ( $lvs < $nl ) {
         $l[-1] .= "$v$sep"; 
       }
       else {
         $l[-1] .= "\n"; 
         push @l, "$lpad$v$sep";
       }
    }
    else  {
      if ( $lvs < $nl ) {
        $l[-1].= $v;
      }
      else {
        $l[-1] .= "\n"; 
        push @l, "$lpad$v";
      }
    }
   }
  $line = join '',@l;
  return $line
}

sub load {
  my $self = shift;
  my %opt = (
    fh        => '',
    file      => '',
    nml       => '',
    @_,
  );
  
  $self->{nml} = $opt{nml} && ref $opt{nml} eq 'HASH' ?  $opt{nml} :  {};
  my ($gname,$var,$val,$type,$ch_start,$ch_end);
  my $fh = $opt{fh};
  if ( $opt{file} ) {
   open( $fh ,"<",$opt{file} ) or
     croak "Couldn't open $opt{file} for reading $!\n";
  }
  my $lines=[''];
  my $comment=''; 
  $ch_start='';
  $ch_end='';
  my $l='';
  while ( <$fh> ) {
    $l = $_;
    chomp;
    chomp $l;
    if ( /^(\s*\!.*)$/ ) {
       $comment = $l;
       if ( ! $ch_start ) {
          push @{$self->{groups}},{ comment => $comment };
        }
        else {
          push @{$lines},$comment;
        }
        $comment='';
    }
    s/\!.*$//;
    s/^\s+//;
    s/\s+$//;
    next unless length;
    if ( /(\$|\&)(\w+)(.*)(\$end|\/)/ixmsg  ) { 
         $ch_start = $1;
         $gname =  $2;
         $ch_end = $4; 
         $lines = [ trim($3) ];
         $self->{nml}{$gname}={};
         push @{$self->{groups}},{ name     => $gname, 
                                   ch_start => $ch_start ,
                                   ch_end   => $ch_end,
                                   vars     => $lines,
                                  };
         $lines = [];
         $ch_start='';
         $ch_end='';
         next;
    }

    if ( /(\$end|\/)$/i ) {
      $ch_end = $1; 
      push @{$self->{groups}},{ name     => $gname, 
                                ch_start => $ch_start ,
                                ch_end   => $ch_end,
                                vars     => $lines,
                              };
      #print join "\n",@lines,"\n";
      #if ( ! $opt{nml} || $group eq $opt{nml} ) 
      #$self->parse_group( $group, @lines );
      $ch_start='';
      $ch_end='';
      next;
    }
    if ( /^(\$|\&)([A-Za-z]\w+)( |$)/  ) { 
      $ch_start = $1;
      $gname = $2;
      $self->{nml}{$gname}={};
      #print "$group $_\n";
      $lines = [];
      #$nml->{$group} = [];
      #$nml->{$group}{comment} = [$comment] if $comment;
      #$comment = '';
      next;
    }
    push @$lines,$l;
  }
  my $ok = $ch_start || $ch_end ? 0 : 1;
           
  return $ok
}
sub new_group {
  my $self = shift;
  my $name = shift;
  my $h    = shift  ;
  my $g    = { name     => $name,
               ch_start => '$' ,
               ch_end   => '$end',
               vars     => $self->new_vars($name,$h),
              };
  $self->{nml}{$name}= {} if ! exists $self->{nml}{$name};
  foreach my $v ( keys %$h ) {
     $self->{nml}{$name}{$v}={};
     $self->{nml}{$name}{$v}=$self->assign_hvar($name,$v,$h);
  }
  push @{$self->{groups}},$g;
  return $g 
}
sub new_vars {
   my $self   = shift;
   my $gname  = shift;
   my $h      = shift;
   my ($idx,$val,$j);
   my $vars = [];
   foreach my $var ( keys %{$h} ) {
    ($idx,$val) = $self->unassign($h->{$var});
    $j=0; #print $var,"\n";
    foreach my $i ( @$idx ) {
      my $line =  $self->write_var("$var$i",$val->[$j++]);
      push @{$vars},$line;
    }
  }
  return $vars 
}
sub group {
  my $self = shift;
  my $gname = shift || croak "No group name given!\n";
  my $g = {};
  ($g) = grep { lc $_->{name} eq lc $gname  } @{$self->{groups}};
  if ( ! $g ) {
    carp "Group $gname not found\n";
  }
  return $g 
}
sub group_lines {
  my $self = shift;
  my $gname = shift || croak "No group name given!\n";
  my $var   = shift || '';
  my @lines = ('');
  my $g = $self->group($gname);
  foreach my $l ( @{$g->{vars}} ) {
     chomp $l;
     $l=~ s/\!.*$//;
     if ( $l !~ /=/ ) {
        $lines[-1] .= " $l";
        next;
     }
     else {
        push @lines,$l;
     }
  }
  return \@lines  
}


sub parse_group {
   my $self = shift;
   my $gname = shift;
   my $vname = shift || '';
   my $group_lines = $self->group_lines($gname);
   my $group = $self->group($gname);
   my $vars = [];  
   my $vlines =[];
   my $comment = '';
   foreach my $l (  @$group_lines ) {
      #print "$l\n";
      if ( $l !~ /^\s*\!/ ) {
        my $hl = $self->parse_vars($gname,$l);
        #foreach my $h ( @$hl ) {
        #   my ($vname) = keys %$h;
        #   $self->assign_hvar($gname,$vname,$h);
        #   push @$vars,@{$self->new_vars($gname,$h) };
        #}
        push @$vlines,@$hl;
      }
      else {
        push @$vars,$l;
      }
   }
   $group->{vars} = $vars;
   return $vlines;
}


sub parse_vars {
  my $self = shift;
  my $gname  = shift;
  my $line  = shift;
  my $v=[];
                      # [A-Za-z_0-9\(\),\s\#\-\:]+ 
                      #    \( [\s0-9\.DdEe\-\+]+ , [\s0-9\.DdEe\-\+]+ \)
  while ( $line =~ / (  
                       [A-Za-z_0-9]+
                       (\s*| 
                        \( \s*
                           (  
                             \s*\d\s*(,|\s*|) 
                           )+ 
                         \s* \) 
                       )\s*  
                       =
                       (
                         (\s*\d+\s*\*|)
                         (
                                \s*\'.*\'\s*            |
                           [\s\-\+A-Za-z_0-9\.'\:,]+    |
                           \s*\(
                             [\s0-9\.DdEeIi\-\+]+ 
                             \s*,\s* 
                             [\s0-9\.DdEeIi\-\+]+ 
                           \)\s*
                         )
                         (,|,\s*|$)  
                         |  
                       )+
                       
                     )+                   
                  /xmsg ) {
     #print "line  : $line\n"; 
     ($var,$val) = split /=/,$1;
     #print "parsing  $var = $val\n";
     my $index=[];
     ($var,$index) = $self->var_index($var);
     my @i= @$index;
      
     #print "index = @$index\n";
     $val = trim($val);
     $val = $self->parse_val($val,$var);
     my $h = { $var => {} };
     if ( ! exists $self->{nml}{$gname}{$var} )  {
       $self->{nml}{$gname}{$var} = {};
     }
     $self->assign($self->{nml}{$gname}{$var},$index,$val);
     $self->assign($h->{$var},$index,$val);
     #$h->{$var} = $self->{nml}{$gname}{$var};
     #print "$var@{$index}=  @{$h->{$var}} \n";
     #print "var $var @{$i} = @{$val}\n";
     push @$v , $h;
  }
  return $v 
}
sub unassign {
   my $self = shift;
   my $h = shift;
   my $index  = shift || [''];
   my $idx = shift || [];
   my $vals = shift || [];
   my $v = '';
   my $l = [];
   my @k = ref $h eq 'HASH' ? sort { $a <=> $b } keys %$h : ();
   #print "keys @k\n";
   #print "$index->[-1]\n";
   if ( @k ) {
     my $ii = $index->[-1];
     my $i=$k[0];
     while ( @k ) {
       $i=shift @k;
       push @{$index},$ii ;
       $index->[-1] .= " $i";
       #print "$index->[-1]\n";
       #push @$vals,$h->{$i} if ref $h->{$i} eq 'ARRAY';
       $self->unassign($h->{$i},$index,$idx,$vals);
     }
   }
   else {
     my @ii =  split ' ',$index->[-1];
     my $j = (join ',', @ii) || '';
     $index->[-1] = $j ? "($j)" : '';
     push @$idx,$index->[-1];
     push @$vals,$h;
   }

   return ($idx,$vals)
}

sub assign {
  my $self = shift;
  my $h = shift;
  my $index = shift;
  my $val   = shift;
  if ( @$index ) {
     my $i = shift @$index;
     $h->{$i}= ! @$index       ? $val     :
               exists $h->{$i} ? $h->{$i} :
                                 {}       ;
     $self->assign( $h->{$i},$index,$val );
  }
  elsif ( ref $h eq 'HASH' ) {
    my ($i) = keys %$h;
    $h->{$i}=$val;
  }
  else {
    $h = $val;
  }

  return $h
}

sub var_index {
   my $self = shift;
   my $var = shift;
   $var =~ s/\s+//g;
   my $index = [];
   if ( $var =~ s/(
                   \(.*\)       # match indexes between parenthesis
                  )
                  (|            # nothing or,
                   \(\d*:\d*\)  # substring indexes, but we will not use them
                                # for now
                  )
                 //x ) {
      my $i= $1;
      $i  =~ s/(\(|\))//g; 
      $index = [ split /,/,$i ];
      #print "index @{$index}\n"; 
   }
   #$index =~ s/\s+//g if $index ;
   return (trim($var),$index);
}

sub parse_val {
   my $self = shift;
   my $val = shift;
   my $var = shift ||'';
   my $values = [];
   my $all = $val ;
   my $ok = 1;
   return  [$val]  if $val =~ /\.(true|false)\./i ;
   while ( $val =~ / (\s*,\s*|\s*)               # match starting null value   
                     ((\s*\d+\s*)\*|)            # match multiplier 
                     (                           # begin matching values
                       \s*\'.*?\'\s*           | #  quoted string
                         [DdEe_0-9\.\-\+\:]+   | #  numeric variable
                      \s*\(                      #  start complex number
                           [\s0-9\.DdEeIi\-\+]+  #    real part
                           \s* , \s*             #    comma  
                           [\s0-9\.DdEeIi\-\+]+  #    imaginary part
                         \)\s*                |  #  end complex  number 
                         \s*,\s*                 #  separator        
                     )                           # end matching values
                     (                           # begin separators:
                       \s*,\s* |                 #   match null value ',,'
                       \s*     |                 #   blanks spaces,tabs,etc
                       $                         #   end of string or new line
                     )                           # end separators
                  /xmsg ) {
      my $nv  = $1;
      my $ntimes = $2;
      my $n = $3 || 1;
      my $c = $4 ;
      my $sep = $5;
      my $pv = $c;
      $nv = trim($nv);
      push @$values,$nv if $nv;
     
      #$c = ! looks_like_number($c) ? "'$c'" : $c;
      #print "! sep= |$sep| bnv = |$nv| rep = |$n| |$ntimes| ";
      #print "! parsing : $var = |$c|\n";
      $pv =~ s/(\+|\(|\)|\.)/\\$1/g;
      $ntimes =~ s/(\*)/\\$1/g;
      $all =~ s/($nv$ntimes$pv$sep)?//;
      $ok = ! $sep && $c eq ',' ?  0 : 1;
      #push @$values,split(/,/,$c);
      push @$values,(trim($c))x($n) if $ok ;
      #my $vv = [ split /$sep/,$val ];
      #foreach my $c ( @$vv ) {
      #   print "var $var| val $val|c $c \n";
      #}
  }
  if ( trim($all) ) { print "left overs |$all|\n";}
  #print "@$values ",scalar @$values,"\n";
  #return scalar @$values > 1 ? $values : $values->[0];
  return $values 
}

sub trim {
  my $s = shift;
  $s =~ s/^\s+//;
  $s =~ s/\s+$//;
  return $s
}
1;

__END__

=head1 NAME

Fortran::Namelist - Perl extension for Fortran namelists 

=head1 SYNOPSIS

use Fortran::Namelist;

my $nml_file = '/home/user/my_namelist.nml';

my $nml=Fortran::Namelist->new( file => $nml_file );


my %new_group = ( group_name => { grp_var1 => 'some_string',
                                  grp_var2 => [ 1 , 2 , 3 ],
                                }
                );

 $nml->set( %group );

 $nml->print( file => 'another_file.nml' );

=head1 DESCRIPTION

Namelist implements a basic handling of standard fortan namelists.
Namelist files are ascii files that allow a fortran program to transfer 
a group of variables by referencing the name of the group which they belong.
Example of a namelist file:

$group_name
  
  vec(2) = 3, 4, 5
 
  c      = 'abc'
  
  i  = 3
  
$end


A namelist record starts with the name of the group preceded by '$' or by '&',
followed by a sequence of variables-values with the appropriate value
separators ( blanks,tabs,newlines, or any of them with a single comma).
the end of the group is indicated by '$end' or by '/'.

=head1 NOTES

The goal of this module is to allow an easier handling of namelist files
before they are used by a fortran program. Although creating a namelist file
from scratch is an easy task in perl, once a file already exists, modifying a 
variable in it, is likely to end up in with a code that at least it is not
reusable, may not be clean and also may fail in some cases due to the
flexibility that fortran provides to write namelist files.
(FORTRAN Namelist-directed I/O is like list directed I/O, i.e using *,instead of
fmt='(...)' in the format statement). 

This module is not a parser ( but almost ), and it may fail in some cases,
however when the namelist file is 'fortran-readable' will handle it correctly
and I had no problems so far.

=head1 METHODS

=head1 B<new>  I<new(%hash)> 

Creates a new namelist object.

my $nml=Fortran::Namelist->new();

Create a namelist object from the file 'myfile.nml'. 

my $nml=Fortran::Namelist->new( file => 'myfile.nml');

=head1 B<set>  I<set(%hash)> 

Its argument is a hash. The keys are the name of the groups to be set. 
The values of the hash are anonymous hashes and its keys are the name of the 
variables in the group.
The values of this anonymous hashes can be: strings, reference to arrays,
or references to anonymous hashes. Strings and references to arrays are used to provide one or multiple values depending on the variable.
References to hashes are used to represent array indexes of variables that
could be multidimensional.
Example:

my $nml= Fortran::Namelist->new( file => 'my_file.nml');

# create groups using  a new hash

my %groups=(  group_a => { str_var => 'abcd efg',
                          arr_var => [ 1, 2 , 4],
                        },
             group_b => { vec_var => { 1 => [ 4,5,6]  },
                          mat_var => { 1 => { 1 => [ 7,8,9 ] } },
                         },
           );
           
# a better way to define group_a and group_b

$groups{group_a}{str_var} = 'abcd efg';

$groups{group_a}{arr_var} = [1, 2, 4];

$groups{group_b}{vec_var}{1} = [4,5,6];

$groups{group_b}{mat_var}{1}{1} = [7,8,9];

$nml->set(%groups);

$nml->print();

# end

#prints

$group_a
  
  str_var='abcd efg'
  arr_var= 1, 2, 3
  
$end

$group_b
  
  vec_var(1)= 4, 5, 6
  mat_var(1,1) = 7, 8, 9

$end


=head1 B<print>  I<print(%hash)> 

Prints the namelist to a file or file-handle, default file-handle is STDOUT.

$nml->print();

$nml->print( file => 'output.nml');

open( my $fh , "> nml_out.nml") or die "$!\n";

$nml->print( fh => $fh );


=head1 VERSION

0.10

=head1 SEE ALSO

Fortran::F90Format


=head1 AUTHOR

Victor Marcelo Santillan E<lt>vms@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2006 Victor Marcelo Santillan. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut






