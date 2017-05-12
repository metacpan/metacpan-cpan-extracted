package Image::MetaData::GQview;

use strict;

#use warnings;
## no critic (RequireUseWarnings);

use 5.008000;
use Carp;
use Fatal qw(:void open close);
use Cwd qw(abs_path);
use PerlIO;

=head1 NAME

Image::MetaData::GQview - Perl extension for GQview image metadata

=head1 SYNOPSIS

   use Image::MetaData::GQview;

   my $md = Image::MetaData::GQview->new("test.jpg");
   my $md2 = Image::MetaData::GQview->new("test2.jpg", {fields => ['keywords', 'comment', 'picture info']});
   my $md3 = Image::MetaData::GQview->new({file => "test2.jpg", fields => ['keywords', 'comment', 'picture info']});
   $md->load("test.jpg");
   my $comment = $md->comment;
   my @keywords = $md->keywords;
   my $raw = $md->raw;
   $md->comment("This is a comment");
   $md->keywords(@keywords);
   $md->save("test.jpg");

=head1 DESCRIPTION

This module is a abstraction to the image meta data of GQview.

All internal errors will trow an error!

=head2 METHODS

=over

=cut

use version; our $VERSION = qv("v2.0.0");

=item new

This is a class method and the only one. It is used to get a object of Image::MetaData::GQview. It can be called without parameter or with the image as only option in witch case it try to load the meta data.

You can provide a hash reference as second or as only parameter which specify file and/or fields. The fields are default "keywords" and "comment" in this order.

=cut

sub new
{
   my $param = shift;
   my $class = ref($param) || $param;
   my $file  = shift;
   my $opts  = shift || {};

   if (ref($file) eq 'HASH')
   {
      $opts = $file;
      $file = undef;
   }

   my $self = {fields => [qw(keywords comment)],};
   $self->{opts}->{file} = $file if $file;

   bless $self, $class;

   foreach (qw(file fields))
   {
      $self->{$_} = $opts->{$_} if exists($opts->{$_});
   }

   $file = $self->{opts}->{file};

   $self->load($file) if $file;

   return $self;
} ## end sub new

=item load

If you didn't load the data with new you can do that with this method. If the parameter is left out the one setted before is used.

You can also specify the location for the meta file as second parameter.

=cut

sub load
{
   my $self     = shift;
   my $image    = shift || $self->{imagefile};
   my $metafile = shift;

   croak("No File given!") unless $image;
   $image = abs_path($image);
   croak("No such file ($image)!") unless -e $image;

   $self->{imagefile} = $image;

   unless ($metafile)
   {
      (my $metadata1 = $image) =~ s#/([^/]*)$#/.metadata/$1.meta#;
      my $metadata2 = abs_path($ENV{HOME}) . ".gqview/metadata$image.meta";

      $metafile = $metadata1 if -r $metadata1;
      $metafile ||= $metadata2 if -r $metadata2;
   } ## end unless ($metafile)
   $self->{metafile} = $metafile;

   croak("No metadata found for image '$image'!") unless $metafile;

   open my $in, "<:utf8", $metafile;
   $self->{metadata} = eval { local $/ = undef; <$in> };
   close $in;

   # Aufbau:
   # #GQview comment (<version>)
   #
   # [keywords]
   # ...
   #
   # [comment]
   # ...
   #
   # #end
   my $select = join("|", @{$self->{fields}});
   my @fields_ext = split(/^\[($select)\]\n/m, $self->{metadata});

   # trow away the head
   shift @fields_ext;
   die "Internal Error: Metadata are not parsable" if (@fields_ext % 2) != 0; ## no critic (RequireCarping);

   # Cleanup the last field if it exists
   $fields_ext[-1] =~ s/\n*#end\n?\z/\n/ if @fields_ext > 0;

   # Now they can be put into $self
   my %fields = @fields_ext;
   $self->{data} = \%fields;

   return 1;
} ## end sub load

=item comment

Get or set the comment.

=cut

sub comment
{
   my $self    = shift;
   my $comment = shift;

   $comment =~ s/^\[/ [/mg if $comment;
   $self->set_field('comment', $comment) if $comment;

   return scalar($self->get_field('comment'));
} ## end sub comment

=item keywords

Get or set the keywords. This is the preferred method for the keywords as it shift out empty keywords.

=cut

sub keywords ## no critic (RequireArgUnpacking);
{
   my $self = shift;

   $self->set_field('keywords', @_) if @_;

   my @keywords = grep {$_} $self->get_field('keywords');

   return @keywords;
} ## end sub keywords

=item raw

Get the raw data

=cut

sub raw
{
   my $self = shift;

   return $self->{metadata};
}

=item save

Save the data to disk. This will read the location from the gqview configuration. If there is none, the info will be saved in local directory.

You can also specify the location for the meta file as second parameter.

=cut

sub save
{
   my $self        = shift;
   my $image       = shift;
   my $newimage    = $image;
   my $metafile    = shift;
   my $newmetafile = $metafile;
   $image    ||= $self->{imagefile};
   $metafile ||= $self->{metafile};

   croak("No File given!") unless $image;
   $image = abs_path($image);
   croak("No such file ($image)!") unless -e $image;

   (my $metadata1 = $image) =~ s#/([^/]*)$#/.metadata/$1.meta#;
   my $metadata2 = abs_path($ENV{HOME}) . ".gqview/metadata$image.meta";

   my $metadata;

   # Read the gqviewrc
   if (open my $in, "<", $ENV{HOME} . "/.gqview/gqviewrc") ## no critic (RequireBriefOpen);
   {
      while (my $line = <$in>)
      {
	 chomp $line;
	 next if $line =~ /^#/;
	 if ($line =~ /^local_metadata: (true|false)$/)
	 {
	    $metadata = ($1 eq "true") ? $metadata1 : $metadata2;
	    last;
	 }
      } ## end while (my $line = <$in>)
      close $in;
   } ## end if (open my $in, "<", ...
   if ($newimage and not $newmetafile)
   {
      $metafile = $metadata;
   }

   my $false;
   my @metadirs = split(/\//, $metafile);
   pop @metadirs;
   my $metadir = "";
   while (@metadirs)
   {
      $metadir .= shift(@metadirs) . "/";
      unless (-d $metadir or mkdir($metadir))
      {
	 $false = 1;
	 last;
      }
   } ## end while (@metadirs)
   if ($false and not $newmetafile and $metafile ne $metadata2)
   {
      $false    = 0;
      $metafile = $metadata2;
      @metadirs = split(/\//, $metadata2);
      pop @metadirs;
      $metadir = "";
      while (@metadirs)
      {
	 $metadir .= shift(@metadirs) . "/";
	 unless (-d $metadir or mkdir($metadir))
	 {
	    $false = 1;
	    last;
	 }
      } ## end while (@metadirs)
   } ## end if ($false and not $newmetafile...
   croak("Cannot create directory structure for meta file '$metafile'!") if ($false);
   $self->_sync;
   if ($self->raw)
   {
      open my $meta, ">:utf8", $metafile;
      print $meta $self->raw or die("Faulty metadata"); ## no critic (RequireCarping);
      close $meta;
   } ## end if ($self->raw)

   $self->{imagefile} = $image;
   $self->{metafile}  = $metafile;

   return 1;
} ## end sub save

=item get_field

This will extract the information of one field and return it as single sting (in scalar context) or as array splitted in lines.

Please note, it array context also empty lines can be returned!

=cut

sub get_field
{
   my $self  = shift;
   my $field = shift || croak("get_field has to be called with a field as the first parameter");

   croak("get_field has to be called with a known field '$field' as first parameter") unless grep {/^\Q$field\E$/s} @{$self->{fields}};

   my $data = $self->{data}->{$field} || "";
   $data =~ s/\n*\z//;

   return wantarray ? split(/\n/, $data) : "$data\n";
} ## end sub get_field

=item set_field

Well, of cause if you can get a field you have to be able to set it.

The arguments are the field name and the data.

The data can be a single value or a array.

=cut

sub set_field ## no critic (RequireArgUnpacking);
{
   my $self  = shift;
   my $field = shift || croak("set_field has to be called with a field as the first parameter");

   croak("set_field has to be called with a known field '$field' }as first parameter") unless grep {/^\Q$field\E$/s} @{$self->{fields}};

   my $data = join("\n", @_);
   $data =~ s/\n*\z/\n/;

   $self->{data}->{$field} = $data;

   $self->_sync;

   return 1;
} ## end sub set_field

#
# Internal method _sync
#
# This will hold the metadata in sync with the single elements
#

sub _sync
{
   my $self = shift;

   $self->{metadata} = "#GQview comment (2.0.0)\n\n";

   foreach my $field (@{$self->{fields}})
   {
      my $data = $self->{data}->{$field} || "";
      $data =~ s/\n*\z/\n\n/s;
      $data = "\n" if $data eq "\n\n";
      $self->{metadata} .= "[$field]\n" . $data;
   } ## end foreach my $field (@{$self->...

   $self->{metadata} .= "#end\n";

   return 1;
} ## end sub _sync

1;

__END__

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-image-metadata-gqview at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Image-MetaData-GQview>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 INCOMPATIBILITIES

The module cannot be used under non unixoid systems like windows. But there is no need for this module anyway as the tool gqview is only available on unixoid systems.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

   perldoc Image::MetaData::GQview

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Image-MetaData-GQview>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Image-MetaData-GQview>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Image-MetaData-GQview>

=item * Search CPAN

L<http://search.cpan.org/dist/Image-MetaData-GQview>

=back

=head1 SEE ALSO

   man qview

=head1 AUTHOR

Klaus Ethgen <Klaus@Ethgen.de>

=head1 COPYRIGHT

Copyright (c) 2006-2009 by Klaus Ethgen. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 675 Mass
Ave, Cambridge, MA 02139, USA.

=cut
