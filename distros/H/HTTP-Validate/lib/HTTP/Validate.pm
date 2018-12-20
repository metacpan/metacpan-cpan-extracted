package HTTP::Validate;

use strict;
use warnings;

use Exporter qw( import );
use Carp qw( carp croak );
use Scalar::Util qw( reftype weaken looks_like_number );

# Check for the existence of the 'fc' function.  If it exists, we can use it
# for casefolding enum values.  Otherwise, we default to 'lc'.

my $case_fold = $] >= 5.016		    ? eval 'sub { return CORE::fc $_[0] }'
	      : $INC{'Unicode/CaseFold.pm'} ? eval 'sub { return Unicode:CaseFold::fc $_[0] }'
	      : 			      eval 'sub { return lc $_[0] }';

our $VERSION = '0.982';

=head1 NAME

HTTP::Validate - validate and clean HTTP parameter values according to a set of rules

Version 0.982

=head1 DESCRIPTION

This module provides validation of HTTP request parameters against a set of
clearly defined rules.  It is designed to work with L<Dancer>, L<Mojolicious>,
L<Catalyst>, and similar web application frameworks, both for interactive apps
and for data services.  It can also be used with L<CGI>, although the use of
L<CGI::Fast> or another similar solution is recommended to avoid paying the
penalty of loading this module and initializing all of the rulesets over again
for each request.  Both an object-oriented interface and a procedural
interface are provided.

The rule definition mechanism is very flexible.  A ruleset can be defined once
and used with multiple URL paths, and rulesets can be combined using the rule
types C<require> and C<allow>.  This allows a complex application that accepts
many different paths to apply common rule patterns.  If the parameters fail
the validation test, an error message is provided which tells the client how
to amend the request in order to make it valid.  A suite of built-in validator
functions is available, and you can also define your own.

This module also provides a mechanism for generating documentation about the
parameter rules.  The documentation is generated in Pod format, which can
then be converted to HTML, TeX, nroff, etc. as needed.

=head1 SYNOPSIS

    package MyWebApp;
    
    use HTTP::Validate qw{:keywords :validators};
    
    define_ruleset( 'filters' => 
        { param => 'lat', valid => DECI_VALUE('-90.0','90.0') },
	    "Return all datasets associated with the given latitude.",
        { param => 'lng', valid => DECI_VALUE('-180.0','180.0') },
	    "Return all datasets associated with the given longitude.",
        { together => ['lat', 'lng'], errmsg => "you must specify 'lng' and 'lat' together" },
	    "If either 'lat' or 'lng' is given, the other must be as well.",
        { param => 'id', valid => POS_VALUE },
	    "Return the dataset with the given identifier",
        { param => 'name', valid => STR_VALUE },
	    "Return all datasets with the given name");
    
    define_ruleset( 'display' => 
        { optional => 'full', valid => FLAG_VALUE },
	    "If specified, then the full dataset descriptions are returned.  No value is necessary",
        { optional => 'short', valid => FLAG_VALUE },
	    "If specified, then a brief summary of the datasets is returned.  No value is necessary",
        { at_most_one => ['full', 'short'] },
        { optional => 'limit', valid => [POS_ZERO_VALUE, ENUM('all')], default => 'all',
          errmsg => "acceptable values for 'limit' are either 'all', 0, or a positive integer" },
	    "Limits the number of results returned.  Acceptable values are 'all', 0, or a positive integer.");
    
    define_ruleset( 'dataset_query' =>
	"This URL queries for stored datasets.  The following parameters select the datasets",
        "to be displayed, and you must specify at least one of them:",
        { require => 'filters',
          errmsg => "you must specify at least one of the following: 'lat' and 'lng', 'id', 'name'" },
	"The following optional parameters control how the data is returned:",
        { allow => 'display' });
    
    # Validate the parameters found in %ARGS against the ruleset
    # 'dataset_query'.  This is just one example, and in general the parameters
    # may be found in various places depending upon which module (CGI,
    # Dancer, Mojolicious, etc.)  you are using to accept and process HTTP
    # requests.
    
    my $result = check_params('dataset_query', \%ARGS);
    
    if ( my @error_list = $result->errors )
    {
        # if an error message was generated, do whatever is necessary to abort the
        # request and report the error back to the end user
    }
    
    # Otherwise, $result->values will return the cleaned parameter
    # values for use in processing the request.

=head1 THE VALIDATION PROCESS

The validation process starts with the definition of one or more sets of rules.
This is done via the L</define_ruleset> keyword.  For example:

    define_ruleset 'some_params' =>
        { param => 'id', valid => POS_VALUE };
        { param => 'short', valid => FLAG_VALUE },
	{ param => 'full', valid => FLAG_VALUE },
        { at_most_one => ['short', 'full'],
          errmsg => "the parameters 'short' and 'full' cannot be used together" };

This statement defines a ruleset named 'some_params' that enforces the following
rules:

=over 4

=item *

The value of parameter 'id' must be a positive integer.

=item *

The parameter 'short' is considered to have a true value if it appears in a
request, and false otherwise.  The value, if any, is ignored.

=item *

The parameter 'full' is treated likewise.

=item *

The parameters 'short' and 'full' must not be specified together in the same
request.

=back

You can define as many rulesets as you wish.  For each URL path recognized by
your code, you can use the L</check_params> function to validate the request
parameters against the appropriate ruleset for that path.  If the given
parameter values are not valid, one or more error messages will be returned.
These messages should be sent back to the HTTP client, in order to instruct
the user or programmer who originally generated the request how to amend the
parameters so that the request will succeed.

During the validation process, a set of parameter values are considered to
"pass" against a given ruleset if they are consistent with all of its rules.
Rulesets may be included inside other rulesets by means of L</allow> and
L</require> rules.  This allows you to define common rulesets to validate
various groups of parameters, and then combine them together into specific
rulesets for use with different URL paths.

A ruleset is considered to be "fulfilled" by a request if at least one
parameter mentioned in a L</param> or L</mandatory> rule is included in that
request, or trivially if the ruleset does not contain any rules of those
types.  When you use L</check_params> to validate a request against a
particular ruleset, the request will be rejected unless the following are both
true:

=over 4

=item *

The request passes against the specified ruleset and all those that it
includes.

=item *

The specified ruleset is fulfilled, along with any other rulesets included by
L</require> rules.  Rulesets included by L</allow> rules do not have to be
fulfilled.

=back

This provides you with a lot of flexibilty as to requiring or not requiring
various parameters.  Note that a ruleset without any L</param> or
L</mandatory> rules is automatically fulfilled, which allows you to make all
of the paramters optional if you wish.  You can augment this mechanism by
using L</together> and L</at_most_one> rules to specify which parameters must
or must not be used together.

=head2 Ruleset names

Each ruleset must have a unique name, which can be any non-empty
string.  You may name them after paths, parameters, functionality ("display",
"filter") or whatever else makes sense to you.

=head2 Ordering of rules

The rules in a given ruleset are always checked in the order they were
defined.  Rulesets that are included via L</allow> and L</require> rules are
checked immediately when the including rule is evaluated.  Each ruleset is
checked at most once per validation, even if it is included multiple times.

You should be cautious about including multiple parameter rules that
correspond to the same parameter name, as this can lead to situations where no
possible value is correct.

=head2 Unrecognized parameters

By default, a request will be rejected with an appropriate error message if it
contains any parameters not mentioned in any of the checked rulesets.  This
can be overridden (see below) to generate warnings instead.  However, please
think carefully before choosing this option.  Allowing unrecognized parameters
opens up the possibility that optional parameters will be accidentally
misspelled and thus ignored, so that the results are mysteriously different
from what was expected.  If you override this behavior, you should make sure that
any resulting warnings are explicitly displayed in the response that you
generate.

=head2 Rule syntax

Every rule is represented by a hashref that contains a key indicating the rule
type.  For clarity, you should always write this key first.  It is an error to
include more than one of these keys in a single rule.  You may optionally
include additional keys to specify what are the acceptable values for this
parameter, what error message should be returned if the parameter value is not
acceptable, and L<many other options|/Other keys>.

=head3 parameter rules

The following three types of rules define the recognized parameter names.

=head4 param

    { param => <parameter_name>, valid => <validator> ... }

If the specified parameter is present with a non-empty value, then its value
must pass one of the specified validators.  If it passes any of them, the rest
are ignored.  If it does not pass any of them, then an appropriate error
message will be generated.  If no validators are specified, then the value
will be accepted no matter what it is.

If the specified parameter is present and its value is valid, then the
containing ruleset will be marked as "fulfilled".  You could use this, for
example, with a query URL in order to require that the query not be empty
but instead contain at least one significant criterion.  The parameters that
count as "significant" would be declared by C<param> rules, the others by
C<optional> rules.

=head4 optional

    { optional => <parameter_name>, valid => <validator> ... }

An C<optional> rule is identical to a C<param> rule, except that the presence
or absence of the parameter will have no effect on whether or not the
containing ruleset is fulfilled. A ruleset in which all of the parameter rules
are C<optional> will always be fulfilled.  This kind of rule is useful in
validating URL parameters, especially for GET requests.

=head4 mandatory

    { mandatory => <parameter_name>, valid => <validator> ... }

A C<mandatory> rule is identical to a C<param> rule, except that this
parameter is required to be present with a non-empty value regardless of the
presence or absence of other parameters.  If it is not, then an error message
will be generated.  This kind of rule can be useful when validating HTML form
submissions, for use with fields such as "name" that must always be filled in.

=head3 parameter constraint rules

The following rule types can be used to specify additional constraints on the
presence or absence of parameter names.

=head4 together

    { together => [ <parameter_name> ... ] }

If one of the listed parameters is present, then all of them must be.
This can be used with parameters such as 'longitude' and 'latitude', where
neither one makes sense without the other.

=head4 at_most_one

    { at_most_one => [ <parameter_name> ... ] }

At most one of the listed parameters may be present.  This can be used along
with a series of C<param> rules to require that exactly one of a particular
set of parameters is provided.

=head4 ignore

    { ignore => [ <parameter_name> ... ] }

The specified parameter or parameters will be ignored if present, and will not
be included in the set of reported parameter values.  This rule can be used to
prevent requests from being rejected with "unrecognized parameter" errors in
cases where spurious parameters may be present.  If you are specifying only one
parameter name, it does need not be in a listref.

=head3 inclusion rules

The following rule types can be used to include one ruleset inside of another.
This allows you, for example, to define rulesets for validating different
groups of parameters and then combine them into specific rulesets for use with
different URL paths.

It is okay for an included ruleset to itself include other rulesets.  A given
ruleset is checked at most once per validation no matter how many times it is
included.

=head4 allow

    { allow => <ruleset_name> }

A rule of this type is essentially an 'include' statement.  If this rule is
encountered during a validation, it causes the named ruleset to be checked
immediately.  The parameters must pass against this ruleset, but it does not
have to be fulfilled.

=head4 require

    { require => <ruleset_name> }

This is a variant of C<allow>, with an additional constraint.  The validation
will fail unless the named ruleset not only passes but is also fulfilled by
the parameters.  You could use this, for example, with a query URL in order to
require that the query not be empty but instead contain at least one
significant criterion.  The parameters that count as "significant" would be
declared by L</param> rules, the others by L</optional> rules.

=head3 inclusion constraint rules

The following rule types can be used to specify additional constraints on the
inclusion of rulesets.

=head4 require_one

    { require_one => [ <ruleset_name> ... ] }

You can use a rule of this type to place an additional constraint on a list of
rulesets already included with L<inclusion rules|/inclusion rules>.  Exactly
one of the named rulesets must be fulfilled, or else the request is rejected.
You can use this, for example, to ensure that a request includes either a
parameter from group A or one from group B, but not both.

=head4 require_any

    { require_any => [ <ruleset_name> ... ] }

This is a variant of C<require_one>.  At least one of the named rulesets must be
fulfilled, or else the request will be rejected.

=head4 allow_one

    { allow_one => [ <ruleset_name> ... ] }

Another variant of C<require_one>.  The request will be rejected if more than one
of the listed rulesets is fulfilled, but will pass if either none of them or
just one of them is fulfilled.  This can be used to allow optional parameters
from either group A or group B, but not from both groups. 

=head3 other rules

=head4 content_type

    { content_type => <parameter_name>, valid => [ <value> ... ] }

You can use a rule of this type, if you wish, to direct that the value of the
specified parameter be used to indicate the content type of the response.  Only one
of these rules should occur in any given validation.  The key C<valid> gives a
list of acceptable values and the content types they should map to.  For
example, if you are using this module with L<Dancer> then you could do
something like the following:

    define_ruleset '/some/path' =>
        { require => 'some_params' },
        { allow => 'other_params' },
        { content_type => 'ct', valid => ['html', 'json', 'frob=application/frobnicate'] };
    
    get '/some/path.:ct' => sub {
    
        my $valid_request = check_params('/some/path', params);
        content_type $valid_request->content_type;
        ...
    }

This code specifies that the content type of the response will be set by the
URL path suffix, which may be either C<.html>, C<.json> or C<.frob>.

If the value given in a request does not occur in the list, or if no value is
found, then an error message will be generated that lists the accepted types.

To match an empty parameter value, include a string that looks like
'=some/type'.  You need not specify the actual content type string for the
well-known types 'html', 'json', 'xml', 'txt' or 'csv', unless you wish to
override the default given by this module.

=head2 Rule attributes

Any rule definition may also include one or more of the following attributes,
specified as key/value pairs in the rule hash:

=head3 errmsg

This attribute specifies the error message to be returned if the rule fails,
overriding the default message.  For example:

    define_ruleset( 'specifier' => 
        { param => 'name', valid => STRING_VALUE },
        { param => 'id', valid => POS_VALUE });
    
    define_ruleset( 'my_route' =>
        { require => 'specifier', 
          errmsg => "you must specify either of the parameters 'name' or 'id'" });

Error messages may include any of the following placeholders: C<{param}>,
C<{value}>.  These are replaced respectively by the relevant parameter name(s)
and original parameter value(s), single-quoted.  This feature allows you to
define messages that quote the actual parameter values presented in the
request, as well as to define common messages and use them with multiple
rules.

=head3 warn

This attribute causes a warning to be generated rather than an error if the
rule fails.  Unlike errors, warnings do not cause a request to be rejected.
At the end of the validation process, the list of generated warnings can be
retrieved by using the L</warnings> method of the result object.

If the value of this key is 1, then what would otherwise be the error
message will be used as the warning message.  Otherwise, the specified string
will be used as the warning message.

For parameter rules, this attribute affects only errors resulting from
validation of the parameter values.  Other error conditions (i.e. multiple
parameter values without the L</multiple> attribute) continue to be reported
as errors.

=head3 key

The attribute 'key' specifies the name under which any information generated by
the rule will be saved. For a parameter rule, the cleaned value will be saved
under this name.  For all rules, any generated warnings or errors will be
stored under the specified name instead of the parameter name or rule number.
This allows you to easily determine after a validation which
warnings or errors were generated.

The following keys can be used only with rules of type
L</param>, L</optional> or L</mandatory>:

=head3 valid

This attribute specifies the domain of acceptable values for the parameter.  The
value must be either a single code reference or a list of them.  You can
either select from the list of L<built-in validator functions|/VALIDATORS>
included with this module, or provide your own.

If the parameter named by this rule is present, its value must pass at least
one of the specified validators or else an error message will be generated.
If multiple validators are given, then the error message returned will be the
one generated by the last validator in the list.  This can be overridden by
using the L</errmsg> key.

=head3 multiple

This attribute specifies that the parameter may appear multiple times in the
request.  Without this directive, multiple values for the same parameter will
generate an error.  For example:

    define_ruleset( 'identifiers' => 
	{ param => 'id', valid => POS_VALUE, multiple => 1 });

If this attribute is present with a true value, then the cleaned value of the
parameter will be an array ref if at least one valid value was found and
I<undef> otherwise.  If you wish a request to be considered valid even if some
of the values fail the validator, then either use the L</list> attribute instead or
include a L</warn> key as well.

=head3 split

This attribute has the same effect as L</multiple>, and in addition causes
each parameter value string to be split (L<perlfunc/split>) as indicated by the
value of the directive.  If this value is a string, then it will be compiled
into a regexp preceded and followed by C<\s*>.  So in the
following example:

    define_ruleset( 'identifiers' =>
        { param => 'id', valid => POS_VALUE, split => ',' });

The value string will be considered to be valid if it contains one or more
positive integers separated by commas and optional whitespace.  Empty strings
between separators are ignored.

    123,456		# returns [123, 456]
    123 , ,456		# returns [123, 456]
    , 456		# returns [456]
    123 456		# not valid
    123:456		# not valid

If you wish more precise control over the separator expression, you can pass a
regexp quoted with L<qr> instead.

=head3 list

This attribute has the same effect as L</split>, but generates warnings
instead of error messages when invalid values are encountered (as if 
C<< warn => 1 >> was also specified).  The resulting cleaned value will be a
listref containing any values which pass the validator, or I<undef> if no
valid values were found.  See also L</warn> and L</bad_value>.

=head3 bad_value

This attribute can be useful in conjunction with L</list>.  If one or more
values are given for the parameter but none of them are valid, this attribute
comes into effect.  If the value of this attribute is C<ERROR>, then the
validation will fail with an appropriate error message.  Otherwise, this will
be used as the value of the parameter.  It is recommended that you set the
value to something outside of the valid range, i.e. C<-1> for a C<POS_VALUE>
parameter.

Using this attribute allows you to easily distinguish between the case when
the parameter appears with an empty value (or not at all, which is considered
equivalent) vs. when the parameter appears with one or more invalid values and
no good ones.

=head3 alias

This attribute specifies one or more aliases for the parameter name (use a
listref for multiple aliases).  These names may be used interchangeably in
requests, but any request that contains more than one of them will be rejected
with an appropriate error message unless L</multiple> is also specified.  The
parameter value and any error or warning messages will be reported under the
main parameter name for this rule, no matter which alias is used in the
request.

=head3 clean

This attribute specifies a subroutine which will be used to modify the
parameter values.  This routine will be called with the raw value of the
parameter as its only argument, once for each value if multiple values are
allowed.  The resulting values will be stored as the "cleaned" values.  The
value of this directive may be either a code ref or one of the strings 'uc',
'lc' or 'fc'.  These direct that the parameter values be converted to
uppercase, lowercase, or L<fold case|Unicode::CaseFold> respectively.

=head3 default

This attribute specifies a default value for the parameter, which will be
reported if the parameter is not present in the request or if it is present
with an empty value.  If the rule also includes a validator and/or a cleaner,
the specified default value will be passed to it when the ruleset is defined.
An exception will be thrown if the default value does not pass the validator.

=head3 undocumented

If this attribute is given with a true value, then this rule will be ignored
by any calls to L</document_params>.  This feature allows you to include
parameters that are recognized as valid but that are not included in any
generated documentation.  Such parameters will be invisible to users, but
will be visible and clearly marked to anybody browsing your source code.

=head2 Documentation

A ruleset definition may include strings interspersed with the rule
definitions (see the L<example at the top of this page|/SYNOPSIS>) which can
be turned into documentation in Pod format by means of the L</document_params>
keyword.  It is recommended that you use this function to auto-generate the
C<PARAMETERS> section of the documentation pages for the various URL paths
accepted by your web application, translating the output from Pod to whatever
format is appropriate.  This will help you to keep the documentation and the
actual rules in synchrony with one another.

The generated documentation will consist of one or more item lists, separated
by ordinary paragraphs.  Each parameter rule will generate one item, whose body
consists of the documentation strings immediately following the rule
definition.  Ordinary paragraphs (see below) can be used to separate the
parameters into groups for documentation purposes, or at the start or end of a
list as introductory or concluding material.  Each L</require> or L</allow>
rule causes the documentation for the indicated ruleset(s) to be interpolated,
except as noted below.  Note that this subsidiary documentation will not be
nested.  All of the parameters will be documented at the same list indentation
level, whether or not they are defined in subsidiary rulesets.

Documentation strings may start with one of the following special characters:

=over 4

=item C<<< >> >>>

The remainder of this string, plus any strings immediately following, will
appear as an ordinary paragraph.  You can use this feature to provide
commentary paragraphs separating the documented parameters into groups.
Any documentation strings occurring before the first parameter rule
definition, or following an C<allow> or C<require> rule, will always generate
ordinary paragraphs regardless of whether they start with this special
character.

=item C<<< > >>>

The remainder of this string, plus any strings immediately following, will
appear as a new paragraph of the same type as the preceding paragraph (item
body or ordinary paragraph).

=item C<!>

The preceding rule definition will be ignored by any calls to
L</document_params>, and all documentation for this rule will be suppressed.
This is equivalent to specifying the rule attribute L</undocumented>.

=item C<^>

Any documentation generated for the preceding rule definition will be
suppressed.  The remainder of this string plus any strings immediately
following will appear as an ordinary paragraph in its place.  You can use
this, for example, to document a subsidiary ruleset with an explanatory note
(i.e. a link to another documentation section or page) instead of explicitly
listing all of the included parameters.

=item C<?>

This character is ignored at the beginning of a documentation string, and the
next character loses any special meaning it might have had.  You can use this
in the unlikely event that you want a documentation paragraph to actually
start with one of these special characters.

=back

Note that modifier rules such as C<at_most_one>, C<require_one>, etc. are
ignored when generating documentation.  Any documentation strings following
them will be treated as if they apply to the most recently preceding parameter
rule or inclusion rule.

=cut

our (@EXPORT_OK, @VALIDATORS, %EXPORT_TAGS);

BEGIN {

    @EXPORT_OK = qw(
	define_ruleset check_params validation_settings ruleset_defined document_params
	list_params 
	INT_VALUE POS_VALUE POS_ZERO_VALUE
	DECI_VALUE
	ENUM_VALUE
	BOOLEAN_VALUE
	MATCH_VALUE
	FLAG_VALUE ANY_VALUE
    );
    
    @VALIDATORS = qw(INT_VALUE POS_VALUE POS_ZERO_VALUE DECI_VALUE
		     ENUM_VALUE MATCH_VALUE BOOLEAN_VALUE FLAG_VALUE ANY_VALUE);

    %EXPORT_TAGS = (
	keywords => [qw(define_ruleset check_params validation_settings ruleset_defined document_params
		        list_params)],
	validators => \@VALIDATORS,
    );
};

# The following defines a single global validator object, for use when this
# module is used in the non-object-oriented manner.

our ($DEFAULT_INSTANCE) = bless { RULESETS => {}, SETTINGS => {} };


# Known media types are defined here

my (%MEDIA_TYPE) = 
   ('html' => 'text/html',
    'xml' => 'text/xml',
    'txt' => 'text/plain',
    'tsv' => 'text/tab-separated-values',
    'csv' => 'text/csv',
    'json' => 'application/json',
   );

# Default error messages

my (%ERROR_MSG) = 
   ('ERR_INVALID' => "the value of parameter {param} is invalid (was {value})",
    'ERR_BAD_VALUES' => "no valid values were specified for {param} (found {value})",
    'ERR_MULT_NAMES' => "you may only include one of {param}",
    'ERR_MULT_VALUES' => "you may only specify one value for {param}: found {value}",
    'ERR_MANDATORY' => "you must specify a value for {param}",
    'ERR_TOGETHER' => "you must specify {param} together or not at all",
    'ERR_AT_MOST' => "you may not specify more than one of {param}",
    'ERR_REQ_SINGLE' => "you must specify the parameter {param}",
    'ERR_REQ_MULT' => "you must specify at least one of the parameters {param}",
    'ERR_REQ_ONE' => "you may not include parameters from more than one of these groups: {param}",
    'ERR_MEDIA_TYPE' => "you must specify a media type, from the following list: {value}",
    'ERR_DEFAULT' => "parameter value error: {param}",
   );

=head1 INTERFACE

This module can be used in either an object-oriented or a procedural manner.
To use the object-oriented interface, generate a new instance of
HTTP::Validate and use any of the routines listed below as methods:

    use HTTP::Validate qw(:validators);
    
    my $validator = HTTP::Validate->new();
    
    $validator->define_ruleset('my_params' =>
        { param => 'foo', valid => INT_VALUE, default => '0' });
    
    my $result = $validator->check_params('my_params', \%ARGS);

Otherwise, you can export these routines to your module and call them
directly.  In this case, a global ruleset namespace will be assumed:

    use HTTP::Validate qw(:keywords :validators);
    
    define_ruleset('my_params' =>
        { param => 'foo', valid => INT_VALUE, default => '0' });
    
    my $validated = check_params('my_params', \%ARGS);

Using C<:keywords> will import all of the keywords listed below, except
'new'.  Using C<:validators> will import all of the L<validators|/VALIDATORS>
 listed below.

The following can be called either as subroutines or as method names,
depending upon which paradigm you prefer:

=head3 new

This can be called as a class method to generate a new validation instance
(see example above) with its own ruleset namespace.  Any of the arguments that
can be passed to L</validation_settings> can also be passed to this routine.

=cut

sub new {

    my ($class, @settings) = @_;
    
    croak "You must call 'new' as a class method" unless defined $class;
    
    # Create a new object
    
    my $self = bless { RULESETS => {}, SETTINGS => {} }, $class;
    
    # Set the requested settings
    
    $self->validation_settings(@settings);
    
    # Return the new object
    
    return $self;
}


=head3 define_ruleset

This keyword defines a set of rules to be used for validating parameters.  The
first argument is the ruleset's name, which must be unique within its
namespace.  The rest of the parameters must be a list of rules (hashrefs) interspersed
with documentation strings.  For examples, see above.

=cut

sub define_ruleset {
    
    # If we were called as a method, use the object on which we were called.
    # Otherwise, use the default instance.
    
    my $self = ref $_[0] eq 'HTTP::Validate' ? shift : $DEFAULT_INSTANCE;

    my ($ruleset_name, @rules) = @_;
    
    # Next make sure we know where this is called from, for the purpose of
    # generating useful error messages.
    
    my ($package, $filename, $line) = caller;
    
    # Check the arguments, then create a new ruleset object.
    
    croak "The first argument to 'define_ruleset' must be a non-empty string"
	unless defined $ruleset_name && !ref $ruleset_name && $ruleset_name ne '';
    
    my $rs = $self->create_ruleset($ruleset_name, $filename, $line);
    
    # Then add the rules.
    
    $self->add_rules($rs, @rules);
    
    # If we get here without any errors, install the ruleset and return.
    
    $self->{RULESETS}{$ruleset_name} = $rs;
    return 1;
};


=head3 check_params

    my $result = check_params('my_ruleset', undef, params('query'));
    
    if ( $result->passed )
    {
        # process the request using the keys and values returned by 
	# $result->values
    }
    
    else
    {
        # redisplay the form, send an error response, or otherwise handle the
        # error condition using the error messages returned by $result->errors
    }

This function validates a set of parameters and values (which may be provided
either as one or more hashrefs or as a flattened list of keys and values or a
combination of the two) against the named ruleset with the specified context.  It
returns a response object from which you can get the cleaned parameter values
along with any errors or warnings that may have been generated.

The second parameter must be either a hashref or undefined.  If it is defined,
it is passed to each of the validator functions as "context".  This allows you
to provide attributes such as a database handle to the validator functions.
The third parameter must be either a hashref or a listref containing parameter
names and values.  If it is a listref, any items at the beginning of the list
which are themselves hashrefs will be expanded before the list is processed
(this allows you, for example, to pass in a hashref plus some additional names
and values without having to modify the hashref in place).

You can use the L</passed> method on the returned object to determine if the
validation passed or failed.  In the latter case, you can return an HTTP error
response to the user, or perhaps redisplay a submitted form.

Note that you can validate against multiple rulesets at once by defining a new
ruleset with inclusion rules referring to all of the rulesets
you wish to validate against.

=cut

sub check_params {
    
    # If we were called as a method, use the object on which we were called.
    # Otherwise, use the globally defined one.
    
    my $self = ref $_[0] eq 'HTTP::Validate' ? shift : $DEFAULT_INSTANCE;
    
    my ($ruleset_name, $context, $parameters) = @_;
    
    # Create a new validation-execution object using the specified context
    # and parameters.
    
    my $vr = $self->new_execution($context, $parameters);
    
    # Now execute that validation using the specified ruleset, and return the
    # result.
    
    return $self->execute_validation($vr, $ruleset_name);
};


=head3 validation_settings

This function allows you to change the settings on the validation routine.
For example:

    validation_settings( allow_unrecognized => 1 );

If you are using this module in an object-oriented way, then you can also pass
any of these settings as parameters to the constructor method.  Available
settings include:

=over 4

=item allow_unrecognized

If specified, then unrecognized parameters will generate warnings instead of errors.

=item ignore_unrecognized

If specified, then unrecognized parameters will be ignored entirely.

=back

You may also specify one or more of the following keys, each followed by a string.  These
allow you to redefine the messages that are generated when parameter errors are detected:

ERR_INVALID, ERR_BAD_VALUES, ERR_MULT_NAMES, ERR_MULT_VALUES, ERR_MANDATORY, ERR_TOGETHER, 
ERR_AT_MOST, ERR_REQ_SINGLE, ERR_REQ_MULT, ERR_REQ_ONE, ERR_MEDIA_TYPE, ERR_DEFAULT

For example:

    validation_settings( ERR_MANDATORY => 'Missing mandatory parameter {param}',
                         ERR_REQ_SINGLE => 'Found {value} for {param}: only one value is allowed' );

=cut

sub validation_settings {
    
    # If we were called as a method, use the object on which we were called.
    # Otherwise, use the globally defined one.
    
    my $self = ref $_[0] eq 'HTTP::Validate' ? shift : $DEFAULT_INSTANCE;
    
    while (@_)
    {
	my $key = shift;
	my $value = shift;
	
	if ( $key eq 'allow_unrecognized' )
	{
	    $self->{SETTINGS}{permissive} = $value ? 1 : 0;
	}
	
	elsif ( $key eq 'ignore_unrecognized' )
	{
	    $self->{SETTINGS}{ignore_unrecognized} = $value ? 1 : 0;
	}
	
	elsif ( $ERROR_MSG{$key} )
	{
	    $self->{SETTINGS}{$key} = $value;
	}
	
	else
	{
	    croak "unrecognized setting: '$key'";
	}
    }
    
    return 1;
}


=head3 ruleset_defined

    if ( ruleset_defined($ruleset_name) ) {
	# then do something
    }

This function returns true if a ruleset has been defined with the given name,
false otherwise.

=cut

sub ruleset_defined {

    # If we were called as a method, use the object on which we were called.
    # Otherwise, use the globally defined one.
    
    my $self = ref $_[0] eq 'HTTP::Validate' ? shift : $DEFAULT_INSTANCE;
    
    my ($ruleset_name) = @_;
    
    # Return the requested result
    
    return defined $self->{RULESETS}{$ruleset_name};
}


=head3 document_params

This function generates L<documentation|/Documentation> for the given
ruleset, in L<Pod|perlpod> format.  This only works if you have included
documentation strings in your calls to L</define_ruleset>.  The method returns
I<undef> if the specified ruleset is not found.

    $my_doc = document_params($ruleset_name);

This capability has been included in order to simplify the process of
documenting web services implemented using this module.  The author has
noticed that documentation is much easier to maintain and more likely to be
kept up-to-date if the documentation strings are located right next to the
relevant definitions.

Any parameter rules that you wish to leave undocumented should either be given
the attribute 'undocumented' or be immediately followed by a string starting
with "!".  All others will automatically generate list items in the resulting
documentation, even if no documentation string is provided (in this case, the
item body will be empty).

=cut

sub document_params {

    # If we were called as a method, use the object on which we were called.
    # Otherwise, use the globally defined instance.
    
    my $self = ref $_[0] eq 'HTTP::Validate' ? shift : $DEFAULT_INSTANCE;
    
    my ($ruleset_name) = @_;
    
    # Make sure we have a valid ruleset, or else return false.
    
    return unless defined $ruleset_name;
    
    my $rs = $self->{RULESETS}{$ruleset_name};
    return unless $rs;
    
    # Now generate the requested documentation.
    
    return $self->generate_docstring($rs, { in_list => 0, level => 0, processed => {} });
}


=head3 list_params 

This function returns a list of the names of all parameters accepted by the
specified ruleset, including those accepted by included rulesets.

    my @parameter_names = list_ruleset_params($ruleset_name);

This may be useful if your validations allow unrecognized parameters, as it
enables you to determine which of the parameters in a given request are
significant to that request.

=cut

sub list_params {

    # If we were called as a method, use the object on which we were called.
    # Otherwise, use the globally defined instance.
    
    my $self = ref $_[0] eq 'HTTP::Validate' ? shift : $DEFAULT_INSTANCE;
    
    my ($ruleset_name) = @_;
    
    # Make sure we have a valid ruleset, or else return false.
    
    return unless defined $ruleset_name;
    
    my $rs = $self->{RULESETS}{$ruleset_name};
    return unless $rs;
    
    # Now generate the requested list.
    
    return $self->generate_param_list($ruleset_name);
}


# Here are the implementing functions:
# ====================================

# create_ruleset ( ruleset_name, filename, line )
# 
# Create a new ruleset with the given name, noting that it was defined in the
# given filename at the given line number.

sub create_ruleset {

    my ($validator, $ruleset_name, $filename, $line_no) = @_;
    
    # Make sure that a non-empty name was given, and that no ruleset has
    # already been defined under that name.
    
    croak "you must provide a non-empty name for the ruleset" if $ruleset_name eq '';
    
    if ( exists $validator->{RULESETS}{$ruleset_name} )
    {
	my $filename = $validator->{RULESETS}{$ruleset_name}{filename};
	my $line_no = $validator->{RULESETS}{$ruleset_name}{line_no};
	croak "ruleset '$ruleset_name' was already defined at line $line_no of $filename\n";
    }
    
    # Create the new ruleset.
    
    my $rs = { name => $ruleset_name,
	       filename => $filename,
	       line_no => $line_no,
	       doc_items => [],
	       fulfill_order => [],
	       params => {},
	       includes => {},
	       rules => [] };
    
    return bless $rs, 'HTTP::Validate::Ruleset';
}


# List all of the keys that are allowed in rule specifications.  Those whose
# value is 2 indicate the rule type, and at most one of these may be included
# per rule.  The others are optional.

my %DIRECTIVE = ( 'param' => 2, 'optional' => 2, 'mandatory' => 2,
		  'together' => 2, 'at_most_one' => 2, 'ignore' => 2,
		  'require' => 2, 'allow' => 2, 'require_one' => 2,
		  'require_any' => 2, 'allow_one' => 2, 'content_type' => 2,
		  'valid' => 1, 'clean' => 1, 
		  'multiple' => 1, 'split' => 1, 'list' => 1, 'bad_value' => 1, 
		  'error' => 1, 'errmsg' => 1, 'warn' => 1, 'undocumented' => 1,
		  'alias' => 1, 'key' => 1, 'default' => 1);

# Categorize the rule types

my %CATEGORY = ( 'param' => 'param', 
		 'optional' => 'param', 
		 'mandatory' => 'param',
		 'together' => 'modifier', 
		 'at_most_one' => 'modifier', 
		 'ignore' => 'modifier',
		 'require' => 'include', 
		 'allow' => 'include',
		 'require_one' => 'constraint',
		 'allow_one' => 'constraint',
		 'require_any' => 'constraint',
		 'content_type' => 'content' );		 

# List the special validators.

my (%VALIDATOR_DEF) = ( 'FLAG_VALUE' => 1, 'ANY_VALUE' => 1 );

my (%CLEANER_DEF) = ( 'uc' => eval 'sub { return uc $_[0] }',
		      'lc' => eval 'sub { return lc $_[0] }',
		      'fc' => $case_fold );

# add_rules ( ruleset, rule ... )
# 
# Add rules to the specified ruleset.  The rules may be optionally
# interspersed with documentation strings.

sub add_rules {
    
    my ($self) = shift;
    my ($rs) = shift;
    
    my @doc_lines;	# collect up documentation strings until we know how to apply them
    my $doc_rule;	# the rule to which all new documentation strings should be added
    
    # Go through the items in @_, one by one.
    
  RULE:
    foreach my $rule (@_)
    {
	# If the item is a scalar, then it is a documentation string.
	
	unless ( ref $rule )
	{
	    # If the string starts with >, !, ^, or ? then treat it specially.
	    
	    if ( $rule =~ qr{ ^ ([!^?] | >>?) (.*) }xs )
	    {
		# If >>, then close the active documentation section (if any)
		# and start a new one that is not tied to any rule.  This will
		# generate an ordinary paragraph starting with the remainder
		# of the line.
		
		if ( $1 eq '>>' )
		{
		    $self->add_doc($rs, $doc_rule, @doc_lines) if $doc_rule || @doc_lines;
		    @doc_lines = $2;
		    $doc_rule = undef;
		}
		
		# If >, then add to the current documentation a blank line
		# (which will cause a new paragraph) followed by the remainder
		# of this line.
		
		elsif ( $1 eq '>' )
		{
		    push @doc_lines, "", $2;
		}
		
		# If !, then discard the contents of the current documentation
		# section and replace them with this line (including the !
		# character).  This will cause add_doc to later discard them.
		
		elsif ( $1 eq '!' )
		{
		    @doc_lines = $rule;
		}
		
		# If ^, then discard the contents of the current documentation
		# section and replace them with the remainder of the line.
		# Set $doc_rule to undef, which will cause the rule currently
		# being documented to be forgotten and the documentation to be
		# added as an ordinary paragraph instead.
		
		elsif ( $1 eq '^' )
		{
		    @doc_lines = $2;
		    $doc_rule = undef;
		}
		
		# If ?, then add the remainder of the line to the current
		# documentation section.  This will prevent the next character
		# from being interpreted specially.
		
		else
		{
		    push @doc_lines, $2;
		}
	    }
	    
	    # Otherwise, just add this string to the current documentation section.
	    
	    else
	    {
		push @doc_lines, $rule;
	    }
	    
	    next RULE;
	}
	
	# All other items must be hashrefs, otherwise throw an exception.
	
	elsif ( reftype $rule ne 'HASH' )
	{
	    croak "The arguments to 'define_ruleset' must all be hashrefs and/or strings";
	}
	
	# If we get here, assume the item represents a rule and create a new record to
	# represent it.
	
	my $rr = { rs => $rs, rn => scalar(@{$rs->{rules}}) + 1 };
	push @{$rs->{rules}}, $rr;
	
	weaken($rr->{rs});
	
	# Check all of the keys in the rule definition, making sure that all
	# are valid, and determine the rule type.
	
	my $type;
	
    KEY:
	foreach my $key (keys %$rule)
	{
	    croak "unknown attribute '$key' found in rule" unless $DIRECTIVE{$key} || $ERROR_MSG{$key};
	    
	    if ( defined $DIRECTIVE{$key} && $DIRECTIVE{$key} == 2 )
	    {
		croak "a rule definition cannot contain the attributes '$key' and '$type' together, because they indicate different rule types"
		    if $type;
		$type = $key;
		$rr->{$type} = $rule->{$type};
		next KEY;
	    }
	}
	
	# Then process the other keys.
	
	foreach my $key (keys %$rule)
	{	
	    my $value = $rule->{$key};
	    
	    if ( $key eq 'valid' )
	    {
		croak "the attribute 'valid' is only allowed with parameter rules"
		    unless $CATEGORY{$type} eq 'param' || $type eq 'content_type';
	    }
	    
	    elsif ( $key eq 'alias' )
	    {
		croak "the attribute 'alias' is only allowed with parameter rules"
		    unless $CATEGORY{$type} eq 'param';
		
		croak "the value of 'alias' must be a string or a list ref"
		    if ref $value and ref $value ne 'ARRAY';
		
		$rr->{alias} = ref $value ? $value : [ $value ];
	    }
	    
	    elsif ( $key eq 'clean' )
	    {
		croak "they attribute 'clean' is only allowed with parameter rules"
		    unless $CATEGORY{$type} eq 'param';
		
		$rr->{cleaner} = $CLEANER_DEF{$value} || $value;
		
		croak "invalid value '$value' for 'clean'"
		    unless ref $rr->{cleaner} eq 'CODE';
	    }
	    
	    elsif ( $key eq 'default' )
	    {
		croak "the attribute 'default' is only allowed with parameter rules"
		    unless $CATEGORY{$type} eq 'param';
		
		$rr->{default} = $value;
	    }
	    
	    elsif ( $key eq 'split' || $key eq 'list' )
	    {
		croak "the attribute '$key' is only allowed with parameter rules"
		    unless $CATEGORY{$type} eq 'param';
		
		croak "the value of '$key' must be a string or a regexp"
		    if ref $value and ref $value ne 'Regexp';
		
		$rr->{multiple} = 1;
		
		# Make sure that we have a proper regular expression.  If 'split'
		# was given with a string, surround it by \s* to ignore
		# whitespace.
		
		unless ( ref $value )
		{
		    $value = qr{ \s* $value \s* }oxs;
		}
		
		$rr->{split} = $value;
		$rr->{warn} = 1 if $key eq 'list';
	    }
	    
	    elsif ( $key eq 'error' || $key eq 'errmsg' )
	    {
		$rr->{errmsg} = $value;
	    }
	    
	    elsif ( $key ne $type )
	    {
		croak "the value of '$key' must be a string" if ref $value;
		
		$rr->{$key} = $value;
	    }
	}
	
	croak "each record must include a key that specifies the rule type, e.g. 'param' or 'allow'"
	    unless $type;
	
	# If we have any documentation strings collected up, then they belong to the previous
	# rule.  If the current rule is a parameter rule, then add the collected documentation to
	# the previous rule and set this new rule as the target for subsequent documentation.
	
	if ( $CATEGORY{$type} ne 'modifier' )
	{
	    $self->add_doc($rs, $doc_rule, @doc_lines);
	    $doc_rule = $rr;
	    @doc_lines = ();
	}
	
	# If the previous rule is an 'include' or 'constraint' rule, then any subsequent
	# documentation should become an ordinary paragraph; so set $doc_rule to undefined.  If
	# the previous rule is a 'modifier' rule, and if $doc_rule is not empty, then its
	# documentation should be added to that previously encountered parameter rule.
	
	# elsif ( $CATEGORY{$type} ne 'modifier' )
	# {
	#     $self->add_doc($rs, $doc_rule);
	#     $self->add_doc($rs, undef, @doc_lines);
	#     $doc_rule = undef;
	#     @doc_lines = ();
	# }
	
	# Now process the rule according to its type.
	
	my $typevalue = $rule->{$type};
	
	if ( $CATEGORY{$type} eq 'param' )
	{
	    $rr->{type} = 'param';
	    $rr->{param} = $typevalue;
	    
	    # Do some basic sanity checking.
	    
	    croak "the value of '$type' must be a parameter name"
		unless defined $typevalue && !ref $typevalue && $typevalue ne '';
	    
	    # Check the validators.
	    
	    my @validators = ref $rule->{valid} eq 'ARRAY' ? @{$rule->{valid}} : $rule->{valid};
	    
	    foreach my $v (@validators)
	    {
		if ( defined $v && $VALIDATOR_DEF{$v} )
		{
		    $rr->{flag} = 1 if $v eq 'FLAG_VALUE';
		    push @{$rr->{validators}}, \&boolean_value if $v eq 'FLAG_VALUE';
		}
		
		elsif ( defined $v )
		{
		    croak "invalid validator '$v': must be a code ref"
			unless ref $v && reftype $v eq 'CODE';
		    
		    push @{$rr->{validators}}, $v;
		}
	    }
	    
	    $rr->{$type} = 1 if $type eq 'optional' || $type eq 'mandatory';
	    
	    if ( $type ne 'optional' )
	    {
		push @{$rs->{fulfill_order}}, $typevalue unless $rs->{params}{$typevalue};
	    }
	    
	    $rs->{params}{$typevalue} = 1;
	    
	    # If a default value was given, run it through all of the
	    # validators in turn until it passes one of them.  Store the
	    # resulting clean value.  If the default does not pass any of the
	    # validators, throw an error.
	    
	    if ( defined $rr->{default} )
	    {
		croak "default value must be a scalar\n" if ref $rr->{default};
		
		next RULE unless ref $rr->{validators} eq 'ARRAY' &&
		    @{$rr->{validators}};
		
		foreach my $v ( @{$rr->{validators}} )
		{
		    my $result = $v->($rr->{default}, {});
		    
		    next RULE unless defined $result;
		    
		    if ( exists $result->{value} )
		    {
			$rr->{default} = $result->{value};
			croak "cleaned default value must be a scalar\n" if ref $rr->{default};
			next RULE;
		    }
		}
		
		croak "the default value '$rr->{default}' failed all of the validators\n";
	    }
	}
	
	elsif ( $CATEGORY{$type} eq 'modifier' )
	{
	    $rr->{type} = $type;
	    $rr->{param} = [];
	    
	    my @params = ref $typevalue eq 'ARRAY' ? @$typevalue : $typevalue;
	    
	    foreach my $arg (@params)
	    {
		# croak "parameter '$arg' was not defined" unless defined
		# $rs->{params}{$arg} || $type eq 'ignore';
		push @{$rr->{param}}, $arg;
	    }
	    
	    croak "a rule of type '$type' requires at least one parameter name"
		unless @{$rr->{param}} > 0;
	}
	
	elsif ( $CATEGORY{$type} eq 'include' )
	{
	    $rr->{type} = 'include';
	    $rr->{require} = 1 if $type eq 'require';
	    $rr->{ruleset} = $typevalue;
	    
	    croak "the value of '$type' must be a ruleset name"
		unless defined $typevalue && !ref $typevalue && $typevalue ne '';
	    
	    croak "ruleset '$typevalue' not found" unless defined $self->{RULESETS}{$typevalue};
	    
	    $rs->{includes}{$typevalue} = 1;
	}
	
	elsif ( $CATEGORY{$type} eq 'constraint' )
	{
	    $rr->{type} = 'constraint';
	    $rr->{constraint} = $type;
	    $rr->{ruleset} = [];
	    
	    croak "the value of '$type' must be a list of ruleset names"
		unless defined $typevalue && ref $typevalue eq 'ARRAY';
	    
	    foreach my $arg (@$typevalue)
	    {
		next unless defined $arg && $arg ne '';
		
		croak "ruleset '$arg' was not included by any rule" unless defined $rs->{includes}{$arg};
		push @{$rr->{ruleset}}, $arg;
	    }
	    
	    croak "a rule of type '$type' requires at least one ruleset name"
		unless @{$rr->{ruleset}} > 0;
	}
	
	elsif ( $type eq 'content_type' )
	{
	    $rr->{type} = 'content_type';
	    $rr->{param} = $typevalue;
	    
	    my %map;
	    
	    croak "invalid parameter name '$typevalue'" if ref $typevalue || $typevalue !~ /\w/;
	    
	    my @types = ref $rule->{valid} eq 'ARRAY' ? @{$rule->{valid}} : $rule->{valid};
	    
	    foreach my $t (@types)
	    {
		if ( $t eq '' )
		{
		    carp "ignored empty value '$t' for 'content_type'";
		    next;
		}
		
		my ($short, $long) = split /\s*=\s*/, $t;
		$long ||= $MEDIA_TYPE{$short};
		
		croak "unknown content type for '$short': you must specify a full content type with '$short=some/type'"
		    unless $long;
		
		croak "type '$short' cannot be specified twice" if defined $rr->{type_map}{$short};
		
		$rr->{type_map}{$short} = $long;
		push @{$rr->{type_list}}, $short;
	    }
	    
	    croak "you must specify at least one value for 'content_type'" unless $rr->{type_map};
	}
	
	else
	{
	    croak "invalid rule type '$type'\n";
	}
    }
    
    # If we have documentation strings collected up, then they belong to the
    # last-defined rule.  Then call add_doc with a special parameter
    # to close any pending lists.
    
    $self->add_doc($rs, $doc_rule, @doc_lines);
}


# add_doc ( ruleset, rule_record, line... )
# 
# Add the specified documentation lines to the specified ruleset.  If
# $rule_record is defined, it represents the rule to which this documentation
# applies.  Otherwise, the documentation represents header material to be
# output before the documentation for the first rule.  If the beginning of the
# first documentation line is '!', then return without doing anything.
# 
# Any line starting with = is, of course, taken to indicate a Pod command
# paragraph.  It will be preceded and followed by a blank line.
# 
# If $rule_record is undefined, then close any pending lists and do nothing
# else.

sub add_doc {

    my ($self, $rs, $rr, @lines) = @_;
    
    # Don't do anything unless we were given either a rule record or some
    # documentation or both.
    
    return unless defined($rr) || @lines;
    
    # If the first documentation line starts with !, return without doing
    # anything.  That character indicates that this rule should not be
    # documented.
    
    return if @lines && $lines[0] =~ /^[!]/;
    
    # Similarly, return without doing anything if the rule contains the
    # 'undocumented' attribute."
    
    return if defined $rr && $rr->{undocumented};
    
    # Otherwise, put the documentation lines together into a single string
    # (which may contain a series of POD paragraphs).
    
    my $body = '';
    my $last_pod;
    my $this_pod;
    
    foreach my $line (@lines)
    {
	# If this line starts with =, then it needs extra spacing.
	
	my $this_pod = $line =~ qr{ ^ = }x;
	
	# If $body already has something in it, add a newline first.  Add
	# two if this line starts with =, or if the previously added line
	# did, so that we get a new paragraph.
	
	if ( $body ne '' )
	{
	    $body .= "\n" if $last_pod || $this_pod;
	    $body .= "\n";
	}
	
	$body .= $line;
	$last_pod = $this_pod;
    }
    
    # Then add the documentation to the ruleset record:
    
    # If there is no attached rule, then we add the body as an ordinary paragraph.
    
    unless ( defined $rr )
    {
	push @{$rs->{doc_items}}, "=ORDINARY";
	push @{$rs->{doc_items}}, process_doc($body) if defined $body;
    }
    
    # If the indicated rule is a parameter rule, then add its record to the list.
    
    elsif ( defined $rr and $rr->{type} eq 'param' )
    {
	push @{$rs->{doc_items}}, $rr;
	weaken $rs->{doc_items}[-1];
	push @{$rs->{doc_items}}, process_doc($body, 1) if defined $body;
    }
    
    # If this is an include rule, then we add a special line to include the
    # specified ruleset(s).
    
    elsif ( defined $rr and $rr->{type} eq 'include' )
    {
	push @{$rs->{doc_items}}, "=INCLUDE $rr->{ruleset}";
	
	# If any body text was specified, then add it as an ordinary paragraph
	# after the inclusion.
	
	if ( $body ne '' )
	{
	    push @{$rs->{doc_items}}, "=ORDINARY";
	    push @{$rs->{doc_items}}, process_doc($body) if defined $body;
	}
    }
}


# process_doc ( )
# 
# Make sure that the indicated string is valid POD.  In particular, if there
# are any unclosed =over sections, close them at the end.  Throw an exception
# if we find an =item before the first =over or a =head inside an =over.

sub process_doc {

    my ($docstring, $item_body) = @_;
    
    my ($list_level) = 0;
    
    while ( $docstring =~ / ^ (=[a-z]+) /gmx )
    {
	if ( $1 eq '=over' )
	{
	    $list_level++;
	}
	
	elsif ( $1 eq '=back' )
	{
	    $list_level--;
	    croak "invalid POD string: =back does not match any =over" if $list_level < 0;
	}
	
	elsif ( $1 eq '=item' )
	{
	    croak "invalid POD string: =item outside of =over" if $list_level == 0;
	}
	
	elsif ( $1 eq '=head' )
	{
	    croak "invalid POD string: =head inside =over" if $list_level > 0 or $item_body;
	}
    }
    
    return $docstring, ('=back') x $list_level;
}


# generate_docstring ( ruleset )
# 
# Generate the documentation string for the specified ruleset, recursively
# evaluating all of the rulesets it includes.  This will generate a series of
# flat top-level lists describing all of the various parameters, potentially
# with non-list paragraphs in between.

sub generate_docstring {

    my ($self, $rs, $state) = @_;
    
    # Make sure that we process each ruleset only once, even if it is included
    # multiple times.  Also keep track of our recursion level.
    
    return '' if $state->{processed}{$rs->{name}};
    
    $state->{processed}{$rs->{name}} = 1;
    $state->{level}++;
    
    # Start with an empty string.  If there are no doc_items for this
    # ruleset, just return that.
    
    my $doc = '';
    
    return $doc unless ref $rs && ref $rs->{doc_items} eq 'ARRAY';
    
    # Go through each docstring, treating it as a POD paragraph.  That means
    # that they will be separated from each other by a blank line.
    
    foreach my $item ( @{$rs->{doc_items}} )
    {
	# An item record starts a list if not already in one.
	
	if ( ref $item && defined $item->{param} )
	{
	    unless ( $state->{in_list} )
	    {
		$doc .= "\n\n" if $doc ne '';
		$doc .= "=over";
		$state->{in_list} = 1;
	    }
	    
	    $doc .= "\n\n=item $item->{param}";
	}
	
	# A string starting with =ORDINARY closes any current list.
	
	elsif ( $item =~ qr{ ^ =ORDINARY }x )
	{
	    if ( $state->{in_list} )
	    {
		$doc .= "\n\n" if $doc ne '';
		$doc .= "=back";
		$state->{in_list} = 0;
	    }
	}
	
	# A string starting with =INCLUDE inserts the specified ruleset.
	
	elsif ( $item =~ qr{ ^ =INCLUDE \s* (.*) }xs )
	{
	    my $included_rs = $self->{RULESETS}{$1};
	    
	    if ( ref $included_rs eq 'HTTP::Validate::Ruleset' )
	    {
		my $subdoc = $self->generate_docstring($included_rs, $state);
		
		$doc .= "\n\n" if $doc ne '' && $subdoc ne '';
		$doc .= $subdoc if $subdoc ne '';
	    }
	}
	
	# All other strings are added as-is.
	
	else
	{
	    $doc .= "\n\n" if $doc ne '' && $item ne '';
	    $doc .= $item;
	}
    }
    
    # If we get to the end of the top-level ruleset and we are still in a
    # list, close it.  Also make sure that our resulting documentation string
    # ends with a newline.
    
    if ( --$state->{level} == 0 )
    {
	$doc .= "\n\n=back" if $state->{in_list};
	$state->{in_list} = 0;
	$doc .= "\n";
    }
    
    return $doc;
}


# generate_param_list ( ruleset )
# 
# Generate a list of unique parameter names for the ruleset and its included
# rulesets if any.

sub generate_param_list {
    
    my ($self, $rs_name, $uniq) = @_;
    
    $uniq ||= {};
    
    return if $uniq->{$rs_name}; $uniq->{$rs_name} = 1;
    
    my @params;
    
    foreach my $rule ( @{$self->{RULESETS}{$rs_name}{rules}} )
    {
	if ( $rule->{type} eq 'param' )
	{
	    push @params, $rule->{param};
	}
	
	elsif ( $rule->{type} eq 'include' )
	{
	    push @params, $self->generate_param_list($rule->{ruleset}, $uniq);
	}
    }
    
    return @params;
}


# new_execution ( context, params )
# 
# Create a new validation-execution control record, using the given context
# and input parameters.

sub new_execution {
    
    my ($self, $context, $input_params) = @_;
    
    # First check the types of the arguments to this function.
    
    croak "the second parameter to check_params() must be a hashref if defined"
	if defined $context && (!ref $context || reftype $context ne 'HASH');
    
    $context = {} unless defined $context;
    
    croak "the third parameter to check_params() must be a hashref or listref"
	unless ref $input_params;
    
    # If the parameters were given as a hashref, just use it straight.
    
    my $unpacked_params = {};
    
    if ( reftype $input_params eq 'HASH' )
    {
	%$unpacked_params = %$input_params;
    }
    
    # If the parameters were given as a listref, we need to look for hashrefs
    # at the front.
    
    elsif ( reftype $input_params eq 'ARRAY' )
    {
	# Look for hashrefs at the beginning of the list and unpack them.
	
	while ( ref $input_params->[0] && reftype $input_params->[0] eq 'HASH' )
	{
	    my $p = shift @$input_params;
	    
	    foreach my $x (keys %$p)
	    {
		add_param($unpacked_params, $x, $p->{$x});
	    }
	}
	
	# All other items must be name/value pairs.
	
	while ( @$input_params )
	{
	    my $p = shift @$input_params;
	    
	    if ( ref $p )
	    {
		croak "invalid parameter '$p'";
	    }
	    
	    else
	    {
		add_param($unpacked_params, $p, shift @$input_params);
	    }
	}
    }
    
    # Anything else is invalid.
    
    else
    {
	croak "the third parameter to check_params() must be a hashref or listref";
    }
    
    # Now create a new validation record
    
    my %settings = %{$self->{SETTINGS}};
    
    my $vr = { raw => $unpacked_params,	# the raw parameters and values
	       clean => { },		# the parameter keys and values
	       clean_list => [ ],	# the parameter keys in order of recognition
	       context => $context,	# context for the validators to use
	       ps => { },		# the status (failed=0, passed=1, ignored=undef) of each parameter
	       rs => { },		# the status (checked=1, fulfilled=2) of each ruleset
	       settings => \%settings,	# a copy of our current settings
	     };
    
    return bless $vr, 'HTTP::Validate::Progress';
}


sub add_param {

    my ($hash, $param, $value) = @_;
    
    # If there is already more than one value for this parameter, add the new
    # value(s) to the array ref.
    
    if ( ref $hash->{$param} && reftype $hash->{$param} eq 'ARRAY' )
    {
	push @{$hash->{$param}}, 
	     (ref $value && reftype $value eq 'ARRAY' ? @$value : $value);
    }
    
    # If there is already one value for this parameter, turn it into an array
    # ref.
    
    elsif ( defined $hash->{$param} && $hash->{$param} ne '' )
    {
	$hash->{$param} = [$hash->{$param},
			   (ref $value && reftype $value eq 'ARRAY' ? @$value : $value)];
    }
    
    # Otherwise, set the value for this parameter to be the new value (which
    # could be either a scalar or a reference).
    
    else
    {
	$hash->{$param} = $value;
    }
}


# This function performs a validation using the given validation-progress
# record, starting with the given ruleset, and returns a hash with the
# results.

sub execute_validation {

    my ($self, $vr, $ruleset_name) = @_;
    
    croak "you must provide a ruleset name" unless defined $ruleset_name && $ruleset_name ne '';
    croak "invalid ruleset name: '$ruleset_name'" if ref $ruleset_name || $ruleset_name !~ /\w/;
    
    # First perform the specified validation against the specified ruleset.
    # This may trigger validations against additional rulesets if the intial
    # one contains 'allow' or 'require' rules.
    
    $self->validate_ruleset($vr, $ruleset_name);
    
    # Now, if this ruleset was not fulfilled, add an appropriate error
    # message. 
    
    if ( $vr->{rs}{$ruleset_name} != 2 )
    {
	my @names = @{$self->{RULESETS}{$ruleset_name}{fulfill_order}};
	my $msg = @names == 1 ? 'ERR_REQ_SINGLE': 'ERR_REQ_MULT';
	add_error($vr, { key => $ruleset_name }, $msg, { param => \@names });
    }
    
    # Create an object to hold the result of this function.
    
    my $result = bless {}, 'HTTP::Validate::Result';
    
    # Add the clean-value hash and the raw-value hash
    
    $result->{clean} = $vr->{clean};
    $result->{clean_list} = $vr->{clean_list};
    $result->{raw} = $vr->{raw};
    
    # Put the clean-value hash under the old name, for backward compatibility
    # (it will be eventually removed).
    
    $result->{values} = $vr->{clean};
    
    # Add the content type, if one was specified.
    
    $result->{content_type} = $vr->{content_type}
	if defined $vr->{content_type} and 
	    $vr->{content_type} ne '' and 
		$vr->{content_type} ne 'unknown';
    
    # Add any errors that were generated.
    
    $result->{ec} = $vr->{ec};
    $result->{er} = $vr->{er};
    $result->{wc} = $vr->{wc};
    $result->{wn} = $vr->{wn};
    $result->{ig} = $vr->{ig};
    
    # Now check for unrecognized parameters, and generate errors or warnings
    # for them.
    
    return $result if $self->{SETTINGS}{ignore_unrecognized};
    
    foreach my $key (keys %{$vr->{raw}})
    {
	next if exists $vr->{ps}{$key} or exists $vr->{ig}{$key};
	
	if ( $self->{SETTINGS}{permissive} )
	{
	    unshift @{$result->{wn}}, [$key, "unknown parameter '$key'"];
	    $result->{wc}{$key}++;
	}
	else
	{
	    unshift @{$result->{er}}, [$key, "unknown parameter '$key'"];
	    $result->{ec}{$key}++;
	}
    }
    
    # Now return the result object.
    
    return $result;
}


# This function does the actual work of validating.  It takes two parameters:
# a validation record and a ruleset name.  It sets various subfields of the
# validation record according to the results of the validation.

sub validate_ruleset {

    my ($self, $vr, $ruleset_name) = @_;
    
    die "Missing ruleset" unless defined $ruleset_name;
    
    my $rs = $self->{RULESETS}{$ruleset_name};
    
    # Throw an error if this ruleset does not exist.
    
    croak "Unknown ruleset '$ruleset_name'" unless ref $rs;
    
    # Return immediately if we have already visited this ruleset.  Otherwise,
    # mark it as visited.
    
    return if exists $vr->{rs}{$ruleset_name};
    $vr->{rs}{$ruleset_name} = 1;
    
    # Mark the ruleset as fulfilled if it has no non-optional parameters.
    
    $vr->{rs}{$ruleset_name} = 2 unless ref $rs->{fulfill_order} && @{$rs->{fulfill_order}};
    
    # Now check all of the rules in this ruleset against the parameter values
    # stored in $vr->{raw}.
    
 RULE:
    foreach my $rr (@{$rs->{rules}})
    {
	my $type = $rr->{type};
	my $param = $rr->{param};
	my $key = $rr->{key} || $param;
	my $default_used;
	
	# To evaluate a rule of type 'param' we check to see if a
	# corresponding parameter was specified.
	
	if ( $type eq 'param' )
	{
	    my (%names_found, @names_found, @raw_values);
	    
	    # Skip this rule if a previous 'ignore' was encountered.
	    
	    next RULE if $vr->{ig}{$key};
	    
	    # Otherwise check to see if the parameter or any of its aliases were specified.  If
	    # so, then collect up their values.
	    
	    foreach my $name ( $rr->{param}, @{$rr->{alias}} )
	    {
		next unless exists $vr->{raw}{$name};
		$names_found{$name} = 1;
		my $v = $vr->{raw}{$name};
		push @raw_values, grep { defined $_ && $_ ne '' } ref $v eq 'ARRAY' ? @$v : $v;
		# Make sure this parameter exists in {ps}, but don't
		# change its status if any.
		$vr->{ps}{$name} = undef unless exists $vr->{ps}{$name};
	    }
	    
	    # If more than one of the aliases for this parameter was specified, and the 'multiple'
	    # option was not specified, then generate an error and go on to the next rule.  We
	    # mark the parameter status as "error" (0), and we also mark the ruleset as fulfilled (2)
	    # if this was a 'param' or 'mandatory' rule.  This last is done to avoid generating a
	    # spurious error message if the ruleset is not fulfilled by any other parameters.
	    
	    if ( keys(%names_found) > 1 && ! $rr->{multiple} )
	    {
		add_error($vr, $rr, 'ERR_MULT_NAMES', { param => [ sort keys %names_found ] });
		$vr->{ps}{$param} = 0;
		$vr->{rs}{$ruleset_name} = 2 unless $rr->{optional};
		next RULE;
	    }
	    
	    # If a clean value has already been determined for this parameter, then it was already
	    # recognized by some other rule.  Consequently, this rule can be ignored.
	    
	    elsif ( exists $vr->{clean}{$key} )
	    {
		next RULE;
	    }
	    
	    # If no values were specified for this parameter, check to see if the rule includes a
	    # default value.  If so, use that instead and go on to the next rule.
	    
	    elsif ( ! @raw_values && exists $rr->{default} )
	    {
		$vr->{clean}{$key} = $rr->{default};
		push @{$vr->{clean_list}}, $key;
		next RULE;
	    }
	    
	    # If more than one value was given and the rule does not include the 'multiple'
	    # directive, signal an error.  We mark the parameter status as "error" (0), and we
	    # also mark the ruleset as fulfilled (2) if this was a 'param' or 'mandatory' rule.
	    # This last is done to avoid generating a spurious error message if the ruleset is not
	    # fulfilled by any other parameters.
	    
	    elsif ( @raw_values > 1 && ! $rr->{multiple} )
	    {
		add_error($vr, $rr, 'ERR_MULT_VALUES',
		      { param => [ sort keys %names_found ], value => \@raw_values });
		$vr->{ps}{$param} = 0;
		$vr->{rs}{$ruleset_name} = 2 unless $rr->{optional};
		next RULE;
	    }
	    
	    # Now we can process the rule.  If the 'split' directive was
	    # given, split the value(s) using the specified regexp.
	    
	    if ( $rr->{split} )
	    {
		# Split all of the raw values, and discard empty strings.
		
		my @new_values = grep { defined $_ && $_ ne '' } 
				    map { split $rr->{split}, $_ } @raw_values;
		@raw_values = @new_values;
	    }
	    
	    # If this is a 'flag' parameter and the parameter was present but
	    # no values were given, assume the value '1'.
	    
	    if ( $rr->{flag} && keys(%names_found) && ! @raw_values )
	    {
		@raw_values = (1);
	    }
	    
	    # At this point, if there are no values then generate an error if
	    # the parameter is mandatory.  Otherwise just skip this rule.
	    
	    unless ( @raw_values )
	    {
		if ( $rr->{mandatory} )
		{
		    add_error($vr, $rr, 'ERR_MANDATORY', { param => $rr->{param} });
		    $vr->{ps}{$param} = 0;
		    $vr->{rs}{$ruleset_name} = 2 unless $rr->{optional};
		}
		
		next RULE;
	    }
	    
	    # Now indicate that at least one value was found for this
	    # parameter, even though we don't yet know if it is a good one.
	    # This will be necessary for properly handling 'together' and
	    # 'at_most_one' rules.
	    
	    $vr->{clean}{$key} = undef;
	    
	    # Now we process each value in turn.
	    
	    my @clean_values;
	    my $error_flag;
	    
	VALUE:
	    foreach my $raw_val ( @raw_values )
	    {
		# If no validators were defined, just pass all of the values
		# that are not empty.
		
		unless ( $rr->{validators} )
		{
		    if ( defined $raw_val && $raw_val ne '' )
		    {
			$raw_val = $rr->{cleaner}($raw_val) if ref $rr->{cleaner} eq 'CODE';
			push @clean_values, $raw_val;
		    }
		    
		    next VALUE;
		}
		
		# Otherwise, check each value against the validators in turn until
		# one of them passes the value or until we have tried them
		# all.
		
		my $result;
		
	    VALIDATOR:
		foreach my $validator ( @{$rr->{validators}} )
		{
		    $result = $validator->($raw_val, $vr->{context});
		    
		    # If the result is not a hash ref, then the value passes
		    # the test.
		    
		    last VALIDATOR unless ref $result && reftype $result eq 'HASH';
		    
		    # If the result contains an 'error' key, then we need to
		    # try the next validator (if any).  Otherwise, the value
		    # passes the test.
		    
		    last VALIDATOR unless $result->{error};
		}
		
		# If the last validator to be tried generated an error, then
		# the value is bad.  We must report it and skip to the next value.
		
		if ( ref $result and $result->{error} )
		{
		    # If the rule contains a 'warn' directive, then generate a
		    # warning.  But the value is still bad, and will be
		    # ignored.
		    
		    if ( $rr->{warn} )
		    {
			my $msg = $rr->{warn} ne '1' ? $rr->{warn} :
			    $rr->{ERR_INVALID} || $rr->{errmsg} || $result->{error};
			add_warning($vr, $rr, $msg, { param => [ keys %names_found ], value => $raw_val });
		    }
		    
		    # Otherwise, generate an error.
		    
		    else
		    {
			my $msg = $rr->{ERR_INVALID} || $rr->{errmsg} || $result->{error};
			add_error($vr, $rr, $msg, { param => [ sort keys %names_found ], value => $raw_val });
		    }
		    
		    $error_flag = 1;
		    next VALUE;
		}
		
		# If the result contains a 'warn' field, then generate a
		# warning.  In this case, the value is still assumed to be
		# good.
		
		if ( ref $result and $result->{warn} )
		{
		    add_warning($vr, $rr, $result->{warn}, { param => [ sort keys %names_found ], value => $raw_val });
		}
		
		# If we get here, then the value is good.  If the result was a
		# hash ref with a 'value' field, we use that for the clean
		# value. Otherwise, we use the raw value.
		
		my $value = ref $result && exists $result->{value} ? $result->{value} : $raw_val;
		
		# If a cleaning subroutine was defined, pass the value through
		# it and save the cleaned value.
		
		$value = $rr->{cleaner}($value) if ref $rr->{cleaner} eq 'CODE';
		
		push @clean_values, $value;
	    }
	    
	    # If clean values were found, store them.  If multiple values are
	    # allowed, then we store them as a list.  Otherwise, there should
	    # only be one clean value and so we just store it as a scalar.
	    
	    if ( @clean_values )
	    {
		push @{$vr->{clean_list}}, $key;
		
		if ( $rr->{multiple} )
		{
		    $vr->{clean}{$key} = \@clean_values;
		}
		
		else
		{
		    $vr->{clean}{$key} = $clean_values[0];
		}
	    }
	    
	    # If raw values were found for this parameter, but none of them
	    # pass the validators, then we need to indicate this condition.
	    
	    else
	    {
		push @{$vr->{clean_list}}, $key;
		
		if ( defined $rr->{bad_value} && $rr->{bad_value} eq 'ERROR' )
		{
		    add_error($vr, $rr, 'ERR_BAD_VALUES',
			      { param => [ sort keys %names_found ], value => \@raw_values });
		    $vr->{clean}{$key} = undef;
		    $error_flag = 1;
		}
		
		elsif ( defined $rr->{bad_value} )
		{
		    $vr->{clean}{$key} = $rr->{multiple} ? [ $rr->{bad_value} ] : $rr->{bad_value};
		}
		
		else
		{
		    $vr->{clean}{$key} = undef;
		}
	    }
	    
	    # Set the status of this parameter to 1 (passed) unless an error
	    # was generated, 0 (failed) otherwise.
	    
	    $vr->{ps}{$param} = $error_flag ? 0 : 1;
	    
	    # If this rule is not 'optional', then set the status of this
	    # ruleset to 'fulfilled' (2).  That does not mean that the validation
	    # passes, because the parameter value may still have generated an
	    # error.
	    
	    unless ( $rr->{optional} )
	    {
		$vr->{rs}{$ruleset_name} = 2;
	    }
	}
	
	# An 'ignore' directive causes the parameter to be recognized, but no
	# cleaned value is generated and the containing ruleset is not
	# triggered.  No error messages will be generated for this parameter,
	# either.
	
	elsif ( $rr->{type} eq 'ignore' )
	{
	    # Make sure that the parameter is counted as having been
	    # recognized.
	    
	    foreach my $param ( @{$rr->{param}} )
	    {
		$vr->{ps}{$param} = undef;
		
		# Make sure that errors, warnings, and cleaned values for this key
		# are ignored.
		
		my $key = $rr->{key} || $param;
		$vr->{ig}{$key} = 1;
		delete $vr->{clean}{$param};
	    }
	}
	
	# A 'together' or 'at_most_one' rule requires checking the presence
	# of each of the specified parameters.  This kind of rule does not
	# affect the status of any parameters or rulesets, but if violated
	# will generate an error message and cause the entire validation to
	# fail.
	
	elsif ( $rr->{type} eq 'together' or $rr->{type} eq 'at_most_one' )
	{
	    # We start by listing those that are present in the parameter set.
	    
	    my @present = grep exists $vr->{clean}{$_}, @{$rr->{param}};
	    
	    # For a 'together' rule, the count must equal the number of
	    # arguments to this rule, or must be zero.  In other words, there
 	    # must be none present or all present.
	    
	    if ( $rr->{type} eq 'together' and @present > 0 and @present < @{$rr->{param}} )
	    {
		add_error_warn($vr, $rr, 'ERR_TOGETHER', { param => $rr->{param} });
	    }
	    
	    # For a 'at_most_one' rule, the count must be less than or equal
	    # to one (i.e. not more than one must have been specified).
	    
	    elsif ( $rr->{type} eq 'at_most_one' and @present > 1 )
	    {
		add_error_warn($vr, $rr, 'ERR_AT_MOST', { param => \@present });
	    }
	}
	
	# For an 'include' rule, we immediately check the given ruleset
	# (unless it has already been checked).  This statement essentially
	# includes one ruleset within another.  It is very powerful, because
	# it allows different route handlers to to validate their parameters
	# using common rulesets.
	
	elsif ( $rr->{type} eq 'include' )
	{
	    my $rs_name = $rr->{ruleset};
	    
	    # First try to validate the given ruleset.
	    
	    $self->validate_ruleset($vr, $rs_name);
	    
	    # If it was a 'require' rule, check to see if the ruleset was
	    # fulfilled. 
	    
	    if ( $rr->{require} and not $vr->{rs}{$rs_name} == 2 )
	    {
		my (@missing, %found);
		
		@missing = grep { unique($_, \%found) } @{$self->{RULESETS}{$rs_name}{fulfill_order}};
		
		my $msg = @missing == 1 ? 'ERR_REQ_SINGLE' : 'ERR_REQ_MULT';
		add_error_warn($vr, $rr, $msg, { param => \@missing });
	    }
	}
	
	elsif ( $rr->{type} eq 'constraint' )
	{
	    # From the list of rulesets specified in this rule, check how many
	    # were and were not fulfilled.
	    
	    my @fulfilled = grep { $vr->{rs}{$_} == 2 } @{$rr->{ruleset}};
	    my @not_fulfilled = grep { $vr->{rs}{$_} != 2 } @{$rr->{ruleset}};
	    
	    # For a 'require_one' or 'require_any' rule, generate an error if
	    # not enough of the rulesets are fulfilled.  List all of the
	    # parameters which could be given in order to fulfill these
	    # rulesets.
	    
	    if ( @fulfilled == 0 and ( $rr->{constraint} eq 'require_one' or
				       $rr->{constraint} eq 'require_any' ) )
	    {
		my (@missing, %found);
		
		@missing = grep { unique($_, \%found) } 
		    map { @{$self->{RULESETS}{$_}{fulfill_order}} } @not_fulfilled;
		
		my $msg = @missing == 1 ? 'ERR_REQ_SINGLE' : 'ERR_REQ_MULT';
		add_error_warn($vr, $rr, $msg, { param => \@missing });
	    }
	    
	    # For an 'allow_one' or 'require_one' rule, generate an error if
	    # more than one of the rulesets was fulfilled.
	    
	    elsif ( @fulfilled > 1 and ($rr->{constraint} eq 'allow_one' or 
					$rr->{constraint} eq 'require_one') )
	    {
		my @params;
		my ($label) = "A";
		
		foreach my $rs ( @fulfilled )
		{
		    push @params, "($label)"; $label++;
		    push @params, @{$self->{RULESETS}{$rs}{fulfill_order}}
			if ref $self->{RULESETS}{$rs}{fulfill_order} eq 'ARRAY';
		}
		
		my $message = 'ERR_REQ_ONE';
		
		add_error_warn($vr, $rr, 'ERR_REQ_ONE', { param => \@params });
	    }
	}
	
	# For a 'content_type' rule, we set the content type of the response
	# according to the given parameter.
	
	elsif ( $type eq 'content_type' )
	{
	    my $param = $rr->{param};
	    my $value = $vr->{raw}{$param} || '';
	    my $clean_name = $rr->{key} || $rr->{param};
	    my ($selected, $selected_type);
	    
	    push @{$vr->{clean_list}}, $key;
	    
	    if ( $rr->{type_map}{$value} )
	    {
		$vr->{content_type} = $rr->{type_map}{$value};
		$vr->{clean}{$clean_name} = $value;
		$vr->{ps}{$param} = 1;
	    }
	    
	    else
	    {
		$vr->{content_type} = 'unknown';
		$vr->{clean}{$clean_name} = undef;
		$vr->{ps}{$param} = 1;
		$rr->{key} ||= '_content_type';
		add_error_warn($vr, $rr, 'ERR_MEDIA_TYPE', { param => $param, value => $rr->{type_list} });
	    }
	}
    }
};


# Helper function - given a hashref to use as a scratchpad, returns true the
# first time a given argument is encountered and false each subsequent time.
# This can be reset by calling it with a newly emptied scratchpad.

sub unique {
    
    my ($arg, $scratch) = @_;
    
    return if exists $scratch->{$arg};
    $scratch->{$arg} = 1;
}


# Add an error message to the current validation.

sub add_error {

    my ($vr, $rr, $msg, $subst) = @_;
    
    # If no message was given, use a default one.  It's not a very good
    # message, but what can we do?
    
    $msg ||= 'ERR_DEFAULT';
    
    # If the given message starts with 'ERR_', assume it is an error code.  If
    # the code is present as an attribute of the rule record, use the
    # corresponding value as the message.  Otherwise, use the global value.
    
    if ( $msg =~ qr{^ERR_} )
    {
	$msg = $rr->{$msg} || $vr->{settings}{$msg} || $ERROR_MSG{$msg} || $ERROR_MSG{ERR_DEFAULT};
    }
    
    # Next, figure out the error key.  If the rule has a 'key' directive, use
    # that.  Otherwise determine it according to the rule type, ruleset name,
    # and rule number.
    
    my $err_key = $rr->{key}				      ? $rr->{key}
		: $rr->{type} eq 'param'		      ? $rr->{param}
		: $rr->{type} eq 'content_type'		      ? '_content_type'     
		:						"_$rr->{rs}{name}_$rr->{rn}";
    
    # Record the error message under the key, and add the key to the error
    # list.  Other rules might later remove or alter the error
    # message.
    
    push @{$vr->{er}}, [$err_key, subst_error($msg, $subst)];
    $vr->{ec}{$err_key}++;
}


# Add a warning message to the current validation.  The $subst hash if
# given specifies placeholder substitutions.

sub add_warning {

    my ($vr, $rr, $msg, $subst) = @_;
    
    # If no message was given, use a default one.  It's not a very good
    # message, but what can we do?
    
    $msg ||= 'ERR_DEFAULT';
    
    # If the given message starts with 'ERR_', assume it is an error code.  If
    # the code is present as an attribute of the rule record, use the
    # corresponding value as the message.  Otherwise, use the global value.
    
    if ( $msg =~ qr{^ERR_} )
    {
	$msg = $rr->{$msg} || $vr->{settings}{$msg} || $ERROR_MSG{$msg} || $ERROR_MSG{ERR_DEFAULT};
    }
    
    # Next, figure out the warning key.  If the rule has a 'key' directive, use
    # that.  Otherwise determine it according to the rule type, ruleset name,
    # and rule number.
    
    my $warn_key = $rr->{key}				      ? $rr->{key}
		 : $rr->{type} eq 'param'		      ? $rr->{param}
		 : $rr->{type} eq 'content_type'	      ? '_content_type'     
		 :						"_$rr->{rs}{name}_$rr->{rn}";
    
    # Record the warning message under the key.  Other rules might later
    # alter the warning message if they use the same key.
    
    push @{$vr->{wn}}, [$warn_key, subst_error($msg, $subst)];
    $vr->{wc}{$warn_key}++;
}


# Add an error or warning message to the current validation.  If the rule has
# a 'warn' attribute, add a warning.  Otherwise, add an error.  If the rule
# has an 'errmsg' attribute, use its value instead of the error message given.

sub add_error_warn {
    
    my ($vr, $rr, $msg, $subst) = @_;
    
    $msg = $rr->{errmsg} if $rr->{errmsg};
    
    if ( $rr->{warn} )
    {
	$msg = $rr->{warn} if $rr->{warn} ne '1';
	return add_warning($vr, $rr, $msg, $subst);
    }
    
    else
    {
	return add_error($vr, $rr, $msg, $subst);
    }
}


# Substitute placeholders in an error or warning message.

sub subst_error {

    my ($message, $subst) = @_;
    
    while ( $message =~ /^(.*)\{(\w+)\}(.*)$/ )
    {
	my $value = $subst->{$2};
	
	if ( ref $value )
	{
	    if ( reftype $value eq 'ARRAY' )
	    {
		$value = name_list(@$value);
	    }
	    elsif ( reftype $value eq 'HASH' )
	    {
		$value = name_list(sort keys %$value);
	    }
	}
	
	elsif ( defined $value && $value !~ /^'/ )
	{
	    $value = "'$value'";
	}
	
	else
	{
	    $value = "''";
	}
	
	$message = "$1$value$3" if defined $value and $value ne '';
    }
    
    return $message;
}


# Generate a list of quoted strings from the specified values.

sub name_list {
    
    my @names = @_;
    
    return unless @names;
    return "'" . join("', '", @names) . "'";
};


package HTTP::Validate::Result;

=head1 OTHER METHODS

The result object returned by L</check_params> provides the following
methods: 

=head3 passed

Returns true if the validation passed, false otherwise.

=cut

sub passed {
    
    my ($self) = @_;
    
    # If any errors occurred, then the validation failed.
    
    return if ref $self->{er} eq 'ARRAY' && @{$self->{er}};
    
    # Otherwise, it passed.
    
    return 1;
}


=head3 errors

In a scalar context, this returns the number of errors generated by this
validation.  In a list context, it returns a list of error messages.  If an
argument is given, only messages whose key equals the argument are returned.

=cut

sub errors {

    my ($self, $key) = @_;
    
    # In scalar context, just return the count.
    
    if ( ! wantarray )
    {
	return 0 unless defined $key ? ref $self->{ec} : ref $self->{er};
	return defined $key ? ($self->{ec}{$key} || 0) : scalar @{$self->{er}};
    }
    
    # In list context, if a key is given then return just the matching error
    # messages or an empty list if there are none.
    
    elsif ( defined $key )
    {
	return unless ref $self->{ec};
	return map { $_->[1] } grep { $_->[0] eq $key } @{$self->{er}};
    }
    
    # If no key is given, just return all of the messages.
    
    else
    {
	return map { $_->[1] } @{$self->{er}};
    }
}

=head3 error_keys

Returns the list of keys for which error messages were generated.

=cut

sub error_keys {
    
    my ($self) = @_;
    return keys %{$self->{ec}};
}


=head3 warnings

In a scalar context, this returns the number of warnings generated by the
validation.  In a list context, it returns a list of warning messages.  If an
argument is given, only messages whose key equals the argument are returned.

=cut

sub warnings {

    my ($self, $key) = @_;
    
    # In scalar context, just return the count.
    
    if ( ! wantarray )
    {
	return 0 unless defined $key ? ref $self->{wc} : ref $self->{wn};
	return defined $key ? ($self->{wc}{$key} || 0) : scalar @{$self->{wn}};
    }
    
    # In list context, if a key is given then return just the matching warning
    # messages or an empty list if there are none.
     
    elsif ( defined $key )
    {
	return unless ref $self->{wn};
	return map { $_->[1] } grep { $_->[0] eq $key } @{$self->{wn}};
    }
    
    # If no key is given, just return all of the messages.
    
    else
    {
	return map { $_->[1] } @{$self->{wn}};
    }
}


=head3 warning_keys

Returns the list of keys for which warning messages were generated.

=cut

sub warning_keys {
    
    my ($self) = @_;
    return keys %{$self->{wc}};
}


=head3 keys

In a scalar context, this returns the number of parameters that had valid values.  In a list
context, it returns a list of parameter names in the order they were recognized.  Individual
parameter values can be gotten by using either L</values> or L</value>.

=cut

sub keys {

    my ($self) = @_;
    
    # Return the list of parameter keys in the order they were recognized.
    
    return @{$self->{clean_list}};
}


=head3 values

Returns the hash of clean parameter values.  This is not a copy, so any
modifications you make to it will be reflected in subsequent calls to L</value>.

=cut

sub values {
    
    my ($self) = @_;
    
    # Return the clean value hash.
    
    return $self->{clean};
}

=head3 value

Returns the value of the specified parameter, or undef if that parameter was
not specified in the request or if its value was invalid.

=cut

sub value {

    my ($self, $param) = @_;
    
    return $self->{clean}{$param};
}


=head3 specified

Returns true if the specified parameter was specified in the request with at least
one value, whether or not that value was valid.  Returns false otherwise.

=cut

sub specified {
    
    my ($self, $param) = @_;
    
    return exists $self->{clean}{$param};
}


=head3 raw

Returns a hash of the raw parameter values as originally provided to
L</check_params>.  Multiple values are represented by array refs.  The
result of this method can be used, for example, to redisplay a web form if the
submission resulted in errors.

=cut

sub raw {
    
    my ($self, $param) = @_;
    
    return $self->{raw};
}


=head3 content_type

This returns the content type specified by the request parameters.  If none
was specified, or if no content_type rule was included in the validation, it
returns undef.

=cut

sub content_type {

    my ($self) = @_;
    
    return $self->{content_type};
}


package HTTP::Validate;

# At the very end, we have the validator functions
# ================================================

=head1 VALIDATORS

Parameter rules can each include one or more validator functions under the key
C<valid>.  The job of these functions is two-fold: first to check for good
parameter values, and second to generate cleaned values.

There are a number of validators provided by this module, or you can specify a
reference to a function of your own.

=head2 Predefined validators

=head3 INT_VALUE

This validator accepts any integer, and rejects all other values.  It
returns a numeric value, generated by adding 0 to the raw parameter value.

=head3 INT_VALUE(min,max)

This validator accepts any integer between C<min> and C<max> (inclusive).  If either C<min>
or C<max> is undefined, that bound will not be tested.

=head3 POS_VALUE

This is an alias for C<INT_VALUE(1)>.

=head3 POS_ZERO_VALUE

This is an alias for C<INT_VALUE(0)>.

=cut

sub int_value {

    my ($value, $context, $min, $max) = @_;
    
    unless ( $value =~ /^([+-]?\d+)$/ )
    {
	return { error => "bad value '$value' for {param}: must be an integer" };
    }
    
    if ( defined $min and $value < $min )
    {
	my $criterion = defined $max ? "between $min and $max"
		      : $min == 0    ? "nonnegative"
		      : $min == 1    ? "positive"
		      :		       "at least $min";	
	
	return { error => "bad value '$value' for {param}: must be $criterion" };
    }
    
    if ( defined $max and $value > $max )
    {
	my $criterion = defined $min ? "between $min and $max" : "at most $max";
	
	return { error => "bad value '$value' for {param} must be $criterion" };
    }
    
    return { value => $value + 0 };
}

sub INT_VALUE { 
    
    my ($min, $max) = @_;
    
    croak "lower bound must be an integer (was '$min')" unless !defined $min || $min =~ /^[+-]?\d+$/;
    croak "upper bound must be an integer (was '$max')" unless !defined $max || $max =~ /^[+-]?\d+$/;
    
    return \&int_value unless defined $min or defined $max;
    return sub { return int_value(shift, shift, $min, $max) };
};

sub POS_VALUE { 
    
    return sub { return int_value(shift, shift, 1) };
};

sub POS_ZERO_VALUE { 

    return sub { return int_value(shift, shift, 0) };
};


=head3 DECI_VALUE

This validator accepts any decimal number, including exponential notation, and
rejects all other values.  It returns a numeric value, generated by adding 0
to the parameter value.

=head3 DECI_VALUE(min,max)

This validator accepts any real number between C<min> and C<max> (inclusive).
Specify these bounds in quotes (i.e. as string arguments) if non-zero so that
they will appear properly in error messages.  If either C<min> or C<max> is
undefined, that bound will not be tested.

=cut

sub deci_value {
    
    my ($value, $context, $min, $max) = @_;
    
    unless ( $value =~ /^[+-]?(?:\d+\.\d*|\d*\.\d+|\d+)(?:[eE][+-]?\d+)?$/ )
    {
	return { error => "bad value '$value' for {param}: must be a decimal number" };
    }
    
    if ( defined $min and defined $max and ($value < $min or $value > $max) )
    {
	return { error => "bad value '$value' for {param}: must be between $min and $max" };
    }
    
    if ( defined $min and $value < $min )
    {
	return { error => "bad value '$value' for {param}: must be at least $min" };
    }
    
    if ( defined $max and $value > $max )
    {
	return { error => "bad value '$value' for {param}: must be at most $max" };
    }
    
    return { value => $value + 0 };
}

sub DECI_VALUE { 
    
    my ($min, $max) = @_;
    
    croak "lower bound must be numeric" if defined $min && !looks_like_number($min);
    croak "upper bound must be numeric" if defined $max && !looks_like_number($max);
    
    return \&deci_value unless defined $min or defined $max;
    return sub { return deci_value(shift, shift, $min, $max) };
};


=head3 MATCH_VALUE

This validator accepts any string that matches the specified pattern, and
rejects any that does not.  If you specify the pattern as a string, it will be
converted into a regexp and will have ^ prepended and $ appended, and also the
modifier "i".  If you specify the pattern using C<qr>, then it is used unchanged.
Any rule that uses this validator should be provided with an error directive, since the
default error message is by necessity not very informative.  The value is not
cleaned in any way.

=cut

sub match_value {

    my ($value, $context, $pattern) = @_;
    
    return if $value =~ $pattern;
    return { error => "bad value '$value' for {param}: did not match the proper pattern" };
}

sub MATCH_VALUE {

    my ($pattern) = @_;
    
    croak "MATCH_VALUE requires a regular expression" unless
	defined $pattern && (!ref $pattern || ref $pattern eq 'Regexp');
    
    my $re = ref $pattern ? $pattern : qr{^$pattern$}oi;
    
    return sub { return match_value(shift, shift, $re) };
};


=head3 ENUM_VALUE(string,...)

This validator accepts any of the specified string values, and rejects all
others.  Comparisons are case insensitive.  If the version of Perl is 5.016 or
greater, or if the module C<Unicode::Casefold> is available and has been
required, then the C<fc> function will be used instead of the usual C<lc> when
comparing values.  The cleaned value will be the matching string value from
this call.

If any of the strings is '#', then subsequent values will be accepted but not
reported in the standard error message as allowable values.  This allows for
undocumented values to be accepted.

=cut

sub enum_value {
    
    my ($value, $context, $accepted, $good_list) = @_;
    
    my $folded = $case_fold->($value);
    
    # If the value is found in the $accepted hash, then we're good.  Return
    # the value as originally given, not the case-folded version.
    
    return { value => $accepted->{$folded} } if exists $accepted->{$folded};
    
    # Otherwise, then we have an error.
    
    return { error => "bad value '$value' for {param}: must be one of $good_list" };
}

sub ENUM_VALUE {
    
    my (%accepted, @documented, $undoc);
    
    foreach my $k ( @_ )
    {
	next unless defined $k && $k ne '';
	
	if ( $k eq '#' )
	{
	    $undoc = 1;
	    next;
	}
	
	$accepted{ $case_fold->($k) } = $k;
	push @documented, $k unless $undoc;
    }
    
    #my @non_empty = grep { defined $_ && $_ ne '' } @_;
    croak "ENUM_VALUE requires at least one value" unless keys %accepted;
    
    # my %accepted = map { $case_fold->($_) => $_ } @non_empty;
    my $good_list = "'" . join("', '", @documented) . "'";
    
    return sub { return enum_value(shift, shift, \%accepted, $good_list) };
};


=head3 BOOLEAN_VALUE

This validator is used for parameters that take a true/false value.  It
accepts any of the following values: "yes", "no", "true", "false", "on",
"off", "1", "0", compared case insensitively.  It returns an error if any
other value is specified.  The cleaned value will be 1 or 0.

=cut

sub boolean_value {

    my ($value, $context) = @_;
    
    if ( ref($value) =~ /boolean/i )
    {
	return { value => $value };
    }
    
    elsif ( ! ref $value )
    {
	if ( $value =~ /^(?:1|yes|true|on)$/i )
	{
	    return { value => 1 };
	}
	
	elsif ( $value =~ /^(?:0|no|false|off)$/i )
	{
	    return { value => 0 };
	}
    }
    
    return { error => "the value of {param} must be one of: yes, no, true, false, on, off, 1, 0" };
}

sub BOOLEAN_VALUE { return \&boolean_value; };


=head3 FLAG_VALUE

This validator should be used for parameters that are considered to be "true"
if present with an empty value.  The validator returns a value of 1 in this case,
and behaves like 'BOOLEAN_VALUE' otherwise.

=cut

sub FLAG_VALUE { return 'FLAG_VALUE'; };


# =head3 EMPTY_VALUE

# This validator accepts only the empty value.  You can use this when you want a
# ruleset to be fulfilled even if the specified parameter is given an empty
# value.  This will typically be used along with at least one other validator for the
# same parameter.  For example:

#     define_ruleset foo =>
#         { param => 'bar', valid => [EMPTY_VALUE, POS_VALUE] };

# This rule would be satisfied if the parameter 'bar' is given either an empty
# value or a value that is a positive integer.  The ruleset will be fulfilled in
# either case, but will not be fulfilled if 'bar' is not mentioned at all.  For
# best results EMPTY_VALUE should not be the last validator in the list, because
# if a value fails all of the validators then the last error message is reported
# and its error message is by necessity not very helpful.

# =cut

# sub empty_value {
    
#     my ($value, $context) = @_;
    
#     return if !defined $value || $value eq '';
#     return { error => "parameter {param} must be empty unless it is given a valid value" };
# }

# sub EMPTY_VALUE {

#     return 'EMPTY_VALUE';
# };


=head3 ANY_VALUE

This validator accepts any non-empty value.  Using this validator
is equivalent to not specifying any validator at all.

=cut

sub ANY_VALUE {
    
    return 'ANY_VALUE';
};


=head2 Reusing validators

Every time you use a parametrized validator such as C<INT_VALUE(0,10)>, a new
closure is generated.  If you are repeating a particular set of parameters
many times, to save space you may want to instantiate the validator just once:

    my $zero_to_ten = INT_VALUE(0,10);
    
    define_ruleset( 'foo' =>
        { param => 'bar', valid => $zero_to_ten },
        { param => 'baz', valid => $zero_to_ten });

=head2 Writing your own validator functions

If you wish to validate parameters which do not match any of the validators
described above, you can write your own validator function.  Validator
functions are called with two arguments:

    ($value, $context)

Where $value is the raw parameter value and $context is a hash ref provided
when the validation process is initiated (or an empty hashref if none is
provided).  This allows the passing of information such as database handles to
the validator functions.

If your function decides that the parameter value is valid and does not need
to be cleaned, it can indicate this by returning an empty result.

Otherwise, it must return a hash reference with one or more of the following
keys: 

=over 4

=item error

If the parameter value is not valid, the value of this key should be an error
message that states I<what a good value should look like>.  This message should
contain the placeholder {param}, which will be substituted with the parameter
name.  Use this placeholder, and do not hard-code the parameter name.

Here is an example of a good message:

    "the value of {param} must be a positive integer (was {value})".

Here is an example of a bad message:

    "bad value for 'foo'".

=item warn

If the parameter value is acceptable but questionable in some way, the value
of this key should be a message that states what a good value should look
like.  All such messages will be made available through the result object that
is returned by the validation routine.  The code that handles the request may
then choose to display these messages as part of the response.  Your code may
also make use of this information during the process of responding to the
request.

=item value

If the parameter value represents anything other than a simple string (i.e. a
number, list, or more complicated data structure), then the value of this key
should be the converted or "cleaned" form of the parameter value.  For
example, a numeric parameter might be converted into an actual number by
adding zero to it, or a pair of values might be split apart and converted into
an array ref.  The value of this key will be returned as the "cleaned" value
of the parameter, in place of the raw parameter value provided in the request.

=back

=head3 Parametrized validators

If you want to write your own parametrized validator, write a function that
generates and returns a closure.  For example:

    sub integer_multiple {

        my ($value, $context, $base) = @_;
        
        return { value => $value + 0 } if $value % $base == 0;
        return { error => "the value of {param} must be a multiple of $base (was {value})" };
    }
    
    sub INTEGER_MULTIPLE {

        my ($base) = $_[0] + 0;
        
        croak "INTEGER_MULTIPLE requires a numeric parameter greater than zero"
            unless defined $base and $base > 0;
        
        return sub { return integer_multiple(shift, shift, $base) };
    }
    
    define_ruleset( 'foo' =>
        { param => foo, valid => INTEGER_MULTIPLE(3) });

=cut



=head1 AUTHOR

Michael McClennen, C<< <mmcclenn at geology.wisc.edu> >>

=head1 SUPPORT

Please report any bugs or feature requests to C<bug-http-validate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-Validate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael McClennen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of HTTP::Validate
