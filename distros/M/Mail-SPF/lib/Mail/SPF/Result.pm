#
# Mail::SPF::Result
# SPF result class.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
# $Id: Result.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::Result;

=head1 NAME

Mail::SPF::Result - SPF result class

=cut

use warnings;
use strict;

use utf8;  # Hack to keep Perl 5.6 from whining about /[\p{}]/.

use base 'Error', 'Mail::SPF::Base';
    # An SPF result is not really a code exception in ideology, but in form.
    # The Error base class fits our purpose, anyway.

use Mail::SPF::Util;

use Error ':try';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant result_classes => {
    pass        => 'Mail::SPF::Result::Pass',
    fail        => 'Mail::SPF::Result::Fail',
    softfail    => 'Mail::SPF::Result::SoftFail',
    neutral     => 'Mail::SPF::Result::Neutral',
   'neutral-by-default'
                => 'Mail::SPF::Result::NeutralByDefault',
    none        => 'Mail::SPF::Result::None',
    error       => 'Mail::SPF::Result::Error',
    permerror   => 'Mail::SPF::Result::PermError',
    temperror   => 'Mail::SPF::Result::TempError'
};

use constant received_spf_header_name => 'Received-SPF';

use constant received_spf_header_scope_names_by_scope => {
    helo        => 'helo',
    mfrom       => 'mailfrom',
    pra         => 'pra'
};

use constant received_spf_header_identity_key_names_by_scope => {
    helo        => 'helo',
    mfrom       => 'envelope-from',
    pra         => 'pra'
};

use constant atext_pattern              => qr/[\p{IsAlnum}!#\$%&'*+\-\/=?^_`{|}~]/;

use constant dot_atom_pattern           => qr/
    (${\atext_pattern})+ ( \. (${\atext_pattern})+ )*
/x;

# Interface:
##############################################################################

=head1 SYNOPSIS

For the general usage of I<Mail::SPF::Result> objects in code that calls
Mail::SPF, see L<Mail::SPF>.  For the detailed interface of I<Mail::SPF::Result>
and its derivatives, see below.

=head2 Throwing results

    package Mail::SPF::Foo;
    use Error ':try';
    use Mail::SPF::Result;

    sub foo {
        if (...) {
            $server->throw_result('pass', $request)
        }
        else {
            $server->throw_result('permerror', $request, 'Invalid foo');
        }
    }

=head2 Catching results

    package Mail::SPF::Bar;
    use Error ':try';
    use Mail::SPF::Foo;

    try {
        Mail::SPF::Foo->foo();
    }
    catch Mail::SPF::Result with {
        my ($result) = @_;
        ...
    };

=head2 Using results

    my $result_name     = $result->name;
    my $result_code     = $result->code;
    my $request         = $result->request;
    my $local_exp       = $result->local_explanation;
    my $authority_exp   = $result->authority_explanation
        if $result->can('authority_explanation');
    my $spf_header      = $result->received_spf_header;

=cut

# Implementation:
##############################################################################

=head1 DESCRIPTION

An object of class B<Mail::SPF::Result> represents the result of an SPF
request.

There is usually no need to construct an SPF result object directly using the
C<new> constructor.  Instead, use the C<throw> class method to signal to the
calling code that a definite SPF result has been determined.  In other words,
use Mail::SPF::Result and its derivatives just like exceptions.  See L<Error>
or L<perlfunc/eval> for how to handle exceptions in Perl.

=head2 Constructor

The following constructor is provided:

=over

=item B<new($server, $request)>: returns I<Mail::SPF::Result>

=item B<new($server, $request, $text)>: returns I<Mail::SPF::Result>

Creates a new SPF result object and associates the given I<Mail::SPF::Server>
and I<Mail::SPF::Request> objects with it.  An optional result text may be
specified.

=cut

sub new {
    my ($self, @args) = @_;

    local $Error::Depth = $Error::Depth + 1;

    $self =
        ref($self) ?                        # Was new() invoked on a class or an object?
            bless({ %$self }, ref($self))   # Object: clone source result object.
        :   $self->SUPER::new();            # Class:  create new result object.

    # Set/override fields:
    $self->{server}  = shift(@args) if @args;
    defined($self->{server})
        or throw Mail::SPF::EOptionRequired('Mail::SPF server object required');
    $self->{request} = shift(@args) if @args;
    defined($self->{request})
        or throw Mail::SPF::EOptionRequired('Request object required');
    $self->{'-text'} = shift(@args) if @args;

    return $self;
}

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<throw($server, $request)>: throws I<Mail::SPF::Result>

=item B<throw($server, $request, $text)>: throws I<Mail::SPF::Result>

Throws a new SPF result object, associating the given I<Mail::SPF::Server> and
I<Mail::SPF::Request> objects with it.  An optional result text may be
specified.

I<Note>:  Do not write code invoking C<throw> on I<literal> result class names
as this would ignore any derivative result classes provided by B<Mail::SPF>
extension modules.  Invoke the L<C<throw_result>|Mail::SPF::Server/throw_result>
method on a I<Mail::SPF::Server> object instead.

=cut

sub throw {
    my ($self, @args) = @_;
    local $Error::Depth = $Error::Depth + 1;
    $self = $self->new(@args);
        # Always create/clone a new result object, not just when throwing for the first time!
    die($Error::THROWN = $self);
}

=item B<name>: returns I<string>

I<Abstract>.  Returns the result name of the result class (or object).  For
classes of the I<Mail::SPF::Result::*> hierarchy, this roughly corresponds to
the trailing part of the class name.  For example, returns C<neutral-by-default>
if invoked on I<Mail::SPF::Result::NeutralByDefault>.  Also see the L</code>
method.  This method may also be used as an instance method.

This method must be implemented by sub-classes of Mail::SPF::Result for which
the result I<name> differs from the result I<code>.

=cut

# This method being implemented here does not make it any less abstract,
# because the code() method it uses is still abstract.
sub name {
    my ($self) = @_;
    return $self->code;
}

=item B<class>: returns I<class>

=item B<class($name)>: returns I<class>

Maps the given result name to the corresponding I<Mail::SPF::Result::*> class,
or returns the result base class (the class on which it is invoked) if no
result name is given.  If an unknown result name is specified, returns
B<undef>.

=cut

sub class {
    my ($self, $name) = @_;
    return defined($name) ? $self->result_classes->{lc($name)} : (ref($self) || $self);
}

=item B<isa_by_name($name)>: returns I<boolean>

If the class (or object) on which this method is invoked represents the given
result name (or a derivative name), returns B<true>.  Returns B<false>
otherwise.  This method may also be used as an instance method.

For example, C<< Mail::SPF::Result::NeutralByDefault->isa_by_name('neutral') >>
returns B<true>.

=cut

sub isa_by_name {
    my ($self, $name) = @_;
    my $suspect_class = $self->class($name);
    return FALSE if not defined($suspect_class);
    return $self->isa($suspect_class);
}

=item B<code>: returns I<string>

I<Abstract>.  Returns the basic SPF result code (C<"pass">, C<"fail">,
C<"softfail">, C<"neutral">, C<"none">, C<"error">, C<"permerror">,
C<"temperror">) of the result class on which it is invoked.  All valid result
codes are valid result names as well, the reverse however does not apply.  This
method may also be used as an instance method.

This method is abstract and must be implemented by sub-classes of
Mail::SPF::Result.

=item B<is_code($code)>: returns I<boolean>

If the class (or object) on which this method is invoked represents the given
result code, returns B<true>.  Returns B<false> otherwise.  This method may
also be used as an instance method.

I<Note>:  The L</isa_by_name> method provides a superset of this method's
functionality.

=cut

sub is_code {
    my ($self, $code) = @_;
    return $self->isa_by_name($code);
}

=item B<received_spf_header_name>: returns I<string>

Returns B<'Received-SPF'> as the field name for C<Received-SPF> header fields.
This method should be overridden by B<Mail::SPF> extension modules that provide
non-standard features (such as local policy) with the capacity to dilute the
purity of SPF results, in order not to deceive users of the header field into
mistaking it as an indication of a natural SPF result.

=back

=head2 Instance methods

The following instance methods are provided:

=over

=item B<throw>: throws I<Mail::SPF::Result>

=item B<throw($server, $request)>: throws I<Mail::SPF::Result>

=item B<throw($server, $request, $text)>: throws I<Mail::SPF::Result>

Re-throws an existing SPF result object.  If I<Mail::SPF::Server> and
I<Mail::SPF::Request> objects are specified, associates them with the result
object, replacing the prior server and request objects.  If a result text is
specified as well, overrides the prior result text.

=item B<server>: returns I<Mail::SPF::Server>

Returns the Mail::SPF server object that produced the result at hand.

=item B<request>: returns I<Mail::SPF::Request>

Returns the SPF request that led to the result at hand.

=cut

# Read-only accessors:
__PACKAGE__->make_accessor($_, TRUE)
    foreach qw(server request);

=item B<text>: returns I<string>

Returns the text message of the result object.

=item B<stringify>: returns I<string>

Returns the result's name and text message formatted as a string.  You can
simply use a Mail::SPF::Result object as a string for the same effect, see
L</OVERLOADING>.

=cut

sub stringify {
    my ($self) = @_;
    return sprintf(
        "%s (%s)",
        $self->name,
        Mail::SPF::Util->sanitize_string($self->SUPER::stringify)
    );
}

=item B<local_explanation>: returns I<string>; throws I<Mail::SPF::EDNSError>,
I<Mail::SPF::EInvalidMacroString>

Returns a locally generated explanation for the result.

The local explanation is prefixed with the authority domain whose sender policy
is responsible for the result.  If the responsible sender policy referred to
another domain's policy (using the C<include> mechanism or the C<redirect>
modifier), that other domain which is I<directly> responsible for the result is
also included in the local explanation's head.  For example:

    example.com: <local-explanation>

The authority domain C<example.com>'s sender policy is directly responsible for
the result.

    example.com ... other.example.org: <local-explanation>

The authority domain C<example.com> (directly or indirectly) referred to the
domain C<other.example.org>, whose sender policy then led to the result.

=cut

sub local_explanation {
    my ($self) = @_;
    my $local_explanation = $self->{local_explanation};

    return $local_explanation
        if defined($local_explanation);

    # Prepare local explanation:
    my $request = $self->{request};
    $local_explanation = $request->state('local_explanation');
    if (defined($local_explanation)) {
        $local_explanation = sprintf("%s (%s)", $local_explanation->expand, lcfirst($self->text));
    }
    else {
        $local_explanation = $self->text;
    }

    # Resolve authority domains of root-request and bottom sub-request:
    my $root_request = $request->root_request;
    $local_explanation =
        $request == $root_request ?
            sprintf("%s: %s", $request->authority_domain, $local_explanation)
        :   sprintf("%s ... %s: %s",
                $root_request->authority_domain, $request->authority_domain, $local_explanation);

    return $self->{local_explanation} = Mail::SPF::Util->sanitize_string($local_explanation);
}

=item B<received_spf_header>: returns I<string>

Returns a string containing an appropriate C<Received-SPF> header field for the
result object.  The header field is not line-wrapped and contains no trailing
newline character.

=cut

sub received_spf_header {
    my ($self) = @_;
    return $self->{received_spf_header}
        if defined($self->{received_spf_header});
    my $scope_name =
        $self->received_spf_header_scope_names_by_scope->{$self->{request}->scope};
    my $identity_key_name =
        $self->received_spf_header_identity_key_names_by_scope->{$self->{request}->scope};
    my @info_pairs = (
        receiver            => $self->{server}->hostname || 'unknown',
        identity            => $scope_name,
        $identity_key_name  => $self->{request}->identity,
        (
            ($self->{request}->scope ne 'helo' and defined($self->{request}->helo_identity)) ?
                (helo       => $self->{request}->helo_identity)
            :   ()
        ),
        'client-ip'         => Mail::SPF::Util->ip_address_to_string($self->{request}->ip_address)
    );
    my $info_string;
    while (@info_pairs) {
        my $key   = shift(@info_pairs);
        my $value = shift(@info_pairs);
        $info_string .= '; ' if defined($info_string);
        if ($value !~ /^${\dot_atom_pattern}$/o) {
            $value =~ s/(["\\])/\\$1/g;   # Escape '\' and '"' characters.
            $value = '"' . $value . '"';  # Double-quote value.
        }
        $info_string .= "$key=$value";
    }
    return $self->{received_spf_header} = sprintf(
        "%s: %s (%s) %s",
        $self->received_spf_header_name,
        $self->code,
        $self->local_explanation,
        $info_string
    );
}

=back

=head1 OVERLOADING

If a Mail::SPF::Result object is used as a I<string>, the L</stringify> method
is used to convert the object into a string.

=head1 RESULT CLASSES

The following result classes are provided:

=over

=item *

I<Mail::SPF::Result::Pass>

=item *

I<Mail::SPF::Result::Fail>

=item *

I<Mail::SPF::Result::SoftFail>

=item *

I<Mail::SPF::Result::Neutral>

=over

=item *

I<Mail::SPF::Result::NeutralByDefault>

This is a special case of the C<neutral> result that is thrown as a default
when "falling off" the end of the record during evaluation.  See RFC 4408,
4.7.

=back

=item *

I<Mail::SPF::Result::None>

=item *

I<Mail::SPF::Result::Error>

=over

=item *

I<Mail::SPF::Result::PermError>

=item *

I<Mail::SPF::Result::TempError>

=back

=back

The following result classes have additional functionality:

=over

=item I<Mail::SPF::Result::Fail>

The following additional instance method is provided:

=over

=item B<authority_explanation>: returns I<string>; throws I<Mail::SPF::EDNSError>,
I<Mail::SPF::EInvalidMacroString>

Returns the authority domain's explanation for the result.  Be aware that the
authority domain may be a malicious party and thus the authority explanation
should not be trusted blindly.  See RFC 4408, 10.5, for a detailed discussion
of this issue.

=back

=back

=cut

package Mail::SPF::Result::Pass;
our @ISA = 'Mail::SPF::Result';
use constant code => 'pass';

package Mail::SPF::Result::Fail;
our @ISA = 'Mail::SPF::Result';
use Error ':try';
use Mail::SPF::Exception;
use constant code => 'fail';

sub authority_explanation {
    my ($self) = @_;
    my $authority_explanation = $self->{authority_explanation};

    return $authority_explanation
        if defined($authority_explanation);

    my $server  = $self->{server};
    my $request = $self->{request};

    my $authority_explanation_macrostring = $request->state('authority_explanation');

    # If an explicit explanation was specified by the authority domain...
    if (defined($authority_explanation_macrostring)) {
        try {
            # ... then try to expand it:
            $authority_explanation = $authority_explanation_macrostring->expand;
        }
        catch Mail::SPF::EInvalidMacroString with {};
            # Ignore expansion errors and leave authority explanation undefined.
    }

    # If no authority explanation could be determined so far...
    if (not defined($authority_explanation)) {
        # ... then use the server's default authority explanation:
        $authority_explanation =
            $server->default_authority_explanation->new(request => $request)->expand;
    }

    return $self->{authority_explanation} = $authority_explanation;
}

package Mail::SPF::Result::SoftFail;
our @ISA = 'Mail::SPF::Result';
use constant code => 'softfail';

package Mail::SPF::Result::Neutral;
our @ISA = 'Mail::SPF::Result';
use constant code => 'neutral';

package Mail::SPF::Result::NeutralByDefault;
our @ISA = 'Mail::SPF::Result::Neutral';
use constant name => 'neutral-by-default';
    # This is a special-case of the Neutral result that is thrown as a default
    # when "falling off" the end of the record.  See Mail::SPF::Record::eval().

package Mail::SPF::Result::None;
our @ISA = 'Mail::SPF::Result';
use constant code => 'none';

package Mail::SPF::Result::Error;
our @ISA = 'Mail::SPF::Result';
use constant code => 'error';

package Mail::SPF::Result::PermError;
our @ISA = 'Mail::SPF::Result::Error';
use constant code => 'permerror';

package Mail::SPF::Result::TempError;
our @ISA = 'Mail::SPF::Result::Error';
use constant code => 'temperror';

=head1 SEE ALSO

L<Mail::SPF>, L<Mail::SPF::Server>, L<Error>, L<perlfunc/eval>

L<http://tools.ietf.org/html/rfc4408>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>

=cut

package Mail::SPF::Result;

TRUE;
