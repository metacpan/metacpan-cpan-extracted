package Egg::Helper::Build::Prototype;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Prototype.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use File::Spec;
use HTML::Prototype;

our $VERSION= '3.00';

sub _start_helper {
	my($self)= @_;
	my $c= $self->config;
	my $o= $self->_helper_get_options;
	return $self->_helper_help() if $o->{help};

	my $htdocs= $c->{dir}{htdocs} || $c->{dir}{static}
	   || return $self->_helper_help('I want configuration dir->{htdocs}.');
	-e $htdocs
	   || return $self->_helper_help("'$htdocs' is not found.");

	my $prototype = File::Spec->catfile( $htdocs, 'prototype.js' );
	my $controls  = File::Spec->catfile( $htdocs, 'controls.js' );
	my $dragdrop  = File::Spec->catfile( $htdocs, 'dragdrop.js' );
	my $complete  = <<END_INFO;

... completed.

  prototype.js : $prototype
  controls.js  : $controls
  dragdrop.js  : $dragdrop

END_INFO

	$self->helper_generate_files(
	  param => {}, chdir => [$c->{root}],
	  complete_msg => $complete,
	  create_files => [
	    { filename=> $prototype, value=> $HTML::Prototype::prototype },
	    { filename=> $controls,  value=> $HTML::Prototype::controls  },
	    { filename=> $dragdrop,  value=> $HTML::Prototype::controls  },
	    ],
	  );
}
sub _helper_help {
	my $self = shift;
	my $msg  = shift || "";
	   $msg .= "\n\n" if $msg;
	my $pname= lc $self->project_name;
	print <<END_HELP;
${msg}% perl ${pname}_helper.pl Plugin::Prototype [-h]

END_HELP
}

1;

__END__

=head1 NAME

Egg::Helper::Build::Prototype - Helper who outputs prototype.js

=head1 SYNOPSIS

  % cd /path/to/MyApp/bin
  % ./myapp_helper Build::Prototype

=head1 DESCRIPTION

It is a helper according to HTML::Prototype to whom the project outputs 'htdocs'
below as for 'prototype.js' etc.

The usage only specifies 'Build::Prototype' and the mode for the helper script
of the project.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Helper>,
L<Egg::Plugin::Prototype>,
L<HTML::Prototype>,
L<File::Spec>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

