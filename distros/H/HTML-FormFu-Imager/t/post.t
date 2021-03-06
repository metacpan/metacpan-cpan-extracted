use strict;
use warnings;

use Test::More;
use HTML::FormFu;

eval {
    require Imager;
    
    my $img = Imager->new;
    
    $img->read(file => 't/1x1.gif')
        or die $img->errstr;
};
if ($@) {
    plan skip_all => 
        "Your Imager intallation may not have GIF support: $@";
    die $@;
}

eval "use CGI";
if ($@) {
    plan skip_all => 'CGI required';
    die $@;
}

plan tests => 4;

# Copied from CGI.pm - http://search.cpan.org/perldoc?CGI

%ENV = (
    %ENV,
    'SCRIPT_NAME'       => '/test.cgi',
    'SERVER_NAME'       => 'perl.org',
    'HTTP_CONNECTION'   => 'TE, close',
    'REQUEST_METHOD'    => 'POST',
    'SCRIPT_URI'        => 'http://www.perl.org/test.cgi',
    'CONTENT_LENGTH'    => 3130,
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

my $q;

{
    my $file = 't/post.txt';
    local *STDIN;
    open STDIN, "<", $file
        or die "missing test file $file";
    binmode STDIN;
    $q = CGI->new;
}

my $form = HTML::FormFu->new->load_config_file('t/post.yml');

$form->process($q);

ok( $form->submitted_and_valid );

{
    my $file = $form->param('100x100_gif');
    
    isa_ok( $file, 'Imager' );
    
    is( $file->getwidth, 150 );
    is( $file->getheight, 150 );
}
