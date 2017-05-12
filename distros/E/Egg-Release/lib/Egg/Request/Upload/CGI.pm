package Egg::Request::Upload::CGI;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: CGI.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION = '3.01';

sub upload {
	Egg::Request::Upload::CGI::handler->new(@_) || (undef);
}

package Egg::Request::Upload::CGI::handler;
use strict;
use base qw/ Egg::Request::Upload /;

sub filename { $_[0]->{r}->param( $_[0]->name ) }
sub tempname { $_[0]->{r}->tmpFileName( $_[0]->handle ) }
sub size     { -s $_[0]->handle }
sub type     { $_[0]->info->{'Content-Type'} }
sub info     { $_[0]->{r}->uploadInfo( $_[0]->handle ) }

1;

__END__

=head1 NAME

Egg::Request::Upload::CGI - File upload by CGI::Upload.

=head1 DESCRIPTION

L<CGI::Upload> It is a module to use the file upload function.

This module is set up by L<Egg::Plugin::Request::Upload>.

=head1 METHODS

=head2 upload ([PARAM_NAME])

The Egg::Request::Upload::CGI::handler object is returned.

Undefined returns when the 'upload' object cannot be acquired in PARAM_NAME.

=head1 HANDLER METHODS

This class has succeeded to L<Egg::Request::Upload>.

=head2 filename

The file name of the up-loading file is returned.

There seems to be a thing that the file name including the directory of the
upload environment of the client is returned though it might be the one by the
environment.

When only the file name is acquired, it is good to use 'catfilename' method of
L<Egg::Request::Upload>.

  my $filename= $upload->filename;

=head2 tempname

The work passing of the up-loading file is temporarily returned.

  my $tmpfile= $upload->tempname;

=head2 size

The size of the upload file is returned.

=head2 type

The contents type of the upload file is returned.

=head2 info

Information on the upload file is returned.

  my $type = $upload->info->{'Content-Type'};

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Request>,
L<Egg::Request::Upload>,
L<Egg::Plugin::Request::Upload>,
L<CGI::Upload>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

