use strict;
package Env::Heroku;
our $AUTHORITY = 'cpan:PNU';
# ABSTRACT: set Heroku add-on specific environment variables

our $VERSION = '0.003'; # VERSION

__END__

=pod

=encoding UTF-8

=head1 NAME

Env::Heroku - set Heroku add-on specific environment variables

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    ## app.psgi
    use Env::Heroku::Pg;
    use Env::Heroku::Redis;

    ## catalyst app config
    'Model::DB' => {
        schema_class => 'WebApp::Schema',
        connect_info => [
            'dbi:Pg:',
            undef, undef, {
                pg_enable_utf8 => 1,
                auto_savepoint => 1,
            }
        ],
    }

=head1 DESCRIPTION

Set Heroku add-on specific environment variables from Heroku
config environment variables to the respective default variables.

For example C<Env::Heroku::Pg> will unpack the DATABASE_URL env
C<postgres://user:password@hostname:port/database> to env variables
PGUSER, PGPASSWORD, PGHOST, PGPORT and PGDATABASE and respective DBI_*
variables.

This allows site configuration to NOT specify database connection info
in configuration files that are under version control, but use the Heroku
env/config pattern to manage such attached resources.

=head1 SEE ALSO

L<http://12factor.net/>

=head1 AUTHOR

Panu Ervamaa <pnu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Panu Ervamaa.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
