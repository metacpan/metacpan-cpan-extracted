package HTML::TableTiler ;
$VERSION = 1.21 ;
use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use 5.005
; use Carp
; use HTML::PullParser 1.0
; use IO::Util 1.2
; require Exporter 
; @HTML::TableTiler::ISA = qw| Exporter |
; @HTML::TableTiler::EXPORT_OK = qw| tile_table |

; BEGIN
   { *PULL  = sub () { 'PULL' }
   ; *TILE  = sub () { 'TILE' }
   ; *TRIM  = sub () { 'TRIM' }
   ; *TRUE  = sub () { 1 }
   ; *FALSE = sub () { 0 }
   ; *RESET = sub () { 0 }
   }

; sub new
   { my $c = shift
   ; my $t = shift || \ '<table><tr><td></td></tr></table>'
   ; $t = IO::Util::slurp($t)
          unless ref $t eq 'SCALAR'
   ; $$t or  croak 'The tile content is empty'
   ; my $s = _parse_table($t)
   ; bless $s, $c
   }

; sub _parse_table
   { my ( $content ) = shift
   ; my ( $start
        , $Hrows
        , $end
        )
        = $$content =~ m| ^
                         (.*?)                    # start
                         ( <TR[^>]*?> .* </TR> )  # Hrows
                         (.*)                     # end
                         $
                       |xsi
   ; my ( $p
        , $rows
        , $ignore
        )
   ; $Hrows or croak 'The tile does not contain any "<tr>...</tr>" area'
   ; eval
      { local $SIG{__DIE__}
      ; $p = HTML::PullParser->new( doc   => $Hrows
                                  , start => 'tag, text',
                                  , end   => 'tag, text'
                                  )
      }
   ; if ($@)
      { croak "Problem with the HTML parser: $@"
      }
   ; ( my $ri
     = my $di
     = my $td
     = my $in_tr
     = my $in_td
     = RESET
     )
   ; my $err = sub
                { croak "Unespected HTML tag $_[0] found in the tile"
                }
   ; while ( my $tok = $p->get_token )
      { my ( $tag, $text ) = @$tok
      ; if ( $tag eq 'tr' )
         { ( not $in_tr and not $in_td ) or $err->($text)
         ; $$rows[$ri]{Srow} = $text
         ; $in_tr = TRUE
         }
        elsif ( $tag eq '/tr')
         { ( $in_tr and not $in_td) or $err->($text)
         ; $$rows[$ri++]{Erow} = $text
         ; $in_tr = FALSE
         ; $di    = FALSE
         }
        elsif ( $tag eq 'td' )
         { ($in_tr and not $in_td) or $err->($text)
         ; $$rows[$ri]{cells}[$di]{Scell} = $text
         ; $in_td = TRUE
         }
        elsif ( $tag eq '/td' )
         { ($in_tr and $in_td) or $err->($text)
         ; $$rows[$ri]{cells}[$di++]{Ecell} .= $text
         ; $in_td = FALSE
         ; $td++
         }
        elsif ( $tag !~ m|^/| )
         { ($in_tr and $in_td) or $err->($text)
         ; $$rows[$ri]{cells}[$di]{Scell} .= $text if $in_td
         }
        elsif ( $tag =~ m|^/| )
         { ( $in_tr and $in_td ) or $err->($text)
         ; $$rows[$ri]{cells}[$di]{Ecell} .= $text if $in_td
         }
      }
   ; $td or croak 'The tile does not contain any "<td>...</td>" area'
   ; return { start => $start
            , rows  => $rows
            , end   => $end
            }
   }

; sub is_matrix
   { my ($data_matrix) = shift
   # bi-dimensional array check
   ; foreach my $dr ( @$data_matrix )
     { if ( ref $dr eq 'ARRAY' )
        { foreach my $d ( @$dr )
           { return 0 if ref $d
           }
        }
       else
        { return 0
        }
     }
   ; return 1
   }
   
; sub tile_table
   { my ( $s
        , $data_matrix
        , $tile
        , $mode
        , $checked
        )
   ; if (  length(ref $_[0])             # blessed obj
        && eval { $_[0]->isa(ref $_[0]) }
        )
      { ( $s, $data_matrix, $mode, $checked) = @_
      }
     else
      { ( $data_matrix, $tile, $mode, $checked ) = @_
      ; $s = __PACKAGE__->new($tile)
      ; undef $tile
      }
   
   ; $mode ||= 'H_PULL V_PULL'

   ; $checked
     || is_matrix($data_matrix)
     || croak 'Wrong data matrix content'
   
   # set Hmode and Vmode
   ; my $m = qr/(PULL|TILE|TRIM)/
   ; my ($Hmode) = $mode =~ /\b H_ $m \b/x ; $Hmode ||= PULL
   ; my ($Vmode) = $mode =~ /\b V_ $m \b/x ; $Vmode ||= PULL

   # spread table
   ; my $out = "\n"
   
   ; ROW:
     for ( ( my $dmi
           = my $tmi
           = RESET
           )
         ; $dmi <= $#$data_matrix 
         ; ( $dmi ++
           , $tmi ++
           )
         )
      { if ( $tmi > $#{$s->{rows}} )
         {
           if    ( $Vmode eq PULL )
            { $tmi = $#{$s->{rows}}
            }
           elsif ( $Vmode eq TILE )
            { $tmi = RESET
            }
           elsif ( $Vmode eq TRIM )
           { last ROW
           }
         }
      ; $out .= $s->{rows}[$tmi]{Srow}
              . "\n"
      ; my $data_cells = $$data_matrix[$dmi]
      ; my $html_cells = $$s{rows}[$tmi]{cells}
      
      ; CELL:
        for ( ( my $di
              = my $ti
              = RESET
              )
            ; $di <= $#$data_cells
            ; ( $di ++
              , $ti ++
              )
            )
         { if ( $ti > $#$html_cells )
            {
              if    ( $Hmode eq PULL )
               { $ti = $#$html_cells
               }
              elsif ( $Hmode eq TILE )
               { $ti = RESET
               }
              elsif ( $Hmode eq TRIM )
               { last CELL
               }
            }
         ; $out .= "\t"
                 . $$html_cells[$ti]{Scell}
                 . $$data_cells[$di]
                 . $$html_cells[$ti]{Ecell}
                 . "\n"
         }
      ; $out .= $$s{rows}[$tmi]{Erow}
              . "\n"
      }
   ; return $$s{start}
          . $out
          . $$s{end}
   }

; 1

__END__

=pod

=head1 NAME

HTML::TableTiler - easily generates complex graphic styled HTML tables

=head1 VERSION 1.21

The latest versions changes are reported in the F<Changes> file in this distribution.

=head1 INSTALLATION

=over

=item Prerequisites

    HTML::PullParser >= 1.0
    IO::Util         >= 1.2

=item CPAN

    perl -MCPAN -e 'install HTML::TableTiler'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head1 SYNOPSIS

=over

=item the tile

    <table border="1" cellspacing="2" cellpadding="2">
    <tr>
        <td><b><i>a optional placeholder</i></b></td>
        <td>another optional placeholder</td>
    </tr>
    </table>

=item the code

    $matrix=[
               [ 'Balls', 'A470', 250, 2.75 ],
               [ 'Cubes', 'A520', 378, 3.25 ],
               [ 'Cones', 'A665', 186, 2.85 ]
            ];

Object-Oriented interface:

    use HTML::TableTiler;
    $tt = HTML::TableTiler->new(\$tile);
    print $tt->tile_table($matrix);

Function-Oriented interface

    use HTML::TableTiler qw(tile_table);
    print tile_table($matrix, \$tile);

=item the tiled table

    <table border="1" cellspacing="2" cellpadding="2">
    <tr>
        <td><b><i>Balls</i></b></td>
        <td>A470</td>
        <td>250</td>
        <td>2.75</td>
    </tr>
    <tr>
        <td><b><i>Cubes</i></b></td>
        <td>A520</td>
        <td>378</td>
        <td>3.25</td>
    </tr>
    <tr>
        <td><b><i>Cones</i></b></td>
        <td>A665</td>
        <td>186</td>
        <td>2.85</td>
    </tr>
    </table>

=back

=head1 DESCRIPTION

HTML::TableTiler uses a minimum HTML table as a tile to generate a complete HTML table from a bidimensional array of data. It can easily produce simple or complex graphic styled tables with minimum effort and maximum speed.

Think about the table tile as a sort of tile that automatically expands itself to contain the whole data. You can control the final look of a table by choosing either the HORIZONTAL and the VERTICAL tiling mode among: PULL, TILE and TRIM.

The main advantages to use it are:

=over

=item * automatic table generation

Pass only a bidimensional array of data to generate a complete HTML table. No worry to decide in advance the quantity of cells (or rows) in the table.

=item * complex graphic patterns generation without coding

Just prepare a simple table tile in your preferred WYSIWYG HTML editor and let the module do the job for you.

=item * simple to maintain

You can indipendently change the table tile or the code, and everything will go as you would expect.

=back

=head1 HTML Examples

Below this paragraph you should see several HTML examples. If you don't see any example, please take a look at the F<Examples.html> file included in this distribution: an image is worth thousands of words (expecially with HTML)!

=for html
<p>All the examples use the code below:</p>
<table border="0" cellspacing="0" cellpadding="8" bgcolor="#000066">
<tr>
<td colspan="2" valign="top"><font color="white"><b>common code for all the examples</b></font></td>
</tr>
<tr>
<td valign="top" bgcolor="#ccccff"><code>01<br>
02<br>
03<br>
04<br>
05<br>
06<br>
07<br>
08<br>
09<br>
10<br>
</code></td>
<td valign="top" bgcolor="#cccccc">
<p><code>$matrix=[<br>
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[ 'Descr.',&nbsp;'Item',&nbsp;'Quant.','Cost',&nbsp;'Price'&nbsp;],<br>
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[ 'Balls',&nbsp;&nbsp;'A001',&nbsp;'101',&nbsp;&nbsp;&nbsp;'2.75',&nbsp;'4.95'&nbsp;&nbsp;],<br>
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[ 'Cubes',&nbsp;&nbsp;'A002',&nbsp;'102',&nbsp;&nbsp;&nbsp;'3.75',&nbsp;'5.95'&nbsp;&nbsp;],<br>
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[ 'Cones',&nbsp;&nbsp;'A003',&nbsp;'103',&nbsp;&nbsp;&nbsp;'4.75',&nbsp;'6.75'&nbsp;&nbsp;],<br>
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[ 'Tubes',&nbsp;&nbsp;'A004',&nbsp;'104',&nbsp;&nbsp;&nbsp;'5.75',&nbsp;'7.95'&nbsp;&nbsp;]<br>
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;];<br>
</code></p>
<p><code>use HTML::TableTiler qw(tile_table);<br>
        print tile_table($matrix, $tile, $modes);</code></p>
</td>
</tr>
</table>
<p>See <b>tile</b> and <b>modes</b> in each example to understand how both work in combination.<code><br>
</code>Placeholders are optional, but very useful to preview the final result. </p>
<hr>
<h3>Example #1</h3>
<table>
<tr>
<td>Descr.</td>
<td>Item</td>
<td>Quant.</td>
<td>Cost</td>
<td>Price</td>
</tr>
<tr>
<td>Balls</td>
<td>A001</td>
<td>101</td>
<td>2.75</td>
<td>4.95</td>
</tr>
<tr>
<td>Cubes</td>
<td>A002</td>
<td>102</td>
<td>3.75</td>
<td>5.95</td>
</tr>
<tr>
<td>Cones</td>
<td>A003</td>
<td>103</td>
<td>4.75</td>
<td>6.75</td>
</tr>
<tr>
<td>Tubes</td>
<td>A004</td>
<td>104</td>
<td>5.75</td>
<td>7.95</td>
</tr>
</table>
<p><b>Tile</b>: <code>undef (default: '&lt;table&gt;&lt;tr&gt;&lt;td&gt;&lt;/td&gt;&lt;/tr&gt;&lt;/table&gt;')</code><br>
</p>
<p><b>Modes</b>: <code>not allowed with default tile<br>
</code></p>
<hr>
<h3>Example #2</h3>
<table border="0" cellspacing="1" cellpadding="3">
<tr>
<td bgcolor="#9999cc"><b>Descr.</b></td>
<td bgcolor="#9999cc"><b>Item</b></td>
<td bgcolor="#9999cc"><b>Quant.</b></td>
<td bgcolor="#9999cc"><b>Cost</b></td>
<td bgcolor="#9999cc"><b>Price</b></td>
</tr>
<tr>
<td bgcolor="#ccccff">Balls</td>
<td bgcolor="#ccccff">A001</td>
<td bgcolor="#ccccff">101</td>
<td bgcolor="#ccccff">2.75</td>
<td bgcolor="#ccccff">4.95</td>
</tr>
<tr>
<td bgcolor="#ccccff">Cubes</td>
<td bgcolor="#ccccff">A002</td>
<td bgcolor="#ccccff">102</td>
<td bgcolor="#ccccff">3.75</td>
<td bgcolor="#ccccff">5.95</td>
</tr>
<tr>
<td bgcolor="#ccccff">Cones</td>
<td bgcolor="#ccccff">A003</td>
<td bgcolor="#ccccff">103</td>
<td bgcolor="#ccccff">4.75</td>
<td bgcolor="#ccccff">6.75</td>
</tr>
<tr>
<td bgcolor="#ccccff">Tubes</td>
<td bgcolor="#ccccff">A004</td>
<td bgcolor="#ccccff">104</td>
<td bgcolor="#ccccff">5.75</td>
<td bgcolor="#ccccff">7.95</td>
</tr>
</table>
<p><b>Tile</b>:<br>
</p>
<table border="0" cellspacing="1" cellpadding="3">
<tr>
<td bgcolor="#9999cc"><b>placeholder</b></td>
</tr>
<tr>
<td bgcolor="#ccccff">placeholder</td>
</tr>
</table>
<p><b>Modes</b>:<code> undef (default: H_PULL V_PULL)<br>
</code></p>
<hr>
<h3>Example #3</h3>
<table border="0" cellspacing="1" cellpadding="3">
<tr>
<td bgcolor="#9999cc">Descr.</td>
<td bgcolor="#9999cc">Item</td>
<td bgcolor="#9999cc">Quant.</td>
<td bgcolor="#9999cc">Cost</td>
<td bgcolor="#9999cc">Price</td>
</tr>
<tr>
<td bgcolor="#ccccff">Balls</td>
<td bgcolor="#ccccff">A001</td>
<td bgcolor="#ccccff">101</td>
<td bgcolor="#ccccff">2.75</td>
<td bgcolor="#ccccff">4.95</td>
</tr>
<tr>
<td bgcolor="#9999cc">Cubes</td>
<td bgcolor="#9999cc">A002</td>
<td bgcolor="#9999cc">102</td>
<td bgcolor="#9999cc">3.75</td>
<td bgcolor="#9999cc">5.95</td>
</tr>
<tr>
<td bgcolor="#ccccff">Cones</td>
<td bgcolor="#ccccff">A003</td>
<td bgcolor="#ccccff">103</td>
<td bgcolor="#ccccff">4.75</td>
<td bgcolor="#ccccff">6.75</td>
</tr>
<tr>
<td bgcolor="#9999cc">Tubes</td>
<td bgcolor="#9999cc">A004</td>
<td bgcolor="#9999cc">104</td>
<td bgcolor="#9999cc">5.75</td>
<td bgcolor="#9999cc">7.95</td>
</tr>
</table>
<p><b>Tile</b>:<br>
</p>
<table border="0" cellspacing="1" cellpadding="3">
<tr>
<td bgcolor="#9999cc">placeholder</td>
</tr>
<tr>
<td bgcolor="#ccccff">placeholder</td>
</tr>
</table>
<p><b>Modes</b>:<code> V_TILE (default: H_PULL)<br>
</code></p>
<hr>
<h3>Example #4</h3>
<table border="0" cellspacing="1" cellpadding="3">
<tr>
<td bgcolor="#9999cc"><b>Descr.</b></td>
<td bgcolor="#ccccff">Item</td>
<td bgcolor="#ccccff">Quant.</td>
<td bgcolor="#ccccff">Cost</td>
<td bgcolor="#ccccff">Price</td>
</tr>
<tr>
<td bgcolor="#9999cc"><b>Balls</b></td>
<td bgcolor="#ccccff">A001</td>
<td bgcolor="#ccccff">101</td>
<td bgcolor="#ccccff">2.75</td>
<td bgcolor="#ccccff">4.95</td>
</tr>
<tr>
<td bgcolor="#9999cc"><b>Cubes</b></td>
<td bgcolor="#ccccff">A002</td>
<td bgcolor="#ccccff">102</td>
<td bgcolor="#ccccff">3.75</td>
<td bgcolor="#ccccff">5.95</td>
</tr>
<tr>
<td bgcolor="#9999cc"><b>Cones</b></td>
<td bgcolor="#ccccff">A003</td>
<td bgcolor="#ccccff">103</td>
<td bgcolor="#ccccff">4.75</td>
<td bgcolor="#ccccff">6.75</td>
</tr>
<tr>
<td bgcolor="#9999cc"><b>Tubes</b></td>
<td bgcolor="#ccccff">A004</td>
<td bgcolor="#ccccff">104</td>
<td bgcolor="#ccccff">5.75</td>
<td bgcolor="#ccccff">7.95</td>
</tr>
</table>
<p><b>Tile</b>:<br>
</p>
<table border="0" cellspacing="1" cellpadding="3">
<tr>
<td bgcolor="#9999cc"><b>placeholder</b></td>
<td bgcolor="#ccccff">placeholder</td>
</tr>
</table>
<p><b>Modes</b>:<code> undef (default: H_PULL V_PULL)<br>
</code></p>
<hr>
<h3>Example #5</h3>
<table border="0" cellspacing="1" cellpadding="3">
<tr>
<td bgcolor="#9999cc">Descr.</td>
<td bgcolor="#ccccff">Item</td>
<td bgcolor="#9999cc">Quant.</td>
<td bgcolor="#ccccff">Cost</td>
<td bgcolor="#9999cc">Price</td>
</tr>
<tr>
<td bgcolor="#9999cc">Balls</td>
<td bgcolor="#ccccff">A001</td>
<td bgcolor="#9999cc">101</td>
<td bgcolor="#ccccff">2.75</td>
<td bgcolor="#9999cc">4.95</td>
</tr>
<tr>
<td bgcolor="#9999cc">Cubes</td>
<td bgcolor="#ccccff">A002</td>
<td bgcolor="#9999cc">102</td>
<td bgcolor="#ccccff">3.75</td>
<td bgcolor="#9999cc">5.95</td>
</tr>
<tr>
<td bgcolor="#9999cc">Cones</td>
<td bgcolor="#ccccff">A003</td>
<td bgcolor="#9999cc">103</td>
<td bgcolor="#ccccff">4.75</td>
<td bgcolor="#9999cc">6.75</td>
</tr>
<tr>
<td bgcolor="#9999cc">Tubes</td>
<td bgcolor="#ccccff">A004</td>
<td bgcolor="#9999cc">104</td>
<td bgcolor="#ccccff">5.75</td>
<td bgcolor="#9999cc">7.95</td>
</tr>
</table>
<p><b>Tile</b>:<br>
</p>
<table border="0" cellspacing="1" cellpadding="3">
<tr>
<td bgcolor="#9999cc">placeholder</td>
<td bgcolor="#ccccff">placeholder</td>
</tr>
</table>
<p><b>Modes</b>:<code> H_TILE (default: V_PULL)<br>
</code></p>
<hr>
<h3>Example #6</h3>
<table border="0" cellspacing="1" cellpadding="3">
<tr>
<td align="center" bgcolor="#ccccff">Descr.</td>
<td align="center" bgcolor="#9999cc">Item</td>
<td align="center" bgcolor="#ccccff">Quant.</td>
<td align="center" bgcolor="#9999cc">Cost</td>
<td align="center" bgcolor="#ccccff">Price</td>
</tr>
<tr>
<td align="center" bgcolor="#9999cc">Balls</td>
<td align="center" bgcolor="#ccccff">A001</td>
<td align="center" bgcolor="#9999cc">101</td>
<td align="center" bgcolor="#ccccff">2.75</td>
<td align="center" bgcolor="#9999cc">4.95</td>
</tr>
<tr>
<td align="center" bgcolor="#ccccff">Cubes</td>
<td align="center" bgcolor="#9999cc">A002</td>
<td align="center" bgcolor="#ccccff">102</td>
<td align="center" bgcolor="#9999cc">3.75</td>
<td align="center" bgcolor="#ccccff">5.95</td>
</tr>
<tr>
<td align="center" bgcolor="#9999cc">Cones</td>
<td align="center" bgcolor="#ccccff">A003</td>
<td align="center" bgcolor="#9999cc">103</td>
<td align="center" bgcolor="#ccccff">4.75</td>
<td align="center" bgcolor="#9999cc">6.75</td>
</tr>
<tr>
<td align="center" bgcolor="#ccccff">Tubes</td>
<td align="center" bgcolor="#9999cc">A004</td>
<td align="center" bgcolor="#ccccff">104</td>
<td align="center" bgcolor="#9999cc">5.75</td>
<td align="center" bgcolor="#ccccff">7.95</td>
</tr>
</table>
<p><b>Tile</b>:<br>
</p>
<table border="0" cellspacing="1" cellpadding="3">
<tr>
<td align="center" bgcolor="#ccccff">placeholder</td>
<td align="center" bgcolor="#9999cc">placeholder</td>
</tr>
<tr>
<td align="center" bgcolor="#9999cc">placeholder</td>
<td align="center" bgcolor="#ccccff">placeholder</td>
</tr>
</table>
<p><b>Modes</b>:<code> H_TILE V_TILE<br>
</code></p>
<hr>
<h3>Example #7</h3>
<table border="0" cellspacing="1" cellpadding="3">
<tr bgcolor="#666699">
<td align="left"><b><font color="white">Descr.</font></b></td>
<td align="center"><b><font color="white">Item</font></b></td>
<td align="center"><b><font color="white">Quant.</font></b></td>
<td align="center"><b><font color="white">Cost</font></b></td>
<td align="center"><b><font color="white">Price</font></b></td>
</tr>
<tr>
<td align="left" bgcolor="#9999cc"><b>Balls</b></td>
<td align="center" bgcolor="#ccccff">A001</td>
<td align="center" bgcolor="#ccccff">101</td>
<td align="center" bgcolor="#ccccff">2.75</td>
<td align="center" bgcolor="#ccccff">4.95</td>
</tr>
<tr>
<td align="left" bgcolor="#9999cc"><b>Cubes</b></td>
<td align="center" bgcolor="#ccccff">A002</td>
<td align="center" bgcolor="#ccccff">102</td>
<td align="center" bgcolor="#ccccff">3.75</td>
<td align="center" bgcolor="#ccccff">5.95</td>
</tr>
<tr>
<td align="left" bgcolor="#9999cc"><b>Cones</b></td>
<td align="center" bgcolor="#ccccff">A003</td>
<td align="center" bgcolor="#ccccff">103</td>
<td align="center" bgcolor="#ccccff">4.75</td>
<td align="center" bgcolor="#ccccff">6.75</td>
</tr>
<tr>
<td align="left" bgcolor="#9999cc"><b>Tubes</b></td>
<td align="center" bgcolor="#ccccff">A004</td>
<td align="center" bgcolor="#ccccff">104</td>
<td align="center" bgcolor="#ccccff">5.75</td>
<td align="center" bgcolor="#ccccff">7.95</td>
</tr>
</table>
<p><b>Tile</b>:<br>
</p>
<table border="0" cellspacing="1" cellpadding="3">
<tr bgcolor="#666699">
<td align="left"><b><font color="white">placeholder</font></b></td>
<td align="center"><b><font color="white">placeholder</font></b></td>
</tr>
<tr>
<td align="left" bgcolor="#9999cc"><b>placeholder</b></td>
<td align="center" bgcolor="#ccccff">placeholder</td>
</tr>
</table>
<p><b>Modes</b>:<code> undef (default: H_PULL V_PULL)<br>
</code></p>

=head1 METHODS

=over

=item new ( [tile] )

The constructor method generate a HTML::TableTiler object. It accepts one optional I<tile> parameter that can be a reference to a SCALAR content, a path to a file or a filehandle. If you don't pass any I<tile> to the constructor method, a plain I<tile> will be used internally to generate a plain HTML table. A I<tile> must be a valid HTML chunk containing at least one "<tr> ... </tr>" area. See L<"HTML Examples"> or the F<Examples.html> file in order to know more useful details about table tiles.

Examples of constructors:

    $tt = HTML::TableTiler->new( \$tile_scalar );
    $tt = HTML::TableTiler->new( '/path/to/table_tile_file' );
    $tt = HTML::TableTiler->new( *TABLE_TILE_FILEHANDLER );
    $tt = HTML::TableTiler->new(); # default \'<table><tr><td></td></tr></table>'

=item is_matrix( array_reference )

This method checks if the passed I<array_reference> is a matrix (i.e. an array of arrays). It returns C<1> on success and C<0> on failure. It is called automatically by the C<tile_table()> method unless you pass a true value as tird argument.


=item tile_table ( matrix [, mode ] [, checked] )

This method generates a tiled table including the data contained in I<matrix>. The I<matrix> parameter must be a reference to a bidimensional array:

    $matrix=[
               [ 'Balls', 'A470', '250', '2.75' ],
               [ 'Cubes', 'A520', '378', '3.25' ],
               [ 'Cones', 'A665', '186', '2.85' ]
            ];

The I<mode> parameter must be scalar containing one or two literal words representing ROW and COLUMN tiling mode. These are the accepted modes:

=over

=item H_PULL

The grafic style of each rightmost CELL in the tile will be rightward replicated. This is the default HORIZONTAL tiling mode, so if you don't explicitly assign any other H_* mode, this mode will be used by default.

=item H_TILE

The grafic style of each ROW in the tile will be rightward replicated.

=item H_TRIM

The table ROW will be trimmed to the tile ROW, and the surplus data in I<matrix> will be ignored.

=item V_PULL

The grafic style of each bottommost CELL in the tile will be downward replicated. This is the default VERTICAL tiling mode, so if you don't explicitly assign any other V_* mode, this mode will be used by default.

=item V_TILE

The grafic style of each COLUMN in the tile will be downward replicated.

=item V_TRIM

The table COLUMN will be trimmed to the tile COLUMN, and the surplus data in I<matrix> will be ignored.

=back

Examples:

    $tt->TableTiler( \@matrix, "V_TRIM H_TILE" );
    $tt->TableTiler( \@matrix, "V_TILE" ); # default "H_PULL"
    $tt->TableTiler( \@matrix );             # default "H_PULL V_PULL"

Different combinations of I<tiling modes> and I<tiles> can easily produce complex tiled tables. (See L<"HTML Examples"> or the F<Examples.html> file for details.)

A true I<checked> argument avoid the C<is_matrix> method to be internally called.

=back

=head1 FUNCTIONS

=over

=item tile_table ( matrix [, tile [, mode ]] )

If you prefer a function-oriented programming style, you can import or directly use the C<tile_table()> function:

    use HTML::TableTiler qw( tile_table );
    print tile_table( \@matrix, \$tile, "V_TILE" );
    print tile_table( \@matrix );

    # or
    use HTML::TableTiler;
    print HTML::TableTiler::tile_table( \@matrix, \$tile, "V_TILE" );
    print HTML::TableTiler::tile_table( \@matrix);

Note that you have to pass the I<tile> as the optional second parameter, and the I<mode> as the optional third parameter. (See method C<tile_table()> for details).

=back

=head1 SEE ALSO

L<Template::Magic::HTML|Template::Magic::HTML>, that supplies an extended and transparent interface to this module.

=head1 SUPPORT and FEEDBACK

If you need support or if you want just to send me some feedback or request, please use this link: http://perl.4pro.net/?HTML::TableTiler.

=head1 AUTHOR and COPYRIGHT

© 2002-2004 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
