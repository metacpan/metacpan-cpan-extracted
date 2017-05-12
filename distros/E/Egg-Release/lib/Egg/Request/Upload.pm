package Egg::Request::Upload;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Upload.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use Carp qw/croak/;
use base qw/ Class::Accessor::Fast /;

our $VERSION= '3.00';

__PACKAGE__->mk_accessors(qw/ name handle /);

sub new {
	my($class, $req)= splice @_, 0, 2;
	my $name  = shift || croak q{ I want upload param name. };
	my $handle= $req->r->upload($name) || return (undef);
	bless { name=> $name, r=> $req->r, handle=> $handle }, $class;
}
*fh = \&handle;

sub catfilename {
	my($up)= @_;
	my $filename= $up->filename || return (undef);
	$filename=~m{([^\\\/]+)$} ? $1: undef;
}
sub copy_to {
	my $up= shift;
	File::Copy->require;
	File::Copy::copy($up->tempname, @_);
}
sub link_to {
	my $up= shift;
	link($up->tempname, @_);
}
sub _setup { @_ }

1;

__END__

=head1 NAME

Egg::Request::Upload - Base class for file upload. 

=head1 SYNOPSIS

  use Egg qw/ Request::Upload /;
  
  # Acquisition of up-loading object.
  my $upload= $e->request->upload('upload_param_name');

=head1 DESCRIPTION

This is a base class for the file upload.

The plugin to use this module is prepared. 

Please load L<Egg::Plugin::Request::Upload> to use it.

Whether the plugin is used in the mod_perl environment is distinguished and the
best following subclasses are read.

L<Egg::Request::Upload::ModPerl>, L<Egg::Request::Upload::CGI>,

Please set environment variable 'POST_MAX' to the high limit setting of the size
of the upload file.

Please set environment variable 'TEMP_DIR' temporarily to set passing the work
file.

Please refer to the document of mod_perl and CGI.pm for details for the environment
variable.

=head1 METHODS

=head2 new ([REQUEST_CONTEXT], [PARAM_NAME])

Constructor.

The L<Egg::Request> object is received with REQUEST_CONTEXT.

When $e-E<gt>request-E<gt>upload is called, this method is internally called.

When any REQUEST_CONTEXT-E<gt>r-E<gt>upload(PARAM_NAME) doesn't return it,
undefined is returned.

  my $upload= $e->request->upload( ...... ) || die 'There is no upload file.';

=head2 handle

The file steering wheel to the preservation place of the up-loading file is 
temporarily returned.

  my $value= join '', $upload->handle->getlines;

=over 4

=item * Alias = fh

=back

=head2 catfilename

Only the file name that doesn't contain the directory path of the upload file
is returned.

  my $filename= $upload->catfilename;

=head2 copy_to ([COPY_PATH])

The upload file of the work place is temporarily copied to COPY_PATH.

  $upload->copy_to("/path/to/upload/$filename");

=head2 link_to ([LINK_PATH])

The hard link of the upload file of the work place is temporarily made in
LINK_PATH.

  $upload->link_to("/path/to/upload/$filename");

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Request>,
L<Egg::Request::Upload>,
L<Egg::Request::Upload::CGI>,
L<Egg::Request::Upload::ModPerl>,
L<Egg::Plugin::Request::Upload>,
L<Class::Accessor::Fast>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

