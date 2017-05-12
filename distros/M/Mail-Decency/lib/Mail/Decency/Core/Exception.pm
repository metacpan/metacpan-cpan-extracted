package Mail::Decency::Core::Exception;
use Moose;
with 'Throwable';

use version 0.74; our $VERSION = qv( "v0.1.4" );

=head1 NAME

Mail::Decency::Core::Exception

=head1 DESCRIPTION

Base class for exceptions in decency

=head1 SYNOPSIS

    Mail::Decency::Core::Exception::Reject->new( "some message" );

=head1 METHODS

=cut

use overload '""' => \&get_message;

has message  => ( is => "rw", isa => "Str", required => 0 );
has internal => ( is => "rw", isa => "Str", required => 0 );

sub get_message { shift->message }


package Mail::Decency::Core::Exception::Reject;
use Moose;
extends 'Mail::Decency::Core::Exception';

package Mail::Decency::Core::Exception::Accept;
use Moose;
extends 'Mail::Decency::Core::Exception';

package Mail::Decency::Core::Exception::Prepend;
use Moose;
extends 'Mail::Decency::Core::Exception';

package Mail::Decency::Core::Exception::Spam;
use Moose;
extends 'Mail::Decency::Core::Exception';

package Mail::Decency::Core::Exception::Virus;
use Moose;
extends 'Mail::Decency::Core::Exception';

package Mail::Decency::Core::Exception::Timeout;
use Moose;
extends 'Mail::Decency::Core::Exception';

package Mail::Decency::Core::Exception::FileToBig;
use Moose;
extends 'Mail::Decency::Core::Exception';

package Mail::Decency::Core::Exception::Timeout;
use Moose;
extends 'Mail::Decency::Core::Exception';

package Mail::Decency::Core::Exception::ReinjectFailure;
use Moose;
extends 'Mail::Decency::Core::Exception';

package Mail::Decency::Core::Exception::Drop;
use Moose;
extends 'Mail::Decency::Core::Exception';




=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;

