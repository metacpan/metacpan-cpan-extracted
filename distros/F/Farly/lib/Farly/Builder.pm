package Farly::Builder;

use 5.008008;
use strict;
use warnings;
use Carp;
use Log::Any qw($log);

our $VERSION = '0.26';

sub new {
    my $class = shift;

    my $self = {
        FILE      => undef,
        CONTAINER => undef,
    };
    bless( $self, $class );
    
    $log->info("$self NEW");

    return $self;
}

sub set_file {
    my ( $self, $file ) = @_;

    $self->{FILE} = $file;
    
    $log->info( "$self SET FILE TO " . $self->{FILE} );
}

sub file {
    return $_[0]->{FILE};
}

1;
__END__

=head1 NAME

Farly::Builder - Builder base class

=head1 DESCRIPTION

Farly::Builder is the Builder base class which defines the
vendor independent Builder interface.

Farly::Builder is used by vendor specific builders only.

=head1 COPYRIGHT AND LICENCE

Farly::Builder
Copyright (C) 2012  Trystan Johnson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
