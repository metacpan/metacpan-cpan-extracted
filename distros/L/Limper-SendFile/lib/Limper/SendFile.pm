package Limper::SendFile;
$Limper::SendFile::VERSION = '0.005';
use base 'Limper';
use 5.10.0;
use strict;
use warnings;

package		# newline because Dist::Zilla::Plugin::PkgVersion and PAUSE indexer
  Limper;

use Time::Local 'timegm';

push @Limper::EXPORT, qw/public send_file/;
push @Limper::EXPORT_OK, qw/mime_types parse_date/;

my %mime_types = map { chomp; split /\t/; } (<DATA>);

sub mime_types { \%mime_types }

my $public = './public/';

sub public {
    if (defined wantarray) { $public } else { ($public) = @_ }
}

# parse whatever crappy date a client might give
my @months = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
sub parse_date {
    my ($d, $m, $y, $h, $n, $s) = $_[0] =~ qr/^(?:\w+), (\d\d)[ -](\w+)[ -](\d\d(?:\d\d)?) (\d\d):(\d\d):(\d\d) GMT$/;
    ($m, $d, $h, $n, $s, $y) = $_[0] =~ qr/^(?:\w+) (\w+) ([ \d]\d) (\d\d):(\d\d):(\d\d) (\d{4})$/ unless defined $d;
    return 0 unless defined $d;
    timegm( $s, $n, $h, $d, (grep { $months[$_] eq $m } 0..$#months)[0], $y + (length $y == 2 ? 1900 : 0) );
}

# support If-Modified-Since and If-Unmodified-Since
hook after => sub {
    my ($request, $response) = @_;
    if ($request->{method} // '' eq 'GET' and substr($response->{status} // 200, 0, 1) == 2 and exists $response->{headers}{'Last-Modified'}) {
        for my $since (grep { /if-(?:un)?modified-since/ } keys %{$request->{headers}}) {
            next if $since eq 'if-modified-since' and ($response->{status} // 200) != 200;
            if (parse_date($request->{headers}{$since}) >= parse_date($response->{headers}{'Last-Modified'})) {
                $response->{body} = '';
                $response->{status} = $since eq 'if-modified-since' ? 304 : 412;
            }
        }
    }
};

sub send_file {
    my $file = $_[0] // request->{uri};

    $file =~ s{^/}{$public/};
    if ($file =~ qr{/\.\./}) {
        status 403;
        return 'Forbidden';
    }
    if (-e $file and -r $file) {
        if (-f $file) {
            if (!exists response->{headers}{'Content-Type'} and my ($ext) = $file =~ /\.(\w+)$/) {
                headers 'Content-Type' => $mime_types{$ext} if exists $mime_types{$ext};
            }
            open my $fh, '<', $file;
            headers 'Last-Modified' => rfc1123date((stat($fh))[9]);
            join '', map { $_ } (<$fh>);
        } elsif (-d $file) {
            opendir(my $dh, $file);
            my @files = sort grep { !/^\./ } readdir $dh;
            my $path = request->{uri};
            $path .= '/' unless $path =~ m|/$|;
            @files = map { "<a href=\"$path$_\">$_</a><br>" } @files;
            headers 'Content-Type' => 'text/html';
            join "\n", '<html><head><title>Directory listing of ' . request->{uri} . '</title></head><body>', @files, '</body></html>';
        } else {
            status 500;
            $Limper::reasons->{500};
        }
    } else {
        status 404;
        'This is the void';
    }
}

1;

=for Pod::Coverage

=head1 NAME

Limper::SendFile - add static content support to Limper

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  # order is important:
  use Limper::SendFile;
  use Limper;

  # some other routes

  get qr{^/} => sub {
      send_file;        # sends request->{uri} by default
  };

  limp;

=head1 DESCRIPTION

B<Limper::SendFile> extends L<Limper> to also return actual files. Because sometimes that's needed.

=head1 EXPORTS

The following are all additionally exported by default:

  public send_file

Also exportable:

  mime_types parse_date

=head1 FUNCTIONS

=head2 send_file

Sends either the file name given, or the value of C<< request->{uri} >> if no file name given.

The following as the last defined route will have B<Limper> look for the file as a last resort:

  get qr{^/} => sub { send_file }

B<Content-Type> will be set by file extension if known and header has not already been defined.
Default is B<text/plain>.

=head2 public

Get or set the public root directory. Default is B<./public/>.

  my $public = public;

  public '/var/www/langlang.us/public_html';

=head1 ADDITIONAL FUNCTIONS

=head2 parse_date

Liberally parses whatever date a client might give, returning a Unix timestamp.

  # these all return 784111777
  my $date = parse_date("Sun, 06 Nov 1994 08:49:37 GMT");
  my $date = parse_date("Sunday, 06-Nov-94 08:49:37 GMT");
  my $date = parse_date("Sun Nov  6 08:49:37 1994");

=head2 mime_types

Returns a B<HASH> of file extension / content-type pairs.

=head1 HOOKS

=head2 after

An B<after> hook is created to support B<If-Modified-Since> and B<If-Unmodified-Since>, comparing to B<Last-Modified>.
This runs for all defined routes, not just those using B<send_file>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Ashley Willis E<lt>ashley+perl@gitable.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Limper>

L<Limper::Engine::PSGI>

L<Limper::SendJSON>

=cut

__DATA__
html	text/html
htm	text/html
shtml	text/html
css	text/css
xml	text/xml
gif	image/gif
jpeg	image/jpeg
jpg	image/jpeg
js	application/javascript
atom	application/atom+xml
rss	application/rss+xml

mml	text/mathml
txt	text/plain
jad	text/vnd.sun.j2me.app-descriptor
wml	text/vnd.wap.wml
htc	text/x-component

png	image/png
tif	image/tiff
tiff	image/tiff
wbmp	image/vnd.wap.wbmp
ico	image/x-icon
jng	image/x-jng
bmp	image/x-ms-bmp
svg	image/svg+xml
svgz	image/svg+xml
webp	image/webp

woff	application/font-woff
jar	application/java-archive
war	application/java-archive
ear	application/java-archive
json	application/json
hqx	application/mac-binhex40
doc	application/msword
pdf	application/pdf
ps	application/postscript
eps	application/postscript
ai	application/postscript
rtf	application/rtf
m3u8	application/vnd.apple.mpegurl
xls	application/vnd.ms-excel
eot	application/vnd.ms-fontobject
ppt	application/vnd.ms-powerpoint
wmlc	application/vnd.wap.wmlc
kml	application/vnd.google-earth.kml+xml
kmz	application/vnd.google-earth.kmz
7z	application/x-7z-compressed
cco	application/x-cocoa
jardiff	application/x-java-archive-diff
jnlp	application/x-java-jnlp-file
run	application/x-makeself
pl	application/x-perl
pm	application/x-perl
prc	application/x-pilot
pdb	application/x-pilot
rar	application/x-rar-compressed
rpm	application/x-redhat-package-manager
sea	application/x-sea
swf	application/x-shockwave-flash
sit	application/x-stuffit
tcl	application/x-tcl
tk	application/x-tcl
der	application/x-x509-ca-cert
pem	application/x-x509-ca-cert
crt	application/x-x509-ca-cert
xpi	application/x-xpinstall
xhtml	application/xhtml+xml
xspf	application/xspf+xml
zip	application/zip

bin	application/octet-stream
exe	application/octet-stream
dll	application/octet-stream
deb	application/octet-stream
dmg	application/octet-stream
iso	application/octet-stream
img	application/octet-stream
msi	application/octet-stream
msp	application/octet-stream
msm	application/octet-stream

docx	application/vnd.openxmlformats-officedocument.wordprocessingml.document
xlsx	application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
pptx	application/vnd.openxmlformats-officedocument.presentationml.presentation

mid	audio/midi
midi	audio/midi
kar	audio/midi
mp3	audio/mpeg
ogg	audio/ogg
m4a	audio/x-m4a
ra	audio/x-realaudio

3gpp	video/3gpp
3gp	video/3gpp
ts	video/mp2t
mp4	video/mp4
mpeg	video/mpeg
mpg	video/mpeg
mov	video/quicktime
webm	video/webm
flv	video/x-flv
m4v	video/x-m4v
mng	video/x-mng
asx	video/x-ms-asf
asf	video/x-ms-asf
wmv	video/x-ms-wmv
avi	video/x-msvideo
