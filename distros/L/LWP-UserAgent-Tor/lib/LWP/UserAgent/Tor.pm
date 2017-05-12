package LWP::UserAgent::Tor;

use 5.010;
use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use File::MMagic;
use File::Which qw(which);
use IO::Socket::INET;
use LWP::Protocol::socks;
use Net::EmptyPort qw(empty_port);
use Proc::Background;
use Path::Tiny;

use base 'LWP::UserAgent';

our $VERSION = '0.06';

my $_tor_data_dir = Path::Tiny->tempdir;

sub new {
    my ($class, %args) = @_;

    my $tor_control_port = delete( $args{tor_control_port} ) // empty_port();
    my $tor_port         = delete( $args{tor_port} )         // do {
        my $port;
        while (($port = empty_port()) == $tor_control_port){};
        $port;
    };
    my $tor_cfg  = delete( $args{tor_cfg} );

    my $self = $class->SUPER::new(%args);
    $self->{_tor_proc}   = _start_tor_proc($tor_port, $tor_control_port, $tor_cfg);
    $self->{_tor_socket} = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $tor_control_port,
    ) // croak 'could not connect to tor';

    $self->proxy( [ 'http', 'https' ], "socks://localhost:$tor_port" );

    return bless $self, $class;
}

sub DESTROY {
    my ($self) = @_;

    my $tor_proc = $self->{_tor_proc};
    $tor_proc->die if defined $tor_proc;
    $_tor_data_dir->remove_tree;
    $self->SUPER::DESTROY if $self->can('SUPER::DESTROY');

    return;
}

sub _start_tor_proc {
    my ($port, $control_port, $cfg) = @_;

    # There must be a Tor binary in $PATH; it might be named "tor.real".
    my $tor = which 'tor';
    defined $tor or croak 'could not find tor binary in $PATH';
    my $tor_real = which 'tor.real';

    my $mm = File::MMagic->new;
    my $file_format = $mm->checktype_filename($tor);

    my $binary_format = 'application/octet-stream';

    if ($file_format eq $binary_format) {
        # tor is a binary; do nothing.
    }
    elsif ($file_format =~ m/sh script text$/ && defined $tor_real) {
        # tor is a shell script; it could be from a Tor Browser distribution.
        $file_format = $mm->checktype_filename($tor_real);
        if ($file_format eq $binary_format) {
            # tor.real is the corresponding Tor binary.
            $tor = $tor_real;
        }
        elsif ($file_format =~ m|^x-system/x-error; |) {
            $file_format =~ s|^x-system/x-error; ||;
            croak 'tor.real file format error detected: "' . $file_format . '"';
        }
        else {
            croak 'could not find matching tor binary for tor shell script';
        }
    }
    elsif ($file_format =~ m|^x-system/x-error; |) {
        $file_format =~ s|^x-system/x-error; ||;
        croak 'tor file format error detected: "' . $file_format . '"';
    }
    else {
        croak 'could not work with tor file format "' . $file_format . '"';
    }

    my $tor_cmd = "$tor " .
        "--ControlPort $control_port " .
        "--SocksPort $port " .
        "--DataDirectory $_tor_data_dir " .
        "--quiet ";

    if (defined $cfg){
        croak 'tor config file does not exist' unless -e $cfg;
        $tor_cmd .= " -f $cfg";
    }

    my $tor_proc = Proc::Background->new($tor_cmd);

    # starting tor...
    sleep 1;

    if (!$tor_proc->alive) {
        croak "error running tor. Run tor manually to get a hint.";
    }

    return $tor_proc;
}


sub rotate_ip {
    my ($self) = @_;

    my $socket = $self->{_tor_socket};
    my $answer = q{};

    $socket->send("AUTHENTICATE\n");
    $socket->recv($answer, 1024);
    return 0 unless $answer eq "250 OK\r\n";

    $socket->send("SIGNAL NEWNYM\n");
    $socket->recv($answer, 1024);
    return 0 unless $answer eq "250 OK\r\n";

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::UserAgent::Tor - rotate your ips

=head1 SYNOPSIS

  use LWP::UserAgent::Tor;

  my $ua = LWP::UserAgent::Tor->new(
      tor_control_port => 9051,            # empty port on default range(49152 .. 65535)
      tor_port         => 9050,            # empty port on default range(49152 .. 65535)
      tor_config       => 'path/to/torrc', # tor default config path
  );

  if ($ua->rotate_ip) {
      say 'got another ip';
  }
  else {
      say 'try again?';
  }

=head1 DESCRIPTION

Inherits directly form LWP::UserAgent. Launches tor proc in background
and connects to it via socket. Every method call of C<rotate_ip> will send
a request to change the exit node and return 1 on sucess.

=head1 METHODS

=head2 rotate_ip

  $ua->rotate_ip;

Try to get another exit node via tor.
Returns 1 for success and 0 for failure.

=head1 ACKNOWLEDGEMENTS

Inspired by a script of ac0v overcoming some limitations (no more!) of web scraping...

=head1 LICENSE

This is released under the Artistic License.

=head1 AUTHOR

spebern <bernhard@specht.net>

=cut
