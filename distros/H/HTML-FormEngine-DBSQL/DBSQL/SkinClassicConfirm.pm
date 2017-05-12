=head1 NAME

HTML::FormEngine::DBSQL::SkinClassicConfirm - the standard FormEngine::DBSQL confirm skin

=head1 ABOUT

This is the default confirm skin of FormEngine::DBSQL. It is based on
the skin class HTML::FormEngine::DBSQL::SkinClassic.

The confirm skin replaces the original skin when the confirm form is
created. Read L<HTML::FormEngine> for more.

=cut

######################################################################

package HTML::FormEngine::DBSQL::SkinClassicConfirm;

use strict;
use vars qw(@ISA);
use HTML::FormEngine::DBSQL::SkinClassic;
@ISA = qw(HTML::FormEngine::DBSQL::SkinClassic);

######################################################################

sub _get_templ {
  my $self = shift;
  my %skin = %{HTML::FormEngine::DBSQL::SkinClassic::_get_templ({'_check' => '#confirm_check_prepare 2', '_radio' => '#confirm_check_prepare 2', '_select' => '#confirm_check_prepare 2', '_select_optgroup' => '#confirm_check_prepare 2'})};

$skin{main} = '
<form action="<&ACTION&>" method="<&METHOD&>" name="<&FORMNAME&>" accept="<&ACCEPT&>" enctype="<&ENCTYPE&>" target="<&TARGET&>" id="<&FORMNAME&>" <&FORM_EXTRA&>>
<table border=<&FORM_TABLE_BORDER&> cellspacing=<&FORM_TABLE_CELLSP&> cellpadding=<&FORM_TABLE_CELLPAD&> align="<&FORM_ALIGN&>" <&FORM_TABLE_EXTRA&>>
<tr <&ROW_CONFMSG_EXTRA&>><td colspan=3 align="<&CONFMSG_ALIGN&>" <&TD_CONFMSG_EXTRA&>><!<&#gettext_var CONFIRMSG&><br><br>!CONFIRMSG!></td></tr><~
<tr <&FORM_ROW_EXTRA&>><&TEMPL&></tr>~TEMPL FORM_ROW_EXTRA~>
<tr <&LROW_EXTRA&>>
   <td align="<&CANCEL_ALIGN&>" <&LCOL_EXTRA&>>
     <!<input type="submit" name="<&CONFIRM_CANCEL&>" value="<&#gettext_var CANCEL&>"/>!CANCEL!>
   </td>
   <td align="<&SUBMIT_ALIGN&>" colspan=2 <&LCOL_EXTRA&>>
      <!<input type="submit" value="<&SUBMIT&>" name="<&CONFIRMED&>" <&SUBMIT_EXTRA&>/>!SUBMIT!>
   </td>
</tr>
</table>
<~<&HIDDEN&>~HIDDEN~>
<input type="hidden" name="<&FORMNAME&>" value="1" />
</form>';

  $skin{'_text'} = '<&_print&>';
  $skin{'_radio'} = '<&_print_option&>';
  $skin{'_select'} = '<&_print_option&>';
  $skin{'_select_optgroup'} ='<&_print_option&>';
  $skin{'_select_flexible'} = '<&_templ&>';
  $skin{'_optgroup'} = '<&_print_option&>';
  $skin{'optgroup'} = '<&#confirm_check_prepare 2&><&_print_option&>';
  $skin{'optgroup_flexible'} = '<&_templ&>';
  $skin{'_option'} = '<&_print_option&>';
  $skin{'option'} = '<&#confirm_check_prepare 2&><&_print_option&>';
  $skin{'_check'} = '<&_print_option&>';
  $skin{'_textarea'} = '<&_print&>';

  return \%skin;
}

sub _get_confirm_skin {
  return undef;
}

1;

__END__
