package Future::HTTP::Handler;
use Moo::Role;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

our $VERSION = '0.14';

=head1 NAME

Future::HTTP::Handler - common role for handling HTTP responses

=cut

has 'on_http_response' => (
    is => 'rw',
);

sub http_response_received( $self, $res, $body, $headers ) {
    $self->on_http_response( $res, $body, $headers )
        if $self->on_http_response;
    if( $headers->{Status} =~ /^[23]../ ) {
        $body = $self->decode_content( $body, $headers );
        $res->done($body, $headers);
    } else {
        $res->fail('error when connecting', $headers);
    }
}

no warnings 'once';
sub decode_content {
    my($self, $body, $headers) = @_;
    my $content_ref = \$body;
    my $content_ref_iscopy = 1;

    if (my $h = $headers->{'content-encoding'}) {
        $h =~ s/^\s+//;
        $h =~ s/\s+$//;
        for my $ce (reverse split(/\s*,\s*/, lc($h))) {
            next unless $ce;
            next if $ce eq "identity" || $ce eq "none";
            if ($ce eq "gzip" || $ce eq "x-gzip") {
                require IO::Uncompress::Gunzip;
                my $output;
                IO::Uncompress::Gunzip::gunzip($content_ref, \$output, Transparent => 0)
                    or die "Can't gunzip content: $IO::Uncompress::Gunzip::GunzipError";
                $content_ref = \$output;
                $content_ref_iscopy++;
            }
            elsif ($ce eq "x-bzip2" or $ce eq "bzip2") {
                require IO::Uncompress::Bunzip2;
                my $output;
                IO::Uncompress::Bunzip2::bunzip2($content_ref, \$output, Transparent => 0)
                or die "Can't bunzip content: $IO::Uncompress::Bunzip2::Bunzip2Error";
                $content_ref = \$output;
                $content_ref_iscopy++;
            }
            elsif ($ce eq "deflate") {
                require IO::Uncompress::Inflate;
                my $output;
                my $status = IO::Uncompress::Inflate::inflate($content_ref, \$output, Transparent => 0);
                my $error = $IO::Uncompress::Inflate::InflateError;
                unless ($status) {
                # "Content-Encoding: deflate" is supposed to mean the
                # "zlib" format of RFC 1950, but Microsoft got that
                # wrong, so some servers sends the raw compressed
                # "deflate" data.  This tries to inflate this format.
                $output = undef;
                require IO::Uncompress::RawInflate;
                unless (IO::Uncompress::RawInflate::rawinflate($content_ref, \$output)) {
                    #$self->push_header("Client-Warning" =>
                    #"Could not raw inflate content: $IO::Uncompress::RawInflate::RawInflateError");
                    $output = undef;
                }
                }
                die "Can't inflate content: $error" unless defined $output;
                $content_ref = \$output;
                $content_ref_iscopy++;
            }
            elsif ($ce eq "compress" || $ce eq "x-compress") {
                die "Can't uncompress content";
            }
            elsif ($ce eq "base64") {  # not really C-T-E, but should be harmless
                require MIME::Base64;
                $content_ref = \MIME::Base64::decode($$content_ref);
                $content_ref_iscopy++;
            }
            elsif ($ce eq "quoted-printable") { # not really C-T-E, but should be harmless
                require MIME::QuotedPrint;
                $content_ref = \MIME::QuotedPrint::decode($$content_ref);
                $content_ref_iscopy++;
            }
            else {
                die "Don't know how to decode Content-Encoding '$ce'";
            }
        }
    }

    return $$content_ref
}

sub mirror( $self, $url, $outfile, $args ) {
    if ( exists $args->{headers} ) {
        my $headers = {};
        while ( my ($key, $value) = each %{$args->{headers} || {}} ) {
            $headers->{lc $key} = $value;
        }
        $args->{headers} = $headers;
    }

    if ( -e $outfile and my $mtime = (stat($outfile))[9] ) {
        $args->{headers}{'if-modified-since'} ||= $self->_http_date($mtime);
    }
    my $tempfile = $outfile . int(rand(2**31));

    require Fcntl;
    sysopen my $fh, $tempfile, Fcntl::O_CREAT()|Fcntl::O_EXCL()|Fcntl::O_WRONLY()
         or croak(qq/Error: Could not create temporary file $tempfile for downloading: $!\n/);
    binmode $fh;
    $args->{on_body} = sub { print {$fh} $_[0] };
    my $response_f = $self->request('GET', $url, $args)->on_done(sub( $response_f ) {
        close $fh
            or croak(qq/Error: Caught error closing temporary file $tempfile: $!\n/);

        if ( $response_f->is_success ) {
            my $response = $response_f->get;
            rename $tempfile, $outfile
                or _croak(qq/Error replacing $outfile with $tempfile: $!\n/);
            my $lm = $response->{headers}{'last-modified'};
            if ( $lm and my $mtime = $self->_parse_http_date($lm) ) {
                utime $mtime, $mtime, $outfile;
            }
        }
        $response_f->{success} ||= $response_f->{status} eq '304';
        unlink $tempfile;

        $response_f
    });
    return $response_f;
}

1;
