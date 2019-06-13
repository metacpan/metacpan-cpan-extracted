package MToken::Const; # $Id: Const.pm 72 2019-06-11 07:28:00Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MToken::Const - Interface for MToken Constants

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use MToken::Const;

=head1 DESCRIPTION

This module provide interface for MToken Constants

=head2 PROJECT, PROJECTNAME

Returns name of the project

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<MToken>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use constant {
        # GENERAL
        PROJECT             => 'mtoken',
        PROJECTNAME         => 'mtoken',
        PREFIX              => 'mtoken',
        HOSTNAME            => 'localhost',
        DEFAULT_URL         => 'http://localhost',
        MSWIN               => $^O =~ /mswin/i ? 1 : 0,
        DIR_KEYS            => 'keys',
        DIR_CERTS           => 'certs',
        DIR_ETC             => 'etc',
        DIR_BACKUP          => 'backup',
        DIR_RESTORE         => 'restore',
        DIR_TMP             => $^O =~ /mswin/i ? 'tmp' : '.tmp',
        GLOBAL_CONF_FILE    => 'mtoken.conf',
        LOCAL_CONF_FILE     => '.mtoken',
		PWCACHE_FILE        => '.pwcache',

        PUBLIC_GPG_KEY      => 'public.key',
        PRIVATE_GPG_KEY     => 'private.key',
        MY_PUBLIC_KEY       => 'mypublic.key',
        MY_PRIVATE_KEY      => 'myprivate.key',
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

use vars qw/$VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS/;
$VERSION = '1.01';

# Named groups of exports
%EXPORT_TAGS = (
    'GENERAL' => [qw/
        PROJECT PROJECTNAME PREFIX
        HOSTNAME DEFAULT_URL
        DIR_KEYS DIR_CERTS DIR_ETC DIR_BACKUP DIR_RESTORE DIR_TMP
        GLOBAL_CONF_FILE LOCAL_CONF_FILE PWCACHE_FILE
        MY_PUBLIC_KEY MY_PRIVATE_KEY
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
