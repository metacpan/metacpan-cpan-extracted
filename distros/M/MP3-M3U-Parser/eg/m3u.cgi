#!/usr/bin/perl -w
use strict;
use warnings;
use CGI;
use Cwd;
use Carp qw( croak );
use MP3::M3U::Parser 2.30;

run();

sub run {
    my $output;
    my $cgi = CGI->new;
    my %opt = (
        encoding      => 'ISO-8859-9', # http encoding
        output_format => $cgi->param('xml') ? 'xml' : 'html',
        base_dir      => getcwd || q{.}, # where are your m3u files?
        error         => 'Invalid parameter!',
    );
    my $target = $cgi->param('m3u') ? \&m3u : \&list;
    $target->( \$output, $cgi, \%opt );
    my $head =  $cgi->header(
                    -type    => "text/$opt{output_format}",
                    -charset => $opt{encoding},
                );
    print $head . $output or croak "Can't print to STDOUT: $!";
    return;
}

sub list {
    my($OUT, $cgi, $opt) = @_;
    my $p = $cgi->url;
    opendir DIR, $opt->{base_dir};
    my @m3u = readdir DIR;
    closedir DIR;
    $OUT .= <<"FRAGMENT";
<p style="font-family:Verdana;font-size:14px;font-weight:bold"
   >M3U List</p>
   <pre>
FRAGMENT
    foreach my $file ( sort @m3u ) {
        next if $file !~ m{ [.] m3u \z }xmsi;
        my $name = $file;
        $name =~ s{ [.] m3u \z }{}xmsi;
        my $u = qq~$p?m3u=$name~;
        $OUT .= qq~[ <a href="$u">HTML</a> - <a href="$u&amp;xml=1" target="_blank">XML</a> ] $_~;
    }
    $OUT .= q~</pre>~;
    return;
}

sub m3u {
    my($OUT, $cgi, $opt) = @_;
    my $m3u = $cgi->param('m3u') or return $opt->{error};
    return $opt->{error} if $m3u =~ m{ \A A-Z_a-z_0-9 }xms;
    my $file = sprintf q{%s/%s.m3u}, $opt->{base_dir}, $m3u;
    return $opt->{error} if ! -e $file;
    my $parser = MP3::M3U::Parser->new(-seconds => 'format');
    $parser->parse($file);
    $parser->export(
        -encoding => $opt->{encoding},
        -format   => $opt->{output_format},
        -drives   => 'off',
        -toscalar => \$OUT,
    );
    my $p    = $cgi->url;
    my $link = <<"FRAGMENT";
<p>
    [
        <a href   = "$p"
           style  = "color:#FFFFFF"
           >M3U List</a>

        &nbsp;&nbsp;&nbsp;

        <a href   = "$p?m3u=$m3u&amp;xml=1"
           style  = "color:#FFFFFF"
           target = "_blank"
           >XML</a>
    ]
</p>
FRAGMENT
    $OUT =~ s{<blockquote>}{$link<blockquote>}xms;
    return;
}

1;

__END__
