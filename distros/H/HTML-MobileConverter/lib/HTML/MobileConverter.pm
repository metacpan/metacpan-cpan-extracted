package HTML::MobileConverter;
use strict;
use HTML::Parser;
use URI;

our $VERSION = '0.011';

sub new {
    my $class = shift;
    my $self = {@_};
    bless $self, $class;
    $self->init;
    return $self;
}

sub init {
    my $self = shift;
    $self->{maxlength} ||= 50000;
    $self->{maxpctagcount} ||= 10;
    $self->{maxpctagrate} ||= 0.1;
    $self->{baseuri} or warn 'baseuri is not specified.';
    $self->{hrefhandler} ||= sub {
        my $href = shift;
        return URI->new_abs($href, $self->{baseuri});
    };
    $self->{mobiletag} ||= {
        a => 'name|accesskey|href|cti|ijam|utn|subject|body|telbook|kana|email|ista|ilet|iswf|irst',
        base => 'href',
        blink => '',
        blockquote => '',
        body => 'bgcolor|text|link|alink|vlink',
        br => 'clear',
        center => '',
        dd => '',
        dir => 'type',
        div => 'align',
        dl => '',
        dt => '',
        font => 'color|size',
        form => 'action|method|utn',
        head => '',
        h1 => 'align',
        h2 => 'align',
        h3 => 'align',
        h4 => 'align',
        h5 => 'align',
        h6 => 'align',
        hr => 'align|size|width|noshade|color',
        html => '',
        img => 'src|align|width|height|hspace|vspace|alt',
        input => 'type|name|size|maxlength|accesskey|value|istyle|checked',
        li => 'type|value',
        marquee => 'behavior|direction|loop|height|width|scrollmount|scrolldelay|bgcolor',
        menu => 'type',
        meta => 'http\-equiv|content',
        object => 'declare|id|data|type|width|height',
        ol => 'type|start',
        option => 'selected|value',
        p => 'align',
        param => 'name|value|valuetype',
        plaintext => '',
        pre => '',
        select => 'name|size|multiple',
        textarea => 'name|accesskey|rows|cols|istyle',
        title => '',
        ul => 'type',
    };
    $self->{codetag} = 'script|style';
    $self->{ignoretag} = 'form|input|select|option|textarea';
    $self->{html} = '';
}

sub _initparser {
    my $self = shift;
    $self->{html2} = '';
    $self->{mhtml} = '';
    $self->{tagcount} = 0;
    $self->{mtagcount} = 0;
    $self->{ismobilecontent} = '';
    $self->{iscode} = 0;
    $self->{parser} = HTML::Parser->new(
        api_version => 3,
        handlers => {
            start => [$self->starthandler, 'text, tagname, attr'],
            end => [$self->endhandler, 'text, tagname'],
            text => [$self->texthandler, 'text'],
            default => [$self->defaulthandler, 'event, text'],
        },
    );
}

sub starthandler {
    my $self = shift;
    return sub {
        my ($text, $tag, $attr) = @_;
        $self->{tagcount}++;
        if ($tag =~ /^($self->{codetag})$/i) {
            $self->{iscode}++;
        }
        if (defined $self->{mobiletag}->{$tag}) {
            $self->{mtagcount}++;
            if ($tag =~ /^($self->{ignoretag})$/i) {
                return;
            } else {
                $self->{mhtml} .= $self->_makestartm($tag,$attr);
                $self->{html2} .= $self->_makestart2($tag,$attr);
            }
        }
    };
}

sub _makestartm {
    my $self = shift;
    my $tag = shift or return;
    my $attr = shift or return;
    if ($tag eq 'img') {
        my ($w,$h) = @$attr{'width', 'height'};
        unless ($w && $h && $w < 100 && $h < 100) {
            my $text = 'img:';
            $text .= $attr->{alt} || $attr->{title} || '';
            return $text;
        }
    }
    my $attrpat = $self->{mobiletag}->{$tag};
    my $text = qq|<$tag|;
    for my $key (keys %$attr) {
        if ($key =~ /^(href|action)$/) {
            $text .= qq| $key="| . 
                $self->{hrefhandler}($attr->{$key}) . '"';
        } elsif ($key eq 'src') {
            $text .= qq| $key="|. URI->new_abs($attr->{$key}, $self->{baseuri}) . '"';
        } elsif ($key =~ /^($attrpat)$/i) {
            $text .= qq| $key="$attr->{$key}"|;
        }
    }
    $text .= '>';
    return $text;
}

sub _makestart2 {
    my $self = shift;
    my $tag = shift or return;
    my $attr = shift or return;
    my $text = qq|<$tag|;
    for my $key (keys %$attr) {
        if ($key =~ /^(href|action)$/) {
            $text .= qq| $key="| . 
                $self->{hrefhandler}($attr->{$key}) . '"';
        } elsif ($key eq 'src') {
            $text .= qq| $key="|. URI->new_abs($attr->{$key}, $self->{baseuri}) . '"';
        } else {
            $text .= qq| $key="$attr->{$key}"|;
        }
    }
    $text .= '>';
    return $text;
}

sub endhandler {
    my $self = shift;
    return sub {
        my ($text, $tag) = @_;
        if ($tag =~ /^($self->{codetag})$/i) {
            $self->{iscode}--;
        }
        if (defined $self->{mobiletag}->{$tag}) {
            if ($tag =~ /^($self->{ignoretag})$/i) {
                $text = '';
            } else {
                $self->{mhtml} .= $text;
            }
            $self->{html2} .= $text;
        }
    };
}

sub texthandler {
    my $self = shift;
    return sub {
        my ($text) = @_;
        if (!$self->{iscode}) {
            $self->{mhtml} .= $text;
        }
        $self->{html2} .= $text;
    };
}

sub defaulthandler {
    my $self = shift;
    return sub {};
}

sub convert {
    my $self = shift;
    $self->{html} = shift or return;
    $self->_initparser;
    $self->{parser}->parse($self->{html});
    if ($self->_checkmobile) {
        return $self->{html2};
    } else {
        return $self->{mhtml};
    }
}

sub _checkmobile {
    my $self = shift;
    if ($self->{maxlength} && (length($self->{html}) > $self->{maxlength})) {
        return; # over max size
    } elsif (($self->{tagcount} - $self->{mtagcount}) > $self->{maxpctagcount}) {
        return; # includes many pc tags
    } elsif (!$self->{tagcount}) {
        # do nothing
    } elsif (($self->{mtagcount} / $self->{tagcount}) < (1 - $self->{maxpctagrate})) {
        return; # includes many pc tags
    }
    $self->{ismobilecontent} = 1;
    return $self->ismobilecontent;
}

sub ismobilecontent {
    my $self = shift;
    return $self->{ismobilecontent};
}

sub param { $_[0]->{$_[1]}; }

1;

__END__

=head1 NAME

HTML::MobileConverter - HTML Converter for mobile agent

=head1 SYNOPSIS

  use HTML::MobileConverter;

  my $baseuri = 'http://example.com/';
  my $c = HTML::MobileConverter->new(baseuri => $baseuri);
  my $html =<<END;
  <html><body>title<hr><a href="./my">my link</a></body></html>
  END
  print $c->convert($html); # get html with abs-uri.
  
  use URI;
  $html = <<END;
  <html><body>
  title<hr>
  <a href="./my">my link</a>
  <iframe src="./my"></iframe>
  </body></html>
  END
  $c = HTML::MobileConverter->new(
    baseuri => $baseuri,
    hrefhandler => sub {
      my $href = shift;
      return URI->new_abs($href, 'http://example.com/');
    },
  );
  print $c->convert($html); # get html without iframe.
  
  # create a proxy
  my $q = CGI->new;
  my $html = $c->convert(LWP::Simple:get($q->param('uri')));
  print Jcode->new($html)->sjis;

=head1 DESCRIPTION

HTML::MobileConverter parses HTML and returns new HTML for mobile agent 
(mainly for DoCoMo i-mode).
If the original HTML doesn't contain so many pc tags, it returns the original 
HTML strings with absolute uri (href,src...). If the original was guessed as 
a content for PC, it returns new HTML for mobile agent.

=head1 METHODS

Here are common methods of HTML::MobileConverter.

=over 4

=item new

  $c = HTML::MobileConverter->new;
  $c = HTML::MobileConverter->new(baseuri => 'http://www.example.com/');
  $c = HTML::MobileConverter->new(
    baseuri => 'http://www.example.com/',
    hrefhandler => sub {
      my $href = shift;
      $href = URI->new_abs($href, 'http://www.example.com/');
      return qq|/browse?uri=$href|;
    },
  );

creates a instance of HTML::MobileConverter. If you specify C<baseuri>, 
C<href/src/action> attributes will be replaced with absolute uris.

If you specify C<hrefhandler> with some function, href attribute will
be handled with the handler.

=item convert

  my $mhtml = $c->convert($html);

returns HTML strings for mobile.

=item ismobilecontent

  print "is mobile" if $c->ismobilecontent;

returns which the original HTML was guessed as mobile content or not.

=back

=head1 AUTHOR

Junya Kondo, E<lt>jkondo@hatena.ne.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Junya Kondo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTML::Parser>
http://www.nttdocomo.co.jp/p_s/imode/tag/lineup.html (Japanese)

=cut
