package GetWeb::File;

use URI::URL::file;
use MailBot::Config;

@ISA = qw( URI::URL::file );
use strict;

sub newlocal {
    my($class, $path) = @_;

    # untaint path
    
    # jf fix canonical url mismatch

    ($path =~ /\.\./)
	and die "cannot go below public dir";
    $path = "./".$path unless
	$path =~ /^\.\//;

    $path =~ m!^([_a-zA-Z0-9/.?%+-]+)$! or die "unsafe filename: $path\n";
    $path = $1;

#  Carp::Croak("Only implemented for Unix file systems")
#      unless $ostype eq "unix";
    # XXX: Should implement the same thing for other systems

    my $url = new URI::URL "file:";
    $url->path($path);
    $url;
}

sub local_path
{
    my $path = URI::URL::file::local_path(@_);

    # require Cwd;
    # my $cwd = Cwd::fastcwd();
    my $config = MailBot::Config::current;
    my $cwd = $config -> getPubDir();
    # die "cwd is $cwd";
    $cwd =~ s:/?$:/:; # force trailing slash on dir
    $path = (defined $path) ? $cwd . $path : $cwd;
    $path;
}
