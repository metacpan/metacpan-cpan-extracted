#
# Mail::SPF::Record
# Abstract base class for SPF records.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: Record.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::Record;

=head1 NAME

Mail::SPF::Record - Abstract base class for SPF records

=cut

use warnings;
use strict;

use utf8;  # Hack to keep Perl 5.6 from whining about /[\p{}]/.

use base 'Mail::SPF::Base';

use overload
    '""'        => 'stringify',
    fallback    => 1;

use Error ':try';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant default_qualifier      => '+';

use constant results_by_qualifier   => {
    ''  => 'pass',
    '+' => 'pass',
    '-' => 'fail',
    '~' => 'softfail',
    '?' => 'neutral'
};

# Interface:
##############################################################################

=head1 SYNOPSIS

=head2 Creating a record from a string

    use Mail::SPF::v1::Record;

    my $record = Mail::SPF::v1::Record->new_from_string("v=spf1 a mx -all");

=head2 Creating a record synthetically

    use Mail::SPF::v2::Record;

    my $record = Mail::SPF::v2::Record->new(
        scopes      => ['mfrom', 'pra'],
        terms       => [
            Mail::SPF::Mech::A->new(),
            Mail::SPF::Mech::MX->new(),
            Mail::SPF::Mech::All->new(qualifier => '-')
        ],
        global_mods => [
            Mail::SPF::Mod::Exp->new(domain_spec => 'spf-exp.example.com')
        ]
    );

=cut

# Implementation:
##############################################################################

=head1 DESCRIPTION

B<Mail::SPF::Record> is an abstract base class for SPF records.  It cannot be
instantiated directly.  Create an instance of a concrete sub-class instead.

=head2 Constructor

The following constructors are provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Record>

Creates a new SPF record object.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<text>

A I<string> denoting the unparsed text of the record.

=item B<scopes>

A reference to an I<array> of I<string>s denoting the scopes that are covered
by the record (see the description of the C<scope> option of
L<Mail::SPF::Request's C<new> constructor|Mail::SPF::Request/new>).

=item B<terms>

A reference to an I<array> of I<Mail::SPF::Term> (i.e. I<Mail::SPF::Mech> or
I<Mail::SPF::Mod>) objects that make up the record.  I<Mail::SPF::GlobalMod>
objects must not be included here, but should be specified using the
C<global_mods> option instead.

=item B<global_mods>

A reference to an I<array> of I<Mail::SPF::GlobalMod> objects that are global
modifiers of the record.

=back

=cut

sub new {
    my ($self, %options) = @_;
    $self->class ne __PACKAGE__
        or throw Mail::SPF::EAbstractClass;
    $self = $self->SUPER::new(%options);
    $self->{parse_text} = $self->{text} if not defined($self->{parse_text});
    $self->{terms}       ||= [];
    $self->{global_mods} ||= {};
    return $self;
}

=item B<new_from_string($text, %options)>: returns I<Mail::SPF::Record>;
throws I<Mail::SPF::ENothingToParse>, I<Mail::SPF::EInvalidRecordVersion>,
I<Mail::SPF::ESyntaxError>

Creates a new SPF record object by parsing the string and any options given.

=cut

sub new_from_string {
    my ($self, $text, %options) = @_;
    $self = $self->new(%options, text => $text);
    $self->parse();
    return $self;
}

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<version_tag_pattern>: returns I<Regexp>

I<Abstract>.  Returns a regular expression that matches a legal version tag.

This method is abstract and must be implemented by sub-classes of
Mail::SPF::Record.

=item B<default_qualifier>: returns I<string>

Returns the default qualifier, i.e. B<'+'>.

=item B<results_by_qualifier>: returns I<hash> of I<string>

Returns a reference to a hash that maps qualifiers to result codes as follows:

     Qualifier | Result code
    -----------+-------------
         +     | pass
         -     | fail
         ~     | softfail
         ?     | neutral

=back

=head2 Instance methods

The following instance methods are provided:

=over

=cut

sub parse {
    my ($self) = @_;
    defined($self->{parse_text})
        or throw Mail::SPF::ENothingToParse('Nothing to parse for record');
    $self->parse_version_tag();
    $self->parse_term() while length($self->{parse_text});
    $self->parse_end();
    return;
}

sub parse_version_tag {
    my ($self) = @_;
    if (not $self->{parse_text} =~ s/^${\$self->version_tag_pattern}(?:\x20+|$)//) {
        throw Mail::SPF::EInvalidRecordVersion(
            "Not a '" . $self->version_tag . "' record: '" . $self->text . "'");
    }
}

sub parse_term {
    my ($self) = @_;
    if (
        $self->{parse_text} =~ s/
            ^
            (
                ${\Mail::SPF::Mech->qualifier_pattern}?
               (${\Mail::SPF::Mech->name_pattern})
                [^\x20]*
            )
            (?: \x20+ | $ )
        //x
    ) {
        # Looks like a mechanism:
        my ($mech_text, $mech_name) = ($1, lc($2));
        my $mech_class = $self->mech_classes->{$mech_name};
        throw Mail::SPF::EInvalidMech("Unknown mechanism type '$mech_name' in '" . $self->version_tag . "' record")
            if not defined($mech_class);
        my $mech = $mech_class->new_from_string($mech_text);
        push(@{$self->{terms}}, $mech);
    }
    elsif (
        $self->{parse_text} =~ s/
            ^
            (
               (${\Mail::SPF::Mod->name_pattern}) =
                [^\x20]*
            ) 
            (?: \x20+ | $ )
        //x
    ) {
        # Looks like a modifier:
        my ($mod_text, $mod_name) = ($1, lc($2));
        my $mod_class = $self->mod_classes->{$mod_name};
        if (defined($mod_class)) {
            # Known modifier.
            my $mod = $mod_class->new_from_string($mod_text);
            if ($mod->isa('Mail::SPF::GlobalMod')) {
                # Global modifier.
                not defined($self->{global_mods}->{$mod_name}) or
                    throw Mail::SPF::EDuplicateGlobalMod("Duplicate global modifier '$mod_name' encountered");
                $self->{global_mods}->{$mod_name} = $mod;
            }
            elsif ($mod->isa('Mail::SPF::PositionalMod')) {
                # Positional modifier, queue normally:
                push(@{$self->{terms}}, $mod);
            }
            else {
                # Huh?  This should not happen.
            }
        }
        else {
            # Unknown modifier.
            my $mod = Mail::SPF::UnknownMod->new_from_string($mod_text);
            push(@{$self->{terms}}, $mod);
        }
    }
    else {
        throw Mail::SPF::EJunkInRecord("Junk encountered in record '" . $self->text . "'");
    }
    return;
}

sub parse_end {
    my ($self) = @_;
    throw Mail::SPF::EJunkInRecord("Junk encountered in record '" . $self->text . "'")
        if $self->{parse_text} ne '';
    delete($self->{parse_text});
    return;
}

=item B<text>: returns I<string>; throws I<Mail::SPF::ENoUnparsedText>

Returns the unparsed text of the record.  Throws a I<Mail::SPF::ENoUnparsedText>
exception if the record was created synthetically instead of being parsed, and
no text was provided.

=cut

sub text {
    my ($self) = @_;
    defined($self->{text})
        or throw Mail::SPF::ENoUnparsedText;
    return $self->{text};
}

=item B<version_tag>: returns I<string>

I<Abstract>.  Returns the version tag of the record.

This method is abstract and must be implemented by sub-classes of
Mail::SPF::Record.

=item B<scopes>: returns I<list> of I<string>

Returns a list of the scopes that are covered by the record.  See the
description of the L</new> constructor's C<scopes> option.

=cut

sub scopes {
    my ($self) = @_;
    return @{$self->{scopes}};
}

=item B<terms>: returns I<list> of I<Mail::SPF::Term>

Returns a list of the terms that make up the record, excluding any global
modifiers, which are returned by the C<global_mods> method.  See the
description of the L</new> constructor's C<terms> option.

=cut

sub terms {
    my ($self) = @_;
    return @{$self->{terms}};
}

=item B<global_mods>: returns I<list> of I<Mail::SPF::GlobalMod>

Returns a list of the global modifiers of the record, ordered ascending by
modifier precedence.  See the description of the L</new> constructor's
C<global_mods> option.

=cut

sub global_mods {
    my ($self) = @_;
    return sort { $a->precedence <=> $b->precedence } values(%{$self->{global_mods}});
}

=item B<global_mod($mod_name)>: returns I<Mail::SPF::GlobalMod>

Returns the global modifier of the given name if it is present in the record.
Returns B<undef> otherwise.  Use this method if you wish to retrieve a specific
global modifier as opposed to getting all of them.

=cut

sub global_mod {
    my ($self, $mod_name) = @_;
    return $self->{global_mods}->{$mod_name};
}

=item B<stringify>: returns I<string>

Returns the record's version tag and terms (including the global modifiers)
formatted as a string.  You can simply use a Mail::SPF::Record object as a
string for the same effect, see L<"OVERLOADING">.

=cut

sub stringify {
    my ($self) = @_;
    return join(' ', $self->version_tag, $self->terms, $self->global_mods);
}

=item B<eval($server, $request)>: throws I<Mail::SPF::Result>

Evaluates the SPF record in the context of the request parameters represented
by the given I<Mail::SPF::Request> object.  The given I<Mail::SPF::Server>
object is used for performing DNS look-ups.  Throws a I<Mail::SPF::Result>
object matching the outcome of the evaluation; see L<Mail::SPF::Result>.  See
RFC 4408, 4.6 and 4.7, for the exact algorithm used.

=cut

sub eval {
    my ($self, $server, $request) = @_;

    defined($server)
        or throw Mail::SPF::EOptionRequired('Mail::SPF server object required for record evaluation');
    defined($request)
        or throw Mail::SPF::EOptionRequired('Request object required for record evaluation');

    try {
        foreach my $term ($self->terms) {
            if ($term->isa('Mail::SPF::Mech')) {
                # Term is a mechanism.
                my $mech = $term;
                if ($mech->match($server, $request)) {
                    my $result_name  = $self->results_by_qualifier->{$mech->qualifier};
                    my $result_class = $server->result_class($result_name);
                    my $result = $result_class->new($server, $request, "Mechanism '$term' matched");
                    $mech->explain($server, $request, $result);
                    $result->throw();
                }
            }
            elsif ($term->isa('Mail::SPF::PositionalMod')) {
                # Term is a positional modifier.
                my $mod = $term;
                $mod->process($server, $request);
            }
            elsif ($term->isa('Mail::SPF::UnknownMod')) {
                # Term is an unknown modifier.  Ignore it (RFC 4408, 6/3).
            }
            else {
                # Invalid term object encountered:
                throw Mail::SPF::EUnexpectedTermObject(
                    "Unexpected term object '$term' encountered");
            }
        }

        # Default result when "falling off" the end of the record (RFC 4408, 4.7/1):
        $server->throw_result('neutral-by-default', $request,
            'Default neutral result due to no mechanism matches');
    }
    catch Mail::SPF::Result with {
        my ($result) = @_;

        # Process global modifiers in ascending order of precedence:
        foreach my $global_mod ($self->global_mods) {
            $global_mod->process($server, $request, $result);
        }

        $result->throw();
    };
}

=back

=head1 OVERLOADING

If a Mail::SPF::Record object is used as a I<string>, the C<stringify> method
is used to convert the object into a string.

=head1 SEE ALSO

L<Mail::SPF>, L<Mail::SPF::v1::Record>, L<Mail::SPF::v2::Record>,
L<Mail::SPF::Term>, L<Mail::SPF::Mech>, L<Mail::SPF::Mod>

L<http://tools.ietf.org/html/rfc4408>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>, Shevek <cpan@anarres.org>

=cut

TRUE;
