package FormValidator::Simple::Plugin::CustomConstraint;

use 5.012004;
use strict;
use warnings;

use FormValidator::Simple::Constants;

require Exporter;

our @ISA = qw/Exporter/;

our %EXPORT_TAGS = ( 'all' => [ qw// ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw//;

our $VERSION = '0.01';

sub CUSTOM_CONSTRAINT {
  my ( $self, $params, $args ) = @_;
  my $coderef = shift @{ $args };
  return $coderef->( $params->[0], $args ) ? TRUE : FALSE;
}

1;
__END__

=head1 NAME

FormValidator::Simple::Plugin::CustomConstraint - Custom constraint support for FormValidator::Simple

=head1 SYNOPSIS

  use FormValidator::Simple qw/CustomConstraint/;

  my $input_params = {
    username => 'someone'
  };

  #limit search to 10 records for example
  my $arg_limit = 'LIMIT 10';

  #run the check
  my $result = FormValidator::Simple->check(
    $input_params => [
      username => [ 'NOT_BLANK', [ 'CUSTOM_CONSTRAINT', \&validate_username, $arg_limit ] ]
    ]
  );

  #define our custom validation rule
  sub validate_username {
    my ( $constraint_value, $other_args ) = @_;
    #check the database to see if username exists for example and use passed in argument ...
    $exists = $dbh->selectrow_arrayref( $sql, {}, $other_args->[0] )->[0];
    return $exists ? 1 : 0;
  }

=head1 DESCRIPTION

 This module provides a plugin for FormValidator::Simple that allows for custom constraint definitions
 or custom validation rules to be specified.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Catalyst::Plugin::FormValidator::Simple>, L<FormValidator::Simple>

=head1 AUTHOR

Alex Pavlovic, E<lt>alex.pavlovic@taskforce-1.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Alex Pavlovic ( alex.pavlovic@taskforce-1.com )

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
