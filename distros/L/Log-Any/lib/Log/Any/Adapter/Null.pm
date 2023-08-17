use 5.008001;
use strict;
use warnings;

package Log::Any::Adapter::Null;

# ABSTRACT: Discards all log messages
our $VERSION = '1.717';

use Log::Any::Adapter::Base;
our @ISA = qw/Log::Any::Adapter::Base/;

use Log::Any::Adapter::Util ();

# All methods are no-ops and return false

foreach my $method (Log::Any::Adapter::Util::logging_and_detection_methods()) {
    no strict 'refs';
    *{$method} = sub { return '' }; # false
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Null - Discards all log messages

=head1 VERSION

version 1.717

=head1 SYNOPSIS

    Log::Any::Adapter->set('Null');

=head1 DESCRIPTION

This Log::Any adapter discards all log messages and returns false for all
detection methods (e.g. is_debug). This is the default adapter when Log::Any is
loaded.

=head1 SEE ALSO

L<Log::Any|Log::Any>, L<Log::Any::Adapter|Log::Any::Adapter>

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Doug Bell <preaction@cpan.org>

=item *

Daniel Pittman <daniel@rimspace.net>

=item *

Stephen Thirlwall <sdt@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jonathan Swartz, David Golden, and Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
