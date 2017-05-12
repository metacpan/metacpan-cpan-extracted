# $Id: Checks.pm 59285 2006-09-01 00:10:10Z nanardon $

package MDV::Distribconf::Checks;

our $VERSION = (qq$Revision: 59285 $ =~ /(\d+)/)[0];

=head1 NAME

MDV::Distribconf::Checks - A Subclass to MDV::Distribconf::Build to check distribution trees

=head1 METHODS

=over 4

=cut

use strict;
use warnings;
use MDV::Distribconf::MediaCFG;
use MDV::Packdrakeng;
use Digest::MD5;
use MDV::Distribconf::Utils;
use base qw(MDV::Distribconf);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;
}

sub _report_err {
    my ($out, $err_code, $fmt, @args) = @_;
    my %errs = (
        'UNSYNC_HDLIST' => 'E',
        'UNSYNC_MD5' => 'E',
        'WRONG_CONFIG' => 'W',
        'MISSING_MEDIA' => 'W',
        'MISSING_MEDIADIR' => 'E',
        'SAME_INDEX' => 'E',
        'NOMEDIA' => 'E',
        'MISSING_INDEX' => 'E',
        'MISSING_INFO' => 'W',
    );
    my $message = sprintf($fmt, @args);

    if (ref $out eq 'CODE') {
        $out->(
            errcode => $err_code || '?',
            level => $errs{$err_code} || '?',
            message => $message,
        );
    } else {
        printf $out "%s: %s\n", $errs{$err_code} || '?', $message;
    }
    return($errs{$err_code} || '?' eq 'E' ? 1 : 0)
}

=item $distrib->check_config

=cut

sub check_config {
    my ($self, $fhout) = @_;
    $fhout ||= \*STDERR;

    my $error = 0;

    foreach my $var ($self->{cfg}->Parameters('media_info')) {
        $self->{cfg}->val('media_info', $var) or next;
        my @er = MDV::Distribconf::MediaCFG::_valid_param(
            'media_info',
            $var,
            $self->{cfg}->val('media_info', $var),
        );
        foreach (@er) {
            $error += _report_err(
                $fhout,
                'WRONG_CONFIG',
                "%s %s: %s", 'media_info', $var, $_
            );
        }
    }
    foreach my $media ($self->listmedia()) {
        foreach my $var ($self->{cfg}->Parameters($media)) {
            $self->{cfg}->val($media, $var) or next;
            my @er = MDV::Distribconf::MediaCFG::_valid_param(
                'media_info',
                $var,
                $self->getvalue($media, $var),
            );
            foreach (@er) {
                $error += _report_err(
                    $fhout,
                    'WRONG_CONFIG',
                    "%s %s: %s", $media, $var, $_
                );
            }
            my $varinfo = MDV::Distribconf::MediaCFG::_value_info($var) || {};
            if ($varinfo->{deny}) {
                if ($self->getvalue($media, $varinfo->{deny})) {
                    $error += _report_err(
                        $fhout,
                        'WRONG_CONFIG',
                        '%s and %s cannot be set together (media %s)',
                        $var, $varinfo->{deny}, $media
                    );
                }
            }
            if ($varinfo->{ismedialist} || $varinfo->{cross}) {
            foreach my $sndmedia (split(/ /, $self->getvalue($media, $var, ''))) {
                if (!$self->mediaexists($sndmedia)) {
                    $error += _report_err(
                        $fhout,
                        'MISSING_MEDIA',
                         "`%s' refer as %s to non existant `%s'",
                        $media,
                        $var,
                        $sndmedia,
                    );
                } elsif($varinfo->{cross}) {
                    if(!grep { $media eq $_ } 
                        split(/ /, 
                            $self->getvalue($sndmedia, $varinfo->{cross})
                        )) {
                        $error += _report_err(
                            $fhout,
                            'WRONG_CONFIG',
                            "`%s' has not `%s' as %s",
                            $sndmedia, $media, $varinfo->{cross},
                        );
                    }
                }
            }
            }
        }
    }

    # checking overlap
    {
        my %foundname;
        push(@{$foundname{$self->getvalue($_, 'name')}}, $_) 
            foreach($self->listmedia());

        foreach (keys %foundname) {
            if (@{$foundname{$_}} > 1) {
                $error += _report_err(
                    $fhout,
                    'WRONG_CONFIG',
                    "`%s' have same name (%s)",
                    join(', ', @{$foundname{$_}}),
                    $_,
                );
            }
        }
    }

    $error
}
=item $distrib->check_media_coherency($fhout)

Performs basic checks on the distribution and prints to $fhout (STDERR by
default) warnings and errors found. Returns the number of errors reported.

=cut

sub check_media_coherency {
    my ($distrib, $fhout) = @_;
    $fhout ||= \*STDERR;

    my $error = 0;

    $distrib->listmedia or $error += _report_err(
        'NOMEDIA', "No media found in this config"
    );

    # Checking no overlap
    foreach my $var (qw/hdlist synthesis path/) {
        my %e;
        foreach ($distrib->listmedia) {
            my $v = $distrib->getpath($_, $var);
            push @{$e{$v}}, $_;
        }

        foreach my $key (keys %e) {
            if (@{$e{$key}} > 1) {
                $error += _report_err(
                    $fhout,
                    'SAME_INDEX', 
                    "media `%s' have same %s (%s)",
                    join (", ", @{$e{$key}}),
                    $var,
                    $key
                );
            }
        }
    }

    foreach my $media ($distrib->listmedia) {
	-d $distrib->getfullpath($media, 'path') or $error += _report_err(
	    $fhout,
		'MISSING_MEDIADIR', "dir %s does't exist for media `%s'",
	    $distrib->getpath($media, 'path'),
	    $media
	);
	foreach (qw/hdlist synthesis MD5SUM/) {
	    -f $distrib->getfullmediapath($media, $_) or $error += _report_err(
        $fhout,
		'MISSING_INDEX', "$_ %s doesn't exist for media `%s'",
		$distrib->getmediapath($media, $_),
		$media
	    );
        /^MD5SUM$/ and next;
	    -f $distrib->getfullpath($media, $_) or $error += _report_err(
        $fhout,
		'MISSING_INDEX', "$_ %s doesn't exist for media `%s'",
		$distrib->getpath($media, $_),
		$media
	    );
	}
    foreach (qw/pubkey/) {
	    -f $distrib->getfullpath($media, $_) or $error += _report_err(
        $fhout,
		'MISSING_INFO', "$_ %s doesn't exist for media `%s'",
		$distrib->getpath($media, $_),
		$media
	    );
	}

    }
    return $error;
}

=item $distrib->check_index_sync($media)

Check the synchronisation between rpms contained by media $media
and its hdlist:

  - all rpms should be in the hdlist
  - the hdlist should not contains rpms that does not exists

Return 1 if no problem were found

=cut

sub check_index_sync {
    return (get_index_sync_offset(@_))[0]
}

sub get_index_sync_offset {
    my ($self, $media, $submedia) = @_;
    my $rpmspath = $self->getfullpath($media, 'path');
    my $hdlist = ($submedia && -d $self->getfullpath($media, 'path') . '/media_info') ?
        $self->getfullmediapath($media, 'hdlist') :
        $self->getfullpath($media, 'hdlist');
    my $synthesis = ($submedia && -d $self->getfullpath($media, 'path') . '/media_info') ?
        $self->getfullmediapath($media, 'synthesis') :
        $self->getfullpath($media, 'synthesis');

    -f $hdlist && -f $synthesis or return 0; # avoid warnings
    my ($inp, $ind) = MDV::Distribconf::Utils::hdlist_vs_dir($hdlist, $rpmspath);
    if (!defined($inp) || (@{$inp || []} + @{$ind || []})) {
        return (0, (defined($inp) ? scalar(@{$inp || []}) : undef), scalar(@{$ind || []}));
    }
    return (1, 0, 0);
}

=item $distrib->check_media_md5($media)

Check md5sum for hdlist and synthesis for the media $media are the same
than value contains in the existing MD5SUM file.

The function return an error also if the value is missing

Return 1 if no error were found.

=cut

sub check_media_md5 {
    my ($self, $media) = @_;
    my ($unsync) = MDV::Distribconf::Utils::checkmd5(
        $self->getfullmediapath($media, 'MD5SUM'),
        map { $self->getfullmediapath($media, $_) } (qw(hdlist synthesis))
    );
    if (@{$unsync || []}) {
        return 0;
    } else {
        return 1;
    }
}

sub check_global_md5 {
    my ($self) = @_;
    my @indexes;
    foreach my $media ($self->listmedia()) {
        push(@indexes, map { $self->getfullpath($media, $_) } (qw(hdlist synthesis)));
    }
    my ($unsync) = MDV::Distribconf::Utils::checkmd5(
        $self->getfullpath(undef, 'MD5SUM'),
        @indexes,
    );
    if (@{$unsync || []}) {
        return 0;
    } else {
        return 1;
    }
}

=item $distrib->checkdistrib($fhout)

Performs all light checks on the distribution and prints to $fhout (STDERR by
default) warnings and errors found. Returns the number of errors reported.

=cut

sub checkdistrib {
    my ($self, $fhout) = @_;
    $fhout ||= \*STDERR;

    my $error = 0;

    $error += $self->check_config($fhout);
    $error += $self->check_media_coherency($fhout);

    foreach my $media ($self->listmedia) {
        my ($e, $inhd, $indir) = $self->get_index_sync_offset($media);
        if (!$e) {
            $error += _report_err(
                $fhout,
                'UNSYNC_HDLIST',
                "hdlist for media `%s' is not sync with its rpms" . 
                    (defined($inhd) ? " (+%d -%d rpms)" : ' (missing or unreadable hdlist: +%d rpms)'),
                $media, ($indir || 0), $inhd
            );
        }

        if(!$self->check_media_md5($media)) {
            $error += _report_err(
                $fhout,
                'UNSYNC_MD5',
                "md5sum for media `%s' is not ok",
                $media,
            );
        }
    }

    if (!$self->check_global_md5()) {
        $error += _report_err(
            $fhout,
            'UNSYNC_MD5',
            'Global md5sum file is not ok',
        );
    }
    
    $error
}

=item $distrib->check($fhout)

=cut

sub check {
    my ($self, $fhout) = @_;
    $fhout ||= \*STDERR;

    my $error = $self->check_config($fhout);
    $error += $self->check_media_coherency($fhout);

    $error
}

1;

__END__

=back

=head1 SEE ALSO

L<MDV::Distribconf>
L<MDV::Distribconf::Build>

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
