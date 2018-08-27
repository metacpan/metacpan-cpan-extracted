package Gearman::ResponseParser::Taskset;
use version ();
$Gearman::ResponseParser::Taskset::VERSION = version->declare("2.004.015");

use strict;
use warnings;

use base "Gearman::ResponseParser";
use Carp ();
use Scalar::Util ();

=head1 NAME

Gearman::ResponseParser::Taskset - gearmand response parser implementation

=head1 DESCRIPTION


derived from L<Gearman::ResponseParser>

=head1 METHODS

=cut

sub new {
    my ($class, %opts) = @_;
    my $ts = delete $opts{taskset};
    (Scalar::Util::blessed($ts) && $ts->isa("Gearman::Taskset"))
        || Carp::croak
        "provided taskset argument is not a Gearman::Taskset reference";

    my $self = $class->SUPER::new(%opts);
    $self->{_taskset} = $ts;
    return $self;
} ## end sub new

=head2 on_packet($packet, $parser)

provide C<$packet> to L<Gearman::Taskset> process_packet

=cut

sub on_packet {
    my ($self, $packet, $parser) = @_;
    $self->{_taskset}->process_packet($packet, $parser->source);
}

=head2 on_error($msg)

die C<$msg>

=cut

sub on_error {
    my ($self, $errmsg) = @_;
    die "ERROR: $errmsg\n";
}

1;
