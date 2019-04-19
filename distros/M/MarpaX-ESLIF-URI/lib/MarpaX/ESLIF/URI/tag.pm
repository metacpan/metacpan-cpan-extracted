use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::URI::tag;

# ABSTRACT: URI::tag syntax as per RFC4151

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '0.007'; # VERSION

use Class::Tiny::Antlers;
use MarpaX::ESLIF;
use DateTime;

extends 'MarpaX::ESLIF::URI::mailto'; # inherit <addr spec> semantic

has '_entity'    => (is => 'rwp');
has '_authority' => (is => 'rwp');
has '_date'      => (is => 'rwp');
has '_year'      => (is => 'rwp');
has '_month'     => (is => 'rwp');
has '_day'       => (is => 'rwp');
has '_dnsname'   => (is => 'rwp');
has '_email'     => (is => 'rwp');

#
# All attributes starting with an underscore are the result of parsing
#
__PACKAGE__->_generate_actions(qw/_entity _authority _date _year _month _day _dnsname _email/);

#
# Constants
#
my $BNF = do { local $/; <DATA> };
my $GRAMMAR = MarpaX::ESLIF::Grammar->new(__PACKAGE__->eslif, __PACKAGE__->bnf);


sub bnf {
  my ($class) = @_;

  join("\n", $BNF, MarpaX::ESLIF::URI::mailto->bnf) # We merge with mailto: BNF to get the <addr spec> syntax from it
};


sub grammar {
  my ($class) = @_;

  return $GRAMMAR;
}


sub entity {
    my ($self, $type) = @_;

    return $self->_generic_getter('_entity', $type)
}


sub authority {
    my ($self, $type) = @_;

    return $self->_generic_getter('_authority', $type)
}


sub date {
    my ($self, $type) = @_;

    my $year  = $self->_generic_getter('_year',  $type); # Only year is required
    return unless defined($year);                        # Indeed, there is no date
    my $month = $self->_generic_getter('_month', $type) // '01';
    my $day   = $self->_generic_getter('_day',   $type) // '01';

    return DateTime->new(year => $year, month => $month, day => $day, time_zone => 'UTC')
}


sub year {
    my ($self, $type) = @_;

    return $self->_generic_getter('_year', $type)
}


sub month {
    my ($self, $type) = @_;

    return $self->_generic_getter('_month', $type)
}


sub day {
    my ($self, $type) = @_;

    return $self->_generic_getter('_day', $type)
}


sub dnsname {
    my ($self, $type) = @_;

    return $self->_generic_getter('_dnsname', $type)
}


sub email {
    my ($self, $type) = @_;

    return $self->_generic_getter('_email', $type)
}

# -------------
# Normalization
# -------------


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::URI::tag - URI::tag syntax as per RFC4151

=head1 VERSION

version 0.007

=head1 SUBROUTINES/METHODS

MarpaX::ESLIF::URI::tag inherits, and eventually overwrites some, methods of MarpaX::ESLIF::URI::_generic.

=head2 $class->bnf

Overwrites parent's bnf implementation. Returns the BNF used to parse the input.

=head2 $class->grammar

Overwrite parent's grammar implementation. Returns the compiled BNF used to parse the input as MarpaX::ESLIF::Grammar singleton.

=head2 $self->entity($type)

Returns the tag entity. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->authority($type)

Returns the tag authority. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->date($type)

Returns the tag date as a L<DateTime> object. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

Note that date in a tag URI is always expressed using UTC timezone.

=head2 $self->year($type)

Returns the tag date's year. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->month($type)

Returns the tag date's month. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->day($type)

Returns the tag date's day. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->dnsname($type)

Returns the tag's DNS name when entity is made from it. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

As per RFC4151: "It is RECOMMENDED that the domain name should be in lowercase form. Alternative formulations of the same authority name will be counted as distinct".

=head2 $self->email($type)

Returns the tag email when entity is made from it. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head1 NOTES

Errata L<1485|https://www.rfc-editor.org/errata/eid1485> has been applied.

=head1 SEE ALSO

L<RFC4151|https://tools.ietf.org/html/rfc4151>, L<MarpaX::ESLIF::URI::_generic>, L<DateTime>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
#
# Reference: https://tools.ietf.org/html/rfc4151#section-2.1
#
<tag URI>                 ::= <tag scheme> ":" <tag entity> ":" <tag specific> <tag fragment> action => _action_string

<tag scheme>              ::= "tag":i                                                         action => _action_scheme

<tag entity>              ::= <tag authority> "," <tag date>                                  action => _action_entity
<tag authority>           ::= DNSname                                                         action => _action_authority
                            | emailAddress                                                    action => _action_authority
<tag date>                ::= year                                                            action => _action_date
                            | year "-" month                                                  action => _action_date
                            | year "-" month "-" day                                          action => _action_date
year                      ::= DIGIT DIGIT DIGIT DIGIT                                         action => _action_year
month                     ::= DIGIT DIGIT                                                     action => _action_month
day                       ::= DIGIT DIGIT                                                     action => _action_day
DNSname                   ::= DNScomp+ separator => "."                                       action => _action_dnsname
DNScomp                   ::= alphaNum
                            | alphaNum DNSCompInner alphaNum
DNSCompInnerUnit          ::= alphaNum
                            | "-"
DNSCompInner              ::= DNSCompInnerUnit*
emailAddress              ::= <addr spec>                                                     action => _action_email
alphaNum                  ::= DIGIT
                            | ALPHA
<tag specific>            ::= <hier part> <URI query>
<tag fragment>            ::= <URI fragment>

#
# mailto syntax, so <addr spec> and further the generic syntax as well, will be appended here
#
