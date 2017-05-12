#
# Mail::SPF::Mod
# SPF record modifier class.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: Mod.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::Mod;

=head1 NAME

Mail::SPF::Mod - SPF record modifier base class

=cut

use warnings;
use strict;

use utf8;  # Hack to keep Perl 5.6 from whining about /[\p{}]/.

use base 'Mail::SPF::Term';

use Mail::SPF::MacroString;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant name_pattern   => qr/ ${\__PACKAGE__->SUPER::name_pattern} (?= = ) /x;

=head1 DESCRIPTION

An object of class B<Mail::SPF::Mod> represents a modifier within an SPF
record.  Mail::SPF::Mod cannot be instantiated directly.  Create an instance of
a concrete sub-class instead.

=head2 Constructors

The following constructors are provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Mod>

I<Abstract>.  Creates a new SPF record modifier object.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<text>

A I<string> denoting the unparsed text of the modifier.

=item B<name>

A I<string> denoting the name of the modifier.  I<Required> if a generic
I<Mail::SPF::Mod> object (as opposed to a specific sub-class) is being
constructed.

=item B<domain_spec>

Either a plain I<string> or a I<Mail::SPF::MacroString> object denoting an
optional C<domain-spec> parameter of the mechanism.

=back

=cut

sub new {
    my ($self, %options) = @_;
    $self->class ne __PACKAGE__
        or throw Mail::SPF::EAbstractClass;
    $self = $self->SUPER::new(%options);
    $self->{parse_text} = $self->{text} if not defined($self->{parse_text});
    $self->{domain_spec} = Mail::SPF::MacroString->new(text => $self->{domain_spec})
        if  defined($self->{domain_spec})
        and not UNIVERSAL::isa($self->{domain_spec}, 'Mail::SPF::MacroString');
    return $self;
}

=item B<new_from_string($text, %options)>: returns I<Mail::SPF::Mod>;
throws I<Mail::SPF::ENothingToParse>, I<Mail::SPF::EInvalidMod>

I<Abstract>.  Creates a new SPF record modifier object by parsing the string and
any options given.

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<name_pattern>: returns I<Regexp>

Returns a regular expression that matches any legal modifier name.

=back

=head2 Instance methods

The following instance methods are provided:

=over

=cut

sub parse {
    my ($self) = @_;
    defined($self->{parse_text})
        or throw Mail::SPF::ENothingToParse('Nothing to parse for modifier');
    $self->parse_name();
    $self->parse_params(TRUE);
    $self->parse_end();
    return;
}

sub parse_name {
    my ($self) = @_;
    if ($self->{parse_text} =~ s/^(${\$self->name_pattern})=//) {
        $self->{name} = $1;
    }
    else {
        throw Mail::SPF::EInvalidMod(
            "Unexpected modifier name encountered in '" . $self->text . "'");
    }
    return;
}

sub parse_params {
    my ($self, $required) = @_;
    # Parse generic macro string of parameters text (should be overridden in sub-classes):
    if ($self->{parse_text} =~ s/^(${\$self->macro_string_pattern})$//) {
        $self->{params_text} = $1;
    }
    elsif ($required) {
        throw Mail::SPF::EInvalidMacroString(
            "Invalid macro string encountered in '" . $self->text . "'");
    }
    return;
}

sub parse_end {
    my ($self) = @_;
    $self->{parse_text} eq ''
        or throw Mail::SPF::EJunkInTerm("Junk encountered in modifier '" . $self->text . "'");
    delete($self->{parse_text});
    return;
}

=item B<text>: returns I<string>; throws I<Mail::SPF::ENoUnparsedText>

Returns the unparsed text of the modifier.  Throws a
I<Mail::SPF::ENoUnparsedText> exception if the modifier was created
synthetically instead of being parsed, and no text was provided.

=item B<name>: returns I<string>

Returns the name of the modifier.

=cut

# Read-only accessor:
__PACKAGE__->make_accessor('name', TRUE);

=item B<params>: returns I<string>

I<Abstract>.  Returns the modifier's parameters formatted as a string.

A sub-class of Mail::SPF::Mod does not have to implement this method if it
supports no parameters, although this is highly unlikely.

=item B<stringify>: returns I<string>

Formats the modifier's name and parameters as a string and returns it.  You can
simply use a Mail::SPF::Mod object as a string for the same effect, see
L<"OVERLOADING">.

=cut

sub stringify {
    my ($self) = @_;
    my $params = $self->can('params') ? $self->params : undef;
    return sprintf(
        '%s=%s',
        $self->name,
        defined($params) ? $params : ''
    );
}

=item B<process>: throws I<Mail::SPF::Result>, I<Mail::SPF::Result::Error>,
I<Mail::SPF::Exception>

I<Abstract>.  Processes the modifier.  What that means depends on the actual
implementation in sub-classes.  See L</MODIFIER TYPES> below.

This method is abstract and must be implemented by sub-classes of
Mail::SPF::Mod.

=back

=head1 MODIFIER TYPES

There are different basic types of modifiers, which are described below.  All
of them are provided by the B<Mail::SPF::Mod> module.

=head2 Global modifiers - B<Mail::SPF::GlobalMod>

B<SPFv1> (RFC 4408) only knows "global" modifiers.  A global modifier may
appear anywhere in an SPF record, but only once.  During evaluation of the
record, global modifiers are processed after the last mechanism has been
evaluated and an SPF result has been determined.

=cut

package Mail::SPF::GlobalMod;
our @ISA = 'Mail::SPF::Mod';

sub new {
    my ($self, %options) = @_;
    $self->class ne __PACKAGE__
        or throw Mail::SPF::EAbstractClass;
    return $self->SUPER::new(%options);
}

=pod

The following additional class method is provided by B<Mail::SPF::GlobalMod>:

=over

=item B<precedence>: returns I<real>

I<Abstract>.  Returns a I<real> number between B<0> and B<1> denoting the
precedence of the type of the global modifier.  Global modifiers present in an
SPF record are processed in the order of their precedence values, B<0> meaning
"first".

This method is abstract and must be implemented by sub-classes of
Mail::SPF::GlobalMod.

=back

The following specific instance method is provided by B<Mail::SPF::GlobalMod>:

=over

=item B<process($server, $request, $result)>: throws I<Mail::SPF::Result>

I<Abstract>.  Processes the modifier.  What that means depends on the actual
implementation in sub-classes.  Takes both a I<Mail::SPF::Server> and a
I<Mail::SPF::Request> object.  As global modifiers are generally processed
I<after> an SPF result has already been determined, takes also the current
I<Mail::SPF::Result>.  If the modifier wishes to modify the SPF result, it may
throw a different I<Mail::SPF::Result> object.

This method is abstract and must be implemented by sub-classes of
Mail::SPF::GlobalMod.

=back

=head2 Positional modifiers - B<Mail::SPF::PositionalMod>

B<Sender ID> (RFC 4406) introduces the concept of "positional" modifiers.
According to RFC 4406, a positional modifier must follow a mechanism and
applies to that, and only that, mechanism.  However, because this definition is
not very useful, and because no positional modifiers have been defined based on
it as of yet, B<Mail::SPF> deviates from RFC 4406 as follows:

A positional modifier may appear anywhere in an SPF record, and it is stateful,
i.e. it applies to all mechanisms and modifiers that follow it.  Positional
modifiers are generally multiple, i.e. they may appear any number of times
throughout the record.  During evaluation of the record, positional modifiers
are processed at exactly the time when they are encountered by the evaluator.
Consequently, all positional modifiers are processed before an SPF result is
determined.

=cut

package Mail::SPF::PositionalMod;
our @ISA = 'Mail::SPF::Mod';

sub new {
    my ($self, %options) = @_;
    $self->class ne __PACKAGE__
        or throw Mail::SPF::EAbstractClass;
    return $self->SUPER::new(%options);
}

=pod

The following specific instance method is provided by
B<Mail::SPF::PositionalMod>:

=over

=item B<process($server, $request)>: throws I<Mail::SPF::Result::Error>, I<Mail::SPF::Exception>

I<Abstract>.  Processes the modifier.  What that means depends on the actual
implementation in sub-classes.  Takes both a I<Mail::SPF::Server> and a
I<Mail::SPF::Request> object.  As global modifiers are generally processed
I<before> an SPF result has been determined, no result object is available to
the modifier.  The modifier can (at least at this time) not directly modify the
final SPF result, however it may throw an exception to signal an error
condition.

This method is abstract and must be implemented by sub-classes of
Mail::SPF::PositionalMod.

=back

=head2 Unknown modifiers - B<Mail::SPF::UnknownMod>

Both B<SPFv1> and B<Sender ID> allow unknown modifiers to appear in SPF records
in order to allow new modifiers to be introduced without breaking existing
implementations.  Obviously, unknown modifiers are neither global nor
positional, but they may appear any number of times throughout the record and
are simply ignored during evaluation of the record.

=cut

package Mail::SPF::UnknownMod;
our @ISA = 'Mail::SPF::Mod';

=pod

Also obviously, B<Mail::SPF::UnknownMod> does not support a C<process> method.

The following specific instance method is provided by
B<Mail::SPF::UnknownMod>:

=over

=item B<params>: returns I<string>

Returns the modifier's unparsed value as a string.

=cut

sub params {
    my ($self) = @_;
    return $self->{params_text};
}

=back

=cut

package Mail::SPF::Mod;

=head1 OVERLOADING

If a Mail::SPF::Mod object is used as a I<string>, the C<stringify> method is
used to convert the object into a string.

=head1 SEE ALSO

L<Mail::SPF::Mod::Redirect>, L<Mail::SPF::Mod::Exp>

L<Mail::SPF>, L<Mail::SPF::Record>, L<Mail::SPF::Term>

L<http://tools.ietf.org/html/rfc4408>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>, Shevek <cpan@anarres.org>

=cut

TRUE;
