package Graphics::Skullplot;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Graphics::Skullplot - Plot the result of an SQL select (e.g. from an emacs shell window)

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';
my $DEBUG = 0;

=head1 SYNOPSIS

   # To use this from emacs, see scripts/skullplot.el.
   # That elisp code accesses the perl script: scripts/skullplot.pl

   # the code used by skullplot.pl
   my $plot_hints = { indie_count           => $indie_count,
                      dependent_requested   => $dependent_requested,
                      independent_requested => $independent_requested,
                    };
   my %gsp_args = 
     ( input_file   => $dbox_file,
       plot_hints   => $plot_hints, );
   $gsp_args{ working_area } = $working_area if $working_area;
   $gsp_args{ image_viewer } = $image_viewer if $image_viewer;
   my $gsp = Graphics::Skullplot->new( %gsp_args );

   $gsp->show_plot_and_exit();  # does an exec 

=head1 DESCRIPTION

Graphics::Skullplot is a module that works with the result from a database 
select in the common tabular text "data box" format. It has routines 
to generate and display plots of the data in png format.

Internally it uses the L<Table::BoxFormat> module to parse the text table,
and the L<Graphics::Skullplot::ClassifyColumns> module to determine the types of the columns.

The default image viewer is the ImageMagick "display" command.

The immediate use for this code is to act as the back-end for the included 
Emacs package scripts/skullplot.el, so that database select results 
generated in an emacs shell window can be immediately plotted.  

This elisp code calls scripts/skullplot.pl, which might be used in
other contexts.

=head1 METHODS

=over

=cut

use 5.10.0;
use Carp;
use Data::Dumper;
use File::Basename  qw( fileparse basename dirname );
# use List::Util      qw( first max maxstr min minstr reduce shuffle sum );
# use List::MoreUtils qw( any zip uniq );

use Image::Magick;

use lib "../../../Table-Classify/lib";   
use lib "../../../Data-BoxFormat/lib";  

use Table::BoxFormat;
use Graphics::Skullplot::ClassifyColumns;

=item new

Creates a new Graphics::Skullplot object.
Object attributes:

=over

=item working_area

Scratch location where intermediate files are created.
Defaults to "/tmp".

=item image_viewer

Defaults to 'display', the ImageMagick viewer
(a dependency on Image::Magick ensures it's available)

=back

=cut

# required arguments to new 
has input_file => ( is => 'ro', isa => Str,      required => 1);  # must be dbox format 
has plot_hints => ( is => 'ro', isa => HashRef,  required => 1);

has working_area => ( is => 'rw', isa => Maybe[Str], default => "/tmp" );
has image_viewer => ( is => 'rw', isa => Maybe[Str], lazy => 1, builder => "builder_image_viewer" );  

# mostly for internal use
has naming         => ( is => 'rw', isa => HashRef, lazy => 1, builder => "generate_output_filenames" ); 

=item builder methods (largely for internal use)

builder_image_viewer Currently just returns a hardcoded selection
(the ImageMagick "display" program).

=cut 

sub builder_image_viewer {
  my $self = shift;
  ($DEBUG) && print STDERR "Running _builder_image_viewer... \n";
  return "display";
}

=item generate_output_filenames

Example usage: 

  # relies on object settings: "input_file" and "working area"
  my $fn = 
    generate_filenames();
  my $basename = $fn->{ base };
  # full paths to file in $working_area
  my $tsv_file  = $fn->{ tsv };  
  my $png_file  = $fn->{ png };  

=cut 

sub generate_output_filenames {
  my $self = shift;
  my $input_file   = $self->input_file   || shift;
  my $working_area = $self->working_area || shift;
  
  my $basename = basename( $input_file ); # includes file-extension

  my ($short_base, $ext);
  if( ( $short_base = $basename ) =~ s{ \. (.*) $ }{}x ) { 
    $ext = $1;
  }

  my $tsv_name     = $short_base . '.tsv';
  my $rscript_name = $short_base . '.r';
  my $png_name     = $short_base . '.png';
  
  my $tsv_file     = "$working_area/$tsv_name";
  my $rscript_file = "$working_area/$rscript_name";
  my $png_file     = "$working_area/$png_name";

  my %filenames =
    (
     base             => $basename,
     base_sans_ext    => $short_base,
     ext              => $ext,
     tsv              => $tsv_file,
     rscript          => $rscript_file,
     png              => $png_file
     );
  # $self->naming( \%filenames );  # Tue  November 13, 2018  20:04  tango
  return \%filenames;
}


=item plot_tsv_to_png

Generate the r-code to plot the tsv file data as the png file.
Takes one argument, a hash of "field metadata".  

The file names (tsv, png, plus internal formats) come from the
"naming" object field.

Example usages:  

  $self->plot_tsv_to_png( $plot_cols ); 

=cut 

sub plot_tsv_to_png {
  my $self = shift;
  my $cd   = shift; 
  my $fn   = $self->naming         || shift;

#  my ($x_field, $y_field, $gb_cats) = @{ $cd->{ qw( x  y  gb_cats ) }}; # hash slice (mangled)

  my $x_field = $cd->{ indie_x };
  my $y_field = $cd->{ y } || $cd->{ dependents_y }->[0] ;
  my $gb_cats = $cd->{ gb_cats };

  my ($gb_cat1, $gb_cat2);
  $gb_cat1 = $gb_cats->[0] if $gb_cats->[0];
  $gb_cat2 = $gb_cats->[1] if $gb_cats->[1];

  # plot code
  my $pc = 'ggplot( skull, ' ;
  $pc .= '               aes(' ;
  $pc .= "                    x = $x_field," ;
  $pc .= "                    y = $y_field, " ;
  $pc .= "                    colour = $gb_cat1," if $gb_cat1;
  $pc .= "                    shape  = $gb_cat2 " if $gb_cat2;
  $pc .= '                          ))' ;
  $pc .= ' + geom_point( ' ;
  $pc .= "              size  = 2.5 " ;
  $pc .= '              )  ' ;

  $self->generate_png_file( $pc, $fn );
}

=item generate_png_file

Example usage:

  $self->generate_png_file( $pc, $fn );

Runs the given plot code (first argument) using the file-name metadata
(second argument, defaults to object's L<naming>), saving the 
plot as a png file ($fn->{png}).

This generates a file of R code to run with an Rscript call.
In debug mode, this generates a standalone unix script. ($DEBUG).

=cut

sub generate_png_file {
  my $self = shift;
  my $pc   = shift;
  my $fn   = shift || $self->naming; 

  my $tsv_file     = $fn->{ tsv };
  my $rscript_file = $fn->{ rscript };
  my $png_file     = $fn->{ png };

  # Generate the file of R code to run with an Rscript call
  # (in debug mode, make it a standalone unix script)
  my $r_code;
  $r_code = qq{#!/usr/bin/Rscript} . "\n" if $DEBUG;

  $r_code .=<<"__END_R_CODE";
library(ggplot2)
skull <- read.delim("$tsv_file", header=TRUE)
png("$png_file") # send plot output to png
$pc
graphics.off()   # doesn't chatter like dev.off
__END_R_CODE

  print $r_code, "\n" if $DEBUG;

  open my $out_fh, '>', $rscript_file;
  print { $out_fh } $r_code;
  close( $out_fh );

  # in case you want to run the rscript standalone
  chmod 0755, $rscript_file;

   # chdir( "$HOME/tmp" ) or die "$!";

  my $erroff = '2>/dev/null';
  $erroff = '' if $DEBUG;

  my $cmd = "Rscript $rscript_file $erroff";

  print STDERR "cmd:\n$cmd\n" if $DEBUG;
  system( $cmd );
}




=item display_png_and_exit

Open the given png file in an image viewer
Defaults to "png" field in object's "naming".

This internally does an exec: it should be
the last thing called.

The image viewer can be set as the second, optional field.
The default image viewer is ImageMagick's "display".

Example usage:

  my $naming = $self->naming;
  my $png_file = $naming->{ png };
  $self->display_png_and_exit( $png_file );

=cut

sub display_png_and_exit {
  my $self        = shift;
  my $fn          = $self->naming; 
  my $png_file    = shift || $fn->{ png };
  my $basename = $fn->{ base } || '';

  my $image_viewer = $self->image_viewer || shift;

  my $erroff = ' 2>/dev/null';
  $erroff = '' if $DEBUG;

  my $vcmd;
  if ($image_viewer eq 'display')  {
    my $title = "skullplot";
    # $title .=  ": $basename" if $basename;
    $vcmd = qq{ display -title $title  $png_file $erroff };
  } else {
    $vcmd = qq{ $image_viewer $png_file $erroff };
  }
  exec( $vcmd );
}



=item show_plot_and_exit

The method called by the skullplot.pl script to actually
plot the data from a "data box format" file, using the 
plot_hints.

It's expected that the dbox file (L<input_file>) and the
L<plot_hints> will be defined at object creation, but at
present those settings may be overridden here and given as
first and second arguments.

This should be used at the end of the program (internally 
it does an "exec").

=cut

sub show_plot_and_exit {
  my $self = shift;
  if ($DEBUG) { say "Running show_plot_and_exit: "; $self->dumporama() };

  my $dbox_file = $self->input_file || shift;

  my $naming = $self->naming;

  my $dbox_name = $naming->{ base };
  my $tsv_file  = $naming->{ tsv };
  ($DEBUG) && print "input dbox name: $dbox_name\nintermediate tsv_file: $tsv_file\n";

  # the input from the dbox file output directly to a tsv file 
  my $dbx = Table::BoxFormat->new( input_file  => $dbox_file ); 
  my $data = $dbx->output_to_tsv( $tsv_file ); # also returns a ref to an array of arrays

  my $plot_cols = $self->classify_columns( $data );

  $self->plot_tsv_to_png( $plot_cols ); # Note: uses naming from object

  if ($DEBUG) { say "About to display png: "; $self->dumporama() };
  $self->display_png_and_exit(); 
}



=item classify_columns

Given a reference to the tabular data in the form of an array of arrays,
returns metadata for each column to be used in deciding how to plot 
the data.

Example usage:

  my $plot_cols = $self->classify_columns( $data );


Classify the columns from the tabular data, returning a "fields_metadata" hash ref.

This is a wrapper around a provisional technique to make it easier to swap in 
better ones later.

At present, the metadata fields are:

     x           => $x_field  (( rename indie_x ))
     y           => $y_field
     gb_cats      => [ @gb_cats ]
     dependents_y => [ @dependents_y ]

=cut

sub classify_columns {
  my $self = shift;
  my $data = shift;  

  my $opt         = $self->plot_hints || shift;
  # my $indie_count = $opt->{ indie_count };  

  # use the tsv data to analysis the column types, 
  # determine what to try to plot
  my $dc = Graphics::Skullplot::ClassifyColumns->new( data => $data );  
  my $plot_cols = 
    $dc->classify_columns_simple( $opt );

  return $plot_cols;
}





=item dumporama

Report on state of object fields.

=cut

sub dumporama {
  my $self = shift;
  say "Graphics::Skullplot self: ", Dumper( $self );
  printf "input_file: %s\n"     , $self->input_file;
  # printf "plot_hints: %s\n"     , $self->fryhash( $self->plot_hints );
  printf "plot_hints: %s\n"     , Dumper( $self->plot_hints );
  printf "working_area: %s\n"   , $self->working_area;
  printf "image_viewer: %s\n"   , $self->image_viewer;
  # printf "naming: %s\n"         , $self->fryhash( $self->naming );
  printf "naming: %s\n"         , Dumper( $self->naming );
}



=item fryhash

=cut

sub fryhash {
  my $self = shift;
  my $href = shift;

  my @keys = keys %{ $href };
  my $rep;
  $rep = "\n" if @keys;
  foreach my $k (@keys) {
    my $val = $href->{ $k } || '';
    if( ref $val eq 'HASH') {
      $rep .= $self->fryhash( $val );
    } elsif( ref $val eq 'ARRAY') {
      $rep .= join " ", @{ $val };
    } else {
      $rep .= sprintf "         %25s: %s\n", $k, $val;
    }
  }
  return $rep;
}



=back

=head1 NOTES 

=head2 TODO

=over 

=item * 

Limited to two group by categories (in addition to the x-axis): used with colour & shape
If there's more than 2, fuse them together into a compound, use with colour

=item * 

See R Graphics Cookbook, p.205: setting up the tics and labels.

    $pc .= 'p + scale_x_date';
    $pc .= '';

=item * 

Currently this defaults to viewing images using the "display" program.
Alternately, the builder_image_viewer could scan through a list of 
likely viewers and pick the first that's installed.

=back


=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
16 Nov 2016

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
