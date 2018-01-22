package MVC::Neaf::X::Form::Wildcard;

use strict;
use warnings;
our $VERSION = 0.2202;

=head1 NAME

MVC::Neaf::X::Form::Wildcard - A special case form with unforeknown fields

=head1 SYNOPSIS

    use MVC::Neaf::X::Form::Wildcard;

    # once during application setup phase
    my $form = MVC::Neaf::X::Form::Wildcard->new(
        [ [ qr/name\d+/ => qr/...*/ ], ... ] );

    # much later, multiple times
    my $checked = $form->validate( {
        name1 => 'foo',
        surname2 => 'bar',
        name5 => 'o'
    } );

    $checked->fields;   # ( 'name1', 'name5' )
                        # ONLY the matched fields
    $checked->is_valid; # false
                        # because of next line
    $checked->error;    # { name5 => 'BAD_FORMAT' }

    $checked->data;     # { name1 => 'foo' }
                        # Data that passed validation
    $checked->raw;      # { name1 => 'foo', name5 => 'o' }
                        # Semi-good data to send back to user for amendment,
                        #     if needed

    # Note that surname2 did NOT affect anything at all.

=head1 DESCRIPTION

This module provides simple yet powerful validation method for plain hashes
in cases where the fields are not known beforehand.

The validation rules come as tuples. A tuple containes name validation regexp,
value validation regexp, and possibly other fields (not implemented yet).

All hash keys are filtered through name rules. In case of match, all other
rules are applied, resulting in either matching or non-matching field
that ends up in C<data> or C<error> hashes, respectively.

A field that doesn't match anything is let through.

=cut

use parent qw(MVC::Neaf::X::Form);
use MVC::Neaf::X::Form::Data;
use MVC::Neaf::Util qw(rex);

=head2 new ( \@rules )

Create a new validator from rules.

More options may follow in the future, but now there are none.

=cut

sub new {
    my ($class, $rules) = @_;

    $class->my_croak("Rule set must be arrayref")
        unless ref $rules eq 'ARRAY';

    my $self = bless {}, $class;
    foreach (@$rules) {
        $self->add_rule( $_ );
    };

    return $self;
};

=head2 add_rule( \@tuple )

=head2 add_rule( \%params )


=cut

sub add_rule {
    my ($self, $in) = @_;

    my $rule;
    if (ref $in eq 'ARRAY') {
        $rule = { re_name => $in->[0], re_value => $in->[1] };
    } else {
        # TODO 0.30 validate fields?
        $rule = { %$in };
    };

    $self->_croak( "re_name must be present in validation rule" )
        unless $rule->{re_name};
    $self->_croak( "re_value must be present in validation rule" )
        unless $rule->{re_value};

    $rule->{re_name}  = rex $rule->{re_name};
    $rule->{re_value} = rex $rule->{re_value};

    push @{ $self->{rules} }, $rule;

    return $self;
};

=head2 validate( \%user_input )

Returns a L<MVC::Neaf::X::Form::Data> object with keys of \%user_input,
filtered by the rules.

=cut

sub validate {
    my ($self, $input) = @_;

    my( %data, %error, %raw );
    KEY: foreach my $key (keys %$input) {
        RULE: foreach my $rule( @{ $self->{rules} } ) {
            $key =~ $rule->{re_name} or next RULE;

            $raw{$key} = $input->{$key};
            if ($raw{$key} =~ $rule->{re_value}) {
                $data{$key}  = $raw{$key};
            } else {
                $error{$key} = 'REGEX_NO_MATCH';
            };

            next KEY;
        };
    };

    return MVC::Neaf::X::Form::Data->new(
        data  => \%data,
        error => \%error,
        raw   => \%raw,
    );
};

=head1 LICENSE AND COPYRIGHT

This module is part of the L<MVC::Neaf> suite.

Copyright 2017 Konstantin S. Uvarin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
