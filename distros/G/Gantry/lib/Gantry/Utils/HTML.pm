package Gantry::Utils::HTML;
require Exporter;

use strict;
use Carp qw( croak );
use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

############################################################
# Variables                                                #
############################################################
@ISA        = qw( Exporter );
@EXPORT     = qw();
@EXPORT_OK  = qw(   ht_a
                    ht_b ht_br
                    ht_checkbox
                    ht_div ht_udiv
                    ht_form ht_form_js
                    ht_h
                    ht_help
                    ht_i ht_img ht_input 
                    ht_lines
                    ht_p ht_popup
                    ht_qt
                    ht_radio
                    ht_select ht_submit
                    ht_table ht_tr ht_td ht_utd
                    ht_uform ht_up ht_uqt ht_utable ht_utr );

%EXPORT_TAGS =( 'common'    => [qw/ ht_a ht_br ht_img ht_lines ht_qt ht_uqt/ ],
                'style'     => [qw/ ht_div ht_udiv ht_b ht_h ht_i ht_p ht_up/],
                'form'      => [qw/ ht_checkbox ht_form ht_form_js
                                    ht_input ht_radio ht_select 
                                    ht_submit ht_uform / ],
                'table'     => [qw/ ht_table ht_tr ht_td ht_utd ht_utr
                                    ht_utable / ],
                'jscript'   => [qw/ ht_help ht_popup / ],
                'all'       => [qw/ ht_a
                                    ht_div ht_udiv
                                    ht_b ht_br
                                    ht_checkbox
                                    ht_form ht_form_js
                                    ht_h
                                    ht_help
                                    ht_i ht_img ht_input 
                                    ht_lines
                                    ht_p ht_popup
                                    ht_qt
                                    ht_radio
                                    ht_select ht_submit
                                    ht_table ht_tr ht_td ht_utd
                                    ht_uform ht_up ht_uqt ht_utable ht_utr / ]);

############################################################
# Functions                                                #
############################################################

#-------------------------------------------------
# ht_a( $url, $text, @extras )
#-------------------------------------------------
sub ht_a { 
    my ( $url, $text, @extras ) = @_;

    return( join( ' ', qq!<a href="$url"!, @extras, qq!>$text</a>! ) );
} # END ht_a 

#-------------------------------------------------
# ht_b( @inside )
#-------------------------------------------------
sub ht_b {
    return( join( '', '<b>', @_, '</b>' ) );
} # END ht_b

#-------------------------------------------------
# ht_br()
#-------------------------------------------------
sub ht_br { 
    return( '<br />' );
} # END ht_br

#-------------------------------------------------
# ht_div( $options, @data )
#-------------------------------------------------
sub ht_div {
    my ( $options, @data ) = @_;

    my @params = ( '<div' );

    for my $option ( keys %{$options} ) {
        next if ( ! defined $$options{$option} );

        push( @params, qq!$option="$$options{$option}"! );
    }

    if ( scalar( @data ) > 0 ) {
        return( join( ' ', @params, '>' ), @data, '</div>' );
    }

    return( join( ' ', @params, '>' ) );
} # END ht_div

#-------------------------------------------------
# ht_udiv( )
#-------------------------------------------------
sub ht_udiv {
    return( '</div>' );
} # END ht_udiv

# START alphabetizing here.

#-------------------------------------------------
# ht_qt( $string )
#-------------------------------------------------
sub ht_qt {
    my $string = shift || '';

    # This removes possibly unsafe characters from this to be outputted. 

    $string =~ s/&/&amp;/g;
    $string =~ s/"/&quot;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;

    return( $string );
} # END of ht_qt

#-------------------------------------------------
# ht_uqt
#-------------------------------------------------
sub ht_uqt {
    my $string = shift;

    # Puts the bad characters back, for editing.

    $string =~ s/&quot;/"/g;
    $string =~ s/&lt;/</g;
    $string =~ s/&gt;/>/g;
    $string =~ s/&amp;/&/g;

    return( $string );
} # END of ht_qt

#-------------------------------------------------
# ht_lines( @lines )
#-------------------------------------------------
sub ht_lines { 
    return( join( "\n", @_, "\n" ) );
} # END ht_lines

#-------------------------------------------------
# ht_img( $url, @extras )
#-------------------------------------------------
sub ht_img { 
    my ( $url, @extra ) = @_;

    return( join( ' ', qq!<img src="$url"!, @extra , '/>' ) );
} # END ht_img

#-------------------------------------------------
# ht_p()
#-------------------------------------------------
sub ht_p {
    return( '<p>' );
} # END ht_p

#-------------------------------------------------
# ht_up()
#-------------------------------------------------
sub ht_up {
    return( '</p>' );
} # END ht_up

#-------------------------------------------------
# ht_i( @inside )
#-------------------------------------------------
sub ht_i {
    return( join( '', '<i>', @_, '</i>' ) );
} # END ht_i

#-------------------------------------------------
# ht_h( $level, @text )
#-------------------------------------------------
sub ht_h {
    my ( $level, @text ) = @_;

    $level = 3 if ( ( ! defined $level ) || ( $level eq '' ) );

    return( join( '', "<h$level>", @text, "</h$level>" ) );

} # END ht_h

#-------------------------------------------------
# ht_form( $action, @params )
#-------------------------------------------------
sub ht_form {
    my ( $action, @params ) = @_;
    
    # Starts a HTML form, check to make sure we have an action to
    # perform

    croak 'No action in ht_form()' if ( ! defined $action );

    return( qq!<form method="post" action="$action"!.  
            join( ' ', @params ). '>' );

} # END ht_form 

#-------------------------------------------------
# ht_form_js( $action, @params )
#-------------------------------------------------
sub ht_form_js { 
    my ( $action, @params ) = @_;

    # This form inserts some JavaScript to make sure we handle the case
    # if someone clicks the submit button twice really quickly

    # Take the js out of this and make it a ht_js function and get rid
    # of this routine ?

    croak 'No action in ht_form_js' if ( ! defined $action );

    push( @params, 'onsubmit="return AntiClicker()"' ); 

    return( q!<script type="text/javascript">!,
            q! <\!--!, 
            q! var button_clicked = false; !,
            q! function AntiClicker() { !,
            q! if(button_clicked == true) { !,
            q!   return false; !,
            q! } !,
            q! button_clicked = true; !,
            q! return true; !,
            q! } !,
            q! // --> !,
            q!</script>!,
            qq!<form method="post" action="$action" !.
            join( ' ', @params ) . ' > ' );

} # END ht_form_js

#-------------------------------------------------
# ht_uform()
#-------------------------------------------------
sub ht_uform () { 
    return( '</form>' );
} # END ht_uform

#-------------------------------------------------
# ht_input( $name, $type, $vals, @params )
#-------------------------------------------------
sub ht_input { 
    my ( $name, $type, $vals, @params ) = @_;

    my $in = ''; 

    if ( ref( $vals ) eq 'HASH' || ref( $vals ) eq 'Apache::Request::Table' ) { 
        $in = ( exists $vals->{$name} ) ? $vals->{$name} : '';
    }
    else {
        $in = ( defined $vals ) ? $vals : '' ; 
    }

    $in = ht_qt( $in );

    # Handle text areas
    if ( $type =~ /^textarea$/i ) { 
        return( join( ' ', "<textarea name='$name'", @params ).
                ">$in</textarea>"   );
    }
    
    my $params  = join( ' ', @params );
    $params     = '' if ( $params =~ /^\s+$/ );

    return( qq!<input type="$type" name="$name" value="$in" $params />! ); #/
} # END ht_input

#-------------------------------------------------
# ht_checkbox( $name, $value, $checked, @params )
#-------------------------------------------------
sub ht_checkbox {
    my ( $name, $value, $check, @params ) = @_;

    my $in = ''; 

    if ( ref( $check ) eq 'HASH' || ref($check) eq 'Apache::Request::Table' ) { 
        $in = ( exists $check->{$name} ) ? $check->{$name} : '';
    }
    else {
        $in = ( defined $check ) ? $check : '' ; 
    }

    my $chk     = ( $value eq $in ) ? 'checked="checked"' : '';
    my $params  = join( ' ', @params );
    $params     = '' if ( ! defined $params || $params =~ /^\s+$/ );

    return( qq!<input type="checkbox" name="$name" $chk value="$value" !.
            qq!$params />! ); #/
} # END ht_checkbox

#-------------------------------------------------
# ht_radio( $name, $value, $checked, @params )
#-------------------------------------------------
sub ht_radio {
    my ( $name, $value, $check, @params ) = @_;

    my $in = ''; 

    if ( ref( $check ) eq 'HASH' || ref( $check ) eq 'Apache::Request::Table' ) { 
        $in = ( exists $check->{$name} ) ? $check->{$name} : '';
    }
    else {
        $in = ( defined $check ) ? $check : '' ; 
    }

    my $chk     = ( $value eq $in ) ? 'checked="checked"' : '';
    my $params  = join( ' ', @params );
    $params     = '' if ( ! defined $params || $params =~ /^\s+$/ );

    return( qq!<input type="radio" name="$name" $chk value="$value" !.
            qq!$params />! ); #/
} # END ht_radio

#-------------------------------------------------
# ht_select( $name, $size, $value, @items )
#-------------------------------------------------
sub ht_select {
    my ( $name, $size, $vals, $multiple, $opts, @items ) = @_;

    my ( @names, $lines ); 

    my $value   = '';
    $opts       = '' if ( ! defined $opts );

    if ( ref( $vals ) eq 'HASH' || ref( $vals ) eq 'Apache::Request::Table' ) { 
        $value = ( exists $vals->{$name} ) ? $vals->{$name} : '';
    }
    else {
        $value = ( defined $vals ) ? $vals : '' ; 
    }

    while ( @items ) { 
        my $opt_value = shift( @items );
        my $opt_name  = shift( @items );

        my $sltd = ( $opt_value eq $value ) ? ' selected' : '';

        $lines .= qq!<option $sltd value="$opt_value">$opt_name</option>\n!;
    }

    $multiple = ( ( defined $multiple && $multiple )  ? ' MULTIPLE ' : ' ' );

    return( qq!<select name="$name" size="$size" $multiple $opts>\n!,
            $lines, '</select>' );

} # END ht_select

#-------------------------------------------------
# ht_submit( $name, $value )
#-------------------------------------------------
sub ht_submit { 
    my ( $name, $value ) = @_;

    return( qq!<input type="submit" name="$name" value="$value" />! ); #/
} # END ht_submit

#-------------------------------------------------
# ht_help( $help_root, $type, $ident )
#-------------------------------------------------
sub ht_help {
    my ( $help_root, $type, $ident ) = @_;

    $type       = ( defined $type && $type =~ /cat/ ) ? 'category' : 'item';
    my $url     = "$help_root/$type/$ident";

    return( join( '',   '[', 
                        ht_a(   'javascript://', ' ? ',
                                qq!onClick="window.open('$url', 'helpwindow', !,
                                q! 'height=300,width=400' +  !,
                                q! ',screenX=' + (window.screenX+150) + !,
                                q! ',screenY=' + (window.screenY+100) + !,
                                q! ',scrollbars,resizable' );"!,
                                'class="help"' ),
                        ']' ) );
} # END ht_help

#-------------------------------------------------
# ht_popup( $url, $text, $winname, $x, $y ) 
#-------------------------------------------------
sub ht_popup {
    my ( $url, $text, $winname, $height, $width ) = @_; 
    
    $height = '250' if ( ! defined $height );
    $width  = '250' if ( ! defined $width ); 
    
    return( ht_a(   'javascript://', $text,
                    qq!onClick="window.open('$url', '$winname', !,
                    qq! 'height=$height,width=$width' +  !,
                    q! ',screenX=' + (window.screenX+150) + !,
                    q! ',screenY=' + (window.screenY+100) + !,
                    q! ',scrollbars,resizable' );"! ) );
} # END ht_popup

#-------------------------------------------------
# ht_table( $options )
#-------------------------------------------------
sub ht_table {
    my $options = shift;

    my @params;

    for my $option ( keys %{$options} ) {
        push( @params, "$option='$$options{$option}'" );
    }

    return( join( ' ', '<table', @params, '>' ) );
} # END ht_table

#-------------------------------------------------
# ht_tr( $options )
#-------------------------------------------------
sub ht_tr {
    my $options = shift;

    my @params;
    
    for my $option ( keys %{$options} ) {
        push( @params, "$option='$$options{$option}'" );
    }

    return( join( ' ', '<tr', @params, '>' ) );
} # END ht_tr

#-------------------------------------------------
# ht_td( $options, @data )
#-------------------------------------------------
sub ht_td {
    my ( $options, @data ) = @_;

    my @params;

    for my $option ( keys %{$options} ) {
        if ( $option !~ /nowrap/i ) {
            push( @params, qq!$option="$$options{$option}"! );
        }
        else {
            push( @params, 'NOWRAP' );
        }
    }

    if ( scalar( @data ) > 0 ) {
        return( join( ' ', '<td', @params, '>' ), @data, '</td>' );
    }

    return( join( ' ', '<td', @params, '>' ) );
} # END ht_td

#-------------------------------------------------
# ht_utd()
#-------------------------------------------------
sub ht_utd () {
    return( '</td>' );
} # END ht_utr

#-------------------------------------------------
# ht_utr()
#-------------------------------------------------
sub ht_utr () {
    return( '</tr>' );
} # END ht_utr

#-------------------------------------------------
# ht_utable()
#-------------------------------------------------
sub ht_utable () {
    return( '</table>' );
} # END ht_utable

# EOF
1;

__END__

=head1 NAME

Gantry::Utils::HTML - HTML tag generators.

=head1 SYNOPSIS

  use Gantry::Utils::HTML qw( :all );

  :common
    ht_a ht_br ht_img ht_lines ht_qt ht_uqt

  :style
    ht_b ht_h ht_i ht_p ht_up ht_div ht_udiv

  :form
    ht_checkbox ht_form ht_form_js ht_input ht_radio ht_select ht_submit
    ht_uform 

  :table
    ht_table ht_tr ht_td ht_utd ht_utr ht_utable

  :jscript
    ht_popup

  ht_a
    @href = ht_a( $url, $text, @extra )

  ht_b
    @bold = ht_b( @text )

  ht_br
    $br = ht_br()

  ht_checkbox
    $checkbox = ht_checkbox( $name, $value, $form_value, @params )


  ht_div
    @div = ht_div( $options, @data )

  ht_form
    $form = ht_form( $action, @extra )

  ht_form_js
    @form = ht_form_js( $action, @extra )

  ht_h
    @h = ht_h( $level, @text )

  ht_help
    @help = ht_help( $help_root, $type, $ident )

  ht_i
    @i = ht_i( @text )

  ht_img
    @img = ht_img( $url, @extra )

  ht_input
    @input = ht_input( $name, $type, $value @params )

  ht_lines
    $lines = ht_lines( @lines )

  ht_p
    $p = ht_p()

  ht_popup
    @popup = ht_popup( $url, $text, $winname, $height, $width )

  ht_qt
    $string = ht_qt( $string )

  ht_radio
    $radio = ht_radio( $name, $value, $form_value, @params )

  ht_select
    @select = ht_select( $name, $size, $value, $multiple,
                         $opts, @items )

  ht_submit
    $submit = ht_submit( $name, $value )

  ht_table
    $table = ht_table( $options )

  ht_tr
    $tr = ht_tr( $options )

  ht_td
    @td = ht_td( $options, @data )

  ht_udiv
    $udiv = ht_udiv()

  ht_uform
    $uform = ht_uform() 

  ht_up
    $up = ht_up() 

  ht_uqt
    $string = ht_uqt( $string )

  ht_utable
    $utable = ht_utable() 

  ht_utd
    $utd = ht_utd()

  ht_utd
    $utd = ht_utd()

  ht_utr
    $utr = ht_utr()

=head1 DESCRIPTION

Implements HTML tags in a browser non-specfic way conforming to 
3.2 and above HTML specifications.

=over 4

=item @href = ht_a( $url, $text, @extra )

This function returns a fully formed href tag. "C<$url>" and "C<$text>" are
required. "C<@extra>" can contain any other tags to add to the href such as
"CLASS='my_href_class'" or an other options a href may take.

=item @bold = ht_b( @text )

This function takes an array or a string of text and then wraps it in "C<<B>>" 
tags. It will always return an array regardless of the input.

=item $br = ht_br()

This function simply returns a "C<<BR>>" html tag, it takes no arguements.

=item $checkbox = ht_checkbox( $name, $value, $form_value, @params )

This function generates individual checkboxes.  "C<$name>" is the name
of the checkbox. "C<$value>" is the value to set for this checkbox.
"C<$form_value> is the currently selected value, for a checkbox to be
checked the $value must be exactly equal to $form_value. An %in hash
with a key of $name may also be used for $form_value. C<@params> is
passed directly to the end of the checkbox, this can be used for
javascript or arbitrary html.

=item $div = ht_div( %attributes )

This takes an optional hash of attributes for a div tag and returns a
scalar containing an opening div tag.

=item $udiv = ht_udiv( )

Returns an ending div tag.

=item $form = ht_form( $action, @extra )

This function takes the action of the form in the first variable "C<$action>"
any other options should be passed in through "C<@extra>". The "C<@extra>"
array should consit of a valid form tag in the form "method='post'".

=item @form = ht_form_js( $action, @extra )

This function behaves exactly the same way the C<ht_form> function works, save 
this function adds a javascript 'anti-click' routine which should keep people
from submitting a form more than one for double clicking the submit button.

=item @h = ht_h( $level, @text )

This function takes a "C<$level>" which is an integer between 1 and 6 
corisponding to the h1 ... h6 tag that is used, there is not checking on 
the value of the integer so any value of level is acceptable to the function
if not as valid html. The "C<@text>" is wrapped in the "h" tags.

=item @help = ht_help( $help_root, $type, $ident )

this function takes the help root, generally '$site{help}' a type,
either 'category' or 'item' and the ident of the help item. It returns
and array of html containing a link that will generate a help popup. 

=item @i = ht_i( @text )

This function takes "C<@text>" and wraps it in "C<<I>>" tags.

=item @img = ht_img( $url, @extra )

This function creates an "C<<IMG SRC=..>>" tag. "C<$url>" is the url to the
image, "C<@extra>" should contain any extra tags that the image tage should
contain. The "C<@extra>" array should contain values of the form "WIDTH='10'".

=item @input = ht_input( $name, $type, $value @params )

This function creates html textareas, checkboxes, text and hidden
elements.  "C<$name>" is the name of the element in the html as used in
the form, "C<$type>" should be the type of the input element, ( ie:
textarea, checkbox, text, radio, or hidden ). "C<$value>" is either a
hash containing the text as a key, or the variable itself. "C<@params>"
contains anything else that needs to be passed to the input type such as
length or the like "LENTGH='1'".

=item $lines = ht_lines( @lines )

This function takes the "C<@lines>" array and concatanates it together with 
newlines "C<\n>" to create a single string.

=item $p = ht_p()

This function takes no arguements and returns a simple C<<P>> tag.

=item @popup = ht_popup( $url, $text, $winname, $height, $width )

This function creates a special html "ref" call. It creates a link to a new
javascript window with the properties specified. The "C<$url>" is the URL
of the new window, "C<$text>" is the text to be displayed by the link. 
"C<$winname>" is the name of the window that will be created. "C<$height>" and
"C<$width>" are the height and the width of the window, respectively.

=item $string = ht_qt( $string )

This function will escape the html special characters in "C<$string>" and 
return the specially formated value of the string.

=item $radio = ht_radio( $name, $value, $form_value, @params )

This function generates individual radio buttons. "C<$name>" is the name
of the radio buttion group. "C<$value>" is the value to set for this
radio button. "C<$form_value> is the currently selected value, for a
radio button to be checked the $value must be exactly equal to
$form_value. An %in hash with a key of $name may also be used for
$form_value. C<@params> is passed directly to the end of the radio
button, this can be used for javascript or arbitrary html.

=item @select = ht_select( $name, $size, $value, $multiple, $opts, @items )

This function creates a html select box. "C<$name>" is the name of select 
box for use in parsing the form. "C<$size>" is the number of rows to show
for the select box. "C<$value>" is the a hash reference which contains the
value that is currently selected with a hash key of the value of "C<$name>".
"C<$multiple>" needs only to be defined to create the select box as a multiple
select rather than a single select box. "C<@items>" is an array/hash of the
values of the select box. C<$opts> will be included directly into the
opening of the select, this allows tweaky javascript things.

=item $submit = ht_submit( $name, $value )

This function creates a submit button with the name of "C<$name>" and the
value of "C<$value>".

=item $table = ht_table( $options )

This function creates an open table tag. It takes a hash reference, 
C<$options>. The hash reference should contain key value pairs corresponding
to the table options ie: 'cellpadding', '0', 'border', '1' or the like.

=item $tr = ht_tr( $options )

This function creates an open table row tag, it operates exactly as the 
C<ht_table()> function does.

=item @td = ht_td( $options, @data )

This function creates a table data completely from the open td tag to the
close td flag. The options flag works like C<ht_table()> and C<ht_tr>. The
C<@data> is what should appear in the table data element. To specify no
wrap set 'nowrap' => '0' or any value since the function will ignore the 
value completely. The @data is optional, if it is not provided then the
td will just issue an opening <td> and the ht_utd function should be
used as well.

=item $uform = ht_uform()

This function should be paried with either C<ht_form> or C<ht_form_js> to 
close a HTML form. 

=item $up = ht_up()

This function returns a "C<</P>>" tag, for use in conjunction with "C<ht_p>".

=item $string = ht_uqt( $string )

This function reverses the affects of the C<ht_qt> function, retuning the 
original sting if passed an encoded string.

=item $utable = ht_utable()

This function closes a HTML table. It don't take anything but it sure 
give a "C<</TABLE>>".

=item $utr = ht_utd()

This function closes a table data. It takes no options.

=item $utr = ht_utr()

This function closes a table row. It takes no options.

=back

=head1 SEE ALSO

Gantry(3)

=head1 LIMITATIONS

Watch out for the context of what the variables return, sometimes
it is an array sometimes it is a string.

=head1 AUTHOR

Nicholas Studt <nstudt@angrydwarf.org>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2003-6, Nicholas Studt.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
