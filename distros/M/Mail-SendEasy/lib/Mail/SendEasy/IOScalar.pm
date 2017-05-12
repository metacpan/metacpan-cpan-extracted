#############################################################################
## Name:        IOScalar.pm
## Purpose:     Mail::SendEasy::IOScalar
## Author:      Graciliano M. P.
## Modified by:
## Created:     25/5/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Mail::SendEasy::IOScalar ;

use strict qw(vars) ;

use vars qw($VERSION @ISA) ;
our $VERSION = '0.01' ;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto ;
  my $sref = shift ;
  my $self = bless \do { local *FH }, $class ;
  tie *$self, $class, $self ;
  if (!defined $sref) { my $s ; $sref = \$s ;}
  *$self->{Pos} = 0;
  *$self->{SR}  = $sref;
  $self;
}

sub print {
  my $self = shift;
  *$self->{Pos} = length(${*$self->{SR}} .= join('', @_));
  1;
}

sub write {
  my $self = $_[0];
  my $n    = $_[2];
  my $off  = $_[3] || 0;
  my $data = substr($_[1], $off, $n);
  $n = length($data);
  $self->print($data);
  return $n;
}

sub eof {
  my $self = shift;
  (*$self->{Pos} >= length(${*$self->{SR}}));
}

sub seek {
  my ($self, $pos, $whence) = @_;
  my $eofpos = length(${*$self->{SR}});
  if    ($whence == 0) { *$self->{Pos} = $pos }             ### SEEK_SET
  elsif ($whence == 1) { *$self->{Pos} += $pos }            ### SEEK_CUR
  elsif ($whence == 2) { *$self->{Pos} = $eofpos + $pos}    ### SEEK_END
  if (*$self->{Pos} < 0)       { *$self->{Pos} = 0 }
  if (*$self->{Pos} > $eofpos) { *$self->{Pos} = $eofpos }
  1;
}

sub tell { *{shift()}->{Pos} }

sub close { my $self = shift ;  %{*$self} = () ;  1 ;}

sub syswrite { shift->write(@_) ;}
sub sysseek { shift->seek (@_) ;}

sub flush {} 
sub autoflush {}
sub binmode {}

sub DESTROY { shift->close ;}

sub TIEHANDLE {
  ((defined($_[1]) && UNIVERSAL::isa($_[1],'Mail::SendEasy::IOScalar')) ? $_[1] : shift->new(@_)) ;
}

sub PRINT     { shift->print(@_) }
sub PRINTF    { shift->print(sprintf(shift, @_)) }
sub WRITE     { shift->write(@_); }
sub CLOSE     { shift->close(@_); }
sub SEEK      { shift->seek(@_); }
sub TELL      { shift->tell(@_); }
sub EOF       { shift->eof(@_); }

#######
# END #
#######

1;


