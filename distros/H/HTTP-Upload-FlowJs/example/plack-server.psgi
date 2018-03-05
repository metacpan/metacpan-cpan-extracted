#!perl -w
use strict;
use Plack;
use Plack::Request;
use Plack::Builder;
use Plack::Middleware::Static;

use HTTP::Upload::FlowJs;
use File::Copy qw(cp mv);
use Digest::SHA1;
use File::Basename 'dirname';

=head1 USAGE

  plackup -a plack-server.psgi

=head1 CHECKLIST

Before putting this on a public server, consider the following:

=over 4

=item *

Run the server under a very restricted user

=item *

Set hard ulimits on the number of inodes and file system quota

=item *

Have a cleanup cron job that removes stale uploads

=back
  
=cut

# This is used to keep the query parameters all in one place
my @parameter_names = (
    'file', # The name of the file
    'flowChunkNumber', # The index of the chunk in the current upload.
                       # First chunk is 1 (no base-0 counting here).
    'flowTotalChunks', # The total number of chunks.
    'flowChunkSize', # The general chunk size. Using this value and
                     # flowTotalSize you can calculate the total number of
                     # chunks. Please note that the size of the data received in
                     # the HTTP might be lower than flowChunkSize of this for
                     # the last chunk for a file.
    'flowTotalSize', #  The total file size.
    'flowIdentifier', # A unique identifier for the file contained in the request.
    'flowFilename', # The original file name (since a bug in Firefox results in
                    # the file name not being transmitted in chunk
                    # multipart posts).
    'flowRelativePath', # The file's relative path when selecting a directory
                        # (defaults to file name in all browsers except Chrome).
);

my $app_base = (dirname $0); # all paths are relative to this!
my $complete_uploads = $app_base . '/user-uploads/';
my $partial_uploads = $app_base . '/flowjs-temp-uploads/';

my $flowjs = HTTP::Upload::FlowJs->new(
    incomingDirectory => $partial_uploads,
    allowedContentType => sub { $_[0] =~ m!^image/! },
    maxFileSize => 1_000_000,
);

# Wipe all temporary files
#$flowjs->resetUploadDirectories;

for ($complete_uploads, $partial_uploads) {
    if(! -d $_) {
        mkdir $complete_uploads
            or die "Couldn't create directory $_: $!";
    };
};

my $app = sub {
    my( $env ) = @_;
    my $req = Plack::Request->new( $env );
    my $path = $req->path_info;
    my $method = $req->method;
    
    #warn  "$method $path\n";
    
    if( $path eq '/' and $method eq 'GET') {
        return [302,[Location => '/static/index.html'], []];

    } elsif( $path eq '/upload' and $method eq 'GET') {
        return GET_upload($req)

    } elsif( $path eq '/upload' and $method eq 'POST') {
        return POST_upload($req)

    } else {
        return [404,[],['No such file']]
    }
};

# In your POST handler for /upload:
sub POST_upload {
    my( $req ) = @_;
    my $params = $req->parameters();
    
    my $upload = $req->uploads->{'file'};
    my %info;
  
    @info{ @parameter_names } = @{$params}{@parameter_names};
    $info{ localChunkSize } = $upload->size;
    $info{ file } = $upload; # not stored in %$params...
    # or however you get the size of the uploaded chunk
    
    # you might want to set this so users don't clobber each others upload
    my $session_id = '';
    my @invalid = $flowjs->validateRequest( 'POST', \%info, $session_id );
    if( @invalid ) {
        warn 'Invalid flow.js upload request:';
        warn $_ for @invalid;
        return [500,[],["Invalid request"]];
    };
  
    if( my $disallowed = $flowjs->disallowedContentType( \%info, $session_id )) {
        # We can determine the content type, and it's not an image
        return [415,[],["File type $disallowed disallowed"]];
    };
    my( $content_type, $image_ext ) = $flowjs->sniffContentType( \%info );
    warn "Uploaded $content_type ($image_ext)";

    my $chunkname = $flowjs->chunkName( \%info, undef );
  
    # Save or copy the uploaded file
    if( !cp( $upload->path, $chunkname)) {
        warn "Couldn't copy: $!";
        return [500,[],[]];
    };
  
    # Now check if we have received all chunks of the file
    if( $flowjs->uploadComplete( \%info, undef )) {
        # Combine all chunks to final name
  
        my $digest = Digest::SHA1->new();
  
        my( $content_type, $ext ) = $flowjs->sniffContentType(\%info);
        
        my $combine_name = $complete_uploads . "file1.$ext" . time() . $$;
        warn "Temp file for combining: $combine_name";
        my $fh;
        if(! open( $fh, '>', $combine_name )) {
            warn "$!";
            return [500,[],[]]
        };
        binmode $fh;
  
        my( $ok, @unlink_chunks )
            = $flowjs->combineChunks( \%info, undef, $fh, $digest );
        unlink @unlink_chunks;

        close $fh;
        
        my $final_name = $digest->hexdigest . '.' . $ext;
        mv( $combine_name => $complete_uploads . $final_name )
            or warn "Couldn't rename $combine_name to '$final_name': $!";
  
        # Notify backend that a file arrived
        warn sprintf "File '%s' upload complete\n", $final_name;
    };
  
    # Signal OK
    return [200,[],[]]
};

# This checks whether a file has been received completely or
# needs to be uploaded again
sub GET_upload {
    my( $req ) = @_;
    my $params = $req->parameters();
    print STDERR "Upload check\n";

    my %info;
    @info{ @parameter_names } = @{$params}{@parameter_names};
  
    my $session_id = undef; # well, use Plack::Middleware::Session
    my @invalid = $flowjs->validateRequest( 'GET', \%info, $session_id );
    if( @invalid ) {
        warn 'Invalid flow.js upload request:';
        warn $_ for @invalid;
        return [500, [], [] ];
  
    } elsif( $flowjs->disallowedContentType( \%info, $session_id)) {
        # We can determine the content type, and it's not an image
        return [415,[],["File type disallowed"]];
  
    } else {
        my( $status, @messages) = $flowjs->chunkOK( \%info, $session_id );
        if( $status != 500 ) {
            # 200 or 416
            return [$status, [], [] ];
        } else {
            # some malformed request
            warn $_ for @messages;
            
            return [500, [], [] ];
        };
    };
};

builder {
    enable "Plack::Middleware::Static",
        path => qr{^/static/},
        root => $app_base;
    $app;
};
