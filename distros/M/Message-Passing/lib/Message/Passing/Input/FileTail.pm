package Message::Passing::Input::FileTail;
use Moo;
use MooX::Types::MooseLike::Base qw/ Str Int /;
use AnyEvent;
use Scalar::Util qw/ weaken /;
use POSIX ":sys_wait_h";
use Sys::Hostname::Long;
use AnyEvent::Handle;
use namespace::clean -except => 'meta';

use constant HOSTNAME => hostname_long();

with 'Message::Passing::Role::Input';

has filename => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has _tail_handle => (
    is => 'ro',
    lazy => 1,
    builder => '_build_tail_handle',
    clearer => '_clear_tail_handle',
);

has raw => (
    is => 'ro',
    default => sub { 0 },
);

sub _emit_line {
    my ($self, $line) = @_;

    my $data = $self->raw ? $line : {
        filename  => $self->filename,
        message   => $line,
        hostname  => HOSTNAME,
        epochtime => AnyEvent->now,
        type      => 'log_line',
    };
    $self->output_to->consume($data);
}

sub _build_tail_handle {
    my $self = shift;
    weaken($self);
    die("Cannot open filename '" . $self->filename . "'") unless -r $self->filename;
    my $child_pid = open(my $r, "-|", "tail", "-F", $self->filename)
       || die "can't fork: $!";

    my $cv = AnyEvent->condvar;

    my $hdl;
    $hdl = AnyEvent::Handle->new(
        fh => $r,
        on_read => sub {
          my ($hdl) = @_;
          $hdl->push_read(
            line => sub {
              my ($hdl, $line, $eof) = @_;
              $self->_emit_line($line);
            }
          );
        },
        on_eof => sub {
          # must re-initialize the original handle to continue tailing.
          # the timer isn't necessary, but just to be a good citizen.
          my $t;
          $t = AnyEvent->timer( after => 1, cb => sub {
            $t = undef;
            $hdl = init_tailer( $r);
          });
        },
        #on_error => $_handle_error,
    );
}

sub _init_tailer {
  my ($self, $fh) = @_;

  my $hdl;
  $hdl = AnyEvent::Handle->new(
    fh => $fh,
    on_read => sub {
      my ($hdl) = @_;
      $hdl->push_read(
        line => sub {
          my ($hdl, $line, $eof) = @_;
          $self->_emit_line($line);
        }
      );
    },
    on_eof => sub {
      # must re-initialize the original handle to continue tailing.
      # the timer isn't necessary, but just to be a good citizen.
      my $t;
      $t = AnyEvent->timer( after => 1, cb => sub {
        $t = undef;
        $self->_init_tailer($fh);
      });
    },
  );
}

sub BUILD {
    my $self = shift;
    $self->_tail_handle;
}


1;

=head1 NAME

Message::Passing::Input::FileTail - File tailing input

=head1 SYNOPSIS

    message-pass --input FileTail --input_options '{"filename": "/var/log/foo.log"} --output STDOUT
    {"filename":"/var/log/foo.log","message":"example line","hostname":"www.example.com","epochtime":"1346705476","type":"log_line"}

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 filename

The filename of the file to tail.

=head2 raw

If the file data should be output raw (as just a line). Normally lines are
output as a hash of data including the fields showing in the SYNOPSIS.

=head1 SEE ALSO

L<Message::Passing>

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API -
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut

