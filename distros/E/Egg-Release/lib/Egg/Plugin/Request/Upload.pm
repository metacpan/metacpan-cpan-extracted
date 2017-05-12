package Egg::Plugin::Request::Upload;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Upload.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use Egg::View::Template::GlobalParam;

our $VERSION= '3.00';

sub _setup {
	my($e)= @_;

	my $pkg= 'Egg::Request::Upload::'. ($e->mp_version ? 'ModPerl': 'CGI');
	$pkg->require or die $@;

	$Egg::View::Template::GlobalParam::param{upload_enctype}= 'multipart/form-data';

	no strict 'refs';  ## no critic.
	push @{'Egg::Request::handler::ISA'}, $pkg;

	"${pkg}::handler"->_setup($e);
	$e->next::method;
}

1;

__END__

=head1 NAME

Egg::Plugin::Upload - File upload function.

=head1 SYNOPSIS

  use Egg qw/ Request::Upload /;
  
  # Acquisition of up-loading object.
  my $upload= $e->request->upload('upload_param_name');

=head1 DESCRIPTION

File upload function availably setup L<Egg::Request::Upload> to this module.

The 'upload' method is added to $e-E<gt>request by this setup.

This plugin doesn't have the method that can be used.

see L<Egg::Request::Upload>.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Request>,
L<Egg::Request::Upload>,
L<Egg::Request::Upload::CGI>,
L<Egg::Request::Upload::ModPerl>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

