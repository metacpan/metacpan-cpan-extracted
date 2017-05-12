package Egg::View::Mail::Plugin::Jfold;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Jfold.pm 285 2008-02-28 04:20:55Z lushe $
#
use strict;
use warnings;
use Jcode;

our $VERSION = '0.01';

sub __get_mailbody {
	my($self, $data)= @_;
	my $body= $self->next::method($data);
	my $j   = $self->{jcode_context}= Jcode->new('jcode');
	my $len = $data->{line_length} || 72;
	my $text;
	for (split /\n/, $$body) {
		$text.= $_ ? join("\n", $j->set(\$_)->jfold($len)). "\n" : "\n";
	}
	\$text;
}

1;

__END__

=head1 NAME

Egg::View::Mail::Plugin::Jfold - The numbers of characters of each line of mail are united. 

=head1 SYNOPSIS

  package MyApp::View::Mail::MyComp;
  use base qw/ Egg::View::Mail::Base /;
  
  ...........
  .....
  
  __PACKAGE__->setup_plugin('Jfold');

=head1 DESCRIPTION

The number of characters of each line of mail is adjusted by using 'Jfold' of 
Jcode.

When 'Jfold' is passed to 'setup_plugin' method, it is built in.

Please note that there is a thing that the processing result doesn't become it 
according to the expectation when using it with other components that use 
'__get_mailbody' in built-in the order.

  __PACKAGE__->setup_plugin(qw/
     EmbAgent
     Jfold
     /);

It comes to be able to set the following items.

=head3 line_length

Lengths of number of characters of each line. The number of characters of 1byte
 character conversion is set.

Default is '72'.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::View::Mail>,
L<Egg::View::Mail::Base>,
L<Jcode>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

