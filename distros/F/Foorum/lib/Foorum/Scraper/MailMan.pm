package Foorum::Scraper::MailMan;

# directly copied from mailman-archive-to-rss
# http://taint.org/mmrss/
# Thanks, Adam Shand

use strict;
use warnings;
our $VERSION = '1.001000';
use HTML::TokeParser;
use LWP::Simple;
use Encode qw/from_to/;
use Encode::Guess qw/euc-cn/;    # XXX? can't explain

sub new {
    my $class = shift;
    my $self  = {};

    return bless $self => $class;
}

sub scraper {
    my ( $self, $url ) = @_;

    my $html = get($url);
    unless ($html) {
        return;
    }

    my $urlbase = $url;
    $urlbase =~ s,/[^/]+$,/,gs;
    $self->{url_base} = $urlbase;

    my $ret = $self->extract_from_thread($html);

    foreach (@$ret) {
        my $details = get( $_->{url} );
        if ($details) {
            ( $_->{when}, $_->{text} )
                = $self->extract_from_message($details);
        }
    }

    return $ret;
}

sub extract_from_thread {
    my ( $self, $html ) = @_;

    my $stream = HTML::TokeParser->new( \$html ) or die $!;

    my @posts = ();
    my $nest  = 0;
    while ( my $tag = $stream->get_tag( 'li', 'ul', '/ul' ) ) {

        $tag = $stream->get_tag('a');
        my $url = $tag->[1]{href} || '--';

        # only follow Mailman-style numeric links
        next unless ( $url =~ /(\d+|msg\d+)\.html$/ );
        my $msg_id = $1;
        $msg_id =~ s/\D+//isg;

        $url = $self->{url_base} . $url;

        my $headline = $stream->get_trimmed_text('/a');
        $headline =~ s/&/&amp;/g;
        $headline =~ s/</&lt;/g;
        $headline =~ s/>/&gt;/g;
        $headline =~ s/^\s*\[\w+\]\s*//;

        $tag = $stream->get_tag('i');
        my $who = $stream->get_trimmed_text('/i');
        $who =~ s/<.*?>//g;
        $who =~ s/\&lt;.*?\&gt;//ig;
        $who =~ s/\&/\&amp;/g;
        $who =~ s/</\&lt;/g;
        $who =~ s/>/\&gt;/g;

        push(
            @posts,
            {   url    => $url,
                title  => $headline,
                who    => $who,
                msg_id => $msg_id,
            }
        );
    }

    return \@posts;
}

sub extract_from_date {
    my ( $self, $html ) = @_;

}

sub extract_from_message {
    my ( $self, $html ) = @_;

    my $stream = HTML::TokeParser->new( \$html ) or die $!;

    my $tag  = $stream->get_tag('i');
    my $when = $stream->get_text('/i');

    $tag = $stream->get_tag('pre');
    my $text = $stream->get_text('/pre');

    my $enc = Encode::Guess->guess($text);
    my $encoding;
    if ( ref($enc) ) {
        $encoding = $enc->name;
    }
    if ( $encoding and 'utf8' ne $encoding ) {
        from_to( $text, $encoding, 'utf8' );
    }

    #$text = mail_body_to_abstract($text);
    return ( $when, $text );
}

sub mail_body_to_abstract {
    my $text = shift;
    local ($_);

    # strip quoted text, replace with \002
    # This is tricky, to catch the "> quote blah chopped\nin mail\n" case
    my $newtext      = '';
    my $lastwasquote = 0;
    my $lastwasblank = 0;

    foreach ( split( /^/, $text ) ) {
        s/^<\/I>//gi;

        if (/^\s*$/) {
            $lastwasblank = 1;
            $newtext .= "\n";
            next;
        } else {
            $lastwasblank = 0;
        }

        if (/^\s*\S*\s*(?:>|\&gt;)/i) {
            $lastwasquote = 1;
            $newtext .= "\002";
            next;
        } else {
            if ( $lastwasquote && !$lastwasblank && length($_) < 20 ) {
                next;
            }
            $newtext .= $_;
            $lastwasquote = 0;
        }
    }
    $text = $newtext;

    # collapse \002's into 1 [...]
    $text =~ s/\s*\002[\002\s]*/\n\n[...]\n\n/igs;

    # PGP header
    $text =~ s/-----BEGIN PGP SIGNED MESSAGE-----.*?\n\n//gs;

    # MIME crud
    $text =~ s/\n--.+?\n\n//gs;
    $text =~ s/This message is in MIME format.*?\n--.+?\n\n//gs;
    $text =~ s/This is a multipart message in MIME format.*?\n--.+?\n\n//gs;
    $text =~ s/^Content-\S+:.*$//gm;

    # trim sigs etc.
    $text =~ s/\n-- \n.*$//gs;     # trad-style
    $text =~ s/\n_____+.*$//gs;    # Hotmail
    $text =~ s/\n-----.*$//gs;     # catches PGP sigs

    $text;
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
