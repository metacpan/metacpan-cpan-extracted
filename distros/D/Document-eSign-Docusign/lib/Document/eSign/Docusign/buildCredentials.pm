package Document::eSign::Docusign::buildCredentials;
use strict;
use warnings;
use XML::LibXML;
use JSON;

# Builds the auth credentials.

=head1 NAME

Document::eSign::Docusign::buildCredentials - Builds the credentials object.

=head1 VERSION

Version 0.02

=head1 functions

=head2 new($parent)

Builds an XML or JSON login string for the Docusign header. Setting "usejsononly" to a non-undef (null) in the constructor determines this behavior.

=cut

sub new {
    my $class = shift;
    my $main = shift;
    my $self = bless {}, $class;
    
    if (defined $main->authxml) {
        return $main->authxml;
    }
    
    if ( $main->usejsononly ) {
        my $json = JSON->new();
        
        $main->authxml($json->encode(
            {
                Username => $main->username,
                Password => $main->password,
                IntegratorKey => $main->IntegratorKey,
                usejsononly => 1
            }
        ));
        return $main->authxml;
    }
    
    
    my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $base = $doc->createElement('DocuSignCredentials');
    my $username = $doc->createElement('Username');
    $username->appendText($main->username);
    my $password = $doc->createElement('Password');
    $password->appendText($main->password);
    my $intkey = $doc->createElement('IntegratorKey');
    $intkey->appendText($main->integratorkey);
    
    $base->appendChild($username);
    $base->appendChild($password);
    $base->appendChild($intkey);
    
    $main->authxml($base->toString());
    
    return $main->authxml;
}


1;
