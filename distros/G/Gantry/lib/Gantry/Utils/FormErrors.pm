package Gantry::Utils::FormErrors;
use strict;

sub new {
    my ( $class, $opts ) = @_;

    my $self = {
        missing => $opts->{ missing } || {},
        invalid => $opts->{ invalid } || {},
    };

    return bless $self, $class;
}

sub has_missing {
    my $self = shift;

    return 1 if ( $self->missing );

    return;
}

sub has_invalid {
    my $self = shift;

    return 1 if ( $self->invalid );

    return;
}

sub missing {
    my $self      = shift;
    my $candidate = shift;

    if ( $candidate ) { return $self->{ missing }{ $candidate }; }
    else              { return keys %{ $self->{ missing } };     }
}

sub invalid {
    my $self      = shift;
    my $candidate = shift;

    if ( $candidate ) { return $self->{ invalid }{ $candidate }; }
    else              { return keys %{ $self->{ invalid } };     }
}

sub get_missing_hash {
    my $self = shift;

    return $self->{ missing };
}

sub get_invalid_hash {
    my $self = shift;

    return $self->{ invalid };
}

1;

=head1 NAME

Gantry::Utils::FormErrors - A CRUD form validation error object

=head1 SYNOPSIS

A typical example:

    use Gantry::Plugins::CRUD;
    use Gantry::Utils::FormErrors;

    my $crud_obj = Gantry::Plugins::CRUD->new(
        #...
        validator => \&my_validator,
    );

    sub my_validator {
        my $opts   = shift;
        my $params = $opts->{ params };
        my $form   = $opts->{ form   };

        my %missing;
        my @errors;

        if ( not $params->{ password } ) {
            $missing{ password }++;
        }
        if ( $params->{ password } =~ /$params->{ user_name }/ ) {
            push @errors, 'Password cannot contain user name';
        }
        # ... other similar tests

        my $error_text = join "\n<br /><b>Error:</b> ", @errors;

        $form->{ error_text } = $error_text;

        return Gantry::Utils::FormErrors->new(
            {
                missing    => \%missing,
            }
        );
    }

The rest is handled by the CRUD plugin and the default template (form.tt).

=head1 DESCRIPTION

This module provides objects which respond to the same API as
Data::FormValidator::Results (or at least the parts of that API which
Gantry normally uses).

Use this module in your Gantry::Plugins::CRUD validator callback.

=head1 METHODS

=over 4

=item new

Constructor, expects a hash reference with the following keys (all are
optional):

    missing    - a hash reference keyed by missing field names
    invalid    - a hash reference keyed by invalid field names

=item has_missing

Returns 1 if there are any keys in the missing hash.

=item has_invalid

Same as has_missing, except that it checks the invalid hash.

=item missing

If called without arguments, returns number of missing fields.  If
call with the name of a field, returns 1 if that field is a key in the
missing hash and 0 otherwise.

=item invalid

Same as missing, but checks the invalid hash.

=item get_missing_hash

Returns the hash reference of missing fields.  Keys are field names values
are usually 1 (but they must be true).

This is useful if two validation routines are cooperating to form the
final lists.

=item get_invalid_hash

Returns the hash reference of invalid fields.  Keys are field names values
are usually 1 (but they must be true).

This is useful if two validation routines are cooperating to form the
final lists.

=back

=head1 AUTHOR

Phil Crow, E<lt>philcrow2000@yayoo.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
