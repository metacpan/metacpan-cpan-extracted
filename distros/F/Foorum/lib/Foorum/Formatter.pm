package Foorum::Formatter;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'Exporter';
use Foorum::XUtils qw/config/;
use vars qw/
    @EXPORT_OK
    $has_text_textile $has_ubb_code $has_text_wiki $has_pod_simple $has_uri_find
    /;
@EXPORT_OK = qw/ filter_format /;

sub filter_format {
    my ( $text, $params ) = @_;

    my $format = $params->{format} || 'plain';

    # don't run eval at beginning, run it when required
    if ( 'textile' eq $format and not defined $has_text_textile ) {
        $has_text_textile
            = eval 'use Text::Textile; 1;'; ## no critic (ProhibitStringyEval)
    }
    if ( 'ubb' eq $format and not defined $has_ubb_code ) {
        $has_ubb_code
            = eval 'use Foorum::Formatter::BBCode2; 1;';    ## no critic
        ## no critic (ProhibitStringyEval)
    }
    if ( 'wiki' eq $format and not defined $has_text_wiki ) {
        $has_text_wiki = eval 'use Text::GooglewikiFormat; 1;';   ## no critic
        ## no critic (ProhibitStringyEval)
    }
    if ( 'pod' eq $format and not defined $has_pod_simple ) {
        $has_pod_simple = eval 'use Foorum::Formatter::Pod; 1;';  ## no critic
        ## no critic (ProhibitStringyEval)
    }

    if ( 'textile' eq $format and $has_text_textile ) {
        my $formatter = Text::Textile->new();
        $formatter->charset('utf-8');
        $text = $formatter->process($text);
    } elsif ( 'ubb' eq $format and $has_ubb_code ) {
        my $formatter
            = Foorum::Formatter::BBCode2->new( { linebreaks => 1 } );
        $text = $formatter->parse($text);

        # emot
        if ( $text =~ /\:\w{2,9}\:/s ) {
            my @emot_icon = (
                'wink',     'sad',      'biggrin', 'cheesy',
                'confused', 'cool',     'angry',   'sads',
                'smile',    'smiled',   'unhappy', 'dozingoff',
                'blink',    'blush',    'crazy',   'cry',
                'bigsmile', 'inlove',   'notify',  'shifty',
                'sick',     'sleeping', 'sneaky2', 'tounge',
                'unsure',   'wacko',    'why',     'wow',
                'mad',      'Oo'
            );
            my $config   = config();
            my $emot_url = $config->{dir}->{images} . '/bbcode/emot';
            foreach my $em (@emot_icon) {
                next unless ( $text =~ /\:$em\:/s );
                $text =~ s/\:$em\:/\<img src=\"$emot_url\/$em.gif\"\>/sg;
                last unless ( $text =~ /\:\w{2,9}\:/s );
            }
        }
    } elsif ( 'pod' eq $format and $has_pod_simple ) {
        my $pod_format = Foorum::Formatter::Pod->new;
        $text = $pod_format->format($text);
    } elsif ( 'wiki' eq $format and $has_text_wiki ) {
        $text =~ s/&/&amp;/gs;
        $text =~ s/>/&gt;/gs;
        $text =~ s/</&lt;/gs;

        # replace link sub
        my $linksub = sub {
            my ( $link, $opts ) = @_;
            $opts ||= {};

            my $ori_text = $link;
            ( $link, my $title )
                = Text::GooglewikiFormat::find_link_title( $link, $opts );
            ( $link, my $is_relative )
                = Text::GooglewikiFormat::escape_link( $link, $opts );
            unless ($is_relative) {
                return qq|<a href="$link" rel="nofollow">$title</a>|;
            } else {
                return $ori_text;
            }
        };
        my %tags = %Text::GooglewikiFormat::tags;
        $tags{link} = $linksub;
        $text = Text::GooglewikiFormat::format( $text, \%tags );
    } elsif ( 'html' eq $format ) {

        # do nothing? XXX? should we linebreak HTML?
    } else {
        $text =~ s/&/&amp;/gs;    # no_html
        $text =~ s|<|&lt;|gs;
        $text =~ s|>|&gt;|gs;

        #$text =~ s/'/&apos;/g; #'
        #$text =~ s/"/&quot;/g; #"
        $text =~ s|\n|<br />\n|gs;    # linebreaks

        $has_uri_find = eval 'use URI::Find::UTF8; 1;'    ## no critic
            ## no critic (ProhibitStringyEval)
            if ( not defined $has_uri_find );
        if ($has_uri_find) {

            # find URIs
            my $finder = URI::Find::UTF8->new(
                sub {
                    my ( $uri, $orig_uri ) = @_;
                    return qq|<a href="$uri" rel="nofollow">$orig_uri</a>|;
                }
            );
            $finder->find( \$text );
        }
    }

    return $text;
}

1;
__END__

=pod

=head1 NAME

Foorum::Formatter - format content for Foorum

=head1 SYNOPSIS

  use Foorum::Formatter qw/filter_format/;
  
  my $text = q~ :inlove: [b]Test[/b] [size=14]dsadsad[/size] [url=http://fayland/]da[/url]~;
  my $html = filter($text, { format => 'ubb' } );
  print $html;
  # <img src="/static/images/bbcode/emot/inlove.gif"> <span style="font-weight:bold">Test</span> <span style="font-size:14px">dsadsad</span> <a href="http://fayland/">da</a>

=head1 SEE ALSO

L<HTML::BBCode>, L<Text::Textile>, L<Text::GooglewikiFormat>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
