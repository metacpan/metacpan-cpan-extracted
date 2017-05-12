package MPMinus::Helper::Skel; # $Id: Skel.pm 202 2013-07-25 19:28:15Z minus $
use strict;

=head1 NAME

MPMinus::Helper::Skel - MPMinus project skeleton

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use MPMinus::Helper::Skel;
    
    my $skel = new MPMinus::Helper::Skel( -c => $c );

=head1 DESCRIPTION

MPMinus project skeleton

=head2 METHODS

=over 8

=item B<new>

    my $skel = new MPMinus::Helper::Skel( 
            -c => $c,
            -sharedir => '/foo/bar/baz',
            -url => 'http://search.cpan.org/src/ABALAMA/MPMinus-[VERSION]/src/mpminus-skel.tar.gz',
        );

Creating Skel object

=item B<build>

    my $status = $skel->build( $path );

Building skeleton files with $path using it as temporary folder for archive. This method returns
summary status of download and extract calls

=item B<checkstatus>

    my $status = $skel->checkstatus;

Check skeleton status. True - OK, False - need downloading and extracting


=item B<download>

    my $status = $skel->download( $path );

Download Skel's archive to $path

=item B<extract>

    my $status = $skel->extract( $path );

Extract files from downloaded Skel's archive in $path to share directory

=back

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved

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

use vars qw($VERSION);
$VERSION = '1.01';

use constant {
        SHAREDIR => 'mpminus',
        SKELDIR  => 'skel-[VERSION]',
        SKELFILE => 'mpminus-skel-[VERSION].tar.gz',
        SKELMD5  => 'mpminus-skel-[VERSION].md5',
        SKELSHA1 => 'mpminus-skel-[VERSION].sha1',
        SUMMARY  => 'SUMMARY',
        MIRRORS  => [qw{
                http://dist.suffit.org
                http://dist.mnshome.info
            }], 
    };

use CTK::Util qw/ :BASE /;
use Archive::Extract;
use Digest;
use URI;
use ExtUtils::Manifest qw/ maniread manicheck /;
use Cwd;
use File::Copy::Recursive qw(dircopy dirmove);

sub new {
    my $class = shift;
    my @in = read_attributes(
            [
                [qw/ C CTK /],                      # 0
                [qw/ S SD SHARE SHAREDIR /],        # 1
                [qw/ URI URL ADDR ADDRESS LINK /],  # 2
            ],
        ,@_);
        
    my $mpmver = MPMinus::Helper::Skel::Backward->get_version();
    my $rplc = {
            VERSION => $mpmver,
        };

    my $c   = $in[0];
    croak("CTK object undefined") unless $c && ref($c) eq 'CTK';
    my $sd  = $in[1] || catdir($c->sharedir, SHAREDIR);
    carp("Can't prepare directory \"$sd\"") unless -e $sd or preparedir($sd);
    my $skeldir = catdir($sd, dformat(SKELDIR, $rplc));
    carp("Can't prepare directory \"$skeldir\"") unless -e $skeldir or preparedir($skeldir);
    my $url = $in[2] || '';

    my @mirrors = (); push(@mirrors, dformat($_, $rplc)) for (@{(MIRRORS)});
    
    return bless({
            c           => $c,
            sharedir    => $sd,
            skeldir     => $skeldir,
            tmpdir      => catfile($c->tmpdir),
            mirrors     => [ @mirrors ],
            ls          => _get_ls($skeldir),
            skelfile    => dformat(SKELFILE, $rplc),
            md5file     => dformat(SKELMD5, $rplc),
            sha1file    => dformat(SKELSHA1, $rplc),
            url         => dformat($url, $rplc),
            rplc        => $rplc,
            version     => $mpmver,
        }, $class);
}
sub download {
    my $self = shift;
    my $path = shift || $self->{tmpdir};
    my $c = $self->{c};
    my $arcfile = catfile($path, $self->{skelfile});
    my $url     = $self->{url};

    if (1
        && $url
        && $c->fetch(
                -connect  => { method => 'GET', url => $url },
                -protocol => 'http',
                -dir      => $path,
                -file     => $self->{skelfile},
            )
        && -e $arcfile 
    ) {
        return 1;
    }

    my @mirrors = @{($self->{mirrors})};
    my $getstat;
    my $f;
    
    # Скачиваем сам файл
    $getstat = 0;
    $f = $self->{skelfile};
    foreach (@mirrors) {
        $getstat = $c->fetch(
            -connect  => {
                    method     => 'GET',
                    url        => _get_uri($_, $f),
                },
            -protocol => 'http',
            -dir      => $path,
            -file     => $f,
        );
        last if $getstat && -e $arcfile;
    }
    unless ($getstat)  {
        carp "File can't fetching \"$f\" on mirrors: ".join("; ",@mirrors);
        return 0;
    }
    
    # Контрольные суммы 
    my $my_md5 = _md5($arcfile);
    my $my_sha1 = _sha1($arcfile);
    
    # Скачиваем файл суммы md5
    my $md5summ = '';
    $f = $self->{md5file};
    foreach (@mirrors) {
        $md5summ = $c->fetch(
            -connect  => {
                    method     => 'GET',
                    url        => _get_uri($_, $f),
                },
            -protocol => 'http',
        );
        last if $md5summ;
    }
    if ($md5summ) {
        # Проверка суммы md5
        $md5summ = $1 if $md5summ =~ /([a-fA-F0-9]+)/s;
        if ($md5summ ne $my_md5) {
            carp "Checksums MD5 for file \"$arcfile\" don't match! Expected: $my_md5; got: $md5summ";
            unlink $arcfile;
            return 0;
        }
    } else {
        carp "File can't fetching \"$f\" on mirrors: ".join("; ",@mirrors);
    }

    # Скачиваем файл суммы sha1
    my $sha1summ = '';
    $f = $self->{sha1file};
    foreach (@mirrors) {
        $sha1summ = $c->fetch(
            -connect  => {
                    method     => 'GET',
                    url        => _get_uri($_, $f),
                },
            -protocol => 'http',
        );
        last if $sha1summ;
    }
    if ($sha1summ) {
        # Проверка суммы sha1
        $sha1summ = $1 if $sha1summ =~ /([a-fA-F0-9]+)/s;
        if ($sha1summ ne $my_sha1) {
            carp "Checksums SHA1 for file \"$arcfile\" don't match! Expected: $my_sha1; got: $sha1summ";
            unlink $arcfile;
            return 0;
        }
    } else {
        carp "File can't fetching \"$f\" on mirrors: ".join("; ",@mirrors);
    }
    
    return 1;
}
sub extract {
    my $self = shift;
    my $path = shift || $self->{tmpdir};
    my $c = $self->{c};
    my $arcfile = catfile($path, $self->{skelfile});
    my $skeldir = $self->{skeldir};
    my $sharedir = $self->{sharedir};
    
    unless (-e $arcfile) {
        carp "File not found: \"$arcfile\"";
        return 0;
    }
    
    my $ae = Archive::Extract->new( archive => $arcfile );
    return 0 unless $ae;
    
    my $ok = $ae->extract( to => $sharedir );
    
    my $fromd = catdir($sharedir, 'skel');
    unless (dirmove($fromd, $skeldir)) {
        carp "Can't move \"$fromd\" to \"$skeldir\"";
        $ok = 0;
    }
    
    return $ok;
}
sub checkstatus {
    my $self = shift;
    return 1 if $self->{ls} && @{($self->{ls})};
    return 0;
}
sub build {
    my $self = shift;
    my $path = shift || $self->{tmpdir};
    my $skeldir = $self->{skeldir};
    my $arcfile = catfile($path, $self->{skelfile});
    
    my $st = $self->download($path) && $self->extract($path) ? 1 : 0;
    $self->{ls} = _get_ls($skeldir) if $st;
    
    unlink $arcfile if -e $arcfile;
    
    return $self->checkstatus;
}
sub readmanifest {
    # Чтение MANIFEST-файла и возврат прочтеного результата в виде хэша с ключем = записю MANIFEST 
    # и значением = пути до файла
    my $self = shift;
    my $cdir = getcwd();
    my $skeldir = $self->{skeldir};
    
    chdir $skeldir;
    
    my @missed = manicheck();
    if (@missed) {
        carp "Files are missing in your kit: ", join ", ", @missed;
    } # else { say "Looks good" }
    
    my $files = maniread();
    $files = {} unless $files && ref($files) eq 'HASH';
    my %outfiles;
    foreach my $k (keys %$files) {
        $outfiles{$k} = catfile($skeldir,$k) unless grep {$k && $_ && $_ eq $k} @missed;
    }
    
    chdir $cdir;
    
    return {%outfiles};
}
sub readsummary {
    # Чтение SUMMARY-файла и возврат прочтеного результата
    my $self = shift;
    my $cdir = getcwd();
    my $skeldir = $self->{skeldir};
    
    chdir $skeldir;
    
    my $summary = fload(SUMMARY);
    unless ($summary) {
        carp "Can't load ".SUMMARY." file";
        $summary = '';
    }

    chdir $cdir;
    
    return $summary;
}

sub _md5 { _digest( "MD5", @_ ) }
sub _sha1 { _digest( "SHA-1", @_ ) }
sub _digest {
    my $s = shift;
    my $f = shift;
    my $d = Digest->new($s);
 
    my $FHD;
    open($FHD, $f) or croak "Can't open \"$f\": $!";
    binmode($FHD);
    my $summ = $d->addfile($FHD)->hexdigest;
    close $FHD;
    return $summ;
}
sub _get_uri {
    my $mirror = shift;
    my $file   = shift;
    my $u = URI->new($mirror);
    my $path = $u->path;
    if ($path) {
        if ($path eq '/') {
            $u->path($file);
        } else {
            my $newpath = $path.'/'.$file;
            $newpath =~ s/\/{2,}/\//g;
            $u->path($newpath);
        }
    } else {
        $u->path($file);
    }
    
    return $u->as_string;
}
sub _get_ls {
    my $p = shift;
    return [] unless $p && -e $p;
    return [ grep {$_ !~ m/^\.+$/} (ls($p)) ]
}

1;

package # hide me from PAUSE
        MPMinus::Helper::Skel::Backward;

use CTK::Util qw/ :API /;
use ExtUtils::MM;

sub get_version { 
    my $mpminusf = '';
    foreach (@INC) {
        my $f = catfile($_,"MPMinus.pm");
        if (-e $f) {
            $mpminusf = $f;
            last;
        }
    }
    my $v = ExtUtils::MM->parse_version($mpminusf);
    croak "Method ExtUtils::MM->parse_version returns false!" unless $v;
    return $v;
}
sub get_make {
    return ExtUtils::MM->new->make();
}

1;

__END__

