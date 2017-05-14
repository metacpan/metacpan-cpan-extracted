# $Id: Session.pm 18 2008-05-05 23:55:18Z jabra $
package MetasploitExpress::Parser::Session;
{
    use Object::InsideOut;
    use XML::LibXML;
    use MetasploitExpress::Parser::ScanDetails;

    my @time : Field : Arg('time') : All('time');
    my @user : Field : Arg(user) : All(user);
    my @project : Field : Arg(project) : All(project);
    my @scandetails : Field : Arg(scandetails) : Get(scandetails) :
        Type(MetasploitExpress::Parser::ScanDetails);

    sub parse {
        my ( $self, $parser, $doc ) = @_;

        foreach my $msf ( $doc->getElementsByTagName('generated') ) {
            return MetasploitExpress::Parser::Session->new(
                'time'      => $msf->getAttribute('time'),
                user        => $msf->getAttribute('user'),
                project     => $msf->getAttribute('project'),
                scandetails => MetasploitExpress::Parser::ScanDetails->parse(
                    $parser, $doc
                ),
            );
        }
    }
}
1;
