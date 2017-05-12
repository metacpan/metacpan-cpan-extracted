package HTML::FormEngine::ComplexSkin;


$skin{main} = '
<form action="<&ACTION&>" method="<&METHOD&>" name="<&FORMNAME&>" accept="<&ACCEPT&>" enctype="<&ENCTYPE&>" target="<&TARGET&>" id="<&FORMNAME&>" <&FORM_EXTRA&>>
<table border=<&FORM_TABLE_BORDER&> cellspacing=<&FORM_TABLE_CELLSP&> cellpadding=<&FORM_TABLE_CELLPAD&> align="<&FORM_ALIGN&>" <&FORM_TABLE_EXTRA&>><~
<tr <&FORM_ROW_EXTRA&>><&<&TEMPL&>&></tr>~TEMPL FORM_ROW_EXTRA~>
<tr <&LROW_EXTRA&>>
   <td align="<&SUBMIT_ALIGN&>" colspan=3 <&LCOL_EXTRA&>>
      <!<input type="submit" value="<&SUBMIT&>" name="<&FORMNAME&>" <&SUBMIT_EXTRA&>/>!SUBMIT!>
   </td>
</tr>
</table>
<~<&HIDDEN&>~HIDDEN~>
</form>
';

$skin{row} = '<~
   <td valign="<&TITLE_VALIGN&>" align="<&TITLE_ALIGN&>" <&TD_EXTRA_TITLE&>><!<&#label&><span <&SP_NOTNULL&>><&#not_null&></span>!TITLE!></td>
   <td <&TD_EXTRA&>><&column&></td>
   <td align="<&ERROR_ALIGN&>" valign="<&ERROR_VALIGN&>" <&TD_EXTRA_ERROR&>><&#error&><&#seperate ,1&></td>~~>
';

$skin{row_notitle} = '<~
   <td colspan=2 <&TD_EXTRA&>><&column&></td>
   <td align="<&ERROR_ALIGN&>" valign="<&ERROR_VALIGN&>" <&TD_EXTRA_ERROR&>><&#error&><&#seperate ,1&></td>~~>
';

$skin{row_notitle_noerror} = '<~
   <td colspan=3 <&TD_EXTRA&>><&column&></td>~~>
';

$skin{column} = '
      <table border=<&TABLE_BORDER&> cellspacing=<&TABLE_CELLSP&> cellpadding=<&TABLE_CELLPAD&> <&TABLE_EXTRA&>><~
        <tr <&TR_EXTRA&>><~
          <td valign="<&TD_VALIGN&>" <&TD_EXTRA_IN&>><&#seperate&>
            <table border=<&TABLE_BORDER_IN&> cellspacing=<&TABLE_CELLSP_IN&> cellpadding=<&TABLE_CELLPAD_IN&> <&TABLE_EXTRA_IN&>>
              <tr <&TR_EXTRA_IN&>>
                <td <&TD_EXTRA_SUBTITLE&>><!<&#label SUBTITLE&><span <&SP_NOTNULL_IN&>><&#not_null ERROR_IN&></span>!SUBTITLE!><&PREFIX&></td>
                <td <&TD_EXTRA_IN_IN&>>
                  <&map_templ&>
                </td>
                <td <&TD_EXTRA_POSTFIX&>><&POSTFIX&></td>
              </tr>
              <tr <&TR_EXTRA_ERROR_IN&>><td <&TD_EXTRA_SUBTITLE_UNDER&>></td><td <&TD_EXTRA_ERROR_IN&>><&#error_in ERROR_IN&></td></tr>
            </table>
          </td>~NAME VALUE MAXLEN SIZE PREFIX POSTFIX SUBTITLE ERROR_IN ID ACCESSKEY READONLY~>
        </tr>~NAME VALUE MAXLEN SIZE PREFIX POSTFIX SUBTITLE ERROR_IN ID ACCESSKEY READONLY~>
      </table>
';

$skin{text} = $skin{row};
$skin{text_notitle} = $skin{row_notitle};
$skin{text_notitle_noerror} = $skin{row_notitle_noerror};
$skin{_text} = '<input type="<&TYPE&>" value="<&value&>" name="<&NAME&>" id="<&ID&>" maxlength="<&MAXLEN&>" size="<&SIZE&>" <&readonly&> />';
