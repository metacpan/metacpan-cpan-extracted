# NAME

**Mailru::Cloud** - Simple REST API cloud mail.ru client

# VERSION
    version 0.02

# SYNOPSYS

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

# METHODS

## login(%opt)

Login on cloud.mail.ru server.Return csrf token if success. Die on error

    $cloud->login(-login => 'test', -password => '12345');
    Options:
        -login          => login form cloud.mail.ru
        -password       => password from cloud.mail.ru

## info()

Return hashref to info with keys: used\_space, total\_space, file\_size\_limit

    my $info = $cloud->info() || die "Can't get info";
    print "Used_space: $info->{used_space}\nTotal space: $info->{total_space}\nFile size limit: $info->{file_size_limit}\n";

## uploadFile(%opt)

Upload local file to cloud. Return full file name on cloud if success. Die on error

    my $uploaded_name = $cloud->uploadFile(-file => 'Temp.png');
    Options:
        -file           => Path to local file
        -path           => Folder on cloud
        -rename         => Rename file if exists (default: overwrite exists file)
    Get Mailru cloud hash of uploaded file
    my $hash = $cloud->get_last_uploaded_file_hash() || die "Can't get file hash";

## downloadFile(%opt)

Download file from cloud.mail.ru to local file. Method overwrites local file if exists. Return full file name on local disk if success. Die if error

    my $local_file = $cloud->downloadFile(-cloud_file => '/Temp/test', -file => 'test');
    Options:
        -cloud_file     => Path to file on cloud.mail.ru
        -file           => Path to local destination

## createFolder(%opt)

Create recursive folder on cloud.mail.ru. Return 1 if success, undef if folder exists. Die on error

    $cloud->creteFolder(-folder => '/Temp/test');
    Options:
        -folder     => Path to folder on cloud

## deleteResource(%opt)

Delete file/folder from cloud.mail.ru. Resource moved to trash. To delete run emptyTrash() method. Return 1 if success. Die on error

    $cloud->deleteResource(-path => '/Temp/test.txt');      #Delete file '/Temp/test.txt' from cloud
    Options:
        -path       => Path to delete resource

## emptyTrash()

Empty trash on cloud.mail.ru. Return 1 if success. Die on error

    $cloud->emptyTrash();

## listFiles(%opt)

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

## shareResource(%opt)

Share resource for all. Return weblink if success. Die if error

    my $link = $cloud->shareResource(-path  => '/Temp/');           Share folder /Temp
    Options:
        -path       => Path to shared resource

# DEPENDENCE

[LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent), [JSON::XS](https://metacpan.org/pod/JSON::XS), [URI::Escape](https://metacpan.org/pod/URI::Escape), [IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL), [Encode](https://metacpan.org/pod/Encode), [HTTP::Request](https://metacpan.org/pod/HTTP::Request), [Carp](https://metacpan.org/pod/Carp), [File::Basename](https://metacpan.org/pod/File::Basename)

# AUTHORS

- Pavel Andryushin <vrag867@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Andryushin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
