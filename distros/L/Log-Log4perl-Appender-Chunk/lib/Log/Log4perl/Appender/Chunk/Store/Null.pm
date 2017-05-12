package Log::Log4perl::Appender::Chunk::Store::Null;
$Log::Log4perl::Appender::Chunk::Store::Null::VERSION = '0.012';
use Moose;
extends qw/Log::Log4perl::Appender::Chunk::Store/;

sub store{}

__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

Log::Log4perl::Appender::Chunk::Store::Null - A Storage that does nothing. This is the default.

=head2 store

See superclass L<Log::Log4perl::Appender::Chunk::Store>

=cut
