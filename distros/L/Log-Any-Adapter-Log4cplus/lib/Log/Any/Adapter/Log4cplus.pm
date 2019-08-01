package Log::Any::Adapter::Log4cplus;

use 5.008001;
use warnings;
use strict;

=head1 NAME

Log::Any::Adapter::Log4cplus - Adapter to use Lib::Log4cplus with Log::Any

=cut

our $VERSION = '0.001';

=head1 SYNOPSIS
 
    use Log::Any::Adapter;
 
    Log::Any::Adapter->set('Log4cplus', file => '/path/to/log.properties');
 
    my $logger = Lib::Log4cplus->new( str => $config_string );
    Log::Any::Adapter->set('Log4cplus', logger => $logger);
 
=head1 DESCRIPTION
 
This L<Log::Any> adapter uses L<Lib::Log4cplus> for
logging.
 
You may either pass parameters (like I<outputs>) to be passed to
C<< Lib::Log4cplus->new >>, or pass a C<Lib::Log4cplus::Logger> object directly in the
I<logger> parameter.

=cut

use Log::Any::Adapter::Util qw(make_method);
use Log::Log4cplus;
use parent qw(Log::Any::Adapter::Base);

sub init
{
    my $self = shift;

    # If a dispatcher was not explicitly passed in, create a new one with the passed arguments.
    #
    $_[-2] eq "category" and splice @_, -2, 2;
    $self->{logger} ||= Log::Log4cplus->new(@_);
}

# Delegate logging methods to same methods in dispatcher
#
foreach my $method (Log::Any->logging_methods())
{
    __PACKAGE__->delegate_method_to_slot('logger', $method, $method);
}

# Delegate detection methods to would_log
#
foreach my $method (Log::Any->detection_methods())
{
    __PACKAGE__->delegate_method_to_slot('logger', $method, $method);
}

1;

=head1 SEE ALSO
 
L<Log::Any::Adapter>, L<Log::Any>,
L<Lib::Log4cplus>
 
=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Log-Any-Adapter-Log4cplus at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Any-Adapter-Log4cplus>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Any::Adapter::Log4cplus

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Any-Adapter-Log4cplus>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Any-Adapter-Log4cplus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Any-Adapter-Log4cplus>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Any-Adapter-Log4cplus/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2018-2019 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
