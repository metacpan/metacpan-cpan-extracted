package Log::Log4perl::Appender::Chunk;
$Log::Log4perl::Appender::Chunk::VERSION = '0.012';
use Moose;

use Carp;
use Class::Load;
use Data::Dumper;
use Log::Log4perl::MDC;


# State variables:

# State can be:
# OFFCHUNK: No chunk is currently captured.
# INCHUNK: A chunk is currently captured in the buffer
# ENTERCHUNK: Entering a chunk from an OFFCHUNK state
# NEWCHUNK: Entering a NEW chunk from an INCHUNK state
# LEAVECHUNK: Leaving a chunk from an INCHUNK state

has '_creator_pid' => ( is => 'ro', isa => 'Int', required => 1 , default => sub{  $$ ; } );

has 'state' => ( is => 'rw' , isa => 'Str', default => 'OFFCHUNK' );
has 'previous_chunk' => ( is => 'rw' , isa => 'Maybe[Str]' , default => undef , writer => '_set_previous_chunk' );
has 'messages_buffer' => ( is => 'rw' , isa => 'ArrayRef[Str]' , default => sub{ []; });

# Settings:
has 'chunk_marker' => ( is => 'ro' , isa => 'Str', required => 1, default => 'chunk' );

# Store:
has 'store' => ( is => 'ro', isa => 'Log::Log4perl::Appender::Chunk::Store',
                 required => 1, lazy_build => 1);
has 'store_class' => ( is => 'ro' , isa => 'Str' , default => 'Null' );
has 'store_args'  => ( is => 'ro' , isa => 'HashRef' , default => sub{ {}; });

has 'store_builder' => ( is => 'ro' , isa => 'CodeRef', required => 1, default => sub{
                             my ($self) = @_;
                             sub{
                                 $self->_full_store_class()->new($self->store_args());
                             }
                         });

sub _build_store{
    my ($self) = @_;
    return $self->store_builder()->();
}

sub _full_store_class{
    my ($self) = @_;
    my $full_class = $self->store_class();
    if( $full_class =~ /^\+/ ){
        $full_class =~ s/^\+//;
    }else{
        $full_class = 'Log::Log4perl::Appender::Chunk::Store::'.$full_class;
    }
    Class::Load::load_class($full_class);
    return $full_class;
}


sub log{
    my ($self, %params) = @_;

    ## Any log within this method will be discarded.
    if( Log::Log4perl::MDC->get(__PACKAGE__.'-reentrance') ){
      return;
    }
    Log::Log4perl::MDC->put(__PACKAGE__.'-reentrance', 1);

    my $chunk = Log::Log4perl::MDC->get($self->chunk_marker());

    # Change the state according to the chunk param
    $self->state( $self->_compute_state($chunk) );

    # Act according to the state.
    my $m_name = '_on_'.$self->state();

    $self->$m_name(\%params);

    $self->_set_previous_chunk($chunk);
    Log::Log4perl::MDC->put(__PACKAGE__.'-reentrance', undef);
}

sub _on_OFFCHUNK{
    my ($self, $params) = @_;
    # Chunk is Off, nothing much to do.
}

sub _on_ENTERCHUNK{
    my ($self,$params) = @_;
    # Push the message in the buffer.
    push @{$self->messages_buffer()} , $params->{message};
}

sub _on_INCHUNK{
    my ($self, $params) = @_;
    # Push the message in the buffer.
    push @{$self->messages_buffer()} , $params->{message};
}

sub _on_NEWCHUNK{
    my ($self, $params) = @_;
    # Leave the chunk
    $self->_on_LEAVECHUNK($params);
    # And we are entering the new one.
    $self->_on_INCHUNK($params);
}

sub _on_LEAVECHUNK{
    my ($self) = @_;

    # The new message should not be pushed on the buffer,
    # As we left a chunk for no chunk.

    # Flush the buffer in one big message.
    my $big_message = join('',@{$self->{messages_buffer}});
    $self->messages_buffer( [] );

    # The chunk ID is in the previous chunk. This should NEVER be null
    my $chunk_id = $self->previous_chunk();
    unless( defined $chunk_id ){
        confess("Undefined previous chunk. This should never happen. Dont know where to put the big message:$big_message");
    }
    $self->store->store($chunk_id, $big_message);
}


sub DEMOLISH{
    my ($self) = @_;
    unless( $self->_creator_pid() == $$ ){ return ; }

    if( my $chunk_id = $self->previous_chunk() ){
        # Simulate transitioning to an non chunked section of the log.
        Log::Log4perl::MDC->put($self->chunk_marker() , undef );
        # Output an empty log.
        $self->log();
    }
}

sub _compute_state{
    my ($self, $chunk) = @_;
    my $previous_chunk = $self->previous_chunk();

    if( defined $chunk ){
        if( defined $previous_chunk ){
            if( $previous_chunk eq $chunk ){
                # State  is INCHUNK
                return 'INCHUNK';
            }else{
                # Chunks are different
                return 'NEWCHUNK';
            }
        }else{
            # No previous chunk.
            return 'ENTERCHUNK';
        }
    }else{
        # No chunk defined.
        if( defined $previous_chunk ){ # But a previous chunk
            return 'LEAVECHUNK';
        }else{
            # No previous chunk neither
            return 'OFFCHUNK';
        }
    }

    confess("UNKNOWN CASE. This should never be reached.");
}

__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

Log::Log4perl::Appender::Chunk - Group log messages in Identified chunks

=head1 DESCRIPTION

This appender will write group of Log lines (chunks) to the underlying store under
an ID that you choose.

A number of Store classes are shipped ( in Log::Log4perl::Appender::Chunk::Store::* ),
but it's very easy to write your own store, as it's essentially a Key/Value storage.

See L<Log::Log4perl::Appender::Chunk::Store> for more details.

=head2 How to mark chunks of logs.

Marking chunks of log rely on the Log4perl Mapped Diagnostic Context (MDC) mechanism.
See L<Log::Log4perl::MDC>

Essentially, each time you set a MDC key 'chunk' to something, this appender will start
recording chunks and fetch them to the storage when the key 'chunk' is unset or changes.

=head1 SYNOPSIS

=head2 In your code

Anywhere in your code:


  #  .. Use log4perl as usual ..

  ## Start capturing Log lines in an identified Chunk
  Log::Log4perl::MDC->put('chunk', "Your-Log-Chunk-Unique-ID-Key");

  #  .. Use Log4perl as usual ..

  ## Finish capturing in the identified Chunk
  Log::Log4perl::MDC->put('chunk',undef);

  #  .. Use Log4perl as usual ..
  $logger->info("Blabla"); # Triggers storing the log chunk

Then depending on the configured store, you will be able to retrieve your log chunks
from different places. See below.

=head2 Configuration


=head3 with built-in store Memory

Reference: L<Log::Log4perl::Appender::Chunk::Store::Memory>

log4perl.conf:

  log4perl.rootLogger=TRACE, Chunk

  log4perl.appender.Chunk=Log::Log4perl::Appender::Chunk

  # Built-in store class S3
  log4perl.appender.Chunk.store_class=Memory

  # Etc..
  log4perl.appender.Chunk.layout=..


=head3 With built-in store S3

log4perl.conf:

  log4perl.rootLogger=TRACE, Chunk

  log4perl.appender.Chunk=Log::Log4perl::Appender::Chunk

  # Built-in store class S3
  log4perl.appender.Chunk.store_class=S3
  # S3 Specific Arguments:
  log4perl.appender.Chunk.store_args.bucket_name=MyLogChunks
  log4perl.appender.Chunk.store_args.aws_access_key_id=YourAWSAccessKey
  log4perl.appender.Chunk.store_args.aws_secret_access_key=YourAWS

  # Optional:
  log4perl.appender.Chunk.store_args.retry=1
  log4perl.appender.Chunk.store_args.vivify_bucket=1

  log4perl.appender.Chunk.store_args.expires_in_days=3
  log4perl.appender.Chunk.store_args.acl_short=public-read

  # Etc..
  log4perl.appender.Chunk.layout=...

=head2 log

L<Log::Log4perl::Appender> framework method.

=head2 store

The instance of L<Log::Log4perl::Appender::Chunk::Store> this logger uses.

It's usually configured from the Log4perl configuration file as shown in the SYNOPSIS, but
you can also inject it from your application code:

  Log::Log4perl->appender_by_name('Chunk')->store($your_instance_of_storage);


=head2 DEMOLISH

Will attempt to store whatever is left in the buffer if your program
finishes before it could output any log file outside a Chunk capturing section.

=cut
