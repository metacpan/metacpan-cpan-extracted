use v5.40;
use blib;
use LibUI qw[:all];
use Affix qw[:all];
my $mainwin;
my $cached_fd;
my $cached_tlp;
my $cached_tlp_view;
uiInit( { Size => 0 } );
$mainwin = uiNewWindow( 'Attributed String Demo', 600, 300, 0 );
uiWindowOnClosing( $mainwin, sub ( $w, $data ) { uiQuit(); 1 }, undef );
uiOnShouldQuit( sub ($data) {1}, $mainwin );
uiWindowSetMargined( $mainwin, 1 );
my $vbox = uiNewVerticalBox();
uiBoxSetPadded( $vbox, 1 );
uiWindowSetChild( $mainwin, $vbox );
my $lbl = uiNewLabel('Styled text rendered via AttributedString + DrawTextLayout');
uiBoxAppend( $vbox, $lbl, 0 );
my $area = uiNewArea(
    {   Draw => sub ( $ah, $a, $p ) {
            my $dc = $p->{Context};
            unless ($cached_fd) {
                $cached_fd = calloc( 1, sizeof( LibUI::FontDescriptor() ) );
                my $load = Affix::wrap( Alien::libui->dynamic_libs, 'uiLoadControlFont', [ Pointer [ LibUI::FontDescriptor() ] ] => Void );
                $load->($cached_fd);
            }
            unless ($cached_tlp) {
                $cached_tlp      = calloc( 1, sizeof( LibUI::DrawTextLayoutParams() ) );
                $cached_tlp_view = Affix::cast( $cached_tlp, Pointer [ LibUI::DrawTextLayoutParams() ] );
            }
            my $str = uiNewAttributedString("Attributed String Demo\n");
            uiAttributedStringAppendUnattributed( $str, 'Normal text  ' );
            uiAttributedStringAppendUnattributed( $str, 'Bold  ' );
            my $len  = uiAttributedStringLen($str);
            my $bold = uiNewWeightAttribute(700);
            uiAttributedStringSetAttribute( $str, $bold, $len - 5, $len - 1 );
            uiAttributedStringAppendUnattributed( $str, 'Italic  ' );
            $len = uiAttributedStringLen($str);
            my $italic = uiNewItalicAttribute(2);
            uiAttributedStringSetAttribute( $str, $italic, $len - 8, $len - 2 );
            uiAttributedStringAppendUnattributed( $str, 'Red  ' );
            $len = uiAttributedStringLen($str);
            my $red = uiNewColorAttribute( 0.9, 0.2, 0.2, 1.0 );
            uiAttributedStringSetAttribute( $str, $red, $len - 5, $len - 1 );
            uiAttributedStringAppendUnattributed( $str, 'Big  ' );
            $len = uiAttributedStringLen($str);
            my $big = uiNewSizeAttribute(24.0);
            uiAttributedStringSetAttribute( $str, $big, $len - 5, $len - 1 );
            uiAttributedStringAppendUnattributed( $str, 'Small  ' );
            $len = uiAttributedStringLen($str);
            my $small = uiNewSizeAttribute(9.0);
            uiAttributedStringSetAttribute( $str, $small, $len - 7, $len - 1 );
            uiAttributedStringAppendUnattributed( $str, "\nUnderline  " );
            $len = uiAttributedStringLen($str);
            my $ul = uiNewUnderlineAttribute(1);
            uiAttributedStringSetAttribute( $str, $ul, $len - 11, $len - 2 );
            uiAttributedStringAppendUnattributed( $str, 'Highlighted  ' );
            $len = uiAttributedStringLen($str);
            my $bg = uiNewBackgroundAttribute( 1.0, 0.9, 0.2, 1.0 );
            uiAttributedStringSetAttribute( $str, $bg, $len - 14, $len - 1 );
            uiAttributedStringAppendUnattributed( $str, 'Bold Blue' );
            $len = uiAttributedStringLen($str);
            my $bold_blue_w = uiNewWeightAttribute(800);
            my $bold_blue_c = uiNewColorAttribute( 0.1, 0.3, 0.9, 1.0 );
            uiAttributedStringSetAttribute( $str, $bold_blue_w, $len - 9, $len );
            uiAttributedStringSetAttribute( $str, $bold_blue_c, $len - 9, $len );
            $$cached_tlp_view->{String}      = $str;
            $$cached_tlp_view->{DefaultFont} = $cached_fd;
            $$cached_tlp_view->{Width}       = $p->{AreaWidth};
            $$cached_tlp_view->{Align}       = 0;
            my $layout = uiDrawNewTextLayout($cached_tlp);
            uiDrawText( $dc, $layout, 10.0, 10.0 );
            uiDrawFreeTextLayout($layout);
            uiFreeAttributedString($str);
        }
    }
);
uiBoxAppend( $vbox, $area, 1 );
uiControlShow($mainwin);
uiMain();
