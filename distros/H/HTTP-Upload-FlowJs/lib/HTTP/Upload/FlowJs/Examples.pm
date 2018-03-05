our $VERSION = '0.01';

=head1 NAME

HTTP::Upload::FlowJs::Examples - examples for HTTP::Upload::FlowJs

=head1 Pure PSGI example

This is a verbose example that assumes a PSGI / Plack environment
and some helper routines to handle the payload of POST parameters.

=head2 ASSUMPTIONS

It is assumed in the below code that your HTTP framework implements some
routines to retrieve information about the current request:

  sub params() {
      # return request parameters, both GET and POST parameters
      # as a hash reference
  }
  
  sub upload {
      # return something like a file system object to retrieve the content
      # of a file upload parameter
  }

=head2 SETUP

  use HTTP::Upload::FlowJs;

  my @parameter_names = (
    'file',                 # The name of the file
    'flowChunkNumber',      # The index of the chunk in the current upload.
                            # First chunk is 1 (no base-0 counting here).
    'flowTotalChunks',      # The total number of chunks.
    'flowCurrentChunkSize', # Current chunk size
    'flowChunkSize',        # The general chunk size. Using this value and
                            # flowTotalSize you can calculate the total number of
                            # chunks. Please note that the size of the data received in
                            # the HTTP might be lower than flowChunkSize of this for
                            # the last chunk for a file.
    'flowTotalSize',        #  The total file size.
    'flowIdentifier',       # A unique identifier for the file contained in the request.
    'flowFilename',         # The original file name (since a bug in Firefox results in
                            # the file name not being transmitted in chunk
                            # multipart posts).
    'flowRelativePath',     # The file's relative path when selecting a directory
                            # (defaults to file name in all browsers except Chrome).
  );
  
  my $uploads = '/tmp/flowjs_uploads/';
  my $flowjs = HTTP::Upload::FlowJs->new(
      incomingDirectory => $uploads,
      allowedContentType => sub { $_[0] =~ m!^image/! },
      parameter_names => \@parameter_names, # to override the default names
  );
  
=head2 POST handler

Your handler for POST requests is where you have to validate and store a
received chunk. This is also where you determine whether a file was received
completely and hand it off for further processing.

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

=head2 GET handler

The GET handler is used by the Javascript code to retrieve information about
whether a chunk already has been uploaded or not.
  
  sub GET_upload {
    my $params = params();
    my %info;
    @info{ @parameter_names} = @{$params}{@parameter_names};
    my $flowjs = HTTP::Upload::FlowJs->new(
        incomingDirectory => $uploads,
        allowedContentType => sub { $_[0] =~ m!^image/! },
    );

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

=cut

1;