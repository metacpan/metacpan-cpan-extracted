# :!plackup %

use Plack::Builder;
use Plack::Request;
use Encode 'encode_utf8';
use Template;
use lib 'lib';
use Lingua::EN::Opinion;
use Data::Dumper;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Varname   = 'score';

my $template =<<HTML;
<html><body>
<h1>Lingua::EN::Opinion!</h1>
<form action="/" method="POST">
<textarea name="text" rows="10" cols="30">
[% text %]
</textarea>
<br>
<input type="submit" value="Evaluate" />
</form>
NRC: <pre>[% nrc_score %]</pre>
<p>
<pre>[% familiar %]</pre>
<p>
Pos/Neg: <pre>[% score %]</pre>
</body></html>
HTML

my $default = 'I am not happy. It is very unhappy.';

builder {
    mount '/' => sub {
        my $req = Plack::Request->new(shift);
        my $sentence = $req->param('text') || $default;

        my $opinion = Lingua::EN::Opinion->new();

        my @words = $opinion->tokenize($sentence);

        my $score = {};
        for my $word ( @words ) {
            my $word_score = $opinion->get_word($word);
            next unless defined $word_score;
            $score->{$word} += $word_score;
        }

        my ( $nrc_score, $known, $unknown ) = $opinion->nrc_get_sentence($sentence);

        my $body;
        Template->new->process(
            \$template,
            {
                text      => $sentence,
                familiar  => Dumper( { known => $known, unknown => $unknown } ),
                score     => Dumper($score),
                nrc_score => Dumper($nrc_score),
            },
            \$body
        );

        my $res = $req->new_response(200);
        $res->content_type('text/html; charset=utf-8');
        $res->body(encode_utf8 $body);
        $res->finalize;
    }
};
