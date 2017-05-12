package HTTP::Body::MultiPart::Extend;

use warnings;
use strict;

=head1 NAME

HTTP::Body::MultiPart::Extend - Extend HTTP::Body::MultiPart's handler to do something you want

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use HTTP::Body::MultiPart::Extend qw(extend no_extend patch_new);

    # Overwrite HTTP::Body::MultiPart::handler
    use HTTP::Body;
    use HTTP::Body::MultiPart::Extend qw(extend);
    
    extend( sub {
	my($self, $part) = @_;

	my $headers = $part->{headers}; # A hash ref to this part's header fields
	my $size = $part->{size}; # The current size this time
	my $done = $part->{done}; # If this part is done (the final call for this part)
	# Please don't modify these fields listed above.

	my $data = substr($part->{data}, 0, length($part->{data}), '');
	    # Each time, the comming data will be appended here.
	    # You can choose whether to take it out, or leave it here (and occupy memory steadily).
	...
	$self->SUPER::handler(@_); # You can call the original one like this when need
    } );
    $body = HTTP::Body->new( $content_type, $content_length );
    # Then use HTTP::Body in a normal way.
    # See the document of HTTP::Body

    # You can overwrite different subs alternatively.
    use HTTP::Body;
    use HTTP::Body::MultiPart::Extend qw(extend no_extend);

    extend(\&A);
    my $body_a = HTTP::Body->new(...);
    # Overwrite by sub A

    extend(\&B);
    my $body_b = HTTP::Body->new(...);
    # Then overwrite by sub B

    no_extend;
    my $body = HTTP::Body->new(...);
    # Switch back to the original one.

    # You can use $body_a, $body_b, and $body here.
    # They will work with handlers A, B, and the original one respectively


    # Beside extend and no_extend, you can use patch_new with a no-side-effect style
    use HTTP::Body::MultiPart::Extend qw(patch_new);
    my $body = patch_new( sub { ... }, ... other args for HTTP::Body->new ... );
    # It will call HTTP::Body->new(...) for you

    # Note that if the request is not multipart/form-data, it's no effect by this module

=cut

use HTTP::Body;
use base qw(Exporter HTTP::Body::MultiPart);
use Carp;

our @EXPORT_OK = qw(extend no_extend patch_new);
our $handler;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->{handler} = $handler;
    return $self;
}

sub handler {
    return $_[0]{handler}(@_)
}


=head1 DESCRIPTION

With this module, you can switch C<HTTP::Body::MultiPart::handler> to your version.
Then you can decide how to deal with the user uploads, such as tracking
uploading progress, droping malform or too large files in time, etc.

=head1 FUNCTIONS

=over 4

=item extend

The only argument of extend should be a CODE ref.
All the following C<< HTTP::Body->new >> will use the given sub
as the L<HTTP::Body::MultiPart> handler if the request
is multipart/form-data, until the next extend or no_extend.

=cut

sub extend($) {
    croak "The only argument of extend should be a CODE ref" unless 'CODE' eq ref $_[0];
    $HTTP::Body::TYPES->{'multipart/form-data'} = __PACKAGE__;
    $handler = shift;
}

=item no_extend

After this call, all the following C<< HTTP::Body->new >> will
switch back to use the original handler.

=cut

sub no_extend() {
    $HTTP::Body::TYPES->{'multipart/form-data'} = 'HTTP::Body::MultiPart';
}

=item patch_new

This function will call C<< HTTP::Body->new >>, and additionally
change the L<HTTP::Body::MultiPart> handler to yours.

This function provides a no-side-effect way to extend.

The first argument should be a CODE ref, and the following arguments
will be passed to C<< HTTP::Body->new >>.

=cut

sub patch_new($@) {
    croak "The first argument of extend should be a CODE ref" unless 'CODE' eq ref $_[0];
    local $HTTP::Body::TYPES->{'multipart/form-data'} = __PACKAGE__;
    local $handler = shift;
    return HTTP::Body->new(@_);
}

=back

=head1 EXPORT

This module will not export anything by default. You could export them by yourself,
or use the fully qualified name directory.

=head1 ORIGINAL HANDLER

If you don't known how to design your own handler.
Take a look on the original one. It might inspire you some.

The code below is HTTP::Body::MultiPart::handler, taken from package L<HTTP::Body> version 1.07.

    sub handler {
	my ( $self, $part ) = @_;

	unless ( exists $part->{name} ) {

	    my $disposition = $part->{headers}->{'Content-Disposition'};
	    my ($name)      = $disposition =~ / name="?([^\";]+)"?/;
	    my ($filename)  = $disposition =~ / filename="?([^\"]*)"?/;
	    # Need to match empty filenames above, so this part is flagged as an upload type

	    $part->{name} = $name;

	    if ( defined $filename ) {
		$part->{filename} = $filename;

		if ( $filename ne "" ) {
		    my $fh = File::Temp->new( UNLINK => 0, DIR => $self->tmpdir );

		    $part->{fh}       = $fh;
		    $part->{tempname} = $fh->filename;
		}
	    }
	}

	if ( $part->{fh} && ( my $length = length( $part->{data} ) ) ) {
	    $part->{fh}->write( substr( $part->{data}, 0, $length, '' ), $length );
	}

	if ( $part->{done} ) {

	    if ( exists $part->{filename} ) {
		if ( $part->{filename} ne "" ) {
		    $part->{fh}->close if defined $part->{fh};

		    delete @{$part}{qw[ data done fh ]};

		    $self->upload( $part->{name}, $part );
		}
	    }
	    else {
		$self->param( $part->{name}, $part->{data} );
	    }
	}
    }

=head1 SEE ALSO

L<HTTP::Body>, L<HTTP::Body::MultiPart>

=head1 AUTHOR

Cindy Wang (CindyLinz)

=head1 BUGS

Please report any bugs or feature requests to C<bug-http-body-multipart-extend at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-Body-MultiPart-Extend>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::Body::MultiPart::Extend


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-Body-MultiPart-Extend>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-Body-MultiPart-Extend>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-Body-MultiPart-Extend>

=item * Search CPAN

L<http://search.cpan.org/dist/HTTP-Body-MultiPart-Extend/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Cindy Wang (CindyLinz).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of HTTP::Body::MultiPart::Extend
