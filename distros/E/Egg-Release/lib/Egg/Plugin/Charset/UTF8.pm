package Egg::Plugin::Charset::UTF8;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: UTF8.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use Jcode;
use base qw/Egg::Plugin::Charset/;

our $VERSION = '3.00';

sub _setup {
	my($e)= @_;
	my $c= $e->config;
	$c->{content_language} ||= 'ja';
	$c->{content_type} ||= 'text/html';
	$c->{charset_out}= 'utf-8';
	$e->next::method;
}
sub _convert_output_body {
	my $e= shift;
	my $body= shift || return 0;
	Jcode->new($body);
}

1;

__END__

=head1 NAME

Egg::Plugin::Charset::UTF8 - Plugin to output contents with UTF-8.

=head1 SYNOPSIS

  use Egg qw/ Charset::UTF8 /;

=head1 DESCRIPTION

This plugin is a subclass of L<Egg::Plugin::Charset>.

Contents are output with UTF-8.

The conversion of the character-code is L<Jcode>. Has gone.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Plugin::Charset>,
L<Jcode>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

