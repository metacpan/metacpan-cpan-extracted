=head1 NAME

DynGig::CLI::Multiplex::CMD - CLI for DynGig::Multiplex::CMD

=cut
package DynGig::CLI::Multiplex::CMD;

use warnings;
use strict;
use Carp;

use YAML::XS;
use IO::Select;
use Pod::Usage;
use Getopt::Long qw( :config no_ignore_case pass_through );

use DynGig::Multiplex::CMD;
use DynGig::Range::String;
use DynGig::Util::Sysrw;
use DynGig::Util::CLI;

$| ++;

=head1 EXAMPLE

 use DynGig::CLI::Multiplex::CMD;

 DynGig::CLI::Multiplex::CMD->main( timeout => 30, max => 30 );

=head1 SYNOPSIS

$exe B<--help>

$exe B<--range> range [B<--timeout> seconds] [B<--max> parallelism]
[B<--verbose> 1 or 2] command ..

e.g.

echo blah | $exe -r 1~10 wc

$exe -r host1~10 -m 5 -t 10 -v 2 ssh {} uptime

=cut
sub main
{
    my ( $class, %option ) = @_;

    map { croak "$_ not defined" if ! defined $option{$_} } qw( max timeout );

    my $menu = DynGig::Util::CLI->new
    (
        'h|help','help menu',
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

    Pod::Usage::pod2usage( %pod_param ) unless $option{r} && @ARGV;

    croak "poll: $!\n" unless my $select = IO::Select->new();
    
    my $buffer;

    $select->add( *STDIN );

    map { DynGig::Util::Sysrw->read( $_, $buffer ) } $select->can_read( 0.1 );
    
    my %config =
    (
        command => \@ARGV,
        buffer => $buffer,
        timeout => $option{timeout},
    );

    my %run =
    (
        multiplex => $option{max},
        verbose => $option{v} ? $option{v} > 1 ? *STDERR : *STDOUT : 0,
    );

    my $target = DynGig::Range::String->new( $option{r} )->list();

    YAML::XS::DumpFile \*STDOUT, _run( \%config, \%run, $target ) if @$target;

    return 0;
}

sub _run
{
    my ( $config, $run, $target ) = @_;
    my $client = DynGig::Multiplex::CMD->new( map { $_ => $config } @$target );

    die $client->error() unless $client->run( %$run );

    my $result = $client->result() || {};
    my $error = $client->error() || {};
    my %tally;
    
    die "no result\n" unless %$result || %$error;
    
    map { $result->{$_}{error} = $error->{$_} } keys %$error;

    for my $target ( keys %$result )
    {
        my $result = $result->{$target};
    
        for my $key ( keys %$result )
        {
            my $output = $result->{$key};
    
            if ( length $output )
            {
                $result->{$key} =~ s/\n+$//;
                push @{ $tally{$key} }, $target;
            }
            else
            {
                delete $result->{$key};
            }
        }
    }

    for my $key ( keys %tally )
    {
        my $target = $tally{$key};
        my $count = scalar @$target;
    
        $tally{$key} = "( $count ) " . DynGig::Range::String->serial( $target );
    }

    return $result, \%tally;
}

=head1 NOTE

See DynGig::CLI

=cut

1;

__END__
