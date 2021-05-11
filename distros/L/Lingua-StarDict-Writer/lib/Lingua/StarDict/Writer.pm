package Lingua::StarDict::Writer;

use 5.008;
use strict;
use warnings;
use Path::Tiny;
use Unicode::UTF8;
use Time::Piece;
use Moo;


use Lingua::StarDict::Writer::Entry;

=encoding utf8
=cut

=head1 NAME

Lingua::StarDict::Writer - A module that allows to create a StarDict dictionary

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

A module that allows to create a StarDict-compatible dictionary, with multipart
and multitype entries.

    use Lingua::StarDict::Writer;

    my $stardict_writer = StarDict::Writer->new(name=>'My Cool Dictionary', date=>"2020-12-31");

    $stardict_writer->entry('42')->add_part(type=> "t", data => "ˈfɔɹti tuː");
    $stardict_writer->entry('42')->add_part(type=> "m", data => "Answer to the Ultimate Question of Life, the Universe, and Everything");

    $stardict_writer->entry('Perl')->add_part(type=> "t", data => "pɛʁl");
    $stardict_writer->entry('Perl')->add_part(type=> "h", data => "The <b>best</b> programming language ever");

    $stardict_writer->write;

=head1 DESCRIPTION

StarDict is a popular dictionary format, supported by many dictionary and book reading programs.

StarDict entry may consist of several parts of various text or media types.

This module allows to create a new StarDict dictionary with entries consisting of parts of
arbitrary types.

=head1 METHODS

=head2 new ( option_name => 'value')

Constructs and returns a new C<Lingua::StarDict::Writer> object. This object will accept parts for the
dictionary entry via C<add_entry_part> method. You can write the resulting dictionary with C<write> method.
C<new> method accepts arguments represented as C<< name=>value >> options hash. Following options are available:

=over

=item * C<name> - sets a name for the dictionary. It will be specified in StarDict dictionary C<.ifo> file as
dictionary name. When you call C<write> method, writer will create C<name> dir in the C<output_dir> dir, and all
dictionary files that will be written there will use C<name> as the base part of file name.
By default, the name will be set to C<"Some Dictionary written by Lingua::StarDict::Writer"> if none is provided.

=item * C<date> - date of dictionary creation in C<YYYY-MM-DD> format. Will be saved in Stardict C<.ifo> file.
By default, current date will be used.

=item * C<output_dir> - path where dictionary files will be saved. By default, current dir will be used as the C<output_dir>.

=back

=head2 entry($entry_title)

Returns dictionary entry named C<$entry_title>. If entry C<$entry_title> does not exist, a new empty
dictionary entry  will be created and returned. The only reason you may want to get a dictionary entry is to
add a new part using C<add_part> method (See below)

Entries can be added in arbitrary order, they will be sorted alphabetically using StarDict sorting algorithm, when
dictionary is written.

=head2 entry->($enry_title)->add_part(type => $part_type, data => $part_data)

Adds new part to an entry.

=over

=item * C<type> - part type, coded as one Latin letter as specified in StarDictFileFormat. (C<'m'> for plaintext, C<'h'> for html,
C<'t'> for pronunciation, etc. See StarDictFileFormat in "See Also" chapter for more info). By default C<'m'> type will
be used if none is specified.

=item * C<data> - Content of added entry part: a text string that can be formatted using chosen C<type> markup.

=back

Parts will be saved in the entry in the order they were added.

=head2 write

This method will write all entries to the disk formatted as StarDict dictionary. C<.dict>, C<.idx> and C<.ifo> files
will be placed in directory C<name> at the path specified in C<output_dir> option. You should put them to C</usr/share/stardict/dic> or
 C<~/.stardict/dic> path to make them visible to StarDict.

=head1 ENCODING ISSUE

All methods expect to recieve data encoded as perl character strings, not as byte string (i.e. Cyrillic "я" should be encoded as C<\x{44f}>,
and not as C<\x{d1}\x{8f}>). If you have read utf-8 source data from a file, database or from web, make sure that utf-8 bytes you've got
are converted to perl characters. See L<this article|https://dev.to/fgasper/perl-unicode-and-bytes-5cg7> for more info.


=head1 CAVEATS

=over

=item * C<sametypesequence> mode is not implemented. Use custom sequence mode instead.

=item * Support for binary parts is not implemented.

=item * Dictionary compression is not implemented.

=item * Synonyms are not implemented.

=back

etc...

=head1 SEE ALSO

=over

=item * L<StarDictFileFormat|http://stardict-4.sourceforge.net/StarDictFileFormat> - StarDict
format description. A copy of this file can be found in this package in C<doc/> dir.

=item * L<Lingua::StarDict::Gen> - another module for writing StarDict dictionaries. It supports only
single-part plain text entries.

=back

=cut

has 'name' => (
    is => 'rw',
    default => "Some Dictionary written by Lingua::StarDict::Writer",
);

has 'date' => (
    is => 'rw',
    default => sub {localtime->ymd},
);

has 'output_dir' => (
    is => 'rw',
    default => "./",
);

has '_entries' => (
    is => 'rw',
    default => sub {+{}}
);

sub entry
{
  my $self = shift;
  my $name = shift;

  if (! exists $self->_entries->{$name})
  {
    $self->_entries->{$name} = Lingua::StarDict::Writer::Entry->new(name=>$name); # Create new entry if does not exist
  }
  return $self->_entries->{$name};
}

sub write
{
  my $self = shift;
  my $dir = path($self->output_dir,$self->name);

  unless(-d $dir)
  {
    mkdir($dir,0755) or die "Cant create directory $dir\n";
  }

  my $dict_fh = $dir->child($self->name.".dict")->openw_raw;
  my $idx_fh  = $dir->child($self->name.".idx" )->openw_raw;
  my $ifo_fh  = $dir->child($self->name.".ifo" )->openw_utf8;

  my $byte_count = 0;
  my @ordered_keys = sort {stardict_strcmp($a,$b)} keys(%{$self->_entries});

  foreach my $word (@ordered_keys)
  {
    my $start_pos = $byte_count;
    my $word_bytes;
    {
      use warnings FATAL => 'utf8';
      $word_bytes = Unicode::UTF8::encode_utf8($word);
    }
    print $idx_fh pack('a*x',$word_bytes);
    print $idx_fh pack('N',$byte_count);

    foreach my $part (@{$self->entry($word)->_parts})
    {
      my $data = $part->{data};
      my $data_bytes;
      {
        use warnings FATAL => 'utf8';
        $data_bytes = Unicode::UTF8::encode_utf8($data);
      }
      print $dict_fh $part->{type};
      print $dict_fh "$data_bytes\0";
      $byte_count += length($data_bytes) + 1 + 1; # one for media type char, one for \0
    }

    print $idx_fh pack('N',$byte_count-$start_pos);
  }

  my $word_count = scalar (keys %{$self->_entries});

  print $ifo_fh "StarDict's dict ifo file\n";
  print $ifo_fh "version=2.4.2\n";
  print $ifo_fh "wordcount=$word_count\n";
  print $ifo_fh "bookname=".$self->name."\n";
  print $ifo_fh "idxfilesize=", tell($idx_fh),"\n";
  print $ifo_fh "date=".$self->date."\n";
#    if($^O eq "MSWin32"){ print $ifo_fh "sametypesequence=m\n";} # do not support sametypesequence for now
#    else                { print $ifo_fh "sametypesequence=x\n";}

  close $dict_fh;
  close $idx_fh;
  close $ifo_fh;
}


# g_ascii_strcasecmp, strcmp, stardict_strcmp_old (formerly known as stardict_strcmp)
# are pure perl reimplementation of sort functons used by StarDirct for index lookup.
# Index file should be ordered with exactly the same functions that is used for lookup
# g_ascii_strcasecmp, strcmp, stardict_strcmp_old are left here commented out for historical
# reasons.
# stardict_strcmp is a perl-way implementation of sort functions that do same ordering
# as function mentioned above

#sub g_ascii_strcasecmp
#{
#  # pure perl re-implementation of g_ascii_strcasecmp
#  my $s1 = shift;
#  my $s2 = shift;
#  no locale;
#  $s1=~s/([A-Z])/lc($1)/ge;
#  $s2=~s/([A-Z])/lc($1)/ge;
#  while (length($s1) || length($s2))
#  {
#    return -1 if length($s1)==0;
#    return 1 if length($s2)==0;
#    $s1=~s/^(.)//;
#    my $c1 = $1;
#    $s2=~s/^(.)//;
#    my $c2 = $1;
#    return ord($c1)-ord($c2) if $c1 ne $c2;
#  }
#  return 0;
#}


#sub strcmp
#{
#  # pure perl re-implementation of strcmp
#  my $s1 = shift;
#  my $s2 = shift;
#  no locale;
#  while (length($s1) || length($s2))
#  {
#    return -1 if length($s1)==0;
#    return 1 if length($s2)==0;
#    $s1=~s/^(.)//;
#    my $c1 = $1;
#    $s2=~s/^(.)//;
#    my $c2 = $1;
#    return ord($c1)-ord($c2) if $c1 ne $c2;
#  }
#  return 0;
#}

#sub stardict_strcmp_old
#{
#  # pure perl re-implementation of stardict_strcmp
#  my $s1 = shift;
#  my $s2 = shift;
#
#  my $i = g_ascii_strcasecmp($s1, $s2);
#  return $i if $i;
#  return strcmp($s1,$s2);
#}



# StarDict expects index file to be sorted in a specific way.
# UTF-8 strings are treated as bytes, all latin (and only latin) characters
# are taken to lower case, and then strings are compared. If strings copmared
# that way found equal, they are compared again, now without converting latin
# letters to lower case.

# For more info see doc/StarDictFileFormat or StarDict code. You should look for
# strcmp and stardict_strcmp functions there, and for g_ascii_strcasecmp in glibc.

sub stardict_strcmp
{
  my $s1 = shift;
  my $s2 = shift;

  my $s1_bytes;
  my $s2_bytes;
  {
    use warnings FATAL => 'utf8';
    $s1_bytes = Unicode::UTF8::encode_utf8($s1); # Convert sting from unicde characters to bytes
    $s2_bytes = Unicode::UTF8::encode_utf8($s2);
  }

  my $s1_lc_bytes = $s1_bytes;
  $s1_lc_bytes =~ tr/A-Z/a-z/; # do lower case
  my $s2_lc_bytes = $s2_bytes;
  $s2_lc_bytes =~ tr/A-Z/a-z/;

  my $res = $s1_lc_bytes cmp $s2_lc_bytes; # Compare lower case string represented as bytes

  $res = $s1_bytes cmp $s2_bytes unless $res; # if equal, compare unlowercased string represented as bytes;

  return $res;
}


=head1 AUTHOR

Nikolay Shaplov, C<< <dhyan at nataraj.su> >>


=head1 BUGS

Please report any bugs or feature requests through
the web interface at L<https://gitlab.com/dhyannataraj/lingua-stardict-writer-perl/-/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::StarDict::Writer


You can also look for information at:

=over 4

=item * The project's bug tracker (report bugs and request features here)

L<https://gitlab.com/dhyannataraj/lingua-stardict-writer-perl/-/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-StarDict-Writer>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Lingua-StarDict-Writer>

=item * Search CPAN

L<https://metacpan.org/release/Lingua-StarDict-Writer>

=back


=head1 ACKNOWLEDGEMENTS

Special thanks to B<xq> from C<freenode> C<#perl> for deep code review.

Thanks to B<Rince> for proofreading.

=head1 LICENSE AND COPYRIGHT

Copyright 2021 Nikolay Shaplov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Lingua::StarDict::Writer
