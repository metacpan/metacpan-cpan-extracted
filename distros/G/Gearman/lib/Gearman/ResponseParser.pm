package Gearman::ResponseParser;
use version ();
$Gearman::ResponseParser::VERSION = version->declare("2.004.015");

use strict;
use warnings;
use Gearman::Util ();

=head1 NAME

Gearman::ResponseParser - gearmand abstract response parser implementation

=head1 DESCRIPTION


I<Gearman::ResponseParser> is an abstract base class.

See: L<Gearman::ResponseParser::Taskset>

Subclasses should call this first, then add their own data in underscore members

=head1 METHODS

=cut

#    Gearman::ResponseParser::Danga    (for Gearman::Client::Danga, the async version)
sub new {
    my $class = shift;
    my %opts  = @_;
    my $src   = delete $opts{'source'};
    die "unsupported arguments '@{[keys %opts]}'" if %opts;

    my $self = bless {

        # the source object/socket that is primarily feeding this.
        source => $src,
    }, $class;

    $self->reset;
    return $self;
} ## end sub new

=head2 source()

B<return> source. The source is object/socket

=cut

sub source {
    my $self = shift;
    return $self->{source};
}

=head2 on_packet($packet, $parser)

subclasses should override this

=cut

sub on_packet {
    my ($self, $packet, $parser) = @_;
    die "SUBCLASSES SHOULD OVERRIDE THIS";
}

=head2 on_error($msg, $parser)

subclasses should override this

=cut

sub on_error {
    my ($self, $errmsg, $parser) = @_;

    # NOTE: this interface will evolve.
    die "SUBCLASSES SHOULD OVERRIDE THIS";
} ## end sub on_error

=head2 reset()

=cut

sub reset {
    my $self = shift;
    $self->{header} = '';
    $self->{pkt}    = undef;
}

=head2 parse_data($data)

don't override:
FUTURE OPTIMIZATION: let caller say "you can own this scalarref", and then we can keep it
on the initial setting of $self->{data} and avoid copying into our own.  overkill for now.

=cut

sub parse_data {
    my ($self, $data) = @_;    # where $data is a scalar or scalarref to parse
    my $dataref = ref $data ? $data : \$data;

    my $err = sub {
        my $code = shift;
        $self->on_error($code);
        return undef;
    };

    while (my $lendata = length $$data) {

        # read the header
        my $hdr_len = length $self->{header};
        unless ($hdr_len == 12) {
            my $need = 12 - $hdr_len;
            $self->{header} .= substr($$dataref, 0, $need, '');
            next unless length $self->{header} == 12;

            my ($magic, $type, $len) = unpack("a4NN", $self->{header});
            return $err->("malformed_magic") unless $magic eq "\0RES";

            my $blob = "";
            $self->{pkt} = {
                type    => Gearman::Util::cmd_name($type),
                len     => $len,
                blobref => \$blob,
            };
            next;
        } ## end unless ($hdr_len == 12)

        # how much data haven't we read for the current packet?
        my $need = $self->{pkt}{len} - length(${ $self->{pkt}{blobref} });

        # copy the MAX(need, have)
        my $to_copy = $lendata > $need ? $need : $lendata;

        ${ $self->{pkt}{blobref} } .= substr($$dataref, 0, $to_copy, '');

        if ($to_copy == $need) {
            $self->on_packet($self->{pkt}, $self);
            $self->reset;
        }
    } ## end while (my $lendata = length...)

    if (defined($self->{pkt})
        && length(${ $self->{pkt}{blobref} }) == $self->{pkt}{len})
    {
        $self->on_packet($self->{pkt}, $self);
        $self->reset;
    } ## end if (defined($self->{pkt...}))
} ## end sub parse_data

=head2 eof()

don't override

=cut

sub eof {
    my $self = shift;

    $self->on_error("EOF");

    # ERROR if in middle of packet
} ## end sub eof

=head2 parse_sock($sock)

don't override

C<$sock> is readable, we should sysread it and feed it to L<parse_data($data)>

=cut

sub parse_sock {
    my ($self, $sock) = @_;
    my $res = Gearman::Util::read_res_packet($sock, \my $err);
    if ($err) {
        $self->on_error("read_error: ${$err}");
        return;
    }

    $self->{pkt} = $res;
    if (defined($self->{pkt})
        && length(${ $self->{pkt}{blobref} }) == $self->{pkt}{len})
    {
        $self->on_packet($self->{pkt}, $self);
        $self->reset;
    } ## end if (defined($self->{pkt...}))
} ## end sub parse_sock

1;
