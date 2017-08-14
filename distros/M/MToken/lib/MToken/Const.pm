package MToken::Const; # $Id: Const.pm 43 2017-07-31 13:04:58Z minus $
use strict;

=head1 NAME

MToken::Const - Interface for MToken Constants

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use MToken::Const;

=head1 DESCRIPTION

This module provide interface for MToken Constants

=head2 PROJECT, PROJECTNAME

Returns name of the project

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTKlib|http://search.cpan.org/~abalama/CTKlib/>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTKlib|http://search.cpan.org/~abalama/CTKlib/>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use constant {
        # GENERAL
        PROJECT             => 'mtoken',
        PROJECTNAME         => 'mtoken',
        PREFIX              => 'mtoken',
        MSWIN               => $^O =~ /mswin/i ? 1 : 0,
        DIR_KEYS            => 'keys',
        DIR_CERTS           => 'certs',
        DIR_ETC             => 'etc',
        DIR_BACKUP          => 'backup',
        DIR_RESTORE         => 'restore',
        DIR_TMP             => '.tmp',
        PUBLIC_GPG_KEY      => 'public.key',
        PRIVATE_GPG_KEY     => 'private.key',
        GPGCONFFILE         => 'gpg.conf',
        GPGBIN              => 'gpg',
        OPENSSLBIN          => 'openssl',

        # MATH
        TRUE                => 1,
        FALSE               => 0,

        # CRYPT
        KEYSUFFIX           => '.key',
        KEYMINSIZE          => 32,
        KEYMAXSIZE          => 2048,

        # TEST
        FOO => 1,
        BAR => 2,
        BAZ => 3,

    };

use base qw/Exporter/;

use Carp; # carp - warn; croak - die;

use vars qw/$VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS/;
$VERSION = '1.00';

# Named groups of exports
%EXPORT_TAGS = (
    'GENERAL' => [qw/
        PROJECT PROJECTNAME PREFIX
        DIR_KEYS DIR_CERTS DIR_ETC DIR_BACKUP DIR_RESTORE DIR_TMP
        GPGCONFFILE PUBLIC_GPG_KEY PRIVATE_GPG_KEY
        MSWIN
        OPENSSLBIN GPGBIN
    /],
    'MATH' => [qw/
        TRUE FALSE
    /],
    'CRYPT' => [qw/
        KEYSUFFIX KEYMINSIZE KEYMAXSIZE
    /],
    'TEST' => [qw/
        FOO
        BAR
        BAZ

    /],
);

# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)
@EXPORT = (
        @{$EXPORT_TAGS{GENERAL}},
    );

# Other items we are prepared to export if requested
@EXPORT_OK = (
        map {@{$_}} values %EXPORT_TAGS
    );

1;
