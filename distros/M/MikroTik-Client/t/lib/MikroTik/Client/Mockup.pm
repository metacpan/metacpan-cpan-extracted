package MikroTik::Client::Mockup;
use MikroTik::Client::Mo;

use AE;
use AnyEvent::Handle;
use AnyEvent::Socket;
use MikroTik::Client::Response;
use MikroTik::Client::Sentence qw(encode_sentence);
use Scalar::Util 'weaken';

has 'fd';
has port   => undef;
has res    => sub { MikroTik::Client::Response->new() };
has server => sub {
    my $self = shift;
    weaken $self;

    return tcp_server "127.0.0.1", $self->port, sub {
        my $fh = shift;
        $self->{h} = AnyEvent::Handle->new(
            fh      => $fh,
            on_read => sub {
                my $h    = shift;
                my $data = $self->res->parse(\$h->{rbuf});
                for (@$data) {
                    my $cmd = $_->{'.type'} // '';
                    warn "wrong command \"$cmd\"\n" and next
                        unless $cmd =~ s/^\//cmd_/;
                    $cmd =~ s/\//_/g;

                    eval {
                        my $resp = '';
                        $resp .= encode_sentence(@$_) for ($self->$cmd($_));
                        $h->push_write($resp);
                        1;
                    } or warn "unhandled command \"$cmd\": $@";
                }
            },
            on_eof => sub { delete $self->{timers} }
        );
    }, sub { $self->port($_[2]); return 0 };
};

sub cmd_cancel {
    my ($self, $attr) = @_;
    my $tag     = $attr->{'.tag'};
    my $cmd_tag = $attr->{'tag'};

    return ['!trap', {message => 'unknown command'}, undef, $tag]
        unless delete $self->{timers}{$cmd_tag};

    return (
        ['!trap', {category => 2, message => 'interrupted'}, undef, $cmd_tag],
        _done($tag), _done($cmd_tag));
}

sub cmd_close_premature {
    my ($self, $attr) = @_;

    $self->{timers}{_prem} = AE::timer 0.25, 0, sub { $self->{h}->destroy };
    return ();
}

sub cmd_err {
    my (undef, $attr) = @_;
    my $tag = $attr->{'.tag'};
    return ['!trap', {message => 'random error', category => 0}, undef, $tag];
}

sub cmd_login {
    my (undef, $attr) = @_;
    my $tag = $attr->{'.tag'};

    return _done($tag, {ret => '098f6bcd4621d373cade4e832627b4f6'})
        unless $attr->{name};

    return _done($tag) if $attr->{name} eq 'test' && (

        # Pre 6.43
        ($attr->{response} // '') eq '00119ce7e093e33497053e73f37a5d3e15'

        # 6.43+
        or ($attr->{password} // '') eq 'tset'
    );

    return ['!fatal', {message => 'cannot log in'}, undef, $tag];
}

sub cmd_nocmd {
    return ();
}

sub cmd_resp {
    my (undef, $attr) = @_;
    my $tag = $attr->{'.tag'};

    my $resp = ['!re', _gen_attr(@{$attr}{'.proplist', 'count'}), undef, $tag];
    return ($resp, $resp, _done($tag));
}

sub cmd_subs {
    my ($self, $attr) = @_;
    my $tag = $attr->{'.tag'} // 0;
    my $key = $attr->{'key'};

    $self->{timers}{$tag} = AE::timer 0.5, 0.5, sub {
        $self->{h}
            ->push_write(encode_sentence('!re', {key => $key}, undef, $tag));
    };

    return ();
}

sub _done {
    return ['!done', $_[1], undef, $_[0]];
}

sub _gen_attr {
    my $c    = $_[1] // 0;
    my $attr = {};
    $attr->{$_} = 'attr' . ($c++) for split /,/, ($_[0] // 'prop1,prop2,prop0');
    return $attr;
}

1;
