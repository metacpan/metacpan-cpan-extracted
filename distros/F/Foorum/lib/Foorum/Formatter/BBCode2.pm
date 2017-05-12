package Foorum::Formatter::BBCode2;

use strict;
use warnings;

our $VERSION = '1.001000';

use strict;
use warnings;

our @bbcode_tags
    = qw(code quote b u i color size list url email img font align flash music video);

sub new {
    my ( $class, $args ) = @_;
    $args ||= {};
    $class->_croak('Options must be a hash reference')
        if ref($args) ne 'HASH';
    my $self = {};
    bless $self, $class;
    $self->_init($args) or return;

    return $self;
}

sub _init {
    my ( $self, $args ) = @_;

    my %html_tags = (
        code => '<div class="bbcode_code_header">Code:</div>'
            . '<div class="bbcode_code_body">%s</div>',
        quote => '<div class="bbcode_quote_header">%s</div>'
            . '<div class="bbcode_quote_body">%s</div>',
        b         => '<span style="font-weight:bold">%s</span>',
        u         => '<span style="text-decoration:underline;">%s</span>',
        i         => '<span style="font-style:italic">%s</span>',
        color     => '<span style="color:%s">%s</span>',
        size      => '<span style="font-size:%spt">%s</span>',
        url       => '<a href="%s">%s</a>',
        email     => '<a href="mailto:%s">%s</a>',
        img       => '<img src="%s" alt="" />',
        ul        => '<ul>%s</ul>',
        ol_number => '<ol>%s</ol>',
        ol_alpha  => '<ol style="list-style-type:lower-alpha;">%s</ol>',

        font  => '<span style="font-family: %s">%s</span>',
        align => '<div style="text-align: %s">%s</div>',
        flash =>
            q!<div class='bbcode_flash'><embed src="%s" type="application/x-shockwave-flash"  width="425" height="344"></embed></div>!,

    );

    my %options = (
        allowed_tags => \@bbcode_tags,
        html_tags    => \%html_tags,
        stripscripts => 1,
        linebreaks   => 0,
        %{$args},
    );
    $self->{options} = \%options;

    return $self;
}

# Parse the input!
sub parse {
    my ( $self, $bbcode ) = @_;
    return if ( !defined $bbcode );

    $self->{_stack}            = ();
    $self->{_in_code_block}    = 0;
    $self->{_skip_nest}        = '';
    $self->{_nest_count}       = 0;
    $self->{_nest_count_stack} = 0;
    $self->{_dont_nest}        = [ 'code', 'url', 'email', 'img' ];
    $self->{bbcode}            = '';
    $self->{html}              = '';

    $self->{bbcode} = $bbcode;
    my $input = $bbcode;

main:
    while (1) {

        # End tag
        if ( $input =~ /^(\[\/[^\]]+\])/s ) {
            my $end = lc $1;
            if ((      $self->{_skip_nest} ne ''
                    && $end ne "[/$self->{_skip_nest}]"
                )
                || ( $self->{_in_code_block} && '[/code]' ne $end )
                ) {
                _content( $self, $end );
            } else {
                _end_tag( $self, $end );
            }
            $input = $';
        }

        # Opening tag
        elsif ( $input =~ /^(\[[^\]]+\])/s ) {
            if ( $self->{_in_code_block} ) {
                _content( $self, $1 );
            } else {
                _open_tag( $self, $1 );
            }
            $input = $';
        }

        # None BBCode content till next tag
        elsif ( $input =~ /^([^\[]+)/s ) {
            _content( $self, $1 );
            $input = $';
        }

        # BUG #14138 unmatched bracket, content till end of input
        elsif ( $input =~ /^(.+)$/s ) {
            _content( $self, $1 );
            $input = $';
        }

        # Now what?
        else {
            last main if ( !$input );    # We're at the end now, stop parsing!
        }
    }
    $self->{html} = join( '', @{ $self->{_stack} } );
    return $self->{html};
}

sub _open_tag {
    my ( $self, $open ) = @_;
    my ( $tag, $rest )
        = $open =~ m/\[([^=\]]+)(.*)?\]/s;    # Don't do this! ARGH!
    $tag = lc $tag;
    if ( _dont_nest( $self, $tag ) && 'img' eq $tag ) {
        $self->{_skip_nest} = $tag;
    }
    if ( $self->{_skip_nest} eq $tag ) {
        $self->{_nest_count}++;
        $self->{_nest_count_stack}++;
    }
    $self->{_in_code_block}++ if ( 'code' eq $tag );
    push @{ $self->{_stack} }, '[' . $tag . $rest . ']';
}

sub _content {
    my ( $self, $content ) = @_;
    $content =~ s|\r*||gs;
    $content =~ s|\n|<br />\n|gs
        if ( $self->{options}->{linebreaks}
        && $self->{_in_code_block} == 0 );
    push @{ $self->{_stack} }, $content;
}

sub _end_tag {
    my ( $self, $end ) = @_;
    my ( $tag, $arg );
    my @buf = ($end);

    if ( "[/$self->{_skip_nest}]" eq $end && $self->{_nest_count} > 1 ) {
        push @{ $self->{_stack} }, $end;
        $self->{_nest_count}--;
        return;
    }

    $self->{_in_code_block} = 0 if ( '[/code]' eq $end );

    # Loop through the stack
    while (1) {
        my $item = pop( @{ $self->{_stack} } );
        push @buf, $item;

        if ( !defined $item ) {
            map { push @{ $self->{_stack} }, $_ if ($_) } reverse @buf;
            last;
        }

        if ( "[$self->{_skip_nest}]" eq "$item" ) {
            $self->{_nest_count_stack}--;
            next if ( $self->{_nest_count_stack} > 0 );
        }

        $self->{_nest_count}--
            if ( "[/$self->{_skip_nest}]" eq $end
            && $self->{_nest_count} > 0 );

        if ( $item =~ /\[([^=\]]+).*\]/s ) {
            $tag = $1;
            if ( $tag && $end eq "[/$tag]" ) {
                push @{ $self->{_stack} },
                    ( _is_allowed( $self, $tag ) )
                    ? _do_BB( $self, @buf )
                    : reverse @buf;

                # Clear the _skip_nest?
                $self->{_skip_nest} = ''
                    if ( defined $self->{_skip_nest}
                    && $tag eq $self->{_skip_nest} );
                last;
            }
        }
    }
    $self->{_nest_count_stack} = 0;
}

sub _do_BB {
    my ( $self, @buf ) = @_;
    my ( $tag, $attr );
    my $html;

    # Get the opening tag
    my $open = pop(@buf);

    # We prefer to read in non-reverse way
    @buf = reverse @buf;

    # Closing tag is kinda useless, pop it
    pop(@buf);

    # Rest should be content;
    my $content = join( ' ', @buf );

    # What are we dealing with anyway? Any attributes maybe?
    if ( $open =~ /\[([^=\]]+)=?([^\]]+)?]/ ) {
        $tag  = $1;
        $attr = $2;
    }

    # custom
    if ( 'music' eq $tag ) {

        # patch for music
        if ( $content =~ /\.(ram|rmm|mp3|mp2|mpa|ra|mpga)$/ ) {
            $html
                = qq!<div><embed name="rplayer" type="audio/x-pn-realaudio-plugin" src="$content" 
controls="StatusBar,ControlPanel" width='320' height='70' border='0' autostart='flase'></embed></div>!;
        } elsif ( $content =~ /\.(rm|mpg|mpv|mpeg|dat)$/ ) {
            $html
                = qq!<div><embed name="rplayer" type="audio/x-pn-realaudio-plugin" src="$content" 
controls="ImageWindow,StatusBar,ControlPanel" width='352' height='288' border='0' autostart='flase'></embed></div>!;
        } elsif ( $content =~ /\.(wma|mpa)$/ ) {
            $html
                = qq!<div><embed type="application/x-mplayer2" pluginspage="http://www.microsoft.com/Windows/Downloads/Contents/Products/MediaPlayer/" src="$content" name="realradio" showcontrols='1' ShowDisplay='0' ShowStatusBar='1' width='480' height='70' autostart='0'></embed></div>!;
        } elsif ( $content =~ /\.(asf|asx|avi|wmv)$/ ) {
            $html
                = qq!<div><object id="videowindow1" width="480" height="330" classid="CLSID:6BF52A52-394A-11D3-B153-00C04F79FAA6"><param NAME="URL" value="$content"><param name="AUTOSTART" value="0"></object></div>!;
        }

        return $html;
    } elsif ( 'video' eq $tag ) {
        if ( $content =~ /^http\:\/\/www.youtube.com\/v\// ) {
            $html
                = qq!<div><embed src="$content" type="application/x-shockwave-flash" allowfullscreen="true" width="425" height="344"></embed></div>!;
        }
        return $html;
    } elsif ( 'size' eq $tag ) {
        $attr = 8  if ( $attr < 8 );    # validation
        $attr = 16 if ( $attr > 16 );
        $html = sprintf( $self->{options}->{html_tags}->{size}, $attr,
            $content );
        return $html;
    }

    # Kludgy way to handle specific BBCodes ...
    if ( 'quote' eq $tag ) {
        $html = sprintf( $self->{options}->{html_tags}->{quote},
            ($attr)
            ? "$attr wrote:"
            : 'Quote:', $content );
    } elsif ( 'code' eq $tag ) {
        $html = sprintf( $self->{options}->{html_tags}->{code},
            _code($content) );
    } elsif ( 'list' eq $tag ) {
        $html = _list( $self, $attr, $content );
    } elsif ( ( 'email' eq $tag || 'url' eq $tag ) && !$attr ) {
        $html = sprintf( $self->{options}->{html_tags}->{$tag},
            $content, $content );
    } elsif ($attr) {
        $attr =~ s/^(.*?)[\"\'].*?$/$1/isg;
        $html = sprintf( $self->{options}->{html_tags}->{$tag}, $attr,
            $content );
    } else {
        $html = sprintf( $self->{options}->{html_tags}->{$tag}, $content );
    }

    # Return ...
    return $html;
}

sub _is_allowed {
    my ( $self, $check ) = @_;
    map { return 1 if ( $_ eq $check ); }
        @{ $self->{options}->{allowed_tags} };
    return 0;
}

sub _dont_nest {
    my ( $self, $check ) = @_;
    map { return 1 if ( $_ eq $check ); } @{ $self->{_dont_nest} };
    return 0;
}

sub _code {
    my $code = shift;
    $code =~ s|^\s+?[\n\r]+?||;
    $code =~ s|<|\&lt;|g;
    $code =~ s|>|\&gt;|g;
    $code =~ s|\[|\&#091;|g;
    $code =~ s|\]|\&#093;|g;
    $code =~ s| |\&nbsp;|g;
    $code =~ s|\n|<br />|g;
    return $code;
}

sub _list {
    my ( $self, $attr, $content ) = @_;
    $content =~ s|^<br />[\s\r\n]*|\n|s;
    $content =~ s|\[\*\]([^(\[]+)|_list_removelastbr($1)|egs;
    $content =~ s|<br />$|\n|s;
    if ($attr) {
        return sprintf( $self->{options}->{html_tags}->{ol_number}, $content )
            if ( $attr =~ /^\d/ );
        return sprintf( $self->{options}->{html_tags}->{ol_alpha}, $content )
            if ( $attr =~ /^\D/ );
    } else {
        return sprintf( $self->{options}->{html_tags}->{ul}, $content );
    }
}

sub _list_removelastbr {
    my $content = shift;
    $content =~ s|<br />[\s\r\n]*$||;
    $content =~ s|^\s*||;
    $content =~ s|\s*$||;
    return "<li>$content</li>\n";
}

sub _croak {
    my ( $class, @error ) = @_;
    require Carp;
    Carp::croak(@error);
}

1;
