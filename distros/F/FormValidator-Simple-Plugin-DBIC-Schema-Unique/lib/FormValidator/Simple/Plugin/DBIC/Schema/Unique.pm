package FormValidator::Simple::Plugin::DBIC::Schema::Unique;
use strict;
use warnings;
use Scalar::Util qw(blessed);
use FormValidator::Simple::Exception;
use FormValidator::Simple::Constants;

our $VERSION = '0.02';

sub DBIC_SCHEMA_UNIQUE {
    my ($class, $params, $args) = @_;

    unless ( scalar(@$args) >= 2 ) {
        FormValidator::Simple::Exception->throw(
            qq/Validation DBIC_SCHEMA_UNIQUE needs two arguments at least. /
        );
    }
    my $rs = pop @$args;
    if ( !blessed($rs) || !$rs->isa('DBIx::Class::ResultSet') ) {
        FormValidator::Simple::Exception->throw(
            qq/Validation DBIC_SCHEMA_UNIQUE: Last parameter need DBIx::Class::ResultSet's object./
        );
    }
    unless ( scalar(@$params) == scalar(@$args) ) {
        FormValidator::Simple::Exception->throw(
            qq/Validation DBIC_SCHEMA_UNIQUE: number of keys and validation arguments aren't same/
        );
    }

    my %criteria = ();
    for ( my $i = 0; $i < scalar(@$args); $i++ ) {
        my $key   = $args->[$i];
        my $value = $params->[$i];
        if ( $key =~ /^!(.+)$/ ) {
            $criteria{$1} = { '!=' => $value };
        }
        else {
            $criteria{$key} = $value || '';
        }
    }
    my $count = $rs->count(\%criteria);
    return $count > 0 ? FALSE : TRUE;
}

1;

=head1 NAME

FormValidator::Simple::Plugin::DBIC::Schema::Unique - unique check for DBIC::Schema

=head1 SYNOPSIS

    use FormValidator::Simple qw/DBIC::Schema::Unique/;

    # check single column
    FormValidator::Simple->check( $q => [
        name => [ [qw/DBIC_SCHEMA_UNIQUE name/, $schema->result_set('User')] ],
    ] );

=head1 DESCRIPTION

This module is a plugin for FormValidator::Simple. This provides you a validation for unique check with DBIC table class.

=head1 SEE ALSO

L<FormValidator::Simple>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Atsushi Kobayashi  C<< <atsushi __at__ mobilefactory.jp> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Atsushi Kobayashi C<< <atsushi __at__ mobilefactory.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

