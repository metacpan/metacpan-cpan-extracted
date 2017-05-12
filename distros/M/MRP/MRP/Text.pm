package MRP::Text;

use strict;

use vars qw($VERSION);

$VERSION = 1.0;

sub pretyArray {
  my $thingy = shift;
  my $array;
  my $text;

  if(@_==1 && "$_[0]" =~ /ARRAY/) {
    $array = shift;
  } else {
    $array = [@_];
  }

  $text = join ', ', @$array;
  return '('.$text.')';
}

sub pretyHash {
  my $thingy = shift;
  my $leader = shift;
  my $hash;
  my $text = "";
  my ($key,$val);
  
  if(@_==1 && (ref $_[0] eq 'HASH' or "$_[0]" =~/HASH/)) {
    $hash = shift;
  } else {
    $hash = {@_};
  }
  
  while( ($key,$val) = each %$hash) {
    $text .= "$leader$key\t=> $val,\n";
  }
  
  return $text;
}

$VERSION;

__END__

=head1 NAME

MRP::Text - some text utilities

=head1 DESCRIPTION

Provides a small number of text manipulating methods that I use all
the time. They are invoked as MRP::Text->func.

=head1 SYNOPSIS

print "got ", MRP::Text->pretyArray(@someList), "\n";

=head1 Functions

=over

=item pretyArray

use:

  print MRP::Text->pretyArray(qw(pig dog cat)); # prints out (pig, dog, cat)
  print MRP::Text->pretyArray($arrayRef); # prety-prints the contence of the array ref

=item pretyHash

use:

  print MRP::Text->pretyHash($leader, $hashRef);
  print MRP::Text->pretyHash($leader, %hash);

leader is printed before each key/value pair.

=back

=head1 AUTHOR

Matthew Pocock mrp@sanger.ac.uk
