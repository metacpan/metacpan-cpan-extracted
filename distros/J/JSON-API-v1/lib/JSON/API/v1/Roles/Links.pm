package JSON::API::v1::Roles::Links;
our $VERSION = '0.002';
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: An role that implements the default links object

has links => (
    is        => 'ro',
    isa       => 'JSON::API::v1::Links',
    predicate => 'has_links',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::API::v1::Roles::Links - An role that implements the default links object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head1 DESCRIPTION

This role makes sure that you never have to implement a links attributes.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
