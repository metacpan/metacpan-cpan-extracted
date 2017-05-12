package Log::Log4perl::Appender::Chunk::Store::Memory;
$Log::Log4perl::Appender::Chunk::Store::Memory::VERSION = '0.012';
use Moose;
extends qw/Log::Log4perl::Appender::Chunk::Store/;

use Log::Log4perl;

my $LOGGER = Log::Log4perl->get_logger();

has 'chunks' => ( is => 'rw' , isa => 'HashRef[Str]' , default => sub{ {}; });


sub clear{
  my ($self) = @_;
  $self->chunks({});
}

sub store{
  my ($self, $chunk_id, $big_message) = @_;
  $LOGGER->trace("Storing chunk ".$chunk_id);
  $self->chunks()->{$chunk_id} = $big_message;
}



__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Log::Log4perl::Appender::Chunk::Store::Memory - Stores chunks in memory

=head1 SYNOPSIS

Fist make sure you read L<Log::Log4perl::Appender::Chunk> documentation.

l4p.conf:

  log4perl.rootLogger=TRACE, Chunk

  layout_class=Log::Log4perl::Layout::PatternLayout
  layout_pattern=%m%n

  log4perl.appender.Chunk=Log::Log4perl::Appender::Chunk

  # Built-in store class Memory
  log4perl.appender.Chunk.store_class=Memory

Then from your code:

  my $store = Log::Log4perl->appender_by_name('Chunk')->store();

You can then inspect

  $store->chunks(); # A hash of all the chunks by chunk ID

Save memory from time to time:

  $store->clear();

=head2 store

See L<Log::Log4perl::Appender::Chunk::Store>

=head2 clear

Clears the chunks storage.

=cut
