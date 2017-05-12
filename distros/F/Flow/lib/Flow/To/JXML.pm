#===============================================================================
#
#  DESCRIPTION:  Serialize to mixied XML and JSON
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
=head1 NAME

Flow::To::JXML - serialize flow to JSON+XML

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
        ToJXML  => \$s,
    );
    $f1->run( 1, 3, 11 );
    
=head1 DESCRIPTION

Flow::To::JXML - serialize flow to JSON+XML

=cut

package Flow::To::JXML;
use strict;
use warnings;
use JSON;
use Flow::To::XML;
use base 'Flow::To::XML';
our $VERSION = '0.1';
sub flow {
    my $self = shift;
    my $xfl  = $self->{_xml_flow};
    $xfl->startTag("flow");
    $xfl->_get_writer->cdata(JSON->new->utf8->pretty(1)->encode(\@_));
    $xfl->endTag("flow");
    return $self->Flow::flow(@_)

}

sub ctl_flow {
    my $self = shift;
    my $xfl  = $self->{_xml_flow};
    $xfl->startTag("ctl_flow");
    $xfl->_get_writer->cdata(encode_json(\@_));
    $xfl->endTag("ctl_flow");
    return $self->Flow::ctl_flow(@_)

}

1;
__END__

=head1 SEE ALSO

Flow::To::XML

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

