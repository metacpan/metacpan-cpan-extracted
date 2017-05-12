package AuthMilterTest;

use strict;
use warnings;
use Test::More;
use Test::File::Contents;

use Cwd qw{ cwd };
use IO::Socket::INET;
use IO::Socket::UNIX;
use Module::Load;
        
use Mail::Milter::Authentication;
use Mail::Milter::Authentication::Client;
use Mail::Milter::Authentication::Config;
use Mail::Milter::Authentication::Protocol::Milter;
use Mail::Milter::Authentication::Protocol::SMTP;

my $base_dir = cwd();

our $MASTER_PROCESS_PID = $$;

{
    my $milter_pid;

    sub start_milter {
        my ( $prefix ) = @_;

        return if $milter_pid;

        if ( ! -e $prefix . '/authentication_milter.json' ) {
            die "Could not find config";
        }
    
        system "cp $prefix/mail-dmarc.ini .";
        
        $milter_pid = fork();
        die "unable to fork: $!" unless defined($milter_pid);
        if (!$milter_pid) {
            $Mail::Milter::Authentication::Config::PREFIX = $prefix;
            Mail::Milter::Authentication::start({
               'pid_file'   => 'tmp/authentication_milter.pid',
                'daemon'     => 0,
            });
            die;
        }

        sleep 5;
        open my $pid_file, '<', 'tmp/authentication_milter.pid';
        $milter_pid = <$pid_file>;
        close $pid_file;
        print "Milter started at pid $milter_pid\n";
        return;
    }

    sub stop_milter {
        return if ! $milter_pid;
        kill( 'HUP', $milter_pid );
        waitpid ($milter_pid,0);
        print "Milter killed at pid $milter_pid\n";
        undef $milter_pid;
        unlink 'tmp/authentication_milter.pid';
        unlink 'mail-dmarc.ini';
        return;
    }

    END {
        return if $MASTER_PROCESS_PID != $$;
        stop_milter();
    }
}

sub smtp_process {
    my ( $args ) = @_;

    if ( ! -e $args->{'prefix'} . '/authentication_milter.json' ) {
        die "Could not find config " . $args->{'prefix'};
    }
    if ( ! -e 'data/source/' . $args->{'source'} ) {
        die "Could not find source";
    }

    my $catargs = {
        'sock_type' => 'unix',
        'sock_path' => 'tmp/authentication_milter_smtp_out.sock',
        'remove'    => [10,11],
        'output'    => 'tmp/result/' . $args->{'dest'},
    };
    unlink 'tmp/authentication_milter_smtp_out.sock';
    my $cat_pid = smtpcat( $catargs );
    sleep 2;

    smtpput({
        'sock_type'    => 'unix',
        'sock_path'    => 'tmp/authentication_milter_test.sock',
        'mailer_name'  => 'test.module',
        'connect_ip'   => [ $args->{'ip'} ],
        'connect_name' => [ $args->{'name'} ],
        'helo_host'    => [ $args->{'name'} ],
        'mail_from'    => [ $args->{'from'} ],
        'rcpt_to'      => [ $args->{'to'} ],
        'mail_file'    => [ 'data/source/' . $args->{'source'} ],
    });

    waitpid( $cat_pid,0 );

    files_eq( 'data/example/' . $args->{'dest'}, 'tmp/result/' . $args->{'dest'}, 'smtp ' . $args->{'desc'} );

    return;
}

sub smtp_process_multi {
    my ( $args ) = @_;

    if ( ! -e $args->{'prefix'} . '/authentication_milter.json' ) {
        die "Could not find config";
    }

    # Hardcoded lines to remove in subsequent messages
    # If you change the source email then change the awk
    # numbers here too.
    # This could be better!

    my $catargs = {
        'sock_type' => 'unix',
        'sock_path' => 'tmp/authentication_milter_smtp_out.sock',
        'remove'    => $args->{'filter'},
        'output'    => 'tmp/result/' . $args->{'dest'},
    };
    unlink 'tmp/authentication_milter_smtp_out.sock';
    my $cat_pid = smtpcat( $catargs );
    sleep 2;
    
    my $putargs = {
        'sock_type'    => 'unix',
        'sock_path'    => 'tmp/authentication_milter_test.sock',
        'mailer_name'  => 'test.module',
        'connect_ip'   => [],
        'connect_name' => [],
        'helo_host'    => [],
        'mail_from'    => [],
        'rcpt_to'      => [],
        'mail_file'    => [],
    };

    foreach my $item ( @{$args->{'ip'}} ) {
        push @{$putargs->{'connect_ip'}}, $item;
    }
    foreach my $item ( @{$args->{'name'}} ) {
        push @{$putargs->{'connect_name'}}, $item;
    }
    foreach my $item ( @{$args->{'name'}} ) {
        push @{$putargs->{'helo_host'}}, $item;
    }
    foreach my $item ( @{$args->{'from'}} ) {
        push @{$putargs->{'mail_from'}}, $item;
    }
    foreach my $item ( @{$args->{'to'}} ) {
        push @{$putargs->{'rcpt_to'}}, $item;
    }
    foreach my $item ( @{$args->{'source'}} ) {
        push @{$putargs->{'mail_file'}}, 'data/source/' . $item;
    }
    #warn 'Testing ' . $args->{'source'} . ' > ' . $args->{'dest'} . "\n";

    smtpput( $putargs );

    waitpid( $cat_pid,0 );

    files_eq( 'data/example/' . $args->{'dest'}, 'tmp/result/' . $args->{'dest'}, 'smtp ' . $args->{'desc'} );

    return;
}

sub milter_process {
    my ( $args ) = @_;

    if ( ! -e $args->{'prefix'} . '/authentication_milter.json' ) {
        die "Could not find config";
    }
    if ( ! -e 'data/source/' . $args->{'source'} ) {
        die "Could not find source";
    }

    client({
        'prefix'       => $args->{'prefix'},
        'mailer_name'  => 'test.module',
        'mail_file'    => 'data/source/' . $args->{'source'},
        'connect_ip'   => $args->{'ip'},
        'connect_name' => $args->{'name'},
        'helo_host'    => $args->{'name'},
        'mail_from'    => $args->{'from'},
        'rcpt_to'      => $args->{'to'},
        'output'       => 'tmp/result/' . $args->{'dest'},
    });

    files_eq( 'data/example/' . $args->{'dest'}, 'tmp/result/' . $args->{'dest'}, 'milter ' . $args->{'desc'} );

    return;
}

sub run_milter_processing_spam {

    start_milter( 'config/spam' );

    milter_process({
        'desc'   => 'Gtube',
        'prefix' => 'config/spam',
        'source' => 'gtube.eml',
        'dest'   => 'gtube.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    milter_process({
        'desc'   => 'Gtube local',
        'prefix' => 'config/spam',
        'source' => 'gtube2.eml',
        'dest'   => 'gtube2.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'recipient2@example.net',
    });

    stop_milter();

    return;
}

sub run_smtp_processing_spam {

    start_milter( 'config/spam.smtp' );

    smtp_process({
        'desc'   => 'Gtube',
        'prefix' => 'config/spam.smtp',
        'source' => 'gtube.eml',
        'dest'   => 'gtube.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    smtp_process({
        'desc'   => 'Gtube local',
        'prefix' => 'config/spam.smtp',
        'source' => 'gtube2.eml',
        'dest'   => 'gtube2.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'recipient2@example.net',
    });

    stop_milter();

    return;
}

sub run_milter_processing_clamav {

    start_milter( 'config/clamav' );

    milter_process({
        'desc'   => 'Virus',
        'prefix' => 'config/clamav',
        'source' => 'virus.eml',
        'dest'   => 'virus.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    milter_process({
        'desc'   => 'No Virus',
        'prefix' => 'config/clamav',
        'source' => 'gtube2.eml',
        'dest'   => 'novirus.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'recipient2@example.net',
    });

    stop_milter();

    return;
}

sub run_smtp_processing_clamav {

    start_milter( 'config/clamav.smtp' );

    smtp_process({
        'desc'   => 'Virus',
        'prefix' => 'config/clamav.smtp',
        'source' => 'virus.eml',
        'dest'   => 'virus.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    smtp_process({
        'desc'   => 'No Virus',
        'prefix' => 'config/clamav.smtp',
        'source' => 'gtube2.eml',
        'dest'   => 'novirus.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'recipient2@example.net',
    });

    stop_milter();

    return;
}

sub run_milter_processing_rspamd {

    start_milter( 'config/rspamd' );

    milter_process({
        'desc'   => 'Gtube',
        'prefix' => 'config/rspamd',
        'source' => 'gtube.eml',
        'dest'   => 'rspamd-gtube.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    milter_process({
        'desc'   => 'Gtube local',
        'prefix' => 'config/rspamd',
        'source' => 'gtube2.eml',
        'dest'   => 'rspamd-gtube2.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'recipient2@example.net',
    });

    stop_milter();

    return;
}

sub run_smtp_processing_rspamd {

    start_milter( 'config/rspamd.smtp' );

    smtp_process({
        'desc'   => 'Gtube',
        'prefix' => 'config/rspamd.smtp',
        'source' => 'gtube.eml',
        'dest'   => 'rspamd-gtube.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    smtp_process({
        'desc'   => 'Gtube local',
        'prefix' => 'config/rspamd.smtp',
        'source' => 'gtube2.eml',
        'dest'   => 'rspamd-gtube2.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'recipient2@example.net',
    });

    stop_milter();

    return;
}

sub smtpput {
    my ( $args ) = @_;

    my $mailer_name  = $args->{'mailer_name'};
    
    my $mail_file_a  = $args->{'mail_file'};
    my $mail_from_a  = $args->{'mail_from'};
    my $rcpt_to_a    = $args->{'rcpt_to'};
    my $x_name_a     = $args->{'connect_name'};
    my $x_addr_a     = $args->{'connect_ip'};
    my $x_helo_a     = $args->{'helo_host'};
    
    my $sock_type    = $args->{'sock_type'};
    my $sock_path    = $args->{'sock_path'};
    my $sock_host    = $args->{'sock_host'};
    my $sock_port    = $args->{'sock_port'};
    
    my $sock;
    if ( $sock_type eq 'inet' ) {
       $sock = IO::Socket::INET->new(
            'Proto' => 'tcp',
            'PeerAddr' => $sock_host,
            'PeerPort' => $sock_port,
        ) || die "could not open outbound SMTP socket: $!";
    }
    elsif ( $sock_type eq 'unix' ) {
       $sock = IO::Socket::UNIX->new(
            'Peer' => $sock_path,
        ) || die "could not open outbound SMTP socket: $!";
    }
    
    my $line = <$sock>;
    
    if ( ! $line =~ /250/ ) {
        die "Unexpected SMTP response $line";
        return 0;
    }
    
    send_smtp_packet( $sock, 'EHLO ' . $mailer_name,       '250' ) || die;
    
    my $first_time = 1;
   
    while ( @$mail_from_a ) {
    
        if ( ! $first_time ) {
            if ( ! send_smtp_packet( $sock, 'RSET', '250' ) ) {
                $sock->close();
                return;
            };
        }
        $first_time = 0;
    
        my $mail_file = shift @$mail_file_a;
        my $mail_from = shift @$mail_from_a; 
        my $rcpt_to   = shift @$rcpt_to_a;
        my $x_name    = shift @$x_name_a;
        my $x_addr    = shift @$x_addr_a;
        my $x_helo    = shift @$x_helo_a;
        
        my $mail_data = q{};
        
        if ( $mail_file eq '-' ) {
            while ( my $l = <> ) {
                $mail_data .= $l;
            }
        }
        else {
            if ( ! -e $mail_file ) {
                die "Mail file $mail_file does not exist";
            }
            open my $inf, '<', $mail_file;
            my @all = <$inf>;
            $mail_data = join( q{}, @all );
            close $inf;
        }
        
        $mail_data =~ s/\015?\012/\015\012/g;
        # Handle transparency
        $mail_data =~ s/\015\012\./\015\012\.\./g;
        
        send_smtp_packet( $sock, 'XFORWARD NAME=' . $x_name,   '250' ) || die;
        send_smtp_packet( $sock, 'XFORWARD ADDR=' . $x_addr,   '250' ) || die;
        send_smtp_packet( $sock, 'XFORWARD HELO=' . $x_helo,   '250' ) || die;
        
        send_smtp_packet( $sock, 'MAIL FROM:' . $mail_from, '250' ) || die;
        send_smtp_packet( $sock, 'RCPT TO:' .   $rcpt_to,   '250' ) || die;
        send_smtp_packet( $sock, 'DATA',                    '354' ) || die;
        
        print $sock $mail_data;
        print $sock "\r\n";
        
        send_smtp_packet( $sock, '.',    '250' ) || return;
    
    }
        
    send_smtp_packet( $sock, 'QUIT', '221' ) || return;
    $sock->close();

    return;
}

sub send_smtp_packet {
    my ( $socket, $send, $expect ) = @_;
    print $socket "$send\r\n";
    my $recv = <$socket>;
    while ( $recv =~ /^\d\d\d\-/ ) {
        $recv = <$socket>;
    }
    if ( $recv =~ /^$expect/ ) {
        return 1;
    }
    else {
        warn "SMTP Send expected $expect received $recv when sending $send";
        return 0;
    }
}

sub smtpcat {
    my ( $args ) = @_;
    
    my $cat_pid = fork();
    die "unable to fork: $!" unless defined($cat_pid);
    return $cat_pid if $cat_pid; 
    
    my $sock_type = $args->{'sock_type'};
    my $sock_path = $args->{'sock_path'};
    my $sock_host = $args->{'sock_host'};
    my $sock_port = $args->{'sock_port'};
    
    my $remove = $args->{'remove'};
    my $output = $args->{'output'};
   
    my @out_lines;

    my $sock;
    if ( $sock_type eq 'inet' ) {
       $sock = IO::Socket::INET->new(
            'Listen'    => 5,
            'LocalHost' => $sock_host,
            'LocalPort' => $sock_port,
            'Protocol'  => 'tcp',
        ) || die "could not open socket: $!";
    }
    elsif ( $sock_type eq 'unix' ) {
       $sock = IO::Socket::UNIX->new(
            'Listen'    => 5,
            'Local' => $sock_path,
        ) || die "could not open socket: $!";
    }
    
    my $accept = $sock->accept();
    
    print $accept "220 smtp.cat ESMTP Test\r\n";
    
    local $SIG{'ALRM'} = sub{ die "Timeout\n" };
    alarm( 60 );
    
    my $quit = 0;
    while ( ! $quit ) {
        my $command = <$accept> || { $quit = 1 };
        alarm( 60 );
    
        if ( $command =~ /^HELO/ ) {
            push @out_lines, $command;
            print $accept "250 HELO Ok\r\n";
        }
        elsif ( $command =~ /^EHLO/ ) {
            push @out_lines, $command;
            print $accept "250 EHLO Ok\r\n";
        }
        elsif ( $command =~ /^MAIL/ ) {
            push @out_lines, $command;
            print $accept "250 MAIL Ok\r\n";
        }
        elsif ( $command =~ /^XFORWARD/ ) {
            push @out_lines, $command;
            print $accept "250 XFORWARD Ok\r\n";
        }
        elsif ( $command =~ /^RCPT/ ) {
            push @out_lines, $command;
            print $accept "250 RCPT Ok\r\n";
        }
        elsif ( $command =~ /^RSET/ ) {
            push @out_lines, $command;
            print $accept "250 RSET Ok\r\n";
        }
        elsif ( $command =~ /^DATA/ ) {
            push @out_lines, $command;
            print $accept "354 Send\r\n";
            DATA:
            while ( my $line = <$accept> ) {
                alarm( 60 );
                push @out_lines, $line;
                last DATA if $line eq ".\r\n";
                # Handle transparency
                if ( $line =~ /^\./ ) {
                    $line = substr( $line, 1 );
                }
            }
            print $accept "250 DATA Ok\r\n";
        }
        elsif ( $command =~ /^QUIT/ ) {
            push @out_lines, $command;
            print $accept "221 Bye\r\n";
            $quit = 1;
        }
        else {
            push @out_lines, $command;
            print $accept "250 Unknown Ok\r\n";
        }
    }

    open my $file, '>', $output;
    my $i = 0;
    foreach my $line ( @out_lines ) {
        $i++;
        next if grep { $i == $_ } @$remove;
        print $file $line;
    }
    close $file;

    $accept->close();
    $sock->close();

    exit 0;
}

sub client {
    my ( $args ) = @_;
    my $pid = fork();
    die "unable to fork: $!" unless defined($pid);
    if ( ! $pid ) {

        my $output = $args->{'output'};
        delete $args->{'output'};

        $Mail::Milter::Authentication::Config::PREFIX = $args->{'prefix'};
        delete $args->{'prefix'};

        my $client = Mail::Milter::Authentication::Client->new( $args );

        $client->process();

        open my $file, '>', $output;
        print $file $client->result();
        close $file;
        exit 0;

    }
    waitpid( $pid, 0 );
    return;
}

1;
