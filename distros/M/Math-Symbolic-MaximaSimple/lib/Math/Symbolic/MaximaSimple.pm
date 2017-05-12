package Math::Symbolic::MaximaSimple;

use parent qw{Exporter};
our %EXPORT_TAGS=(
  tex => [ qw{ &maxima_tex &maxima_tex1 &maxima_tex2 } ],
  maxima => [ qw{ &maxima &startmaxima } ],
);

our @EXPORT_OK=  map {ref($_) ? (@$_):()}  values %EXPORT_TAGS ;

$EXPORT_TAGS{all}= \@EXPORT_OK;

use warnings;
use strict;
our $VERSION = '0.02';
our $state="stoped";

our $N=333333333333;
use IPC::Open2;

my $pid;
my $R;
my $W;

#INIT {
# startmaxima();
#}

sub startmaxima{
  return if $state eq "started";
  $state = "started";
  $SIG{"INT" }=\&_K;
  $pid = open2($R,$W,"maxima ---very-quiet") || die("can open2 maxima\n");
  print $W 'display2d:false$';
  print $W "\n$N;\n";
  my $a=<$R>;
  while($a !~ /^\(\%o\d+\)\s*$N/){ $a = <$R>;}
}

#while(<>) {
#  chomp;
#  next unless /\S/;
#  print "maxima-- ",maxima($_), "\n";
#  print "maxima tex-- ",maxima_tex($_), "\n";
#  print "maxima tex1-- ",maxima_tex1($_), "\n";
#  print "maxima tex2-- ",maxima_tex2($_), "\n";
#}

sub maxima_tex1{
  startmaxima() unless $state eq "started";
  my $exp=shift;
  print $W "tex1($exp);\n$N;\n";
  my $a=<$R>;
  my $b="";
  while($a !~ /^\(\%o\d+\)\s*$N/){ 
    $b .= $a;
    $a = <$R>;}
  _clean($b);
}

sub maxima_tex2{
  startmaxima() unless $state eq "started";
  my $exp=shift;
  print $W "tex($exp);\n$N;\n";
  #print $W "tex($exp)\$;\n$N;\n";
  my $a=<$R>;
  my $b="";
  while($a !~ /^\(\%o\d+\)\s*$N/){ 
    $b .= $a;
    $a = <$R>;}
  _clean2($b,nomathenv=>1);
}

sub maxima_tex{
  startmaxima() unless $state eq "started";
  my $exp=shift;
  print $W "tex($exp);\n$N;\n";
  #print $W "tex($exp)\$;\n$N;\n";
  my $a=<$R>;
  my $b="";
  while($a !~ /^\(\%o\d+\)\s*$N/){ 
    $b .= $a;
    $a = <$R>;}
  _clean2($b);
}

sub maxima{
  startmaxima() unless $state eq "started";
  my $exp=shift;
  print $W "$exp;\n$N;\n";
  my $a=<$R>;
  my $b="";
  while($a !~ /^\(\%o\d+\)\s*$N/){ $b .= $a;
    $a = <$R>;}
  _clean($b);
}

sub _clean2{my ($b,%a)=@_;
  $b =~ s/\(%i\d+\)\s*//g;
  $b =~ s/\s*$//;
  if($b =~ s/\s*\(\%o\d+\)\s*false\s*//){ 
    $b =~ s/\%e\b/e/g;
    $b =~ s/\%pi\b/\\pi/g;
    if($a{nomathenv}){ $b =~ s/^\$\$(.*)\$\$$/$1/s; 
          $b }
    else{ $b }
  }
  else                               { [$b]}
}

sub _clean{my $b=shift;
  $b =~ s/\(%i\d+\)\s*//g;
  $b =~ s/\s*$//;
  $b =~ s/\%e\b/e/g;
  $b =~ s/\%pi\b/\\pi/g;
  if($b =~ s/\(\%o\d+\)\s*//){ $b  }
  else                       { [$b]}
}

sub _K { ## print STDERR "END (--$state--)\n\n"; 
        kill(9,$pid) if $state eq "started" ; 
        exit 0; 
}

END{ _K();}

1; # End of Math::Symbolic::MaximaSimple

=head1 NAME

Math::Symbolic::MaximaSimple - open2 interface with maxima math system

=head1 VERSION

Version 0.01_4

=head1 SYNOPSIS

    use Math::Symbolic::MaximaSimple qw(:all);

    $e = "x+x+x+x+x**2-4+8"
    maxima_tex($e)            ## $$x^2+4\,x+4$$
    maxima_tex1$e)            ## "x^2+4\\,x+4"
    maxima_tex2($e)           ## x^2+4\,x+4
    maxima_tex2("diff($e,x)") ## 2\,x+4
    maxima("diff($e,x)")      ## 2*x+4

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 startmaxima

star maxima process in beckgrown with Open2.
Not necessary; the other functions call startmaxima if state="stoped";

=head2 maxima_tex

=head2 maxima_tex1

=head2 maxima_tex2

=head2 maxima

=head1 AUTHOR

J.Joao Almeida, C<< <jj at di.uminho.pt> >>

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Project Natura.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.

