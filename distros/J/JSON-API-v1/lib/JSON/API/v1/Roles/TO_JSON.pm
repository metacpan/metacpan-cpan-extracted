package JSON::API::v1::Roles::TO_JSON;
our $VERSION = '0.002';
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: An interface for Objects to adhere to

requires qw(
    TO_JSON
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::API::v1::Roles::TO_JSON - An interface for Objects to adhere to

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head1 DESCRIPTION

This role implements an interface to which consumers must adhere to. It defines
several methods that L<JSON::API::v1> namespaced objects must implement
to support the JSON API v1 specifications.

=head1 AUTHOR

Wesley Schwengle

=head1 LICENSE and COPYRIGHT

Wesley Schwengle, 2017.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
