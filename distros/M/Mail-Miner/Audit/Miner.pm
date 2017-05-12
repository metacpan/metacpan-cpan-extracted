package Mail::Audit::Miner;
use vars qw($VERSION);
$VERSION = "0.01";

package Mail::Audit;
use MIME::Parser;
use Mail::Miner;

sub miner {
    my $self = shift;
    my $message = $self->as_string;
    my $entity = Mail::Miner::Mail->create(
                    $Mail::Miner::parser->parse_data($message)
                 )->content;
    $entity->{_audit_opts} = { %{ $self->{_audit_opts} } };
    $entity->{obj} = $entity;
    return bless $entity, "Mail::Audit::MimeEntity";
}

1;

=head1 NAME

Mail::Audit::Miner - A Mail::Audit extension for Mail::Miner

=head1 SYNOPSIS

    use Mail::Audit::Miner;
    my $item = new Mail::Audit(@foo);
    $item = $item->miner; # Yes, you must re-assign.

=head1 DESCRIPTION

This plugin to C<Mail::Audit> B<VERSION 2.1 OR ABOVE ONLY> calls
C<Mail::Miner>'s message processing functions to store information about
the incoming email. It also re-writes it, stripping attachments and
replacing them with information about how to get them back out of Miner
again.
