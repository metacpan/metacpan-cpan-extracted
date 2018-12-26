package MP3::M3U::Parser::Export;
$MP3::M3U::Parser::Export::VERSION = '2.33';
use strict;
use warnings;

use Carp qw( croak );
use MP3::M3U::Parser::Constants;
use MP3::M3U::Parser::Dummy;

my %DEFAULT = (
    format    => 'html',
    filename  => 'mp3_m3u%s.%s',
    encoding  => 'ISO-8859-1',
    drives    => 'on',
    overwrite => 0,
    toscalar  => 0,
);

sub export {
    my($self, @args) = @_;
    my %opt       = @args % 2 ? () : @args;
    my $format    = $opt{'-format'}    || $self->{expformat}   || $DEFAULT{format   };
    my $encoding  = $opt{'-encoding'}  || $self->{encoding}    || $DEFAULT{encoding };
    my $drives    = $opt{'-drives'}    || $self->{expdrives}   || $DEFAULT{drives   };
    my $overwrite = $opt{'-overwrite'} || $self->{overwrite}   || $DEFAULT{overwrite};
    my $to_scalar = $opt{'-toscalar'}  || $self->{exptoscalar} || $DEFAULT{toscalar };
    my $file      = $opt{'-file'}      || $self->_default_filename( $format );

    $file = $self->_locate_file($file) if ! $to_scalar;
    my $OUTPUT = $format eq 'xml'
               ? $self->_export_to_xml(  $encoding )
               : $self->_export_to_html( $encoding, $drives, $to_scalar, $file)
               ;

    if ( $to_scalar ) {
        ${$to_scalar} = $OUTPUT;
    }
    else {
        my $fh = $self->_check_export_params( $file, $to_scalar, $overwrite );
        print {$fh} $OUTPUT or croak "Can't print to FH: $!";
        $fh->close;
    }

   $self->{EXPORTF}++;
   return $self if defined wantarray;
   return;
}

sub _default_filename {
    my($self, $format) = @_;
    croak 'Export format is missing' if ! $format;
    return sprintf $DEFAULT{filename}, $self->{EXPORTF}, $format;
}

sub _check_export_params {
    my($self, $file, $to_scalar, $overwrite) = @_;
    my $fh;
    if ( $to_scalar && ( ! ref $to_scalar || ref $to_scalar ne 'SCALAR' ) ) {
        croak '-toscalar must be a SCALAR reference';
    }
    if ( ! $to_scalar ) {
        if ( -e $file && ! $overwrite ) {
           croak "The export file '$file' exists & overwrite option is not set";
        }
        require IO::File;
        $fh = IO::File->new;
        $fh->open( $file, '>' )
            or croak "I can't open export file '$file' for writing: $!";
    }
    return $fh;
}

sub _export_to_html {
    my($self, $encoding, $drives, $to_scalar, $file) = @_;
    my $OUTPUT = EMPTY_STRING;
    # I don't think that weird numbers in the html mean anything 
    # to anyone. So, if you didn't want to format seconds in your 
    # code, I'm overriding it here (only for export(); Outside 
    # export(), you'll get the old value):
    my $old_seconds = $self->{seconds};
    $self->{seconds} = 'format';
    my %t;
    @t{ qw( up cd data down ) } = split m{\Q<!-- MP3DATASPLIT -->\E}xms,
                                        $self->_template;
    foreach (keys %t) {
        $t{$_} = $self->_trim( $t{$_} );
    }
    my $tmptime = $self->{TOTAL_TIME} ? $self->_seconds($self->{TOTAL_TIME})
                :                       undef;
    my @tmptime;

    if ($tmptime) {
        @tmptime = split m{:}xms,$tmptime;
        unshift @tmptime, 'Z' if $#tmptime <= 1;
    }

    my $average = $self->{AVERAGE_TIME}
                ? $self->_seconds( $self->{AVERAGE_TIME} )
                : '<i>Unknown</i>'
                ;

    my $HTML = {
        ENCODING    => $encoding,
        SONGS       => $self->{TOTAL_SONGS},
        TOTAL       => $self->{TOTAL_FILES},
        AVERTIME    => $average,
        FILE        => $to_scalar ? EMPTY_STRING : $self->_locate_file($file),
        TOTAL_FILES => $self->{TOTAL_FILES},
        TOTAL_TIME  => @tmptime ? [ @tmptime ]   : EMPTY_STRING,
    };

    $OUTPUT .= $self->_tcompile(template => $t{up}, params=> {HTML => $HTML});
    my($song,$cdrom, $dlen);
    foreach my $cd (@{ $self->{'_M3U_'} }) {
        next if($#{$cd->{data}} < 0);
        $cdrom .= "$cd->{drive}\\" if $drives ne 'off';
        $cdrom .= $cd->{list};
        $OUTPUT .= sprintf $t{cd}."\n", $cdrom;
        foreach my $m3u (@{ $cd->{data} }) {
            $song = $m3u->[ID3];
            if ( ! $song ) {
                my @test_path = split /\\/xms, $m3u->[PATH];
                my $tp        = pop @test_path || $m3u->[PATH];
                my @test_file = split /\./xms, $song;
                $song         = $test_file[0] || $tp;
            }
            $dlen = $m3u->[LEN] ? $self->_seconds($m3u->[LEN]) : '&nbsp;';
            $song = $song       ? $self->_escape($song)        : '&nbsp;';
            $OUTPUT .= sprintf "%s\n", $self->_tcompile(
                                            template => $t{data},
                                            params   => {
                                                data => {
                                                    len  => $dlen,
                                                    song => $song,
                                                }
                                            }
                                        );
        }
        $cdrom = EMPTY_STRING;
    }
    $OUTPUT .= $t{down};
    $self->{seconds} = $old_seconds; # restore
    return $OUTPUT;
}

sub _export_to_xml {
    my($self, $encoding) = @_;
    my $OUTPUT = EMPTY_STRING;
    $self->{TOTAL_TIME} = $self->_seconds($self->{TOTAL_TIME})
                                if $self->{TOTAL_TIME} > 0;
    $OUTPUT .= sprintf qq~<?xml version="1.0" encoding="%s" ?>\n~, $encoding;
    $OUTPUT .= sprintf qq~<m3u lists="%s" songs="%s" time="%s" average="%s">\n~,
                       $self->{TOTAL_FILES},
                       $self->{TOTAL_SONGS},
                       $self->{TOTAL_TIME},
                       $self->{AVERAGE_TIME};
    my $sc = 0;
    foreach my $cd (@{ $self->{'_M3U_'} }) {
        $sc = $#{$cd->{data}}+1;
        next if ! $sc;
        $OUTPUT .= sprintf qq~<list name="%s" drive="%s" songs="%s">\n~,
                            $cd->{list},
                            $cd->{drive},
                            $sc;
        foreach my $m3u (@{ $cd->{data} }) {
            $OUTPUT .= sprintf qq~<song id3="%s" time="%s">%s</song>\n~,
                                $self->_escape( $m3u->[ID3] ) || EMPTY_STRING,
                                $m3u->[LEN]                   || EMPTY_STRING,
                                $self->_escape( $m3u->[PATH] );
        }
        $OUTPUT .= "</list>\n";
        $sc = 0;
    }
    $OUTPUT .= "</m3u>\n";
    return $OUTPUT;
}

# compile template
sub _tcompile {
    my($self, @args) = @_;
    my $class = ref $self;
    croak 'Invalid number of parameters' if @args % 2;
    require Text::Template;
    my %opt = @args;
    my $t   = Text::Template->new(
                TYPE       => 'STRING',
                SOURCE     => $opt{template},
                DELIMITERS => ['<%', '%>'],
            ) or croak "Couldn't construct the template: $Text::Template::ERROR";

    my @globals;
    foreach my $p ( keys %{ $opt{params} } ) {
        my $ref    = ref $opt{params}->{$p};
        my $prefix = $ref eq 'HASH'  ? q{%}
                   : $ref eq 'ARRAY' ? q{@}
                   :                   q{$}
                   ;
        push @globals, $prefix . $p;
    }

    my $text = $t->fill_in(PACKAGE => $class . '::Dummy',
                PREPEND => sprintf('use strict;use vars qw[%s];',
                                    join q{ }, @globals ),
                HASH    => $opt{params},
              ) or croak "Couldn't fill in template: $Text::Template::ERROR";
    return $text;
}

# HTML template code
sub _template {
   return <<'MP3M3UPARSERTEMPLATE';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
   "http://www.w3.org/TR/html4/loose.dtd">
<html>
 <head>
   <title>MP3::M3U::Parser Generated PlayList</title>
   <meta name="Generator" content="MP3::M3U::Parser">
   <meta http-equiv="content-type"
         content="text/html; charset=<%$HTML{ENCODING}%>">

   <style type="text/css">
   <!--
      body   { background   : #000040;
               font-family  : font1, Arial, serif;
               color        : #FFFFFF;
               font-size    : 10pt;    }
      td     { background   : none;
               font-family  : Arial, serif;
               color        : #FFFFFF;
               font-size    : 13px;    }
      hr     { background   : none;
               color        : #FFBF00; }
      .para1 { margin-top   : -42px;
               margin-left  : 350px;
               margin-right : 10px;
               font-family  : font2, Arial, serif;
               font-size    : 30px; 
               line-height  : 35px;
               background   : none;
               color        : #E1E1E1;
               text-align   : left;    }
      .para2 { margin-top   : 15px;
               margin-left  : 15px;
               margin-right : 50px;
               font-family  : font1, Arial Black, serif;
               font-size    : 50px;
               line-height  : 40px;
               background   : none;
               color        : #004080;
               text-align   : left;    }
      .t     { font-family  : Arial, serif;
               background   : none;
               color        : #FFBF00;
               font-size    : 13px;    }
      .ts    { font-family  : Arial, serif;
               color        : #FFBF00;
               background   : none;
               font-size    : 10px;    }
      .s     { font-family  : Arial, serif;
               background   : none;
               color        : #FFFFFF;
               font-size    : 13px;    }
      .info  { font-family  : Arial, serif;
               background   : none;
               color        : #409FFF;
               font-size    : 10px;    }
      .infob { font-family  : Arial, serif;
               background   : none;
               color        : #FFBF00;
               font-size    : 15px;    }
    -->
   </style>

 </head>

<body>

 <div align="center">
  <div class="para2" align="center"><p>MP3::M3U::Parser</p></div>
  <div class="para1" align="center"><p>playlist</p></div>
 </div>

<hr align="left" width="90%" noshade="noshade" size="1">
 <div align="left">

  <table border="0" cellspacing="0" cellpadding="0" width="98%">
   <tr><td>
    <span class="ts"><%$HTML{SONGS}%></span> <span class="info"> tracks and 
    <span class="ts"><%$HTML{TOTAL}%></span> Lists in playlist, 
      average track length: </span> 
      <span class="ts"><%$HTML{AVERTIME}%></span><span class="info">.</span>
     <br>
    <span class="info">Playlist length: </span><%
   my $time;
   if ($HTML{TOTAL_TIME}) {
      my @time = @{$HTML{TOTAL_TIME}};
      $time = qq~<span class="ts"  > $time[0] </span>
                 <span class="info"> hours    </span>~ if $time[0] ne 'Z';
      $time .= qq~
            <span class="ts"  > $time[1] </span>
            <span class="info"> minutes  </span>
            <span class="ts"  > $time[2] </span>
            <span class="info"> seconds. </span>~;
   } else {
      $time = qq~<span class="ts"><i>Unknown</i></span><span class="info">.</span>~;
   }
   $time;

     %><br>
    <% 
      qq~<span class="info">Right-click <a href="file://$HTML{FILE}">here</a>
      to save this HTML file.</span>~ if $HTML{FILE}
    %>
    </td>
   </tr>
 </table>

</div>
<blockquote>
<p><span class="infob"><big><% 
$HTML{TOTAL_FILES} > 1 ? "Playlists and Files" : "Playlist files"; 
%>:</big></span></p>

<table border="0" cellspacing="1" cellpadding="2">

<!-- MP3DATASPLIT -->
<tr><td colspan="2"><b>%s</b></td></tr>
<!-- MP3DATASPLIT -->
<tr><td><span class="t"><%$data{len}%></span></td><td><%$data{song}%></td></tr>
<!-- MP3DATASPLIT -->

  </table>
</blockquote>
<hr align="left" width="90%" noshade size="1">
<span class="s">This HTML File is based on 
<a href="http://www.winamp.com">WinAmp</a>`s HTML List.</span>
</body>
</html>
MP3M3UPARSERTEMPLATE
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MP3::M3U::Parser::Export

=head1 VERSION

version 2.33

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

-

=head1 NAME

MP3::M3U::Parser::Export - Exports playlist to HTML/XML

=head1 METHODS

=head2 export

See C<export> in L<MP3::M3U::Parser>.

=head1 SEE ALSO

L<MP3::M3U::Parser>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
