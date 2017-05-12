package Google::Search::Result;

=head1 NAME

Google::Search::Result 

=head1 DESCRIPTION

An object represting a result from a Google search (via L<Google::Search>)

=head1 METHODS

There are a variety of property accessors associated with each result depending which
service you use (web, blog, news, local, etc.)

For more information, see L<http://code.google.com/apis/ajaxsearch/documentation/reference.html#_intro_GResult>

For example, a local result has C<lat> accessor and C<lng> accessor:

    print $result->uri, " ", $result->title, " at ", $result->lat, " ", $result->lng, "\n";

=head2 $result->uri

A L<URI> object best representing the location of the result

=head2 $result->title

"Supplies the title value of the result"

=head2 $result->titleNoFormatting

"Supplies the title, but unlike .title, this property is stripped of html markup (e.g., <b>, <i>, etc.)"

=head2 $result->rank

The position of the result in the search (0-based)

=head2 $result->previous

The previous result before $result or undef if beyond the first

=head2 $result->next

The next result after $result or undef if after the last

=head2 $result->GsearchResultClass

"Indicates the "type" of result"

The result class as given by Google

=cut

our $field = sub {
    my $package = caller;
    my %field = @_;

    my $name = $field{name};

    $package->meta->add_attribute( $name => qw/ is ro lazy_build 1 / );
    $package->meta->add_method( "_build_$name" => sub {
        my $self = shift;
        my $value = $self->get( $name );
        $value = URI->new( $value ) if $value && $field{uri};
        return $value;
    } );
};

use Any::Moose;
use Google::Search::Carp;

use URI;

has page => qw/ is ro required 1 isa Google::Search::Page /, handles => [qw/ http_response /];
has search => qw/ is ro required 1 isa Google::Search /;
has number => qw/ is ro isa Int required 1 /;
sub rank { return shift->number( @_ ) }
has _content => qw/ is ro required 1 /;
$field->( name => $_ ) for qw/ GsearchResultClass /;

sub previous {
    my $self = shift;
    my $number = $self->number;
    return undef unless $number > 0;
    return $self->search->result( $number - 1 );
}

sub next {
    my $self = shift;
    return $self->search->result( $self->number + 1 );
}

sub get {
    my $self = shift;
    my $field = shift;

    return unless $field;
    return $self->_content->{$field};
}

sub parse {
    my $class = shift;
    my $content = shift;
    my $GsearchResultClass = $content->{GsearchResultClass};
    my $result_class;
    ($result_class) = $GsearchResultClass =~ m/^G(\w+)Search/;
    croak "Don't know how to parse $GsearchResultClass" unless $result_class;
    $result_class = ucfirst $result_class;
    $result_class = "Google::Search::Result::$result_class";
    return $result_class->new(_content => $content, @_);
}

package Google::Search::Result::Web;

use Any::Moose;
use Google::Search::Carp;
extends qw/ Google::Search::Result /;

$field->( name => $_ ) for qw/
title
titleNoFormatting
visibleUrl
content
/;

$field->( name => $_, uri => 1 ) for qw/
unescapedUrl
cacheUrl
/;

sub uri { return shift->unescapedUrl(@_) }

package Google::Search::Result::Local;

use Any::Moose;
use Google::Search::Carp;
extends qw/ Google::Search::Result /;

$field->( name => $_ ) for qw/
title
titleNoFormatting
lat
lng
streetAddress
city
region
country
phoneNumbers
addressLines
/;

$field->( name => $_, uri => 1 ) for qw/
url
ddUrl
ddUrlToHere
ddUrlFromHere
staticMapUrl
/;

sub uri { return shift->url(@_) }

package Google::Search::Result::Video;

use Any::Moose;
use Google::Search::Carp;
extends qw/ Google::Search::Result /;

$field->( name => $_ ) for qw/
title
titleNoFormatting
content
published
publisher
duration
tbWidth
tbHeight
/;

$field->( name => $_, uri => 1 ) for qw/
url
tbUrl
playUrl
/;

sub uri { return shift->url(@_) }

package Google::Search::Result::Blog;

use Any::Moose;
use Google::Search::Carp;
extends qw/ Google::Search::Result /;

$field->( name => $_ ) for qw/
title
titleNoFormatting
content
publishedDate
author
/;

$field->( name => $_, uri => 1 ) for qw/
blogUrl
postUrl
/;

sub uri { return shift->postUrl(@_) }

package Google::Search::Result::News;

use Any::Moose;
use Google::Search::Carp;
extends qw/ Google::Search::Result /;

$field->( name => $_ ) for qw/
title
titleNoFormatting
content
url
publisher
location
publishedDate
/;

$field->( name => $_, uri => 1 ) for qw/
unescapedUrl
clusterUrl
/;

sub uri { return shift->unescapedUrl(@_) }

package Google::Search::Result::Book;

use Any::Moose;
use Google::Search::Carp;
extends qw/ Google::Search::Result /;

$field->( name => $_ ) for
qw/
title
titleNoFormatting
content
url
authors
publishedYear
bookId
pageCount
tbWidth
tbHeight
/;

$field->( name => $_, uri => 1 ) for
qw/
unescapedUrl
tbUrl
/;

sub uri { return shift->unescapedUrl(@_) }

package Google::Search::Result::Image;

use Any::Moose;
use Google::Search::Carp;
extends qw/ Google::Search::Result /;

$field->( name => $_ ) for qw/
title
titleNoFormatting
content
contentNoFormatting
url
visibleUrl
width
height
tbWidth
tbHeight
/;

$field->( name => $_, uri => 1 ) for qw/
unescapedUrl
originalContextUrl
tbUrl
/;

sub uri { return shift->unescapedUrl(@_) }

package Google::Search::Result::Patent;

use Any::Moose;
use Google::Search::Carp;
extends qw/ Google::Search::Result /;

$field->( name => $_ ) for qw/
title
titleNoFormatting
content
url
applicationDate
patentNumber
patentStatus
assignee
/;

$field->( name => $_, uri => 1 ) for qw/
unescapedUrl
originalContextUrl
tbUrl
/;

sub uri { return shift->unescapedUrl(@_) }

1;
