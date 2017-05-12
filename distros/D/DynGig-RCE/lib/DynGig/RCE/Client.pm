=head1 NAME

DynGig::RCE::Client - RCE client. Extends DynGig::Multiplex::TCP.

=cut
package DynGig::RCE::Client;

use base DynGig::Multiplex::TCP;

use warnings;
use strict;

use File::Spec;
use Sys::Hostname;

use DynGig::RCE::Query;

=head1 SYNOPSIS

 use DynGig::RCE::Client;

 my %config =
 (
     buffer => +
     [
         {
             code => codename,
             param => ..
         },

         ...

         {
             code => ..
             param => ..
         },
     ],

     ## other DynGig::Multiplex::TCP::new() parameter
     ...
 );

 my $client = DynGig::RCE::Client->new( "$host:$port" => \%config );

 $client->run();

=cut
sub new
{
    my ( $class, %config ) = @_;
    my %done;
    my %client = 
    (
        prog => File::Spec->rel2abs( $0 ),
        host => Sys::Hostname::hostname(),
        user => scalar getpwuid $<,
    );

    for my $server ( keys %config )
    {
        my $config = $config{$server};
        my $nozip = delete $config->{nozip};

        next if $done{ $config->{buffer} };

        my %param = (
            client => \%client,
            query => $config->{buffer},
        );

        $param{mnumber} = $config->{mnumber}
            if defined $config->{mnumber};

        $config->{buffer} = DynGig::RCE::Query->new( %param )->zip( $nozip );

        $done{ $config->{buffer} } = 1;
    }

    bless DynGig::Multiplex::TCP->new( %config ), ref $class || $class;
}

=head1 NOTE

See DynGig::RCE

=cut

1;

__END__
