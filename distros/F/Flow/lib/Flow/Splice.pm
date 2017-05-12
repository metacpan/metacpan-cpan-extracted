#===============================================================================
#
#  DESCRIPTION:  Splice flow
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================

=head1 NAME

Flow::Splice - Stream breakdown on a parts

=head1 SYNOPSIS

    my $f1 = Flow::create_flow(
        Splice => 200 );
    $f1->run( 1, 3, 11 );

=cut

package Flow::Splice;
use warnings;
use strict;
use Data::Dumper;
use Flow;
use base 'Flow';
our $VERSION = '0.1';


sub new {
    my $class = shift;
    my $count = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{stack}   = [];
    $self->{_Splice} = $count;
    return $self;

}

sub purge_stack {
    my $self  = shift;
    my $stack = $self->{stack};
    my $res;
    if ( scalar(@$stack) ) {
        $res    = $self->put_flow(@$stack);
        @$stack = ();
    }
    $res    #return put_flow res
}

sub ctl_flow {
    my $self  = shift;
    my $state = $self->purge_stack();
    return $state || $self->SUPER::ctl_flow(@_);
}

sub flow {
    my $self  = shift;
    my $stack = $self->{stack};
    my $count = $self->{_Splice};
    foreach my $r (@_) {
        if ( @$stack >= $count ) {
            if ( my $status = $self->purge_stack() ) { return $status }
        }
        push @$stack, $r;
    }
    return undef;
}

sub end {
    my $self  = shift;
    my $stack = $self->{stack};
    if ( my $status = $self->purge_stack() ) { return $status }
    return \@_;
}

1;

__END__

=head1 SEE ALSO

Flow

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

