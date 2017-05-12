
package LW4::Reader;

use 5.008001;
#use strict;
#use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( read_header read_item_info build_category_phrases );
our $VERSION = '0.01';

sub read_header {
  # Read the show info information of the file.
  #
  # Passed: The file handle of the Lightwright file to read from.
  # Returns: Hashref of header info.
  
  my $lw4_file_fh = shift;
  my $header_ref = { };
  
  # Get file header info. This includes: * The file identifier * The
  # date/time last saved, and the user saved by.  * The show info
  # (title of the document).  This data should always predictably be
  # found at the top of the file so there isn't a need to go seeking
  # for it.
  
  # There are some things in this format that I haven't
  # figured out yet. For now read them in to a discardable
  # variable and carry on. We'll come back and fill in the
  # blanks when I have a better understanding of some of
  # these specifics.
  
  my $junk                        = <$lw4_file_fh>;
  $junk                           = <$lw4_file_fh>;
  $junk                           = <$lw4_file_fh>;
  $header_ref->{file_ident}       = <$lw4_file_fh>;
  $junk                           = <$lw4_file_fh>;
  $junk                           = <$lw4_file_fh>;
  $junk                           = <$lw4_file_fh>;
  $header_ref->{show_name}        = <$lw4_file_fh>;
  $header_ref->{sub_head_1}       = <$lw4_file_fh>;
  $header_ref->{sub_head_2}       = <$lw4_file_fh>;
  $header_ref->{sub_head_3}       = <$lw4_file_fh>;
  $header_ref->{sub_head_4}       = <$lw4_file_fh>;
  $header_ref->{sub_head_5}       = <$lw4_file_fh>;
  $header_ref->{sub_head_6}       = <$lw4_file_fh>;
  $junk                           = <$lw4_file_fh>;
  $junk                           = <$lw4_file_fh>;
  $junk                           = <$lw4_file_fh>;
  $junk                           = <$lw4_file_fh>;
  $junk                           = <$lw4_file_fh>;
  $header_ref->{num_fixtures}     = <$lw4_file_fh>;
  $header_ref->{save_date}        = <$lw4_file_fh>;
  $junk                           = <$lw4_file_fh>;
  $header_ref->{save_time}        = <$lw4_file_fh>;
  $junk                           = <$lw4_file_fh>;
  $header_ref->{max_num_fixtures} = <$lw4_file_fh>;    
  
  # Some entries have preceding white space that we'll want to
  # strip. 
  
  foreach my $key (keys %$header_ref) {
    $header_ref->{$key} =~ s/^\s+//gxms;
    $header_ref->{$key} =~ s/\s+$//gxms;
  }
  
  return $header_ref;
}

sub read_item_info {
  # Read the data portions of the file.
  #
  # Passed: the file handle of the LW4 file.
  # Returns: Array of hashes of item information extracted from
  #  the file.

  my $lw4_file_fh = shift;
  my @lw4_item_info_AoH;

  # * Build the "vocabulary" the file uses to describe
  #   it's data.    
  my $phrase_table_AoA = build_category_phrases($lw4_file_fh);
      
  my $current_count = 0;
    
  # ** Seek to the line that contains '** Item Info:'
 LINE: while (<$lw4_file_fh>) {
    my $lw4_file_line = $_;
    chomp $lw4_file_line;
      
    # Read lines from the file until we find Item info, then create
    # an AoH of each item, substituting the references in the file
    # for the names we have compiled in the phrase table. 
    
    if ($lw4_file_line =~ m/^\*\* Item Info:/) {
      # There are two things at the top of the Item Info section,
      # and I don't know what they are yet. We'll probably be able
      # to use them for something once I figure out what they are,
      # but for now just store them.
      my $final_rec  = 0;
      my $item_count = <$lw4_file_fh>;
      chomp $item_count;
      $item_count =~ s/^\s//;
      $item_count =~ s/\s+$//g;
	
      my $mystery_item_head_two = <$lw4_file_fh>;
      my $head_seperator        = <$lw4_file_fh>;
	
    ITEM: while ($current_count <= $item_count) {
	$lw4_file_line = <$lw4_file_fh>;
	chomp $lw4_file_line;

	my %lw4_item;
	  
	# Build the item hash table, one lines at a time. There are
	# still a lot of uknowns in this file, but we should be able
	# to figure them out at some point in the future.
	#
	# Rather than doing phrase table substitutions in place,
	# we'll batch clean out the newlines and leading whitespace
	# after the fact, and then make the substitutions for the
	# appropriate records.
	
	$lw4_item{unknown1}   = $lw4_file_line;
	$lw4_item{channel}    = <$lw4_file_fh>;
	$lw4_item{dimmer}     = <$lw4_file_fh>;
	$lw4_item{unit}       = <$lw4_file_fh>;
	$lw4_item{watts}      = <$lw4_file_fh>;
	$lw4_item{circuit}    = <$lw4_file_fh>;
	$lw4_item{unknown2}   = <$lw4_file_fh>;
	$lw4_item{unknown3}   = <$lw4_file_fh>;
	$lw4_item{unknown4}   = <$lw4_file_fh>;
	$lw4_item{unknown5}   = <$lw4_file_fh>;
	$lw4_item{unknown6}   = <$lw4_file_fh>;
	$lw4_item{unknown7}   = <$lw4_file_fh>;
	$lw4_item{unknown8}   = <$lw4_file_fh>;
	$lw4_item{purpose}    = <$lw4_file_fh>; # lookup needed
	$lw4_item{position}   = <$lw4_file_fh>; # lookup needed
	$lw4_item{color}      = <$lw4_file_fh>; # lookup needed
	$lw4_item{accessory}  = <$lw4_file_fh>; # lookup needed
	$lw4_item{type}       = <$lw4_file_fh>; # lookup needed
	$lw4_item{pattern}    = <$lw4_file_fh>; # lookup needed
	$lw4_item{unknown10}  = <$lw4_file_fh>;
	$lw4_item{unknown11}  = <$lw4_file_fh>;
	$lw4_item{unknown12}  = <$lw4_file_fh>;
	$lw4_item{unknown13}  = <$lw4_file_fh>;
	$lw4_item{unknown14}  = <$lw4_file_fh>;
	$lw4_item{unknown15}  = <$lw4_file_fh>;
	$lw4_item{unknown16}  = <$lw4_file_fh>;
	$lw4_item{unknown17}  = <$lw4_file_fh>;
	$lw4_item{unknown18}  = <$lw4_file_fh>;
	$lw4_item{unknown19}  = <$lw4_file_fh>;
	$lw4_item{unknown20}  = <$lw4_file_fh>;
	$lw4_item{unknown21}  = <$lw4_file_fh>;
	$lw4_item{unknown22}  = <$lw4_file_fh>;
	$lw4_item{unknown23}  = <$lw4_file_fh>;
	$lw4_item{unknown24}  = <$lw4_file_fh>;
	$lw4_item{unknown25}  = <$lw4_file_fh>;
	$lw4_item{unknown26}  = <$lw4_file_fh>;
	$lw4_item{unknown27}  = <$lw4_file_fh>;
	$lw4_item{unknown28}  = <$lw4_file_fh>;
	$lw4_item{item_key}   = <$lw4_file_fh>;
	$lw4_item{unknown30}  = <$lw4_file_fh>;
	$lw4_item{unknown31}  = <$lw4_file_fh>;
	$lw4_item{unknown32}  = <$lw4_file_fh>;
	$lw4_item{unknown33}  = <$lw4_file_fh>;
	$lw4_item{unknown34}  = <$lw4_file_fh>;
	$lw4_item{unknown35}  = <$lw4_file_fh>;
	$lw4_item{unknown36}  = <$lw4_file_fh>;
	my $seperator          = <$lw4_file_fh>;
	
	# This should be the end of the item record.
	# Eliminate leading whitespace and newlines.
	
	foreach my $key (keys %lw4_item) {
	  chomp $lw4_item{$key};
	  $lw4_item{$key} =~ s/^\s//;
	  $lw4_item{$key} =~ s/\s+$//g;
	}
	
	# Now perform the substitutions for the items in
	# the phrase table.
	
	my $temp_buff         = $lw4_item{purpose};
	$lw4_item{purpose}   = $phrase_table_AoA->[1]->[$temp_buff];
	
	$temp_buff            = $lw4_item{position};
	$lw4_item{position}  = $phrase_table_AoA->[2]->[$temp_buff];
	
	$temp_buff            = $lw4_item{type};
	$lw4_item{type}      = $phrase_table_AoA->[3]->[$temp_buff];
	
	$temp_buff            = $lw4_item{accessory};
	$lw4_item{accessory} = $phrase_table_AoA->[4]->[$temp_buff];
	
	$temp_buff            = $lw4_item{color};
	$lw4_item{color}     = $phrase_table_AoA->[5]->[$temp_buff];
	
	$temp_buff            = $lw4_item{pattern};
	$lw4_item{pattern}   = $phrase_table_AoA->[6]->[$temp_buff];
	
	# Now that substitutions are completed, add a ref to the hash
	# to the AoH.
	
	push @lw4_item_info_AoH, \%lw4_item;
	
	$current_count++;
	
      } # end ITEM: while (<$lw4_file_fh>) {
    } # end if ($lw4_file_line =~ m/^\*\* Item Info:/) {
  } # end LINE: while (<$lw4_file_fh>) {
  
  return \@lw4_item_info_AoH;
} # end sub read_item_info {

sub build_category_phrases {
  # Passed: The file handle of the LW4 file.
  # Returns: Array of Arrays of category phrases

  my $lw4_file_fh     = shift;

  # This method of creating the ref to @category_phrases is a little
  # bit wordy, but safe for use strict.
  
  my @category_phrases  = ( );
  my $category_phrases    = \@category_phrases;
  my $category_index      = 0;
  
  # * Seek to '** Category Phrases:'

 LINE:  while (<$lw4_file_fh>) {
    my $lw4_file_line = $_;
    chomp $lw4_file_line;

    ##print "$lw4_file_line\n";

    # Read the Category Phrases out of the LW4 file. Everything is
    # sequential, so an AoA seems to make the most sense. If we
    # make sure that we're incrimenting the index on the newline that
    # seperates the records BEFORE reading the first record, everything
    # will start at index 1, so we won't need to read the Category
    # Index table later.
    if ($lw4_file_line =~ m/^\*\* Category Phrases:/) {
    PHRASE: while (<$lw4_file_fh>) {
	my $lw4_file_line = $_;
	chomp $lw4_file_line;
	if ($lw4_file_line =~ m/^\W+$/)
	  {
	   $category_index++;
	  }
	last LINE if $lw4_file_line =~ m/^\*\* Category Order Pointers:/;

	# Apparently there is some trailing white space at the
	# end of each record.
	$lw4_file_line =~ s/\s+$//g;
	push @{ $category_phrases->[$category_index] }, $lw4_file_line;
	
      }
    }
  }
  
  return $category_phrases;
}


1;
    
# Autoload methods go after =cut, and are processed by the autosplit program.

__END__
# POD follows...

=head1 NAME

LW4::Reader - Perl extension for reading Lightwright 4 files.

=head1 SYNOPSIS

  use LW4::Reader qw( read_header read_item_info );

  # Open a file.

  my $lw4_file_name = 't/test.lw4';

  open my $lw4_file_fh, "$lw4_file_name"
      or die "Couldn't open $lw4_file_name:   $!\n";

  # Get file header info.

  my $lw4_header = read_header($lw4_file_fh)

  # Get file contents.

  my $lw4_items_AoH = read_item_info($lw4_file_fh);

=head1 DESCRIPTION

This module is designed to read basic information out of a file generated
by John McKernon's "Lightwright 4" software. At the time of this writing,
Lightwright is not available for POSIX compliant operating systems, and
these functions are convenient to use for the purpose of converting the
basic item info of a Lightwright file into a spreadsheet (or some other
data format).

=over

=item read_header($file_handle)

This subroutine reads the header information out of an open file handle and
returns it as a hashref. Access as follows:

my $lw4_header = read_header($file_handle);

$lw4_header->{save_date};        # The date the file was last saved.
$lw4_header->{save_time};        # The time the file was last saved.
$lw4_header->{show_name};        # The name of the show.
$lw4_header->{sub_head_1};       # File sub heading 1.
$lw4_header->{sub_head_2};       # File sub heading 2.
$lw4_header->{sub_head_3};       # File sub heading 3.
$lw4_header->{sub_head_4};       # File sub heading 4.
$lw4_header->{sub_head_5};       # File sub heading 5.
$lw4_header->{sub_head_6};       # File sub heading 6.
$lw4_header->{num_fixtures};     # Current number of fixtures in the file.
$lw4_header->{max_num_fixtures}; # The maximum number of fixtures the file
                                 # has had.
$lw4_header->{file_ident};       # The unique identifier for the file.

=item read_item_info($file_handle)

This subroutine reads the items out of an open file handle and returns a ref
to an array of hashes. The items are read into a hashref, and then stored
sequentially in an array, the ref to which is returned to caller. Access to
item info is as follows:

my $lw4_info = read_item_info($file_handle)

$lw4_info->[0]->{channel};      # The channel the item is assigned to.
$lw4_info->[0]->{dimmer};       # The dimmer the item is assigned to.
$lw4_info->[0]->{unit};         # The unit number of the item.
$lw4_info->[0]->{watts};        # The wattage of the item.
$lw4_info->[0]->{circuit};      # The circuit number of the item.
$lw4_info->[0]->{purpose};      # The purpose of the item.
$lw4_info->[0]->{position};     # The hang position of the item.
$lw4_info->[0]->{color};        # The gel color of the item.
$lw4_info->[0]->{type};         # The fixture type of the item.
$lw4_info->[0]->{pattern};      # The pattern the item carries.
$lw4_info->[0]->{item_key};     # The unique key identifier of the item,
                                # generated by Lightwright.

There are several pieces of information that Lightwright stores for each item
that have not yet been identified. They are presently stored in the hash,
and are accessable: if you know what one of these is, see the code for which
unknown type you're looking for, and please drop the author an email so he
can update the software accordingly.

=back

=head

=head2 EXPORT

None by default.

read_header and read_item_info by request.

build_category_phrases by request, if you have a good reason for it, but
probably you don't.

=head1 SEE ALSO

Lightwright software and documentation is available through John McKernon
Software at http://www.mckernon.com

=head1 AUTHOR

Tony Tambasco, E<lt>tambascot(at)yahoo{dot}comE<gt>

This library is not developed by or with, or endorsed by John McKernon
Software, nor is the author affiliated with John McKernon Software in
any way. 

If you have questions about Lightwright software itself, or would like
to purchase Lightwright, please contact John McKernon at
E<lt>help2006(at)mckernon{dot}comE<gt> or visit his website:
http://www.mckernon.com

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Tony Tambasco

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This library is not developed by or with, or endorsed by John McKernon
Software, nor is the author affiliated with John McKernon Software in
any way. 

"Lightwright" is copyright 1999 - 2003 by John McKernon Software, all
rights reserved. 

=cut
