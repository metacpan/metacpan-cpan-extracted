package HTML::MobileJpCSS;
use strict;
use warnings;
use Carp;
use File::Spec;
use CSS::Tiny;
use HTTP::MobileAgent;

our $VERSION = '0.02';

our %IstyleDoCoMo = (
    '1' => '-wap-input-format:&quot;*&lt;ja:h&gt;&;',
    '2' => '-wap-input-format:&quot;*&lt;ja:hk&gt;&quot;',
    '3' => '-wap-input-format:&quot;*&lt;ja:en&gt;&quot;',
    '4' => '-wap-input-format:&quot;*&lt;ja:n&gt;&quot;',
);

our $StyleMap = {
    'hr' => {
        'text-align' => {
            'I' => 'float', 'S' => 'float',
        },
        'color' => {
            'I' => 'border-color', 'S' => 'border-color',
        },
    },
    'div' => {
        'font-size' => [{
            '10px' => { 'I' => 'font-size:xx-small', 'S' => 'font-size:small',   },
            '16px' => { 'I' => 'font-size:xx-large', 'S' => 'font-size:xx-large',},
        }],
    },
    'span' => {
        'font-size' => [{
            '10px' => { 'I' => 'font-size:xx-small', 'S' => 'font-size:small',    },
            '16px' => { 'I' => 'font-size:xx-large', 'S' => 'font-size:xx-large', },
        }],
    },
    'img' => {
        'text-align' => [{
            'left'  =>  { 'I' => 'float:left',  'S' => 'float:left',  },
            'right' =>  { 'I' => 'float:right', 'S' => 'float:right', },
            'center' => { 'I' => 'float:none',  'S' => 'float:none',  },
        }],
    },
};

sub new {
    my ($class, %args) = @_;
    my $self = bless {%args}, $class;
    $self->_init;
    $self;
}

sub apply {
    my ($self, $content) = @_;
    return $content if $self->{agent}->is_non_mobile;
    return $content if $self->{agent}->is_ezweb && !(map { $self->{$_} } qw/inliner_ezweb css_file css/);

    $content =~ s/(?:\r\n|\n)/\n/g;

    my @css;
    my @link = $content =~ /<link\s.*?rel="stylesheet".*?>/isg;
    for (@link) {
        if (/href="(.+?)"/) {
            my $css = $self->_read_href($1);
            push @css, $css; 
        }
    }
    $content =~ s/<link\s.*?rel="stylesheet".*?>\s*//isg if @link;

    push @css, $self->_read($self->{css_file}) if $self->{css_file};
    push @css, bless $self->{css}, 'CSS::Tiny' if $self->{css};

    my $style = {};
    for my $css (@css) {
        for (keys %$css) {
            if (/^a:(?:link|focus|visited)$/) {
                $style->{pseudo}->{$_} = $style->{pseudo}->{$_}
                    ? { %{$style->{pseudo}->{$_}}, %{$css->{$_}} }
                    : $css->{$_};
            }
            elsif (/^(\#(.+))/) {
                $style->{id}->{$2} = $style->{id}->{$2}
                    ? { %{$style->{id}->{$2}}, %{$css->{$1}} }
                    : $css->{$1};
            }
            elsif (/^(\.(.+))/) {
                $style->{class}->{$2} = $style->{class}->{$2}
                    ? { %{$style->{class}->{$2}}, %{$css->{$1}} }
                    : $css->{$1};
            }
            else {
                $style->{tag}->{$_} = $style->{tag}->{$_}
                    ? { %{$style->{tag}->{$_}}, %{$css->{$_}} }
                    : $css->{$_};
            }
        }
    }

    # pseudo
    if ($style->{pseudo}) {
        my $css = bless $style->{pseudo}, 'CSS::Tiny';
        my $pseudo = $self->{agent}->is_docomo ? "<![CDATA[\n".$css->write_string."]]>" : $css->write_string;
        $content =~ s{<head>(.*)</head>}{<head>$1<style type="text/css">\n$pseudo</style></head>}is;
    }

    # tag
    for my $tag (keys %{$style->{tag}}) {
        my $props = $style->{tag}->{$tag};
        my @node = $content =~ /<$tag[^<>]*?>/isg;
        for my $node (@node) {
            $content = $self->_replace_style($content, $node, $props);
        }
    }

    # id
    for my $id (keys %{$style->{id}}) {
        my $props = $style->{id}->{$id};
        my @node = $content =~ /<[^<>]+?id="$id"[^<>]*?>/isg;
        for my $node (@node) {
            $content = $self->_replace_style($content, $node, $props);            
        }
    }

    # class
    for my $class (keys %{$style->{class}}) {
        my $props = $style->{class}->{$class};
        my @node = $content =~ /<[^<>]+?\sclass="$class"[^<>]*?>/isg;
        for my $node (@node) {
            $content = $self->_replace_style($content, $node, $props);
        }
        $content =~ s/<([^<>]+?)\sclass="$class"([^<>]*?)>/<$1$2>/isg;
    }

    # istyle for DoCoMo
    if ($self->{agent}->is_docomo) {
        $content =~ s/(<input[^>]*?)(istyle="(\d)")([^>]*?>)/$1style="$IstyleDoCoMo{$3}"$4/isg;
        $content =~ s/(<textarea[^>]*?)(istyle="(\d)")([^>]*?>)/$1style="$IstyleDoCoMo{$3}"$4/isg;
    }
    return $content;
}

sub _init {
    my $self = shift;
    if ($self->{agent}) {
        $self->{agent} = HTTP::MobileAgent->new($self->{agent}) unless (ref $self->{agent}) =~ /^HTTP::MobileAgent/;
    }
    else {
        $self->{agent} = HTTP::MobileAgent->new();
    }
}

my %CSS;
sub _read_href {
    my ($self, $href) = @_;
    if ($href !~ m{^https?://}) {
        $href =~ s/\?.+$//;
        $href = File::Spec->catdir($self->{base_dir}, $href);
        return $self->_read($href);
    }
    else {
        return $self->_fetch($href);
    }
}

sub _read {
    my ($self, $path) = @_;
    my $css;
    if ($css = $CSS{$path}) {
        if ($css->{mtime} >= (stat($path))[9]) {
            return $css->{style};
        }
    }
    $css = CSS::Tiny->read($path) 
        or croak "Can't open '$path' by @{[ __PACKAGE__ ]}";
    return unless $css;
    $CSS{$path} = {
        style => $css,
        mtime => (stat($path))[9],
    };
    return $css;
}

sub _fetch {
    my ($self, $url) = @_;
    require LWP::UserAgent;
    my $ua = $self->{_ua} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
    my $res = $ua->get($url);
    if ($res->is_success) {
        my $css = CSS::Tiny->read_string($res->content)
            or croak "Can't parse '$url' by @{[ __PACKAGE__ ]}";
        return $css;
    }
    croak "Can't fetch $url by @{[ __PACKAGE__ ]}";
}

sub _replace_style {
    my ($self, $content, $node, $props) = @_;
    my ($tag) = $node =~ /^<([^\s]+).*?>/is;
    my $replace = $node;
    my $style;
    for (keys %$props) {
        $style .= $self->_filter($tag, $_, $props->{$_});
    }
    if ($node =~ /style=".+?"/) {
        $replace =~ s/(style=".+?)"/$1$style"/is;
    }
    else {
        $replace =~ s/<$tag/<$tag style="$style"/is;
    }
    $replace =~ s/[\n\s]+/ /g;
    $content =~ s/$node/$replace/is;
    return $content;
}

sub _filter {
    my ($self, $tagname, $property, $value) = @_;
    return "$property:$value;" unless $StyleMap->{$tagname};
    return "$property:$value;" unless $StyleMap->{$tagname}->{$property};
    my $style = $StyleMap->{$tagname}->{$property};
    my $carrier = $self->{agent}->carrier;
    $carrier =~ s/^V$/S/;
    $carrier =~ s/^H$/W/;    
    if (ref $style eq 'ARRAY') {
        my $prop = $style->[0]->{$value}->{$carrier};
        return "$prop;" if $prop;
    }
    elsif ($style) {
        my $prop = $style->{$carrier};
        return "$prop:$value;" if $prop;
    }
    return "$property:$value;";
}

1;

__END__

=head1 NAME

HTML::MobileJpCSS - css inliner and converter

=head1 SYNOPSIS

  use HTML::MobileJpCSS;
  my $inliner = HTML::MobileJpCSS->new(base_dir => '/path/to/documentroot/');
  $inliner->apply(<<'...');
  <?xml version="1.0" encoding="Shift_JIS"?>
  <!DOCTYPE html PUBLIC "-//i-mode group (ja)//DTD XHTML i-XHTML(Locale/Ver.=ja/2.1) 1.0//EN"
      "i-xhtml_4ja_10.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
  <head>
    <link rel="stylesheet" href="/css/foo.css" />
  </head>
  <body>
    <div class="title">bar</div>
  </body>
  </html>
  ...

  # foo.css
  .title {
    color: red;
  }

  # result
  <?xml version="1.0" encoding="Shift_JIS"?>
  <!DOCTYPE html PUBLIC "-//i-mode group (ja)//DTD XHTML i-XHTML(Locale/Ver.=ja/2.1) 1.0//EN"
      "i-xhtml_4ja_10.dtd">
  <html>
  <head>
  </head>
  <body>
    <div class="title" style="color:red;">bar</div>
  </body>
  </html>

=head1 DESCRIPTION

HTML::MobileJpCSS is css inliner.

this module is possible the specification of a style based EZweb in each career(DoCoMo,EZweb,Softbank[,Willcom])

=head1 METHODS

=over 4

=item new(%option)
    
constructor of HTML::MobileJpCSS->new();

=over 5

=item agent

HTTP_USER_AGENT or instance of HTTP::MobileAgent (default: instance of HTTP::MobileAgent)

=item inliner_ezweb

inline css when user_agent is EZweb (default: I<none>) 

=item base_dir

concatenate local css file specified with '<link rel="stylesheet" href="/css/foo.css">' (default: I<none>)

  my $inliner = HTML::DoCoMoCSS->new(base_dir => '/path/to');

=item css_file

read css file (default: I<none>)
force inline css when user_agent is EZweb

  my $inliner = HTML::DoCoMoCSS->new(css_file => '/path/to/css/foo.css');

=item css

read css (default: I<none>)
force inline css when user_agent is EZweb

  my $inliner = HTML::DoCoMoCSS->new(css => {'.color-red' => { color => 'blue' });

=back

=item apply($content)

=back

=head1 AUTHOR

Kazunari Komoriya  C<< <kmry1462@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Kazunari Komoriya C<< <komoriya@livedoor.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

L<HTML::DoCoMoCSS>, L<CSS::Tiny>, L<HTTP::MobileAgent>
    
=cut
