# -*- coding: utf-8 -*- 
package Devel::Stub::lib;

use warnings;
use strict;
use Carp;

sub import {
    my $class = shift;
    my %params = @_;
    my $active_if = $params{active_if} || $ENV{STUB};
    my $stubpath = $params{path} || "stub";
    my $quiet = $params{quiet};

    if ($active_if){
        unshift @INC,$stubpath if $INC[0] ne $stubpath;
        print STDERR __PACKAGE__," - path '$stubpath' have been added to \@INC\n" unless $quiet;
    }
}


1;
__END__

=head1 NAME

Devel::Stub::lib - change lib path for stubbing

=head1 SEE ALSO

L<Devel::Stub>

=head1 AUTHOR

Masaki Sawamura
