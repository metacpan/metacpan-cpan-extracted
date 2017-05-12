
###############################################################################
##                                                                           ##
##    Copyright (c) 2001 by Steffen Beyer.                                   ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Internals;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION %EXPORT_TAGS);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw();

@EXPORT_OK = qw(IsWriteProtected SetReadOnly SetReadWrite GetRefCount SetRefCount);

$VERSION = '1.1';

%EXPORT_TAGS = (all => [@EXPORT_OK]);

bootstrap Internals $VERSION;

1;

__END__

=head1 NAME

Internals - Write-protect variables, manipulate refcounts

=head1 SYNOPSIS

  use Internals qw(IsWriteProtected SetReadOnly SetReadWrite GetRefCount SetRefCount);

  use Internals qw(:all);

  $object = My::Class->new(@parameters);

  SetReadOnly($object);

  SetReadWrite($object);

  if (IsWriteProtected($object)) { ... }

  $value = GetRefCount($object);

  SetRefCount($object,$value);

or

  package My::Class;

  use Internals;

  @ISA = qw(Internals);

  $object = My::Class->new(@parameters)->SetReadOnly();

  $object->SetReadWrite();

  if ($object->IsWriteProtected()) { ... }

  $value = $object->GetRefCount();

  $object->SetRefCount($value);

or

  use Internals qw(IsWriteProtected SetReadOnly SetReadWrite GetRefCount SetRefCount);

  use Internals qw(:all);

  SetReadOnly(\$scalar);

  SetReadOnly(\@array);

  SetReadOnly(\%hash);

  SetReadOnly(\$hash{$element});

  SetReadOnly(\$reference);

etc.

=head1 DESCRIPTION

This module allows you to write-protect and write-enable
your Perl variables, objects and data structures.

Moreover, the reference count of any Perl variable can
be read and set.

You can never pass the object directly on which to
perform the desired action, you always have to pass
a reference to the variable or data structure in
question.

This comes in handy for objects and anonymous data
structures, where you only have a reference anyway!

BEWARE: This module is DANGEROUS!

DO NOT attempt to unlock Perl's built-in variables!

DO NOT manipulate reference counts unless you know
exactly what you're doing!

ANYTHING might happen! Hell might break loose! C<:-)>

YOU HAVE BEEN WARNED!

=head1 VERSION

This man page documents "Internals" version 1.1.

=head1 AUTHOR

  Steffen Beyer
  mailto:sb@engelschall.com
  http://www.engelschall.com/u/sb/download/

=head1 COPYRIGHT

Copyright (c) 2001 by Steffen Beyer. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, i.e., under the
terms of the "Artistic License" or the "GNU General Public License".

Please refer to the files "Artistic.txt" and "GNU_GPL.txt"
in this distribution for details!

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

