#===============================================================================
#
#  DESCRIPTION:
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
=head1 NAME

Flow::Code - process flow by user defined code

=head1 SYNOPSIS

    my $f1 = Flow::create_flow(
        Splice => 200,
        Join   => {
            Data => Flow::create_flow(
                sub {
                    return [ grep { $_ > 10 } @_ ];
                },
                Splice => 10

            ),
            Min => Flow::create_flow(
                sub {
                    return [ grep { $_ == 1 } @_ ];
                },
                Splice => 40,
            )
        },
        ToXML  => \$s,
    );
    $f1->run( 1, 3, 11 );

=cut

package Flow::Code;
use strict;
use warnings;
use base 'Flow';
our $VERSION = '0.1';

=head2  new 

    new Flow::Code:: { flow=>sub{ shift; [] }[, begin=>sub{ shift ..}, end .., cnt_flow=>... };
    new Flow::Code:: sub{ \@_ } #default handle flow
=cut

foreach my $method ( "begin", "flow", "ctl_flow", "end" ) {
    my $s_method = "SUPER::" . $method;
    no strict 'refs';
    *{ __PACKAGE__ . "::$method" } = sub {
        my $self = shift;
        if ( my $code = $self->{ "_" . $method } ) {
            return &$code(@_);
        }
        elsif ( my $code_s = $self->{$method} ) {
            return &$code_s( $self, @_ );
        }
        else {
            return $self->$s_method(@_);
        }
    };
}

sub new {
    my $class = shift;
    if ( $#_ == 0 and ref( $_[0] ) eq 'CODE' ) {
        unshift @_, '_flow';
    }
    my $self = $class->SUPER::new(@_);

    #clean up hnot valided handlers
    foreach my $method (qw/ begin flow  ctl_flow end /) {
        my $code = $self->{$method} || next;
        delete $self->{$method} unless ref($code) eq 'CODE';
    }
    return $self;
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

