=head1 NAME

HTML::FormEngine::SkinClassic - the standard FormEngine skin

=head1 ABOUT

This is the default skin of FormEngine. It is based on the skin class
HTML::FormEngine::SkinComplex.

To understand the diffrence between I<SkinClassic> and I<SkinComplex>
read the source code and L<HTML::FormEngine::SkinComplex>.

=cut

######################################################################

package HTML::FormEngine::SkinClassic;

use strict;
use vars qw(@ISA);
use HTML::FormEngine::SkinComplex;
@ISA = qw(HTML::FormEngine::SkinComplex);

######################################################################

#NOTE: its important that templates which do not implement a certain field but are of a generic type (reuseable) begin with _, else the seperate algorithm does not work

sub _get_templ {
  my %skin = %{HTML::FormEngine::SkinComplex::_get_templ(@_)};

  $skin{_row} = '
   <td valign="<&TITLE_VALIGN&>" align="<&TITLE_ALIGN&>" <&TD_EXTRA_TITLE&>><!<&#label&><span <&SP_NOTNULL&>><&#not_null&></span>!TITLE!></td>
   <td <&TD_EXTRA&>><&_column <&#arg 0&>,<&#arg 1&>,<&#arg 2&>&></td>
   <td align="<&ERROR_ALIGN&>" valign="<&ERROR_VALIGN&>" <&TD_EXTRA_ERROR&>><&#error&></td><&#seperate ,1&>
';
  
  $skin{_row_notitle} = '
   <td colspan=2 <&TD_EXTRA&>><&_column <&#arg 0&>,<&#arg 1&>,<&#arg 2&>&></td>
   <td align="<&ERROR_ALIGN&>" valign="<&ERROR_VALIGN&>" <&TD_EXTRA_ERROR&>><&#error&></td><&#seperate ,1&>
';
  
  $skin{_row_notitle_noerror} = '
   <td colspan=3 <&TD_EXTRA&>><&_column <&#arg 0&>,<&#arg 1&>&></td><&#seperate ,1&>
';

  $skin{_row_noerror} = '
   <td valign="<&TITLE_VALIGN&>" align="<&TITLE_ALIGN&>" <&TD_EXTRA_TITLE&>><!<&#label&><span <&SP_NOTNULL&>><&#not_null&></span>!TITLE!></td>
   <td <&TD_EXTRA&> colspan=2><&_column <&#arg 0&>,<&#arg 1&>,<&#arg 2&>&></td><&#seperate ,1&>
';
  
  #_row_error_nl
  $skin{_row2} = '
   <td valign="<&TITLE_VALIGN&>" align="<&TITLE_ALIGN&>" <&TD_EXTRA_TITLE&>><!<&#label&><span <&SP_NOTNULL&>><&#not_null&></span>!TITLE!></td>
   <td <&TD_EXTRA&> colspan=2><&_column <&#arg 0&>,<&#arg 1&>,<&#arg 2&>&></td>
   </tr>
   <tr>
   <td align="<&ERROR_ALIGN&>" valign="<&ERROR_VALIGN&>" colspan=3 <&TD_EXTRA_ERROR&>><&#error&></td><&#seperate ,1&>
';

  return \%skin;
}


sub _get_confirm_skin {
  require HTML::FormEngine::SkinClassicConfirm;
  return new HTML::FormEngine::SkinClassicConfirm;
}

1;

__END__
