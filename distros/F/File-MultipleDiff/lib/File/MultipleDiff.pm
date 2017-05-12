package File::MultipleDiff;

use 5.006;
use strict;
use warnings FATAL => 'all';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(multiple_file_diff);

use Carp ;
our $VERSION = '0.06';

use Algorithm::Diff "sdiff";
use Tie::File ;
use Term::ANSIColor;
use Cwd;

##---------------------------------------------------------------------------##
##  Compares 2 files and finds out amount of differences between them        ##
##---------------------------------------------------------------------------##
sub _CompareFiles
{
   my ($file_A, $file_B) = @_ ;

   tie my @A, 'Tie::File', "$file_A"  or die "Can't tie $file_A: $!";
   tie my @B, 'Tie::File', "$file_B"  or die "Can't tie $file_B: $!";

#  printf "CompareFiles: %-12s  %-12s : %3d  %3d\n", $file_A, $file_B, ($#A + 1), ($#B + 1) ;
   my @sdiffs = sdiff( \@A, \@B );

   my $diff_counter = 0;
   my $aref ;

   for $aref (@sdiffs)
   {
      if ($aref->[0] ne 'u')
      {
#        printf "%-2s | %-40s | %-40s | %3d\n", $aref->[0], $aref->[1], $aref->[2], $diff_counter ;
         $diff_counter ++ ;
      }
   }
   untie @A;
   untie @B;

   return $diff_counter ;
}  #  end of "sub _CompareFiles"


##---------------------------------------------------------------------------##
sub multiple_file_diff
{
   my ($directory, $file_pattern, $colour, $digits) = @_;
   my $File_A;
   my $File_B;
   my $file         ;
   my %file         ;
   my $count        ;
   my $title        ;
   my $title_length ;
   my $field        ;
   my $header       ;
   my $name_length  ;
   my $max_length =0;

   my $bold_red   = qq(<b><font color="#FF0000">) ;
   my $blue       = qq(<font color="#0000FF">) ;
   my $bold_blue  = qq(<b><font color="#0000FF">) ;
   my $bold_green = qq(<b><font color="#00FF00">) ;
   my $color_over      = "</font>"     ;
   my $bold_color_over = "</font></b>" ;

   unless ((defined $file_pattern) && $file_pattern) { $file_pattern = '.'; }

   unless ((defined $colour) && $colour) { $colour = 'b'; }
   if ($colour !~ /^[bc]$/) { croak "ERROR: colour parameter must be either 'c' or 'b' or empty"; }
   if ($colour eq 'b') { $colour = ''; }

   unless ((defined $digits) && $digits) { $digits = 2; }

   my $start_dir = cwd;
   chdir $directory ;
   opendir (my $dh, '.') || croak "ERROR: can't opendir $directory: $!";
   my @files = grep { /$file_pattern/ && -f "./$_" } readdir($dh);
## foreach $file (<*>) { $file{ $file } = 0 ; } 
   closedir $dh;
   for (@files)
   {
      $file{$_} = 0;
      $name_length = length ;
      if ($name_length > $max_length) { $max_length = $name_length; }
   }

   #------------------------------------------------------------------------------
   my %count ;  # HoH

   foreach $File_A (sort keys %file)
   {
      foreach $File_B (sort keys %file)
      {
         if ($File_B ge $File_A)
         {
            $count{$File_A}{$File_B} = &_CompareFiles ($File_A, $File_B) ;
            if (($count{$File_A}{$File_B} >   9) && ($digits <= 2)) { $digits = 3; }
            if (($count{$File_A}{$File_B} >  99) && ($digits <= 3)) { $digits = 4; }
            if (($count{$File_A}{$File_B} > 999) && ($digits <= 4)) { $digits = 5; }
         }
      }
   }
   #------------------------------------------------------------------------------

   my %HoA ;
   foreach (sort keys %file) { $HoA{ $_ } = [ split (//) ] ; } 

   my $cnt = 0;
   while ($cnt < $max_length)
   {
      $title .= " " x $max_length . " |" ;
      foreach (sort keys %file)
      {
         if ( exists $HoA{ $_ }[$cnt] ) {  $title .= sprintf " %${digits}s ", $HoA{ $_ }[$cnt] ; }
         else                           {  $title .= sprintf " %${digits}s ", " " ; }
      }
      unless ($cnt) { $title_length = length $title ; }
      $title .= "\n" ;
      $cnt ++;
   }

   $header  = sprintf "%s\n", "-" x $title_length ;
   $header .= sprintf "%s",         $title        ;
   $header .= sprintf "%s", "-" x $title_length ;
   if ($colour) { print  colored ['bold blue'], "$header\n" ; }
   else { print "$header\n" ; }

   chdir $start_dir;

   #-----------------------------------------------------------------------------------
   foreach $File_A (sort keys %file)
   {
      $field = sprintf "%-${max_length}s | ", $File_A ;
      if ($colour) { print colored ['bold blue'], $field ; }
      else { print $field ; }
      foreach $File_B (sort keys %file)
      {
         if ($File_B ge $File_A)
         {
            $count = $count{$File_A}{$File_B} ;

            $field = sprintf "%${digits}d  ", $count ;

            if ($count)
            {
               if ($colour) { print colored ['bold red'], $field; }
               else { print $field; }
            }
            else
            {
               if ($colour) { print colored ['bold green'], $field; }
               else { print $field ; }
            }
         }
         else
         {
            printf "%${digits}s  ", "-" ;
         }
      }
      print  "\n";
   }
}  # end of "sub multiple_file_diff"
1;

__END__

=head1 NAME

File::MultipleDiff - Compare multiple files

=head1 SYNOPSIS

   use File::MultipleDiff;
   multiple_file_diff ( <input_directory>
                      , <file_names_pattern>
                      , 'c|b'            # c - colour, b - black/white
                      , <max_digits_amount> );

=head1 DESCRIPTION

Compares many files with each other.
Writes comparison results into a symmetric matrix with one row and column
per compared file. Each matrix element reports the number of differences
between the files corresponding to the column and row.

If a directory "inp_directory" contains files "file1", ... "file5" and only these
files, then the command

   multiple_file_diff ('inp_directory');

produces following output matrix:

   ---------------------------
         |  f   f   f   f   f 
         |  i   i   i   i   i 
         |  l   l   l   l   l 
         |  e   e   e   e   e 
         |  1   2   3   4   5 
   ---------------------------
   file1 |  0   1   2   0   3  
   file2 |  -   0   3   1   4  
   file3 |  -   -   0   2   5  
   file4 |  -   -   -   0   3  
   file5 |  -   -   -   -   0  
 
The entries of the matrix report the number of lines which differ between 
the two files. Thus, file1 and file4 are identical, while file2 and file5
have 4 differences.

Comparison of 2 objects is a commutative operation:
its result does not depend on the order of operands.
C<That means, if A is equal to B, than B is equal to A,
            if A is not equal to B, that B is not equal to A.
Thus the matrix is symmetric. See http://en.wikipedia.org/wiki/Symmetric_matrix.>

For performance's sake a half of the matrix will be filled in.

Example:

   fileA        fileB
   -----        -----
   line1        line1
   line2        line3
   line3        line4
   line4        line5

Perl module Algorithm::Diff is used for file comparison.
This module minimizes amount of differences and for the example above
it detects 2 (not 3) differences between these files:

   fileA        fileB
   -----        -----
   line1        line1
   line2                 1st difference
   line3        line3
   line4        line4
                line5    2nd difference

A basis of this minimization is the longest common subsequence (LCS) method,
that is implemented in that module.

=head2 Remark for more curious

Have you noticed the catch above? The number of differences between two files
is strictly speaking not commutative when Algorithm::Diff is used. Nevertheless
I've decided to create a triangular matrix, as if a full matrix were indeed
a symmetric matrix. This is acceptable for the implementation of this module
as a "chaosmeter". Assume that you expect some configuration files on many
computers to be identical and you want to check this. Hopefully most of them
will be identical, but some of them are different. Zeroes in the matrix mean
identical files and the identity check is indeed a commutative operation.
Non-zeroes matrix elements mean the file contents differ and a level of chaos.
The larger the matrix element, the larger distance between two files. 

A known from mathematics metric or distance function is similar with a conversion,
made by Algorithm::Diff.
Absent commutativity is known as quasimetric.
Quote from http://en.wikipedia.org/wiki/Metric_(mathematics)#Quasimetrics
"Quasimetrics are common in real life. ...
Example is a taxicab geometry topology having one-way streets, where a path from
point A to point B comprises a different set of streets than a path from B to A."

=head1 EXPORT

   multiple_file_diff

=head1 SUBROUTINES

=head2 multiple_file_diff

   multiple_file_diff (
       <input_directory>      # Directory, that contains all compared files;

     , <file_name_pattern>    # Regular expression, optional parameter,
                              # default value - all files in the input directory;
                             
     , 'c|b'                  # Refers to output of comparison, optional.
                              # c - colour, b - black/white output (b is default).
                              # Prerequisite for usage of colour mode is that
                              # terminal supports ANSI escape sequences.
                              # More about is here
                              # http://search.cpan.org/~rra/Term-ANSIColor-4.02/ANSIColor.pm ;

     , <max_digits_amount> ); # Max amount of digits in amounts of differences.
                              # Optional parameter, default value is 2.
                              # This parameter is self expandable and supports
                              # amount of differences until 9999.
                              # You can ignore the last parameter.

Only 1st parameter of this subroutine must be specified.
Undefined or empty further parameters will be replaces by default values.

=head1 AUTHOR

Mart E. Rivilis,  rivilism@cpan.org 

=head1 BUGS

Please report any bugs or feature requests to bug-file-multiplediff@rt.cpan.org,
or through the web interface at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-MultipleDiff.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

   perldoc File::MultipleDiff

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

 http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-MultipleDiff

=item * AnnoCPAN: Annotated CPAN documentation

 http://annocpan.org/dist/File-MultipleDiff

=item * CPAN Ratings

 http://cpanratings.perl.org/d/File-MultipleDiff

=item * Search CPAN

 http://search.cpan.org/dist/File-MultipleDiff/

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Mart E. Rivilis.
This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0).

=cut
