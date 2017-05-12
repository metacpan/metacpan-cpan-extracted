package MDV::Distribconf::MediaCFG;

use strict;
use warnings;
use MDV::Distribconf;

our $VERSION = (qq$Revision: 224942 $ =~ /(\d+)/)[0];

=head1 NAME

MDV::Distribconf::MediaCFG

=head1 DESCRIPTION

This module provides documenation of known values in F<media.cfg>.

=head1 MEDIACFG VERSION

The media.cfg version is given by the 'mediacfg_version' in 'media_info'.
This value should be set is you want to use new features that can change the
behavior of this module.

=head2 1

This is the default and the first version of media.cfg format.

=head2 2

Since this version, all media paths are relative to the media_info path.
Previously, media paths were relative to media_info except when beginning with
F</>, which were relative to the root of the distrib.

=head2 3

This version allows to include in values variables that refer to
other values defined in the configuration file:

=over 4

=item ${...}

refers to a global value (distribution version, arch...)

=item %{...}

refers to a value specific to the media (name, ...)

=back

=head1 VALUE

=cut

my $value = {};

=head2 GLOBAL VALUES

This value can only be set into 'media_info' section.

=cut

$value->{mediacfg_version} = { 
    validation => sub {
        my ($val) = @_;
        if ($val !~ /^(\d|.)+$/) {
            return ("should be a number");
        }
        return ();
    },
};

=head3 mediacfg_version

The version of the media_cfg

See L<MEDIACFG VERSION>

=cut

$value->{version} = { section => 'media_info' };

=head3 version

The version of distrib

=cut

$value->{arch} = { section => 'media_info' };

=head3 arch

The arcitecture of the distribution

=cut

$value->{suppl} = { section => 'media_info' };

=head3 suppl

This tag is used to change installer behavior, when set, user should be allow
to add media not provided by this distribution.

=cut

$value->{askmedia} = { section => 'media_info' };

=head3 askmedia

This tag is used to change installer behavior, when set, user should be prompt
before adding each media.

=cut

$value->{branch} = { section => 'media_info' };

=head3 branch

The branch of the distribution.

=cut

$value->{product} = { section => 'media_info' };

=head3 product

The name of the product, 'Download' by default

=cut

$value->{minor} = { section => 'media_info' };

=head3 minor

No documentation

=cut

$value->{subversion} = { section => 'media_info' };

=head3 subversion

No documentation

=cut

=head2 MEDIA VALUES

=cut

foreach (qw(hdlist name synthesis pubkey)) {
    $value->{$_} = { };
}

=head3 name

The name of the media. If unset, the section is the name.

=head3 hdlist

The hdlist file holding rpm infos for the media

=head3 synthesis

The synthesis file holding rpm infos for the media

=head3 pubkey

The file holding public gpg key used to sign rpms in this media.

=cut

$value->{srpms} = { deny => 'rpms', cross => 'rpms', ismedialist => 1 };

=head3 srpms

If the media hold binaries rpms, this parameter contains
the list of medias holding corresponding sources rpms.

=cut

$value->{rpms} = { deny => 'srpms', cross => 'srpms', ismedialist => 1 };

=head3 rpms

If the media hold sources rpms, this parameter contains
the list of media holding binaries rpms build by srpms from this media.

=cut

$value->{updates_for} = { ismedialist => 1 };

=head3 updates_for

If the media contain updates, it contain the list of media for which
rpms are updates.

=cut

$value->{debug_for} = { ismedialist => 1 };

=head3 debug_for

If the media contain debug rpms, it contain the list of media for which
rpms are debug rpms.

=cut

$value->{noauto} = {};

=head3 noauto

This value is used by tools to assume if the media should automatically
added to the config (urpmi).

=cut

$value->{size} = {
    validation => sub {
        my ($v) = @_;
        if ($v =~ /^(\d+)(\w)?$/) {
            if ($2) {
                if (! grep { lc($2) eq $_ } qw(k m g t p)) {
                    return("wrong unit");
                }
            }
            return;
        } else {
            return ("malformed value");
        }
    },
};

=head3 size

The size of the media. The value is suffixed by the unit.

=cut

# valid_param($media, $var, $val)
#
# Return a list of errors (if any) about having such value in the config

sub _valid_param {
    my ($media, $var, $val) = @_[-3..-1];
    if (!exists($value->{$var})) {
        return ("unknow var");
    }
    $media ||= 'media_info'; # assume default
    my @errors;
    if ($value->{$var}{section} && $value->{$var}{section} ne $media) {
        push(@errors, "wrong section: should be in $value->{$var}{section}");
    }
    if ($value->{$var}{validation}) {
        push(@errors, $value->{$var}{validation}->($val));
    }
    return @errors;
}

# Retun a hash containing information about $var

sub _value_info {
    my ($var) = $_[-1];
    if (exists($value->{$var})) {
        return $value->{$var}
    }
    return;
}

1;

__END__

=head1 AUTHOR

Olivier Thauvin <nanardon@mandriva.org>

=head1 LICENSE AND COPYRIGHT

(c) 2005, 2006, 2007 Olivier Thauvin
(c) 2005, 2006, 2007 Mandriva

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut
