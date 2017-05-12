package IkuSan;

use 5.10.0;

use strict;
use warnings;

our $VERSION = "0.01";

use AnySan;
use AnySan::Provider::IRC;
use Encode;
use Plack::Request;
use Twiggy::Server;
use Getopt::Long qw(
    GetOptionsFromString
    :config posix_default no_ignore_case bundling
);
use AnyEvent::ForkManager;
use Try::Tiny;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $self = bless \%args, $class;

    $self->{nickname}           //= 'ikusan';
    $self->{port}               ||= 6667;
    $self->{post_interval}      //= 2;
    $self->{reconnect_interval} //= 3;
    $self->{receive_commands}   //= ['PRIVMSG'];
    $self->{http_host}            = '127.0.0.1'; # 固定
    $self->{http_port}          //= 19300;
    $self->{max_workers}        //= 10;
    $self->{pid}                  = $$; # 固定
    $self->{on_option_error}    //= sub {
        my ($e, $receive) = @_;
        warn "on_option_error: $e";
    };
    $self->{on_start}           //= sub {
        my ($pm, $receive, $sub, $message, @matches) = @_;
        warn "on_start: $message";
    };
    $self->{on_error}           //= sub {
        my ($e, $pm, $receive, $sub, $message, @matches) = @_;
        warn "on_error: $e";
    };
    $self->{on_finish}           //= sub {
        my ($pm, $receive, $sub, $message, @matches) = @_;
        warn "on_finish: $message";
    };

    my ($irc, $is_connect, $connector);
    $connector = sub {
        irc
            $self->{host},
            port       => $self->{port},
            key        => $self->{keyword},
            password   => $self->{password},
            nickname   => $self->{nickname},
            user       => $self->{user},
            interval   => $self->{post_interval},
            enable_ssl => $self->{enable_ssl},
            recive_commands => $self->{receive_commands},
            on_connect => sub {
                my ($con, $err) = @_;
                if (defined $err) {
                    warn "connect error: $err\n";
                    exit 1 unless $self->{reconnect_interval};
                    sleep $self->{reconnect_interval};
                    $con->disconnect('try reconnect');
                } else {
                    warn 'connect';
                    $is_connect = 1;
                }
            },
            on_disconnect => sub {
                warn 'disconnect';
                # XXX: bad hack...
                undef $irc->{client};
                undef $irc->{SEND_TIMER};
                undef $irc;
                $is_connect = 0;
                $irc = $connector->();
            },
            channels => {
                map { my $chan = $_; $chan = '#'.$chan unless $chan =~ /^#/;  ;($chan => +{}) } @{ $self->{join_channels} || [] },
            };
    };
    $irc = $connector->();

    my $app = sub {
        my $req = Plack::Request->new(shift);
        if ($req->address eq $self->{http_host} && $req->method eq 'POST') {
            my $message = $req->param('message');
            my $channel = $req->param('channel');
            my $privmsg = $req->param('privmsg');
            my @message = split(/\n/, $message);
            $irc->send_message( $message[0], channel => $channel, privmsg => $privmsg );
            return [ 200, ["Content-Type" => "text/plain"], ["message sent channel: $channel $message"] ]
        }
        [ 404, ["Content-Type" => "text/plain"], ["not found"] ]
    };

    warn sprintf("starting httpd: http://%s:%s", $self->{http_host}, $self->{http_port});
    my $twiggy = Twiggy::Server->new(
        host => $self->{http_host},
        port => $self->{http_port},
    );

    $twiggy->register_service($app);

    my $pm = AnyEvent::ForkManager->new(
        max_workers => $self->{max_workers},
    );

    AnySan->register_listener(
        $self->{nickname} => {
            cb => sub {
                my $receive = shift;
                $receive->{message}   = decode_utf8 $receive->{message};
                $receive->{http_host} = $self->{http_host};
                $receive->{http_port} = $self->{http_port};
                $receive->{pid}       = $self->{pid};
                my $respond = [];
                try {
                    $respond = $self->_respond($receive);
                } catch {
                    $self->{on_option_error}->($_, $receive);
                };
                for my $r (@$respond) {
                    my ($sub, $message, @matches) = @$r;
                    $pm->start(
                        cb => sub {
                            my ($pm, $receive, $sub, $message, @matches) = @_;
                            $self->{on_start}->($pm, $receive, $sub, $message, @matches);
                            try {
                                $sub->($pm, $receive, $sub, $message, @matches);
                            } catch {
                                $self->{on_error}->($_, $pm, $receive, $sub, $message, @matches);
                            } finally {
                                $self->{on_finish}->($pm, $receive, $sub, $message, @matches) unless (@_);
                            };
                        },
                        args => [$receive, $sub, $message, @matches],
                    );
                }
            }
        }
    );

    $self;
}

sub on_message {
    my ($self, @jobs) = @_;
    while (my ($reg, $sub) = splice @jobs, 0, 2) {
        push @{ $self->_reactions }, [$reg, $sub];
    }
}

sub on_command {
    my ($self, @jobs) = @_;
    while (my ($command, $sub) = splice @jobs, 0, 2) {
        my $reg = _build_command_reg($self->{nickname}, $command);
        push @{ $self->_reactions }, [$reg, $sub, $command];
    }
}

sub on_option {
    my ($self, @jobs) = @_;
    while (my ($command, $option, $sub) = splice @jobs, 0, 3) {
        die "on_option is require 3 arguments." unless $sub;
        my $reg = _build_command_reg($self->{nickname}, $command);
        push @{ $self->_reactions }, [$reg, $sub, $command, $option];
    }
}

sub _build_command_reg {
    my ($nick, $command) = @_;

    my $prefix = '^\s*'.quotemeta($nick). '_*[:\s]\s*' . quotemeta($command);
}

sub fever { AnySan->run }

sub respond_all { shift->{respond_all} }

sub _reactions {
    shift->{_reactions} ||= [];
}

sub _respond {
    my ($self, $receive) = @_;

    my @result = ();
    my $message = $receive->message;
    $message =~ s/^\s+//; $message =~ s/\s+$//;
    for my $reaction (@{ $self->_reactions }) {
        my ($reg, $sub, $command, $option) = @$reaction;
        if (my @matches = $message =~ $reg) {
            if (defined $option) {
                @matches = _build_option_args($reg, $message, $option);
            }
            elsif (defined $command) {
                @matches = _build_command_args($reg, $message);
            }
            push @result, [$sub, $message, @matches];
            return \@result unless $self->respond_all;
        }
    }

    return \@result;
}

sub _build_command_args {
    my ($reg, $mes) = @_;
    $mes =~ s/$reg//;
    $mes =~ s/^\s+//; $mes =~ s/\s+$//;
    split /\s+/, $mes;
}

sub _build_option_args {
    my ($reg, $mes, $opt) = @_;
    $mes =~ s/$reg//;
    $mes =~ s/^\s+//; $mes =~ s/\s+$//;
    my $warn = "";
    local $SIG{__WARN__} = sub {
        $warn = $_[0]; chomp($warn)
    };
    GetOptionsFromString($mes, \my %opts, @$opt);
    die $warn if ($warn);
    return %opts;
}

1;

package # hide from pause
    AnySan::Receive;

use Furl;
use Encode qw/encode_utf8/;

sub furl {
    my $self = shift;
    $self->{_furl} = Furl->new();
    $self->{_furl};
}

sub notice {
    my ($self, $msg) = @_;
    $self->reply($msg)
}

sub privmsg {
    my ($self, $msg) = @_;
    $self->reply($msg, privmsg => 1)
}

sub reply {
    my ($self, $msg, %args) = @_;
    my @msg = split(/\n/, $msg);
    if ($self->{pid} == $$) {
        $self->attribute('send_command', 'PRIVMSG') if ($args{privmsg});
        $self->send_reply($msg[0]);
    } else {
        $self->furl->post(
            sprintf("http://%s:%s", $self->{http_host}, $self->{http_port}), [], [
                message => encode_utf8 $msg,
                channel => $self->attribute("channel"),
                privmsg => $args{privmsg} || 0,
            ],
        );
    }
}

1;

__END__

=encoding utf-8

=begin html

<img src="https://raw.githubusercontent.com/mix3/p5-IkuSan/master/share/AA.png" alt="AA" />

=end html

=head1 NAME

IkuSan - IkuSan is IRC reaction bot framework.

=head1 SYNOPSIS

    use utf8;
    use IkuSan;

    my $ikusan = IkuSan->new(
        host          => 'example.com',
        password      => '******',
        enable_ssl    => 1,
        join_channels => [qw/test/],
    );

    $ikusan->on_option(
        sleep => [qw/
            time|t=i
            die|d
        /] => sub {
            my ($pm, $receive, $sub, $message, %args) = @_;
            $receive->privmsg($receive->{from_nickname}.": 寝ます");
            for my $c (1..$args{time}) {
                sleep 1;
                $receive->notice("zzz…(".$c.")");
            }
            die if ($args{die}); # will catch
            $receive->privmsg($receive->{from_nickname}.": 起きました");
        },
    );

    $ikusan->on_command(
        echo => sub {
            my ($pm, $receive, $sub, $message, @args) = @_;
            $receive->privmsg($receive->{from_nickname}.": ".join(" ", @args));
        },
    );

    $ikusan->on_message(
        qr/^ikusan:?/ => sub {
            my ($pm, $receive, $sub, $message) = @_;
            $receive->privmsg($receive->{from_nickname}.": ｻﾀﾃﾞｰﾅｲﾄﾌｨｰﾊﾞｰ!");
        },
    );

    $ikusan->fever;

=head1 DESCRIPTION

IkuSan is IRC reaction bot framework. IkuSan was inspired by L<UnazuSan> by songmu and L<App::Ikachan> by yappo.

THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.

=head1 LICENSE

Copyright (C) mix3.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mix3 E<lt>himachocost333@gmail.comE<gt>

=cut

