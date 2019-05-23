package Mediafire::Api::UploadFile;

use 5.008001;
use utf8;
use strict;
use warnings;
use open qw(:std :utf8);
use Carp qw/croak carp/;
use URI::Escape;
use LWP::UserAgent;
use File::Basename;
use HTTP::Request;
use JSON::XS;
use MIME::Detect;
use Crypt::Digest::SHA256 qw/sha256_hex/;
use Time::HiRes qw/gettimeofday/;

use Mediafire::Api::File;

our $VERSION = '0.01';

my $DEFAULT_BUFF_SIZE           = 1048576;

############################ PRIVATE METHODS ############################################
my ($getSha256Sum, $checkUploadFile, $getFileFromCache, $checkResumeUpload, $getMimeType, $uploadF);

$getSha256Sum = sub {
    my ($fname) = @_;
    my $sha = Crypt::Digest::SHA256->new();
    $sha->addfile($fname);
    return $sha->hexdigest;
};

$checkUploadFile = sub {
    my ($self) = @_;

    my $url = 'https://www.mediafire.com/api/1.5/upload/check.php';

    my @sec = gettimeofday();
    my $microseconds = substr(join('', @sec), 0, 13);

    my %param = (
        'hash'              => $self->{file}->hash,
        'size'              => $self->{file}->size,
        'filename'          => $self->{file}->name,
        'unit_size'         => $self->{buff_size},
        'resumable'         => 'yes',
        'preemptive'        => 'yes',
        'folder_key'        => $self->{path},
        'session_token'     => $self->{session_token},
        'response_format'   => 'json',
        $microseconds       => '', 
    );

    my $param_str = join('&', map {"$_=" . uri_escape($param{$_})} keys %param);
    my $full_url = $url . '?' . $param_str;
    my $res = $self->{ua}->get($full_url);
    my $code = $res->code;
    if ($code ne '200') {
        croak "Wrong response code checkUploadFile(). Url: '$full_url'. Code: $code";
    }
    my $json_res = eval {
        decode_json($res->decoded_content);
    };
    if ($@) {
        croak "Can't parse respone '" . $res->decoded_content . "' to json";
    }

    # Get json response
    my $response = $json_res->{response};
    if ($response->{result} ne 'Success') {
        croak "checkUploadFile() not success";
    }

    # Limit exceeded
    if ($response->{storage_limit_exceeded} ne 'no') {
        croak "Can't checkUploadFile. Storage limit exceeded";
    }

    my $file_key = $response->{preemptive_quickkey} // $response->{duplicate_quickkey};
    $self->{file}->key($file_key);
    $self->{upload_url} = $response->{upload_url}->{resumable};
    return $response;
};

$getFileFromCache = sub {
    my ($self) = @_;

    my $url = 'https://www.mediafire.com/api/1.5/upload/instant.php';

    my @sec = gettimeofday();
    my $microseconds = substr(join('', @sec), 0, 13);

    my %param = (
        'hash'              => $self->{file}->hash,
        'size'              => $self->{file}->size,
        'filename'          => $self->{file}->name,
        'folder_key'        => $self->{path},
        'session_token'     => $self->{session_token},
        'response_format'   => 'json',
        $microseconds       => '', 
    );

    my $param_str = join('&', map {"$_=" . uri_escape($param{$_})} keys %param);
    my $full_url = $url . '?' . $param_str;
    my $res = $self->{ua}->get($full_url);
    my $code = $res->code;
    if ($code ne '200') {
        croak "Wrong response code checkUploadFile(). Url: '$full_url'. Code: $code";
    }
    my $json_res = eval {
        decode_json($res->decoded_content);
    };
    if ($@) {
        croak "Can't parse respone '" . $res->decoded_content . "' to json";
    }

    # Get json response
    my $response = $json_res->{response};
    if ($response->{result} ne 'Success') {
        croak "getFileFromCache() not success";
    }
    my $file_key = $response->{quickkey};
    $self->{file}->key($file_key);

    return 1;
};

$checkResumeUpload = sub {
    my ($self) = @_;

    my $ua = $self->{ua};
    my $url = 'https://ul.mediafireuserupload.com/api/1.5/upload/resumable.php';
    my %param = (
        'session_token'             => $self->{session_token},
        'uploadkey'                 => $self->{path},
        'response_format'           => 'json',
    );

    my $headers = [
        'Access-Control-Request-Method'         => 'POST',
        'Origin'                                => 'https://www.mediafire.com',
        'Access-Control-Request-Headers'        => 'content-type,x-filehash,x-filename,x-filesize,x-filetype,x-unit-hash,x-unit-id,x-unit-size',
        'Accept'                                => '*/*',
        'Accept-Encoding'                       => 'gzip, deflate, br',
        'Accept-Language'                       => 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
    ];
    my $param_str = join('&', map {"$_=" . uri_escape($param{$_})} keys %param);
    my $full_url = $url . '?' . $param_str;
    my $request = HTTP::Request->new('OPTIONS', $full_url, $headers);
    my $res = $ua->request($request);
    my $code = $res->code;
    if ($code ne '200') {
        croak "Wrong response code on url: '$full_url'. Code: $code";
    }

    return 1;

};

# Upload file
$uploadF = sub {
    my ($self) = @_;

    my $upload_file     = $self->{upload_file};

    my %param = (
        'session_token'         => $self->{session_token},
        'uploadkey'             => $self->{path},
        'response_format'       => 'json',
    );
    my $param_str = join('&', map {"$_=" . uri_escape($param{$_})} keys %param);
    my $url = $self->{upload_url} . '?' . $param_str;

    my $unit_id = 0;
    my $filebuf;
    open my $FH, "<$upload_file" or croak "Can't open $upload_file $!";
    binmode $FH;

    my $json_res;
    while (my $bytes = read($FH, $filebuf, $self->{buff_size})) {
        my $unit_hash = sha256_hex($filebuf);
        my @headers = ( 
            "Accept"            => "*/*",
            "Accept-Language"   => "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7",
            "Accept-Encoding"   => "gzip, deflate, br",
            "Content-Type"      => "application/octet-stream",
            "Referer"           => "https://www.mediafire.com/uploads",
            "Origin"            => "https://www.mediafire.com",
            "X-Filesize"        => $self->{file}->size,
            "X-Filename"        => $self->{file}->name,
            "X-Filetype"        => $getMimeType->($self->{file}->name),
            "X-Filehash"        => $self->{file}->hash,
            "X-Unit-Hash"       => $unit_hash,
            "X-Unit-Size"       => $bytes,
            "X-Unit-Id"         => $unit_id,
            "Content"           => $filebuf,
                    );
        my $res = $self->{ua}->post($url, @headers);
        my $code = $res->code;
        if ($code ne '200') {
            croak "Wrong response code on request to url '$url'. Code: '$code'";
        }

        $json_res = eval {
            decode_json($res->decoded_content);
        };
        if ($@) {
            croak "Can't decode response to json. Response: '" . $res->decoded_content . "'";
        }

        if ($json_res->{response}->{result} ne 'Success') {
            croak "Response on url '$url' not success";
        }

        # Check all units ready
        if ($json_res->{response}->{resumable_upload}->{all_units_ready} eq 'yes') {
            last;
        }

        ++$unit_id;
    }
    close $FH;

    # Check all units ready
    if ($json_res->{response}->{resumable_upload}->{all_units_ready} ne 'yes') {
        croak "Not all parts of file '$upload_file' uploaded. Wrong answer from server";
    }

    return 1;
};

$getMimeType = sub {
    my ($fname) = @_;
    my $default_mime = 'application/zip';
    my $mime = MIME::Detect->new();
    my @types = $mime->mime_types_from_name($fname);
    if (@types) {
        return $types[0]->mime_type;
    }
    return $default_mime;
};

########################################################################################


sub new {
    my ($class, %opt) = @_;
    my $self = {};
    $self->{ua}             = $opt{-ua}                 // croak "You must specify param '-ua' for method new";
    $self->{session_token}  = $opt{-session_token}      // croak "You must specify '-session_token' param";
    $self->{buff_size}      = $opt{-buff_size}          // $DEFAULT_BUFF_SIZE;
    bless $self, $class;
    return $self;
}

sub uploadFile {
    my ($self, %opt)            = @_;

    $self->{upload_file}        = $opt{'-file'} || croak "You must specify -file param for method uploadFile";
    $self->{path}               = $opt{'-path'} || 'myfiles';


    if (not -f $self->{upload_file}) {
        croak "File '" . $self->{upload_file} . "' not exists";
    }

    $self->{file} = Mediafire::Api::File->new(
        -size               => -s $self->{upload_file},
        -name               => basename($self->{upload_file}),
        -hash               => $getSha256Sum->($self->{upload_file}),
    );


    # Get upload url
    my $response = $self->$checkUploadFile();
    if ($response->{hash_exists} eq 'yes') {
        # No need upload file. Get file from cache
        $self->$getFileFromCache();
    }
    else {
        # Upload file
        $self->$checkResumeUpload();
        $self->$uploadF();
    }

    # Check exists file key
    if (not defined($self->{file}->key)) {
        croak "Key of upload file '$self->{upload_file}' not exists. Error on upload file to server";
    }

    return $self->{file};
}




1;
