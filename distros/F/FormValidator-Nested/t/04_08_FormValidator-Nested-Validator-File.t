use strict;
use Test::More;

use FormValidator::Nested;
use FormValidator::Nested::ProfileProvider::YAML;

use CGI;

use utf8;

my ($fvt, $res, @error_params);

$fvt = FormValidator::Nested->new({
    profile_provider => FormValidator::Nested::ProfileProvider::YAML->new({
        dir => 't/var/profile',
    }),
});
# Copied from CGI.pm - http://search.cpan.org/perldoc?CGI
%ENV = (
    %ENV,
    'SCRIPT_NAME'       => '/test.cgi',
    'SERVER_NAME'       => 'perl.org',
    'HTTP_CONNECTION'   => 'TE, close',
    'REQUEST_METHOD'    => 'POST',
    'SCRIPT_URI'        => 'http://www.perl.org/test.cgi',
    'CONTENT_LENGTH'    => 3458,
    'SCRIPT_FILENAME'   => '/home/usr/test.cgi',
    'SERVER_SOFTWARE'   => 'Apache/1.3.27 (Unix) ',
    'HTTP_TE'           => 'deflate,gzip;q=0.3',
    'QUERY_STRING'      => '',
    'REMOTE_PORT'       => '1855',
    'HTTP_USER_AGENT'   => 'Mozilla/5.0 (compatible; Konqueror/2.1.1; X11)',
    'SERVER_PORT'       => '80',
    'REMOTE_ADDR'       => '127.0.0.1',
    'CONTENT_TYPE'      => 'multipart/form-data; boundary=xYzZY',
    'SERVER_PROTOCOL'   => 'HTTP/1.1',
    'PATH'              => '/usr/local/bin:/usr/bin:/bin',
    'REQUEST_URI'       => '/test.cgi',
    'GATEWAY_INTERFACE' => 'CGI/1.1',
    'SCRIPT_URL'        => '/test.cgi',
    'SERVER_ADDR'       => '127.0.0.1',
    'DOCUMENT_ROOT'     => '/home/develop',
    'HTTP_HOST'         => 'www.perl.org'
);

my $cgi = do {
    # Copied from FormValidator::Lite
    my $file = 't/var/file_post.txt';
    local *STDIN;
    open STDIN, "<", $file
      or die "missing test file $file";
    binmode STDIN;
    CGI->new;
};
{
    package MyUpload;
    sub new { bless { name => $_[1] }, $_[0] }
    sub size {
        my $file = $cgi->param($_[0]->{name});
        return unless $file;

        return $cgi->uploadInfo($file)->{'Content-Length'};
    }
}
{
    package MyFoo;
    sub new { bless { }, shift }
    sub param {
        return $cgi->param(@_);
    }
    sub upload {
        my ($self, $name) = @_;
        return MyUpload->new($name);
    }
}

{ # max_size
    check($cgi, 'validator/file_noerror', 0);
    check($cgi, 'validator/file', 1, 'hello_world', 'ファイルは10byte以内のファイルをアップロードしてください');

    check(MyFoo->new, 'validator/file_noerror', 0);
    check(MyFoo->new, 'validator/file', 1, 'hello_world', 'ファイルは10byte以内のファイルをアップロードしてください');
}


sub check {
    my ($param, $key, $error, $param_name, $msg) = @_;

    $res = $fvt->validate($param, $key);

    is $res->has_error => $error;

    my $error_params = $res->error_params;

    if ( $error ) {
        is $error_params->{$param_name}->[0]->msg => $msg;
    }
}

done_testing;

