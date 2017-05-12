package Image::OrgChart;

use strict;
use GD;
use vars qw($VERSION $DEBUG);
require Exporter;


$VERSION = '0.20';

sub new {
    my ($pkg,@args) = @_;
    my %args;
    if ((scalar @args % 2) == 0) {
        %args = @args;
    }

    ## defaults
    my $self = {
        min_width      => 0,
        min_height     => 0,
        box_color      => [0,0,0],
        box_fill_color => [120,120,120],
        connect_color  => [0,0,0],
        text_color     => [0,0,0],
        bg_color       => [255,255,255],
        shadow_color   => [50,50,50],
        shadow         => 0,
        arrow_heads    => 0,
        fill_boxes     => 0,
        h_spacing      => 15,
        v_spacing      => 5,
        path_seperator => '/',
        font           => 'gdTinyFont',
        font_height    => 10,  ## ?
        font_width     => 5,   ## ?
        indent         => undef,
        _data          => {},
        _track         => {
            longest_name => 0,
            shortest_name => 100,
            deapest_path => 0,
            most_keys  => 0,
            total_boxes => 1,
            },
        _image_info    => {
            height    => 0,
            width     => 0,
            },
        color         => {
            ## used by allocateColor
        },
        data_type     => ( GD::Image->can('gif') ? 'gif' : 'png'),
    };

    ## from new() args
    for (keys %args) {
        $self->{$_} = $args{$_};
    }
    
    return bless($self,$pkg);
}

sub data_type {
    return shift->{data_type};
}

sub add {
    my ($self,$path) = @_;
    $path =~ s/^$self->{path_seperator}//;
    my @arr_path = split(/$self->{path_seperator}/,$path);
    warn("PATH($path) - ",join(',',@arr_path),"\n") if $DEBUG;
    my $curr = '$self->{_data}';
    my $depth = 0;
    foreach my $limb (@arr_path) {
         $curr .= "{'$limb'}";
         if (length($limb) > $self->{_track}{longest_name}) {
             $self->{_track}{longest_name} = length($limb);
         } elsif (length($limb) < $self->{_track}{shortest_name}) {
             $self->{_track}{shortest_name} = length($limb);
         }
    }
    warn("CREATING: $curr\n") if $DEBUG;
    eval("$curr = {} unless (exists $curr)");
    die $@ if $@;
}

sub set_hashref {
    my ($self,$href) = @_;
    $self->{_data} = $href;
}

sub add_hashref {
    my ($self,$href) = @_;
    foreach my $nkey (keys %{ $href }) {
        if ($self->{$nkey}) {
            &add_hashref($self->{$nkey},$href->{$nkey});
        } else {
            $self->{$nkey} = $href->{$nkey};
            if (length($nkey) > $self->{_track}{longest_name}) {
                $self->{_track}{longest_name} = length($nkey);
            } elsif (length($nkey) > $self->{_track}{shortest_name}) {
                $self->{_track}{shortest_name} = length($nkey);
            }
        }
    }
}

sub alloc_collors {
    my ($self,$image) = @_;
    $self->{color}{box_color} = $image->colorAllocate($self->{box_color}[0],$self->{box_color}[1],$self->{box_color}[2]);
    $self->{color}{box_fill_color} = $image->colorAllocate($self->{box_fill_color}[0],$self->{box_fill_color}[1],$self->{box_fill_color}[2]);
    $self->{color}{connect_color} = $image->colorAllocate($self->{connect_color}[0],$self->{connect_color}[1],$self->{connect_color}[2]);
    $self->{color}{text_color} = $image->colorAllocate($self->{text_color}[0],$self->{text_color}[1],$self->{text_color}[2]);
    $self->{color}{bg_color} = $image->colorAllocate($self->{bg_color}[0],$self->{bg_color}[1],$self->{bg_color}[2]);
}

sub alloc_fonts {
    my $self = shift;

    no strict 'refs';
    my $fnt = &{$self->{font}}();
    use strict 'refs';
    $self->{font_width} = $fnt->width;
    $self->{font_height} = $fnt->height;
    $self->{indent} ||= 5;
    $self->{indent} =  $self->{font_width}*$self->{indent};
    warn "GD::Font H/W ($self->{font}) : $self->{font_height}/$self->{font_width}\n" if $DEBUG;
}

sub draw_boxes {
    my ($self,$image) = @_;
    my ($ULx,$ULy) = (5,5); ## start with some padding
    $Image::OrgChart::S::CurrentY = $ULy;
    $Image::OrgChart::S::BaseX = $ULx;
    &_draw_one_row_box($self,$self->{_data},$image,$ULx,$ULy);
}


sub _draw_one_row_box {
    my ($self,$href,$image,$indentX,$indentY) = @_;
    my $ULx = $indentX;
    my $indent =  $self->{indent};
    my $creap = $self->{_tracked}{box_height} + $self->{v_spacing};
    foreach my $person (sort keys %{ $href }) {
        my $ULy = $Image::OrgChart::S::CurrentY;
        
        # CONNECTER (if we are a child)
        if ($Image::OrgChart::S::ParentX && ($ULx > $Image::OrgChart::S::BaseX) ) {
            ## connect
            $self->_con_boxes($image,[$Image::OrgChart::S::ParentX,$Image::OrgChart::S::ParentY-$creap],[$ULx,$ULy]);
        }

        # RECTANGLE
        if ($self->{shadow}) {
            $image->filledRectangle($ULx+3,$ULy+3,$ULx+3+$self->{_tracked}{box_width},$ULy+3+$self->{_tracked}{box_height},$self->{color}{shadow_color});
            $image->filledRectangle($ULx,$ULy,$ULx+$self->{_tracked}{box_width},$ULy+$self->{_tracked}{box_height},$self->{color}{bg_color});
            $image->rectangle($ULx,$ULy,$ULx+$self->{_tracked}{box_width},$ULy+$self->{_tracked}{box_height},$self->{color}{box_color});
            if ($self->{fill_boxes}) {
                $image->fill($ULx+1,$ULy+1,$self->{color}{box_fill_color});
            }
        } else {
            $image->rectangle($ULx,$ULy,$ULx+$self->{_tracked}{box_width},$ULy+$self->{_tracked}{box_height},$self->{color}{box_color});
            if ($self->{fill_boxes}) {
                $image->fill($ULx+1,$ULy+1,$self->{color}{box_fill_color});
            }
        }

        # STRING
        no strict 'refs';
        my $fnt = &{$self->{font}}();
        use strict 'refs';
        $image->string($fnt,$ULx+2,$ULy+2,$person,$self->{color}{text_color});

        # TRANSLATE
        $Image::OrgChart::S::CurrentY += $creap;

        # REPORTS
        my $report_cnt = scalar keys %{ $href->{$person} };
        if ($report_cnt > 0) {
            $Image::OrgChart::S::ParentX = $ULx;
            $Image::OrgChart::S::ParentY = $Image::OrgChart::S::CurrentY;
            $self->_draw_one_row_box($href->{$person},$image,$ULx+$indent,$Image::OrgChart::S::CurrentY);
            $Image::OrgChart::S::ParentX -= $indent;
            $Image::OrgChart::S::ParentY -= $creap;
        }
    }
}

sub _con_boxes {
    my ($self,$image,$from,$to) = @_;

    $to->[1] += ( $self->{_tracked}{box_height} / 2 );
    my $vert_x    = ( $from->[0] + ($self->{indent}/2));
    my $v_start_y = ( $from->[1] + $self->{_tracked}{box_height} );

    $self->_draw_line($image,[$vert_x,$v_start_y],[$vert_x,$to->[1]]); # vertical
    $self->_draw_line($image,[$vert_x,$to->[1]],[$to->[0],$to->[1]]);
}

sub _draw_line {
    my ($self,$image,$from,$to) = @_;
    $image->line($from->[0],$from->[1],$to->[0],$to->[1],$self->{color}{connect_color});
    if ($self->{arrow_heads}) { 
        ## i only currently do Horizontal and Vertical lines, which makes
        ## directional calculations much easier
        if ($from->[0] == $to->[0]) {
            ## vert line
            if ($to->[1] > $from->[1]) {
                ## face up
                ###### not yet needed
            } else {
                ##  face down
                ###### not yet needed
            }
        } else {
            ## horiz line
            if ($to->[0] > $from->[0]) {
                ## face right
                $image->line($to->[0],$to->[1],$to->[0]-4,$to->[1]-2,$self->{color}{connect_color});
                $image->line($to->[0],$to->[1],$to->[0]-4,$to->[1]+2,$self->{color}{connect_color});
                $image->line($to->[0]-4,$to->[1]-2,$to->[0]-4,$to->[1]+2,$self->{color}{connect_color});
            } else {
                ##  face left
                ###### currently unused
                $image->line($to->[0],$to->[1],$to->[0]+2,$to->[1]+4,$self->{color}{connect_color});
                $image->line($to->[0],$to->[1],$to->[0]-2,$to->[1]+4,$self->{color}{connect_color});
                $image->line($to->[0]+2,$to->[1]+4,$to->[0]-2,$to->[1]+4,$self->{color}{connect_color});
            }
        }
    }
}

sub draw {
    my $self = shift;
    my $gd = $self->gd();

    my $dt = $self->{data_type};
    return $gd->$dt();
}

*as_image = *draw;

sub gd {
   my $self = shift;

    ## new image
    $self->alloc_fonts();
    $self->_calc_depth();
    $self->calc_image_info();
    my $height = ( $self->{min_height} > $self->{_image_info}{height} ? $self->{min_height}  : $self->{_image_info}{height} );
    my $width  = ( $self->{min_width} > $self->{_image_info}{width} ? $self->{min_width}  : $self->{_image_info}{width} );
    #printf("HxW = %dx%d\n",$height,$width);
    my $image = new GD::Image($width,$height);
    $self->alloc_collors($image);
    $image->fill(0,0,$self->{color}{bg_color});
    $self->draw_boxes($image);

    return $image;
}

sub _calc_depth {
    my $self = shift;
    $Image::OrgChart::S::total = $self->{_track}{deapest_path};
    $Image::OrgChart::S::Kcount = $self->{_track}{most_keys};
    $Image::OrgChart::S::Lname = $self->{_track}{longest_name};
    $Image::OrgChart::S::Sname = $self->{_track}{shortest_name};
    $Image::OrgChart::S::TBox = $self->{_track}{total_boxes};
    &_re_f_depth($self->{_data});
    $self->{_track}{most_keys} = $Image::OrgChart::S::Kcount;
    $self->{_track}{deapest_path} = $Image::OrgChart::S::total;
    $self->{_track}{longest_name} = $Image::OrgChart::S::Lname;
    $self->{_track}{shortest_name} = $Image::OrgChart::S::Sname;
    $self->{_track}{total_boxes} = $Image::OrgChart::S::TBox ;
    undef($Image::OrgChart::S::total);
    undef($Image::OrgChart::S::Kcount);
    undef($Image::OrgChart::S::Lname);
    undef($Image::OrgChart::S::Sname);
    undef($Image::OrgChart::S::TBox);
}

sub _re_f_depth {
    my $href = shift;
    my $indent = shift;
    $indent ||= 0;
    if ( $indent > $Image::OrgChart::S::total ) {
        $Image::OrgChart::S::total = $indent;
    }
    foreach my $key (keys %$href) {
        $Image::OrgChart::S::TBox++;
            if (length($key) > $Image::OrgChart::S::Lname) {
                $Image::OrgChart::S::Lname = length($key);
            } elsif (length($key) < $Image::OrgChart::S::Sname) {
                $Image::OrgChart::S::Sname = length($key);
            }        
        my $value = $href->{$key};
        if (ref($value) eq 'HASH') {
            &_re_f_depth($value, $indent + 1);
            $Image::OrgChart::S::Kcount = ( (scalar keys %$href > $Image::OrgChart::S::Kcount) ? scalar keys %$href : $Image::OrgChart::S::Kcount );
        }
    }
}

sub calc_image_info {
    my $self = shift; 
    $self->{_tracked}{box_width} = ( ( $self->{_track}{longest_name} * $self->{font_width} ) + 2);
    $self->{_tracked}{box_height} = ( $self->{font_height} + 2 );
    $self->{_image_info}{height} = ( ($self->{v_spacing} + $self->{_tracked}{box_height}) * $self->{_track}{total_boxes});
    $self->{_image_info}{width}  = ( ($self->{indent}+$self->{h_spacing}) * $self->{_track}{deapest_path})+$self->{_tracked}{box_width};
}

sub mid_point {
    my ($x1,$y1,$x2,$y2) = @_;
    my $X = (((_max($x1,$x2) - _min($x1,$x2))/2) + _min($x1,$x2));
    my $Y = (((_max($y1,$y2) - _min($y1,$y2))/2) + _min($y1,$y2));
    return [$X,$Y];
}

sub _min {
    my ($a,$b) = @_;
    return ( $a > $b ? $b : $a);
}

sub _max {
    my ($a,$b) = @_;
    return ( $a < $b ? $b : $a);
}

1;
__END__

=head1 NAME

Image::OrgChart - Perl extension for writing org charts

=head1 SYNOPSIS

  use Image::OrgChart;
  use strict;
    
  my $org_chart = Image::OrgChart->new();
  $org_chart->add('/manager/middle-manager/employee1');
  $org_chart->add('/manager/middle-manager/employee2');
  $org_chart->add('/manager/middle-manager/employee3');
  $org_chart->add('/manager/middle-manager/employee4');
  
  my $imagedata = $org_chart->as_image();
  if ($org_chart->data_type() eq 'gif') {
      ## write gif file using $imagedata
  } elsif ($org_chart->data_type() eq 'png') {
      ## write png file using $imagedata
  }
  
  ## or
  my $GDObj = $org_chart->gd();
  my $imagedata = $GDObj->png();
  

=head1 DESCRIPTION

Image::OrgChart, uses the perl GD module to create OrgChart style images in gif or png format, depending on which is available from your version of GD.
There are several ways to add data to the object, but the most common is the C<$object->add($path)>. The C<$path> can be seperated by any charachter, but the default is a L</>. See the C<new()> method for that and other configuration options.

=head1 FUNCTIONS 

=over 8

=item new([OPTIONS])

Created a new Image::OrgChart object. Takes a hash-like list of configuration options. See list below.
 
=over 2

=item *

min_height - A minimum height for the output image (in pixels)

=item *

min_width - A minimum width for the output image (in pixels)
 
=item *

box_color - box border color in arrref triplet. default [0,0,0]
   
=item *

box_fill_color - box fill color in arrref triplet. default [75,75,75] 
   
=item *

connect_color - line color in arrref triplet. default [0,0,0]
   
=item *

text_color - text color in arrref triplet. default [0,0,0]
   
=item *

bg_color - bg color in arrref triplet. default [255,255,255]
   
=item *

shadow_color - shadow color in arrref triplet. default [50,50,50]
   
=item *

arrow_heads - 1/0, adds arrow heads to ends of lines
   
=item *

fill_boxes - 1/0, fills boxes with box_fill_color prior to adding text
   
=item *

shadow - 1/0, draw 'shadows' for boxes. use shadow_color for color

=item *

h_spacing - horizontal spacing in (in pixels)
   
=item *

v_spacing - vertical spacing in (in pixels)
   
=item *

indent - indent when new section of boxes is started. measured in characters.
   
=item *

font - font to use. must be a vlid GD::Font name (gdTinyFont [default],gdMediumBoldFont, gdGiantFont, etc)

=item *

path_seperator - Seperator to use for paths provided by the C<add()> command.


   
=back

=item add(PATH)

Add data to the object using a seperated scalar. The seperator can be set in the C<new()> constructor, but defaults to L</>.
 
=item set_hashref(HASH_REF)

This allows assignment of a hash-of-hashes as the data element of the object. People who have not persons underneath them should have an empty hash-reference as the value. e.g.
 
=over 3
 
 $hash{'root'}{'foo'} = {
                         'bar'      => {},
                         'more foo' => {},
                         'kung-foo' => {},
                        };
                        
=back
 
=item draw()

this plots all of the data from the object and returns the image data.
 
=item data_type()

returns the data type used by the version of GD in use.
  
=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs with options

  -AXC -v 0.01 -n Image::OrgChart
  
=item 0.02

Development version, unreleased

=item 0.03

=over 2

=item *

Added C<new()> options : arrow_heads,file_boxes,indent,shadow,shadow_color

=item *

Re-wrote image height and width calculations.

=item *

Corrected problem connector lines

=item *

Resturctured internal code to better handle changes.

=item *

Added font support, including dynamic font attributes.

=back

=item 0.04

=over 2

=item *

Fixed some pod errors

=item *

Fixed error with connecting line of multiple first level boxes.

=item *

added gd() method. returns gd object.

=back

=item 0.05

=over 2

=item *

Fixed some (more) pod errors

=item *

Added as_image() method as a replacment for draw(). draw() is maintained for backwards compatability, but should be considered depriciated.

=item *

Added GD as a prerequisite in Makefile.PL (version 1.16 of GD)

=back

=item 0.10

=over 2

=item *

Fixed tests for Win32

=back

=item 0.15

=over 2

=item *

Added min_height and min_width options. Added exmaple7.pl (simple min h&w example)

=back

=item 0.20

=over 2

=item *

Fixed Makefile.PL

=back

=back


=head1 AUTHOR

Matt Sanford E<lt>mzsanford@cpan.orgE<gt>

=head1 SEE ALSO

perl(1),GD

=cut
