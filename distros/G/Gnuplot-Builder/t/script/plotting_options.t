use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Identity;
use Test::Fatal;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;

{
    no warnings "once";
    $Gnuplot::Buidler::Process::NO_STDERR = 0;
}

{
    note('basic set-get-delete operation');
    my $s = Gnuplot::Builder::Script->new;
    is $s->get_plot('output'), undef;
    is $s->get_plot('no_stderr'), undef;
    identical $s->set_plot(output => "hoge.png"), $s;
    is $s->get_plot('output'), "hoge.png";
    is $s->get_plot('no_stderr'), undef;
    identical $s->set_plot(no_stderr => 1), $s;
    is $s->get_plot('output'), "hoge.png";
    is $s->get_plot('no_stderr'), 1;
    identical $s->delete_plot('output'), $s;
    is $s->get_plot('output'), undef;
    is $s->get_plot('no_stderr'), 1;
    identical $s->delete_plot('no_stderr'), $s;
    is $s->get_plot('output'), undef;
    is $s->get_plot('no_stderr'), undef;
}

{
    note('set-delete multiple');
    my $s = Gnuplot::Builder::Script->new;
    $s->set_plot(
        output => "hoge.png",
        no_stderr => 1
    );
    is $s->get_plot("output"), "hoge.png";
    is $s->get_plot("no_stderr"), 1;
    $s->delete_plot(qw(output no_stderr));
    is $s->get_plot("output"), undef;
    is $s->get_plot("no_stderr"), undef;
}

{
    note('passing code-ref, get it as-is');
    my $s = Gnuplot::Builder::Script->new;
    my $code = sub { die "this should not be executed." };
    $s->set_plot(writer => $code);
    identical $s->get_plot("writer"), $code;
}

{
    note('passing array-ref, get it as-is');
    my $s = Gnuplot::Builder::Script->new;
    my $aref = [1, 2, 3];
    $s->set_plot(output => $aref);
    identical $s->get_plot("output"), $aref;
}

{
    note('effect on short-hands (plot() etc.)');
    my $buf;
    my $s = Gnuplot::Builder::Script->new(
        term => 'dumb'
    )->set_plot(
        writer => sub { $buf .= $_[0] }
    );
    
    $buf = "";
    is $s->plot('sin(x)'), "";
    like $buf, qr/^set term/, 'writer option for plot()';

    $buf = "";
    is $s->splot('sin(x * y)'), "";
    like $buf, qr/^set term/, 'writer option for splot()';

    $buf = "";
    is $s->multiplot("layout 1,2", sub { }), "";
    like $buf, qr/^set term/, 'writer option for multiplot()';

    $buf = "";
    is $s->run(), "";
    like $buf, qr/^set term/, 'writer option for run()';
}

{
    note('override by given arguments');
    my $buf1;
    my $buf2;
    my $writer2 = sub { $buf2 .= $_[0] };
    my $s = Gnuplot::Builder::Script->new(
        term => 'dumb'
    )->set_plot(
        writer => sub { $buf1 .= $_[0] },
        output => "hoge.png"
    );

    foreach my $method (qw(plot_with splot_with)) {
        $buf1 = $buf2 = "";
        is $s->$method(
            dataset => 'sin(x)',
            writer => $writer2,
            output => "foobar.jpg"
        ), "";
        is $buf1, "", "$method: writer is overridden";
        unlike $buf2, qr/hoge\.png/, "$method: output hoge.png is overridden";
        like $buf2, qr/foobar\.jpg/, "$method: output is now foobar.png";
    }

    foreach my $method (qw(multiplot_with run_with)) {
        $buf1 = $buf2 = "";
        is $s->$method(
            do => sub {  },
            writer => $writer2,
            output => "foobar.jpg"
        ), "";
        is $buf1, "", "$method: writer is overridden";
        unlike $buf2, qr/hoge\.png/, "$method: output hoge.png is overridden";
        like $buf2, qr/foobar\.jpg/, "$method: output is now foobar.jpg";
    }
}

{
    note("override by given undef");
    my $s = Gnuplot::Builder::Script->new->set_plot(output => "hoge.png");
    my $buf = "";
    $s->plot_with(
        dataset => 'sin(x)',
        writer => sub { $buf .= $_[0] },
        output => undef,
    );
    like $buf, qr/sin\(x\)/, "script is writtent to buffer";
    unlike $buf, qr/set output/, "not output because output is now overridden by undef";
    unlike $buf, qr/hoge\.png/;
}

{
    note('exception on unknown argument');
    my $s = Gnuplot::Builder::Script->new;
    like exception { $s->set_plot(hoge => 1) }, qr/unknown plotting option/i;
    like exception { $s->get_plot("hoge") }, qr/unknown plotting option/i;
    like exception { $s->delete_plot("hoge") }, qr/unknown plotting option/i;
}

{
    note('inheritance set-get-delete');
    my $p1 = Gnuplot::Builder::Script->new->set_plot(
        output => "hoge.png"
    );
    my $p2 = Gnuplot::Builder::Script->new->set_plot(
        output => "foobar.png",
        no_stderr => 1
    );
    my $c = $p1->new_child;
    
    is $c->get_plot("output"), "hoge.png";
    is $c->get_plot("no_stderr"), undef;
    
    $c->set_plot(output => "buzz.jpg");
    is $c->get_plot("output"), "buzz.jpg";
    is $c->get_plot("no_stderr"), undef;

    $c->set_parent($p2);
    is $c->get_plot("output"), "buzz.jpg";
    is $c->get_plot("no_stderr"), 1;

    $c->delete_plot("output", "no_stderr");
    is $c->get_plot("output"), "foobar.png";
    is $c->get_plot("no_stderr"), 1;

    $c->set_plot(no_stderr => undef);
    is $c->get_plot("output"), "foobar.png";
    is $c->get_plot("no_stderr"), undef;

    $c->delete_plot("no_stderr");
    is $c->get_plot("output"), "foobar.png";
    is $c->get_plot("no_stderr"), 1;
}




done_testing;
