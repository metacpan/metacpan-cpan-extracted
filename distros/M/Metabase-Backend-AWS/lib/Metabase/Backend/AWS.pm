use 5.006;
use strict;
use warnings;

package Metabase::Backend::AWS;
our $VERSION = '1.000'; # VERSION

use Moose::Role;
use namespace::autoclean;

has 'access_key_id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'secret_access_key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;

# ABSTRACT: Metabase backend implemented using Amazon Web Services
#
# This file is part of Metabase-Backend-AWS
#
# This software is Copyright (c) 2011 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#



__END__
=pod

=head1 NAME

Metabase::Backend::AWS - Metabase backend implemented using Amazon Web Services

=head1 VERSION

version 1.000

=head1 SYNOPSIS

XXX consolidate synopses from modules

=head1 DESCRIPTION

This distribution provides a backend for L<Metabase> using Amazon Web Services.
There are two modules included, L<Metabase::Index::SimpleDB> and
L<Metabase::Archive::S3>.  They can be used separately or together (see
L<Metabase::Librarian> for details).

The L<Metabase::Backend::AWX> module is a L<Moose::Role> that provides
common attributes and private helpers and is not intended to be used directly.

Common attributes are described further below.

=head1 ATTRIBUTES

=head2 access_key_id

An AWS Access Key ID

=head2 secret_access_key

An AWS Secret Access Key matching the Access Key ID

=for Pod::Coverage method_names_here

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Metabase-Backend-AWS>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/metabase-backend-aws>

  git clone https://github.com/dagolden/metabase-backend-aws.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

