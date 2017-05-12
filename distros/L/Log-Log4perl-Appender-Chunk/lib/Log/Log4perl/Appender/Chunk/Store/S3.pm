package Log::Log4perl::Appender::Chunk::Store::S3;
$Log::Log4perl::Appender::Chunk::Store::S3::VERSION = '0.012';
use Moose;
extends qw/Log::Log4perl::Appender::Chunk::Store/;


use Carp;

use Net::Amazon::S3;
use Net::Amazon::S3::Client;

use DateTime;

use Log::Log4perl;
my $LOGGER = Log::Log4perl->get_logger();

sub BEGIN{
    eval "require Net::Amazon::S3::Client;";
    if( $@ ){
        die "\n\nFor ".__PACKAGE__.": Cannot load Net::Amazon::S3::Client\n\n -> Please install that if you want to use S3 Log Chunk storage.\n\n";
    }
}

has 's3_client' => ( is => 'ro', isa => 'Net::Amazon::S3::Client', lazy_build => 1 );
has 'bucket' => ( is => 'ro' , isa => 'Net::Amazon::S3::Client::Bucket', lazy_build => 1);


has 'host' => ( is => 'ro', isa => 'Maybe[Str]');
has 'location_constraint' => ( is => 'ro', isa => 'Maybe[Str]');
has 'bucket_name' => ( is => 'ro' , isa => 'Str' , required => 1);
has 'aws_access_key_id' => ( is => 'ro' , isa => 'Str', required => 1 );
has 'aws_secret_access_key' => ( is => 'ro' , isa => 'Str' , required => 1);
has 'retry' => ( is => 'ro' , isa => 'Bool' , required => 1 , default => 1);

has 'log_auth_links' => ( is => 'ro' , isa => 'Bool' , required => 1, default => 0);

has 'with_forking' => ( is => 'ro', isa => 'Bool', default => 1 );


# Single object properties.

# Short access list name
has 'acl_short' => ( is => 'ro' , isa => 'Maybe[Str]', default => undef );

# Expires in this amount of days.
has 'expires_in_days' => ( is => 'ro' , isa => 'Maybe[Int]' , default => undef );

has 'vivify_bucket' => ( is => 'ro' , isa => 'Bool' , required => 1 , default => 0 );

sub _build_s3_client{
    my ($self) = @_;
    return Net::Amazon::S3::Client->new( s3 =>
                                         Net::Amazon::S3->new(
                                                              aws_access_key_id => $self->aws_access_key_id(),
                                                              aws_secret_access_key => $self->aws_secret_access_key(),
                                                              retry => $self->retry(),
                                                              ( $self->host() ? ( host => $self->host() ) : () )
                                                             ));
}

=head1 NAME

Log::Log4perl::Appender::Chunk::Store::S3 - Store chunks in an S3 bucket

=head1 SYNOPSIS

Example:

  # Built-in store class S3
  log4perl.appender.Chunk.store_class=S3
  # S3 Mandatory options
  log4perl.appender.Chunk.store_args.bucket_name=MyLogChunks
  log4perl.appender.Chunk.store_args.aws_access_key_id=YourAWSAccessKey
  log4perl.appender.Chunk.store_args.aws_secret_access_key=YourAWS


See L<Log::Log4perl::Appender::Chunk>'s synopsis for a more complete example.

=head1 OPTIONS

=over

=item bucket_name

Mandatory. Name of the Amazon S3 bucket to store the log chunks.

=item location_constraint

Optional. If your current Net::Amazon::S3 supports it, you can use that to set the location constraint
of the vivified bucket. See L<Net::Amazon::S3#add_bucket> for more info on supported constraints.

Note that if you specify a location constraint, you will have to follow Amazon's recommendation about
naming your bucket. See L<http://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html> for restriction
about bucket names. In Particular, if you are outside the US, you will not be able to have upper case characters
in your bucket name.

=item host

Optional. If the bucket you are using is not in the USA, and depending on the version of L<Net::Amazon::S3> you
have, you might want to set that to a different host, according to
L<http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region>

See <Net::Amazon::S3#new>

=item aws_access_key_id

Mandatory. Your S3 access key ID. See L<Net::Amazon::S3>

=item asw_secret_acccess_key

Mandatory. Your S3 Secret access key. See L<Net::Amazon::S3>

=item retry

Optional. See L<Net::Amazon::S3>

Defaults to true (1).

=item with_forking

Optional. Causes this to (double) fork before actually storing stuff to S3, so your processes
are not slowed down by slow transfers to S3. On highly loaded machines, this
could actually be slower than not forking at all. So set this to false (0) on higly
loaded machines.

Defaults to true (1).

=item acl_short

Optional. Shortcut to commonly used ACL rules. Valid values are:
private public-read public-read-write authenticated-read.

See L<https://metacpan.org/source/PFIG/Net-Amazon-S3-0.59/lib/Net/Amazon/S3/Client/Object.pm>

Defaults to undef, meaning your Amazon Bucket's default will be applied. That's probably
the most desirable behaviour.

=item expires_in_days

Optional. Amount of days in the future stored chunks should expire. No value means never.

Defaults to undef.

=item vivify_bucket

Optional. If true, this writer will attempt to vivify a non existing bucket name if possible.

Defaults to false.

=item log_auth_links

Optional. If true, this writer will log (at DEBUG level) the authenticated links to the stored chunks
in other log appenders.

Use with care as this could lead to confidential information leakage.

Defaults to false.

=back

=head1 METHODS

=head2 clone

Returns a fresh copy of myself based on the same settings. Mainly used internaly.

Usage:

 my $clone = $this->clone();

=cut

sub clone{
    my ($self) = @_;
    return __PACKAGE__->new({bucket_name => $self->bucket_name(),
                             aws_access_key_id => $self->aws_access_key_id(),
                             aws_secret_access_key => $self->aws_secret_access_key(),
                             retry => $self->retry(),
                             acl_short => $self->acl_short(),
                             expires_in_days => $self->expires_in_days(),
                             vivify_bucket => $self->vivify_bucket(),
                             log_auth_links => $self->log_auth_links(),
                             host => $self->host(),
                             location_constraint => $self->location_constraint(),
                             with_forking => $self->with_forking()
                            });
}

sub _build_bucket{
    my ($self) = @_;

    my $s3_client = $self->s3_client();
    my $bucket_name = $self->bucket_name();

    # Try to hit an existing bucket from the list
    my @buckets = $s3_client->buckets();
    foreach my $bucket ( @buckets ){
        if( $bucket->name() eq $bucket_name ){
            # Hit!
            return $bucket;
        }
    }

    unless( $self->vivify_bucket() ){
        confess("Could not find bucket ".$bucket_name." in this account [access_key_id='".$self->aws_access_key_id()."'] and no vivify_bucket option");
    }
    return $self->s3_client()->create_bucket( name => $bucket_name,
                                              ( $self->location_constraint() ? ( location_constraint => $self->location_constraint() ) : () )
                                          );
}

sub _expiry_ymd{
    my ($self) = @_;
    unless( $self->expires_in_days() ){
        return undef;
    }
    return DateTime->now()->add( days => $self->expires_in_days() )->ymd();
}

=head2 store

See superclass L<Log::Log4perl::Appender::Chunk::Store>

=cut

sub store{
    my ($self, $chunk_id, $big_message) = @_;

    if( $self->with_forking() ){

        defined(my $child = fork()) or confess("Cannot fork: $!");
        if( $child ){
            ## We are the main parent. We wait for the child.
            waitpid($child, 0);
            return 1;
        }

        # We are the child
        # Double fork to avoid zombies.
        defined( my $grand_child = fork() ) or confess("Cannot double fork: $!");
        if( $grand_child ){
            # We are the child but we dont wait for
            # our grand child. It will be picked up by init
            exit(0);
        }
        # Grand child. We can do stuff.
        $self = $self->clone();
    }

    my $expires_ymd = $self->_expiry_ymd();
    my $s3object = $self->bucket()->object( key => $chunk_id,
                                            content_type => 'text/plain; charset=utf-8',
                                            $self->acl_short() ? ( acl_short => $self->acl_short() ) : (),
                                            $expires_ymd ? ( expires => $expires_ymd ) : (),
                                        );
    eval{
        $s3object->put(Encode::encode_utf8($big_message));
    };
    if( my $err = $@ ){
        $LOGGER->error("Log chunk storing error: $err");
        warn "Log chunk storing error: $err";
        exit(1);
    }
    if( $self->log_auth_links() ){
        $LOGGER->info("Stored log chunk in ".$s3object->query_string_authentication_uri());
    }

    if( $self->with_forking() ){
        exit(0);
    }else{
        return 1;
    }
}

__PACKAGE__->meta->make_immutable();
