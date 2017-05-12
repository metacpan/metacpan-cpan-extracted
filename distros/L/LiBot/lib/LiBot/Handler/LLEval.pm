package LiBot::Handler::LLEval;
use strict;
use warnings;
use utf8;
use Furl;
use URI::Escape qw(uri_escape_utf8);
use JSON qw(decode_json);
use Text::Shorten qw(shorten_scalar);

use Mouse;

no Mouse;

sub lleval {
    my ($src, $lang) = @_;
    my $ua = Furl->new(agent => 'lleval2lingr', timeout => 5);
    my $res = $ua->get(sprintf('http://api.dan.co.jp/lleval.cgi?l=%s&s=%s', $lang, uri_escape_utf8($src)));
    $res->is_success or die $res->status_line;
    print $res->content, "\n";
    return decode_json($res->content);
}

sub init {
    my ($self, $bot) = @_;

    $bot->register(
        qr/^!\s*(.*)/s => sub {
            my ( $cb, $event, $code ) = @_;

            my $lang = 'pl';
            if ($code =~ /^!\s*([a-z0-9]+)\s*(.+)/s) {
                $lang = $1;
                $code = $2;
            } else {
                unless ( $code =~ m{^(print|say)} ) {
                    $code = "print sub { ${code} }->()";
                }
            }
            my $res = lleval($code, $lang);
            if ( defined $res->{error} ) {
                $cb->( shorten_scalar( $res->{error}, 80 ) );
            }
            else {
                $cb->( shorten_scalar( $res->{stdout} . $res->{stderr}, 80 ) );
            }
        }
    );
}

1;
__END__

=for stopwords lleval

=head1 NAME

LiBot::Handler::LLEval - lleval gateway

=head1 SYNOPSIS

    # config.pl
    +{
        'handlers' => [
            'LLEval'
        ]
    }

    # script
    <hsegawa> !3+2
    >bot< 5
    <hsegawa> !!rb 1.upto(3) {|i| print i }
    >bot< 1 2 3

=head1 DESCRIPTION

This is a gateway for L<lleval|colabv6.dan.co.jp/lleval.html>.

=head1 CONFIGURATION

There is no configuration parameters.

