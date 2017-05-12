=head1 NAME

HTML::FormEngine::SkinComplex - a complete but complex FormEngine skin

=head1 ABOUT

This is a complete useable skin for FormEngine, it is based on the
abstract class HTML::FormEngine::Skin.  So read
L<HTML::FormEngine::Skin> for more information on its methods and
about the template system.

It is called I<Complex> because its more flexible than
HTML::FormEngine::SkinClassic but also a bit more complicated.  To
understand it try out I<sendmessages.cgi>, play with it and compare it
to the other examples. Normally you'll be more happy with
I<SkinClassic>.

=cut

######################################################################

package HTML::FormEngine::SkinComplex;

use strict;
use vars qw(@ISA);
use HTML::FormEngine::Skin;
@ISA = qw(HTML::FormEngine::Skin);

######################################################################

#NOTE: its important that templates which do not implement a certain field but are of a generic type (reuseable) begin with _, else the seperate algorithm does not work

sub _get_templ {
  my $confirm_handler = shift;
  my %skin = %{HTML::FormEngine::Skin::_get_templ()};
  my @baseskin = keys(%skin);

  $skin{main} = '
<form action="<&ACTION&>" method="<&METHOD&>" name="<&FORMNAME&>" accept="<&ACCEPT&>" enctype="<&ENCTYPE&>" target="<&TARGET&>" id="<&FORMNAME&>" <&FORM_EXTRA&>>
<table border=<&FORM_TABLE_BORDER&> cellspacing=<&FORM_TABLE_CELLSP&> cellpadding=<&FORM_TABLE_CELLPAD&> align="<&FORM_ALIGN&>" <&FORM_TABLE_EXTRA&>><~
<tr <&FORM_ROW_EXTRA&>><&TEMPL&></tr>~TEMPL FORM_ROW_EXTRA~>
<tr <&LROW_EXTRA&>>
   <td align="<&SUBMIT_ALIGN&>" colspan=3 <&LCOL_EXTRA&>>
      <!<input type="submit" value="<&SUBMIT&>" name="<&FORMNAME&>" <&SUBMIT_EXTRA&>/>!SUBMIT!>
   </td>
</tr>
</table>
<~<&HIDDEN&>~HIDDEN~>
</form>
';
  
  $skin{_row} = '<~<&#start_collect_results #get_value,VALUES1&>
   <td valign="<&TITLE_VALIGN&>" align="<&TITLE_ALIGN&>" <&TD_EXTRA_TITLE&>><!<&#label&><span <&SP_NOTNULL&>><&#not_null&></span>!TITLE!></td>
   <td <&TD_EXTRA&>><&_column <&#arg 0&>,<&#arg 1&>,<&#arg 2&>&></td>
   <td align="<&ERROR_ALIGN&>" valign="<&ERROR_VALIGN&>" <&TD_EXTRA_ERROR&>><&#error&></td><&#seperate ,1&>~~>
';

#original:
#  $skin{_row} = '<~<&#start_collect_results #get_value,VALUES1&>
#   <td valign="<&TITLE_VALIGN&>" align="<&TITLE_ALIGN&>" <&TD_EXTRA_TITLE&>><!<&#label&><span <&SP_NOTNULL&>><&#not_null&></span>!TITLE!></td>
#   <td <&TD_EXTRA&>><&_column <&#arg 0&>&></td>
#   <td align="<&ERROR_ALIGN&>" valign="<&ERROR_VALIGN&>" <&TD_EXTRA_ERROR&>><&#error&></td>~~><&#seperate ,1&>
#';
  
  $skin{_row_notitle} = '<~
   <td colspan=2 <&TD_EXTRA&>><&_column <&#arg 0&>,<&#arg 1&>,<&#arg 2&>&></td>
   <td align="<&ERROR_ALIGN&>" valign="<&ERROR_VALIGN&>" <&TD_EXTRA_ERROR&>><&#error&></td><&#seperate ,1&>~~>
';

#original
#  $skin{_row_notitle} = '<~
#   <td colspan=2 <&TD_EXTRA&>><&_column <&#arg 0&>&></td>
#   <td align="<&ERROR_ALIGN&>" valign="<&ERROR_VALIGN&>" <&TD_EXTRA_ERROR&>><&#error&></td>~~><&#seperate ,1&>
#';
  
  $skin{_row_notitle_noerror} = '<~
   <td colspan=3 <&TD_EXTRA&>><&_column <&#arg 0&>,<&#arg 1&>,<&#arg 2&>&></td><&#seperate ,1&>~~>
';

#original:
#  $skin{_row_notitle_noerror} = '<~
#   <td colspan=3 <&TD_EXTRA&>><&_column <&#arg 0&>&></td>~~><&#seperate ,1&>
#';

  $skin{_row_noerror} = '<~
   <td valign="<&TITLE_VALIGN&>" align="<&TITLE_ALIGN&>" <&TD_EXTRA_TITLE&>><!<&#label&><span <&SP_NOTNULL&>><&#not_null&></span>!TITLE!></td>
   <td <&TD_EXTRA&> colspan=2><&_column <&#arg 0&>,<&#arg 1&>,<&#arg 2&>&></td><&#seperate ,1&>~~>
';

# original
#  $skin{_row_noerror} = '<~
#   <td valign="<&TITLE_VALIGN&>" align="<&TITLE_ALIGN&>" <&TD_EXTRA_TITLE&>><!<&#label&><span <&SP_NOTNULL&>><&#not_null&></span>!TITLE!></td>
#   <td <&TD_EXTRA&> colspan=2><&_column <&#arg 0&>&></td>~~><&#seperate ,1&>
#';
  
  $skin{_row2} = '<~
   <td valign="<&TITLE_VALIGN&>" align="<&TITLE_ALIGN&>" <&TD_EXTRA_TITLE&>><!<&#label&><span <&SP_NOTNULL&>><&#not_null&></span>!TITLE!></td>
   <td <&TD_EXTRA&>  valign="top" colspan=2>
      <table border=0 cellspacing=0 cellpadding=0>
        <tr>
           <td><&_column <&#arg 0&>,<&#arg 1&>,<&#arg 2&>&></td>
        </tr>
        <tr>
          <td align="<&ERROR_ALIGN&>" valign="<&ERROR_VALIGN&>" colspan=3 <&TD_EXTRA_ERROR&>><&#error&></td>
        </tr>
      </table>
   </td><&#seperate ,1&>~~>
   </tr>
';

# original
#  $skin{_row2} = '<~
#   <td valign="<&TITLE_VALIGN&>" align="<&TITLE_ALIGN&>" <&TD_EXTRA_TITLE&>><!<&#label&><span <&SP_NOTNULL&>><&#not_null&></span>!TITLE!></td>
#   <td <&TD_EXTRA&> colspan=2><&_column <&#arg 0&>&></td>~~>
#   </tr>
#   <tr><~
#   <td align="<&ERROR_ALIGN&>" valign="<&ERROR_VALIGN&>" colspan=3 <&TD_EXTRA_ERROR&>><&#error_in&></td>~~><&#seperate ,1&>
#';


#original
  #$skin{_column} = '
  #    <table border=<&TABLE_BORDER&> cellspacing=<&TABLE_CELLSP&> cellpadding=<&TABLE_CELLPAD&> <&TABLE_EXTRA&>><~
  #      <tr <&TR_EXTRA&>><~
  #        <td valign="<&TD_VALIGN&>" <&TD_EXTRA_IN&>><&#seperate&>
  #          <table border=<&TABLE_BORDER_IN&> cellspacing=<&TABLE_CELLSP_IN&> cellpadding=<&TABLE_CELLPAD_IN&> <&TABLE_EXTRA_IN&>>
  #            <tr <&TR_EXTRA_IN&>>
  #              <td align="<&TD_SUBTITLE_ALIGN&>" valign="<&TD_SUBTITLE_VALIGN&>" <&TD_EXTRA_SUBTITLE&>><!<&#label SUBTITLE&><span <&SP_NOTNULL_IN&>><&#not_null ERROR_IN&></span>!SUBTITLE!><&PREFIX&></td>
   #             <td <&TD_EXTRA_IN_IN&>>
   #               <&<&#arg 0&>&>
   #             </td>
   #             <td <&TD_EXTRA_POSTFIX&>><&POSTFIX&></td>
   #           </tr>
   #           <tr <&TR_EXTRA_ERROR_IN&>><td <&TD_EXTRA_SUBTITLE_UNDER&>></td><td <&TD_EXTRA_ERROR_IN&>><&#error_in ERROR_IN&></td></tr>
   #         </table>
   #       </td>~NAME VALUE MAXLEN SIZE PREFIX POSTFIX SUBTITLE ERROR_IN ID ACCESSKEY READONLY~>
   #     </tr>~NAME VALUE MAXLEN SIZE PREFIX POSTFIX SUBTITLE ERROR_IN ID ACCESSKEY READONLY~>
   #   </table>
#';

$skin{_column} = '<&<&#arg 2&>&>
      <table border=<&TABLE_BORDER&> cellspacing=<&TABLE_CELLSP&> cellpadding=<&TABLE_CELLPAD&> <&TABLE_EXTRA&>><~
        <tr <&TR_EXTRA&>><~
          <td valign="<&TD_VALIGN&>" <&TD_EXTRA_IN&>><&#seperate&>
            <table border=<&TABLE_BORDER_IN&> cellspacing=<&TABLE_CELLSP_IN&> cellpadding=<&TABLE_CELLPAD_IN&> <&TABLE_EXTRA_IN&>>
              <tr <&TR_EXTRA_IN&>>
                <td align="<&TD_SUBTITLE_ALIGN&>" valign="<&TD_SUBTITLE_VALIGN&>" <&TD_EXTRA_SUBTITLE&>><!<&#label SUBTITLE&><span <&SP_NOTNULL_IN&>><&#not_null ERROR_IN&></span>!SUBTITLE!><&PREFIX&></td>
                <td <&TD_EXTRA_IN_IN&>>
                  <&<&#arg 0&>&>
                </td>
                <td <&TD_EXTRA_POSTFIX&>><&POSTFIX&></td>
              </tr>
              <tr <&TR_EXTRA_ERROR_IN&>><td <&TD_EXTRA_SUBTITLE_UNDER&>></td><td <&TD_EXTRA_ERROR_IN&>><&<&#arg 1&> ERROR_IN&></td></tr>
            </table>
          </td>~~>
        </tr>~~>
      </table>
';


  my %error_handler;
  $error_handler{'_check'} = '#error_check';

  $confirm_handler = {} unless(ref($confirm_handler) eq 'HASH');
  
  foreach $_ (@baseskin) {
    my $templ = $_;
    if(s/^_//) {
      foreach my $alias ('', '_notitle', '_notitle_noerror', '2') {
	$templ .= ',' . ($error_handler{$templ} || '#error_in') . ',' . ($confirm_handler->{$templ} || '');
	$skin{$_.$alias} = '<&_row'.$alias.' '.$templ.'&>' unless(defined($skin{$_.$alias}));
      }
    }
  }

  #$skin{text} = '<&row _text&>';

  return \%skin;
}

sub _get_default {
  my %default = %{HTML::FormEngine::Skin::_get_default()};
  $default{_column} = {};
  $default{_column}->{PREFIX} = ' &nbsp; ';
  $default{_column}->{POSTFIX} = ' &nbsp; ';
  #$default{_column}->{TD_SUBTITLE_VALIGN} = 'top';
  #$default{_column}->{TD_EXTRA_IN_IN} = 'valign=top';
  return \%default;
}

1;

__END__
