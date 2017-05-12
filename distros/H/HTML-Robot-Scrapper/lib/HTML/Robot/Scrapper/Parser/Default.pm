package  HTML::Robot::Scrapper::Parser::Default;
use Moose;

with('HTML::Robot::Scrapper::Parser::HTML::TreeBuilder::XPath'); #gives parse_xpath
with('HTML::Robot::Scrapper::Parser::XML::XPath'); #gives parse_xml

has robot => ( is => 'rw', );
has engine => ( is => 'rw', );

sub content_types {
    my ( $self ) = @_;
    return {
        'text/html' => [
            {
                parse_method => 'parse_xpath',
                description => q{
                    The method above 'parse_xpath' is inside class:
                    HTML::Robot::Scrapper::Parser::HTML::TreeBuilder::XPath
                },
            }
        ],
        'text/xml' => [
            {
                parse_method => 'parse_xml'
            },
        ],
    };
}

1;
