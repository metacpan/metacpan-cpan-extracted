package MVC::Neaf::X::Form;

use strict;
use warnings;
our $VERSION = 0.2501;

=head1 NAME

MVC::Neaf::X::Form - Form validator for Not Even A Framework

=head1 CAUTION

This module should be moved into a separate distribution or (ideally)
merged with an existing module with similar functionality.

Possible candidates include L<Validator::LIVR>, L<Data::FormValidator>,
L<Data::CGIForm>, and more.

=head1 DESCRIPTION

Ths module provides hashref validation mechanism that allows for
showing per-value errors,
post-validation user-defined checks,
and returning the original content for resubmission.

=head1 SINOPSYS

    use MVC::Neaf::X::Form;

    # At the start of the application
    my $validator = MVC::Neaf::X::Form->new( \%profile );

    # Much later, multiple times
    my $form = $validator->validate( \%user_input );

    if ($form->is_valid) {
        do_intended_stuff( $form->data ); # a hashref
    } else {
        display_errors( $form->error ); # a hashref
        show_form_for_resubmission( $form->raw ); # also a hashref
    };

As you can see, nothing here has anything to do with http or html,
it just so happens that the above pattern is common in web applications.

=head1 METHODS

=cut

use parent qw(MVC::Neaf::X);
use MVC::Neaf::X::Form::Data;

=head2 new( \%profile )

Receives a validation profile, returns a validator object.

In the default implementation,
%profile must be a hash with keys corresponding to the data being validated,
and values in the form of either regexp, [ regexp ], or [ required => regexp ].

Regular expressions are accepted in qr(...) and string format, and will be
compiled to only match the whole line.

B<NOTE> One may need to pass qr(...)s in order to allow multiline data
(e.g. in textarea).

B<NOTE> Format may be subject to extention with extra options.

=cut

sub new {
    # TODO 0.90 other constructor forms e.g. with options
    my ($class, $profile) = @_;

    my $self = bless {
        known_keys => [ keys %$profile ],
    }, $class;

    $self->{rules} = $self->make_rules( $profile );
    return $self;
};

=head2 make_rules( \%profile )

Preprocesses the validation profile before doing actual validation.

Returns an object or reference to be stored in the C<rules> property.

This method is called from new() and is to be overridden in a subclass.

=cut

sub make_rules {
    my ($self, $profile) = @_;

    my %regexp;
    my %required;

    foreach (keys %$profile) {
        my $spec = $profile->{$_};
        if (ref $spec eq 'ARRAY') {
            if (@$spec == 1) {
                $regexp{$_} = _mkreg( $spec->[-1] );
            } elsif (@$spec == 2 and lc $spec->[0] eq 'required') {
                $regexp{$_} = _mkreg( $spec->[-1] );
                $required{$_}++;
            } else {
                $self->my_croak("Invalid validation profile for value $_");
            };
        } else {
            # plain or regexp
            $regexp{$_} = _mkreg( $spec );
        };
    };

    return { regexp => \%regexp, required => \%required };
};

sub _mkreg {
    my $str = shift;
    return qr/^$str$/;
};

=head2 validate( \%data )

Returns a MVC::Neaf::X::Form::Data object with methods:

=over

=item * is_valid - true if validation passed.

=item * data - data that passed validation as hash
(MAY be incomplete, must check is_valid() before usage).

=item * error - errors encountered.
May be extended if called with 2 args.
(E.g. failed to load an otherwise correct item from DB).
This also affects is_valid.

=item * raw - user params as is. Only the known keys end up in this hash.
Useful to send data back for resubmission.

=back

=cut

sub validate {
    my ($self, $data) = @_;

    my $raw;
    defined $data->{$_} and $raw->{$_} = $data->{$_}
        for $self->known_keys;

    my ($clean, $error) = $self->do_validate( $raw );

    return MVC::Neaf::X::Form::Data->new(
        raw => $raw, data=>$clean, error => $error,
    );
};

=head2 do_validate( $raw_data )

Returns a pair of hashes: the cleaned data and errors.

This is called by validate() and is to be overridden in subclasses.

=cut

sub do_validate {
    my ($self, $data) = @_;

    my $rex = $self->{rules}{regexp};
    my $must = $self->{rules}{required};
    my (%clean, %error);
    foreach ( $self->known_keys ) {
        if (!defined $data->{$_}) {
            $error{$_} = 'REQUIRED' if $must->{$_};
            next;
        };

        if ($data->{$_} =~ $rex->{$_}) {
            $clean{$_} = $data->{$_};
        } elsif (length $data->{$_} or $must->{$_}) {
            # Silently skip empty values if they don't match RE
            # so that /foo?bar= and /foo work the same
            # (unless EXPLICITLY told NOT to)
            $error{$_} = 'BAD_FORMAT';
        };
    };

    return (\%clean, \%error);
};

=head2 known_keys()

Returns list of data keys subject to validation.

All other keys present in the input SHOULD be ignored.

=cut

sub known_keys {
    my $self = shift;
    return @{ $self->{known_keys} };
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2018 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
