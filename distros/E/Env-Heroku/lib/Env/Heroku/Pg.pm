use strict;
package Env::Heroku::Pg;
our $AUTHORITY = 'cpan:PNU';
# ABSTRACT: env for heroku-postgresql

use warnings;
use URI;

our $VERSION = '0.003'; # VERSION

sub import {
    my ($self) = @_;

    my $dburl = $ENV{DATABASE_URL};
    if ( $dburl and $dburl =~ s/^postgres:// ) {
        my $pgurl = URI->new( $dburl, 'http' );
        $ENV{PGHOST} = $pgurl->host;
        $ENV{PGPORT} = $pgurl->port;
        $ENV{PGDATABASE} = substr $pgurl->path, 1;
        ($ENV{PGUSER},$ENV{PGPASSWORD}) = split ':', $pgurl->userinfo;

        $ENV{DBI_DRIVER} = 'Pg';
        $ENV{DBI_DSN}    = 'dbi:Pg:'.$ENV{PGDATABASE}.'@'.$ENV{PGHOST}.':'.$ENV{PGPORT};
        $ENV{DBI_USER}   = $ENV{PGUSER};
        $ENV{DBI_PASS}   = $ENV{PGPASSWORD};
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Env::Heroku::Pg - env for heroku-postgresql

=head1 VERSION

version 0.003

=head1 AUTHOR

Panu Ervamaa <pnu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Panu Ervamaa.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
