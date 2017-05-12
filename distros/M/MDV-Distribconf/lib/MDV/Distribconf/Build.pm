package MDV::Distribconf::Build;

=head1 NAME

MDV::Distribconf::Build - Subclass to MDV::Distribconf to build configuration

=head1 METHODS

=over 4

=cut

use strict;
use warnings;
use File::Path;
use MDV::Packdrakeng;
use File::Temp qw(tempfile);
use File::Copy qw(cp);
use Digest::MD5;

use base qw(MDV::Distribconf MDV::Distribconf::Checks);
our $VERSION = (qq$Revision: 224942 $ =~ /(\d+)/)[0];

=item MDV::Distribconf::Build->new($root_of_distrib)

Returns a new MDV::Distribconf::Build object.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;
}

=item $distrib->init($flavour)

Create initals directories in the distrib tree if missing.

$flavour is either 'mandriva' or 'mandrake', depending the tree type
you want to create.

See also L<MDV::Distribconf/settree>

Return 1 on success, 0 otherwise.

=cut

sub init {
    my ($self, $flavour) = @_;
    $self->settree($flavour || 'mandriva') unless($self->{infodir});
    if (!-d $self->getfullpath(undef, 'root')) {
        if (!mkdir($self->getfullpath(undef, 'root'))) {
            warn 'Cannot create ' . $self->getfullpath(undef, 'root') .": $!\n";
            return 0;
        }
    }
    foreach my $dir (map { $self->getfullpath(undef, $_) } qw(mediadir infodir)) {
        if (!-d $dir) {
            eval { mkpath($dir) };
            if ($@) {
                warn "Cannot create $dir: $@\n";
                return 0;
            }
        }
    }

    foreach my $media ($self->listmedia()) {
        $self->create_media($media) or return 0;
    }

    1;
}

=item $distrib->create_media($media)

Create a media $media if not exists and its directories if need.

See also L<setvalue>

Return 1 on success, 0 otherwise

=cut

sub create_media {
    my ($self, $media) = @_;
    $self->setvalue($media, undef, undef);
    foreach my $dir (map { $self->getfullmediapath($media, $_) } qw(path infodir)) {
        if (!-d $dir) {
            eval { mkpath($dir) };
            if ($@) {
                warn "Cannot create $dir: $@\n";
                $self->delvalue($media, undef);
                return 0;
            }
        }
    }

    1;
}

=item $distrib->setvalue($media, $var, $val)

Sets or adds $var parameter from $media to $val. If $media doesn't exist,
it is implicitly created. If $var is C<undef>, a new media is created with
no defined parameters.

=cut

sub setvalue {
    my ($distrib, $media, $var, $val) = @_;
    $media ||= 'media_info';
    $distrib->{cfg}->AddSection($media);
    if ($var) {
        if ($media && !$distrib->mediaexists($media)) {
            $distrib->setvalue($media);
        }
        $var =~ /^(?:media|info)dir\z/ and do {
            $distrib->{$var} = $val;
            return 1;
        };
        if ($val) {
            $distrib->{cfg}->newval($media, $var, $val)
	        or warn "Can't set value [$var=$val] for $media\n";
        } else {
            $distrib->{cfg}->delval($media, $var);
        }
    }
    $distrib->_post_setvalue($media, $var, $val) if ($media);
}

sub _post_setvalue {
    my ($distrib, $cmedia, $cvar, $cval) = @_;
    if ($cvar) {
        my $vsettings = MDV::Distribconf::MediaCFG::_value_info($cvar);
        if ($vsettings->{cross}) {
            my %pointed_media = map { $_ => 1 } split(/\s/, $cval);
            foreach my $media ($distrib->listmedia()) {
                my %ml = map { $_ => 1 }
                    split(/\s/, $distrib->getvalue($media, $vsettings->{cross}));

                if (exists($pointed_media{$media})) {
                    exists($ml{$cmedia}) and next;
                    $ml{$cmedia} = 1;
                } else {
                    exists($ml{$cmedia}) or next;
                    delete($ml{$cmedia});
                }
                $distrib->setvalue(
                    $media,
                    $vsettings->{cross},
                    join(" ", keys %ml),
                );
            }
        }
    } else {
        foreach my $media ($distrib->listmedia()) {
            foreach my $val ($distrib->{cfg}->Parameters($media)) {
            my $vsettings = MDV::Distribconf::MediaCFG::_value_info($val);
                if ($vsettings->{cross}) {
                    if (grep { $_ eq $cmedia } 
                        split(/\s/, $distrib->getvalue($media, $val))) {
                        my %ml = map { $_ => 1 }
                            split(/\s/, $distrib->getvalue($cmedia, $vsettings->{cross}));
                        exists($ml{$media}) and next;
                        $ml{$media} = 1;
                        $distrib->setvalue(
                            $cmedia,
                            $vsettings->{cross},
                            join(" ", keys %ml),
                        );
                    }
                }
            }
        }
    }
    1;
}

=item $distrib->delvalue($media, $var)

Delete $var parameter from $media. If $var is not specified, the media is
is deleted. If $media is not specified, $var is remove from global settings.

=cut

sub delvalue {
    my ($distrib, $media, $var) = @_;
    if ($var) {
        $distrib->{cfg}->delval($media, $var);
    } else {
        $distrib->{cfg}->DeleteSection($media);
    }
    $distrib->_post_delvalue($media, $var);
}

sub _post_delvalue {
    my ($distrib, $cmedia, $cvar) = @_;
    foreach my $media ($distrib->listmedia()) {
        if ($cvar) {
            my $vsettings = MDV::Distribconf::MediaCFG::_value_info($cvar);
            if ($vsettings->{cross}) {
                if($distrib->getvalue($media, $vsettings->{cross})) {
                    my %ml = map { $_ => 1 } split(/\s/, $distrib->getvalue($media, $vsettings->{cross}));
                    exists($ml{$cmedia}) or next;
                    delete($ml{$cmedia});

                    $distrib->setvalue(
                        $media,
                        $vsettings->{cross},
                        join(" ", keys %ml)
                    );
                }
            }
        } else {
            foreach my $val ($distrib->{cfg}->Parameters($media)) {
                my $vsettings = MDV::Distribconf::MediaCFG::_value_info($val);
                if ($vsettings->{ismedialist} && $distrib->getvalue($media, $val)) {
                    my %ml = map { $_ => 1 } split(/\s/, $distrib->getvalue($media, $val));
                    exists($ml{$cmedia}) or next;
                    delete($ml{$cmedia});
                    $distrib->setvalue(
                        $media,
                        $val,
                        join(" ", keys %ml)
                    );
                }
            }
        }
    }
    1;
}

=item $distrib->write_hdlists($hdlists)

Writes the F<hdlists> file to C<$hdlists>, or if no parameter is given, in
the media information directory. C<$hdlists> can be a file path or a file
handle. Returns 1 on success, 0 on error.

=cut

sub write_hdlists {
    my ($distrib, $hdlists) = @_;
    my $h_hdlists;
    if (ref $hdlists eq 'GLOB') {
        $h_hdlists = $hdlists;
    } else {
        $hdlists ||= "$distrib->{root}/$distrib->{infodir}/hdlists";
        open $h_hdlists, ">", $hdlists
	    or return 0;
    }
    foreach my $media ($distrib->listmedia) {
        printf($h_hdlists "%s%s\t%s\t%s\t%s\n",
            join('', map { "$_:" } grep { $distrib->getvalue($media, $_) } qw/askmedia suppl noauto/) || "",
            $distrib->getvalue($media, 'hdlist'),
            $distrib->getpath($media, 'path'),
            $distrib->getvalue($media, 'name'),
            $distrib->getvalue($media, 'size') ? '('.$distrib->getvalue($media, 'size'). ')' : "",
        ) or return 0;
    }
    return 1;
}

=item $distrib->write_mediacfg($mediacfg)

Write the media.cfg file into the media information directory, or into the
$mediacfg given as argument. $mediacfg can be a file path, or a glob reference
(\*STDOUT for example).

Returns 1 on success, 0 on error.

=cut

sub write_mediacfg {
    my ($distrib, $hdlistscfg) = @_;
    $hdlistscfg ||= "$distrib->{root}/$distrib->{infodir}/media.cfg";
    $distrib->{cfg}->WriteConfig($hdlistscfg);
}

=item $distrib->write_version($version)

Write the VERSION file. Returns 0 on error, 1 on success.

=cut

sub write_version {
    my ($distrib, $version) = @_;
    my $h_version;
    if (ref($version) eq 'GLOB') {
        $h_version = $version;
    } else {
        $version ||= $distrib->getfullpath(undef, 'VERSION');
        open($h_version, ">", $version) or return 0;
    }

    my @gmt = gmtime(time);

    printf($h_version "Mandriva Linux %s %s-%s-%s%s %s\n",
        $distrib->getvalue(undef, 'version') || 'cooker',
        $distrib->getvalue(undef, 'branch') || 'cooker',
        $distrib->getvalue(undef, 'arch') || 'noarch',
        $distrib->getvalue(undef, 'product'),
        $distrib->getvalue(undef, 'tag') ? '-' . $distrib->getvalue(undef, 'tag') : '',
        sprintf("%04d%02d%02d %02d:%02d", $gmt[5] + 1900, $gmt[4]+1, $gmt[3], $gmt[2], $gmt[1])
    );

    if (ref($version) ne 'GLOB') {
        close($h_version);
    }
    return 1;
}

=item $distrib->write_productid($productid)

Write the productid file. Returns 0 on error, 1 on success.

=cut

sub write_productid {
    my ($distrib, $productid) = @_;
    my $h_productid;
    if (ref($productid) eq 'GLOB') {
        $h_productid = $productid;
    } else {
        $productid ||= $distrib->getfullpath(undef, 'product.id');
        open($h_productid, ">", $productid) or return 0;
    }

    print $h_productid $distrib->getvalue(undef, 'productid') . "\n";

    if (ref($productid) ne 'GLOB') {
        close($h_productid);
    }

    return 1;
}

=item $distrib->list_existing_medias()

List media which really exists on the disk

=cut

sub list_existing_medias {
    my ($self) = @_;
    grep { -d $self->getfullmediapath($_, 'path') } $self->listmedia();
}

=item $distrib->set_medias_size($media)

Set media size into media.cfg for $media

=cut

sub set_media_size {
    my ($self, $media) = @_;
    my $size = 0;
    foreach (glob($self->getfullmediapath($media, 'path') . '/*.rpm')) {
        $size += (stat($_))[7];
    }
    my $blk = 1;
    my $showsize = $size;
    my @unit = (' ', qw(k m g));
    while (@unit) {
        my $u = shift(@unit);
        if ($size / $blk < 1) {
            last;
        }
        $showsize = sprintf('%d%s', $size / $blk, $u);
        $blk *= 1024;
    }
    $self->setvalue($media, 'size', $showsize);
}

=item $distrib->set_all_medias_size()

Set media size into media.cfg

=cut

sub set_all_medias_size {
    my ($self) = @_;
    foreach my $media ($self->list_existing_medias()) {
        $self->set_media_size($media);
    }
}

1;

__END__

=back

=head1 SEE ALSO

L<MDV::Distribconf>

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
