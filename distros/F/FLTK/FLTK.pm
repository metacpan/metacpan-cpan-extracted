package FLTK;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
#use Carp;
require Exporter;
require DynaLoader;
#require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
$VERSION = '0.52';

#sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

#    my $constname;
#    ($constname = $AUTOLOAD) =~ s/.*:://;
#    croak "& not defined" if $constname eq 'constant';
#    my $val = constant($constname, @_ ? $_[0] : 0);
#    if ($! != 0) {
#	if ($! =~ /Invalid/) {
#	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
#	    goto &AutoLoader::AUTOLOAD;
#	}
#	else {
#		croak "Your vendor has not defined FLTK macro $constname";
#	}
#    }
#    no strict 'refs';
#    *$AUTOLOAD = sub () { $val };
#    goto &$AUTOLOAD;
#}

# Cheap pixmap loader.
sub fl_load_image {
  my ($file) = @_;

  undef $/;
  open(IMG, "$file") or die "Unable to load $file: $!";
  my $data = <IMG>;
  close(IMG);

  $/ = "\n";
  my @image;

  while($data =~ m/"(.*)"/gc) {
    push @image, $1;
  }

  return \@image;
}

# Very long list of subs to represent FLTK constants. I'm not using 
sub FL_UP_BOX                 {1;}
sub FL_NORMAL_BOX             {2;}
sub FL_DOWN_BOX               {3;}
sub FL_THIN_UP_BOX            {4;}
sub FL_THIN_BOX               {5;}
sub FL_THIN_DOWN_BOX          {6;}
sub FL_ENGRAVED_BOX           {7;}
sub FL_EMBOSSED_BOX           {8;}
sub FL_BORDER_BOX             {9;}
sub FL_FLAT_BOX               {10;}
sub FL_HIGHLIGHT_UP_BOX       {11;}
sub FL_FLAT_UP_BOX            {12;}
sub FL_HIGHLIGHT_BOX          {13;}
sub FL_HIGHLIGHT_DOWN_BOX     {14;}
sub FL_FLAT_DOWN_BOX          {15;}
sub FL_ROUND_UP_BOX           {16;}
sub FL_ROUND_BOX              {17;}
sub FL_ROUND_DOWN_BOX         {18;}
sub FL_DIAMOND_UP_BOX         {19;}
sub FL_DIAMOND_BOX            {20;}
sub FL_DIAMOND_DOWN_BOX       {21;}
sub FL_NO_BOX                 {22;}
sub FL_SHADOW_BOX             {23;}
sub FL_ROUNDED_BOX            {24;}
sub FL_RSHADOW_BOX            {25;}
sub FL_RFLAT_BOX              {26;}
sub FL_OVAL_BOX               {27;}
sub FL_OSHADOW_BOX            {28;}
sub FL_OFLAT_BOX              {29;}
sub FL_BORDER_FRAME           {30;}

sub FL_NO_FLAGS               {0;}
sub FL_ALIGN_CENTER           {0;}
sub FL_ALIGN_TOP              {0x00000001;}
sub FL_ALIGN_BOTTOM           {0x00000002;}
sub FL_ALIGN_LEFT             {0x00000004;}
sub FL_ALIGN_RIGHT            {0x00000008;}
sub FL_ALIGN_INSIDE           {0x00000010;}
sub FL_ALIGN_TILED            {0x00000020;}
sub FL_ALIGN_CLIP             {0x00000040;}
sub FL_ALIGN_WRAP             {0x00000080;}
sub FL_ALIGN_MASK             {0x000000FF;}
sub FL_INACTIVE               {0x00000100;}
sub FL_MENU_STAYS_UP          {0x00000200;}
sub FL_VALUE                  {0x00000400;}
sub FL_OPEN                   {0x00000800;}
sub FL_INVISIBLE              {0x00001000;}
sub FL_OUTPUT                 {0x00002000;}
sub FL_CHANGED                {0x00004000;}
sub FL_COPIED_LABEL           {0x00008000;}
sub FL_FOCUSED                {0x00010000;}
sub FL_HIGHLIGHT              {0x00020000;}
sub FL_FRAME_ONLY             {0x00040000;}
sub FL_SELECTED               {0x00080000;}
sub FL_NO_SHORTCUT_LABEL      {0x00100000;}
sub FL_NO_EVENT               {0;}
sub FL_PUSH                   {1;}
sub FL_RELEASE                {2;}
sub FL_ENTER                  {3;}
sub FL_LEAVE                  {4;}
sub FL_DRAG                   {5;}
sub FL_FOCUS                  {6;}
sub FL_UNFOCUS                {7;}
sub FL_KEY                    {8;}
sub FL_KEYUP                  {9;}
sub FL_MOVE                   {10;}
sub FL_SHORTCUT               {11;}
sub FL_ACTIVATE               {12;}
sub FL_DEACTIVATE             {13;}
sub FL_SHOW                   {14;}
sub FL_HIDE                   {15;}
sub FL_VIEWCHANGE             {16;}
sub FL_PASTE                  {17;}
sub FL_DND_ENTER              {18;}
sub FL_DND_DRAG               {19;}
sub FL_DND_LEAVE              {20;}
sub FL_DND_RELEASE            {21;}
sub FL_KEYBOARD               {8;}
sub FL_WHEN_NEVER             {0;}
sub FL_WHEN_CHANGED           {1;}
sub FL_WHEN_RELEASE           {4;}
sub FL_WHEN_RELEASE_ALWAYS    {6;}
sub FL_WHEN_ENTER_KEY         {8;}
sub FL_WHEN_ENTER_KEY_ALWAYS  {10;}
sub FL_WHEN_ENTER_KEY_CHANGED {11;}
sub FL_WHEN_NOT_CHANGED       {2;}
sub FL_Button                 {0xfee8;}
sub FL_BackSpace              {0xff08;}
sub FL_Tab                    {0xff09;}
sub FL_Clear                  {0xff0b;}
sub FL_Enter                  {0xff0d;}
sub FL_Pause                  {0xff13;}
sub FL_Scroll_Lock            {0xff14;}
sub FL_Escape                 {0xff1b;}
sub FL_Home                   {0xff50;}
sub FL_Left                   {0xff51;}
sub FL_Up                     {0xff52;}
sub FL_Right                  {0xff53;}
sub FL_Down                   {0xff54;}
sub FL_Page_Up                {0xff55;}
sub FL_Page_Down              {0xff56;}
sub FL_End                    {0xff57;}
sub FL_Print                  {0xff61;}
sub FL_Insert                 {0xff63;}
sub FL_Menu                   {0xff67;}
sub FL_Num_Lock               {0xff7f;}
sub FL_KP                     {0xff80;}
sub FL_KP_Enter               {0xff8d;}
sub FL_KP_Last                {0xffbd;}
sub FL_F                      {0xffbd;}
sub FL_F_Last                 {0xffe0;}
sub FL_Shift_L                {0xffe1;}
sub FL_Shift_R                {0xffe2;}
sub FL_Control_L              {0xffe3;}
sub FL_Control_R              {0xffe4;}
sub FL_Caps_Lock              {0xffe5;}
sub FL_Meta_L                 {0xffe7;}
sub FL_Meta_R                 {0xffe8;}
sub FL_Alt_L                  {0xffe9;}
sub FL_Alt_R                  {0xffea;}
sub FL_Delete                 {0xffff;}
sub FL_LEFT_MOUSE             {1;}
sub FL_MIDDLE_MOUSE           {2;}
sub FL_RIGHT_MOUSE            {3;}
sub FL_SHIFT                  {0x00010000;}
sub FL_CAPS_LOCK              {0x00020000;}
sub FL_CTRL                   {0x00040000;}
sub FL_ALT                    {0x00080000;}
sub FL_NUM_LOCK               {0x00100000;}
sub FL_META                   {0x00400000;}
sub FL_SCROLL_LOCK            {0x00800000;}
sub FL_BUTTON1                {0x01000000;}
sub FL_BUTTON2                {0x02000000;}
sub FL_BUTTON3                {0x04000000;}
sub FL_CURSOR_DEFAULT         {0;}
sub FL_CURSOR_ARROW           {35;}
sub FL_CURSOR_CROSS           {66;}
sub FL_CURSOR_WAIT            {76;}
sub FL_CURSOR_INSERT          {77;}
sub FL_CURSOR_HAND            {31;}
sub FL_CURSOR_HELP            {47;}
sub FL_CURSOR_MOVE            {27;}
sub FL_CURSOR_NS              {78;}
sub FL_CURSOR_WE              {79;}
sub FL_CURSOR_NWSE            {80;}
sub FL_CURSOR_NESW            {81;}
sub FL_CURSOR_NONE            {255;}
sub FL_CURSOR_N               {70;}
sub FL_CURSOR_NE              {69;}
sub FL_CURSOR_E               {49;}
sub FL_CURSOR_SE              {8;}
sub FL_CURSOR_S               {9;}
sub FL_CURSOR_SW              {7;}
sub FL_CURSOR_W               {36;}
sub FL_CURSOR_NW              {68;}
sub FL_READ                   {1;}
sub FL_WRITE                  {4;}
sub FL_EXCEPT                 {8;}
sub FL_RGB                    {0;}
sub FL_INDEX                  {1;}
sub FL_SINGLE                 {0;}
sub FL_DOUBLE                 {2;}
sub FL_ACCUM                  {4;}
sub FL_ALPHA                  {8;}
sub FL_DEPTH                  {16;}
sub FL_STENCIL                {32;}
sub FL_RGB8                   {64;}
sub FL_MULTISAMPLE            {128;}
sub FL_DAMAGE_CHILD           {0x01;}
sub FL_DAMAGE_EXPOSE          {0x02;}
sub FL_DAMAGE_SCROLL          {0x04;}
sub FL_DAMAGE_OVERLAY         {0x08;}
sub FL_DAMAGE_HIGHLIGHT       {0x10;}
sub FL_DAMAGE_CHILD_LABEL     {0x20;}
sub FL_DAMAGE_LAYOUT          {0x40;}
sub FL_DAMAGE_ALL             {0x80;}

sub FL_IMAGE_PNG              {1;}
sub FL_IMAGE_XPM              {2;}
sub FL_IMAGE_GIF              {3;}
sub FL_IMAGE_JPEG             {4;}
sub FL_IMAGE_BMP              {5;}

sub FL_NO_COLOR               {0;}
sub FL_GRAY_RAMP              {32;}
sub FL_GRAY                   {49;}
sub FL_INACTIVE_COLOR         {39;}
sub FL_COLOR_CUBE             {0x38;}
sub FL_BLACK                  {0x38;}
sub FL_RED                    {0x58;}
sub FL_GREEN                  {0x3f;}
sub FL_YELLOW                 {0x5f;}
sub FL_BLUE                   {0xd8;}
sub FL_MAGENTA                {0xf8;}
sub FL_CYAN                   {0xdf;}
sub FL_WHITE                  {0xff;}
sub FL_BLUE_SELECTION_COLOR   {0x88;}

sub FL_VERTICAL               {0;}
sub FL_HORIZONTAL             {1;}
sub FL_VERT_SLIDER            {0;}
sub FL_HOR_SLIDER             {1;}
sub FL_VERT_FILL_SLIDER       {2;}
sub FL_HOR_FILL_SLIDER        {3;}
sub FL_VERT_NICE_SLIDER       {4;}
sub FL_HOR_NICE_SLIDER        {5;}

sub FL_RESERVED_TYPE          {0x64;}

sub FL_TOGGLE_BUTTON          {return (FL_RESERVED_TYPE + 1);}
sub FL_RADIO_BUTTON           {return (FL_RESERVED_TYPE + 2);}
sub FL_HIDDEN_BUTTON          {return (FL_RESERVED_TYPE + 3);}

sub FL_SOLID                  {0;}
sub FL_DASH                   {1;}
sub FL_DOT                    {2;}
sub FL_DASHDOT                {3;}
sub FL_DASHDOTDOT             {4;}
sub FL_CAP_FLAT               {0x100;}
sub FL_CAP_ROUND              {0x200;}
sub FL_CAP_SQUARE             {0x300;}
sub FL_JOIN_MITER             {0x1000;}
sub FL_JOIN_ROUND             {0x2000;}
sub FL_JOIN_BEVEL             {0x3000;}

bootstrap FLTK $VERSION;

# Enormous freakin list of exported constants. May want to be nice to perl
# namespace and make these EXPORT_OK, but just EXPORT follows FLTK coding 
# style better.

%EXPORT_TAGS = (
'Boxtypes'    => [qw(
FL_UP_BOX
FL_NORMAL_BOX
FL_DOWN_BOX
FL_THIN_UP_BOX
FL_THIN_BOX
FL_THIN_DOWN_BOX
FL_ENGRAVED_BOX
FL_EMBOSSED_BOX
FL_BORDER_BOX
FL_FLAT_BOX
FL_HIGHLIGHT_UP_BOX
FL_FLAT_UP_BOX
FL_HIGHLIGHT_BOX
FL_HIGHLIGHT_DOWN_BOX
FL_FLAT_DOWN_BOX
FL_ROUND_UP_BOX
FL_ROUND_BOX
FL_ROUND_DOWN_BOX
FL_DIAMOND_UP_BOX
FL_DIAMOND_BOX
FL_DIAMOND_DOWN_BOX
FL_NO_BOX
FL_SHADOW_BOX
FL_ROUNDED_BOX
FL_RSHADOW_BOX
FL_RFLAT_BOX
FL_OVAL_BOX
FL_OSHADOW_BOX
FL_OFLAT_BOX
FL_BORDER_FRAME
)],
'Labeltypes'  => [qw(
FL_NORMAL_LABEL
FL_NO_LABEL
FL_SYMBOL_LABEL
FL_SHADOW_LABEL
FL_ENGRAVED_LABEL
FL_EMBOSSED_LABEL
)],
'Events'      => [qw(
FL_NO_EVENT
FL_PUSH
FL_RELEASE
FL_ENTER
FL_LEAVE
FL_DRAG
FL_FOCUS
FL_UNFOCUS
FL_KEY
FL_KEYUP
FL_MOVE
FL_SHORTCUT
FL_ACTIVATE
FL_DEACTIVATE
FL_SHOW
FL_HIDE
FL_VIEWCHANGE
FL_PASTE
FL_DND_ENTER
FL_DND_DRAG
FL_DND_LEAVE
FL_DND_RELEASE
FL_KEYBOARD
)],
'When'        => [qw(
FL_WHEN_NEVER
FL_WHEN_CHANGED
FL_WHEN_RELEASE
FL_WHEN_RELEASE_ALWAYS
FL_WHEN_ENTER_KEY
FL_WHEN_ENTER_KEY_ALWAYS
FL_WHEN_ENTER_KEY_CHANGED
FL_WHEN_NOT_CHANGED
FL_READ
FL_WRITE
FL_EXCEPT
)],
'Keytypes'    => [qw(
FL_Button
FL_BackSpace
FL_Tab
FL_Clear
FL_Enter
FL_Pause
FL_Scroll_Lock
FL_Escape
FL_Home
FL_Left
FL_Up
FL_Right
FL_Down
FL_Page_Up
FL_Page_Down
FL_End
FL_Print
FL_Insert
FL_Menu
FL_Num_Lock
FL_KP
FL_KP_Enter
FL_KP_Last
FL_F
FL_F_Last
FL_Shift_L
FL_Shift_R
FL_Control_L
FL_Control_R
FL_Caps_Lock
FL_Meta_L
FL_Meta_R
FL_Alt_L
FL_Alt_R
FL_Delete
FL_LEFT_MOUSE
FL_MIDDLE_MOUSE
FL_RIGHT_MOUSE 
FL_SHIFT
FL_CAPS_LOCK
FL_CTRL
FL_ALT
FL_NUM_LOCK
FL_META
FL_SCROLL_LOCK
FL_BUTTON1
FL_BUTTON2
FL_BUTTON3
)],
'Cursors'     => [qw(
FL_CURSOR_DEFAULT
FL_CURSOR_ARROW
FL_CURSOR_CROSS
FL_CURSOR_WAIT
FL_CURSOR_INSERT
FL_CURSOR_HAND
FL_CURSOR_HELP
FL_CURSOR_MOVE
FL_CURSOR_NS
FL_CURSOR_WE
FL_CURSOR_NWSE
FL_CURSOR_NESW
FL_CURSOR_NONE
FL_CURSOR_N
FL_CURSOR_NE
FL_CURSOR_E
FL_CURSOR_SE
FL_CURSOR_S
FL_CURSOR_SW
FL_CURSOR_W
FL_CURSOR_NW
)],
'Modes'       => [qw(
FL_RGB
FL_INDEX
FL_SINGLE
FL_DOUBLE
FL_ACCUM
FL_ALPHA
FL_DEPTH
FL_STENCIL
FL_RGB8
FL_MULTISAMPLE
)],
'Damage'      => [qw(
FL_DAMAGE_CHILD
FL_DAMAGE_EXPOSE
FL_DAMAGE_SCROLL
FL_DAMAGE_OVERLAY
FL_DAMAGE_HIGHLIGHT
FL_DAMAGE_CHILD_LABEL
FL_DAMAGE_LAYOUT
FL_DAMAGE_ALL
)],
'Imagetypes'  => [qw(
FL_IMAGE_PNG
FL_IMAGE_XPM
FL_IMAGE_GIF
FL_IMAGE_JPEG
FL_IMAGE_BMP
)],
'Flags'       => [qw(
FL_ALIGN_CENTER
FL_ALIGN_TOP
FL_ALIGN_BOTTOM
FL_ALIGN_LEFT
FL_ALIGN_RIGHT
FL_ALIGN_INSIDE
FL_ALIGN_TILED
FL_ALIGN_CLIP
FL_ALIGN_WRAP
FL_ALIGN_MASK
FL_INACTIVE
FL_MENU_STAYS_UP
FL_VALUE
FL_OPEN
FL_INVISIBLE
FL_OUTPUT
FL_CHANGED
FL_COPIED_LABEL
FL_FOCUSED
FL_HIGHLIGHT
FL_FRAME_ONLY
FL_SELECTED
FL_NO_SHORTCUT_LABEL
)],
'Colors'      => [qw(
FL_NO_COLOR
FL_GRAY_RAMP
FL_GRAY
FL_INACTIVE_COLOR
FL_COLOR_CUBE
FL_BLACK
FL_RED
FL_GREEN
FL_YELLOW
FL_BLUE
FL_MAGENTA
FL_CYAN
FL_WHITE
FL_BLUE_SELECTION_COLOR
)],
'Slidertypes'  => [qw(
FL_VERTICAL
FL_HORIZONTAL
FL_VERT_SLIDER
FL_HOR_SLIDER
FL_VERT_FILL_SLIDER
FL_HOR_FILL_SLIDER
FL_VERT_NICE_SLIDER
FL_HOR_NICE_SLIDER
)],
'Buttons'     => [qw(
FL_TOGGLE_BUTTON
FL_RADIO_BUTTON
FL_HIDDEN_BUTTON
)],
'Utils'       => [qw(
widget_type
fl_file_chooser
fl_message
fl_alert
fl_ask
fl_choice
fl_input
fl_password
fl_message_icon
fl_color_chooser
fl_show_colormap
fl_gray_ramp
fl_color_cube
fl_rgb
fl_color_average
fl_inactive
fl_contrast
fl_get_color
fl_set_color
fl_free_color
fl_background
fl_nearest_color
)],
'Fonts'       => [qw(
FL_HELVETICA
FL_HELVETICA_BOLD
FL_HELVETICA_ITALIC
FL_HELVETICA_BOLD_ITALIC
FL_COURIER
FL_COURIER_BOLD
FL_COURIER_ITALIC
FL_COURIER_BOLD_ITALIC
FL_TIMES
FL_TIMES_BOLD
FL_TIMES_ITALIC
FL_TIMES_BOLD_ITALIC
FL_SYMBOL
FL_SCREEN
FL_SCREEN_BOLD
FL_ZAPF_DINGBATS
fl_font
fl_size
fl_height
fl_descent
fl_width
)],
'Drawing'     => [qw(
fl_clip
fl_clip_out
fl_push_no_clip
fl_pop_clip
fl_not_clipped
fl_clip_box
fl_line_style
FL_SOLID
FL_DASH
FL_DOT
FL_DASHDOT
FL_DASHDOTDOT
FL_CAP_FLAT
FL_CAP_ROUND
FL_CAP_SQUARE
FL_JOIN_MITER
FL_JOIN_ROUND
FL_JOIN_BEVEL
fl_point
fl_rect
fl_rectf
fl_line
fl_loop
fl_polygon
fl_xyline
fl_yxline
fl_arc
fl_pie
fl_push_matrix
fl_pop_matrix
fl_scale
fl_translate
fl_rotate
fl_mult_matrix
fl_begin_points
fl_begin_line
fl_begin_loop
fl_begin_polygon
fl_vertex
fl_curve
fl_circle
fl_end_points
fl_end_line
fl_end_loop
fl_end_polygon
fl_begin_complex_polygon
fl_gap
fl_end_complex_polygon
fl_transform_x
fl_transform_y
fl_transform_dx
fl_transform_dy
fl_transformed_vertex
)]
);

Exporter::export_ok_tags('Boxtypes');
Exporter::export_ok_tags('Labeltypes');
Exporter::export_ok_tags('Events');
Exporter::export_ok_tags('When');
Exporter::export_ok_tags('Keytypes');
Exporter::export_ok_tags('Cursors');
Exporter::export_ok_tags('Modes');
Exporter::export_ok_tags('Damage');
Exporter::export_ok_tags('Imagetypes');
Exporter::export_ok_tags('Flags');
Exporter::export_ok_tags('Colors');
Exporter::export_ok_tags('Slidertypes');
Exporter::export_ok_tags('Buttons');
Exporter::export_ok_tags('Utils');
Exporter::export_ok_tags('Fonts');
Exporter::export_ok_tags('Drawing');

package Fl_Group;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Widget );

package Fl_Window;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Group );

package Fl_Double_Window;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Window );

package Fl_Align_Group;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Group );

package Fl_Box;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Widget );

package Fl_Button;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Widget );

package Fl_Check_Button;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Button );

package Fl_Highlight_Button;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Button );

package Fl_Light_Button;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Check_Button );

package Fl_Round_Button;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Check_Button );

package Fl_Radio_Button;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Check_Button );

package Fl_Radio_Round_Button;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Round_Button );

package Fl_Radio_Light_Button;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Light_Button );


package Fl_Toggle_Button;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Button );

package Fl_Toggle_Round_Button;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Round_Button );

package Fl_Toggle_Light_Button;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Light_Button );

package Fl_Repeat_Button;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Button );

package Fl_Return_Button;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Button );

package Fl_Input;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Widget );

package Fl_Float_Input;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Input );

package Fl_Int_Input;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Input );

package Fl_Multiline_Input;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Input );

package Fl_Secret_Input;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Input );

package Fl_Wordwrap_Input;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Input );

package Fl_Output;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Input );

package Fl_Multiline_Output;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Output );

package Fl_Wordwrap_Output;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Output );

package Fl_Tabs;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Group );

package Fl_Pack;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Group );

sub VERTICAL    {0;}
sub HORIZONTAL  {1;}

package Fl_Scroll;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Group );

sub HORIZONTAL        {1;}
sub VERTICAL          {2;}
sub BOTH              {3;}
sub ALWAYS_ON         {4;}
sub HORIZONTAL_ALWAYS {5;}
sub VERTICAL_ALWAYS   {6;}
sub BOTH_ALWAYS       {7;}

package Fl_Tile;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Group );

package Fl_Menu_;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Group );

package Fl_Item_Group;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Menu_ );

package Fl_Menu_Bar;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Menu_ );

package Fl_Menu_Button;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Menu_ );

sub NORMAL      {224;}
sub POPUP1      {225;}
sub POPUP2      {226;}
sub POPUP12     {227;}
sub POPUP3      {228;}
sub POPUP13     {229;}
sub POPUP23     {230;}
sub POPUP123    {231;}

package Fl_Choice;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Menu_ );

package Fl_Browser;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Menu_ );

sub HORIZONTAL          {1;}
sub VERTICAL            {2;}
sub BOTH                {3;}
sub ALWAYS_ON           {4;}
sub HORIZONTAL_ALWAYS   {5;}
sub VERTICAL_ALWAYS     {6;}
sub BOTH_ALWAYS         {7;}
sub MULTI_BROWSER       {8;}
sub FL_NORMAL_BROWSER   {3;}
sub FL_MULTI_BROWSER    { return (BOTH|MULTI_BROWSER);}

sub HERE                {0;}
sub FOCUS               {1;}
sub FIRST_VISIBLE       {2;}
sub REDRAW_0            {3;}
sub REDRAW_1            {4;}
sub USER_0              {5;}
sub USER_1              {6;}
sub NUMMARKS            {7;}

package Fl_Hold_Browser;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Browser );

package Fl_Multi_Browser;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Browser );

package Fl_Select_Browser;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Browser );

package Fl_Item;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Widget );

package Fl_Radio_Item;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Item );

package Fl_Toggle_Item;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Item );

package Fl_Image;
use strict;

package Fl_Pixmap;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Image );

package Fl_Shared_Image;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Image );

package Fl_Valuator;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Widget );

package Fl_Slider;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Valuator );

package Fl_Fill_Slider;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Slider );

package Fl_Value_Slider;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Slider );

package Fl_Hor_Slider;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Slider );

package Fl_Hor_Fill_Slider;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Slider );

package Fl_Hor_Value_Slider;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Value_Slider );

package Fl_Nice_Slider;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Slider );

package Fl_Hor_Nice_Slider;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Slider );

package Fl_Scrollbar;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Slider );

package Fl_Text_Buffer;
use strict;

sub load_file {
  my ($pkg, $fname) = @_;
  open(INFILE, "$fname") or die "Unable to open $fname: $!";
  undef $/;
  my $inbuffer = <INFILE>;
  $inbuffer =~ s/([\015])//g;
  close(INFILE);
  $/ = "\n";

  $pkg->text($inbuffer);
}

package Fl_Text_Display;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Group );

sub NORMAL_CURSOR       {0;}
sub CARET_CURSOR        {1;}
sub DIM_CURSOR          {2;}
sub BLOCK_CURSOR        {3;}
sub HEAVY_CURSOR        {4;}

sub CURSOR_POS          {0;}
sub CHARACTER_POS       {1;}

sub DRAG_CHAR           {0;}
sub DRAG_WORD           {1;}
sub DRAG_LINE           {2;}

package Fl_Text_Editor;
use strict;
use vars qw(@ISA);
@ISA = qw( Fl_Text_Display );

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

FLTK - Perl interface to the Fast Light Toolkit Library

=head1 SYNOPSIS

  use FLTK qw( :Boxtypes );
  
  $window = new Fl_Window(110, 40, "$0");
  $button = new Fl_Highlight_Button(5, 5, 100, 30, "Hello World!");
  $button->callback(sub {exit;});
  $button->box(FL_THIN_UP_BOX);
  $window->end();
  
  $window->show();
  FLTK::run();

=head1 DESCRIPTION

This modules provides hooks to create GUI interfaces using the Fast Light
Toolkit Library in Perl. This documentation is barely started, let alone 
near completion.

The Perl interface to FLTK is designed to emulate FLTK's C++ API as closely 
as possible. Developers already well aquainted with the FLTK toolkit should 
be able to figure this thing out fairly easily.

Real documentation for FLTK is available at <http://fltk.org/>.

Please note that this module is for FLTK version 2, which is currently in 
CVS. This module is 100% guaranteed to choke and die horribly if you try to 
build it against FLTK 1, which is the stable release.

=head1 AUTHOR

Matt Kennedy <matt@jumpline.com>

=head1 SEE ALSO

perl(1).

=cut
