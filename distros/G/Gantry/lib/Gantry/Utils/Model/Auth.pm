package Gantry::Utils::Model::Auth;
use strict; use warnings;

use base 'Gantry::Utils::Model';

use Gantry::Utils::ModelHelper qw(
    auth_db_Main
    get_form_selections
    retrieve_all_for_main_listing
);

1;

=head1 NAME

Gantry::Utils::Model::Auth - base class for auth database modelers

=head1 SYNOPSIS

    package Your::App::Name::Model::table_name;

    use base 'Gantry::Utils::Model::Auth';

=head1 DESCRIPTION

Use this as the parent class of your individual model module when
that model needs to use the auth database connection.  Follow
the instructions in Gantry::Utils::Model for what your subclass must
implement (and it is a lot, we usually generate the module with Bigtop).

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
