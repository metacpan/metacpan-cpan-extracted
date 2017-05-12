=head1 NAME

HTML::FormEngine::DBSQL::SkinClassic - the standard FormEngine::DBSQL skin

=head1 ABOUT

This is the default skin of FormEngine::DBSQL. It is based on the skin
class HTML::FormEngine::SkinClassic.

Please read its source code for more ;)

=cut

######################################################################

package HTML::FormEngine::DBSQL::SkinClassic;

use strict;
use vars qw(@ISA);
use HTML::FormEngine::SkinClassic;
@ISA = qw(HTML::FormEngine::SkinClassic);

######################################################################

sub get_dbsql_secret {
  my $self = shift;
  return $self->{dbsql_secret};
}

######################################################################

=head1 METHODS

=head2 set_dbsql_secret ( SECRET )

If you want to update records, you can use the C<dbsql_update> method
of L<HTML::FormEngine::DBSQL> That method uses the given values of the
primary key to create where conditions, so that the right records are
updated. The weak point is, that someone could corrupt the input data,
so that the primary key values are changed and the wrong records are
updated. To prevent this, for every record a extra hidden field is
created which contains the md5 sum of the primary key concatenated
with a secret string. So it is recognized if a primary key value was
changed (because the newly created md5 sum won't match the submitted
md5 sum).

With this method you can set the secret string. By default it is set
to NULL, which means that calling C<dbsql_conf> will raise an
error. For security reason an update isn't allowed without a secret
string, except you pass false (0) to the C<dbsql_set_hide_pkey> method
of L<HTML::FormEngine::DBSQL>, which will allow changing the primary
key and so no secret string will be needed.

Another possibilty is changing the value of C<dbsql_secret> in the
C<_init_child> method of this package.  By that you would set a valid
default secret string. But be careful, someone might just edit
SkinClassic.pm and so get the secret string, whereas using diffrent
keys in your scripts is much more secure.

It is recommended that you set the read permissions of scripts which
define secret keys as restrictive as possible. For cgi scripts this
means, that only the webserver user (mostly I<nobody> or I<www-data>)
must be able to read them.

=cut

######################################################################

sub set_dbsql_secret {
  my $self = shift;
  $self->{dbsql_secret} = shift;
}

######################################################################

=head2 get_dbsql_dthandler ( NAME )

Returns a reference on the datatype handler with the given name. If
name is not given a hash reference with all datatype handlers is
returned.

=cut

######################################################################

sub get_dbsql_dthandler {
  my($self, $name) = @_;
  return $self->{dbsql_dthandler}->{$name} if($name);
  return $self->{dbsql_dthandler};
}

######################################################################

=head2 set_dbsql_dthandler ( HASHREF )

Expects a hash reference with the handler names as keys and the
referenced handler functions as elements. It overwrites the current
dthandler settings completly, its not recommended to use this method.

=cut

######################################################################

sub set_dbsql_dthandler {
  my($self, $dthandler) = @_;
  $self->{dbsql_dthandler} = $dthandler and return 1 if(ref($dthandler) eq 'HASH');
  return 0;
}

######################################################################

=head2 alter_dbsql_dthandler ( HASHREF )

Expects a hash reference like L<set_dbsql_dthandler ( HASHREF )> but
instead of overwriting all settings it just updates the settings.

=cut

######################################################################

sub alter_dbsql_dthandler {
  my($self, $dthandler) = @_;
  $self->{default} = merge($dthandler, $self->{dbsql_dthandler}) and return 1 if(ref($dthandler) eq 'HASH');
  return 0;
}

####################
# INTERNAL METHODS #
####################

sub _init_child {
  my $self = shift;
  $self->{dbsql_dthandler} = $self->_get_dbsql_dthandler;
  $self->{dbsql_secret} = '';
}

sub _get_dbsql_dthandler {
  require HTML::FormEngine::DBSQL::DtHandler;
  my %dbsql_dthandler;
  $dbsql_dthandler{default} = \&HTML::FormEngine::DBSQL::DtHandler::_dbsql_dthandle_string;
  $dbsql_dthandler{boolean} = \&HTML::FormEngine::DBSQL::DtHandler::_dbsql_dthandle_bool;
  $dbsql_dthandler{integer} = \&HTML::FormEngine::DBSQL::DtHandler::_dbsql_dthandle_integer;
  $dbsql_dthandler{date} = \&HTML::FormEngine::DBSQL::DtHandler::_dbsql_dthandle_date;
  $dbsql_dthandler{text} = \&HTML::FormEngine::DBSQL::DtHandler::_dbsql_dthandle_text;
  return \%dbsql_dthandler;
}

sub _get_templ {
  my %skin = %{HTML::FormEngine::SkinClassic::_get_templ(@_)};

  $skin{body} = '
<td colspan=3>
<table border=0 summary=""><~
<tr><&TEMPL&></tr>~TEMPL~>
</table>
<~<&HIDDEN&>~HIDDEN~>
</td>
';

  $skin{row} = '
<td valign="top"><&ROWNUM&>. </td><~
<td>
<table border=0 cellspacing=0 cellpadding=0>
<tr><&TEMPL&></tr>
</table>
</td>~TEMPL~>
<~<&HIDDEN&>~HIDDEN~>';

  $skin{title} = '
  <td valign="top"></td><~
  <td align="center"><&TITLE&></td>~TITLE~>';

  $skin{errmsg} = '
   <td colspan=3 style="color:#FF0000">
     <&#gettext Error&>:<br>
     <&ERRMSG&>
   </td>
';

  $skin{sqlerr} = '
   <td colspan=3 style="color:#FF0000">
     <&#gettext SQL failure&>:<br>
     <i><&ERRMSG&></i><br>
     <&#gettext Error number&>: <i><&ERRNUM&></i><br>
     <&#gettext Statement was&>:<br>
     <i><&SQLSTAT&></i>
   </td>
';

  $skin{empty} = '
   <td colspan=3>&nbsp;</td>
';

  $skin{dbsql_hidden} = '<~<~<&#seperate&><input type="hidden" name="<&NAME&>" value="<&#value&>" />~NAME VALUE MAXLEN SIZE POSTFIX SUBTITLE ERROR_IN ID ACCESSKEY READONLY~>~NAME VALUE MAXLEN SIZE POSTFIX SUBTITLE ERROR_IN ID ACCESSKEY READONLY~><&#seperate ,1&>';  

  return \%skin;
}

sub _get_checks {
  my %checks = %{HTML::FormEngine::SkinClassic::_get_checks};
  require HTML::FormEngine::DBSQL::Checks;
  $checks{dbsql_unique} = \&HTML::FormEngine::DBSQL::Checks::_dbsql_check_unique;
  return \%checks;
}

sub _get_confirm_skin {
  require HTML::FormEngine::DBSQL::SkinClassicConfirm;
  return new HTML::FormEngine::DBSQL::SkinClassicConfirm;
}

1;

__END__
