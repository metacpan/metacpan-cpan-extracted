package Mailru::Cloud;

use 5.008001;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use Carp qw/croak carp/;
use URI::Escape;
use File::Basename;
use HTTP::Request;
use JSON::XS;
use Encode;
use IO::Socket::SSL;
use base qw/Mailru::Cloud::Auth/;

our $VERSION = '0.02';

my $BUFF_SIZE = 512;

sub uploadFile {
    my ($self, %opt)    = @_;
    my $upload_file     = $opt{'-file'} || croak "You must specify -file param for method uploadFile";
    my $path            = $opt{'-path'} || '/';
    my $rename          = $opt{'-rename'};
    $self->{file_hash}  = undef;

    $self->__isLogin();

    my $conflict_mode = $rename ? 'rename' : 'rewrite';

    if (not -f $upload_file) {
        croak "File $upload_file not exist";
    }

    if ($path !~ /\/$/) {
        $path .= '/';
    }

    my $request = 'https://cloclo18-upload.cloud.mail.ru/upload/?' .'cloud_domain=2&x-email=' . uri_escape($self->{email});

    my ($file_hash, $size) = $self->__upload_file($request, $upload_file) or return;
    $self->{file_hash} = $file_hash;
    
    #Опубликуем файл
    my %param = (
            'api'       => '2',
            'build'     => $self->{build},
            'conflict'  => $conflict_mode,
            'email'     => $self->{email},
            'hash'      => $file_hash,    
            'home'      => $path . basename($upload_file), 
            'size'      => $size,
            'token'     => $self->{authToken},   
            'x-email'   => $self->{email},
            'x-page-id' => $self->{'x-page-id'},
        );
    my $res = $self->{ua}->post('https://cloud.mail.ru/api/v2/file/add', \%param);

    my $code = $res->code;
    if ($code eq '200') {
        my $json = JSON::XS::decode_json($res->content); 
        my $new_fname = $json->{body};
        return $new_fname;
    }

    croak "Cant upload file $upload_file. Code: $code " . $res->decoded_content . "\n";
}

sub downloadFile {
    my ($self, %opt)    = @_;
    my $file            = $opt{-file}         || croak "You must specify -file param for method downloadFile";
    my $cloud_file      = $opt{-cloud_file}   || croak "You must specify -cloud_file param for method downloadFile";

    $self->__isLogin();

    my $FL;
    my $ua = $self->{ua};
    my $url = 'https://cloclo5.datacloudmail.ru/get/' . uri_escape($cloud_file) . '?x-email=' . uri_escape($self->{email});
    my $res = $ua->get($url, ':read_size_hint' => $BUFF_SIZE, ':content_cb' => sub {
                                                                                        if (not $FL) {
                                                                                            open $FL, ">$file", or croak "Cant open $file to write $!";
                                                                                            binmode $FL;
                                                                                        }
                                                                                        print $FL $_[0];
                                                                                    });
    my $code = $res->code;
    if ($code ne '200') {
        croak "Cant download file $cloud_file to $file. Code: $code";
    }
    close $FL if $FL;
    return 1;
}

sub createFolder {
    my ($self, %opt)    = @_;
    my $path            = $opt{-path} || croak "You must specify -path param for method createFolder";

    $self->__isLogin();

    my $ua = $self->{ua};
    my %param = (
        'api'       => '2',
        'build'     => $self->{build},
        'conflict'  => 'strict',
        'email'     => $self->{email},
        'home'      => $path,
        'token'     => $self->{authToken},
        'x-email'   => $self->{email},
        'x-page-id' => $self->{'x-page-id'},
    );
    my $res = $ua->post('https://cloud.mail.ru/api/v2/folder/add', \%param);

    my $code = $res->code;
    if ($code eq '200') {
        return 1;
    }
    if ($code eq '400') {
        carp "Can't create folder $path. Folder exists";
        return;
    }
    croak "Cant create folder $path. Code: $code";

}

sub deleteResource {
    my ($self, %opt)    = @_;
    my $path            = $opt{-path} || croak "You must specify -path options for method deleteResource";

    $self->__isLogin();

    my %param = (
        'api'           => '2',
        'build'         => $self->{build},
        'email'         => $self->{email},
        'home'          => $path,
        'token'         => $self->{authToken},
        'x-email'       => $self->{email},
        'x-page-id'     => $self->{'x-page-id'},
    );

    my $res = $self->{ua}->post('https://cloud.mail.ru/api/v2/file/remove', \%param);
    my $code = $res->code;

    if ($code eq '200') {
        return 1;
    }
    croak "Cant remove $path. Code: $code";
}

sub emptyTrash {
    my $self = shift;

    $self->__isLogin();

    my  %param = (
        'api'       => '2',
        'build'     => $self->{build},
        'email'     => $self->{email},      
        'token'     => $self->{authToken},   
        'x-email'   => $self->{email}, 
        'x-page-id' => $self->{'x-page-id'},   
    );

    my $res = $self->{ua}->post('https://cloud.mail.ru/api/v2/trashbin/empty', \%param);
    my $code = $res->code;

    if ($code eq '200') {
        return 1;
    }
    croak "Cant empty trash. Code: $code";
}

sub listFiles {
    my ($self, %opt)    = @_;
    my $path            = $opt{-path} || '/';
    my $orig_path       = $path;

    $self->__isLogin();
    $path = uri_escape($path);
    my $res = $self->{ua}->get('https://cloud.mail.ru/api/v2/folder' . '?token=' . $self->{authToken} . '&home=' . $path);
    my $code = $res->code;
    if ($res->is_success) {
        my $json_parsed = decode_json($res->content);
        my @list_files;
        
        for my $item (@{$json_parsed->{body}->{list}}) {
            my $h = {
                                'type'      => $item->{type},
                                'name'      => $item->{name},
                                'size'      => $item->{size},
                            };
            if ($item->{weblink}) {
                $h->{weblink} = 'https://cloud.mail.ru/public/' . $item->{weblink};
            }
            push @list_files, $h;
        }
        return \@list_files;
    }
    if ($code eq '404') {
        croak "Folder $orig_path not exists";
    }
    croak "Cant get file list for path: $orig_path. Code: $code"; 
}

sub shareResource {
    my ($self, %opt)    = @_;
    my $path            = $opt{-path} || croak "You must specify -path param for method shareResource";

    #Добавим слеш в начало, если его нет
    $path =~ s/^([^\/])/\/$1/;

    my %param = (
                    'api'           => '2',
                    'build'         => $self->{build},
                    'email'         => $self->{email},   
                    'home'          => $path,
                    'token'         => $self->{authToken},
                    'x-email'       => $self->{email}, 
                    'x-page-id'     => $self->{'x-page-id'},
    );

    my $res = $self->{ua}->post('https://cloud.mail.ru/api/v2/file/publish', \%param);
    my $code = $res->code;
    if ($code ne '200') {
        croak "Error on shareResource. Path: $path. Code: $code";
    }
    my $json = decode_json($res->decoded_content);
    my $link = 'https://cloud.mail.ru/public/' . $json->{body};
    return $link;
}

sub __upload_file {
    my ($self, $url, $file) = @_;

    my $u1 = URI->new($url);

#    $IO::Socket::SSL::DEBUG = 5;
    my $host = $u1->host;
    my $port = $u1->port;
    my $path = $u1->path;

    my $sock = IO::Socket::SSL->new(
                                        PeerAddr    => $host,
                                        PeerPort    => $port,
                                        Proto       => 'tcp',
                                    ) or croak "Cant connect to $host:$port";
    binmode $sock;
    $sock->autoflush(1);

    #Generate boundary
    my $boundary = '5';
    for (1..20) {
        $boundary .= int(rand(10) + 1);
    }
    $boundary = '----------------------------' . $boundary;

    my $content_disposition = 'Content-Disposition: form-data; name="file"; filename="' . basename($file) . '"' . "\n";
    $content_disposition .= "Content-Type: text/plain\n\n";
    my $length = (stat $file)[7];

    my @cookie_arr;
    $self->{ua}->cookie_jar->scan(sub {push @cookie_arr, "$_[1]=$_[2]"});
    my $cookie = join('; ', @cookie_arr);


    my @headers = ( "PUT $path HTTP/1.1",
                    "HOST: $host",
                    "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:46.0) Gecko/20100101 Firefox/46.0",
                    "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                    "Accept-Language: en-US,en;q=0.5",
                    "Accept-Encoding: gzip, deflate, br",
                    "Content-Type: multipart/form-data; boundary=$boundary",
                    "Connection: close",
                    "Referer: https://cloud.mail.ru/home/",
                    "Origin: https://cloud.mail.ru",
                    "Cookie: $cookie",
                    "X-Requested-With: XMLHttpRequest",
                );

    for my $head (@headers) {
        $sock->print($head . "\n");
    }

    $sock->print("Content-Length: $length\n");
    $sock->print("\n");


    open my $FH, "<$file" or croak "Cant open $file $!";
    binmode $FH;
    my $filebuf;
    while (my $bytes = read($FH, $filebuf, $BUFF_SIZE)) {
        $sock->print($filebuf);
    }
    $sock->print("\n");

    my @answer = $sock->getlines();
    $sock->close();

    #Если запрос успешен
    if ($answer[0] =~ /201/) {
        #Возврат хэша файла
        return (pop @answer, $length);
    }

    return;
}

################################## ACCESSORS ##########################3
#
sub get_last_uploaded_file_hash {
    return $_[0]->{file_hash};
}

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

B<Mailru::Cloud> - Simple REST API cloud mail.ru client

=head1 VERSION
    version 0.02

=head1 SYNOPSYS
    
    use Mailru::Cloud;
    my $cloud = Mailru::Cloud->new;
    
    #Authorize on cloud.mail.ru
    $cloud->login(-login => 'test', -password => '12345') or die "Cant login on mail.ru";

    #Upload file Temp.png to folder /folder on cloud.mail.ru
    my $uploaded_name = $cloud->uploadFile(
                            -file           => 'Temp.png',      # Path to file on localhost
                            -path           =>  '/folder',      # Path on cloud.
                            -rename         => 1,               # Rename file if exists (default: overwrite exists file)
                            );

    #Download file from cloud
    $cloud->downloadFile(
                            -cloud_file     => '/folder/Temp.png',
                            -file           => 'Temp.png',
                            );

=head1 METHODS

=head2 login(%opt)

Login on cloud.mail.ru server.Return csrf token if success. Die on error

    $cloud->login(-login => 'test', -password => '12345');
    Options:
        -login          => login form cloud.mail.ru
        -password       => password from cloud.mail.ru

=head2 info()

Return hashref to info with keys: used_space, total_space, file_size_limit
    
    my $info = $cloud->info() || die "Can't get info";
    print "Used_space: $info->{used_space}\nTotal space: $info->{total_space}\nFile size limit: $info->{file_size_limit}\n";


=head2 uploadFile(%opt)

Upload local file to cloud. Return full file name on cloud if success. Die on error

    my $uploaded_name = $cloud->uploadFile(-file => 'Temp.png');
    Options:
        -file           => Path to local file
        -path           => Folder on cloud
        -rename         => Rename file if exists (default: overwrite exists file)
    Get Mailru cloud hash of uploaded file
    my $hash = $cloud->get_last_uploaded_file_hash() || die "Can't get file hash";

=head2 downloadFile(%opt)

Download file from cloud.mail.ru to local file. Method overwrites local file if exists. Return full file name on local disk if success. Die if error

    my $local_file = $cloud->downloadFile(-cloud_file => '/Temp/test', -file => 'test');
    Options:
        -cloud_file     => Path to file on cloud.mail.ru
        -file           => Path to local destination

=head2 createFolder(%opt)

Create recursive folder on cloud.mail.ru. Return 1 if success, undef if folder exists. Die on error

    $cloud->creteFolder(-folder => '/Temp/test');
    Options:
        -folder     => Path to folder on cloud

=head2 deleteResource(%opt)

Delete file/folder from cloud.mail.ru. Resource moved to trash. To delete run emptyTrash() method. Return 1 if success. Die on error

    $cloud->deleteResource(-path => '/Temp/test.txt');      #Delete file '/Temp/test.txt' from cloud
    Options:
        -path       => Path to delete resource

=head2 emptyTrash()

Empty trash on cloud.mail.ru. Return 1 if success. Die on error

    $cloud->emptyTrash();

=head2 listFiles(%opt)

Return struct (arrayref) of files and folders. Die on error

    my $list = $cloud->listFiles(-path => '/');              #Get list files and folder in path '/'
    Options:
        -path       => Path to get file list (default: '/')
    Example output:
    [
        {
            type    => 'folder',                                         # Type file/folder  
            name    => 'Temp',                                           # Name of resource
            size    => 12221,                                            # Size in bytes
            weblink => 'https://cloud.mail.ru/public/4L8/K343',          # Weblink to resource, if resource shared
    },
    ]

=head2 shareResource(%opt)

Share resource for all. Return weblink if success. Die if error

    my $link = $cloud->shareResource(-path  => '/Temp/');           Share folder /Temp
    Options:
        -path       => Path to shared resource


=head1 DEPENDENCE

L<LWP::UserAgent>, L<JSON::XS>, L<URI::Escape>, L<IO::Socket::SSL>, L<Encode>, L<HTTP::Request>, L<Carp>, L<File::Basename>

=head1 AUTHORS

=over 4

=item *

Pavel Andryushin <vrag867@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Andryushin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
