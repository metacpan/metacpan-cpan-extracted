=head1 NAME

DynGig::CLI::Schedule::Make - Make a schedule config from polices

=cut
package DynGig::CLI::Schedule::Make;

use strict;
use warnings;

use Carp;
use YAML::XS;
use File::Spec;
use Pod::Usage;
use Getopt::Long;

use DynGig::Util::CLI;
use DynGig::Schedule::Policy;
use DynGig::Schedule::Override;

=head1 SYNOPSIS

$exe B<--help>

$exe [B<--timezone> zone] [B<--cycle> days] [B<--level> count]
[B<--config> dir] [B<--output> file] 

=cut
sub main
{
    my ( $class, %option ) = @_;

    map { croak "$_ not defined" if ! defined $option{$_} }
        qw( level timezone cycle config output );

    my $menu = DynGig::Util::CLI->new
    (
        'h|help','help menu',
        'level=i',"[ $option{level} ] levels of escalation",
        'cycle=i',"[ $option{cycle} ] number of days per cycle",
        'timezone=s',"[ $option{timezone} ] timezone",
        'config=s',"[ $option{config} ]",
        'output=s',"[ $option{output} ]",
    );
    
    Pod::Usage::pod2usage( -input => __FILE__, -output => \*STDERR )
        unless Getopt::Long::GetOptions( \%option, $menu->option() );

    if ( $option{h} )
    {
        warn join "\n", "Default value in [ ]", $menu->string(), "\n";
        return 0;
    }

    my %config;
    my $output = $option{output};
    my $config = $option{config};
    my $file = File::Spec->join( $config, 'policy' );

    delete $option{output};

    $config{policy} = DynGig::Schedule::Policy->new( %option, config => $file );
    $config{override} = DynGig::Schedule::Override
        ->new( %config, config => $file )
            if -f ( $file = File::Spec->join( $config, 'override' ) );

    YAML::XS::DumpFile $output, \%config;

    return 0;
}

=head1 NOTE

See DynGig::CLI

=cut

1;

__END__
