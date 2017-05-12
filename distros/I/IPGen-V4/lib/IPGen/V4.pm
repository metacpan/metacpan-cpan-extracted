package IPGen::V4;
use 5.005;
use strict;
require Exporter;
use AutoLoader qw(AUTOLOAD);
use vars qw($VERSION @ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw( ipgen );
$VERSION = '1.1';
sub new{
	my $self = bless {}, shift;
	$self->{range} = shift;
	$self;
}
sub ipgen{
	my($range);
	$range = ref($_[0])?$_[0]->{range}:$_[0];
	if($range =~ /^((\d{1,3}\.){3}\d{1,3})\/(\d{1,2})$/)	#ipv4/block
	{
		my $from = oct("0b".substr(join("",map substr(unpack("B32",pack("N",$_)),-8),split(/\./,$1)),0,$3)."0"x(32-$3));
		join '.', unpack 'C4', pack 'N', $from + int rand (oct("0b".substr(join("",map substr(unpack("B32",pack("N",$_)),-8),split(/\./,$1)),0,$3)."1"x(32-$3)) - $from);
	}elsif($range =~ /^((\d{1,3}\.){3}\d{1,3})-((\d{1,3}\.){3}\d{1,3})$/)	#ipv4-ipv4(full-range)
	{
		my $from = (unpack N => pack CCCC => split /\./ => $1);
		join '.', unpack 'C4', pack 'N', $from + int rand ((unpack N => pack CCCC => split /\./ => $3) - $from);
	}elsif($range =~ /^(\d{1,3})-?(\d{1,3})?\.(\d{1,3})-?(\d{1,3})?\.(\d{1,3})-?(\d{1,3})?\.(\d{1,3})-?(\d{1,3})?$/)	#byte1.1-byte1.2...(sub-range)
	{
		($1+int rand abs $2-$1+1).'.'.($3+int rand abs $4-$3+1).'.'.($5+int rand abs $6-$5+1).'.'.($7+int rand abs $8-$7+1);
	}elsif(!length $range){
		join '.', unpack 'C4', pack 'N',int rand 42949672951; # = 255.255.255.255
	}
}

1;
__END__
=head1 NAME

IPGen::V4 - Perl extension for -Fast- random IP address generating 

=head1 SYNOPSIS

  use IPGen::V4;
  #Functional
  print ipgen("4.2.2.4/25");	#cidr
  print ipgen("4.2.2.4-5.5.5.5");	#from-to range
  print ipgen("4-43.2.2-20.4-8");	#sub-range	
  #OO
  $ig = new IPGen::V4("4.2.2.4/25");
  print $ig->ipgen()."\n" for 1..300;

=head1 DESCRIPTION

The main purpose of the IPGen::V4 module is providing fun and easy way to generate random v4 ip addresses by CIDR,Full range (from - to) and subrange.

=head2 EXPORT

ipgen($RANGE)

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/IPv4>

=head1 AUTHOR

Sadegh Ahmadzadegan (sadegh@cpan.org)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Sadegh Ahmadzadegan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
