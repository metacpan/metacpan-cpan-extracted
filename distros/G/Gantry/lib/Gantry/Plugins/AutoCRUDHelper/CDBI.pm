package Gantry::Plugins::AutoCRUDHelper::CDBI;
use strict;

sub insert {
    my $class       = shift;
    my $gantry_site = shift;
    my $params      = shift;
    my $new_row     = $gantry_site->get_model_name->create( $params );

    $new_row->dbi_commit();

    return $new_row;
}

sub retrieve {
    my $class       = shift;
    my $gantry_site = shift;
    my $id          = shift;

    return $gantry_site->get_model_name()->retrieve( $id );
}

sub update {
    my $class       = shift;
    my $gantry_site = shift;
    my $row         = shift;
    my $params      = shift;

    $row->set( %{ $params } );
    $row->update;
    $row->dbi_commit;   # XXX check autocommit flag
}

sub delete {
    my $class       = shift;
    my $gantry_site = shift;
    my $row         = shift;

    $row->delete;
    $gantry_site->get_model_name()->dbi_commit();
}

1;

=head1 NAME

Gantry::Plugins::AutoCRUDHelper::CDBI - the actual CRUD for CDBI AutoCRUD

=head1 SYNOPSIS

This module is used for you by Gantry::Plugins::AutoCRUD.  It is in fact the
default helper.  It supports Class::DBI models which inherit from
Gantry::Utils::CDBI.

=head1 DESCRIPTION

Inside Gantry::Plugins::AutoCRUD, whenever actual database work needs to be
done, your model is asked to supply a helper by calling its get_orm_helper
method.  If that method returns 'Gantry::Plugins::AutoCRUDHelper::CDBI'
or that method is missing, this module is used to do database work.

=head1 METHODS

The methods of this module are documented in Gantry::Plugins::AutoCRUD, but
here is a list for completeness (and to keep POD testers happy):

=over 4

=item insert

=item retrieve

=item update

=item delete

=back

=head1 SEE ALSO

    Gantry::Plugins::AutoCRUDHelper
    Gantry::Plugins::AutoCRUDHelper::DBIxClass

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
