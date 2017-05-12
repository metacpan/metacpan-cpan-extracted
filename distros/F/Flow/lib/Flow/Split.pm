#===============================================================================
#
#  DESCRIPTION:  Split flow into more( alternate Join)
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
=head1 NAME

Flow::Split -Send flow to multiple processor, with switching 

=head1 SYNOPSIS

    use Flow;
    my $fi = create_flow(
    FromXML => \$in,
    Split => { Data1 => $fi1, Data2 => $fi2 },
    Splice=>10,
    ToXML => \$out
    );
    $fi->run();
    
=head1 DESCRIPTION


Flow::Split  is a object that passes each flow it receives on to a list of downstream handlers.

=cut

package Flow::Split;
use strict;
use warnings;
use Flow::To::Null;
use base 'Flow';
our $VERSION = '0.1';


sub new {
    my $self  = shift->SUPER::new();
    my @order = ();
    # Flow::Split:: { Data=>$dsd, Test=>$sdsd}
    if ($#_ == 0 ) {
        @_ = %{ shift @_ } ;
    }
    while ( my ( $name, $value ) = splice @_, 0, 2 ) {
        push @order,
          {
            name   => $name,
            flow   => $value,
          };
    }
    $self->{flows} = \@order;
    $self;
}

sub _get_flows {
    my $self = shift;
    my @res  = ();
    foreach my $rec ( @{ $self->{flows} } ) {
        push @res, $rec->{flow};
    }
    @res;
}


sub begin {
    my $self = shift;
    my $res  = $self->SUPER::begin(@_);
    foreach my $f ( $self->_get_flows ) {
        $f->parser->begin(@_);
    }
    return $res;
}

sub end {
    my $self = shift;
    foreach my $f ( $self->_get_flows ) {
        $f->parser->end(@_);
    }
    return $self->SUPER::end(@_);
}

sub current_pipe {
    my $self = shift;
     $self->{_cp} || $self->get_handler()  || new Flow::To::Null::;
}

sub flow {
    my $self = shift;
#    warn Dumper(\@_);
    return $self->current_pipe->parser->flow(@_);
}

sub ctl_flow {
    my $self = shift;
    foreach my $rec ( @_ ) {
        #check if  switch pipe
        if ( (ref($rec) eq 'HASH') && ( my $type= $rec->{type} ) ) {
              #check if "name" exists in HASH
              my %hash = ();
              @hash{map {$_->{name}} @{ $self->{flows} } } = ();
              if ( $type eq  'named_pipes' and exists $hash{$rec->{name}}) {
                    my $stage  = $rec->{stage};
                    my $name = $rec->{name};
                    if ( $stage == 2 ||$stage == 4 ) {
                       #close switch
                       delete $self->{_cp};
                       next;
                    }
                    #now get pipe by name and set as default
                    my $flow;
                    foreach my $f ( @{ $self->{flows} } ) {
                       if ( $name eq $f->{name}) {
                         $flow = $f->{flow};
                         last;
                       }
                    }
                    if ( $flow ) {
                    $self->{_cp} = $flow;
                    next;
                    } else {
                        warn "can't get flow for name $name"
                    }
               }
        }
        return $self->current_pipe->parser->ctl_flow( $rec )
    }
    return ;
}

1;
__END__

=head1 SEE ALSO

Flow::Join

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


