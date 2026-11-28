package SmtpdHarness;

# Drives filter-mimedefang.pl the way smtpd(8) does: smtpd-filters(7) lines
# on stdin, decisions on stdout, and a fake mimedefang-multiplexor(8) on a
# UNIX socket.

use strict;
use warnings;

use Exporter 'import';
use File::Temp qw( tempdir );
use IO::Socket::UNIX;
use IPC::Open3;
use Symbol qw( gensym );

our @EXPORT_OK = qw( run_filter session );

my $TS = 0;

# session($id, \%opts) returns the report lines for one connection and one
# transaction up to the data phase.
sub session {
    my ( $id, %o ) = @_;
    my $mid = $o{msgid} // 'abcd1234';
    my @l;
    push @l, _report( 'link-connect', $id,
        $o{rdns} // 'mx.example.org', 'pass',
        $o{src}  // '192.0.2.1:3333', $o{dest} // '192.0.2.2:25' );
    push @l, _report( 'link-identify', $id, 'EHLO', $o{helo} // 'client.example.org' );
    push @l, _report( 'link-tls', $id, $o{tls} ) if $o{tls};
    push @l, _report( 'link-auth', $id, 'pass', $o{user} ) if defined $o{user};
    return @l;
}

sub _report {
    my ( $event, $id, @params ) = @_;
    return join '|', 'report', '0.7', sprintf( '%d.000000', ++$TS ),
        'smtp-in', $event, $id, @params;
}

sub report { return _report(@_) }

sub filter {
    my ( $phase, $id, $token, @params ) = @_;
    return join '|', 'filter', '0.7', sprintf( '%d.000000', ++$TS ),
        'smtp-in', $phase, $id, $token, @params;
}

push @EXPORT_OK, qw( report filter );

# run_filter(args => [...], mx => sub { my ($cmd) = @_; return $reply },
#            lines => [...])
sub run_filter {
    my (%a) = @_;
    my $dir   = tempdir( CLEANUP => 1 );
    my $sock  = "$dir/mx.sock";
    my $spool = "$dir/spool";
    mkdir $spool or die "mkdir: $!";

    my $srv = IO::Socket::UNIX->new( Local => $sock, Listen => 20 ) or die "listen: $!";
    my $mxpid = fork() // die;
    if ( not $mxpid ) {
        open my $log, '>>', "$dir/mx.log" or die;
        $log->autoflush(1);
        while ( my $c = $srv->accept ) {
            my $cmd = <$c> // '';
            chomp $cmd;
            print {$log} "$cmd\n";
            my $reply = $a{mx} ? $a{mx}->( $cmd, $spool ) : "ok 1 ok 250 2.1.0 0\n";
            print {$c} $reply if defined $reply;
            close $c;
        }
        exit 0;
    }
    close $srv;

    my $script = $a{script} // 'filter-mimedefang.pl';
    my @cmd = ( $^X, '-Ilib', $script, '-m', $sock, '-z', $spool, @{ $a{args} // [] } );
    my $err = gensym;
    my $pid = open3( my $in, my $out, $err, @cmd );

    print {$in} "$_\n" for (
        'config|smtpd-version|7.6.0',
        'config|protocol|0.7',
        'config|smtpd-name|OpenSMTPD',
        'config|subsystem|smtp-in',
        'config|ready',
        @{ $a{lines} },
    );
    close $in;

    my @out = <$out>;
    my @err = <$err>;
    waitpid $pid, 0;
    kill 'TERM', $mxpid;
    waitpid $mxpid, 0;

    chomp @out;
    my @mx;
    if ( open my $fh, '<', "$dir/mx.log" ) { chomp( @mx = <$fh> ); }

    # Leftover spool directories (should be none after a transaction)
    opendir my $dh, $spool or die;
    my @left = grep { !/^\./ } readdir $dh;

    return {
        out   => [ grep { !/^register\|/ } @out ],
        mx    => \@mx,
        err   => \@err,
        spool => \@left,
        dir   => $dir,
    };
}

1;
