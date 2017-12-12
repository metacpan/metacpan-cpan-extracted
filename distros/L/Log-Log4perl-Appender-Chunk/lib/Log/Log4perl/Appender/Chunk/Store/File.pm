package Log::Log4perl::Appender::Chunk::Store::File;
$Log::Log4perl::Appender::Chunk::Store::File::VERSION = '0.013';
use Moose;
extends qw/Log::Log4perl::Appender::Chunk::Store/;

use Log::Log4perl;
use File::Path ();
use File::Spec ();
use File::Temp ();

my $LOGGER = Log::Log4perl->get_logger();

has 'base_directory' => ( is => 'ro' , isa => 'Str' , default => sub { File::Temp::tempdir() });
has 'log_folder'     => ( is => 'ro' , isa => 'Str' , default => sub{ {'Log4perl_Appender_Chunk_Store_File'}; });

has '_logging_folder' => ( is => 'ro' , lazy_build => 1 );

sub _build__logging_folder {
    my ($self)= @_;
    return File::Spec->catfile($self->base_directory, $self->log_folder)
}

sub store{
    my ($self, $chunk_id, $big_message) = @_;
    my $logging_dir = $self->_logging_folder();
    unless ( -d $logging_dir ) {
        eval { File::Path::mkpath($logging_dir) };
        if ($@) {
            $LOGGER->trace("Couldn't create $logging_dir: $@");
            return;
        }
    }
    my $chunk_log_file = File::Spec->catfile($logging_dir, $chunk_id);
    $LOGGER->info("Stored log chunk in $chunk_log_file");

    File::Slurp::write_file(
        $chunk_log_file,
        {binmode => ':utf8'},
        $big_message
    );
    return 1;
}

__PACKAGE__->meta->make_immutable();
1;
__END__

=head1 NAME

Log::Log4perl::Appender::Chunk::Store::File - Stores chunks on disk

=head1 SYNOPSIS

Fist make sure you read L<Log::Log4perl::Appender::Chunk> documentation.

l4p.conf:

  log4perl.rootLogger=TRACE, Chunk

  layout_class=Log::Log4perl::Layout::PatternLayout
  layout_pattern=%m%n

  log4perl.appender.Chunk=Log::Log4perl::Appender::Chunk

  # Built-in store class File
  log4perl.appender.Chunk.store_class=File
  log4perl.appender.Chunk.store_args.base_directory=/tmp/
  log4perl.appender.Chunk.store_args.log_folder=chucks


See L<Log::Log4perl::Appender::Chunk>'s synopsis for a more complete example.

=head1 OPTIONS

=over

=item base_directory

Optional. This is the root folder for where the chunks live on the disk.

=item log_folder

Optional. The sub folder inside of the base directory where the chunks live.

=head2 store

See L<Log::Log4perl::Appender::Chunk::Store>

=cut
