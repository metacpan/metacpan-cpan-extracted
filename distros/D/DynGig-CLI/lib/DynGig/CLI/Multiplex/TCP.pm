=head1 NAME

DynGig::CLI::Multiplex::TCP - CLI for DynGig::Multiplex::TCP

=cut
package DynGig::CLI::Multiplex::TCP;

use warnings;
use strict;
use Carp;

use YAML::XS;
use IO::Select;
use Pod::Usage;
use Getopt::Long;

use DynGig::Multiplex::TCP;
use DynGig::Range::String;
use DynGig::Util::Sysrw;
use DynGig::Util::CLI;

$| ++;

=head1 EXAMPLE

 use DynGig::CLI::Multiplex::TCP;

 DynGig::CLI::Multiplex::TCP->main( timeout => 30, max => 30 );

=head1 SYNOPSIS

$exe B<--help>

$exe B<--range> hosts B<--port> port
[B<--timeout> seconds] [B<--max> parallelism] [B<--verbose> 1 or 2] input ..

e.g.

$exe -r host1~10 -p 12345 -v 1 uptime

echo blah | $exe -r host1~10 -p 12345

=cut
sub main
{
    my ( $class, %option ) = @_;

    map { croak "$_ not defined" if ! defined $option{$_} } qw( max timeout );

    my $menu = DynGig::Util::CLI->new
    (
        'h|help','help menu',
        'p|port=i','remote port',
        'r|range=s','range of targets',
        'v|verbose=i','report progress to STDOUT (1) or STDERR (2)',
        'max=i',"[ $option{max} ] parallelism",
        'timeout=i',"[ $option{timeout} ] seconds timeout per target",
    );

    my %pod_param = ( -input => __FILE__, -output => \*STDERR );

    Pod::Usage::pod2usage( %pod_param )
        unless Getopt::Long::GetOptions( \%option, $menu->option() );

    if ( $option{h} )
    {
        warn join "\n", "Default value in [ ]", $menu->string(), "\n";
        return 0;
    }

    Pod::Usage::pod2usage( %pod_param ) unless $option{r} && $option{p};
    
    my $buffer;

    if ( @ARGV )
    {
        $buffer = join ' ', @ARGV;
    }
    elsif ( my $select = IO::Select->new() )
    {
        $select->add( *STDIN );

        map { DynGig::Util::Sysrw->read( $_, $buffer ) }
            $select->can_read( 0.1 );
    }
    else
    {
        croak "poll: $!\n";
    }
    
    my %config =
    (
        buffer => $buffer,
        timeout => $option{timeout},
    );

    my %run =
    (
        multiplex => $option{max},
        verbose => $option{v} ? $option{v} > 1 ? *STDERR : *STDOUT : 0,
    );

    my $port = ':' . $option{p};
    my $target = DynGig::Range::String->new( $option{r} )->list();

    YAML::XS::DumpFile \*STDOUT, _run( \%config, \%run, $target, $port )
        if @$target;

    return 0;
}
    
sub _run
{
    my ( $config, $run, $target, $port ) = @_;

    my $client = DynGig::Multiplex::TCP
        ->new( map { $_.$port => $config } @$target );

    die $client->error() unless $client->run( %$run );
    
    my $result = $client->result() || {};
    my $error = $client->error() || {};
    my %tally;
    
    die "no result\n" unless %$result || %$error;

    for my $hash ( $result, $error )
    {
        for my $output ( keys %$hash )
        {
            my $target = $hash->{$output};
    
            $output =~ s/\n+$//;
            map { $_ =~ s/$port$// } @$target;

            $tally{ DynGig::Range::String->serial( \@$target ) } = $output;
        }
    }
    
    return \%tally;
}

=head1 NOTE

See DynGig::CLI

=cut

1;

__END__

