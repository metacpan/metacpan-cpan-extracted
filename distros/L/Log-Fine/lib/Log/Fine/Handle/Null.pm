
=head1 NAME

Log::Fine::Handle::Null - Output messages to nowhere

=head1 SYNOPSIS

Provides logging to nowhere in particular

    use Log::Fine::Handle::Null;
    use Log::Fine::Levels::Syslog qw( :masks );

    # Create a new handle
    my $handle = Log::Fine::Handle::Null
      ->new( name => "devnull",
             mask => LOGMASK_DEBUG | LOGMASK_INFO | LOGMASK_NOTICE
           );

    # This is a no-op
    $handle->msgWrite(INFO, "Goes Nowhere.  Does Nothing.");

=head1 DESCRIPTION

The null handle provides logging to nowhere in particular.

=cut

use strict;
use warnings;

package Log::Fine::Handle::Null;

use base qw( Log::Fine::Handle );

use Log::Fine;

our $VERSION = $Log::Fine::Handle::VERSION;

=head1 METHODS

=head2 msgWrite

See L<Log::Fine::Handle/msgWrite>

=cut

sub msgWrite { return $_[0]; }          # msgWrite()

=head1 BUGS

Please report any bugs or feature requests to
C<bug-log-fine at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Fine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Fine

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Fine>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Fine>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Fine>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Fine>

=back

=head1 AUTHOR

Christopher M. Fuhrman, C<< <cfuhrman at pobox.com> >>

=head1 SEE ALSO

L<perl>, L<Log::Fine::Handle>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013 Christopher M. Fuhrman, 
All rights reserved.

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;          # End of Log::Fine::Handle::Null
