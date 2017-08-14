package MToken::Server; # $Id: Server.pm 43 2017-07-31 13:04:58Z minus $
use strict;
use warnings FATAL => 'all';
use utf8;

=head1 NAME

MToken::Server - mod_perl2 server for storing backups of MToken devices

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    # Apache2 config section
    <Location /mtoken>
       SetHandler modperl
       PerlResponseHandler MToken::Server
       #PerlSetVar Debug 1
       PerlSetVar MTokenDir /var/www/mtoken
    </Location>

=head1 DESCRIPTION

To use the functionality of this module, you must edit the virtual-host section of
the Apache2 WEB server configuration file by specifying the directory for storing
backup files and authorization data. For example please run
command: "make serverconfig"

=head2 FUNCTIONS

=over 8

=item B<handler>

Handler for Apache2 WEB server

=item B<index_get>

This function returns a list of files on directory in the JSON format

    {
       "response_object" : "index_get",
       "data" : {
          "uri" : "/mtoken",
          "finished" : 1501500207,
          "is_index" : 1,
          "qs" : "",
          "started" : 1501500206,
          "method" : "GET",
          "finishedfmt" : "07/31/17 14:23:27 MSK",
          "location" : "/mtoken",
          "startedfmt" : "07/31/17 14:23:26 MSK",
          "debug" : 0,
          "filename" : "",
          "mtokendir" : "/var/www/mtoken/mtoken",
          "files" : [
             {
                "sha1" : "9a7cf5e50477dceab768fdc449eee233e3a9d670",
                "date_fmt" : "2017/07/26",
                "file" : "/var/www/mtoken/mtoken/myfooproject.20170726",
                "size" : 19830,
                "filename" : "myfooproject.20170726",
                "md5" : "4b435617553a7a226210b142ccb2cbcc",
                "date_sfx" : "20170726"
             }
          ]
       },
       "request_object" : null,
       "error" : [],
       "status" : 1
    }

=item B<index_post>

This function add new backup file to directory

=item B<file_get>

This function provides downloading the backup file from directory

=item B<file_put>

Update the backup file in the directory

=item B<file_delete>

This function provides removing the backup file from directory

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<LWP>, C<mod_perl2>, L<CTK>, C<openssl>, C<gnupg>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<CTK>, L<mod_perl2>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw/ $VERSION /;
$VERSION = "1.00";

use Encode;
use Encode::Locale;

use mod_perl2;
use Apache2::RequestIO ();
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::ServerRec ();
use Apache2::ServerUtil ();
use Apache2::Connection ();
use Apache2::Const -compile => qw/ :common :http /;
use Apache2::Log;
use Apache2::Util ();
use APR::Const -compile => qw/ :common /;
use APR::Table ();

use CGI -compile => qw/ :all /;
use JSON;
use File::Spec;
use File::Find;
use File::Basename;

use MToken::Util;

use constant {
        PREFIX => "MToken",
        LOCATION => "/mtoken",
        DATE_FORMAT => "%D %H:%M:%S %Z",
        OBJECTS_REQUIRED => [qw/
                index_post
            /],
        ERRORS => {
            0 => "Internal error",
            1 => "Can't create directory %s: %s",
            2 => "Incorrect permissions for directory %s. Required permissions: RWX for owner",
            3 => "Incorrect uploaded file name",
            4 => "Can't open file for saving %s: %s",
            5 => "Can't upload file %s",
            6 => "File size mismatch: Expected: %s; Got: %s",
            7 => "File md5sum mismatch: Expected: %s; Got: %s",
            8 => "File sha1sum mismatch: Expected: %s; Got: %s",
            9 => "Object mismatch: Expected: %s; Got: %s",
            10 => "File already exists: %s",
            11 => "Can't rewrite file, please use PUT command for updating it: %s",
            12 => "Can't delete file %s: %s",
            13 => "File not exists: %s",
            Apache2::Const::HTTP_NO_CONTENT => "No content",
            Apache2::Const::HTTP_BAD_REQUEST => "Bad request: %s",
            Apache2::Const::HTTP_METHOD_NOT_ALLOWED => "This method not allowed: %s",
        },
    };
my $DEBUG;

sub handler {
    my $r = shift;
    Apache2::RequestUtil->request($r);
    $r->handler('modperl');
    my $q = new CGI if $r->method ne 'PUT';
    $r->content_type('application/json; charset=utf-8');
    my $uri = $r->uri || ""; $uri =~ s/\/+$//;
    my $location = $r->location || LOCATION; $location =~ s/\/+$//;
    my $blank = {
            status  => 1,
            error   => [],
            request_object => scalar($q ? $q->param("object") : ''),
            data    => {
                    started => $r->request_time,
                    startedfmt => decode(locale => Apache2::Util::ht_time($r->pool, $r->request_time, DATE_FORMAT, 0)),
                    method => $r->method,
                    location => $location,
                    uri => $uri,
                    qs  => $r->args || "",
                },
        };
    my %json = %$blank;

    # Debug Mode
    $DEBUG = $r->dir_config("debug") || 0;
    $json{data}{debug} = $DEBUG ? 1 : 0;

    # Directory
    my $docroot = $r->document_root();
    my $mtokendir = $r->dir_config("mtokendir") // $docroot;
    unless (File::Spec->file_name_is_absolute($mtokendir)) {
        $mtokendir = File::Spec->catdir($docroot, $mtokendir);
    }
    unless (-e $mtokendir) {
        mkdir($mtokendir) or _set_error(\%json, 1, $mtokendir, $!) && return _output($r => \%json);
    }
    unless (-r $mtokendir and -w _ and -x _) {
        _set_error(\%json, 2, $mtokendir);
        return _output($r => \%json);
    }
    $json{data}{mtokendir} = $mtokendir;

    # Index & File
    my $is_index = 1;
    my $file = "";
    if ($uri =~ /\.[0-9]{8}$/) { # Is File by mask
        if (index($uri,$location,0) == 0) { # Catched!
            $file = substr($uri,length($location)+1);
            if ($file && $file !~ /\//) {
                $is_index = 0;
            }
        } else {
            $is_index = 1;
        }
    }
    $json{data}{is_index} = $is_index;
    $json{data}{filename} = $file;

    # Dispatching
    my $status = 0;
    my $meth = uc($r->method || "GET");
    if ($is_index) { # GET and POST for index
        if ($meth eq "GET" or $meth eq "HEAD") {
            $status = index_get($r, $q, \%json);
            _debug(sprintf("%s index: %s", $meth, $status ? 'OK' : 'ERROR'));
        } elsif ($meth eq "POST") {
            $status = index_post($r, $q, \%json);
            _debug(sprintf("%s index: %s", $meth, $status ? 'OK' : 'ERROR'));
        } else {
            _set_error(\%json, Apache2::Const::HTTP_METHOD_NOT_ALLOWED, $meth);
            _error("Error method %s", $meth);
        }
    } else { # GET, HEAD, PUT and DELETE for file
        if ($meth eq "GET" or $meth eq "HEAD") {
            $status = file_get($r, $q, \%json);
            _debug(sprintf("%s file: %s", $meth, $status == Apache2::Const::OK ? 'OK' : 'ERROR'));
            return $status;
        } elsif ($meth eq "PUT") {
            $status = file_put($r, $q, \%json);
            _debug(sprintf("%s file: %s", $meth, $status ? 'OK' : 'ERROR'));
        } elsif ($meth eq "DELETE") {
            $status = file_delete($r, $q, \%json);
            _debug(sprintf("%s file: %s", $meth, $status ? 'OK' : 'ERROR'));
        } else {
            _set_error(\%json, Apache2::Const::HTTP_METHOD_NOT_ALLOWED, $meth);
            _error("Error method %s", $meth);
        }
    }

    # Object mismatch
    my $obj_req = $json{request_object};
    my $obj_res = $json{response_object};
    if (grep {$_ eq $obj_res} @{(OBJECTS_REQUIRED())}) {
        unless ($obj_req) {
            _set_error(\%json, Apache2::Const::HTTP_BAD_REQUEST, "Object not specified");
            return _output($r => \%json);
        }
    }
    if ($obj_req && $obj_res) {
        if ($obj_req ne $obj_res) {
            _set_error(\%json, 9, $obj_req, $obj_res);
        }
    }

    # OUTPUT
    return _output($r => \%json);
}
sub index_get {
    my ($r, $q, $json) = @_;
    $json->{response_object} = "index_get";
    my $filename = $q->param("file") || $q->param("info");

    my @files = _get_file_list($json->{data}{mtokendir});
    if ($filename) {
        $json->{data}{info} = _get_file_info($filename, @files);
    } else {
        $json->{data}{files} = [@files];
    }
    return 1;
}
sub index_post {
    my ($r, $q, $json) = @_;
    $json->{response_object} = "index_post";
    my $mtokendir = $json->{data}{mtokendir};
    my $file_k = "file1";
    my $fileup = defined($q->param($file_k)) ? $q->param($file_k).'' : '';
    unless (defined($fileup) && length($fileup)) {
        _set_error($json, 3);
        return 0;
    }
    my $in_sha1 = $q->param("sha1");
    my $in_md5 = $q->param("md5");
    my $in_size = $q->param("size");

    my $exsts = _get_file_info($fileup, _get_file_list($mtokendir));
    if ($exsts) { # Catched!
        if (_ieq($exsts->{size}, $in_size) && _ieq($exsts->{md5}, $in_md5) && _ieq($exsts->{sha1}, $in_sha1)) {
            _set_error($json, 10, $fileup);
        } else {
            _set_error($json, 11, $fileup);
        }
        return 0;
    }

    $json->{data}{in} = {
        in_file => $fileup,
        in_sha1 => $in_sha1,
        in_md5  => $in_md5,
        in_size => $in_size,
    };

    my $file;
    if ($fileup && $fileup =~ /^[0-9a-z.\-_]+$/i) {
        $file = File::Spec->catfile($mtokendir, $fileup);
        unless (open(UPLOAD,">",$file)) {
            _set_error($json, 4, $file, $!);
            return 0;
        }
        binmode(UPLOAD);
        if ( my $fh = $q->upload($file_k) ) {
            binmode($fh);
            my $buffer;
            while ( my $bytesread = read($fh, $buffer,1024) ) {
                print UPLOAD $buffer;
            }
        } else {
            _set_error($json, 5, $fileup);
            close UPLOAD;
            return 0;
        }
        close UPLOAD;
    } else {
        _set_error($json, 3);
        return 0;
    }

    my $out_size = filesize($file);
    my $out_sha1 = sha1sum($file);
    my $out_md5 = md5sum($file);

    $json->{data}{out} = {
        out_file => $file,
        out_sha1 => $out_sha1,
        out_md5  => $out_md5,
        out_size => $out_size,
    };

    # Mismatch?
    my $miss = 1;
    if ($in_size != $out_size) {
        _set_error($json, 6, $in_size, $out_size);
        $miss = 0;
    }
    if ($in_md5 ne $out_md5) {
        _set_error($json, 7, $in_md5, $out_md5);
        $miss = 0;
    }
    if ($in_sha1 ne $out_sha1) {
        _set_error($json, 8, $in_sha1, $out_sha1);
        $miss = 0;
    }
    unless ($miss) {
        unless (unlink($file)  ) {
            _set_error($json, 12, $file, $!);
            return 0;
        }
    }
    return $miss;
}
sub file_get {
    my ($r, $q, $json) = @_;
    my $notes = $r->notes;

    $json->{response_object} = "file_get";
    my $mtokendir = $json->{data}{mtokendir};
    my $filename = $json->{data}{filename};
    my $file = File::Spec->catfile($mtokendir, $filename);

    return Apache2::Const::NOT_FOUND unless $filename && -e $file;
    my $len = filesize($file);
    return Apache2::Const::NOT_FOUND unless $len;
    $r->set_content_length($len);
    $r->content_type('application/octet-stream');
    $r->headers_out->set('Content-Disposition', sprintf("attachment; filename=\"%s\"", $filename));
    my $rc = $r->sendfile($file,0,$len);
    unless ($rc == APR::Const::SUCCESS) {
        my $errmsg = sprintf("Can't send file: %s (%s)", $filename, $file);
        _error($errmsg);
        $ENV{REDIRECT_ERROR_NOTES} = $errmsg;
        $r->subprocess_env(REDIRECT_ERROR_NOTES => $errmsg);
        $notes->set('error-notes' => $errmsg);
        return Apache2::Const::SERVER_ERROR;
    }

    return Apache2::Const::OK;
}
sub file_put {
    my ($r, $q, $json) = @_;
    $json->{response_object} = "file_put";

    my $mtokendir = $json->{data}{mtokendir};
    my $filename = $json->{data}{filename};
    my $file = File::Spec->catfile($mtokendir, $filename);

    unless ($filename && -e $file) {
        _set_error($json, 13, $file);
        return 0;
    }

    unless (open(UPDATE,">",$file)) {
        _set_error($json, 4, $file, $!);
        return 0;
    }
    binmode(UPDATE);
    my $buffer;
    while ( my $bytesread = $r->read($buffer, 1024) ) {
        print UPDATE $buffer;
    }
    close(UPDATE);

    my $size = filesize($file);
    unless ($size) {
        unless (unlink($file)  ) {
            _set_error($json, 12, $file, $!);
            return 0;
        }
        _set_error($json, 5, $file);
        return 0;
    }

    $json->{data}{out} = {
        out_file => $file,
        out_sha1 => sha1sum($file),
        out_md5  => md5sum($file),
        out_size => $size,
    };
    return 1;
}
sub file_delete {
    my ($r, $q, $json) = @_;
    $json->{response_object} = "file_delete";

    my $mtokendir = $json->{data}{mtokendir};
    my $filename = $json->{data}{filename};
    my $file = File::Spec->catfile($mtokendir, $filename);

    unless ($filename && -e $file) {
        _set_error($json, 13, $file);
        return 0;
    }
    unless (unlink($file)  ) {
        _set_error($json, 12, $file, $!);
        return 0;
    }

    return 1;
}

sub _output {
    my $r = shift;
    my $json = shift;
    my $tm = time();
    $json->{data}{finished} = $tm;
    $json->{data}{finishedfmt} = decode(locale => Apache2::Util::ht_time($r->pool, $tm, DATE_FORMAT, 0));

    my $output = to_json($json, { utf8  => 0, pretty => 1, });
    $r->headers_out->set('Accept-Ranges', 'none');
    $r->set_content_length(length(Encode::encode_utf8($output)) || 0);
    return Apache2::Const::OK if uc($r->method) eq "HEAD";
    $r->print($output);
    $r->rflush();
    return Apache2::Const::OK;
}
sub _set_error {
    my $json = shift;
    my $code = shift || 0;
    my @data = @_;
    my $msg = sprintf(ERRORS->{$code}, @data);
    push @{$json->{error}}, {code => $code, message => $msg};
    _debug(sprintf("Error: code=%d; message=\"%s\"", $code, $msg));
    $json->{status} = 0;
    return 1;
}
sub _debug {
    my $msg = shift;
    return 1 unless $DEBUG;
    return 0 unless defined $msg;
    my $r = Apache2::RequestUtil->request();
    $r->log->debug(sprintf("%s> %s", PREFIX, $msg)); # ---> Request ok :=)"
    return 1;
}
sub _error {
    my $msg = shift;
    return 0 unless defined $msg;
    my $r = Apache2::RequestUtil->request();
    $r->log->error(sprintf("%s> %s", PREFIX, $msg));
    return 1;
}
sub _get_file_list {
    my $dir = shift || '.';
    my @files;
    find({
      no_chdir => 1,
      wanted => sub {
        my $file = $_;
        my $filename = basename($_);
        return unless ((-f $file) && $file =~ /\.[0-9]{8}$/);
        my ($y,$m,$d) = ($1,$2,$3) if $file =~ /([0-9]{4})([0-9]{2})([0-9]{2})$/;
        push @files, {
                file        => $file,
                filename    => $filename,
                size        => filesize($file),
                md5         => md5sum($file),
                sha1        => sha1sum($file),
                date_sfx    => sprintf("%04d%02d%02d", $y,$m,$d),
                date_fmt    => sprintf("%04d/%02d/%02d", $y,$m,$d),
            };
    }}, $dir);
    return @files;
}
sub _get_file_info {
    my $filename = shift;
    foreach (@_) {
        return $_ if (ref($_) eq 'HASH') && $_->{filename} eq $filename;
    }
    return undef;
}
sub _ieq {
    my ($l, $r) = @_;
    return 0 unless defined $l;
    return 0 unless defined $r;

    if ($l =~ /^[0-9a-z]+$/i and $r =~ /^[0-9a-z]+$/i) {
        return ($l eq $r) ? 1 : 0;
    } elsif (($l =~ /^[0-9]+$/ and $r =~ /^[0-9]+$/)) {
        return ($l == $r) ? 1 : 0;
    }
    return 0;
}

1;

__END__
