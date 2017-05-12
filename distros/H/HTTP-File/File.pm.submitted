#!/usr/bin/perl -w


use HTTP::Headers::UserAgent;
use File::Basename;
use strict;


$HTTP::File::VERSION = '3.5';

package HTTP::File;
sub platform {

    my $__platform;

    $__platform = HTTP::Headers::UserAgent::GetPlatform ($ENV{HTTP_USER_AGENT});
    $__platform =~ /^Win/ && return 'MSWin32';
    $__platform =~ /^MAC/ && return 'MacOS';
    $__platform =~ /x$/   && return '';


}

# wifd == warn if debug

sub wifd {    warn "HTTP::File --- $_[0]" if $_[1];  }

sub upload {

    my ($raw_file, $path, $save_as,$debug,$kludge) = @_; # <-- added  $save_as  parameter
    my $temp_dir = '/tmp';

    $path = $path ? $path : $temp_dir;
    my $platform = platform;

    wifd "raw_file \t $raw_file"  , $debug;
    wifd "path     \t $path"      , $debug;
    wifd "platform \t $platform"  , $debug;

  File::Basename::fileparse_set_fstype(platform);
    my ($basename,$junk,$junk2) = File::Basename::fileparse $raw_file;
    $save_as = $save_as ? $save_as : $basename; # <-- if $save_as is not defined save it under the $basename name

    wifd(sprintf("ref(raw_file) \t %s", ref($raw_file))  , $debug);
    wifd "raw_file \t $raw_file"  , $debug;
    wifd "path     \t $path"      , $debug;
    wifd "platform \t $platform"  , $debug;
    wifd "basename \t $basename"  , $debug;

    open  O, ">$path/$save_as" || die $!; # <-- changed to use $save_as variable
    (open  K, ">$temp_dir/$save_as" || die $!) if $kludge; # <-- changed to use $save_as variable
    {
	my $buffer;
	my $bytesread = read($raw_file,$buffer,1024);

	# let's exit with an error if read() returned undef
	die "error with file read: $!" if !defined($bytesread);

	# let's exit with an error if print() did not return true
	die "error with print: $!" unless (print O $buffer);
	if ($kludge) {
	    die "error with print: $!" unless (print K $buffer);
	}

	# let's redo the loop if we read > 0 chars on the last read
	redo unless !$bytesread;

    }
    close O;
    close K if $kludge;

    

    return $basename;

}


1;

=head1 NAME

HTTP::File - Routines to deal with HTML input type file (HTTP file upload).


=cut

=head1 SYNOPSIS 

=head2 CGI.pm example

C<savepage.html> looks like this:

<H1>Upload a webpage</H1>

<FORM METHOD=POST ENCTYPE="multipart/form-data" action="/cgi-bin/webplugin/savepage.cgi"> 

<INPUT TYPE=file name=FILE_UPLOAD size=35> 

<INPUT TYPE=submit NAME=Action VALUE="Upload Ahoy!">

</FORM>


C<savepage.cgi> looks like this:

#!/usr/bin/perl

use CGI;
use HTTP::File;

$cgi = new CGI;

$upload_path='/tmp';

$raw_file = $cgi->param('FILE_UPLOAD');
$basename = HTTP::File::upload($raw_file,$upload_path);


print $cgi->header;
print $cgi->start_html;

print "$basename upload successfully.<BR>Upload path: ";
print $upload_path ? $upload_path : '/tmp';

print $cgi->end_html;

=head2 HTML::Mason example

<FORM METHOD=POST ENCTYPE="multipart/form-data" action="receive-upload.html">
<INPUT TYPE=file name=PHOTO_FILE size=35>
</FORM>

... then in receive-upload.html

<%init>
    use HTTP::File;
</%init>

<%perl>
$output_path="/var/spool";
$raw_file=$ARGS{PHOTO_FILE};
HTTP::File::upload($raw_file, $output_path);
</%perl>


=head1 DESCRIPTION

HTTP::File is a module to facilitate file uploads from HTML file input.It 
detects the basename of the raw file across MacOS, Windows, and Unix/Linux 
platforms.

=cut

=head2 sub platform

Uses a subset of the functionality of HTTP::Headers::UserAgent to determine
the type of machine that uploaded the file.



=head2 sub upload

Upload RAW_FILE to the local disk to a specified PATH, or to /tmp if PATH
is not specified.

    Returns the basename of the uploaded file;


As of version 3.1, there are two new args to upload():

=over 4 

=item * $debug

A third argument, C<$debug>, if non-zero will send
debugging information to STDERR. 

=item * $kludge

A fourth argument, C<$kludge>, if non-zero, will also write
the read data to a file in the temp directory.

=back


=head1 AUTHOR

Terrence Brannon
tbone@cpan.org

A useful contribution by  Uros Gaber 
was to allow the specification of the
filename under which the uploaded file should be stored.

=cut


