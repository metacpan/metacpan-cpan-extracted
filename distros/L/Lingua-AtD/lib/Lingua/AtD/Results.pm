#
# This file is part of Lingua-AtD
#
# This software is copyright (c) 2011 by David L. Day.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Lingua::AtD::Results;
$Lingua::AtD::Results::VERSION = '1.160790';
use strict;
use warnings;
use Carp;
use XML::LibXML;
use Lingua::AtD::Error;
use Lingua::AtD::Exceptions;
use Class::Std;

# ABSTRACT: Encapsulate conversion of XML from /checkDocument or /checkGrammar call to Error objects.

{

    # Attributes
    my %xml_of : ATTR( :init_arg<xml> :get<xml> );
    my %server_exception_of : ATTR( :get<server_exception> );
    my %error_count_of : ATTR( :get<error_count> :default<0> );
    my %errors_of : ATTR();

    sub START {
        my ( $self, $ident, $arg_ref ) = @_;
        my @atd_errors = ();

        my $parser = XML::LibXML->new();
        my $dom = $parser->load_xml( string => $xml_of{$ident} );

        # Check for server message.
        if ( $dom->exists('/results/message') ) {
            $server_exception_of{$ident} = $dom->findvalue('/results/message');

            # TODO: Implement Exceptions
            croak $server_exception_of{$ident};

            #            Lingua::AtD::ServiceException->throw(
            #                service_message => $server_exception_of{$ident} );
        }

        foreach my $error_node ( $dom->findnodes('/results/error') ) {
            my @options = ();
            foreach
              my $option_node ( $error_node->findnodes('./suggestions/option') )
            {
                push( @options, $option_node->string_value );
            }
            my $url =
              ( $error_node->exists('url') )
              ? $error_node->findvalue('url')
              : undef;
            my $atd_error = Lingua::AtD::Error->new(
                {
                    string      => $error_node->findvalue('string'),
                    description => $error_node->findvalue('description'),
                    precontext  => $error_node->findvalue('precontext'),
                    suggestions => [@options],
                    type        => $error_node->findvalue('type'),
                    url         => $url,
                }
            );
            push( @atd_errors, $atd_error );
            $error_count_of{$ident} += 1;
        }
        $errors_of{$ident} = [@atd_errors];

        return;
    }

    sub has_server_exception {
        my $self = shift;
        return defined( $server_exception_of{ ident($self) } ) ? 1 : 0;
    }

    sub has_errors {
        my $self = shift;

        #        return defined( $errors_of{ ident($self) } ) ? 1 : 0;
        return ( $error_count_of{ ident($self) } > 0 ) ? 1 : 0;
    }

    sub get_errors {
        my $self = shift;
        return $self->has_errors()
          ? @{ $errors_of{ ident($self) } }
          : undef;
    }

}

1;    # Magic true value required at end of module

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::AtD::Results - Encapsulate conversion of XML from /checkDocument or /checkGrammar call to Error objects.

=head1 VERSION

version 1.160790

=head1 SYNOPSIS

    use Lingua::AtD;

    # Create a new service proxy
    my $atd = Lingua::AtD->new( {
        host => 'service.afterthedeadline.com',
        port => 80
        throttle => 2,
    });

    # Run spelling and grammar checks. Returns a Lingua::AtD::Response object.
    my $doc_check = $atd->check_document('Text to check.');
    # Loop through reported document errors.
    foreach my $atd_error ($doc_check->get_errors()) {
        # Do something with...
        print "Error string: ", $atd_error->get_string(), "\n";
    }

    # Run only grammar checks. Essentially the same as
    # check_document(), sans spell-check.
    my $grmr_check = $atd->check_grammar('Text to check.');
    # Loop through reported document errors.
    foreach my $atd_error ($grmr_check->get_errors()) {
        # Do something with...
        print "Error string: ", $atd_error->get_string(), "\n";
    }

    # Get statistics on a document. Returns a Lingua::AtD::Scores object.
    my $atd_scores = $atd->stats('Text to check.');
    # Loop through reported document errors.
    foreach my $atd_metric ($atd_scores->get_metrics()) {
        # Do something with...
        print $atd_metric->get_type(), "/", $atd_metric->get_key(),
            " = ", $atd_metric->get_value(), "\n";
    }

=head1 DESCRIPTION

Encapsulates conversion of the XML response from the AtD server into a list of spelling/grammar/style error objects (L<Lingua::AtD::Error>).

=head1 METHODS

=head2 new

    # Possible, but not likely
    my $atd_results = Lingua::AtD::Results->new($xml_response);
    foreach my $atd_error ($atd_results->get_errors()) {
        # Do something really fun...
    }

Lingua::AtD::Results objects should only ever be created from method calls to L<Lingua::AtD>. However, if you have saved XML responses from prior calls to AtD, you can use this object to convert those responses into PERL objects. I won't stop you.

See the L<SYNOPSIS> for typical usage.

=head2 has_server_exception

Convenience method to see if the AtD server returned an error message.

=head2 get_server_exception

Exception message from the server.

=head2 has_errors

Convenience method to see if the XML response from AtD actually contained any spelling/grammar/style errors. These are not exceptions (see L<get_server_exception>). These are expected, and in fact are what you've asked for.

=head2 get_error_count

Returns the number of spelling/grammar/style errors detected.

=head2 get_errors

Returns a list of spelling/grammar/style errors as L<Lingua::AtD::Error> objects.

=head2 get_xml

Returns a string containing the raw XML response from the AtD service call.

=head1 SEE ALSO

See the L<API Documentation|http://www.afterthedeadline.com/api.slp> at After the Deadline's website.

=head1 AUTHOR

David L. Day <dday376@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David L. Day.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
