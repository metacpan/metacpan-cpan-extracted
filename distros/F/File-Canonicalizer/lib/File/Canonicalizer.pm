package File::Canonicalizer;

use 5.006;
use strict;
use warnings FATAL => 'all';
use English;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(file_canonicalizer);

use Carp;
our $VERSION = '0.11';

sub file_canonicalizer {
   my ( $inp_file                                       # 1
      , $out_file                                       # 2
      , $remove_comments_started_with_RE                # 3
      , $replace_adjacent_tabs_and_spaces_with_1_space  # 4
      , $replace_adjacent_slashes_with_single_slash     # 5
      , $remove_white_char_from_line_edges              # 6
      , $remove_empty_lines                             # 7
      , $convert_to_lowercased                          # 8
      , $remove_leading_zeroes                          # 9
      , $sort_lines                                     #10
      , $aref_replacements                              #11
      ) = @_ ;

   my %lines ;
   my $INP;
   my $OUT;
   my $i ;
   my $replaced_pattern;
   my $replacement;

   unless ($inp_file) { $inp_file = '&STDIN'; } 
   open ($INP, "<$inp_file") || croak "Error: Can't open file \"$inp_file\" for read: $!"; 
   unless ($out_file) { $out_file = '&STDOUT'; } 
   open ($OUT, ">$out_file") || croak "Error: Can't open file \"$out_file\" for write: $!" ;

   while (<$INP>)
   {
     chomp;
     if ($remove_comments_started_with_RE) { s/$remove_comments_started_with_RE.+$//; }
     if ($replace_adjacent_tabs_and_spaces_with_1_space) { s/[ \t]+/ /g; }
     if ($replace_adjacent_slashes_with_single_slash) { s#/+#/#g; }
     if ($remove_empty_lines) { (/^\s*$/) && next; }
     if ($remove_white_char_from_line_edges) { s/(^[ \t]*|[ \t]*$)//g; }
     if ($convert_to_lowercased) { $_ = lc; }
     if ($remove_leading_zeroes) { s/(\W)0+(\d)/$1$2/g; }

     if (defined $aref_replacements)
     {
        $i = 0;
        REPLACEMENTS: while (1)
        {
           ($replaced_pattern, $replacement) = (@{$aref_replacements})[$i++,$i++];
           (defined $replacement) || last REPLACEMENTS;
           s/$replaced_pattern/$replacement/g;
        }
     }

     if ($sort_lines) { $lines{$_} = undef; next; }
     print $OUT "$_\n" || croak "Error: Can't write to $out_file: $!";
   }

   if ($sort_lines)
   {
      for (sort keys %lines)
      {  print $OUT "$_\n" || croak "Error: Can't write to $out_file: $!"; }
   }

   close $OUT; 
   close $INP;
}  #  end of 'sub file_canonicalizer'

1;

__END__

=head1 NAME

File::Canonicalizer - ASCII file canonicalizer

=head1 SYNOPSIS

   use File::Canonicalizer;

   $aref = [ 'replaced_pattern1', 'replacement1',
             'replaced_pattern2', 'replacement2',
             ... ];

   file_canonicalizer ('input_file','canonical_output_file', '',4,5,6,7,8,9,10, $aref);

=head1 DESCRIPTION

Sometimes files must be compared semantically, that is their contents, not their forms
are to be compared.
Following two files have different forms, but contain identical information:

file_A

   First name -        Barack

   Last name  -        Obama

   Birth Date -        1961/8/4

   Profession -        President 


file_B

   last name : Obama
   first name: Barack
   profession: president   # not sure

   Birth Date: 1961/08/04

Some differences between forms of these files are:

=over 4

=item * arbitrary line order

=item * arbitrary character cases

=item * arbitrary leading zeroes for numbers

=item * arbitrary amounts of white characters

=item * arbitrary comments

=item * arbitrary empty lines

=item * field separators

=back

Using file_canonicalizer allows one to simplify both of these files, so that
they can be compared with each other.

=head1 SUBROUTINES

=head2 file_canonicalizer

   file_canonicalizer ( <input_file>                                   # 1 default is STDIN
                      , <output_file>                                  # 2 default is STDOUT 
                      , remove_comments_started_with_<regular_express> # 3 if empty, ignore comments
                      , 'replace_adjacent_tabs_and_spaces_with_1_space'# 4
                      , 'replace_adjacent_slashes_with_single_slash'   # 5
                      , 'remove_white_characters_from_line_edges'      # 6
                      , 'remove_empty_lines'                           # 7
                      , 'convert_to_lower_cased'                       # 8
                      , 'remove_leading_zeroes_in_numbers'             # 9
                      , 'sort_lines_lexically'                         #10
                      , array_reference_to_pairs_replaced_replacement  #11
   );

All parameters, beginning with the 3rd, are interpreted as Boolean values
true or false. A corresponding action will be executed only if its parameter value is true.
This means, that each of literals between apostrophes '' can be shortened to
single arbitrary character or digit 1-9.

List of parameters can be shortened, that is any amount of last parameters can be skipped.
In this case the actions, corresponding skipped parameters, will not be executed.

=head1 EXAMPLES

Read from STDIN, write to STDOUT and remove all substrings, beginning with '#' :

   file_canonicalizer ('','','#');

Create canonicalized cron table (on UNIX/Linux) in any of equivalent examples:

   file_canonicalizer('path/cron_table','/tmp/cron_table.canonic','#',4,5,'e','empty_lin','',9,'sort');
   file_canonicalizer('path/cron_table','/tmp/cron_table.canonic','#',4,5, 6,    7,       '',9, 10);
   file_canonicalizer('path/cron_table','/tmp/cron_table.canonic','#',1,1, 1,    1,       '',1, 1);

Canonicalization of files 'file_A' and 'file_B', shown in the section "DESCRIPTION":

   file_canonicalizer('file_A','file_A.canonic','#',1,5,1,1,1,1,10, ['\s*-\s*',' : ', '^','<', '$','>']);
   file_canonicalizer('file_B','file_B.canonic','#',1,5,1,1,1,1,10, ['\s*:\s*',' : ', '^','<', '$','>']);

creates two identical files 'file_A.canonic' and 'file_B.canonic':

   <birth date : 1961/8/4>
   <first name : barack>
   <last name : obama>
   <profession : president>

=cut

=head1 AUTHOR

Mart E. Rivilis,  rivilism@cpan.org

=head1 BUGS

Please report any bugs or feature requests to bug-file-canonicalizer@rt.cpan.org, or through
the web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Canonicalizer.
I will be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

   perldoc File::Canonicalizer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)
 L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Canonicalizer>

=item * AnnoCPAN: Annotated CPAN documentation
 L<http://annocpan.org/dist/File-Canonicalizer>

=item * CPAN Ratings
 L<http://cpanratings.perl.org/d/File-Canonicalizer>

=item * Search CPAN
 L<http://search.cpan.org/dist/File-Canonicalizer/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Mart E. Rivilis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0).

=cut
