
use Test::More tests => 4; 
#use Test::Exception;

use strict;
use warnings;

#use Apache::FakeRequest;
use MasonX::Plugin::Compress;
use HTML::Mason::Plugin::Context;
    
my $output = do { local $/; <DATA> };

my $output2 = $output;

# fake up $m and $r
my $r = FakeRequest->new( { header_in => 'bzip2,flarb,fleeble' } );
$r->content_type( 'text/plain' );
                                        
my $m = FakeRequest->new;
$m->apache_req( $r );
$m->request_buffer( $output );
          
# fake up a context
my $request_args = { flee => 'floo' };
my $wantarray = 0;
my @result = ();
my $error;

my $context = bless [$m, $r, \$m->{request_buffer}, $wantarray, \@result, \$error],
            'HTML::Mason::Plugin::Context::EndRequest';

my $plugin = MasonX::Plugin::Compress->new;

# do the work
$plugin->end_request_hook( $context );

# start testing
ok( length( $m->request_buffer ) < length( $output ) );

like( $r->content_encoding, qr(^bzip2) );

is_deeply( $r->header_out, [ Vary => 'Accept-Encoding' ] );

like( Compress::Bzip2::memBunzip( $m->request_buffer ), qr($output2) );





# --------------------------------------------------------------------
BEGIN
{
    package FakeRequest;
    use base 'Class::Accessor';
    __PACKAGE__->mk_accessors( qw( request_buffer apache_req content_type content_encoding header_out ) );
    #__PACKAGE__->mk_ro_accessors( qw( header_in ) );
    
    sub header_in { shift->{header_in} }
}

__DATA__

Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Nunc iaculis libero vitae wisi. Pellentesque wisi. Aenean sed leo vitae odio aliquet dapibus. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Phasellus auctor, orci id dapibus tempus, nunc diam sodales mauris, in ullamcorper tellus lectus aliquet quam. Cras pede sem, cursus quis, rhoncus eu, convallis vitae, velit. Nunc ut nisl. Nullam viverra. Maecenas id orci porta diam rutrum sollicitudin. Sed et mauris. Maecenas dolor pede, tincidunt eu, elementum quis, egestas eleifend, lorem. Ut at lectus in neque molestie euismod. Aliquam condimentum magna. Cras ornare nibh vel dolor. In lacus neque, tempus eget, porta quis, dapibus et, neque. Donec nonummy magna et lacus. Vivamus sagittis wisi feugiat est.

Phasellus nec elit nec tortor aliquet sagittis. Ut enim. Donec vitae nunc. Nulla venenatis diam ultricies dolor convallis malesuada. Vestibulum felis massa, pretium vulputate, vulputate vitae, imperdiet in, quam. Quisque aliquet pede. Donec non velit. Phasellus porta scelerisque libero. Maecenas lacus quam, tincidunt sed, pellentesque at, semper sit amet, sem. Aliquam non nunc molestie enim porta ultrices. Phasellus consectetuer luctus arcu. Sed at turpis fringilla massa blandit consequat.

Quisque nulla enim, malesuada ac, sodales lobortis, porta vel, wisi. Maecenas vel urna. Curabitur orci tellus, pulvinar at, pretium quis, adipiscing a, sapien. Donec consectetuer wisi non velit. Quisque at nibh ut mauris luctus tempor. Aenean orci. Morbi est. Cras justo magna, consectetuer non, tincidunt ac, porta vel, wisi. Mauris est odio, laoreet quis, posuere sit amet, mattis id, mi. Vestibulum eget turpis.

Vestibulum non sem. Morbi pellentesque tempor lacus. Maecenas gravida fermentum ligula. Curabitur sollicitudin felis. Nullam in mi et lectus dignissim facilisis. Nam at libero. Cras nec sem non arcu volutpat congue. Donec eget massa in sapien blandit posuere. Phasellus erat dolor, sollicitudin in, auctor nec, sagittis et, eros. Vestibulum eget arcu at erat fermentum feugiat. Curabitur ut ante. Quisque ac orci. Nam vitae massa. Sed porttitor congue pede. Aliquam tincidunt condimentum pede.

Donec laoreet. Etiam bibendum. Cras viverra justo sed sem. Donec vitae nisl quis dui imperdiet auctor. Nulla tellus odio, pulvinar at, luctus eget, facilisis aliquam, augue. Mauris tincidunt leo consectetuer mauris. Duis quis sem gravida dolor fringilla dictum. Nunc a mi. Sed consequat augue nec massa. Nunc orci. Donec et ante fermentum nulla hendrerit aliquam. Cras vitae velit. Ut adipiscing turpis nec diam.
