package TestServer::Plugin;
use strict;
use warnings;
use 5.010;

use Data::Dumper::Concise;
use JSON;

my %DISPATCH;
my %REGISTERED;

sub DISPATCH_TABLE {
    return \%TestServer::Plugin::DISPATCH;
}

sub register_dispatch {
    my $class = shift;
    return if $REGISTERED{$class}++;

    while ( my ( $path, $handler ) = splice @_, 0, 2 ) {
        if ( exists DISPATCH_TABLE->{$path} ) {
            my $package = get_package_for_subref(DISPATCH_TABLE->{$path});
            die "$class: dispatch entry for $path already defined in $package: "
                . Dumper(DISPATCH_TABLE->{$path});
        }
        else {
            DISPATCH_TABLE->{$path} = $handler;
        }
    }
}

sub get_package_for_subref {
    my $subref = shift;
    my $dumped = Dumper($subref);
    my ($package) = $dumped =~ /package\s+([^;]+)\s*;/;
    return $package;
}

sub response {
    my $self     = shift;
    my $server   = shift;
    my $content  = encode_json(shift);
    my $response = "Content-Type: application/json\r\n";
    $response   .= "Content-Length: ".length($content)."\r\n";
    $response   .= "\n$content";
    print $response;
}

1;
