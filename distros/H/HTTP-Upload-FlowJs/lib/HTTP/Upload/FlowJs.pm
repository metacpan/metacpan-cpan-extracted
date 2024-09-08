package HTTP::Upload::FlowJs;
use strict;
use Carp qw(croak);
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
use Text::CleanFragment 'clean_fragment';
use Data::Dumper;
use MIME::Detect;

our $VERSION = '0.02';

use JSON qw(encode_json decode_json);

=head1 NAME

HTTP::Upload::FlowJs - handle resumable multi-part HTTP uploads with flowjs

=head1 SYNOPSIS

This synopsis assumes a L<Plack>/L<PSGI>-like environment. There are
plugins for L<Dancer> and L<Mojolicious> planned. See
L<HTTP::Upload::FlowJs::Examples> for longer examples.

The C<flow.js> workflow assumes that your application handles two kinds of
requests, POST requests for storing the payload data and GET requests for
retrieving information about uploaded parts. You will have to make various calls
to the HTTP::Upload::FlowJs object to validate the incoming request at every
stage.

  use HTTP::Upload::FlowJs;

  my $uploads = '/tmp/flowjs_uploads/';
  my $flowjs = HTTP::Upload::FlowJs->new(
      incomingDirectory => $uploads,
      allowedContentType => sub { $_[0] =~ m!^image/! },
  );

  my @parameter_names = $flowjs->parameter_names();

  # In your POST handler for /upload:
  sub POST_upload {
    my $params = params();

    my %info;
    @info{ @parameter_names } = @{$params}{@parameter_names};
    $info{ localChunkSize } = -s $params{ file };
    # or however you get the size of the uploaded chunk

    # you might want to set this so users don't clobber each others upload
    my $session_id = '';
    my @invalid = $flowjs->validateRequest( 'POST', \%info, $session_id );
    if( @invalid ) {
        warn 'Invalid flow.js upload request:';
        warn $_ for @invalid;
        return [500,[],["Invalid request"]];
        return;
    };

    if( $flowjs->disallowedContentType( \%info, $session_id )) {
        # We can determine the content type, and it's not an image
        return [415,[],["File type disallowed"]];
    };

    my $chunkname = $flowjs->chunkName( \%info, undef );

    # Save or copy the uploaded file
    upload('file')->copy_to($chunkname);

    # Now check if we have received all chunks of the file
    if( $flowjs->uploadComplete( \%info, undef )) {
        # Combine all chunks to final name

        my $digest = Digest::SHA256->new();

        my( $content_type, $ext ) = $flowjs->sniffContentType();
        my $final_name = "file1.$ext";
        open( my $fh, '>', $final_name )
            or die $!;
        binmode $fh;

        my( $ok, @unlink_chunks )
            = $flowjs->combineChunks( \%info, undef, $fh, $digest );
        unlink @unlink_chunks;

        # Notify backend that a file arrived
        print sprintf "File '%s' upload complete\n", $final_name;
    };

    # Signal OK
    return [200,[],[]]
  };

  # This checks whether a file has been received completely or
  # needs to be uploaded again
  sub GET_upload {
    my $params = params();
    my %info;
    @info{ @parameter_names} = @{$params}{@parameter_names};

    my @invalid = $flowjs->validateRequest( 'GET', \%info, session->{connid} );
    if( @invalid ) {
        warn 'Invalid flow.js upload request:';
        warn $_ for @invalid;
        return [500, [], [] ];

    } elsif( $flowjs->disallowedContentType( \%info, $session_id)) {
        # We can determine the content type, and it's not an image
        return [415,[],["File type disallowed"]];

    } else {
        my( $status, @messages )
            = $flowjs->chunkOK( $uploads, \%info, $session_id );
        if( $status != 500 ) {
            # 200 or 416
            return [$status, [], [] ];
        } else {
            warn $_ for @messages;
            return [$status, [], [] ];
        };
    };
  };

=head1 OVERVIEW

L<flow.js|https://github.com/flowjs/flow.js> is a client-side Javascript upload
library that uploads
a file in multiple parts. It requires two API points on the server side,
one C<GET> API point to check whether a part already has been uploaded
completely and one C<POST> API point to send the data of each partial
upload to. This Perl module implements the backend functionality for
both endpoints. It does not implement the handling of the HTTP requests
themselves, but you likely already use a framework like L<Mojolicious>
or L<Dancer> for that.

=head1 METHODS

=head2 C<< HTTP::Upload::FlowJs->new >>

  my $flowjs = HTTP::Upload::FlowJs->new(
      maxChunkCount => 1000,
      maxFileSize => 10_000_000,
      maxChunkSize => 1024*1024,
      simultaneousUploads => 3,
      allowedContentType => sub {
          my($type) = @_;
          $type =~ m!^image/!; # we only allow for cat images
      },
  );

=over 4

B<incomingDirectory> - path for the temporary upload parts

Required

B<maxChunkCount> - hard maximum chunks allowed for a single upload

Default 1000

B<maxFileSize> - hard maximum total file size for a single upload

Default 10_000_000

B<maxChunkSize> - hard maximum chunk size for a single chunk

Default 1048576

B<minChunkSize> - hard minimum chunk size for a single chunk

Default 1024

The minimum chunk size is required since the file type detection
works on the first chunk. If the first chunk is too small, its file type
cannot be checked.

B<forceChunkSize> - force all chunks to be less or equal than C<maxChunkSize>

Default: true

Otherwise, the last chunk will be greater than or equal to C<maxChunkSize>
(the last uploaded chunk will be at least this size and up to two the size).

Note: when C<forceChunkSize> is C<false> it only make C<chunkSize> value in
L</jsConfig> equal to C<maxChunkSize/2>.

B<simultaneousUploads> - simultaneously allowed uploads per file

Default 3

This is just an indication to the Javascript C<flow.js> client
if you pass it the configuration from this object. This is not enforced
in any way yet.

B<allowedContentType> - subroutine to check the MIME type

The default is to allow any kind of file

If you need more advanced checking, do so after you've determined a file
upload as complete with C<< $flowjs->uploadComplete >>.

B<fileParameterName> - The name of the multipart POST parameter to use for the
file chunk

Default C<file>

=back

More interesting limits would be hard maxima for the number of pending
uploads or the number of outstanding chunks per user/session. Checking
these would entail a call to C<glob> for each check and thus would be
fairly disk-intensive on some systems.

=cut

sub new( $class, %options ) {
    croak "Need a directory name for the temporary upload parts"
        unless $options{ incomingDirectory };

    $options{ maxChunkCount } ||= 1000;
    $options{ maxFileSize } ||= 10_000_000;
    $options{ maxChunkSize } ||= 1024*1024;
    $options{ minChunkSize } //= 1024;
    $options{ forceChunkSize } //= 1;
    $options{ simultaneousUploads } ||= 3;
    $options{ mime } ||= MIME::Detect->new();
    $options{ fileParameterName } ||= 'file';
    $options{ allowedContentType } ||= sub { 1 };

    bless \%options => $class;
};

=head2 C<< $flowjs->incomingDirectory >>

Return the incoming directory name.

=cut

sub incomingDirectory( $self ) {
    $self->{incomingDirectory};
};

=head2 C<< $flowjs->mime >>

Return the L<MIME::Detect> instance.

=cut

sub mime($self) {
    $self->{mime}
};

=head2 C<< $flowjs->jsConfig >>

=head2 C<< $flowjs->jsConfigStr >>

  # Perl HASH
  my $config = $flowjs->jsConfig(
      target => '/upload',
  );

  # JSON string
  my $config = $flowjs->jsConfigStr(
      target => '/upload',
  );

Create a JSON string that encapsulates the configuration of the Perl
object for inclusion with the JS side of the world.

=cut

sub jsConfig( $self, %override ) {
    # The last uploaded chunk will be at least this size and up to two the size
    # when forceChunkSize is false
    my $chunkSize = $self->{maxChunkSize};
    $chunkSize = $chunkSize/2 unless $self->{forceChunkSize}; # / placate Filter::Simple

    +{
        (
            map { $_ => $self->{$_} } (qw(
                simultaneousUploads
                forceChunkSize
            ))
        ),
        chunkSize => $chunkSize,
        testChunks => 1,
        withCredentials => 1,
        uploadMethod => 'POST',
        %override,
    };
}

sub jsConfigStr( $self, %override ) {
    encode_json($self->jsConfig(%override))
}

=head2 C<< $flowjs->parameter_names >>

    my $params = params();                 # request params
    my @parameter_names = $flowjs->parameter_names; # params needed by Flowjs

    my %info;
    @info{ @parameter_names } = @{$params}{@parameter_names};

    $info{ file }           = $params{ file };
    $info{ localChunkSize } = -s $params{ file };

    my @invalid = $flowjs->validateRequest( 'POST', \%info );

Returns needed params for validating request.

=cut

sub parameter_names( $self, $required_params ) {
    my $params = $self->{parameter_names} ||= {
        flowChunkNumber      => 1,
        flowTotalChunks      => 1,
        flowChunkSize        => 1,
        flowCurrentChunkSize => 1,
        flowTotalSize        => 1,
        flowIdentifier       => 1,
        flowFilename         => 1,
        flowRelativePath     => 0,
    };

    if ( $required_params ) {
        return grep { $params->{$_} } keys( %{$params} );
    }

    return keys( %{$params} );
}

=head2 C<< $flowjs->validateRequest >>

    my $session_id = '';
    my @invalid = $flowjs->validateRequest( 'POST', \%info, $session_id );
    if( @invalid ) {
        warning 'Invalid flow.js upload request:';
        warning $_ for @invalid;
        status 500;
        return;
    };

Does formal validation of the request HTTP parameters. It does not
check previously stored information.

B<Note> when C<POST> there are addition required params C<localChunkSize>
and C<$self->{fileParameterName}> (default 'file').

=cut

sub validateRequest( $self, $method, $info, $sessionId=undef ) {
    # Validate the input somewhat
    local $Data::Dumper::Useqq = 1;

    my @invalid;

    my @required = $self->parameter_names('required');
    if( $method eq 'POST') {
        push @required, $self->{fileParameterName}, 'localChunkSize'
            ;
    };

    for my $param (@required) {
        if( ! exists $info->{ $param } or !defined $info->{$param}) {
            push @invalid, sprintf 'Parameter [%s] is required but is missing',
                                $param,
                                ;
        };
    };
    if( @invalid ) {
        return @invalid;
    };

    # Numbers should be numbers
    for my $param (qw(flowChunkNumber flowTotalChunks flowChunkSize flowTotalSize flowCurrentChunkSize)) {
        if( exists $info->{ $param } and $info->{ $param } !~ /^[0-9]+$/) {
            push @invalid, sprintf 'Parameter [%s] should be numeric, but is [%s]; set to 0',
                                $param,
                                Dumper $info->{$param}
                                ;
            $info->{ $param } = 0;
        };
    };

    # Check maximum chunk count
    for my $param (qw(flowChunkNumber flowTotalChunks )) {
        if( exists $info->{ $param } and not $info->{ $param } <= $self->{maxChunkCount}) {
            push @invalid, sprintf 'Parameter [%s] should be less than %d, but is [%s]',
                                $param,
                                $self->{maxChunkCount},
                                $info->{$param},
                                ;
        };
    };

    # The chunk number needs to be less than or equal to the total chunks
    if( ($info->{ flowChunkNumber } || 0) > ($info->{ flowTotalChunks } || 0)) {
        push @invalid, sprintf 'Flow chunk number [%s] is greater than the number of total chunks [%s]',
                            $info->{ flowChunkNumber },
                            $info->{ flowTotalChunks },
                            ;
    };

    # Filenames should contain no path fragments
    # This will interact badly with directory uploads, but oh well
    for my $param (qw(flowFilename)) {
        # Sanitize the filename
        if( exists $info->{ $param } and $info->{ $param } =~ m![/\\]! ) {
            push @invalid, sprintf 'Parameter [%s] contains invalid path segments',
                                $param,
                                Dumper $info->{$param}
                                ;
        };
    };

    # Filenames and paths should not contain upward directory references
    for my $param (qw(flowFilename flowRelativePath)) {
        # Sanitize the filename
        if( exists $info->{ $param } and $info->{ $param } =~ m![/\\]\.\.[/\\]! ) {
            push @invalid, sprintf 'Parameter [%s] contains invalid upward path segments [%s]',
                                $param,
                                Dumper $info->{$param}
                                ;
        };
    };

    # The filename shouldn't contain control characters
    for my $param (qw(flowFilename flowRelativePath)) {
        if( exists $info->{ $param } and $info->{ $param } =~ m![\x00-\x1f]! ) {
            push @invalid, sprintf 'Parameter [%s] contains control characters [%s]',
                                $param,
                                Dumper $info->{$param}
                                ;
        };
    };



    my $min_max_error = 0;
    for my $param (qw(flowChunkSize flowCurrentChunkSize)) {
        if( exists $info->{ $param } and $info->{ $param } > $self->{ maxChunkSize } ) {
            $min_max_error = 1;
            push @invalid, sprintf 'Uploaded chunk [%d] of file [%s] is too large [%d], allowed is [%d]',
                                $info->{flowChunkNumber},
                                $info->{flowFilename},
                                $info->{$param},
                                $self->{maxChunkSize},
                                ;

        }
    }

    for my $param (qw(flowChunkSize flowCurrentChunkSize)) {
        if( exists $info->{ $param } and $info->{ $param } < $self->{ minChunkSize }
            and ( $info->{flowChunkNumber} < $info->{flowTotalChunks} # only last chunk could be smaller
               or $info->{flowTotalChunks} <= 1                       # when total chunks > 1
            )
        ) {
            $min_max_error = 1;
            push @invalid, sprintf 'Uploaded chunk [%d] of file [%s] is too small [%d], allowed is [%d]',
                                $info->{flowChunkNumber},
                                $info->{flowFilename},
                                $info->{$param},
                                $self->{minChunkSize},
                                ;

        }
    }

    if( ! $min_max_error and ($info->{ flowTotalSize } || 0) > $self->{ maxFileSize } ) {
        # Uploaded file would be too large
        push @invalid, sprintf 'Uploaded file [%s] would be too large ([%d]) allowed is [%d]',
                            $info->{flowFilename},
                            $info->{flowTotalSize},
                            $self->{maxFileSize},
                            ;

    } elsif( ! $min_max_error and $method eq 'POST' and $info->{ localChunkSize } > $info->{flowChunkSize} ) {
        # Uploaded chunk is larger than the maximum chunk upload size
        push @invalid, sprintf 'Uploaded chunk [%d] of file [%s] is larger than it should be ([%d], allowed is [%d])',
                            $info->{flowChunkNumber},
                            $info->{flowFilename},
                            $info->{localChunkSize},
                            $self->{maxChunkSize},
                            ;

    } elsif( ! $min_max_error and $info->{ flowCurrentChunkSize } < $self->expectedChunkSize( $info ) ) {
        # Uploaded chunk is a middle or end chunk but is too small
        push @invalid, sprintf 'Uploaded chunk [%s] is too small ([%d]) expect [%d]',
                            $info->{flowChunkNumber},
                            $info->{flowCurrentChunkSize},
                            $self->expectedChunkSize( $info ),
                            ;

    } elsif( ! $min_max_error and $method eq 'POST' and $info->{ localChunkSize } < $info->{ flowCurrentChunkSize } ) {
        # Real uploaded chunk is smaller than provided chunk upload size
        push @invalid, sprintf 'Uploaded chunk [%s] is too small ([%d]) expect [%d]',
                            $info->{flowChunkNumber},
                            $info->{localChunkSize},
                            $info->{flowCurrentChunkSize},
                            ;

    } elsif( ! $min_max_error and $info->{ flowCurrentChunkSize } > $self->expectedChunkSize( $info ) ) {
        # Uploaded chunk is a middle or end chunk but is too large
        push @invalid, sprintf 'Uploaded chunk [%s] is too large ([%d]) expect [%d]',
                            $info->{flowChunkNumber},
                            $info->{flowCurrentChunkSize},
                            $self->expectedChunkSize( $info ),
                            ;

    } else {
        # Everything is OK with the chunk size and file size, I guess.

    };

    @invalid
};

=head2 C<< $flowJs->expectedChunkSize >>

    my $expectedSize = $flowJs->expectedChunkSize( $info, $chunkIndex );

Returns the file size we expect for the chunk C<$chunkIndex>. The index
starts at 1, if it is not passed in or zero, we assume it is for the current
chunk as indicated by C<$info>.

=cut

sub expectedChunkSize( $self, $info, $index=0 ) {
    # If we are not the last chunk, we need to be what the information says:
    $index ||= $info->{flowChunkNumber};
    if( ! $info->{flowTotalChunks}) {
        # Some kind of invalid request, it'll be zero
        return 0

    } elsif( $index != $info->{flowTotalChunks}) {
        return $info->{flowChunkSize}

    } elsif( ! $info->{flowChunkSize} ) {
        # No size, we guess it'll be zero:
        return 0

    } elsif( ! $info->{flowTotalSize} ) {
        # Total size is zero
        return 0;

    } else {
        # The last chunk can be smaller or sized just like all the chunks
        # if the file size happens to be divided by the chunk size
        if( $info->{flowTotalSize} % $info->{flowChunkSize}) {
            return $info->{flowTotalSize} % $info->{flowChunkSize}
        } else {
            return $info->{flowChunkSize}
        };
    }
}

=head2 C<< $flowjs->resetUploadDirectories >>

    if( $firstrun or $wipe ) {
        $flowJs->resetUploadDirectories( $wipe )
    };

Creates the directory for incoming uploads. If C<$wipe>
is passed, it will remove all partial files from the directory.

=cut

sub resetUploadDirectories( $self, $wipe=undef ) {
    my $dir = $self->{incomingDirectory};
    if( ! -d $dir ) {
        mkdir $dir
            or return $!;
    };
    if(   $wipe ) {
        unlink glob( $dir . "/*.part" );
    };

}

=head2 C<< $flowjs->chunkName >>

    my $target = $flowjs->chunkName( $info, $sessionid );

Returns the local filename of the chunk described by C<$info> and
the C<$sessionid> if given. An optional index can be passed in as
the third parameter to get the filename of another chunk than
the current chunk.

    my $target = $flowjs->chunkName( $info, $sessionid, 1 );
    # First chunk

=cut

sub chunkName( $self, $info, $sessionPrefix=undef, $index=0 ) {
    my $dir = $self->{incomingDirectory};
    $sessionPrefix = '' unless defined $sessionPrefix;
    my $chunkname = sprintf "%s/%s%s.part%03d",
                        $dir,
                        $sessionPrefix,
                        clean_fragment($info->{ flowIdentifier }),
                        $index || $info->{ flowChunkNumber },
                        ;
    $chunkname
}

=head2 C<< $flowjs->chunkOK >>

    my( $status, @messages ) = $flowjs->chunkOK( $info, $sessionPrefix );
    if( $status == 500 ) {
        warn $_ for @messages;
        return [ 500, [], [] ]

    } elsif( $status == 200 ) {
        # That chunk exists and has the right size
        return [ 200, [], [] ]

    } else {
        # That chunk does not exist and should be uploaded
        return [ 416, [],[] ]
    }

=cut

sub chunkOK($self, $info, $sessionPrefix=undef, $index=0) {
    my @messages = $self->validateRequest( 'GET', $info, $sessionPrefix );
    if( @messages ) {
        return 500, @messages
    };

    my $chunkname = $self->chunkName( $info, $sessionPrefix, $index );
    my $exists = -f $chunkname && -s $chunkname == $self->expectedChunkSize( $info, $index );
    if( $exists ) {
        return 200
    } else {
        return 416
    }
}

=head2 C<< $flowjs->uploadComplete( $info, $sessionPrefix=undef ) >>

  if( $flowjs->uploadComplete($info, $sessionPrefix) ) {
      # do something with the chunks
  }

=cut

sub uploadComplete( $self, $info, $sessionPrefix=undef ) {
    my $complete = 1;
    for( 1.. $info->{ flowTotalChunks }) {
        my( $status, @messages ) = $self->chunkOK( $info, $sessionPrefix, $_ ) ;
        $complete = $complete && $status == 200 && !@messages;
        if( ! $complete ) {
            # No need to check the rest
            last;
        };
    };
    !!$complete
}

=head2 C<< $flowjs->chunkFh >>

  my $fh = $flowjs->chunkFh( $info, $sessionid, $index );

Returns an opened filehandle to the chunk described by C<$info>. The session
and the index are optional.

=cut

sub chunkFh( $self, $info, $sessionPrefix=undef, $index=0 ) {
    my %info = %$info;
    $info{ chunkNumber } = $index if $index;
    my $chunkname = $self->chunkName( \%info, $sessionPrefix, $index );
    open my $chunk, '<', $chunkname
        or croak "Can't open chunk '$chunkname': $!";
    binmode $chunk;
    $chunk
}

=head2 C<< $flowjs->chunkContent >>

  my $content = $flowjs->chunkContent( $info, $sessionid, $index );

Returns the content of a chunk described by C<$info>. The session
and the index are optional.

=cut

sub chunkContent( $self, $info, $sessionPrefix=undef, $index=0 ) {
    my $chunk = $self->chunkFh( $info, $sessionPrefix, $index );
    local $/; # / placate Filter::Simple
    <$chunk>
}

=head2 C<< $flowjs->disallowedContentType( $info, $session ) >>

    if( $flowjs->disallowedContentType( $info, $session )) {
        return 415, "This type of file is not allowed";
    };

Checks that the subroutine validator passed in the constructor allows
this MIME type. Unrecognized files will be blocked.

=cut

sub disallowedContentType( $self, $info, $session=undef ) {
    my( $content_type, $image_ext ) = $self->sniffContentType($info,$session);
    if( !defined $content_type ) {
        # we need more chunks uploaded to check the content type
        return

    } elsif( $content_type eq '' ) {
        # We couldn't determine what the content type is?!
        return 1

    } elsif( !$self->{allowedContentType}->( $content_type )) {
        return $content_type || 1
    } else {
        return
    };
};

=head2 C<< $flowjs->sniffContentType( $info, $session ) >>

    my( $content_type, $image_ext ) = $flowjs->sniffContentType( $info, $session );
    if( !defined $content_type ) {
        # we need more chunks uploaded to check the content type

    } elsif( $content_type eq '' ) {
        # We couldn't determine what the content type is?!
        return 415, "This type of upload is not allowed";

    } elsif( $content_type !~ m!^image/(jpeg|png|gif)$!i ) {
        return 415, "This type of upload is not allowed";

    } else {
        # We allow this upload to continue, as it seems to have
        # an appropriate content type
    };

This allows for finer-grained checking of the MIME-type. See also
the C<allowedContentType> argument in the constructor and
L<< ->disallowedContentType >> for a more convenient way to quickly
check the upload type.

=cut

sub sniffContentType( $self, $info, $sessionPrefix=undef ) {
    my( $content_type, $image_ext );

    my( $status, @messages ) = $self->chunkOK( $info, $sessionPrefix, 1 );
    if( 200 == $status ) {
        my $fh = $self->chunkFh( $info, $sessionPrefix, 1 );
        my $t = $self->mime->mime_type($fh);
        if( $t ) {
            $content_type = $t->mime_type;
            $image_ext    = $t->extension;
        } else {
            $content_type = '';
            $image_ext    = '';
        };

    } else {
        # Chunk 1 not uploaded/complete yet
    }
    return $content_type, $image_ext;
};

=head2 C<< $flowjs->combineChunks $info, $sessionPrefix, $target_fh, $digest ) >>

  if( not $flowjs->uploadComplete($info, $sessionPrefix) ) {
      print "Upload not yet completed\n";
      return;
  };

  open my $file, '>', 'user_upload.jpg'
      or die "Couldn't create final file 'user_upload.jpg': $!";
  binmode $file;
  my $digest = Digest::SHA256->new();
  my($ok,@unlink) = $flowjs->combineChunks( $info, undef, $file, $digest );
  close $file;

  if( $ok ) {
      print "Received upload OK, removing temporary upload files\n";
      unlink @unlink;
      print "Checksum: " . $digest->md5hex;
  } else {
      # whoops
      print "Received upload failed, removing target file\n";
      unlink 'user_upload.jpg';
  };

=cut

sub combineChunks( $self, $info, $sessionPrefix, $target_fh, $digest=undef ) {
    my @unlink_chunks;
    my $ok = 1;
    for( 1.. $info->{ flowTotalChunks }) {
        my $chunkname = $self->chunkName( $info, $sessionPrefix, $_ );
        push @unlink_chunks, $chunkname;

        my $content = $self->chunkContent( $info, $sessionPrefix, $_ );
        $digest->add( $content )
            if $digest;
        print { $target_fh } $content;
    };
    return $ok, @unlink_chunks
}

=head2 C<< $flowjs->pendingUploads >>

  my $uploading = $flowjs->pendingUploads();

In scalar context, returns the number of pending uploads. In list context,
returns the list of filenames that belong to the pending uploads. This list
can be larger than the number of pending uploads, as one upload can have more
than one chunk.

=cut

sub pendingUploads( $self ) {
    my @files;
    my %uploads;

    my $incoming = $self->incomingDirectory;
    opendir my $dir, $incoming
        or croak sprintf "Couldn't read incoming directory '%s': %s",
            $self->incomingDirectory, $!;
    @files = sort
    map {
            (my $upload = $_) =~ s!\.part\d+$!!;
            $uploads{ $upload }++;
            $_
        }
    grep { -f }
    map {
        "$incoming/$_"
    } readdir $dir;

    wantarray ? @files : scalar keys %uploads;
}

=head2 C<< $flowjs->staleUploads( $timeout, $now ) >>

  my @stale_files = $flowjs->staleUploads(3600);

In scalar context, returns the number of stale uploads. In list context,
returns the list of filenames that belong to the stale uploads.

An upload is considered stale if no part of it has been written to since
C<$timeout> seconds ago.

The optional C<$timeout> parameter is the minimum age of an incomplete upload
before it is considered stale.

The optional C<$now> parameter is the point of reference for C<$timeout>.
It defaults to C<time>.

=cut

sub staleUploads( $self, $timeout = 3600, $now = time ) {
    my $cutoff = $now - $timeout;
    my %mtime;
    my @files = reverse sort $self->pendingUploads();
    for ( @files ) {
        (my $upload = $_) =~ s!\.part\d+$!!;
        if( ! exists $mtime{ $upload } or $mtime{ $upload } < $cutoff ) {
            my @stat = stat( $_ );
            # We want to remember the newest instance for this upload
            $mtime{ $upload } ||= 0;
            $mtime{ $upload } = $stat[9]
                if $stat[9] > $mtime{ $upload };
            #warn "$upload: $mtime{ $upload } ($stat[9])";
        } else {
            #warn "$upload has already younger known participant, is not stale";
        };
    };

    my %stale;
    @files = grep {
        (my $upload = $_) =~ s!\.part\d+$!!;
        if( exists $mtime{ $upload } and $mtime{ $upload } < $cutoff ) {
            $stale{ $upload } = 1;
        };
    } @files;

    wantarray ? @files : scalar keys %stale;
}

=head2 C<< $flowjs->purgeStaleOrInvalid( $timeout, $now ) >>

    my @errors = $flowjs->purgeStaleOrInvalid();

Routine to delete all stale uploads and uploads with an invalid
file type.

This is mostly a helper routine to run from a cron job.

Note that if you allow uploads of multiple flowJs instances into the same
directory, they need to all have the same allowed file types or this method
will delete files from another instance.

=cut

sub purgeStaleOrInvalid($self, $timeout = 3600, $now = time ) {
    # First, kill off all stale files
    my @errors;
    for my $f ($self->staleUploads( $timeout, $now )) {
        unlink $f or push @errors, [$f => "$!"];
    };

    for my $f ($self->pendingUploads()) {
        # Hmm - here we need to synthesize session info from a filename
        # not really easy, isn't it?!
    };

    @errors
};

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/HTTP-Upload-FlowJs>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Upload-FlowJs>
or via mail to L<bug-http-upload-flowjs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2009-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
