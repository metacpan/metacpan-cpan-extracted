package Excel::Template::XLSX;

use strict;
use warnings;
use base 'Excel::Writer::XLSX';
use Excel::Writer::XLSX::Utility;

use version; our $VERSION = version->declare("v1.1.1");

use Archive::Zip;
use Graphics::ColorUtils 'rgb2hls', 'hls2rgb';
use Scalar::Util 'openhandle';
use XML::Twig;

1;    # Return True from module

###############################################################################
sub __podhead {

=for pod

=head1 NAME

Excel-Template-XLSX - Create Excel .xlsx files starting from (one or more) template(s).

=head1 SYNOPSIS

   use Excel::Template::XLSX;
   my ($self, $workbook) = Excel::Template::XLSX->new('perl.xlsx', 'template1.xlsx', 'template2.xlsx', ...);
   $self->parse_template();
   
   # Add a worksheet, ... and anything else you would do with Excel::Writer::XLSX
   $worksheet = $workbook->add_worksheet();

   # Although Excel::Writer::XLSX says the workbook will automatically get 
   # closed during global destruction.  This wrapper around Excel::Writer::XLSX may
   # mess this up, and it is better to specifically close your workbook when you are done.
   $workbook->close();

=head1 DESCRIPTION

This module is a companion to
L<Excel::Writer::XLSX|https://metacpan.org/release/Excel-Writer-XLSX>(EWX), or
if you prefer, a wrapper to that module.  It uses EWX as a base class.  It opens
an existing spreadsheet file (.xlsx format), and also creates a new EWX object.
As it parses the template file(s), it calls EWX methods to re-create the template
contents in the EWX object.

When parsing is complete, the workbook object is left open for the calling perl
script to add additional content.

The purpose of this module is to separate the roles of content/presentation vs
programming in an Excel document, in much the same way that HTML templating
engines work.  A user who is knowledgeable in Excel can create an Excel file for
use as a template, without requiring the skill set of Perl or
Excel::Writer::XLSX. Conversely, the Perl programmer who is creating dynamic
content does not need design skills to layout the presentation in the template.

=head1 WHAT IT CAN DO

   Cell Values (strings, numbers, dates, ... )
   Cell Formulas
   Cell Hyperlinks
   
   Cell Formatting (borders, shading, fonts, font sizes, colors)
   
   Column Widths
   Row Widths
   
   Headers and Footers
   
Simple template variables (via callback) See L</"template_callback">

=head1 WHAT IT CAN NOT DO

   Excel::Template::Excel can not modify Excel files in place!  It is not
   intended to.  Since the parser directly adds content to the EWX workbook object
   as the contents are parsed, both the template, and the output file must
   be open at the same time.  
   
   It may be possible to open the output file to a file handle, and 
   after parsing of the template is complete, write the contents of file
   over the template.  The author has not tried this.
   
   It is not the design of this module to faithfully re-create the entire
   contents of the template file in the EWX output.  If you are using this
   module to rewrite Excel files, you are on your own.

   These items are completely dropped from the output file:

   Images in the Sheet
   Images in Headers/Footers
   Charts
   Shapes
   Themes (gradients, fonts, fills, styles)
   macros
   modules (vba code)

   And probably other things.  See the tests (t directory of the distribution) 
   for examples of what does work.

=head1 SUBROUTINES AND METHODS

=head2 __podhead

Dummy subroutine to allow me to hide this pod documentation when using code
folding in the editor.

=cut

}
###############################################################################
sub new {

=head2 new

Creates a new Excel::Template::XLSX object, and also creates a new
Excel::Writer::XLSX object. A workbook object is created for the output file.

Returns the Template object, and the workbook object.  Workbook object is also
available as $self->{EWX};  If the caller is only expecting a single
return value, then just the $self object is returned.

=cut

   my ( $class, $output_file, @template_files ) = @_;
   my $self = {
      FORMATS        => [],
      HYPERLINKS     => {},
      NEED_PROPS     => 1,
      PRINT_AREA     => {},
      PRINT_TITLES   => {},
      MERGED_RANGES  => {},
      SHARED_STRINGS => [],
      THEMES         => [],
      ZIP            => [],

      template_callback => undef,
   };

   # Create a new Excel workbook
   $self->{EWX} = Excel::Writer::XLSX->new($output_file);
   if ( defined $self->{EWX} ) {
      $self->{DEFAULT_FORMAT} = $self->{EWX}->add_format();
      bless $self, $class;
   }
   else {
      die
          "Can't create new Excel::Writer::XLSX object using file ($output_file) $!";
   }

   foreach my $template_file (@template_files) {
      my $zip = Archive::Zip->new;
      if ( openhandle($template_file) ) {
         bless $template_file, 'IO::File'
             if ref($template_file) eq 'GLOB';    # sigh
         my $status = $zip->readFromFileHandle($template_file);
         unless ( $status == Archive::Zip::AZ_OK ) {
            warn "Can't open filehandle as a zip file, skipping";
            $zip = undef;
         }
      }
      elsif ( !ref($template_file) ) {
         my $status = $zip->read($template_file);
         unless ( $status == Archive::Zip::AZ_OK ) {
						$template_file //= '(undef)';
            warn "Can't open file '$template_file' as a zip file, skipping";
            $zip = undef;
         }
      }
      else {
         warn
             "Argument to 'new' must be a filename or open filehandle.  skipping $template_file";
         $zip = undef;
      }

      # Create a list of template files to add to the workbook
      push @{ $self->{ZIP} }, $zip;
   }
   if (wantarray) {
      return ( $self, $self->{EWX} );
   }
   else {
      return $self;
   }
}
###############################################################################
sub parse_template {

=head2 parse_template

Parses common elements of the Spreadsheet, such as themes, styles, and strings.
These are stored in the main object ($self).

Finds each sheet in the workbook, and initiates parsing of each sheet.

Properties for the created workbook are set from the first template that has
properties.  Properties in subsequent workbooks are ignored.

=cut

   my $self = shift;

   my $remap = {
      title       => 'title',
      subject     => 'subject',
      creator     => 'author',
      keywords    => 'keywords',
      description => 'comments',

      manager  => 'manager',
      company  => 'company',
      category => 'category',
      status   => 'status',
   };

   for my $z ( 0 .. $#{ $self->{ZIP} } ) {
      my $zip = $self->{ZIP}[$z] // next;
      $self->{PRINT_TITLES}   = {};
      $self->{SHARED_STRINGS} = [];
      $self->{FORMATS}        = [];

      my $files = $self->_extract_files($zip);

      my $callback = $self->{template_callback};
      my $call     = ref($callback) eq 'CODE';
      if ( $self->{NEED_PROPS} ) {
         if ( my @core_nodes
            = $files->{core}->find_nodes('//cp:coreProperties') )
         {
            my $core = shift @core_nodes;
            my %hash = map {
               my $prop = $core->first_child( "dc:" . $_ )
                   // $core->first_child( "cp:" . $_ );
               my %pair = ();
               if ($prop) {
                  my $text = $prop->text();
                  $call and $self->$callback( \$text );
                  %pair = ( $remap->{$_}, $text );
               }
               %pair;
            } keys %$remap;
            $self->{EWX}->set_properties(%hash);
            $self->{NEED_PROPS} = 0;
         }
      }

      $self->{THEMES}
          = $self->_parse_themes( ( values %{ $files->{themes} } )[0] );

      $self->_parse_styles( $files->{styles} );
      $self->_parse_shared_strings( $files->{strings} );

      # Defined Names (includes print area, print titles)
      map {
         my $name = $_->att('name') // '';
         my $address = $_->text();

# Print Titles (may contain none, one, or both.  Delimited by comma if both supplied)
# e.g. Title_Page!$A:$A
         if ( $name eq '_xlnm.Print_Titles' ) {
            my @title = split( ',', $address );
            foreach (@title) {
               my ( $sheet_name, $range ) = split('!');
               push @{ $self->{PRINT_TITLES}{$sheet_name} }, $range;
            }

            # Print Area (Save it until sheets are processed)
         }
         elsif ( $name eq '_xlnm.Print_Area' ) {
            my @title = split( ',', $address );
            my ( $sheet_name, $range ) = split( '!', $address );
            $self->{PRINT_AREA}{$sheet_name} = $range;
         }
         else {
            $self->{EWX}->define_name( $name, $address );
         }
      } $files->{workbook}->find_nodes('//definedNames/definedName');

      # Sheets: Add a worksheet for each sheet in workbook
      # Rename sheet if template(s) already has a sheet by that name
      map {
         my $name = $_->att('name');
         my $test = $name;
         for ( my $i = 1; ; $i++ ) {
            last unless $self->{EWX}->get_worksheet_by_name($test);
            $test = $name . "($i)";
         }
         my $sheet = $self->{EWX}->add_worksheet($test);

         my $range = $self->{PRINT_AREA}{$name};
         $sheet->print_area($range) if $range;

         foreach my $range ( @{ $self->{PRINT_TITLES}{$name} } ) {

            if ($range =~ m/[A-Za-z]/) { # Column Range like $A:$A
              $sheet->repeat_columns( $range ) 
            } else {
              # Row Range like $1:$1
              $range =~ s/\$//g;
              my ($first, $last) = split('\:', $range);
              $sheet->repeat_rows( --$first, --$last );
           }
         }

         # Parse the contents of the sheet
         my $idx = $_->att('r:id');
         $self->_parse_sheet( $sheet, $files->{sheets}{$idx} );
      } $files->{workbook}->find_nodes('//sheets/sheet');
      $self->{ZIP}[$z] = undef;
   }
}
###############################################################################
sub template_callback {

=head2 template_callback

Place holder method for a callback routine to modify the content of the template
before being written to the output spreadsheet.

This callback is activated for all shared string (both plain and rich text
strings), and also for header/footer text.

The callback is supplied with the two parameters: The object name (since this is
a method), and the text to be processed. This is passed as a reference to single
scalar.

This method is called numerous times during processing (e.g. once for each
unique string in the spreadsheet, so the user is advised to keep it efficient.

This callback approach does not force any particular templating system on the
user.  They are free to use whatever system they choose.

Note that templating can only do simple scalars.  Complex templating (if-then-
else, loops, etc) do not make sense in that the callback is supplied with the
contents of a single cell.  Having said that, remember that the full power of
Excel::Writer::XLSX is available to the user to modify the template after it is
processed.

   # A snippet of code to replace [% template %] in the 
   # template spreadsheet with 'Output'

   my ($self, $wbk) = Excel::Template::XLSX->new($output_xlsx, $template_xlsx);

   use Template::Tiny;
   my $template = Template::Tiny->new( TRIM => 1 );
   $self->{template_callback} = sub {
      my ($self, $textref) = @_;
      $template->process($textref, { template => 'Output' }, $textref );
   };

   $self->parse_template();

=cut

   my $self = shift;
   my ($text) = @_;
}
###############################################################################
sub _apply_tint {

=head2 _apply_tint

Applies tinting to a color object, if the tint attribute is encountered in
parsing.

=cut

   my $self = shift;
   my ( $color, $tint ) = @_;

   my ( $r, $g, $b ) = map { oct("0x$_") } $color =~ /#(..)(..)(..)/;
   my ( $h, $l, $s ) = rgb2hls( $r, $g, $b );

   if ( $tint < 0 ) {
      $l = $l * ( 1.0 + $tint );
   }
   else {
      $l = $l * ( 1.0 - $tint ) + ( 1.0 - 1.0 * ( 1.0 - $tint ) );
   }

   return scalar hls2rgb( $h, $l, $s );
}
###############################################################################
sub _base_path_for {

=head2 _base_path_for

Manipulates the path to a member in the zip file, to find the associated
rels file.

=cut

   my $self = shift;
   my ($file) = @_;

   my @path = split '/', $file;
   pop @path;

   return join( '/', @path ) . '/';
}
###############################################################################
sub _cell_to_row_col {

=head2 _cell_to_row_col

Converts an A1 style cell reference to a row and column index.

=cut

   my $self = shift;
   my $cell = shift;

   my ( $col, $row ) = $cell =~ /([A-Z]+)([0-9]+)/;

   my $ncol = 0;
   for my $char ( split //, $col ) {
      $ncol *= 26;
      $ncol += ord($char) - ord('A') + 1;
   }
   $ncol = $ncol - 1;
   my $nrow = $row - 1;
   return ( $nrow, $ncol );
}
###############################################################################
sub _color {

=head2 _color

Parses color element (rgb, index, theme, and tint)

=cut

   my $self = shift;
   my ( $color_node, $fill ) = @_;

   my $themes = $self->{THEMES};
   my $color;
   if ( $color_node && !$color_node->att('auto') ) {
      my $rgb   = $color_node->att('rgb');
      my $theme = $color_node->att('theme');
      my $index = $color_node->att('indexed');
      my $tint  = $color_node->att('tint');

# see https://rt.cpan.org/Public/Bug/Display.html?id=93065 (still needed for XLSX??)
# defined $index and $color = ($fill && $index == 64) ? '#FFFFFF' : $index;
      $rgb and $color = '#' . substr( $rgb, 2, 6 );
      defined $theme and $color = '#' . $themes->{Color}[$theme];
      $tint and $color = $self->_apply_tint( $color, $tint );
   }
   return $color;
}
###############################################################################
sub _extract_files {

=head2 _extract_files

Called by parse_template to fetch the xml strings from the zip file.  XML
strings are parsed, except for worksheets.  Individual worksheets are
parsed separately.

=cut

   my $self = shift;
   my ($zip) = @_;

   my $type_base
       = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

   my $rels = $self->_parse_xml( $zip, $self->_rels_for('') );

   my $node    = qq<//Relationship[\@Type="$type_base/officeDocument"]>;
   my $wb_name = ( $rels->find_nodes($node) )[0]->att('Target');
   my $wb_xml  = $self->_parse_xml( $zip, $wb_name );

   my $path_base = $self->_base_path_for($wb_name);
   my $wb_rels = $self->_parse_xml( $zip, $self->_rels_for($wb_name) );

   my $string_xpath = qq<//Relationship[\@Type="$type_base/sharedStrings"]>;
   my ($strings_xml) = map { 
      $zip->memberNamed( $path_base . $_->att('Target') )->contents 
   } $wb_rels->find_nodes($string_xpath);

   my $style_xpath = qq<//Relationship[\@Type="$type_base/styles"]>;
   my $style_target
       = ( $wb_rels->find_nodes($style_xpath) )[0]->att('Target');
   my $styles_xml = $self->_parse_xml( $zip, $path_base . $style_target );

   my %sheet_rels;
   my $wks_xpath = qq<//Relationship[\@Type="$type_base/worksheet"]>;
   my %worksheet_xml = map {

      my $sheet_file = $path_base . $_->att('Target');
      my $rels_file  = $self->_rels_for($sheet_file);
      my $sheet_rels = '';
      if ( $zip->memberNamed($rels_file) ) {
         $sheet_rels = $self->_parse_xml( $zip, $rels_file );
      }

      if ( my $contents = $zip->memberNamed($sheet_file)->contents ) {
         ( $_->att('Id') => { 'xml' => $contents, 'rels' => $sheet_rels } );
      }
      
   } $wb_rels->find_nodes($wks_xpath);

   my %themes_xml = map {
      $_->att('Id') =>
          $self->_parse_xml( $zip, $path_base . $_->att('Target') )
   } $wb_rels->find_nodes(qq<//Relationship[\@Type="$type_base/theme"]>);

   my $core_base
       = 'http://schemas.openxmlformats.org/package/2006/relationships/metadata';
   my $core_full = qq<//Relationship[\@Type="$core_base/core-properties"]>;
   my $core_name = ( $rels->find_nodes($core_full) )[0]->att('Target');
   my $core_xml  = $self->_parse_xml( $zip, $core_name );

   return {
      workbook => $wb_xml,
      styles   => $styles_xml,
      sheets   => \%worksheet_xml,
      themes   => \%themes_xml,
      core     => $core_xml,
      ( $strings_xml ? ( strings => $strings_xml ) : () ),
   };
}
###############################################################################
sub _parse_alignment {

=head2 _parse_alignment

Parses horizontal and vertical cell alignments in a sheet.

=cut

   my $self = shift;
   my ($node) = @_;

   my %align_map = (
      horizontal   => 'align',
      vertical     => 'valign',
      textRotation => 'rotation',
      indent       => 'indent',
      wrapText     => 'text_wrap',
      shrinkToFit  => 'shrink',
   );
   my %align = ();
   if ( my $alignment = $node->first_child('alignment') ) {
      map {
         my $v = $alignment->att($_);
         if ( defined $v ) {
            $v = 'vcenter' if ( $_ eq 'vertical' ) and ( $v eq 'center' );
            $align{ $align_map{$_} } = $v;
         }
      } keys %align_map;
   }
   return %align;
}
###############################################################################
sub _parse_borders {

=head2 _parse_borders

Parses cell border and diagonal border styles.  Called from _parse_styles.
Returns an array of border styles, each one as a hash.

=cut

   my $self = shift;
   my ($styles) = @_;

   my $borders    = [];
   my %border_map = (
      dashDot          => 9,
      dashDotDot       => 11,
      dashed           => 3,
      dotted           => 4,
      double           => 6,
      hair             => 7,
      medium           => 2,
      mediumDashDot    => 10,
      mediumDashDotDot => 12,
      mediumDashed     => 8,
      none             => 0,
      slantDashDot     => 13,
      thick            => 5,
      thin             => 1,
   );
   push @$borders, map {
      my $border = $_;

      # XXX specs say "begin" and "end" rather than "left" and "right",
      # but... that's not what seems to be in the file itself (sigh)

      my %colors = ();
      map {
         my $color
             = $self->_color(
            $border->first_child($_)->first_child('color') );
         $colors{ $_ . '_color' } = $color if $color;
      } qw(left right top bottom);

      my %types = ();
      map {
         my $style = $border->first_child($_)->att('style');
         $types{$_} = $border_map{$style} if $style;
      } qw(left right top bottom);

      my %diag = ();
      my $down = $border->att('diagonalDown') // 0;
      my $up   = $border->att('diagonalUp') // 0;
      $diag{'diag_type'} = 2 * $down + $up if $down + $up;
      my $dborder = $border->first_child('diagonal')->att('style');
      $diag{'diag_border'} = $border_map{$dborder} if $dborder;
      my $dcolor = $border->first_child('diagonal')->first_child('color');
      $diag{'diag_color'} = $self->_color($dcolor) if $dcolor;

      my $border_ref = { %colors, %types, %diag };
#      use Mojo::Util qw(dumper);
# warn dumper ($border_ref);
#    $border_ref;

   } $styles->find_nodes('//borders/border');
   return $borders;
}
###############################################################################
sub _parse_fills {

=head2 _parse_fills

Parses styles for cell fills (pattern, foreground and background colors.
horizontal and horizontal and vertical cell alignments in a sheet.

Gradients are parsed, but since EWX does not support gradients, a
pattern is substituted.

=cut

   my $self     = shift;
   my ($styles) = @_;
   my %fill_map = (
      darkDown        => 7,
      darkGray        => 3,
      darkGrid        => 9,
      darkHorizontal  => 5,
      darkTrellis     => 10,
      darkUp          => 8,
      darkVertical    => 6,
      gray0625        => 18,
      gray125         => 17,
      lightDown       => 13,
      lightGray       => 4,
      lightGrid       => 15,
      lightHorizontal => 11,
      lightTrellis    => 16,
      lightUp         => 14,
      lightVertical   => 12,
      mediumGray      => 2,
      none            => 0,
      solid           => 1,
   );

   # Pattern Fills /    # Gradient Fills
   # EWX does not support Gradient fills (yet??)
   # so, substitute a pattern fill to keep indices aligned
   my $fills = [];
   push @$fills, map {
      my ( $fill, @color );
      my $pat = $_->first_child('patternFill');
      if ($pat) {
         for (qw[fg bg]) {
            my $fgbg = $self->_color( $pat->first_child("${_}Color"), 1 );
            push @color, ( "${_}_color", $fgbg ) if $fgbg;
         }
         $fill = { pattern => $fill_map{ $pat->att('patternType') }, @color };
      }
      my $gradient = $_->first_child('gradientFill');
      if ($gradient) {
         my @stop_colors = $gradient->find_nodes('stop/color');
         my $fg          = $self->_color( $stop_colors[0], 1 );
         my $bg          = $self->_color( $stop_colors[1], 1 );
         my %hfg         = ( 'fg_color' => ( $fg // 'white' ) );
         my %hbg         = ( 'bg_color' => ( $bg // 'black' ) );

         ### ?? Create a lightGrid pattern in place of a gradient for now
         $fill = { pattern => $fill_map{'lightGrid'}, %hfg, %hbg };
      }
      $fill;
   } $styles->find_nodes('//fills/fill');
   $fills;
}
###############################################################################
sub _parse_fonts {

=head2 _parse_fonts

Parses font information (font name, size, super/sub scripts, alignment
colors, underline, bold, italic, and strikeout attributes).

=cut

   my $self = shift;
   my ( $styles, $xpath ) = @_;
   $xpath //= '//fonts/font';

   my $fonts = [];
   @$fonts = map {

      my $u    = $_->first_child('u');
      my $vert = $_->first_child('vertAlign');
      my $font;

      my $size = $_->first_child('sz')->att('val');
      $font->{'size'} = $size if $size;

      # XXX if color tag is missing is it black?? '#000000'
      my $color = $_->first_child('color');
      $font->{'color'} = $self->_color($color) if $color;

      my $script_map = {
         'superscript' => 1,
         'subscript'   => 2,
      };

      if ( defined $vert ) {
         my $script = $vert->att('val');
         $font->{'font_script'} = $script_map->{$script} if $script;
      }

      my $u_map = {
         'single'           => 1,
         'double'           => 2,
         'singleAccounting' => 33,
         'doubleAccounting' => 34,
      };
      if ( defined $u ) {

         # XXX sometimes style xml files can contain just <u/> with no
         # val attribute. i think this means single underline, but not sure
         my $underline = $u->att('val') // 'single';
         $font->{'underline'} = $u_map->{$underline} if $underline;
      }

      my $font_name = $_->first_child('name');
      $font->{'font'} = $font_name->att('val') if $font_name;

      # Alternate for rich strings (embedded font)
      my $rFont = $_->first_child('rFont');
      $font->{'font'} = $rFont->att('val') if $rFont;

      my $bold = $_->first_child('b');
      $font->{'bold'} = 1 if $bold;

      my $italic = $_->first_child('i');
      $font->{'italic'} = 1 if $italic;

      my $strike = $_->first_child('strike');
      $font->{'font_strikeout'} = 1 if $strike;

      $font;
   } $styles->find_nodes($xpath);
   return $fonts;
}
###############################################################################
sub _parse_numbers {

=head2 _parse_numbers

Parses styles for cell number formats (financial, decimal, exponential, date-time, ...)

=cut

   my $self          = shift;
   my ($styles)      = @_;
   my $number_format = { 0 => {} };
   map {
      my $id = $_->att('numFmtId') // 0;

# defaults are from
#http://social.msdn.microsoft.com/Forums/en-US/oxmlsdk/thread/e27aaf16-b900-4654-8210-83c5774a179c
# Defaults do not need to be re-created.
      my $code = $_->att('formatCode') // $id;
      $number_format->{$id} = { num_format => $code } if $id;
   } $styles->find_nodes('//numFmts/numFmt');
   return $number_format;
}
###############################################################################
sub _parse_protection {

=head2 _parse_protection

Parses locked and hidden attributes for a cell. These are only
useful if the worksheet is locked.  

This module does not lock the workbook or the worksheet.

=cut

   my $self       = shift;
   my ($node)     = @_;
   my @protection = qw(locked hidden);
   my %prot       = ();
   if ( my $protection = $_->first_child('protection') ) {
      map {
         my $v = $protection->att($_);
         $prot{$_} = $v if defined $v;
      } @protection;
   }
   return %prot;
}
###############################################################################
sub _parse_shared_strings {

=head2 _parse_shared_strings

Parses the shared strings file.  Excel does not directly store
string values with the cell, but stores an index into the shared
strings table instead, to save memory, if a string value is 
referenced more than once.  Shared strings also contain
formatting if multiple formats are applied within a cell (See
write_rich_string in EWX.

=cut

   my $self = shift;
   my ($strings) = @_;

   return unless $strings;
   my $xml = XML::Twig->new(
      twig_handlers => {
         'si' => sub {
            my ( $twig, $si ) = @_;

            my $callback = $self->{template_callback};
            my $call     = ref($callback) eq 'CODE';

            # plain text strings
            my $t = $si->first_child('t');
            if ($t) {
               my $text = $t->text();
               $call and $self->$callback( \$text );
               push @{ $self->{SHARED_STRINGS} }, $text;
            }

            # rich text strings;  String item (si) with multiple
            # text elements, with optional formatting
            my $rich = [];
            for my $r ( $si->find_nodes('r') ) {
               my $text = $r->first_child('t')->text();
               $call and $self->$callback( \$text );
               my $rPr = $r->first_child('rPr');

               if ($rPr) {
                  my $xml    = $r->first_child('rPr')->outer_xml();
                  my $twig   = XML::Twig->parse($xml);
                  my $fonts  = $self->_parse_fonts( $twig, '//rPr' );
                  my $format = $self->{EWX}->add_format( %{ $fonts->[0] } );
                  push @$rich, $format, $text;
               }
               else {
                  push @$rich, $text;
               }
            }
            push( @{ $self->{SHARED_STRINGS} }, $rich ) if scalar(@$rich);
            $twig->purge;
         }
      }
   );    # } twig_handlers ) new
   $xml->parse($strings);
}
###############################################################################
sub _parse_sheet {

=head2 _parse_sheet

Parses an individual worksheet.  This is done in two passes.
See _parse_sheet_pass1 and _parse_sheet_pass2 for what elements are
parsed.  This is necessary because the parse order of XML::Twig callbacks
are in the wrong order for some sheet information (header/footer information,
hyperlinks, and merged cells).

=cut

   my $self = shift;
   my ( $sheet, $sheet_file ) = @_;

   # Hyperlinks are local to each sheet
   $self->{HYPERLINKS} = {};
   my $pass1
       = XML::Twig->new( twig_roots => $self->_parse_sheet_pass1($sheet) );
   $pass1->parse( $sheet_file->{xml} );

   # Half time show - track down the URLs for hyperlinks found in pass 1
   while ( my ( $a1, $rid ) = each %{ $self->{HYPERLINKS} } ) {
      my $xpath = qq<//Relationship[\@Id="$rid"]>;
      my $url   = ( $sheet_file->{rels}->find_nodes($xpath) )[0];
      if ($url) {
         my $target = $url->att('Target');
         my $mode   = lc( $url->att('TargetMode') );
         $self->{HYPERLINKS}{$a1} = "$target";
      }
   }

# 2nd pass: cell/row building is dependent on having parsed the merge definitions
# beforehand.  Also header/footer margins must be parsed before setting header/footer
   my $pass2
       = XML::Twig->new( twig_roots => $self->_parse_sheet_pass2($sheet) );
   $pass2->parse( $sheet_file->{xml} );
}
###############################################################################
sub _parse_sheet_pass1 {

=head2 _parse_sheet_pass1

Parses some elements in a worksheet ( pageMargins, headerFooter,
hyperlinks, pageSetup, Merged Cells, Sheet Formatting Row and Column
heights, Sheet selection, and Tab Color)

=cut

   my $self = shift;
   my ($sheet) = @_;

   my $default_row_height   = 15;
   my $default_column_width = 10;
   my %hf_margin;

   return {
      'pageMargins' => sub {
         my ( $twig, $margin ) = @_;
         map {
            my $method = "set_margin_" . $_;
            $sheet->$method( $margin->att($_) // 0 );
         } qw( left right top bottom );

         # Capture header/footer margin, for use with headerFooter callback
         $hf_margin{Header} = $margin->att('header');
         $hf_margin{Footer} = $margin->att('footer');
         $twig->purge;
      },

      # Headers/Footers
      'headerFooter' => sub {
         my ( $twig, $hf ) = @_;

         my $callback = $self->{template_callback};
         my $call     = ref($callback) eq 'CODE';
         for (qw[Header Footer]) {
            my $child = $hf->first_child( 'odd' . $_ );
            my $text = $child ? $child->text() : '';
            $call and $self->$callback( \$text );
            my $method = 'set_' . lc($_);
            $sheet->$method( $text, $hf_margin{$_} );
         }

         $twig->purge;
      },

      # Hyperlinks
      'hyperlinks/hyperlink ' => sub {
         my ( $twig, $link ) = @_;
         my $a1 = $link->att('ref');
         $self->{HYPERLINKS}{$a1} = $link->att('r:id');
         $twig->purge;
      },

      # Paper/page setup
      'pageSetup' => sub {
         my ( $twig, $setup ) = @_;
         my %lookup = (
            orientation     => => 'set_portrait',
            firstPageNumber => 'set_start_page',
            scale           => 'set_print_scale',
            paperSize       => 'set_paper'

                #           horizontalDpi ??
                #           verticalDpi
         );

         my @page
             = qw(scale orientation horizontalDpi verticalDpi paperSize firstPageNumber scale);
         foreach (@page) {

            # Ignore if we do not have a EWX method for this attribute
            my $method = $lookup{$_} // next;

            # Ignore if no value defined for this attribute
            next unless my $set = $setup->att($_);

            # Special case; no generic method to set portrait/landscape
            $method = 'set_landscape' if $set eq 'landscape';
            $sheet->$method($set);
         }

         $twig->purge;
      },

      # Merged cells (Create the ranges: content will be added later)
      'mergeCells/mergeCell' => sub {
         my ( $twig, $merge_area ) = @_;

         if ( my $ref = $merge_area->att('ref') ) {
            my ( $topleft, $bottomright ) = $ref =~ /([^:]+):([^:]+)/;
            # my ( $tr, $lc )               = $self->_cell_to_row_col($topleft);
            # my ( $br, $rc )               = $self->_cell_to_row_col($bottomright);

            # Merged Ranges/Areas: save the address for pass 2.
            # cells within the merged range will be processed with 
            # merge_range_type(), instead of write()
            $self->{MERGED_RANGES}{$sheet->{_index}}{$topleft} = $ref;
         }
         $twig->purge;
      },

      # Default row height
      'sheetFormatPr' => sub {
         my ( $twig, $format ) = @_;
         $default_row_height   //= $format->att('defaultRowHeight');
         $default_column_width //= $format->att('baseColWidth');
         $sheet->set_default_row($default_row_height);
         $twig->purge;
      },

      'col' => sub {
         my ( $twig, $col ) = @_;

         for my $ci ( $col->att('min') .. $col->att('max') ) {
            #set_column($first,$last,$width,$fmt,$hide,$level,$collapsed )
            $sheet->set_column( $ci - 1, $ci - 1, $col->att('width') );
            #?? just sets width, not $col->att('style')
         }
         $twig->purge;
      },

      'row' => sub {
         my ( $twig, $row ) = @_;

         # ?? just sets row height.  No formatting yet
         # set_row( $row, $height, $format, $hidden, $level, $collapsed )
         $sheet->set_row( $row->att('r') - 1, $row->att('ht') );
         $twig->purge;
      },

      'sheetView/selection' => sub {
         my ( $twig, $selection ) = @_;
         my $range = $selection->att('sqref')
             // $selection->att('activeCell') // 'A1';
         $sheet->set_selection($range);
         $twig->purge;
      },

      'sheetPr/tabColor' => sub {
         my ( $twig, $tab_color ) = @_;
         $sheet->set_tab_color( $tab_color->att('rgb') );
         $twig->purge;
      }

       }    # return hashref
}
###############################################################################
sub _parse_sheet_pass2 {

=head2 _parse_sheet_pass2

Parses cell contents (first by row, then by column).  Cells can contain
inline strings, string references, direct string values, formulas,
and hyperlinks.  Each cell may also contain formatting information.  
The format is in an index to formatting for borders, shading, alignment,
font, and number formats.

=cut

   my $self = shift;
   my ($sheet) = @_;

   return {
      'sheetData/row' => sub {
         my ( $twig, $row_elt ) = @_;
         my $sheet_idx = $sheet->{_index};
         for my $cell ( $row_elt->children('c') ) {
         
            my $string_index = 0;
            my $a1           = $cell->att('r');           # Cell Address
            my $t            = $cell->att('t') || 'n';    # Cell Type
            my $s            = $cell->att('s');           # Cell Format Index
            my $val_xml
                = $t eq 'inlineStr'
                ? $cell->first_child('is')->first_child('t')
                : $cell->first_child('v');
            my $val = $val_xml ? $val_xml->text() : undef;


            my $format_idx = $s // 0;
            my $format = $self->{FORMATS}[$format_idx];

            # Formatted cell, no contents
            if ( !defined($val) ) {
               $sheet->write_blank($a1, $format);
               next;
            }

            if ( $t eq 's' ) {
               $string_index = $val;
               $val          = $self->{SHARED_STRINGS}[$val];

               my $is_array = ref($val) eq 'ARRAY';
               my @aval = $is_array ? @$val : ($val);
               if ( my $ref = $self->{MERGED_RANGES}{$sheet_idx}{$a1} ) {
                  my $type = $is_array ? 'rich_string' : 'string';
                  $sheet->merge_range_type($type, $ref, @aval, $format );
                  next;
               }

               # Special case for multiple formats in a cell
               # see _parse_shared_strings for rPr nodes
               if ( $is_array ) {
                  $sheet->write_rich_string( $a1, @aval );
                  next;
               }
               if ( my $url = $self->{HYPERLINKS}{$a1} ) {
                  $sheet->write_url( $a1, $url, $format, $val );
                  next;
               }
               $sheet->write_string( $a1, $val, $format );
               next;
            }

            # In-line string (not seen in practice)
            elsif ( $t eq 'str' ) {
               $val = '=' . $cell->first_child('f')->text();
            }

            # Formulas
            elsif ( $t eq 'n' ) {
               if ( my $form_child = $cell->first_child('f') ) {
                  my $is_array = $form_child->att('t');
                  my $ref      = $form_child->att('ref');
                  my $formula  = $form_child->text() // q[="No Formula Found"];
                  if ($is_array and $ref) {
                     $sheet->write_array_formula( $ref, "=${formula}", $format, $val );
                  }
                  else {
                     #if ( my $ref = $self->{MERGED_RANGES}{$a1} ) {
                     if ( my $ref = $self->{MERGED_RANGES}{$sheet_idx}{$a1} ) {
                       $sheet->merge_range_type('formula', $ref, "=${formula}", $format, $val);
                     } else {
                        $sheet->write_formula( $a1, "=${formula}", $format, $val );
                     }
                  }
                  next;
               }

            }
            elsif ( $t eq 'b' ) {
               $val = $val ? "TRUE" : "FALSE";
            }
            elsif ( $t eq 'e' ) {
            }
            elsif ( $t eq 'str' || $t eq 'inlineStr' ) {
            }
            else {
               warn "unimplemented type $t found in cell $a1";    # XXX
            }

            $sheet->write( $a1, $val, $format );
         }

         $twig->purge;
      }
   };
}
###############################################################################
sub _parse_styles {

=head2 _parse_styles

Parses style information.  
Parses number formats directly.  Calls subroutines to parse 
fonts, fills, and borders, alignment, and protection.  

Finally, parses Cell Xfs elements to Combine fonts, borders, number formats,
alignment, patterns, into a single format specification.

Calls EWX add_formats to create a format, and stores the format information
in a FORMAT array within the object.

=cut

   my $self = shift;
   my ($styles) = @_;

   # Number Formats
   my $numfmt = $self->_parse_numbers($styles);

   # Fonts / Fills / Borders
   my $fonts   = $self->_parse_fonts( $styles, '//fonts/font' );
   my $fills   = $self->_parse_fills($styles);
   my $borders = $self->_parse_borders($styles);

# Cell Xfs
#  Combine fonts, borders, number formats, alignment, patterns, into a single format spec
   map {
      # Also has applyAlignment property, which we do not examine
      # same for ApplyFont, ApplyBorder ApplyProtection

      my %halign = $self->_parse_alignment($_);
      my %hprot  = $self->_parse_protection($_);
      my %hfont  = %{ $fonts->[ $_->att('fontId') // 0 ] };

      my $numFmtId = $_->att('numFmtId') // 0;
      # Use custom format, or built-in if custom not found
      my $ref = $numfmt->{$numFmtId} // { num_format => $numFmtId };
      my %hnumfmt = %$ref;

      my %hbord = %{ $borders->[ $_->att('borderId') // 0 ] };
      my %hfill = %{ $fills->[ $_->att('fillId')     // 0 ] };

      my $fmt
          = $self->{EWX}
          ->add_format( %hfont, %hnumfmt, %hbord, %halign, %hprot, %hfill );
      push @{ $self->{FORMATS} }, $fmt;
   } $styles->find_nodes('//cellXfs/xf');
}
###############################################################################
sub _parse_themes {

=head2 _parse_themes

Parses theme information.  Some color settings are referenced by an 
index to the theme.

=cut

   my $self = shift;
   my ($themes) = @_;

   return {} unless $themes;

   my @color
       = map { $_->name eq 'a:sysClr' ? $_->att('lastClr') : $_->att('val') }
       $themes->find_nodes('//a:clrScheme/*/*');

# this shouldn't be necessary, but the documentation is wrong here
# see http://stackoverflow.com/questions/2760976/theme-confusion-in-spreadsheetml
   ( $color[0], $color[1] ) = ( $color[1], $color[0] );
   ( $color[2], $color[3] ) = ( $color[3], $color[2] );

   return { Color => \@color };
}
###############################################################################
sub _parse_xml {

=head2 _parse_xml

Low level subroutine to parse an entire member of a zip file. Used
for small files, such as xxx.xml.rels, where the entire file is parsed.

For larger files, XML::Twig::twig_handlers are used.

=cut

   my $self = shift;
   my ( $zip, $subfile ) = @_;

   my $member = $zip->memberNamed($subfile);
   die "no subfile named $subfile" unless $member;

   my $xml = XML::Twig->new;
   $xml->parse( scalar $member->contents );
   return $xml;
}
###############################################################################
sub _rels_for {

=head2 _rels_for

Returns the .rels file name for a sibling workbook or worksheet.

=cut

   my $self = shift;
   my ($file) = @_;

   my @path = split '/', $file;
   my $name = pop @path;
   $name = '' unless defined $name;
   push @path, '_rels';
   push @path, "$name.rels";

   return join '/', @path;
}
###############################################################################
sub zzpodtail {

=for pod

=head2 zzpodtail

Dummy subroutine to allow me to hide pod documentation when using code
folding in the editor.

=head1 INSTALLATION

   Install with CPAN
   
      cpan Excel::Template::XLSX

   or, use the standard Unix style installation.
 
   Unzip and untar the module as follows:
 
      tar -zxvf Excel::Template::XLSX-nnn.tar.gz
 
   The module can be installed using the standard Perl procedure:
 
      perl Makefile.PL
      make
      make test
      make install    # As sudo/root

=head1 BUGS

=over 4

=item Large spreadsheets may cause segfaults on perl 5.14 and earlier

This module internally uses XML::Twig, which makes it potentially subject to
L<Bug #71636 for XML-Twig: Segfault with medium-sized document|https://rt.cpan.org/Public/Bug/Display.html?id=71636>
on perl versions 5.14 and below (the underlying bug with perl weak references
was fixed in perl 5.15.5). The larger and more complex the spreadsheet, the
more likely to be affected, but the actual size at which it segfaults is
platform dependent. On a 64-bit perl with 7.6gb memory, it was seen on
spreadsheets about 300mb and above. You can work around this adding
C<XML::Twig::_set_weakrefs(0)> to your code before parsing the spreadsheet,
although this may have other consequences such as memory leaks.

Please report any bugs to GitHub Issues at
L<https://github.com/davidsclarke/Excel-Template-XLSX/issues>.

=back

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Excel::Template::XLSX

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Excel-Template-XLSX>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Excel-Template-XLSX>

=item * Github

L<https://github.com/davidsclarke/Excel-Template-XLSX>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Excel-Template-XLSX>

=back

=head1 DEBUGGING TIPS

Using the Perl debugger gets complicated because of XML::Twig.  The objects
created by XML::Twig are HUGE.  Also,  stepping through the code often results
in exceeding a stack depth of >100.  The author found it helpful to take
advantage of the simplify() method in XML::Twig when using the debugger 'x' 
command to examine variables.

   x $node->simplify()
   
Also, it is helpful to use the 'c' command to jump over XML::Twig subroutine calls and callbacks.

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 TO DO

   Worksheet Activation
   Table Formatting/Styles
   Calculation Mode
   
=head1 REPOSITORY

The Excel::Template::XLSX source code is hosted on github:
L<http://github.com/davidsclarke/Excel-Template-xlsx>.

=head1 SEE ALSO

   Excel::Writer::XLSX
   
   This module does not provide much documentation on the capabilites of methods
   for creating Excel content.  The documentation provided with EWX is excellent,
   and also has numerous examples included.

   Spreadsheet::ParseXLSX
   
   Although this module does not use Spreadsheet::ParseXLSX, the parsing and 
   comments regarding issues involved with parsing spreadsheets came from this module.

   XML::Twig and Archive::Zip
   
   Excel .xlsx files are zippped .xml files.  These two modules are used to 
   unzip the .xlsx file, extract the members, and parse the relative portions
   of the .xml files inside.

=head1 ACKNOWLEDGEMENTS

This module leverages the methods in L<Excel::Writer::XLSX|https://metacpan.org/release/Excel-Writer-XLSX>, maintained by L<John McNamara|https://metacpan.org/author/JMCNAMARA>
to recreate the template.

The parser was developed using L<Spreadsheet::ParseXLSX|https://metacpan.org/release/Spreadsheet-ParseXLSX> as a starting point, maintained by L<Jesse Luehrs|https://metacpan.org/author/DOY>. 
This parser calls methods in EWX directly when a token is resolved rather than building
up an object representing the parsed content.

=head1 LICENSE AND COPYRIGHT

Either the Perl Artistic Licence L<http://dev.perl.org/licenses/artistic.html>
or the GPL L<http://www.opensource.org/licenses/gpl-license.php>.

AUTHOR

   David Clarke dclarke@cpan.org

=cut

}

