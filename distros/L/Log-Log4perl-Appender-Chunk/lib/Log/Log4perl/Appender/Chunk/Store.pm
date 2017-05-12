package Log::Log4perl::Appender::Chunk::Store;
$Log::Log4perl::Appender::Chunk::Store::VERSION = '0.012';
use Moose;

use Carp;

sub store{
    my ($self, $chunk_id , $big_message) = @_;
    die "sub 'store' is not Implemented in $self";
}

__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

Log::Log4perl::Appender::Chunk::Store - Store adapter baseclass

=head1 DESCRIPTION

This is the baseclass for all Store adapters used by the
L<Log::Log4perl::Appender::Chunk> appender.

=head1 IMPLEMENTING YOUR OWN

=head2 Write your subclass

Make a Moose subclass of this and implement the 'store' method.

Have a look at the minimalistic code in L<Log::Log4perl::Appender::Chunk::Store::Memory>.

Settings:

Settings should be plain Scalar Moose attributes. They will be injected from the configuration
file key 'store_args'.

=head2 Use your Store from the config file.

Set the store_class property of your Chunk appender to something like:

  log4perl.appender.Chunk.store_class=+My::L4p::Appender::Chunk::Store::MyStorage

Remember you can set some your storage class parameters like:

  log4perl.appender.Chunk.store_args.my_setting1=Setting1Value
  log4perl.appender.Chunk.store_args.my_setting2=Setting2Value


=head2 Use your Store from your application code.

If your Storage is too complex to build itself only from the configuration file properties, you can perfectly
build an instance of it and inject it in your Chunk Appender at run time (do that only once right after L4P init):

  my $store = .. An instance of your My::L4p::Appender::Chunk::Store::MyStorage
  if( my $chunk_appender = Log::Log4perl->appender_by_name('Chunk') ){
    $chunk_appender->store($store);
  }

Don't forget to change 'Chunk' by whatever name you gave to your Chunk appender in the config file.

=head1 METHODS

=head2 store

This method will be called by the L<Log::Log4perl::Appender::Chunk> to store a whole chunk of log lines
under the given chunk ID.

Implement it in any subclass like:

  sub store{
     my ($self, $chunk_id, $chunk) = @_;
     ...
  }

=cut
