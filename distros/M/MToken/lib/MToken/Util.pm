package MToken::Util; # $Id: Util.pm 69 2019-06-09 16:17:44Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MToken::Util - Exported utility functions

=head1 VERSION

Version 1.01

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

=item B<explain>

    print explain( $object );

Returns Data::Dumper dump

=item B<md5sum>

    my $md5 = md5sum( $file );

See L<Digest::MD5>

=item B<sha1sum>

    my $sha1 = sha1sum( $file );

See L<Digest::SHA1>

=item B<filesize>

    my $fsize = filesize( $file );

Returns file size

=item B<hide_pasword>

    print hide_pasword('http://user:password@example.com'); # 'http://user:*****@example.com'

Returns specified URL but without password

=item B<blue>, B<cyan>, B<green>, B<red>, B<yellow>

    print cyan("Format %s", "text");

Returns colored string

=item B<nope>, B<skip>, B<wow>, B<yep>

    my $status = nope("Format %s", "text");

Prints status message and returns status.

For nope returns - 0; for skip, wow, yep - 1

=item B<parse_credentials>

    my ($user, $password) = parse_credentials( 'http://user:password@example.com' );
    my ($user, $password) = parse_credentials( new URI('http://user:password@example.com') );

Returns credentials pair by URL or URI object

=item B<tcd_load>

    if (my $text = tcd_load("/my/file.tcd")) {
        print $text; # Blah-Blah-Blah
    } else {
        or die("Oops");
    }

Load text data from TCD04 file

=item B<tcd_save>

    tcd_save("/my/file.tcd", "Blah-Blah-Blah") or die("Oops");

Save text data to TCD04 file

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<Digest::MD5>, L<Digest::SHA1>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION @EXPORT_OK @EXPORT /;
$VERSION = "1.01";

use Carp;
use CTK::Util qw/bload bsave/;
use CTK::Crypt::TCD04;
use URI;
use URI::Escape qw/uri_unescape/;
use Digest::MD5;
use Digest::SHA1;
use Data::Dumper; #$Data::Dumper::Deparse = 1;
use Term::ANSIColor qw/colored/;

use base qw/Exporter/;
@EXPORT = qw(
        yep nope skip wow
        blue green red yellow cyan
    );
@EXPORT_OK = (qw(
        cleanServerName cleanFileName
        filesize md5sum sha1sum
        parse_credentials hide_pasword
		tcd_save tcd_load
        explain
    ), @EXPORT);

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
sub parse_credentials {
    my $url = shift || return ();
    my $uri = (ref($url) eq 'URI') ? $url : URI->new($url);
    my $info = $uri->userinfo() // "";
    my $user = $info;
    my $pass = $info;
    $user =~ s/:.*//;
    $pass =~ s/^[^:]*://;
    return (uri_unescape($user // ''), uri_unescape($pass // ''));
}
sub hide_pasword {
    my $url = shift || return "";
	my $full = shift || 0;
	my $uri = new URI($url);
	my ($u,$p) = parse_credentials($uri);
	return $url unless defined($p) && length($p);
	$uri->userinfo($full ? undef : sprintf("%s:*****", $u));
    return $uri->canonical->as_string;
}
sub tcd_save {
	my $fn = shift;
	my $text = shift // '';
	carp("No file specified") unless $fn;
	return unless length $text;
	bsave($fn, CTK::Crypt::TCD04->new()->encrypt($text))
		or carp("Can't save file \"$fn\"");
	return 1;
}
sub tcd_load {
	my $fn = shift;
	carp("No file specified") unless $fn;
	return unless -f $fn and -r _ and -s _;
	return CTK::Crypt::TCD04->new()->decrypt(bload($fn) // '');
}
sub explain {
    my $dumper = new Data::Dumper( [shift] );
    $dumper->Indent(1)->Terse(1);
    $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
    return $dumper->Dump;
}

################
# Colored says
################
sub yep {
    print(green('[  OK  ]'), ' ', sprintf(shift, @_), "\n");
    return 1;
}
sub nope {
    print(red('[ FAIL ]'), ' ', sprintf(shift, @_), "\n");
    return 0;
}
sub skip {
    print(yellow('[ SKIP ]'), ' ', sprintf(shift, @_), "\n");
    return 1;
}
sub wow {
    print(blue('[ INFO ]'), ' ', sprintf(shift, @_), "\n");
    return 1;
}
# Colored helper functions
sub green {  colored(['bright_green'],  sprintf(shift, @_)) }
sub red {    colored(['bright_red'],    sprintf(shift, @_)) }
sub yellow { colored(['bright_yellow'], sprintf(shift, @_)) }
sub cyan {   colored(['bright_cyan'],   sprintf(shift, @_)) }
sub blue {   colored(['bright_blue'],   sprintf(shift, @_)) }

1;
