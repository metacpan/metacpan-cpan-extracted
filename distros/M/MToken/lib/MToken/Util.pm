package MToken::Util; # $Id: Util.pm 51 2017-08-02 03:44:49Z minus $
use strict;

=head1 NAME

MToken::Util - Exported utility functions

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use MToken::Util;

=head1 DESCRIPTION

Exported utility functions

=over

=item B<cleanServerName>

    my $servername = cleanServerName( "my.server.com" );

Clening the specified ServerName value

=item B<cleanFileName>

    my $filename = cleanServerName( "mtoken.12345678" );

Clening the specified FileName value

=item B<which>

    my $ls = which( "ls" );

Get full path to specified command. Based on File::Which

=item B<where>

    my @ls = which( "ls" );

Get all full paths to specified command. Based on File::Which

=item B<md5sum>

    my $md5 = md5sum( $file );

See L<Digest::MD5>

=item B<sha1sum>

    my $sha1 = sha1sum( $file );

See L<Digest::SHA1>

=item B<filesize>

    my $fsize = filesize( $file );

Returns file size

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>, C<openssl>, C<gnupg>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<CTK>, L<File::Which>

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

use vars qw/ $VERSION @EXPORT @EXPORT_OK /;
$VERSION = "1.00";

use CTK::Util qw/:ALL/;
use List::MoreUtils qw/uniq/;
use Digest::MD5;
use Digest::SHA1;

use base qw/Exporter/;
@EXPORT = qw(
        which where
        cleanServerName cleanFileName
        filesize md5sum sha1sum
    );
@EXPORT_OK = @EXPORT;

sub which {
    # Based on File::Which
    my $cs = shift;
    my $wh = shift;
    return undef unless defined $cs;
    return undef if $cs eq '';
    my @aliases = ($cs);
    if (isostype('Windows')) {
        my @pext = (qw/.com .exe .bat/);
        if ($ENV{PATHEXT}) {
            push @pext, split /\s*\;\s*/, lc($ENV{PATHEXT});
        }
        push @aliases, $cs.$_ for (uniq(@pext));
    }
    my @path = path();
    unshift @path, curdir;

    my @arr = ();
    foreach my $p ( @path ) {
        foreach my $f ( @aliases ) {
            my $file = catfile($p, $f);
            next if -d $file;
            if (isostype('Windows')) {
                if (-e $file) {
                    my $nospcsf = ($file =~ /\s/) ? sprintf("\"%s\"", $file) : $file;
                    if ($wh) {push @arr, $nospcsf} else {return $nospcsf}
                }
            } elsif (isostype('Unix')) {
                if (-e $file and -x _) {
                    if ($wh) {push @arr, $file} else {return $file}
                }
            } else {
                if (-e $file) {
                    if ($wh) {push @arr, $file} else {return $file}
                }
            }
        }
    }
    return @arr if $wh;
    return undef;
}
sub where { which(shift,1) }
sub cleanServerName {
    my $sn = shift // 'localhost';
    $sn =~ s/[^a-z0-9_\-.]//ig;
    return $sn;
}
sub cleanFileName {
    my $f = shift // '';
    $f =~ s/[^a-z0-9_\-.]//ig;
    return $f;
}
sub sha1sum {
    my $f = shift;
    my $sha1 = new Digest::SHA1;
    my $sum = '';
    return $sum unless -e $f;
    open( my $sha1_fh, '<', $f) or (carp("Can't open '$f': $!") && return $sum);
    if ($sha1_fh) {
        binmode($sha1_fh);
        $sha1->addfile($sha1_fh);
        $sum = $sha1->hexdigest;
        close($sha1_fh);
    }
    return $sum;
}
sub md5sum {
    my $f = shift;
    my $md5 = new Digest::MD5;
    my $sum = '';
    return $sum unless -e $f;
    open( my $md5_fh, '<', $f) or (carp("Can't open '$f': $!") && return $sum);
    if ($md5_fh) {
        binmode($md5_fh);
        $md5->addfile($md5_fh);
        $sum = $md5->hexdigest;
        close($md5_fh);
    }
    return $sum;
}
sub filesize {
    my $f = shift;
    my $filesize = 0;
    $filesize = (stat $f)[7] if -e $f;
    return $filesize;
}

1;
