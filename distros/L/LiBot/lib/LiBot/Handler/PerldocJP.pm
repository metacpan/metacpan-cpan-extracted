package LiBot::Handler::PerldocJP;
use strict;
use warnings;
use utf8;
use Encode qw(decode_utf8 encode_utf8);
use Text::Shorten qw(shorten_scalar);

use Mouse;

has limit => (
    is => 'ro',
    default => sub { 120 },
);

no Mouse;

sub init {
    my ($self, $bot) = @_;

    $bot->register(
        qr/^perldoc\s+(.*)/ => sub {
            my ( $cb, $event, $arg ) = @_;

            pipe( my $rh, my $wh );

            my $pid = fork();
            $pid // do {
                close $rh;
                close $wh;
                die $!;
            };

            if ($pid) {

                # parent
                close $wh;

                my $ret = '';
                my $sweep;
                my $timer = AE::timer(
                    10, 0,
                    sub {
                        kill 9, $pid;
                    }
                );
                my $child;
                $child = AE::child(
                    $pid,
                    sub {
                        undef $timer;
                        $ret =~ s/NAME\n//;
                        $ret =~ s/\nDESCRIPTION\n/\n/;
                        $ret = shorten_scalar( decode_utf8($ret), $self->limit );
                        if ( $arg =~ /\A[\$\@\%]/ ) {
                            $ret .= "\n\nhttp://perldoc.jp/perlvar";
                        }
                        elsif ( $arg =~ /\A-[a-z]\s+(.+)/ ) {
                            $ret .= "\n\nhttp://perldoc.jp/$1";
                        }
                        else {
                            $ret .= "\n\nhttp://perldoc.jp/$arg";
                        }
                        $cb->($ret);
                        undef $sweep;
                        undef $child;
                    }
                );
                $sweep = AE::io(
                    $rh, 0,
                    sub {
                        $ret .= scalar(<$rh>);
                    }
                );
            }
            else {
                # child
                close $rh;

                open STDERR, '>&', $wh
                  or die "failed to redirect STDERR to logfile";
                open STDOUT, '>&', $wh
                  or die "failed to redirect STDOUT to logfile";

                eval {
                    require Pod::PerldocJp;
                    local @ARGV = split /\s+/, $arg;
                    if ( @ARGV == 1 && $ARGV[0] =~ /^[\$\@\%]/ ) {
                        unshift @ARGV, '-v';
                    }
                    unshift @ARGV, '-J';
                    @ARGV = map { encode_utf8($_) } @ARGV;
                    Pod::PerldocJp->run();
                };
                warn $@ if $@;

                exit 0;
            }
        }
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

LiBot::Handler::PerldocJP - Tell me link for perldoc.jp

=head1 SYNOPSIS

    # config.pl
    +{
        'handlers' => [
            'PerldocJP'
        ]
    }

    # script
    <hsegawa> perldoc perlre
    >bot< perlre - Perl 正規表現
    >bot< このページでは Perl での正規表現の構文について説明します。
    >bot< もしこれまでに正規表現を使ったことがないのであれば、 perlrequick にクイ
    >bot< ックスタ...
    >bot< http://perldoc.jp/perlre

=head1 DESCRIPTION

This bot tell me a link for perldoc.jp.

=head1 CONFIGURATION

=over 4

=item limit

Limit length of pod

=back

