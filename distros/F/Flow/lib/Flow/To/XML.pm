#===============================================================================
#
#  DESCRIPTION:  Export flows to XML
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
=head1 NAME

Flow::To::XML - serialize flow to XML

=head1 SYNOPSIS

    my ( $s, $s1 );
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
    
=head1 DESCRIPTION

Flow::To::XML - serialize flow to XML

=cut

package Flow::To::XML;
use strict;
use warnings;
use Flow;
use base 'Flow';
use XML::Flow qw( ref2xml xml2ref);
our $VERSION = '0.1';


=head2 new  dst
    
    new Flow::To::XML:: \$str

=cut

sub new {
    my $class = shift;
    my $dst   = shift;
    my $xflow = ( new XML::Flow:: $dst );
    return $class->SUPER::new( @_, _xml_flow => $xflow, );
}

sub begin {
    my $self = shift;
    $self->{_xml_flow}->startTag( "FLOW", makedby => __PACKAGE__ );
    return $self->SUPER::begin(@_);
}

sub flow {
    my $self = shift;
    my $xfl  = $self->{_xml_flow};
    $xfl->startTag("flow");
    $xfl->write( \@_ );
    $xfl->endTag("flow");
    return $self->SUPER::flow(@_)

}

sub ctl_flow {
    my $self = shift;
    my $xfl  = $self->{_xml_flow};
    $xfl->startTag("ctl_flow");
    $xfl->write( \@_ );
    $xfl->endTag("ctl_flow");
    return $self->SUPER::ctl_flow(@_)

}

sub end {
    my $self = shift;
    my $res  = $self->SUPER::end(@_);
    $self->{_xml_flow}->endTag("FLOW");
    return $res

}
1;
__END__

=head1 SEE ALSO

Flow::To::JXML

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

