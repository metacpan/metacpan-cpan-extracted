=head1 NAME

HTML::FormEngine::Checks - collection of FormEngine check routines

=head1 CHECK ROUTINES

B<NOTE>: all error messages are passed through gettext, that means if
you configured you locales e.g. to german you get the corresponding
german error message instead of the english messages which are
mentioned here. Read L<HTML::FormEngine> and
L<HTML::FormEngine::Handler> on how to overwrite the default error
messages with your own in the form configuration.

=cut

######################################################################

package HTML::FormEngine::Checks;

use Locale::gettext;
use Date::Pcalc qw(check_date);

######################################################################

=head2 not_null

Returns I<value missing> if the field wasn't filled.

=cut

######################################################################

sub _check_not_null {
  my($value) = @_;
  return gettext('value missing').'!' if(!defined($value) or (ref($value) eq 'ARRAY' and !@{$value}) or $value eq '');
}

######################################################################

=head2 email

Returns I<invalid> if the format of the field value seems to be
incompatible to an email address. A simple regular expression is used
here , so far it matches the common email addresses. But it isn't
compatible to any standard. Use C<rfc822> if you want to check for RFC
compatible address format.

Here is the used regexp, please inform me if you discover any bugs:

C<^[A-Za-z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$>

=cut

######################################################################

sub _check_email {
  my ($value) = @_;
  return '' unless($value ne '');
  # better use rfc822!
  if(! ($value =~ m/^[A-Za-z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$/)) {
    return gettext('invalid').'!';
  }  
}

######################################################################

=head2 rfc822

Returns I<standard incompatible> if the given field value doesn't
match the RFC 822 specification. In RFC 822 the format of valid email
addresses is defined.  This check routine is somewhat better than
I<email>, the only disadvantage is, that some working email addresses
don't follow the RFC 822 standard. So if you have problems try using
the I<email> routine.

Thanks to  Richard Piacentini for fixing this method :)

It now simply uses the rfc822 method of Email::Valid (you have to
install Email::Valid to be able to use this method).

=cut

######################################################################

sub _check_rfc822 {
  my($value) = @_;
  return '' unless($value ne '');
  require Email::Valid;
  return gettext('standard incompatible') unless
    Email::Valid->rfc822($value);
  return '';
}

######################################################################

=head2 date

Returns I<invalid> if the field value seems to be incompatible to
common date formats or the date doesn't exist in the Gregorian
calendar.  The following formats are allowed:

dd.mm.yyyy dd-mm-yyyy dd/mm/yyyy yyyy-mm-dd yyyy/mm/dd yyyy.mm.dd

The C<check_date> method of the I<Date::Pcalc> package is used to
prove the dates existence.

=cut

######################################################################

sub _check_date {
  my ($value) = @_;
  return '' unless($value ne '');
  my ($d, $m, $y);
  my $msg = gettext('invalid').'!';

  #  dd.mm.yyyy dd-mm-yyyy dd/mm/yyyy
  if($value =~ m/^([0-9]{1,2})\.([0-9]{1,2})\.([0-9]{2,4})$/ || $value =~ m/^([0-9]{2})-([0-9]{2})-([0-9]{2,4})$/ || $value =~ m/^([0-9]{2})\/([0-9]{2})\/([0-9]{2,4})$/) {
    $d = $1;
    $m = $2;
    $y = $3;
  }
  #  yyyy-mm-dd yyyy/mm/dd yyyy.mm.dd
  elsif($value =~ m/^([0-9]{4})-([0-9]{2})-([0-9]{2})$/ || $value =~ m/^([0-9]{4})\/([0-9]{2})\/([0-9]{2})$/ || $value =~ m/^([0-9]{4}).([0-9]{2}).([0-9]{2})$/) {
    $d = $3;
    $m = $2;
    $y = $1;
  }
  else {
    return $msg;
  }

  if(! check_date($y, $m, $d)) {
    return $msg;
  }

  return '';
}

######################################################################

=head2 digitonly

... returns I<invalid> if the value doesn't match C<[0-9]*>.

=cut

######################################################################

sub _check_digitonly {
  ($_,$self,$caller,$min,$max) = @_;
  return '' unless($_ ne '');
  $regex = '^[0-9]{' . ($min||0) . ',' . ($max||'') . '}' . '$';
  return gettext('invalid').'!' unless(m/$regex/);
  return '';
}

######################################################################

=head2 match

Expects a variable name as first argument. If the argument is not
given, the method uses I<saved> as variable name.  It then trys to
read in the value of the variable and returns an error if its not
equal to the value of the current field.

This method can also compare arrays. In that case the two arrays must
have the same count of fields and every field must match its partner
in the other array.

Please also read L<fmatch >.

=head2 fmatch

Like C<match> but instead of expecting the argument to be a variable
name it expects it to be a fieldname and thus compares the currents
field value with the value of the field which fieldname was given.  If
the argument is not given, the method will try to read in the variable
I<fmatch> to be compatible to older versions of FormEngine (fmatch is
deprecated, don't use it!). The rest works exactly as in C<match>.

If the value of the field that you want to check against isn't unique
because you used that field name several times, you can use a trick:
call the handler C<save_to_global> in the fields definition so that
its value is saved to a global variable which by default is I<saved>
(that's why the C<match> check methods default is also I<saved>). Have
a look at FormEngine:.DBSQL s example I<manageuserswithpassword.cgi>
for better understanding.

B<Note:> When you're using the DBSQL extension and you defined several
tables, you must reference other fields with I<tablename.fieldname>!

=cut

######################################################################

sub _check_match {
  my($value,$self,$caller,$match,$namevar) = @_;
  if($caller eq 'fmatch') {
    $match = $self->_get_var('fmatch') unless(defined($match) and $match ne '');
    return '' unless($match ne '');
    local $_ = $match;
    $match = $self->_get_input($match);
    if(ref($match) eq 'ARRAY' and ref($value) ne 'ARRAY') {
      my $field = $self->_get_var($namevar||'NAME');
      $match = $match->[$self->{values}->{$field}||0];
      $match = $match->[$self->{_handle_error}->{$field}-1] if(ref($match) eq 'ARRAY');
    }
    carp("no such field: $_") and return '' unless(defined($match));
  }
  else {
    $match = $self->_get_var($match||'saved');
  }
  return '' unless($match ne '');
  my $errmsg = gettext('doesn\'t match') . '!';
  if(ref($match) eq 'ARRAY' and ref($value) eq 'ARRAY') {
    return $errmsg if(@{$match} ne @{$value});
    for(my $i = 0; $i < @{$value}; $i++) {
      return $errmsg if($value->[$i] ne $match->[$i]);
    }
  }
  else {
    return $errmsg if($value ne $match);
  }
  return '';
}

######################################################################

=head2 regex

Expects a regular expression string as first argument. For being
compatible to older versions of FormEngine it'll read in the special
variable I<regex> if the first argument is not given (I<regex> is
deprecated, don't use it!). If the value doesn't match this regex,
I<invalid> is returned.

=cut

######################################################################

sub _check_regex {
  my($value,$self,$caller,$regex) = @_;
  return '' unless($value ne '');
  $regex = $self->_get_var('regex') unless($regex);
  if($regex) {
    return gettext('invalid').'!' unless($value =~ m/$regex/);
  }
  return '';
}

######################################################################

=head2 unique

This check method simply checks that the fields value is unique in the
list of values of fields with the same field name. So this check
method only makes sense if you used a field name more than one
time. You can pass it the name of the variable which configures the
field name. The default is I<NAME> which should be fine, so you
normally don't have to pass any arguments.

It returns I<not unique!> if the check fails. Note: you can translate
this text easily so that it is displayed in the language configured by
your locale setting. Read I<ERROR MESSAGE TRANSLATION> for more info.

=cut

######################################################################

sub _check_unique {
  my($value,$self,$caller,$namevar) = @_;
  return '' unless($value ne '');
  my $values = $self->_get_input($self->_get_var($namevar||'NAME'));
  return '' unless(ref($values) eq 'ARRAY');
  $value = [$value] unless(ref($value) eq 'ARRAY');
  local $_;
  my $t = 0;
  foreach $_ (@$values) {
    $_ = [$_] unless(ref($_) eq 'ARRAY');
    my $x = 0;
    for(my $i = 0; $i<@$value; $i ++) {
      $x += ($value->[$i] eq $_->[$i]) ? 1 : -1;
    }
    $t ++ if($x > 0);
    return gettext('not unique').'!' if($t > 1);
  }
  return '';
}

######################################################################

1;

=head1 WRITING A CHECK ROUTINE

=head2 Design

In general, a check routine has the following structure:

  sub mycheck {
    my($value,$self,$caller,@args) = @_;
    #some lines of code#
    return gettext('My ErrorMessage');
  }

C<$value> contains the submitted field value.

C<$self> contains a reference to the FormEngine object.

C<$caller> contains the name with which the check method was called,
B<this is only given if the check method has a name!> That means that
it was referenced by its name defined in by the skin.  Methods
referenced directly by a function reference do not get passed this
value.

C<@args> contains the list of arguments configured by the user for
that check method call.

B<Note:> you can define the error message and pass arguments by
yourself with the help of an array: [checkmethod, errmsg, arg1, arg2..]

=head2 Install

If your routine does a general job, you can make it part of a
FormEngine skin. Therefore just add the routine to e.g. this file and
refer to it from I<Skin.pm> or any other skin package. Please send me
such routines.

=head1 ERROR MESSAGE TRANSLATIONS

The translations of the error messages are stored in I<FormEngine.po>
files.  Calling I<msgfmt> translates these into I<FormEngine.mo>
files. You must store these FormEngine.mo files in your locale
directory, this should be I</usr/share/locale>, if it isn't, you have
to pass the right pass to the constructor of your FormEngine skin (see
L<HTML::FormEngine::Skin> and e.g. C<sendmessages.cgi>).

Provided that a translation for I<yourlanguage> exists, you can call
C<setlocale(LC_MESSAGES, 'yourlanguage')> in your script to have the
FormEngine error message in I<yourlanguage>.

=cut

1;

__END__
