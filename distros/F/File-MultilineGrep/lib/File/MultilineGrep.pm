package File::MultilineGrep;

use 5.006;
use strict;
use warnings FATAL => 'all';
use English;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(file_multiline_grep);

use Carp;
our $VERSION = '0.01';

my %group_lines  = () ;  # reset %group_lines
my $line;

#-------------------------------------------------#
sub file_multiline_grep
{
   my ($begin_pattern, $finish_pattern, $middle_pattern, $numeration, $file, $separator) = @_ ;

   my $one_separator_flag = 0; 
   if ($begin_pattern and ! $finish_pattern)
   {
      $finish_pattern = $begin_pattern;
      $one_separator_flag = 1; 
   }

   my $inside_flag  = 0;
   my $match_flag   = 0;
   my $next_line;
   my $FILE;
   if (defined $file) { open ($FILE, "<$file") || die "Error: Can't open file $file: $!"; }
   else { $FILE = *STDIN; }

   MAIN_LOOP: while (1)
   {
      if ($next_line)
      {
         $line = $next_line ;
         $next_line = '';
      }
      else
      {
         $line = <$FILE> ;
         unless ($line)
         {  # found EOF
            $one_separator_flag && $match_flag && &_PrintMatchingGroup($numeration, $match_flag, $separator) ;
            exit 0;
         } 
      }

      if ($inside_flag ) { $group_lines{$.} = $line }
      else
      {
         ($line !~ /$begin_pattern/) && next MAIN_LOOP;

         $inside_flag     = 1 ;
         $group_lines{$.} = $line ;
         $line            = $' ;
      }

      # $inside_flag = 1
      if ( (! $match_flag) && ($line =~ /$middle_pattern/) )
      {
         $match_flag = $.
      }

      if ( $line =~ /$finish_pattern/ )
      {
         $next_line       = $' ;
         $match_flag  &&  &_PrintMatchingGroup($numeration, $match_flag, $separator) ;
         $match_flag  = 0 ;
         %group_lines  = () ;  # reset %group_lines

         unless ($one_separator_flag) { $inside_flag  = 0 }
      }   
   }  #  end of "MAIN_LOOP: while(1)"
}  #  end of "sub file_multiline_grep"

#-------------------------------------------------#
sub _PrintMatchingGroup
{
   my ($numeration, $match_line_nr, $separator) = @_ ;
   for my $line_nr (sort {$a <=> $b} keys %group_lines)
   {
      if ($numeration)
      {
         if ($line_nr == $match_line_nr) { printf "%3d= ", $line_nr; }
         else                            { printf "%3d: ", $line_nr; }
      }
      print $group_lines{ $line_nr };
   }
   defined $separator && print "$separator\n";
}  #  end of "sub PrintMatchingGroup"

#-------------------------------------------------#
1;

__END__

=head1 NAME

File::MultilineGrep - Match multiple line block delimited by start/stop pattern

=head1 SYNOPSIS

   use File::MultilineGrep;

   file_multiline_grep ($begin_pattern
                      , $finish_pattern
                      , $middle_pattern
                      , $numeration
                      , $input_file
                      , $output_separator);

=head1 DESCRIPTION

To be considered text files having repeated structures. These structures possess repeated
start delimiter, optional stop delimiter and variable contents. That is some or all fields
of these structures are optional.
A task is to select all whole structures, that contain a specified pattern.
This can be done using a multiline regular expressions. But there is a performance issue:
Processing time using regular expression is not directly proportional to amount of structures,
so that increasing of this amount might cause the reqular expression will never finish.
Processing time of the proposed function is directly proportional to amount of structures.

=head1 SUBROUTINES

=head2 file_multiline_grep

   file_multiline_grep( $begin_pattern      #                     regular expression
                      , $finish_pattern     # optional parameter, regular expression
                      , $middle_pattern     #                     regular expression
                      , $numeration         # if false - not enumerate output lines
                      , $input_file         # optional parameter
                                            # if false - read from STDIN
                      , $output_separator); # optional parameter

=head1 EXAMPLE

   use File::MultilineGrep;

   file_multiline_grep ('person_id'
                      , 'end_person'
                      , 'Giant'
                      , 'enumerate_lines'
                      , 'most_famous_people'
                      , '------

reads all records from a file 'most_famous_people' 
(where line enumeration doesn't belong to the file):

  1 person_id  - 001
  2 profession - Prophet
  3 first name - Moses
  4 birthyear  - 1391 BCE
  5 end_person    
  6    ...
  7 person_id  - 002
  8 profession - Giant
  9 first name - Samson
 10 birthyear  - Unknown
 11 end_person   
 12    ...
 13 person_id  - 003
 14 profession - King
 15 first name - David
 16 birthyear  - 1040 BCE
 17 end_person   
 18    ...
 19 person_id  - 004
 20 profession - Giant
 21 first name - Goliath
 22 birthyear  - 135  BCE
 23 end_person   

that begin with 'person_id', finish with 'end_person' and contain a pattern 'Giant':

   7: person_id  - 002 
   8= profession - Giant
   9: first name - Samson
  10: birthyear  - Unknown
  11: end_person
 ------
  19: person_id  - 004 
  20= profession - Giant
  21: first name - Goliath
  22: birthyear  - 135  BCE 
  23: end_person
 ------

=head1 AUTHOR

Mart E. Rivilis,  rivilism@cpan.org

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-multilinegrep at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-MultilineGrep>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::MultilineGrep


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)
 L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-MultilineGrep>

=item * AnnoCPAN: Annotated CPAN documentation
 L<http://annocpan.org/dist/File-MultilineGrep>

=item * CPAN Ratings
 L<http://cpanratings.perl.org/d/File-MultilineGrep>

=item * Search CPAN
 L<http://search.cpan.org/dist/File-MultilineGrep/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Mart E. Rivilis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0).

=cut
