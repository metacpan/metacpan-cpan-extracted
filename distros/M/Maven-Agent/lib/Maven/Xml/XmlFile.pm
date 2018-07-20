use strict;
use warnings;

package Maven::Xml::XmlFile;
$Maven::Xml::XmlFile::VERSION = '1.15';
# ABSTRACT: A base class for Maven XML file
# PODNAME: Maven::Xml::XmlFile

use parent qw(Maven::Xml::XmlNodeParser);

use Carp;
use Log::Any;
use XML::LibXML::Reader;

my $logger = Log::Any->get_logger();

sub _init {
    my ( $self, %options ) = @_;

    my $xml_string = $options{string};
    if ( !$xml_string && $options{file} ) {
        $logger->debugf( 'loading xml from file %s', $options{file} );

        # http://www.perl.com/pub/2003/11/21/slurp.html
        $xml_string = do { local ( @ARGV, $/ ) = $options{file}; <> };
    }
    if ( !$xml_string && $options{url} ) {
        $logger->debugf( 'loading xml from uri %s', $options{url} );
        my $agent = $options{agent};
        if ( !$agent ) {
            require LWP::UserAgent;
            $agent = LWP::UserAgent->new();
        }

        my $response = $agent->get( $options{url} );
        if ( !$response->is_success() ) {
            if ( $options{die_on_failure} ) {
                die($response);
            }
            else {
                return;
            }
        }

        $xml_string = $response->content();
    }

    $self->_parse_node( XML::LibXML::Reader->new( string => $xml_string ) );

    return $self;
}

1;

__END__

=pod

=head1 NAME

Maven::Xml::XmlFile - A base class for Maven XML file

=head1 VERSION

version 1.15

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Maven::Agent|Maven::Agent>

=back

=cut
