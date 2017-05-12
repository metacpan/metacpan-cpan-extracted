package Egg::Util::STDIO;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: STDIO.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use IO::Scalar;
use Carp qw/croak/;

our $VERSION= '3.00';

sub out { shift->_stdio(*STDOUT, @_) }
sub in  { shift->_stdio(*STDIN, @_) }

sub _stdio {
	my($class, $handle, $e)= splice @_, 0, 3;
	my $code= shift || croak q{ I want code. };
	ref($code) eq 'CODE' || croak q{ I want CODE reference. };
	my $q= shift || "";
	$q= $$q if ref($q) eq 'SCALAR';
	eval {
		tie $handle, 'IO::Scalar', \$q;
		$code->($e, @_);
		untie $handle;
	  };
	Egg::Util::STDIO::result->new($handle, \$q, $@);
}

package Egg::Util::STDIO::result;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/ result error /);

sub new {
	my($class, $handle, $result, $error)= @_;
	$error= q{'STDOUT' is not output.}
	     if ($handle=~m{STDOUT} and ! $error and ! defined($$result));
	bless { result=> $$result, error=> ($error || undef) }, $class;
}

1;

__END__

=head1 NAME

Egg::Util::STDIO - Module to use IO::Scalar easily.

=head1 SYNOPSIS

  use Egg::Util::STDIO;
  
  my $res= Egg::Util::STDIO->out(0, sub {
        print "Hellow";
     });
  
  print $res->result;

=head1 DESCRIPTION

L<IO::Scalar> It is a module to use it for easy.

=head1 METHODS

=head2 out ([CONTEXT], [CODE_REF])

STDOUT is obtained and the Egg::Util::STDIO::result object is returned.

It is not especially necessary though the thing that the object of the project is passed is 
assumed to CONTEXT.

CODE_REF is always necessary.

=head2 in ([CONTEXT], [CODE_REF])

STDIN is obtained and the Egg::Util::STDIO::result object is returned.

It is not especially necessary though the thing that the object of the project is passed is 
assumed to CONTEXT.

CODE_REF is always necessary.

=head1 RESULT METHODS

=head2 new

Constructor.

=head2 result

The obtained data is returned.

=head2 error

When the error occurs, the message is returned.

=head1 SEE ALSO

L<Egg::Release>,
L<IO::Scalar>,
L<Class::Accessor::Fast>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

