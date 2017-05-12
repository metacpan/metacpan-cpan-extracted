
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Validate.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################


package Embperl::Form::Validate;

use strict;
use vars qw($VERSION $has_encode);

BEGIN
    {
    eval "require Encode" ;
    $has_encode = $@?0:1 ;
    } 


$VERSION = '2.5.0' ;

=head1 NAME

Embperl::Form::Validate - Form validation with server- and client-side support.

=head1 DESCRIPTION

This modules is developed to do form validation for you. It works
on the server side by checking the posted form data and it
generates client side script functions, to validate the
form values, as far as possible, before they are send to
the server, to avoid another server roundtrip.

Also it has the best support for Embperl, it should also work
outside of Embperl e.g. with CGI.pm or mod_perl.

It can be extended by new validation rules for
additional syntaxes (e.g. US zip codes, German
Postleitzahlen, number plates, iso-3166 2-digit language or country
codes, etc.)

Each module has the ability to rely it's answer on parameters like
e.g. the browser, which caused the request for or submitted the form.

The module fully supports internationalisation. Any message can be
provided in multiple languages and it makes use of Embperl's 
multilanguage support.

=head1 SYNOPSIS

 use Embperl::Form::Validate;

 my $epf = new Embperl::Form::Validate($rules, $form_id);

 $epf->add_rule('fnord', $fnord_rules);

 # validate the form values and returns error information, if any
 my $result = $epf -> validate ;

 # Does the form content validate?
 print 'Validate: ' . ($result?'no':'yes');
 
 # validate the form values and reaturn all error messages, if any
 my $errors = $epf->validate_messages($fdat, $pref);

 # Get the code for a client-side form validation according to the
 # rules given to new:
 $epf -> get_script_code ;

=head1 METHODS

The following methods are available:

=head2 $epf = Embperl::Form::Validate -> new ($rules [, $form_id ], [$default_language], [$charset]);

Constructor for a new form validator. Returns a reference to a
Embperl::Form::Validate object.

=over

=item $rules 

should be a reference to an array of rules, see L<"RULES"> elsewhere in this
document for details. 

=item $form_id 

should be the name (im HTML) or id (in XHTML) parameter of
the form tag, which has to be verified.It\'s e.g. used for
generating the right path in the JavaScript DOM. It defaults to 'forms[0]'
which should be the first form in your page.

=item $default_language

language to use when no messages are available in the desired language.
Defaults to 'en'.

=item $charset

Pass 'utf-8' in case you want utf-8 messages.

=back

=cut

sub new 
    {
    my $invokedby = shift;
    my $class = ref($invokedby) || $invokedby;
    my ($frules, $form_id, $default_language, $charset) = @_ ;

    my $self = {
	         form_id          => $form_id || 'forms[0]', # The name 
		 frules           => $frules || [],          # \@frules
		 default_language => $default_language || 'en',
		 charset          => $charset || 'iso8859-15',
	       };
    bless($self, $class);
    $self->init;
    return $self;
    }

###
### init() yet undocumented. The only purpose of init() is too allow
### to add functionality without rewriting the whole new() method.
###

sub init # $self
{
    my $self = shift;
    return 1;
}

=head2 $epf->add_rules($field, $field_rules);

Adds rules $field_rules for a (new) field $field to the validator,
e.g.

 $epf->add_rule([ -key => 'fnord', -type => 'Number', -max => 1.3, -name => 'Fnord' ]);

The new rule will be appended to the end of the list of rules.

See L<"RULES"> elsewhere in this document.

=cut

sub add_rule # $self, $field, \%rules
    {
    my $self = shift;
    my $rules = shift;

    push @{$self->{frules}}, $rules;
    return 1;
    }




=head2 $epf -> validate ([$fdat, [$pref]]);

Does the server-side form validation.

=over

=item $fdat

should be a hash reference to all postend form values.
It defaults to %fdat of the current Embperl page.

=item $pref

can contain addtional information for the validation process.
At the moment the keys C<language> and C<default_language>
are recognized. C<language> defaults to the language set by
Embperl. C<default_language> defaults to the one given with C<new>.

=back

The method verifies the content $fdat according to the rules given 
to the Embperl::Form::Validate
constructor and added by the add_rule() method and returns an 
array refernce to error information. If there is no error it
returns undef. Each element of the returned array contains a hash with
the following keys:

=over

=item key

key into $fdat which caused the error

=item id

message id

=item typeobj

object reference to the Validate object which was used to validate the field

=item name

human readable name, if any. Maybe a hash with multiple languages.

=item msg

field specific messages, if any. Maybe a hash with multiple languages.

=item param

array with parameters which should subsituted inside the message

=back

=cut


sub loadtype 
    {
    my ($self, $type) = @_ ;

    
    eval "require $type;";
    die 'Died inside '.__PACKAGE__.'::loadtype::eval: '.$@ if $@;
    return $type;
    }


sub newtype 
    {
    my ($self, $type) = @_ ;

    $type ||= 'Default';
    $type = 'Embperl::Form::Validate::'.$type
        unless $type =~ m!(::|/)!;

    my $obj = $self -> {typeobjs}{$type} ;
    return $obj if ($obj) ;
    
    $type = $self -> loadtype ($type) ;

    $obj = $self -> {typeobjs}{$type} = $type -> new ;

    return $obj ;
    }



sub validate_rules
    {
    my ($self, $frules, $fdat, $pref, $result) = @_ ;

    my %param ;
    my $type ;
    my $typeobj ;
    my $i ;
    my $keys = [] ;
    my $key ;
    my $status ;
    my $name ;
    my $msg ;
    my $break = 0 ;

    while ($i < @$frules) 
        {
        my $action = $frules -> [$i++] ;
        if (ref $action eq 'ARRAY')
            {
            my $fail = $self -> validate_rules ($action, $fdat, $pref, $result) ;
            return $fail if ($fail) ;
            }
        elsif (ref $action eq 'CODE')
            {
            my $arg = $frules -> [$i++] ;
            foreach my $k (@$keys) 
                {
                $status = &$action($k, $fdat -> {$k}, $arg, $fdat, $pref) ;
                last if (!$status) ;
                }
            }
        elsif ($action =~ /^-(.*?)$/)
            {
            if ($1 eq 'key')
                {
                $key        = $frules->[$i++] ;
		$keys 	    = ref $key?$key:[$key] ;
                $type       = 'Default' ;
                $typeobj    = $self -> newtype ($type) ;
                $name       = undef ;
                $msg        = undef ;
                }
            elsif ($1 eq 'name')
                {
                $name    = $i++ ;
                }
            elsif ($1 eq 'msg')
                {
                $msg    = $i++ ;
                }
            elsif ($1 eq 'break')
                {
                $break    = $frules->[$i++] ;
                }
            elsif ($1 eq 'type')
                {
                $type    = $frules->[$i++] ;
                $typeobj = $self -> newtype ($type) ;
		foreach my $k (@$keys) 
		    {
		    $status  = $typeobj -> validate ($k, $fdat -> {$k}, $fdat, $pref) ;
		    last if (!$status) ;
		    }
                }
            else
                {
                $param{$1} = 1 ;
                }
            }
        else
            {
            my $arg = $frules -> [$i++] ;
            foreach my $k (@$keys) 
                {
		my $method = 'validate_' . $action ;                 
                $status = $typeobj -> $method ($k, $fdat -> {$k}, $arg, $fdat, $pref) ;
                last if (!$status) ;
                }
            }
        
        if ($status)
            {
            if (@$status && !$break)
                { 
                my $id = $status  -> [0] ;
                push @$result, { typeobj => $typeobj, id => $id, key => $key, ($name?(name => $frules -> [$name]):()), ($msg?(msg => $frules -> [$msg]):()), param => $status} ;
                }
            last if (!$param{cont}) 
            }
        }
    return $param{fail} ;
    }




sub validate
    {
    my ($self, $fdat, $pref, $epreq) = @_ ;

    $epreq ||= $Embperl::req ;
    $fdat  ||= $epreq -> thread -> form_hash ;

    my @result ;
    $self -> validate_rules ($self->{frules}, $fdat, $pref, \@result) ;

    return \@result ;
    }


sub build_message
    {
    my ($self, $id, $key, $name, $msg, $param, $typeobj, $pref, $epreq) = @_ ;

    my $language = $pref -> {language} ;
    my $default_language = $pref -> {default_language} || $self -> {default_language} ;
    my $charset = $pref -> {charset} ;
    my $txt ;

    $name ||=  $epreq?$epreq -> gettext($key):$key ;
    if (ref $name eq 'ARRAY')
        {
        my @names ;
        foreach my $n (@$name)
            {
            push @names, ref $n ? ($n -> {"$language.$charset"} || $n -> {"$default_language.$charset"} || $n -> {$language} || $n -> {$default_language} || (each %$n)[1] || $key):$n ; 
            }
        $name = join (', ', @names) ;
        }
    else
        {
        $name = ref $name ? ($name -> {"$language.$charset"} || $name -> {"$default_language.$charset"} || $name -> {$language} || $name -> {$default_language} || (each %$name)[1] || $key):$name ; 
        }

    if ($msg)
        {
        $txt = ref $msg ? ($msg -> {"$language.$charset"} || $msg -> {"$default_language.$charset"} || $msg -> {$language} || $msg -> {$default_language} || (each %$msg)[1] || undef):$msg ; 
        }
    else
        {
        $txt = $typeobj -> getmsg ($id, "$language.$charset", "$default_language.$charset") ;
        $txt ||= $typeobj -> getmsg ($id, $language, $default_language) ;
        }
    $txt = $epreq -> gettext($id) if (!$txt && $epreq) ;
    $txt ||= "Missing Message $id: %0 %1 %2 %3" ;                 
    $id = $param -> [0] ;
    $param -> [0] = $name ;
    my @param ;
    eval "require Encode" ;
    if ($charset && $has_encode)
        {
        @param = map { Encode::encode($charset, $_) } @$param ;
        }
    else
        {
        @param =  @$param ;
        }
    
    $txt =~ s/%(\d+)/$param[$1]/g ;
    $param -> [0] = $id ;

    return $txt ;
    }


=pod

=head2 $epf -> error_message ($err, [ $pref ])

Converts one item returned by validate into a error message

=over

=item $err

Item returned by validate

=item $pref

Preferences (see L<validate>)

=back

=cut


sub error_message
    {
    my ($self, $err, $pref, $epreq) = @_ ;

    $epreq ||= $Embperl::req ;

    return $self -> build_message ($err -> {id}, $err -> {key}, $err -> {name}, $err -> {msg}, $err -> {param}, $err -> {typeobj}, $pref, $epreq) ;
    }


=pod

=head2 $epf -> validate_messages ($fdat, [ $pref ])

Validate the form content and returns the error messages
as array ref if any. See L<validate> for details.

=cut


sub validate_messages
    {
    my ($self, $fdat, $pref, $epreq) = @_ ;
    
    $epreq ||= $Embperl::req ;
    $pref -> {language} ||= $epreq -> param -> language if ($epreq) ;
    $pref -> {default_language} ||= $self -> {default_language} ;
    $pref -> {charset} ||= $self -> {charset} ;

    my $result = $self -> validate ($fdat, $pref, $epreq) ;
    return [] if (!@$result) ;

    my @msgs ;
    foreach my $err (@$result)
        {
        my $msg = $self -> build_message ($err -> {id}, $err -> {key}, $err -> {name}, $err -> {msg}, $err -> {param}, $err -> {typeobj}, $pref, $epreq) ;
        push @msgs, $msg ;    
        }

    return \@msgs ;
    }



sub gather_script_code
    {
    my ($self, $frules, $pref, $epreq) = @_ ;

    my %param ;
    my $type ;
    my $typeobj ;
    my $i ;
    my $keys = [] ;
    my $key ;
    my $status ;
    my $name ;
    my $msg ;
    my $msgparam ;
    my $language = $pref -> {language} ;
    my $default_language = $pref -> {default_language} || 'en' ;
    my $scriptcode = $self -> {scriptcode} ||= {} ;
    my $script = '' ;
    my $form  = $self -> {form_id} ;
    my $break = 0 ;

    while ($i < @$frules) 
        {
        my $arg ;
        my $method ;
        my $action = $frules -> [$i++] ;
        if (ref $action eq 'ARRAY')
            {
            $script .= $self -> gather_script_code ($action, $pref, $epreq) ;
            }
        elsif (ref $action eq 'CODE')
            {
            $i++ ;
            }
        elsif ($action =~ /^-(.*?)$/)
            {
            if ($1 eq 'key')
                {
                $key        = $frules->[$i++] ;
		$keys 	    = ref $key?$key:[$key] ;
                $type       = 'Default' ;
                $typeobj    = $self -> newtype ($type) ;
                $name       = undef ;
                $msg        = undef ;
                }
            elsif ($1 eq 'name')
                {
                $name    = $i++ ;
                }
            elsif ($1 eq 'msg')
                {
                $msg    = $i++ ;
                }
            elsif ($1 eq 'break')
                {
                $break    = $frules->[$i++] ;
                }
            elsif ($1 eq 'type')
                {
                $type    = $frules->[$i++] ;
                $typeobj = $self -> newtype ($type) ;
                $method  = 'getscript_validate' ;
                $arg     = '' ;
                }
            else
                {
                $param{$1} = 1 ;
                }
            }
        else
            {
	    $method = 'getscript_' . $action ;                 
            $arg = $frules -> [$i++] ;
            }
        
        if ($method)
            {
            my $code ;
            my $ret ;
            my $k = "$type*$action*$arg" ;
            if (!exists ($scriptcode -> {$k}))
                {
                if ($typeobj -> can ($method))
                    {
                    ($code, $msgparam) = $typeobj -> $method ($arg, $pref, $form) ;
                    $scriptcode -> {$k} = [$code, $msgparam] ;
                    }
                else
                    {
                    $code = '' ;
                    $scriptcode -> {$k} = '' ;
                    }
                }
            else
                {
                if ($scriptcode -> {$k})
                    {
                    $code     = $scriptcode -> {$k}[0] ;
                    $msgparam = $scriptcode -> {$k}[1] ;
                    }
                }   

            if ($code)
                {
                my $nametxt = $name?$frules -> [$name]:undef ;
                my $msgtxt  = $msg?$frules -> [$msg]:undef ;
                my $setmsg = '' ;
                if ($msgparam && !$break)
                    {
                    my $txt = $self -> build_message ($msgparam -> [0], $key, $nametxt, $msgtxt, $msgparam, $typeobj, $pref, $epreq) ;
                    $setmsg = "ids[i] = '$key' ; msgs[i++]='$txt';" 
                    }
                if (!ref $key)
                    {
                    $script .= "obj = formelem\['$key'\] ; if (obj && !($code)) { $setmsg " . ($param{fail}?'fail=1;break;':($param{cont}?'':'break;')) . "}\n" ;
                    }
                else
                    {
                    foreach my $k (@$keys)
                        {
                        $script .= "obj = formelem\['$k'\] ; if (obj && !($code)) {" ;
                        }
                     
                    $script .= " $setmsg " . ($param{fail}?'fail=1;break;':($param{cont}?'':'break;')) . "\n" ;
                    foreach my $k (@$keys)
                        {
                        $script .= "}" ;
                        }
                    }
                }
            }
        }
    if ($script)
        {
        return qq{
do {
$script 
} while (0) ; if (fail) break ;
} ;
        }
    return '' ;
    }


=pod

=head2 $epf -> get_script_code ([$pref])

Returns the script code necessary to do the client-side validation.
Put the result between <SCRIPT> and </SCRIPT> tags inside your page.
It will contain a function that is named C<epform_validate_<name_of_your_form>>
where <name_of_your_form> is replaced by the form named you have passed 
to L<new>. You should call this function in the C<onSubmit> of your form.
Example:

    <script>
    [+ do { local $escmode = 0 ; $epf -> get_script_code } +]
    </script>

    <form name="foo" action="POST" onSubmit="return epform_validate_foo()">
        ....
    </form>

=cut


sub get_script_code
    {
    my ($self, $pref, $epreq) = @_ ;

    $epreq ||= $Embperl::req ;
    $pref  ||= {} ;
    $pref -> {language} ||= $epreq -> param -> language if ($epreq) ;
    $pref -> {default_language} ||= $self -> {default_language} ;
    $pref -> {charset} ||= $self -> {charset} ;
    
    my $script ;
    $script = $self -> gather_script_code ($self->{frules}, $pref, $epreq) ;
    my $fname = $self -> {form_id} ;
    
    $fname =~ s/([^a-zA-Z0-9_])/_/g ;

    return qq{

function epform_validate_$fname(return_msgs, failed_class, formelem)
    {
    var msgs = new Array ;
    var ids  = new Array ;
    var fail = 0 ;
    var i = 0 ;
    var obj ;

    if (!formelem)
	formelem = document.$fname ;
    
    do {
    $script ;
    }
    while (0) ;
    if (failed_class)
        {
        var key ;
        var i ;
        for (key in ids)
            {
            var elems = formelem\[ids[key]\] ;
            if (elems)
                {
                if (!(elems instanceof NodeList))
                    elems = [elems] ;
                if (elems[0] instanceof NodeList)
                    elems = elems[0] ;
                for (i = 0; i < elems.length ;i++)
                    {
                    var elem = elems[i] ;
                    if (elem.getAttribute('type') == 'radio')
                        elem = elem.parentElement ;
                    var eclass = elem.getAttribute('class') ;
                    elem.setAttribute ('class', eclass + ' ' + failed_class) ;
                    elem.setAttribute ('title', msgs[key]) ;
                    }    
                }
            }    
        }
        
    if (return_msgs)
        {
        var ret = [msgs, ids] ;
        return ret ;
        }
        
    if (i)
        alert (msgs.join('\\n')) ;

    return !i ;
    }
} ;
    }



=head1 DATA STRUCTURES

The functions and methods expect the named data structures as follows:

=head2 RULES

The $rules array contains a list of tests to perform. Alls the given tests
are process sequenzially. You can group tests together, so when one test fails
the remaining tests of the same group are not processed and the processing 
continues in the next outer group with the next test.

  [
    [
    -key        => 'lang',
    -name       => 'Language'
    required    => 1,
    length_max  => 5,
    ],
    [
    -key        => 'from',
    -type       => 'EMail',
    emptyok     => 1,
    ],

    -key        => ['foo', 'bar']
    required    => 1,
  ]   


All items starting with a dash are control elements, while all items
without a dash are tests to perform.

=over

=item -key

gives the key in the passed form data hash which should be tested. -key
is normally the name given in the HTML name attribute within a form field.
C<-key> can also be a arrayref, in which case B<only one of> the given keys
must statisfy the following test to succeed.

=item -name

is a human readable name that should be used in error messages. Can be 
hash with multiple languages, e.g.

    -name => { 'en' => 'date', 'de' => 'Datum' }

=item -type

specfify to not use the standard tests, but the ones for a special type.
For example there is a type C<Number> which will replaces all the comparsions
by numeric ones instead of string comparisions. You may add your own types
by writing a module that contains the necessary test and dropping it under
Embperl::Form::Validate::<Typename>. The -type directive also can verfiy
that the given data has a valid format for the type.

The following types are available:

=over

=item Default

This one is used when no type is specified. It contains all the standard
tests.

=item Number

Input must be a floating point number.

=item Integer

Input must be a integer number.

=item PosInteger

Input must be a integer number and greater or equal zero.

=item TimeHHMM

Input must be the time in the format hh::mm

=item TimeHHMMSS

Input must be the time in the format hh::mm:ss

=item TimeValue

Input must be a number followed by s, m, h, d or w.

=item EMail

Input must be a valid email address including a top level domain
e.g. user@example.com

=item EMailRFC

Input must be a valid email address, no top level domain is required,
so user@foo is also valid.

=item IPAddr

Input must be an ip-address in the form nnn.nnn.nnn.nnn

=item IPAddr_Mask

Input must be an ip-address and network mask in the form nnn.nnn.nnn.nnn/mm

=item FQDN_IPAddr

Input must be an ip-address or an fqdn (host.domain)

=item select

This used together with required and causes Embperl::Form::Validate
to test of a selected index != 0 instead of a non empty input.

=back


If you write your own type package,
make sure to send them back, so they can be part of the next distribution.

=item -msg

Used to give messages which should be used when the test fails. This message
overrides the standard messages provided by Embperl::Form::Validate and
by Embperls message management. Can also be a hash with messages for multiple
languages. The -msg parameter must preceed the test for which it should be
displayed. You can have multiple different messages for different tests, e.g.

       [
	-key        => 'email',
	-name       => 'E-Mail-Address',
	emptyok     => 1,                   # it's ok to leave this field empty (in this case the following tests are skiped)
         
	-msg => 'The E-Mail-Address is invalid.',
	matches_regex => '(^[^ <>()@¡-ÿ]+@[^ <>()@¡-ÿ]+\.[a-zA-Z]{2,3}$)', 
        	
	-msg => 'The E-Mail address must contain a "@".',
	must_contain_one_of => '@',
         
	-msg => 'The E-Mail address must contain at least one period.',
	must_contain_one_of => '.',
       ],


=item -fail

stops further validation of any rule after the first error is found

=item -cont

continues validation in the same group, also a error was found

=item -break => 1

errors only break current block, but does not display any message.
-break => 0 turns bak to normal behaviour. This can be used for preconditions:

    [
    -key => 'action',  emptyok => 1, -break => 1, ne => 0, -break => 0,
    -key => 'input', 'required' => 1
    ]

The above example will only require the field "input", when the field "action" is
not empty and is not zero.


=item [arrayref]

you can place a arrayref with tests at any point in the rules list. The array will
be considered as a group and the default is the stop processing of a group as soon
as the first error is found and continue with processing with the next rule in the 
next outer group.

=back

The following test are currently defined:

=over

=item required

=item emptyok

=item length_min

=item length_max

=item length_eq

=item eq

=item same

Value must be the same as in field given as argument. This is useful
if you want for example verify that two passwords are the same. The 
Text displayed to the user for the second field maybe added to the argument
separeted by a colon. Example:

  $epf = Embperl::Form::Validate -> new (
        [
            -key => 'pass',  -name => 'Password', required => 1, length_min => 4,
            -key => 'pass2', -name => 'Repeat Password', required => 1, length_min => 4,
                             same => 'pass:Password',
        ],
        'passform') ; 


=item ne

=item lt

=item gt

=item le

=item ge

=item matches_regex

Value must match B<Perl> regular expression. Only executed on server side.

=item matches_regex_js

Value must match B<JavaScript> regular expression. Only executed on client side.
B<IMPORTANT:> If the user has disabled JavaScript in his browser this test will
be never executed. Use a corresponding Perl Regex with C<matches_regex>
to get a server side validation. Use this with care, because different browser
may have different support for regular expressions.

=item not_matches_regex

Value must not match B<Perl> regular expression. Only executed on server side.

=item not_matches_regex_js

Value must not match B<JavaScript> regular expression. Only executed on client side.
B<IMPORTANT:> If the user has disabled JavaScript in his browser this test will
be never executed. Use a corresponding Perl Regex with C<not_matches_regex>
to get a server side validation. Use this with care, because different browser
may have different support for regular expressions.

=item matches_wildcard

=item must_only_contain

=item must_not_contain

=item must_contain_one_of

=item checked

Checkbox must be selected

=item notchecked

Checkbox must not be selected

=back


=head2 PREFERENCES

The $pref hash (reference) contains information about a single form
request or submission, e.g. the browser version, which made the
request or submission and the language in which the error messages
should be returned. See also L<validate>


=head2 ERROR CODES

For a descriptions of the error codes, validate is returning see L<validate>


=head2 FDAT

See also L<Embperl>.

 my $fdat = { foo => 'foobar',
	      bar => 'baz', 
	      baz => 49, 
	      fnord => 1.2 };

=head1 Example

This example simply validates the form input when you hit submit.
If your input is correct, the form is redisplay with your input,
otherwise the error message is shown. If you turn off JavaScript
the validation is still done one the server-side. Any validation
for which no JavaScript validation is defined (like regex matches), 
only the server-side validation is performed.


    <html>
    <head>
    [-

    use Embperl::Form::Validate ;

    $epf = Embperl::Form::Validate -> new (
        [
            [
            -key => 'name',
            -name => 'Name',
            required => 1,
            length_min => 4,
            ],
            [
            -key => 'id',
            -name => 'Id',
            -type => 'Number',
            gt   => 0,
            lt   => 10,
            ],
            [
            -key => 'email',
            -msg => 'This is not a valid E-Mail address',
            must_contain_one_of => '@.',
            matches_regex => '..+@..+\\...+',
            length_min => 8,
            ],
            [
            -key => 'msg',
            -name => 'Message',
            emptyok => 1,
            length_min => 10,
            ]
        ]) ;

    if ($fdat{check})
        {
        $errors = $epf -> validate_messages ;
        }

    -]
    <script>
    [+ do { local $escmode = 0 ; $epf -> get_script_code } +]
    </script>
    </head>
    <body>

    <h1>Embperl Example - Input Form Validation</h1>

    [$if @$errors $]
        <h3>Please correct the following errors</h3>
        [$foreach $e (@$errors)$]
            <font color="red">[+ $e +]</font><br>
        [$endforeach$]
    [$else$]
        <h3>Please enter your data</h3>
    [$endif$]

    <form action="formvalidation.htm" method="GET" onSubmit="return epform_validate_forms_0_()">
      <table>
        <tr><td><b>Name</b></td> <td><input type="text" name="name"></td></tr>
        <tr><td><b>Id (1-9)</b></td> <td><input type="text" name="id"></td></tr>
        <tr><td><b>E-Mail</b></td> <td><input type="text" name="email"></td></tr>
        <tr><td><b>Message</b></td> <td><input type="text" name="msg"></td></tr>
        <tr><td colspan=2><input type="submit" name="check" value="send"></td></tr>
      </table>
    </form>


    <p><hr>

    <small>Embperl (c) 1997-2010 G.Richter / ecos gmbh <a href="http://www.ecos.de">www.ecos.de</a></small>

    </body>
    </html>


See also eg/x/formvalidation.htm


=head1 SEE ALSO

See also L<Embperl>.

=head1 AUTHOR

Axel Beckert (abe@ecos.de)
Gerald Richter (richter at embperl dot org)

