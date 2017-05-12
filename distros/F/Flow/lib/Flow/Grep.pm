#===============================================================================
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
=head1 NAME

Flow::Grep - Evaluates the EXPR for each element of flow

=head1 SYNOPSIS

    my $f1 = Flow::create_flow(
        Grep =>qr/1/ );
    $f1->run( 1, 3, 11 );

=cut

package Flow::Grep;
use warnings;
use strict;
use Data::Dumper;
use Flow;
use base 'Flow';
our $VERSION = '0.1';


sub new {
    my $class = shift;
    my $arg = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{_Grep} = $arg;
    return $self;

}

sub flow {
    my $self  = shift;
    my $arg = $self->{_Grep};
    return [ grep $arg, @_ ] 
}
1;
__END__

=head1 SEE ALSO

Flow::

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


