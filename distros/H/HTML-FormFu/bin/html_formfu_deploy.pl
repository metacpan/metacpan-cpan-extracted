#!/usr/bin/perl
use strict;
use warnings;

# PODNAME: html_formfu_deploy.pl
# ABSTRACT: deploy local copy of HTML::FormFu template files

use HTML::FormFu::Deploy;

warn <<'END';
You only need to create a local copy of the HTML::FormFu template files
if you intend on customising them.
Otherwise, HTML::FormFu should automatically locate the system-wide copy of
the files, installed in the perl @INC paths.

END

if ( @ARGV != 1 ) {
    die "ERROR: Target directory argument required\n";
}

HTML::FormFu::Deploy::deploy( $ARGV[0] );

__END__

=pod

=encoding UTF-8

=head1 NAME

html_formfu_deploy.pl - deploy local copy of HTML::FormFu template files

=head1 VERSION

version 2.07

=head1 SYNOPSIS

html_formfu_deploy.pl F<target-directory>

=head1 DESCRIPTION

The "html_formfu_deploy.pl" script creates a local copy of the HTML::FormFu
template files for customization in the directory F<target-directory>.

If no customization is needed, HTML::FormFu should use the system-wide
installation of the template files.

=head1 SEE ALSO

HTML::FormFu::Deploy

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
