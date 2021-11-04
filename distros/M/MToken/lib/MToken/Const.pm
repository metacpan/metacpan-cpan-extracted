package MToken::Const; # $Id: Const.pm 105 2021-10-10 19:48:33Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MToken::Const - Interface for MToken Constants

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    use MToken::Const;

=head1 DESCRIPTION

This module provide interface for MToken Constants

=head2 PROJECT, PROJECTNAME, PROJECTNAMEL

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

Copyright (C) 1998-2021 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Try::Tiny;

use constant {
        # GENERAL
        PROJECT             => 'MToken',
        PROJECTNAME         => 'MToken',
        PROJECTNAMEL        => 'mtoken',
        PREFIX              => 'mtoken',
        HOSTNAME            => 'localhost',
        DEFAULT_URL         => 'http://localhost',
        IS_TTY              => (-t STDOUT) ? 1 : 0,
        IS_ROOT             => ($> == 0) ? 1 : 0,
        IS_MSWIN            => $^O =~ /mswin/i ? 1 : 0,
        SCREENWIDTH_DEFAULT => 80,
        DATE_FORMAT         => "%YYYY-%MM-%DD",
        TIME_FORMAT         => "%hh:%mm:%ss",
        DATETIME_FORMAT     => "%YYYY-%MM-%DD %hh:%mm:%ss",
        DATETIME_GMT_FORMAT => "%YYYY-%MM-%DD %hh:%mm:%ss %G",
        TOKEN_PATTERN       => qr/^[a-z][a-z0-9]+$/,
        TARBALL_FORMAT      => "C%YYYY%MM%DDT%hh%mm%ss.tkn",
        TARBALL_PATTERN     => qr/^C[0-9]{8}T[0-9]{6}\.tkn$/,
        RECORDS_PER_PAGE    => 100,

        # UID/GID for daemon
        USERNAME            => 'mtoken',
        GROUPNAME           => 'mtoken',

        # DIRS
        DIR_KEYS            => 'keys',
        DIR_CERTS           => 'certs',
        DIR_ETC             => 'etc',
        DIR_BACKUP          => $^O =~ /mswin/i ? 'backup' : '.backup',
        DIR_RESTORE         => $^O =~ /mswin/i ? 'restore' : '.restore',
        DIR_TMP             => $^O =~ /mswin/i ? 'tmp' : '.tmp',
        DIR_PRIVATE         => $^O =~ /mswin/i ? 'mtoken' : '.mtoken',

        # Files
        GLOBAL_CONF_FILE    => 'mtoken.conf',
        DEVICE_CONF_FILE    => 'mtoken.conf',
        DEVICE_MANIFEST_FILE=> 'manifest.lst',
        DB_FILE             => 'tokencase.db',
        RND_KEY_FILE        => 'tokenrnd.key',
		PWCACHE_FILE        => 'pwcache.tmp',
        PUBLIC_GPG_KEY      => 'public.key',
        PRIVATE_GPG_KEY     => 'private.key',
        MY_PUBLIC_KEY       => 'mypublic.key',
        MY_PRIVATE_KEY      => 'myprivate.key',
        GPGCONFFILE         => 'gpg.conf',

        # System paths
        GPGBIN              => 'gpg',
        OPENSSLBIN          => 'openssl',

        # Server
        SERVER_URL          => 'https://localhost:8642/mtoken',
        SERVER_LISTEN_PORT  => 8642,
        SERVER_LISTEN_ADDR  => "*",
        UPGRADE_TIMEOUT     => 30,

        # MATH
        TRUE                => 1,
        FALSE               => 0,

        # CRYPT
        KEYSUFFIX           => '.key',
        KEYMINSIZE          => 32,
        KEYMAXSIZE          => 2048,
    };

use base qw/Exporter/;

use vars qw/$VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS/;
$VERSION = '1.02';

# Named groups of exports
%EXPORT_TAGS = (
    'GENERAL' => [qw/
        PROJECT PROJECTNAME PROJECTNAMEL PREFIX
        HOSTNAME DEFAULT_URL
        DIR_KEYS DIR_CERTS DIR_ETC DIR_BACKUP DIR_RESTORE DIR_TMP DIR_PRIVATE
        GLOBAL_CONF_FILE DEVICE_CONF_FILE DEVICE_MANIFEST_FILE DB_FILE PWCACHE_FILE RND_KEY_FILE
        MY_PUBLIC_KEY MY_PRIVATE_KEY
        GPGCONFFILE PUBLIC_GPG_KEY PRIVATE_GPG_KEY
        SCREENWIDTH_DEFAULT SCREENWIDTH
        IS_TTY IS_ROOT IS_MSWIN
        TOKEN_PATTERN TARBALL_PATTERN TARBALL_FORMAT
        DATE_FORMAT DATETIME_FORMAT TIME_FORMAT DATETIME_GMT_FORMAT
        RECORDS_PER_PAGE
        OPENSSLBIN GPGBIN
        SERVER_URL SERVER_LISTEN_PORT SERVER_LISTEN_ADDR UPGRADE_TIMEOUT
        USERNAME GROUPNAME
    /],
    'MATH' => [qw/
        TRUE FALSE
    /],
    'CRYPT' => [qw/
        KEYSUFFIX KEYMINSIZE KEYMAXSIZE
    /],
);

my $myscreenw = undef;
*SCREENWIDTH = sub {
    return $myscreenw if defined $myscreenw;
    if (IS_TTY) {
        try {
            require Term::ReadKey;
            my $w = (Term::ReadKey::GetTerminalSize())[0];
            $myscreenw = $w < SCREENWIDTH_DEFAULT ? SCREENWIDTH_DEFAULT : $w;
        } catch {
            $myscreenw = SCREENWIDTH_DEFAULT;
        };
    } else {
        $myscreenw = SCREENWIDTH_DEFAULT;
    }
    return $myscreenw;
};

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
