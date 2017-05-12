package Lingua::EN::NameParse::Simple;

use warnings;
use strict;
use DBI; 
use DB_File; 
use Fcntl ':flock'; 
use locale;  

=head1 NAME

Lingua::EN::NameParse::Simple - Parse an English name into component parts 

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 SYNOPSIS

Invoke this package as follows:  

	use Lingua::EN::NameParse::Simple;
	my %name = Lingua::EN::NameParse::Simple::ParseName($fullname); 
    
	# %name will contain available values for these keys:  
	# TITLE, FIRST, MIDDLE, LAST, SUFFIX

    # unless the FIRST and LAST keys are populated
    # or if digits are found in a key other than SUFFIX, 
    # an ERROR key is returned instead.

    unless( defined( $name{'ERROR'} )){
        print Dumper( \%name );
    }

=head1 FUNCTIONS

=head2 ParseName 

my %name = Lingua::EN::NameParse::Simple::ParseName($fullname); 

returns values for these keys:
TITLE, FIRST, MIDDLE, LAST, SUFFIX

=cut

sub ParseName {
  my(@returnarray,$namearraysize,$i,$j); 
  my(@namearray,$fullname,@validtitle,@validsuffix); 
  my($titlematch,%name);
  my($nameelement,$tmp,$lnamematch,$mnamematch); 
  my($fnamematch,,$suffixmatch,$tmpelement);
  $fullname=$_[0];
  @namearray=split(/\s+/,$fullname);
  @validtitle = ('MR', 'MS', 'MRS', 'MISS', 'MISTER', 'DR', 'DOCTOR', 'REV', 'REVEREND', 'PASTOR', 'HONORABLE'); 
  @validsuffix = ('SR', 'SENIOR', 'JR', 'JUNIOR', 'II', 'III', 'IV');  
  $namearraysize=@namearray; # Number of items in array
  $i=0; # Keep track of name element
  $titlematch=0; 
  $lnamematch=0; 
  $mnamematch=0;
  $fnamematch=0; 
  $suffixmatch=0;
  NAMEPARSE:foreach(@namearray) {
    $nameelement=$_;
    if(($i+1) == $namearraysize) {
      # Test to see if last element
      # Either Suffix or Last Name
      foreach(@validsuffix) {
        $tmp=uc($nameelement);
        $tmp=~s/\[,.]//g;
        $tmp=~s/\,//g;
        $tmp=~s/\.//g;
        if($tmp eq $_) {
          # Suffix detected
          $returnarray[$i][0]="SUFFIX";
          $nameelement=~s/\[,.]//g;
          $returnarray[$i][1]=$nameelement;
          $suffixmatch++;
          if($lnamematch == 0 && $returnarray[$i-1][0] eq "MIDDLE") {
            # If no last name has been found then next to last element
            # that is a middle name becomes the last name
            $returnarray[$i-1][0] = "LAST";
          }
          $i++;
          next NAMEPARSE;
        }
      }
      if($lnamematch == 0) {
        # Since Suffix is not found and lastname not found
        # must be a last name
        $returnarray[$i][0]="LAST";
        $nameelement=~s/\.//g;
        $nameelement=~s/\,//g;
        $returnarray[$i][1]=$nameelement;
        $lnamematch++;
        $i++;
        next NAMEPARSE;
      } else {
        # Must be a middle name
        $returnarray[$i][0]="MIDDLE";
        $nameelement=~s/\[,.]//g;
        $returnarray[$i][1]=$nameelement;
        $mnamematch=1;
        $i++;
        next NAMEPARSE;
      }
    } elsif(($i+2) == $namearraysize) {
      # Test to see if second to last element
      # See if element is part of the first 3
      if($i < 3) {
        # Part of first 3 crucial elements
        if($i == 0) {
          # Two element array, first element
          # Check to see if title
          VALIDTITLE:foreach(@validtitle) {
            # See if there is a title match
            $tmp=uc($nameelement);
            $tmp=~s/\[.,]//g;
            $tmp=~s/\,//g;
            $tmp=~s/\.//g;
            # print "$tmp vs $_ test var\n"; 
            if($tmp eq $_) {
              # Match!
              $returnarray[$i][0]="TITLE";
              $returnarray[$i][1]=$nameelement;
              $titlematch++;
              $i++;
              next NAMEPARSE;
            }
          }
          if(substr($nameelement,length($nameelement)-1,1) eq ",") {
            # Check to see if last name
            $returnarray[$i][0]="LAST";
            $returnarray[$i][1]=$nameelement;
            $lnamematch++;
            $i++;
            next NAMEPARSE;
          } else {
            # Otherwise, must be a first name
            $returnarray[$i][0]="FIRST";
            $returnarray[$i][1]=$nameelement;
            $fnamematch++;
            $i++;
            next NAMEPARSE;
          }
        } elsif($i == 1) {
          # Three element array, second element
          if($returnarray[$i-1][0] eq "TITLE" || $returnarray[$i-1][0] eq "LAST") {
            # Must be a first name
            $returnarray[$i][0]="FIRST";
            $nameelement=~s/\,//g;
            $nameelement=~s/\.//g;
            $returnarray[$i][1]=$nameelement;
            $fnamematch=1;
            $i++;
            next NAMEPARSE;
          } elsif($returnarray[$i-1][0] eq "FIRST") {
            # Must be a middle name
            $returnarray[$i][0]="MIDDLE";
            $nameelement=~s/\,//g;
            $nameelement=~s/\.//g;
            $returnarray[$i][1]=$nameelement;
            $mnamematch=1;
            $i++;
            next NAMEPARSE;
          }
        } elsif($i == 2) {
          # Four element array, third element
          # Must be a middle or a last name but must set to middle until last element is detected
          $returnarray[$i][0]="MIDDLE";
          $nameelement=~s/\,//g;
          $nameelement=~s/\.//g;
          $returnarray[$i][1]=$nameelement;
          $mnamematch=1;
          $i++;
          next NAMEPARSE;
        }
      } else {
        # Must be a middle (or last name but won't know that
        # until we check the last element so set to middle name)
        $returnarray[$i][0]="MIDDLE";
        $nameelement=~s/\,//g;
        $nameelement=~s/\.//g;
        $returnarray[$i][1]=$nameelement;
        $mnamematch=1;
        $i++;
        next NAMEPARSE;
      }
    } elsif($i > 2 && ($i+2) < $namearraysize) {
      # All elements after the 3rd and before 2nd to last
      $returnarray[$i][0]="MIDDLE";
      $nameelement=~s/\,//g;
      $nameelement=~s/\.//g;
      $returnarray[$i][1]=$nameelement;
      $mnamematch=1;
      $i++;
      next NAMEPARSE;
    } elsif($i == 0) {
      # Test to see if first element
      # Test to see if this is a title
      VALIDTITLE:foreach(@validtitle) {
        # See if there is a title match
        $tmp=uc($nameelement);
        $tmp=~s/\[.,]//g;
        $tmp=~s/\,//g;
        $tmp=~s/\.//g;
        # print "$tmp vs $_ test var\n"; 
        if($tmp eq $_) {
          # Match!
          $returnarray[$i][0]="TITLE";
          $returnarray[$i][1]=$nameelement;
          $titlematch++;
          $i++;
          next NAMEPARSE;
        }
      }
      if(substr($nameelement,length($nameelement)-1,1) eq ",") {
        # Detected a last name
        $returnarray[$i][0]="LAST";
        $nameelement=~s/\,//g;
        $nameelement=~s/\.//g;
        $returnarray[$i][1]=$nameelement;
        $i++;
        $lnamematch++;
        next NAMEPARSE;
      } else {
        # If all else fails, must be first name
        $returnarray[$i][0]="FIRST";
        $nameelement=~s/\,//g;
        $nameelement=~s/\.//g;
        $returnarray[$i][1]=$nameelement;
        $i++;
        $fnamematch++;
        next NAMEPARSE;
      }
    } elsif($i == 1) {
      # Test to see if second element
      if($returnarray[$i-1][0] eq "TITLE" || $returnarray[$i-1][0] eq "LAST") {
        # First Name
        $returnarray[$i][0]="FIRST";
        $nameelement=~s/\,//g;
        $nameelement=~s/\.//g;
        $returnarray[$i][1]=$nameelement;
        $i++;
        $fnamematch++;
        next NAMEPARSE;
      } else {
        # Middle Name
        $returnarray[$i][0]="MIDDLE";
        $nameelement=~s/\,//g;
        $nameelement=~s/\.//g;
        $returnarray[$i][1]=$nameelement;
        $i++;
        $mnamematch++;
        next NAMEPARSE;
      }
    } elsif($i == 2) {
      # Test to see if third element
      # Must be middle if there since there are more than one elements after this
      # Middle Name
      $returnarray[$i][0]="MIDDLE";
      $nameelement=~s/\,//g;
      $nameelement=~s/\.//g;
      $returnarray[$i][1]=$nameelement;
      $i++;
      $mnamematch++;
      next NAMEPARSE;
    }
  }
  foreach $j (0...(scalar(@returnarray)-1)) { 
    $name{$returnarray[$j][0]} = $returnarray[$j][1]; 
  } 
  foreach my $key ('TITLE','FIRST','MIDDLE','LAST'){
    if( defined( $name{$key} ) && $name{$key} =~ m/[0-9]/){
      $name{'ERROR'} = 'We do not expect to see digits in a person\'s name';
    }
  }
  unless( defined($name{'LAST'}) && defined($name{'FIRST'}) ){
    $name{'ERROR'} = 'Does not appear to be a person\'s name conforming to traditional English format';
  }
  if( defined( $name{'ERROR'} )){
    foreach my $key ('TITLE','FIRST','MIDDLE','LAST','SUFFIX'){ delete $name{$key}; }
  }
  return (%name);
} # End ParseName

=head1 AUTHOR

Hugh Esco, C<< <hesco at campaignfoundations.com> >> and James Jones

=head1 BUGS

Please report any bugs or feature requests
to C<bug-lingua-en-nameparse-simple at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-EN-NameParse-Simple>.
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::EN::NameParse::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-EN-NameParse-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-EN-NameParse-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-EN-NameParse-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-EN-NameParse-Simple/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright (C) 2004-2012 by Hugh Esco, James Jones and the Georgia Green Party

originally written as: 

parser.pm -- Parses a name into its constituent parts 
Copyright (C) 2004 by Hugh Esco, James Jones and the Georgia Green Party

Original concept and early buggy version by Esco, original
working module refactored by James Jones as parser.pm in 2004.
In 2006 the state Committee of the Georgia Green Party agreed
to release generally useful portions of its code base under
the Gnu Public License.  The test suite was added and the
module renamed and packaged for CPAN distribution by Esco
doing business as CampaignFoundations.com in 2010.  In early 
2012 Esco again extended this module to report an ERROR key 
in certain circumstances.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; version 2 dated
June, 1991 or at your option any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the
source tree; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

1; # End of Lingua::EN::NameParse::Simple

