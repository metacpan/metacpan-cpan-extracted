# $Id: Adnix.pm,v 1.1.1.1 2004/06/19 09:37:19 cosimo Exp $

=head1 NAME

HTTP::Proxy::BodyFilter::Adnix - Automatically block advertising images with custom regexes

=head1 SYNOPSIS

    use HTTP::Proxy::BodyFilter::Adnix

    # Use default blacklist rules and default placeholder image
    $proxy->push_filter(
        mime     => 'image/*',
        response => HTTP::Proxy::BodyFilter::Adnix->new();
    );

    # OR ...

    # You must supply your custom rules for filtering
    my $filter = HTTP::Proxy::BodyFilter::Adnix->new(
        deny  => [ 'spammingserver.com', 'WeSpamYou.org', ... ],
        image => 'http://www.mydomain.com/mylogo.png'
    );
    $proxy->push_filter(
        mime     => 'image/*',
        response => $filter
    );

=head1 ABSTRACT

  This class acts as a plugin filter module for HTTP::Proxy distribution.
  Its purpose is to block advertising (but you can define it) images
  to avoid wasting bandwidth for these images.

=head1 DESCRIPTION

C<HTTP::Proxy::BodyFilter::Adnix> filter module is based on
C<HTTP::Proxy::BodyFilter> class that is part of C<HTTP::Proxy> distribution.

This filter tries to detect advertising images into your HTTP requests,
and it replaces them with an image of your choice.
Detection is done through a set of regular expression you can customize.

If you're wondering where the name C<Adnix> comes from, you should
really read the wonderful book B<Contact> by Carl Sagan.

For more detailed information on C<HTTP::Proxy::BodyFilter>, see
its documentation on CPAN.

=head2 EXPORT

None by default.

=head1 METHODS

=cut

package HTTP::Proxy::BodyFilter::Adnix;

use strict;
use Carp;
use base qw(HTTP::Proxy::BodyFilter);
use vars qw($VERSION $IMAGE);

$VERSION = '0.01';
our @UGLY_IMAGE = qw(
    5089 474e 0a0d 0a1a 0000 0d00 4849 5244 0000 1000 0000 1000 0608 0000 1f00 fff3
    0061 0000 6206 474b 0044 00ff 00ff a0ff a7bd 0093 0000 7009 5948 0073 0b00 0012
    0b00 0112 ddd2 fc7e 0000 0700 4974 454d d307 140c 240b ee31 e796 0095 0000 4935
    4144 7854 639c 4060 0680 6628 4520 898c 4281 88c0 9a64 9403 803e 4f24 8c50 1762
    8320 8606 0881 d183 1c40 440d d074 30c0 8110 0008 da6b 9616 bfd8 6986 0000 0000
    4549 444e 42ae 8260
);

=head2 init()

Internal. Gets called on filter initialization.
Accepts the options that customize filter behaviour.

=over 4

=item image

    String. Filesystem path to PNG image to be used as a placeholder for all detected
    advertising images.

=item deny

    Array reference. Must contain all regular expressions that block images.
    This means that if the current image matches any of these regular expressions,
    it will be blocked.

=back

=cut

sub init
{
    my $self = shift;
    my %opt;

    if( @_ % 1 == 0 ) {
        %opt = @_;
    }
    else {
        croak "You must supply key => value options";
    }

    # Set path of placeholder image
    if( exists $opt{image} ) {
        $self->{_image} = $opt{image};
    }

    $self->{_image} ||= '/usr/local/share/replaced.png';

    # Set regex blacklist
    if( exists $opt{deny} && ref $opt{deny} eq 'ARRAY' ) {
        $self->{_denylist} = $opt{deny};
    }
    $self->{_denylist} ||= [ map { qr($_) }
        'ad[vs\.]',
    	'adv?server',
    	'468x60',
    	'doubleclick\.net',
    	'promot[ie]',
    ];

    # Set regex whitelist (empty at start)
    if( exists $opt{allow} && ref $opt{allow} eq 'ARRAY' ) {
        $self->{_allowlist} = $opt{allow};
    }
    $self->{_allowlist} ||= [];

    # Do I need this? TODO must ask Philippe
    $self->{rw} = delete $opt{rw};

}


=head2 filter()

This is where the hard work gets done.
Every image is matched against a set of regexes and if it matches B<any> of
these, it is B<not> downloaded and B<its content is replaced> by the
placeholder image.

The intention here is to save bandwidth and to remove those annoying
banners.

=cut

sub filter
{
	my($self, $headers, $message) = @_;
	my $uri = $message->uri();

	# "DECLINE" non-image urls
	#return 0 unless $uri =~ /\.(gif|jpe?g|png)/i;

    # Load placeholder image if not yet done
    if( ! $IMAGE ) {
        $self->_loadImage();
    }
    
	foreach( @{ $self->{_denylist} } ) {
		my $re = $_;
		if( $uri =~ $re ) {
			$self->proxy()->log( '', '', 'blocked ad image('.$uri.')' );
            my $response = HTTP::Response->new(
                200,
                'OK',
                HTTP::Headers->new(
                    Content_Type => ( $self->{_image} =~ /\.(gif|png|jpg)/i ? qq{image/$1} : 'image/png' ),
                    Content_Length => -s $IMAGE,
                ),
                $IMAGE
            );

            $self->proxy()->response($response);
			last;
		}
	}

	return 1;
}



=head2 _loadImage()

Internal function. Tries to load the image to be used as a placeholder
for all advertising images. If no remote/local image can be loaded,
an hardcoded binary PNG image is used.

=cut

sub _loadImage
{
    my $self   = $_[0];
    my $loaded = 0;

    #$self->{_image} = lc $self->{_image};

    # If image is specified as URL, try to load it
    if( ($self->{_image} =~ m|^[Hh][Tt][Tt][Pp]://|) || ($self->{_image} =~ m|^[Ff][Tt][Pp]://|) ) {
        eval {
            use LWP::Simple ();
            $IMAGE = LWP::Simple::get($self->{_image});
            $loaded = 1 if defined $IMAGE && length($IMAGE) > 0;
        };
        if( ! $loaded ) {
            croak "Can't load image $$self{_image}";
        }
    }

    else {

        # Try to load image from disk
        if( open IMG, $self->{_image} ) {
            binmode(IMG);
            local $/ = undef;
            $IMAGE   = <IMG>;
            $loaded  = (length($IMAGE) > 0) && close(IMG);
        }

    }
 
    if( $loaded ) {
        #printf STDERR 'loaded replace image from %s (%d bytes)'."\n", $self->{_image}, length($IMAGE);
        # Here proxy object is not yet prepared
        $self->proxy()->log('', '', sprintf('loaded replace image from %s (%d bytes)', $self->{_image}, length($IMAGE)));
    }
    else {
        # If all else failed, load static binary PNG data
        $IMAGE = "";

        for( @UGLY_IMAGE ) {
            my($b1,$b2) = unpack('A2 A2',$_);
            $b1 = chr hex $b1;
            $b2 = chr hex $b2;
            $IMAGE .= $b2 . $b1;
        } 
    }

    return $loaded;
}

1;

# 
# END OF MODULE
#


=head1 SEE ALSO

For more information, you should read C<HTTP::Proxy> distribution documentation.
If you find this class useful or want to report complaints or bugs, please
do it through the good CPAN bug report system on http://rt.cpan.org.

This class has been derived from original work by Philippe "Book" Bruhat,
author of L<HTTP::Proxy> distribution. Go check out his good work!

=head1 AUTHOR

Cosimo Streppone E<lt>cosimo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Cosimo Streppone

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;

