package File::ReadSimple;

use 5.006;
use strict;
use warnings;

require Exporter;

#our @ISA = qw(Exporter);
our (@ISA, @EXPORT, $VERSION);
@ISA = qw(Exporter);
@EXPORT = qw(file_read file_read_line file_bulk_read_line file_read_last_lines file_read_first_lines file_read_odd_lines file_read_even_lines file_grep_word file_grep_word_line_no file_tail file_word_replace );
$VERSION = "1.0";
# Preloaded methods go here.

sub file_read {
open ( FILEREAD, "@_" ) || die "File not found" ;
while ( readline *FILEREAD )
{
  print $_;
}  
close ( FILEREAD );   
}

sub file_read_line {
my $linenumber = $_[1] -1;  
open ( FILEREADLINE, "$_[0]" ) || die "File not found" ;
my @lines = <FILEREADLINE>;
print $lines[$linenumber];
close ( FILEREADLINE );
}

sub file_bulk_read_line {
my $linestart = $_[1] - 1;
my $lineend = $_[2];
open ( FILEBULKREAD, "$_[0]" ) || die "File not found" ;
my @line = <FILEBULKREAD>;
while ( $linestart < $lineend )
{
   print $line[$linestart];
   $linestart = $linestart + 1;
}
close ( FILEBULKREAD );
}

sub file_read_last_lines {
my $linestart = $_[1];
open ( LASTLINES, "$_[0]" ) || die "File not found";
my @li = <LASTLINES>;
while (  $linestart > 0 )
{
  print $li[-$linestart];
  $linestart = $linestart - 1;
}  
close ( LASTLINES );
}
 
sub file_read_first_lines {
open ( FIRSTLINES, "$_[0]" ) || die "File not found";
my @li = <FIRSTLINES>;
my $line = 0;
while ( $line < $_[1] )
{
    
    print $li[$line];
     $line = $line + 1;
}
close ( FIRSTLINES );
}

sub file_read_odd_lines {
  open ( ODD, $_[0]) || die "File not found";
  my @data = <ODD>;
  my $i = "1";
  my $size = $#data + 1;
  while ( $i <= $size )
  {
    print "$data[$i]";
    $i = $i + 2;
   }
close ( ODD );
}

sub file_read_even_lines {
  open ( EVEN, "$_[0]" ) || die "File not found";
  my @data = <EVEN>;
  my $i = "0";
  my $size = $#data + 1;
  while ( $i <= $size )
  {
    print "$data[$i]";
    $i = $i + 2;

  }
close ( EVEN );
  }

sub file_grep_word {
open ( FILEGREP, "$_[0]" ) || die "File not found" ;
while ( readline *FILEGREP )
{
  print $_ if ( $_ =~ /$_[1]/ );
}
close ( FILEGREP );
}

sub file_grep_word_line_no {
my $no = "1";  
open ( FILEGREPNO, "$_[0]" ) || die "File not found" ;
while ( readline *FILEGREPNO )
{
  
  print "$no:$_ " if ( $_ =~ /$_[1]/ );
  $no = $no + 1;
  }
close ( FILEGREPNO );
}

sub file_word_replace {
open ( GREPREPLACE, "$_[0]" ) || die "File not found" ;
while ( readline *GREPREPLACE )
{
if ( $_ =~ /$_[1]/ )
{
$_ =~ s/$_[1]/$_[2]/;
print $_;

}
}
close ( GREPREPLACE );
}



sub file_tail {
my $no = "1" ;
open ( FILETAIL, "$_[0]") || die "File not found";
my @lines = <FILETAIL>;
my $start = $#lines;
#my $first = $lines[-1];
#my $len = length ($first );
print $lines[-1] if ( length($lines[-1]) > 0 );
while ($no > 0 )
{
	my @new_lines = <FILETAIL>;
  my $end = $#new_lines;
	if ( $start =! $end )
	{
  print $new_lines[-1]; 	
}	
}
close(FILETAIL);
}




1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

File::ReadSimple - Perl extension for making filehandling very easy for not-so good Perl Programmers.

=head1 SYNOPSIS

  use File::ReadSimple;
  
  file_read ("1.txt" or "ls -la |");
  file_read_line("1.txt or "ls -la |","2");
  file_bulk_read_line("1.txt" or "ls -la |","2","5");
  file_read_last_lines("1.txt" or "ls -la |","2");
  file_read_first_lines("1.txt" or "ls -la |","2");
  file_read_odd_lines("1.txt" or "ls -la |");
  file_read_even_lines("1.txt" or "ls -la |");
  file_grep_word ("1.txt" or "ls -la |");
  file_word_replace("1.txt" or "ls -la","abc","xyz");
  file_grep_word_line_no("1.txt" or "ls -la");
  file_tail("1.txt");
  
=head1 DESCRIPTION

This module wraps many of the routine Filehandling/Command output handling tasks performed by Perl users/programmers.
The reason for the development of the module is to help people use filehandling more efficiently and easily.
Following is the way these functions can be used.

Function Name:file_read 
Description: To read a file or command output

Function:file_read_line
Description: To read a specific line from the a file or command ouput

Function:file_bulk_read_line
Description: To read range of lines from a file or command output

Function:file_read_last_lines
Description:to read range of lines from the end of the file or command output

Function:file_read_first_lines
Description:To read range of lines from the start of the file or command output

Function:file_read_odd_lines
Description:To read odd lines from file or command output

Function:file_read_even_lines
Description:To read even no lined from a file or command output

Function:file_grep_word
Description:To find a lines containing the word from a file or command output

Function:file_word_replace
Description:To find a word and replace with another word in a file or command output

Function:file_grep_word_line_no
Description:To display the lines with nos where the word given if found from the file or command output

Function:file_tail
Description:To continuously follow file output or command output i.e tail -f in UNIX.


=head2 EXPORT

None by default.



=head1 SEE ALSO


=head1 AUTHOR

Nitin Harale, E<lt>nitin.harale@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Super-User

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
