package KiokuDB::Role::UUIDs::SerialIDs;
BEGIN {
  $KiokuDB::Role::UUIDs::SerialIDs::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Role::UUIDs::SerialIDs::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Serial ID assignment based on a global counter.

use namespace::clean -except => 'meta';

my $i = "0001"; # so that the first 10k objects sort lexically
sub generate_uuid { $i++ }

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Role::UUIDs::SerialIDs - Serial ID assignment based on a global counter.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    # set before loading:

    BEGIN { $KiokuDB::SERIAL_IDS = 1 }

    use KiokuDB;

=head1 DESCRIPTION

This role provides an alternate, development only ID generation role.

The purpose of this role is to ease testing when the database is created from
scratch on each run. Objects will typically be assigned the same IDs between
runs, making things easier to follow.

Do B<NOT> use this role for storage of actual data, because ID clashes are
almost guaranteed to cause data loss.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
