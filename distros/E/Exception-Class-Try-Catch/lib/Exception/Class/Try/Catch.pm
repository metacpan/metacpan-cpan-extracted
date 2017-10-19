# Copyright (c) 2017 by Pali <pali@cpan.org>

package Exception::Class::Try::Catch;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.2';

use Carp;
use Exception::Class::Base;
use Exporter 5.57 'import';
use Scalar::Util;
use Try::Catch qw(try);

$Carp::Internal{+__PACKAGE__} = 1;

our @EXPORT_OK = qw(try catch);
our @EXPORT = @EXPORT_OK;

sub catch (&) {
	my $block = $_[0];
	$_[0] = sub {
		my $error = $_[0];
		if (Scalar::Util::blessed($error) and not $error->isa('Exception::Class::Base')) {
			$error = $error->as_string() if $error->can('as_string');
			$error = "$error";
		}
		if (not Scalar::Util::blessed($error)) {
			$_[0] = $_ = Exception::Class::Base->new($error);
		}
		goto &$block;
	};
	goto &Try::Catch::catch;
}

1;
__END__

=head1 NAME

Exception::Class::Try::Catch - Try::Catch for Exception::Class

=head1 SYNOPSIS

  use Exception::Class::Try::Catch;

  try {
      My::Exception::Class->throw('my error');
  } catch {
      if ($_->isa('Specific::Exception')) {
          handle_specific_exception($_);
      } elsif ($_->isa('Local::Exception')) {
          handle_local_exception($_);
      } else {
          # $_ is always object of 'Exception::Class::Base'
          handle_base_exception($_);
      }
  };

  try {
      die 'my error';
  } catch {
      # $_ is always object of 'Exception::Class::Base'
      handle_base_exception($_);
      process_text_of_exception($_->error);
  };

  try {
      die 'my error';
  } catch {
      $_->rethrow();
  };

=head1 DESCRIPTION

C<Exception::Class::Try::Catch> provides C<try>/C<catch> syntactic sugar from
L<Try::Catch|Try::Catch> for L<Exception::Class|Exception::Class> object
exceptions.

In other words, the exception thrown in the C<try> block will always be an
object of the L<Exception::Class::Base|Exception::Class::Base> class or its
ancestor in the catch block. If you throw an exception of a different class,
or just C<die> with an error message, the exception will be stringified
(by the C<as_string> method, if available) and blessed into
L<Exception::Class::Base|Exception::Class::Base>. Exceptions inheriting from
L<Exception::Class::Base|Exception::Class::Base> remain unchanged.

=head1 SEE ALSO

L<Try::Catch>,
L<Exception::Class>

=head1 AUTHOR

Pali E<lt>pali@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Pali E<lt>pali@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
