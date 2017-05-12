package FormValidator::Simple::Plugin::Number::Phone::JP;

use strict;
use Number::Phone::JP;
use FormValidator::Simple::Constants;

our $VERSION = '0.04';
our @CARP_NOT = qw(Number::Phone::JP);

sub NUMBER_PHONE_JP {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    #return FALSE unless $data;
    
    my $tel = Number::Phone::JP->new($data);
    return $tel->is_valid_number ? TRUE : FALSE;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

FormValidator::Simple::Plugin::Number::Phone::JP - Japanese phone number validation

=head1 SYNOPSIS

  use FormValidator::Simple qw/Number::Phone::JP/;

  my $result = FormValidator::Simple->check( $req => [
      tel       => [ 'NOT_BLANK', 'NUMBER_PHONE_JP' ],
  ] );

=head1 DESCRIPTION

This modules adds Japanese phone number  validation command to FormValidator::Simple. 

=head1 SEE ALSO

L<FormValidator::Simple>

L<Number::Phone::JP>

=head1 AUTHOR

Gosuke Miyashita, E<lt>gosukenator@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Gosuke Miyashita

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
