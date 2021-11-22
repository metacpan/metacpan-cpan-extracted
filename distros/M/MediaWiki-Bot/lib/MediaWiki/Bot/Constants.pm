package MediaWiki::Bot::Constants;
use strict;
use warnings;
# ABSTRACT: constants for MediaWiki::Bot
our $VERSION = '5.007000'; # VERSION

use MediaWiki::API; # How to grab these constants?
use Constant::Generate {
    ERR_NO_ERROR    => MediaWiki::API->ERR_NO_ERROR,
    ERR_CONFIG      => MediaWiki::API->ERR_CONFIG,
    ERR_HTTP        => MediaWiki::API->ERR_HTTP,
    ERR_API         => MediaWiki::API->ERR_API,
    ERR_LOGIN       => MediaWiki::API->ERR_LOGIN,
    ERR_EDIT        => MediaWiki::API->ERR_EDIT,
    ERR_PARAMS      => MediaWiki::API->ERR_PARAMS,
    ERR_UPLOAD      => MediaWiki::API->ERR_UPLOAD,
    ERR_DOWNLOAD    => MediaWiki::API->ERR_DOWNLOAD,
    ERR_CAPTCHA     => 10,

    RET_TRUE        => !!1,
    RET_FALSE       => !!0,

    PAGE_NONEXISTENT => -1,

    FILE_NONEXISTENT    => 0,
    FILE_LOCAL          => 1,
    FILE_SHARED         => 2,
    FILE_PAGE_TEXT_ONLY => 3,

    NS_USER     => 2,
    NS_FILE     => 6,
    NS_CATEGORY => 14,

};#, dualvar => 1;

use Exporter qw(import);
our %EXPORT_TAGS = (
    err => [qw(
        ERR_NO_ERROR
        ERR_CONFIG
        ERR_HTTP
        ERR_API
        ERR_LOGIN
        ERR_EDIT
        ERR_PARAMS
        ERR_UPLOAD
        ERR_DOWNLOAD
        ERR_CAPTCHA
    )],
    bool => [qw( RET_TRUE RET_FALSE )],
    page => [qw( PAGE_NONEXISTENT )],
    file => [qw( FILE_NONEXISTENT FILE_LOCAL FILE_SHARED FILE_PAGE_TEXT_ONLY )],
    ns   => [qw( NS_USER NS_FILE NS_CATEGORY )],
);

Exporter::export_tags(qw(err));
Exporter::export_ok_tags(qw(bool page file ns));

{
  my %seen;

  push @{$EXPORT_TAGS{all}},
    grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MediaWiki::Bot::Constants - constants for MediaWiki::Bot

=head1 VERSION

version 5.007000

=head1 CONSTANTS

The available constants are divided into 5 tags, which can be imported
individually:

=over 4

=item *

err - the error constants, inherited from L<MediaWiki::API>

=item *

bool - boolean constants

=item *

page - page existence

=item *

file - file (image/media) existence status (which is not boolean)

=item *

ns - some namespace numbers. B<Achtung!> Incomplete! Use L<MediaWiki::Bot>'s
functions for getting namespace information for your wiki.

=back

=head1 EXPORTS

No symbols are exported by default. The available tags are err, bool, page, file, ns, and all.

=head1 SYNOPSIS

    use MediaWiki::Bot;
    use MediaWiki::Bot::Constants qw(:file);

    my $bot = MediaWiki::Bot->new();
    my $file_existence = $bot->test_image_exists("File:...");

    # Make sense of MediaWiki::Bot's random numbers
    if ($file_existence == FILE_LOCAL) {
        # Get from local media repository
    }
    elsif ($file_existence == FILE_SHARED) {
        # Get from shared (remote) media repository
    }

=head1 DESCRIPTION

Exportable constants used by L<MediaWiki::Bot>. Use these constants
in your code to avoid the use of magical numbers, and to ensure
compatibility with future changes in C<MediaWiki::Bot>.

You can also import C<:constants> or any constant name(s) from
L<MediaWiki::Bot>:

    use MediaWiki::Bot qw(:constants);
    use MediaWiki::Bot qw(PAGE_NONEXISTENT);

=head1 AVAILABILITY

The project homepage is L<https://metacpan.org/module/MediaWiki::Bot>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/MediaWiki::Bot/>.

=head1 SOURCE

The development version is on github at L<https://github.com/MediaWiki-Bot/MediaWiki-Bot>
and may be cloned from L<git://github.com/MediaWiki-Bot/MediaWiki-Bot.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/MediaWiki-Bot/MediaWiki-Bot/issues>.

=head1 AUTHORS

=over 4

=item *

Dan Collins <dcollins@cpan.org>

=item *

Mike.lifeguard <lifeguard@cpan.org>

=item *

Alex Rowe <alex.d.rowe@gmail.com>

=item *

Oleg Alexandrov <oleg.alexandrov@gmail.com>

=item *

jmax.code <jmax.code@gmail.com>

=item *

Stefan Petrea <stefan.petrea@gmail.com>

=item *

kc2aei <kc2aei@gmail.com>

=item *

bosborne@alum.mit.edu

=item *

Brian Obio <brianobio@gmail.com>

=item *

patch and bug report contributors

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by the MediaWiki::Bot team <perlwikibot@googlegroups.com>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
