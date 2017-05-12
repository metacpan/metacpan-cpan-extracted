package LEOCHARRE::BogusFile;
use strict;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA @CHARS $CHARLAST $MAXLENGTH);
use Exporter;
use Carp;
$VERSION = sprintf "%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)/g;
@ISA = qw/Exporter/;
@EXPORT_OK = qw(make_bogus_file arg2bytes);
%EXPORT_TAGS = ( all => \@EXPORT_OK );
@CHARS = (0 .. 9);
$CHARLAST = scalar @CHARS;
$MAXLENGTH = 100000;




sub make_bogus_file {
   my ($path, $size_arg) = @_;   
   $path or confess("missing path argument");   
   (Carp::cluck("$path already on disk") and return) if -e $path;
   
   
   my $size = $size_arg ? arg2bytes($size_arg) : _randlength();
   
   
   # size should be in k?
   
   open(F,'>',$path) or Carp::Cluck("cant open for writing '$path', $!") and return;
   print F _randstring($size);
   close F;

   # cant return size here so simply..   
   # it may not have been defined..
   $size || (stat($path))[7];
}


sub _randlength { int( rand($MAXLENGTH) + 1 ) }

sub _randstring {
   my $length = shift;    
   $length ||= int( rand($MAXLENGTH) + 1 );
   
   #print STDERR "randstring() length: $length\n" if $DEBUG;
   
   my $string;
   
   for ( 0 .. ($length - 1)){
      $string.=$CHARS[int(rand($CHARLAST))];
   }
   
   $string;
}


sub arg2bytes {   
   defined $_[0] or confess("missing arg");
   $_[0]=~/^\d+$/ and return $_[0];
   
   my $totalbytes = $_[0];   
   

   #print STDERR "\n\ninitial bytes arg at $totalbytes\n" if $DEBUG;
   $totalbytes=~/^\d/ or confess("invalid size ammount spec $totalbytes");

   my %unit = (
      B => 1,                          # in bytes
      K => 1024,                       # kilobytes
      M => ( 1024 * 1024 ),            # megabytes
      G => ( 1024 * 1024 * 1024 ),     # gigabytes - too big.. ??
   );
   if($totalbytes=~s/([BKMG]{1}).*$//i){
      my $unit = $unit{uc($1)};
      #print STDERR " [$totalbytes] ";
      $totalbytes = int ($totalbytes * $unit);

      #printf STDERR "totalbytes [unit %s] resolved to total bytes: $totalbytes\n", $unit{uc($1)};
   }
   
   $totalbytes and $totalbytes=~/^\d+$/ or die("invalid size resolved: $totalbytes");

   $totalbytes;     
}









1;

__END__

=pod

=head1 NAME

LEOCHARRE::BogusFile - make file of x size with junk data

=head1 SYNOPSIS

   use LEOCHARRE::BogusFile ':all';
   
   my $size_in_k = make_bogus_file('./t/00.tmp');
   make_bogus_file('./t/01.tmp','100')
      or die("can't make 100k file"); 
   
   make_bogus_file('./t/01.tmp','1.24M')
      or die("can't make 100k file"); 


=head1 SUBS

Not exported by default.

=head2 make_bogus_file()

Arg is path to new file. If already on disk, warns and returns undef.
Optional arg is size in k for file.
If no size is passed, will make a filesize under $LEOCHARRE::BogusFile::MAXLENGTH

=head2 arg2bytes()

Arg is size such as.. 100, 1M, 12.4M, 100k, 100K, etc. 
Returns what it resolves to in bytes.
Throws exception if not a size amount.

=head1 $MAXLENGTH

This is the max chars to put in file, also max k in file.
Default value is 100000, which is about 100k.


=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut


