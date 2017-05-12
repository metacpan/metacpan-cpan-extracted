package Regexp::Match::Any;

use strict;
use warnings;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

$Regexp::Match::Any::VERSION    = 0.03;
@ISA                            = qw(Exporter);
@EXPORT                         = qw(&match_any);
@EXPORT_OK                      = qw(&match_any);

sub match_any {
  my $ref = shift;
  my $opt = shift || '';
  my $regex = join('|', @{$ref});
  return qq{(?$opt:$regex)};
}
__END__

=head1 NAME

  Regexp::Match::Any - Match many regexes against a variable

 
=head1 CHANGES
  
  Version 0.03: Pass match_any() a second arguement of matching options [NOTE: array reference only]


=head1 SYNOPSIS

  use Regexp::Match::Any;
  my @array = qw(Foo Bar Wibble);
  my $opt = 'i'; #ignore case
  my $var = "foo";
  if($var =~ match_any(\@array,$opt)){
    print "It matched\n";
  }else{
    print "It didn't match\n";
  }


=head1 DESCRIPTION

  This module allows you to pass the match_any() function a reference to an array of regexes which will
  then return a full regex for the the variable to be matched against. Optionally, you can pass it
  matching arguements such as 'g' or 'i'. Pass these in one variable with no spaces.
  Note: I from personal experience have found this module to be very handy for use with Mail::Audit.


=head1 AUTHOR

  Scott McWhirter <scott@kungfuftr.com>


=head1 COPYRIGHT

  Copyright (c) 2001, Scott McWhirter. All Rights Reserved.  This module is
  free software. It may be used, redistributed and/or modified under the
  terms of the Perl Artistic License. 
  ( see http://www.perl.com/perl/misc/Artistic.html )

