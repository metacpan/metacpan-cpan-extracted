package Devel::ebug::Plugin::SymbolBrowser;

use strict;
use base qw(Exporter);

our @EXPORT = qw(package_list symbol_list subroutine_info);

sub package_list {
    my( $self, $package ) = @_;
    my $response = $self->talk( { command   => "package_list",
                                  package   => $package,
                                  } );
    return @{$response->{packages}};
}

sub symbol_list {
    my( $self, $package, $types ) = @_;
    my $response = $self->talk( { command   => "symbol_list",
                                  package   => $package,
                                  types     => $types,
                                  } );
    return @{$response->{symbols}};
}

sub subroutine_info {
    my( $self, $subroutine ) = @_;
    my $response = $self->talk( { command    => "subroutine_info",
                                  subroutine => $subroutine,
                                  } );
    return @{$response}{qw(filename start end)};
}

1;
