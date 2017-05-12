package HTML::Template::Associate::FormField;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FormField.pm 298 2007-11-05 11:41:25Z lushe $
#
use strict;
use warnings;
use UNIVERSAL qw( isa );
use CGI qw( :form );
use strict;

our $VERSION= '0.12';

{
	no warnings 'redefine';
	sub hidden {
		$_[0]->{hidden} ||= do {
			my $hidden;
			$_[0]->{hidden}=
			HTML::Template::Associate::FormField::Hidden->new($hidden);
		 };
	 };
	no strict 'refs';  ## no critic
	for my $accessor (qw{ default defaults value }) {
		*{__PACKAGE__."::_proc_$accessor"}= sub {
			my($af, $attr)= @_;
			if (! $attr->{override}
			  && ($attr->{$accessor}= $af->{query}->param($attr->{name}))) {
				$attr->{override}= 1;
			}
			return $attr;
		  };
	}
  };

sub init {
	my ($af, $params)= @_;
	$af->{query}= _new_query($params->{cgi});
	$af->params($params->{form_fields});
	return $af;
}
sub new {
	my $class= shift;
	my $af= bless {
	  query=> _new_query(shift),
	  param=> {},
	 }, $class;
	$af->params(shift);
	return $af;
}
sub param {
	my($af, $key, $value)= @_;
	return keys %{$af->{param}} if @_< 2;
	my $name;
	if ($key=~/^\__(.+?)\__$/) {
		$name= $1;
	} else {
		$name= $key;
		$key= '__'. $key .'__';
	}
	$key= uc($key);
	if (@_== 3 && ref($value) eq 'HASH') {
		while (my($n, $v)= each %$value) {
			$n=~/^\-/ and do {
				$n=~s/^\-//;
				$value->{$n}= $value->{"-$n"};
				delete $value->{"-$n"};
			 };
			$n=~/[A-Z]/ and do {
				$value->{lc $n}= $value->{$n};
				delete $value->{$n};
			 };
		}
		return "" unless $value->{type};
		if ($value->{type}=~/[Ff][Oo][Rr][Mm]$/) {
			$value->{name}= $value->{alias} if $value->{alias};
		} else {
			$value->{name}= $value->{alias} || $name;
		}
		$af->{param}{$key}= $value;
		return wantarray ? %{$af->{param}{$key}}: $af->{param}{$key};
	} else {
		return $af->_field_conv(%{$af->{param}{$key}});
	}
}
sub params {
	my($af, $hash)= @_;
	if ($hash && ref($hash) eq 'HASH') {
		while (my($key, $value)= each %$hash) { $af->param($key, $value) }
	}
	return $af->{param};
}
sub hidden_out {
	my($af, $hidden)= @_;
	HTML::Template::Associate::FormField::Hidden->new($hidden);
}
sub _field_conv {
	my($af, %attr)= @_; ! %attr and return "";
	my $_type= lc($attr{type}) || return qq{ Can't find field type. };
	my $type= '__'. $_type;
	return qq{ Can't call "$_type" a field type. } unless $af->can($type);
	for my $key (qw(type alias)) { delete $attr{$key} }
	return $af->$type(\%attr);
}
sub _new_query {
	my $query= shift || {};
	my $type = ref($query);
	$type ? do {
		($ENV{MOD_PERL} && isa $query, 'SCALAR') ? do { return $query }:
		$type eq 'HASH'        ? do { return _const_param($query) }:
		! (isa $query, 'HASH') ? do { $query= {}; return _const_param($query) }:
		! $query->can('param') ? do { return _const_param($query) }:
		                         do { return $query };
	 }:                          do { $query= {}; return _const_param($query) };
}
sub _const_param {
	my $query= shift || {};
	HTML::Template::Associate::FormField::Param->new($query);
}
sub __startform  {
	my($af, $attr)= @_;
	$attr->{enctype}= CGI->MULTIPART
	  if ($attr->{enctype} && $attr->{enctype}=~/[Uu][Pp][Ll][Oo][Aa][Dd]/);
	my $form= startform($attr);
	$form.= $af->hidden->get if $af->hidden->exists;
	return $form;
}
sub __form { &__startform }
sub __start_form { &__startform }
sub __start_multipart_form {
	my($af, $attr)= @_;
	my $form= start_multipart_form($attr);
	$form.= $af->hidden->get if $af->hidden->exists;
	return $form;
}
sub __multipart_form { &__start_multipart_form }
sub __start_upload_form { &__start_multipart_form }
sub __upload_form { &__start_multipart_form }
sub __opt_multipart_form {
	my($af, $attr)= @_;
	my $form= start_multipart_form($attr);
	$form=~s/(?:<[Ff][Oo][Rr][Mm]\s+|\s*>\n?)//g;
	return $form;
}
sub __opt_upload_form { &__opt_multipart_form }
sub __opt_form {
	my($af, $attr)= @_;
	my $form= startform($attr);
	$form=~s/(?:<[Ff][Oo][Rr][Mm]\s+|\s*>\n?)//g;
	return $form;
}
sub __endform    { q{</form>} }
sub __end_form   { &__endform  }
sub __hidden_out { shift->hidden->get }
sub __hidden_field { CGI::hidden(&_proc_value) }
sub __hidden { CGI::hidden(&_proc_value) }
sub __textfield { textfield(&_proc_value) }
sub __text { &__textfield }
sub __filefield { filefield(&_proc_value) }
sub __file { &__filefield }
sub __password_field { password_field(&_proc_value) }
sub __password { &__password_field }
sub __textarea { textarea(&_proc_value) }
sub __button   { button($_[1]) }
sub __reset    { reset($_[1]) }
sub __defaults { defaults($_[1]) }
sub __checkbox { checkbox(&_proc_defaults) }
sub __checkbox_group { checkbox_group(&_proc_defaults) }
sub __popup_menu { popup_menu(&_proc_defaults) }
sub __scrolling_list { scrolling_list(&_proc_defaults) }
sub __select { &__popup_menu }
sub __radio_group { radio_group(&_proc_default) }
sub __radio { &__radio_group }
sub __image_button { image_button($_[1]) }
sub __image { image_button($_[1]) }
sub __submit   { submit($_[1]) }


package HTML::Template::Associate::FormField::Param;
use strict;

sub new {
	my($class, $hash)= @_;
	return bless $hash, $class;
}
sub param {
	my($q, $key, $value)= @_;
	return keys %$q if @_<  2;
	$q->{$key}= $value if @_== 3;
	$q->{$key};
}

package HTML::Template::Associate::FormField::Hidden;
use strict;

sub new {
	my($class, $hidden)= @_;
	$hidden= {} if (! $hidden || ref($hidden) ne 'HASH');
	bless $hidden, $class;
}
sub set {
	my($h, $key, $value)= @_;
	if (@_== 3) {
		if ($h->{$key}) {
			if (ref($h->{$key}) eq 'ARRAY') {
				push @{$h->{$key}}, $value;
			} else {
				$h->{$key}= [$h->{$key}, $value];
			}
		} else {
			$h->{$key}= $value;
		}
	}
	return();
}
sub unset {
	my($h, $key)= @_;
	delete $h->{$key} if @_== 2;
	return();
}
sub get {
	my($h, $key)= @_;
	return _create_fields($h) if @_< 2;
	return _create_field($key, $h->{$key});
}
sub exists {
	my($h, $key)= @_;
	if (@_== 2) {
		if (ref($h->{$key}) eq 'ARRAY') {
			return @{$h->{$key}} ? 1: 0;
		} else {
			return CORE::exists $h->{$key} ? 1: 0;
		}
	} else {
		return %$h ? 1: 0;
	}
}
sub clear { my $h= shift; %$h= () }

sub _create_fields {
	my $hidden= shift || return "";
	my @hidden;
	while (my($key, $value)= each %$hidden) {
		push @hidden, _create_field($key, $value) if $value;
	}
	return @hidden ? join('', @hidden): "";
}
sub _create_field {
	my $key  = &CGI::escapeHTML(shift);
	my $value= shift;
	my $result;
	for my $val (ref($value) eq 'ARRAY' ? @$value: $value) {
		$val= &CGI::escapeHTML($val) || next;
		$result.= qq{<input type="hidden" name="$key" value="$val" />\n};
	}
	return $result;
}

1;

__END__


=head1 NAME

HTML::Template::Associate::FormField

  - CGI Form for using by HTML::Template is generated.
  - HTML::Template::Associate FormField plugin.

=head1 SYNOPSIS

 use CGI;
 use HTML::Template;
 use HTML::Template::Associate::FormField;

 ## The form field setup. ( CGI.pm like )
 my %formfields= (
  StartForm=> { type=> 'opt_form' },
  Name  => { type=> 'textfield', size=> 30, maxlength=> 100 },
  Email => { type=> 'textfield', size=> 50, maxlength=> 200 },
  Sex   => { type=> 'select', values=> [0, 1, 2],
             labels=> { 0=> 'please select !!', 1=> 'man', 2=> 'gal' } },
  ID    => { type=> 'textfield', size=> 15, maxlength=> 15 },
  Passwd=> { type=> 'password', size=> 15, maxlength=> 15,
             default=> "", override=> 1 },
  submit=> { type=> 'submit', value=> ' Please push !! ' },
  );

 ## The template.
 my $example_template= <<END_OF_TEMPLATE;
 <html>
 <head><title>Exsample template</title></head>
 <body>
 <h1>Exsample CGI Form</h1>
 <form <tmpl_var name="__StartForm__">>
 <table>
 <tr><td>Name     </td><td> <tmpl_var name="__NAME__">   </td></tr>
 <tr><td>E-mail   </td><td> <tmpl_var name="__EMAIL__">  </td></tr>
 <tr><td>Sex      </td><td> <tmpl_var name="__SEX__">    </td></tr>
 <tr><td>ID       </td><td> <tmpl_var name="__ID__">     </td></tr>
 <tr><td>PASSWORD </td><td> <tmpl_var name="__PASSWD__"> </td></tr>
 </table>
 <tmpl_var name="__SUBMIT__">
 </form>
 </body>
 </html>
 END_OF_TEMPLATE

 ## The code.
 my $cgi = CGI->new;
 # Give CGI object and definition of field ・・・
 my $form= HTML::Template::Associate::FormField->new($cgi, \%formfields);
 # Give ... ::Form Field object to associate 
 my $tp  = HTML::Template->new(
            scalarref=> \$example_template,
            associate=> [$form],
           );
 # And output your screen
 print $cgi->header, $tp->output;

   or, a way to use not give associate・・・

 my $cgi = CGI->new;
 my $form= HTML::Template::Associate::FormField->new($cgi, \%formfields);
 my $tp  = HTML::Template->new(scalarref=> \$example_template);
 # set up the parameter directly
 $tp->param('__StartForm__', $form->param('StartForm'));
 $tp->param('__NAME__',   $form->param('Name'));
 $tp->param('__EMAIL__',  $form->param('Email'));
 $tp->param('__SEX__',    $form->param('Sex'));
 $tp->param('__ID__',     $form->param('ID'));
 $tp->param('__PASSWD__', $form->param('Passwd'));
 $tp->param('__SUBMIT__', $form->param('submit'));

 print $cgi->header, $tp->output;


 # If you move it as a plug-in of HTML::Template::Associate.
 # * The code is an offer from "Alex Pavlovic" who is the author of HTML::Template::Associate.

 use HTML::Template;
 use HTML::Template::Associate;

 my $associate = HTML::Template::Associate->new ({
    target => 'FormField',
    cgi    => $cgi,
    form_fields => \%formfields
  });

 my $template= HTML::Template->new (
   scalarref=> \$example_template,
   associate=> [ $associate ],
  );

 print $cgi->header, $template->output;

=head1 DESCRIPTION

This is Form Field object using bridge associate option of HTML::Template.
Fill in the Form Field which made from object follow the template.
If the Form Field data which was input at the previous screen exist, it is
 easy to make code, because process (CGI pm dependense) of fill in Form is
 automatic.

=head2 Form Field Setup

=over 4

=item *

The Form of the definition data of Form Field is HASH.  And, contents of each
 key is HASH, too.

=item *

The name of each key is hadled as name of Form Field. Also, in case of hadling
 by B<HTML::Template, the name of key become enclosed with '__'> .
 For example, Field that was defined Foo correspomds to B<__FOO__> of template.

=item *

The contents of each key certainly be defined the key ,type, which shows type
 of Form Field.

=item *

The value of designate to type is same as method for making Form Field of
 CGI.pm. B<Please refer to document of CGI.pm for details>.

B<startform> , B<start_multipart_form> , B<endform> , B<textfield> ,
 B<filefield> , B<password_field> , B<textarea> , B<checkbox> , B<radio_group>
 , B<popup_menu> , B<optgroup> , B<scrolling_list> , B<image_button> ,
 B<defaults> , B<button> , B<reset>

=item *

And others, be possible to designate for extension Field type
 at B<HTML::Template::Associate::FormField> are as follows:

B<form>               ... other name of startform. I<(%)>

B<start_upload_form>  ... other name of start_multipart_form. I<(%)>

B<upload_form>        ... other name of start_multipart_form. I<(%)>

B<opt_form>           ... return only a part of attribute of startform.

B<opt_multipart_form> ... return only a part of attribute of start_multipart_form.

B<opt_upload_form>    ... other name of opt_multipart_form.

B<hidden_field>       ... return all of no indication Field which is seting up.

B<hidden>             ... other name of hidden_field

B<text>               ... other name of textfield.

B<file>               ... other name of filefield.

B<password>           ... other name of password_field.

B<radio>              ... other name of radio_group.

B<select>             ... other name of popup_menu.

B<image>              ... other name of image_button.

I<(%) In case of no indication Field was set up ,
 connect the no indication Field and return the value.>

=item *

In case of you'd like to acquire the name from CGI query - it is different name
 of the key which definition of Form Field, designate for the name of CGI query
  as alias to contents of each key.

 $cgi->param('Baz', 'Hello!!');
 my %formfields= ( 'Foo'=> { alias=> 'Baz', type=> 'textfield' } );

=back

=head1 METHOD

=head2 new

Constructor

=over 4

=item 1

Accept CGI object or HASH reference to the first parameter.

=item 2

Accept definition of CGI Form (HASH reference) to the second parameter. 

$form= HTML::Template::Associate::FormField-E<gt>B<new>($cgi, \%formfields);

=back

=head2 init

Constructor for HTML::Template::Associate.

=head2 param, params

Set up or refer to definition parameter of CGI Form.

=over 4

=item *

Get all keys which is defined as Form Field.

(B<All keys which was able to get by this are enclosed by '__'>)

$form-E<gt>B<param>;

=item *

Get the Form Field which was designated.

$form-E<gt>B<param>('Foo');

    or

$form-E<gt>B<param>('__FOO__');

=back

=head2 hidden

Access to object which control no indication Field.

=over 4

=item *

Add to no indication Field.

$form-E<gt>B<hidden>-E<gt>set('Foo', 'Hoge'); 

=item *

Get all no indication Fields which was set beforehand.

$form-E<gt>B<hidden>-E<gt>get;

=item *

Get no indication Field which was designated.

$form-E<gt>B<hidden>-E<gt>get('Foo');

=item *

Erase the data of no indication field which was designated.

$form-E<gt>B<hidden>-E<gt>unset('Foo');

=item *

Find out the no indication Field was set or not.

$form-E<gt>B<hidden>-E<gt>exists ? 'true': 'false';

=item *

Erase all of no indication Field which was set.

$form-E<gt>B<hidden>-E<gt>clear;

=back

=head2 hidden_out

Export no indication Field, object.

=over 4

=item *

Get no indication field, object.

my %hash = ( 'Foo'=E<gt> 'Form Field !!' );

B<$hidden> = $form-E<gt>B<hidden_out>(\%hash);

=item *

Usable methods are same as hidden.

B<$hidden>-E<gt>set('Baz', 'Hoge');

B<$hidden>-E<gt>get;

B<$hidden>-E<gt>unset('Baz');

=item *

B<Hidden object> which was exported is not linked with startform and,
 start_multipart_form. No indication field which was formed at this object is
  please give to B<param method of HTML::Template>.

$tp= HTML::Template-E<gt>new( ..... );

$tp-E<gt>param('HIDDEN_FIELD', B<$hidden>-E<gt>get);

=back

=head1 ERRORS

In case of errors in the definition of Form field, return this error message
 instead of Form field.

=over 4

=item * Can't find field type.

There is no designation of type in definition Form field.

=item * Can't call "%s" a field type.

Errors in definition form of type.

=back

=head1 BUGS

When you call a function start_form without an action attribute by old CGI
 module, you might find a caution "Use of uninitialized value". In this case,
 let's upgrade to the latest CGI module.

=head1 SEE ALSO

 HTML::Template, CGI

=head1 CREDITS

Generously contributed to English translation by:

Ayumi Ohno

Special Thanks!

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2004-2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
