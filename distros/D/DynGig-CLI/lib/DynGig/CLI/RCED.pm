=head1 NAME

DynGig::CLI::RCED - CLI for RCE Server

=cut
package DynGig::CLI::RCED;

use warnings;
use strict;
use Carp;

use Pod::Usage;
use Getopt::Long;

use DynGig::Util::CLI;
use DynGig::RCE::Server;

$| ++;

=head1 EXAMPLE

 use DynGig::CLI::RCED;

 DynGig::CLI::RCED->main
 (
     'access-file' => '/access/file/path',
     'code-dir' => '/code/dir/path',
     'max-buf' => 4092,
     'thread' => 20,
 );

=head1 SYNOPSIS

$exe B<--help>

$exe [B<--access-file> file] [B<--code-dir> dir] [B<--max-buf> size]
[B<--thread> number] B<--port> number | /unix/domain/socket/path

=cut
sub main
{
    my ( $class, %option ) = @_;

    map { croak "$_ not defined" if ! defined $option{$_} }
        qw( code-dir access-file max-buf thread );

    my $menu = DynGig::Util::CLI->new
    (
        'h|help',"print help menu",
        'port=s','server port or unix domain socket',
        'thread=i',"[ $option{thread} ] number of threads",
        'code-dir=s',"[ $option{'code-dir'} ] code directory",
        'access-file=s',"[ $option{'access-file'} ] access file",
        'max-buf=i',"[ $option{'max-buf'} ] max number of bytes in a request",
    );

    my %pod_param = ( -input => __FILE__, -output => \*STDERR );

    Pod::Usage::pod2usage( %pod_param )
        unless Getopt::Long::GetOptions( \%option, $menu->option() )
            && ( $option{port} || $option{h} );

    if ( $option{h} )
    {
        warn join "\n", "Usage:\tdefault value in [ ]", $menu->string(), "\n";
        return 0;
    }

    DynGig::RCE::Server->new( map { $_ => $option{$_} } qw( port thread ) )->run
    (
        max_buf => $option{'max-buf'},
        code_dir => $option{'code-dir'},
        access_file => $option{'access-file'}
    );

    return 0;
}

=head1 NOTE

See DynGig::CLI

=cut

1;

__END__
