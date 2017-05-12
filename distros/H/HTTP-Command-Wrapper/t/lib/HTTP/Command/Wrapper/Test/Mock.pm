package HTTP::Command::Wrapper::Test::Mock;
use strict;
use warnings;
use utf8;

use Config;
use Cwd qw/abs_path/;
use Data::Section::Simple qw/get_data_section/;
use Exporter qw/import/;
use File::Basename qw/dirname/;
use File::Path qw/mkpath/;
use File::Slurp qw/write_file/;
use File::Spec;
use Sys::Info;

our @EXPORT = qw/
    create_binary_mock
    create_dummy_wgetrc
    create_dummy_curlrc
/;

my $data_path = abs_path(
    File::Spec->catfile(dirname(__FILE__), qw/.. .. .. .. .. data/));

sub create_binary_mock (&) {
    my $code      = shift;
    my $mock_path = File::Spec->catfile($data_path, 'bin');
    my $path      = $mock_path;
    my $info      = Sys::Info->new;

    if ($info->os->is_windows) {
        $path .= $Config{path_sep};
        $path .= dirname($ENV{COMSPEC});
    }

    else {
        $path .= $Config{path_sep};
        $path .= $ENV{PATH};
    }

    local $ENV{PATH} = $path;
    return $code->();
}

sub create_dummy_wgetrc (&) {
    my $code        = shift;
    my $wgetrc_path = File::Spec->catfile($data_path, 'rc/.wgetrc');
    my $wgetrc_dir  = dirname($wgetrc_path);
    my $wgetrc_data = get_data_section('.wgetrc');

    mkpath($wgetrc_dir) unless -d $wgetrc_dir;
    write_file($wgetrc_path, $wgetrc_data);

    local $ENV{WGETRC} = $wgetrc_path;
    return $code->();
}

sub create_dummy_curlrc (&) {
    my $code = shift;

    my $home_path   = File::Spec->catfile($data_path, 'rc/');
    my $curlrc_path = File::Spec->catfile($data_path, 'rc/.curlrc');
    my $netrc_path  = File::Spec->catfile($data_path, 'rc/.netrc');
    my $curlrc_data = get_data_section('.curlrc');

    mkpath($home_path) unless -d $home_path;
    write_file($netrc_path, '');
    write_file($curlrc_path, sprintf($curlrc_data, $netrc_path));

    local $ENV{CURL_HOME} = $home_path;
    return $code->();
}

1;
__DATA__
@@ .wgetrc
netrc = off
no_proxy = 127.0.0.1

@@ .curlrc
noproxy = "127.0.0.1"
netrc-file = "%s"
