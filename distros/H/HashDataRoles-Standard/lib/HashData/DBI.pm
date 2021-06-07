package HashData::DBI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-21'; # DATE
our $DIST = 'HashDataRoles-Standard'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Role::Tiny::With;
with 'HashDataRole::Source::DBI';

1;
# ABSTRACT: Get hash data from DBI

__END__

=pod

=encoding UTF-8

=head1 NAME

HashData::DBI - Get hash data from DBI

=head1 VERSION

This document describes version 0.001 of HashData::DBI (from Perl distribution HashDataRoles-Standard), released on 2021-05-21.

=head1 SYNOPSIS

 use HashData::DBI;

 my $ary = HashData::DBI->new(
     iterate_sth    => $dbh->prepare("SELECT mykey,myval FROM mytable"),
     get_by_key_sth => $dbh->prepare("SELECT myval FROM mytable WHERE mykey=?"),
     row_count_sth  => $dbh->prepare("SELECT COUNT(*) FROM mytable"),
 );

 # or
 my $ary = HashData::DBI->new(
     dsn           => "DBI:mysql:database=mydb",
     user          => "...",
     password      => "...",
     table         => "mytable",
     key_column    => "mykey",
     val_column    => "myval",
 );

=head1 DESCRIPTION

This is an C<HashData::> module to get array elements from a L<DBI> query.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HashDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HashDataRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-HashDataRoles-Standard/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DBI>

L<ArrayData>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
