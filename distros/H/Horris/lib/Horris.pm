package Horris;
# ABSTRACT: An IRC Bot Based On Moose/AnyEvent - forked L<Morris>


use Moose;
use AnyEvent;
use Const::Fast;
use Horris::Connection;
use namespace::clean -except => qw/meta/;

const our $DEBUG => $ENV{PERL_HORRIS_DEBUG};

has condvar => (
    is => 'ro', 
    lazy_build => 1, 
);

has connections => (
    traits => ['Array'],
    is => 'ro', 
    isa => 'ArrayRef[Horris::Connection]', 
    lazy_build => 1, 
    handles => {
        all_connections => 'elements', 
        push_connection => 'push', 
    }, 
);

has config => (
    is => 'ro', 
    isa => 'HashRef', 
    required => 1, 
);

sub _build_condvar { AnyEvent->condvar }
sub _build_connections {
    my ($self) = @_;
    my @connections;
    while (my ($name, $conn) = each %{$self->{config}{connection}}) {
        confess "No network specified for connection '$name'" unless $conn->{network};
        print "Connection Name: $name\n" if $Horris::DEBUG;

        my $network = $self->{config}{network}->{ $conn->{network} };
        my $connection = Horris::Connection->new({
            %$network,
            %$conn,
            plugins => $conn->{loadmodule} ? $conn->{loadmodule} : [], 
        });
        push @connections, $connection;
    }

    return \@connections;
}

sub run {
    my $self = shift;
    my $cv = $self->condvar;
    $cv->begin;
    foreach my $conn ($self->all_connections) {
        $conn->run;
    }

    $cv->recv;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Horris - An IRC Bot Based On Moose/AnyEvent - forked L<Morris>

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

    use Horris;
    my $config = {
        'network' => {
            'freenode' => {
                'nickname' => 'botname',
                'server' => 'irc.freenode.net',
                'port' => '6667',
                'username' => 'botname'
            }
        },
        'connection' => {
            'freenode' => {
                'plugin' => {
                    'Join' => {
                        'channels' => [
                            '#channel-name', 
                        ]
                    },
                    'Twitter' => {},
                }, 
                'network' => 'freenode',
                'loadmodule' => [
                    'Twitter',
                    'Join',
                ]
            }
        }
    };

    my $horris = Horris->new(config => $config);
    $horris->run;

or

    horris run --configfile /path/to/config.conf        # more general

below shows some feature of Horris.

    ### assume here at a irc channel & hongbot is horris bot, hshong is me.
    ### echo
    HH:MM:SS  hshong | hongbot echo
    HH:MM:SS      -- | Notice(hongbot) echo on
    HH:MM:SS  hshong | hi
    HH:MM:SS hongbot | hshong: hi
    HH:MM:SS  hshong | hongbot echo
    HH:MM:SS      -- | Notice(hongbot) echo off
    HH:MM:SS  hshong | hi                           # and no echo here..
    ### evaluate
    HH:MM:SS  hshong | eval print 'hello world'
    HH:MM:SS hongbot | hello world
    HH:MM:SS  hshong | eval print $^V
    HH:MM:SS hongbot | v5.10.1
    ### hit(cute joke)
    HH:MM:SS  hshong | hongbot hit hshong
    HH:MM:SS hongbot | hshong: fork you
    HH:MM:SS  hshong | hongbot hit hshong
    HH:MM:SS hongbot | hshong: http://stfuawsc.com
    HH:MM:SS  hshong | jeen: 껒
    HH:MM:SS hongbot | hshong: ㅁㅁ? - http://tinyurl.com/5t3ew8t
    ### letter - Acme::Letter
    HH:MM:SS  hshong | letter bye
    HH:MM:SS hongbot |  _____ _    _ _____
    HH:MM:SS hongbot | |  _  \ \  / /  ___|
    HH:MM:SS hongbot | | |_)_/\_\/_/| |__
    HH:MM:SS hongbot | | |_) \  | | | |___
    HH:MM:SS hongbot | |_____/  |_| |_____|
    ### PeekURL
    HH:MM:SS  hshong | http://sports.media.daum.net/baseball/news/breaking/view.html?cateid=1028&newsid=20110211110523268&p=SpoSeoul
    HH:MM:SS      -- | Notice(hongbot): Daum 스포츠 [text/html;charset=UTF-8] - http://tinyurl.com/4rs9afr
    ### Twitter
    HH:MM:SS  hshong | http://twitter.com/#!/umma_coding_bot/status/8721128864350209
    HH:MM:SS hongbot | 엄마코딩봇: 세계가 네 코드를 지켜보고 있단다. 버그 배출을 자제하렴.
    ### kspell - KoreanSpellChecker
    HH:MM:SS  hshong | kspell 키디님
    HH:MM:SS hongbot | 키디님 -> 케디님
    ### Relay chat messages from other networks
    HH:MM:SS hongbot | <other_irc_server_hshong> i'm here
    ### PowerManagement
    HH:MM:SS    NICK | hongbot quit
    HH:MM:SS     <-- | hongbot (nick@some.host) has quit (Remote host closed the connection)

=head1 DESCRIPTION

L<Morris> is awesome.
L<Horris> stolen L<Morris>'s idea, documents, code base, plugin and so on. (everything)
L<Morris> has self implemeted pluggable process. but L<Horris> is not.

<Horris> is <Morris> + CLI utility + More Simple plugins.

This documents concentrate I<How to use> instead I<What it is>.
because you can also seeing L<Morris>.

=head1 BASIC CONFIGURATION

    <Config>
      <Connection YourConnectionName>
        Network YourNetworkName
        ... LoadModules ...
        ... plugins ...
      </Connection>

      <Network YourNetworkName>
        ... network config ...
      </Network>
    </Config>

=head2 Connection CLAUSE

    <Connection YourConnectionName>
        LoadModule  Echo
        LoadModule  PeekURL
        LoadModule  Twitter
        <Plugin Echo/>
        <Plugin PeekURL/>
        <Plugin Twitter/>
    </Connection>

LoadModule has execute priority.
First in first out.
Each plugin return boolean value when a event occur.
If any plugin return false, lower plugins never processing occured event.

=head1 SEE ALSO

L<Morris>

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

