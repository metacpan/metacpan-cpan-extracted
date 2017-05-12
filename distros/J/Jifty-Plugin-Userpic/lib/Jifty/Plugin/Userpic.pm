use strict;
use warnings;

package Jifty::Plugin::Userpic;
use base qw/Jifty::Plugin Class::Accessor::Fast/;

our $VERSION = '0.9';

=head1 NAME

Jifty::Plugin::Userpic - Provides user pictures for Jifty

=head1 SYNOPSIS

In your model class schema description, add the following:

    column image => is Userpic;

=head1 DESCRIPTION

This plugin provides user pictures, or any image field associated with
a record.

=cut

use Jifty::DBI::Schema;

sub _userpic {
    my ($column, $from) = @_;
    my $name = $column->name;
    $column->type('blob');
}

use Jifty::DBI::Schema;

Jifty::DBI::Schema->register_types(
    Userpic =>
        sub { _init_handler is \&_userpic,  render_as 'Jifty::Plugin::Userpic::Widget'},
);

=head1 AUTHOR

Alex Vandiver

=head1 LICENSE

Copyright 2005-2009 Best Practical Solutions, LLC.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
