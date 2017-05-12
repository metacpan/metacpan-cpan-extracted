
use warnings;
use strict;
use lib 't';
use Test::More tests => 5;
use HTML::Template::Compiled;
use HTC_Utils qw($cache $tdir &cdir);

for (0..1) {
    my $plug = bless(
        {}, 'HTC_Test'
    );
    HTML::Template::Compiled->register($plug);
    sub HTC_Test::register {
        my ($class) = @_;
        my %plugs = (
            escape => {
                TESTING => sub {
                    my ($arg) = @_;
                    return "$_$arg$arg";
                },
            },
        );
        return \%plugs;

    }
    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<'EOM',
<%= foo escape=testing %>
EOM
        plugin => [$plug],
        debug    => 0,
        cache => 0,
    );
    my $string = 'string';
    $htc->param(
        foo => $string,
    );

    my $out = $htc->output;
    #print "out: $out\n";
    cmp_ok($out, '=~', "$_$string$string", "plugin as object $_");
}

{
    my $plug = bless(
        {
            'lang' => 'en',
            'map' => {
                en => {
                    HELLO_WORLD => 'Hello world',
                },
                de => {
                    HELLO_WORLD => 'Hallo Welt',
                },
                es => {
                    HELLO_WORLD => 'Hola Mundo',
                },
            },
        }, 'HTC_Test2'
    );
    HTML::Template::Compiled->register($plug);
    sub HTC_Test2::translate {
        my ($self, $id) = @_;
        return $self->{map}->{ $self->{lang} }->{$id};
    }
    sub HTC_Test2::register {
        my ($class) = @_;

        my %plugs = (
            tagnames => {
                HTML::Template::Compiled::Token::OPENING_TAG() => {
                    TRANSLATE => [sub { exists $_[1]->{ID} }, 'ID'],
                },
            },
            compile => {
                TRANSLATE => {
                    open => sub {
                        my ($htc, $token, $args) = @_;
                        my $OUT = $args->{out};
                        my $attr = $token->get_attributes;
                        my $expression = <<"EOM";
    $OUT "Translation of $attr->{ID}: ";
    $OUT \$t->get_plugin('HTC_Test2')->translate('\Q$attr->{ID}\E');
EOM
                        return $expression;
                    },
                },
            },
        );
        return \%plugs;
    }
    my $htc = HTML::Template::Compiled->new(
        scalarref => \<<'EOM',
<%translate id="HELLO_WORLD" %>
EOM
        plugin => [$plug],
        debug    => 0,
        cache => 0,
    );
    my $string = 'string';
    for my $lang (qw/ en de es /) {
        $plug->{lang} = $lang;
        my $translated = $plug->{map}->{$lang}->{HELLO_WORLD};
        my $out = $htc->output;
        #print "out: $out\n";
        cmp_ok($out, '=~', "$translated", "plugin as object $lang");
    }


}

HTML::Template::Compiled->clear_filecache($cache);


