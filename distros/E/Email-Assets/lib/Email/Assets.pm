package Email::Assets;
use Moose;

=head1 NAME

Email::Assets - Manage assets for Email

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

use MIME::Types;
use Email::Assets::File;

has base => (
	     is => 'ro',
);

has mime_types => (
		    is => 'ro',
		    lazy => 1,
		    default => sub { return MIME::Types->new(); },
);

has _assets => (
		traits  => ['Hash'],
		is      => 'ro',
		isa     => 'HashRef[Email::Assets::File]',
		default => sub { {} },
		handles => {
			    _asset_exists => 'exists',
			    names => 'keys',
			    _set_asset => 'set',
			    _get_asset => 'get',
			    _all_assets => 'values',
			   }
);

sub include {
    my ($self, $filename, $options) = @_;
    $options ||= { inline_only => 0 };

    if ($self->_asset_exists($filename)) {
      return $self->_get_asset($filename);
    }

    my $asset = Email::Assets::File->new({
					  mime_types => $self->mime_types,
					  base_paths => $self->base,
					  relative_filename => $filename,
					  inline_only => $options->{inline_only}
					 });
    $self->_set_asset($filename => $asset);
    return $asset;
}

sub include_base64 {
    my ($self, $base64_string, $filename, $options) = @_;
    $options ||= { inline_only => 0 };
    my $asset = Email::Assets::File->new({
					  mime_types => $self->mime_types,
					  base_paths => $self->base,
					  relative_filename => $filename,
					  base64_data => $base64_string,
					  inline_only => $options->{inline_only},
					  url_encoding => $options->{url_encoding},
					 });
    $self->_set_asset($filename => $asset);
    return $asset;
}


sub exports {
  return shift->_all_assets;
}

sub get {
    my ($self, $filename) = @_;
    return $self->_get_asset($filename);
}

sub attachments {
    return [ grep { $_->not_inline_only } shift()->_all_assets ];
}

sub to_mime_parts {
    my $self = shift;
    return [ map { $_->as_mime_part } @{$self->attachments}  ];
}

=head1 DESCRIPION

HTML Email is a world of pain, this makes life a bit simpler. This is a Simple to use perl class for handling file assets in email,
allowing you to link using cid or embed inline as data uri,  providing hopefully something close to what File::Assets does for web.

Also supports exporting as MIME::Lite message parts.

=head1 SYNOPSIS

   use Email::Assets;

   my $assets = Email::Assets->new( base => [ $uri_root, $dir_root ] );

   # Email::Assets will automatically detect the type based on the extension
   my $asset = $assets->include("/static/foo.gif");

   # or

   my $asset = $assets->include_base64( $image_base64 );

   # This asset won't get attached twice, as Email::Assets will ignore repeats of a path
   my $cid = $assets->include("/static/foo.gif")->cid;

   # Or you can iterate (in order)
   for my $asset ($assets->exports) {
     print $asset->cid, "\n";
     my $mime_part = $asset->as_mime_part;
  }

..or in a template :

  <img src="cid://[% assets.include('static/foo.gif').cid %]">
  [% # or %]
  <img src="data:[% assets.include('static/foo.gif', {inline_only => 1}).inline_data -%]">
  <p>
  <img src="cid:[% assets.include_base64(image_base64, filename, { url_encoded => 1 }).cid %]">
</p>
<p>


=head1 ATTRIBUTES

=head2 mime_types

MIME::Types object

=head2 base

arrayref of paths to find files in

=head1 METHODS

=head2 include

Add an asset, takes filename (required), then optional hashref of options (inline_only currently only one supported), returns Email::Assets::File object

=head2 include_base64

Object method. Adds an asset already encoded in base64, returns that asset.

Takes string holding base64 encoded file, filename, then optional hashref of options:

=over 4

=item inline_only - exclude asset from to_mime_parts, to avoid adding un-necessary size & attachments

=item url_encoded - base64 encoding is "url safe" so use base64url decoder, and re-encode for MIME::Lite, etc as not suited for most email use.

=back

Returns Email::Assets::File object.

=head2 exports

Get all assets, returns list of Email::Assets::File objects

=head2 get

Get an asset by name, takes relative path, returns Email::Assets::File object

=head2 attachments

Get assets that aren't inline_only, returns arrayref of Email::Assets::File objects

=head2 to_mime_parts

Returns assets that aren't inline_only as arrayref of MIME::Lite objects

=head1 SEE ALSO

=over 4

=item L<Email::Assets::File>

=item L<MIME::Lite>

=item L<File::Assets>

=back

=head1 AUTHOR

Aaron J Trevena, C<< <teejay at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-email-assets at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Assets>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::Assets


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Assets>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-Assets>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-Assets>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-Assets/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Aaron J Trevena.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Email::Assets
