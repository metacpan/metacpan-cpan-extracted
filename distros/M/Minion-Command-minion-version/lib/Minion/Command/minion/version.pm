package Minion::Command::minion::version;

use Mojo::Base 'Mojolicious::Command';

our $VERSION = '0.02';

has description => 'Show version of Minion';
has usage => sub { shift->extract_usage };

sub run {
   my $self = shift;

   my $minion_version = eval 'use Minion; 1' ? $Minion::VERSION : 'n/a';

   print <<EOF;
      Perl    ($^V, $^O)
      Minion  ($minion_version)
EOF

  # Check latest version on CPAN
  my $latest = eval {
    $self->app->ua->max_redirects(10)->tap(sub { $_->proxy->detect })
      ->get('fastapi.metacpan.org/v1/release/Minion')
      ->result->json->{version};
  } or return;
 
  my $msg = 'This version is up to date, have fun!';
  $msg = 'Thanks for testing a development release, you are awesome!'
    if $latest < $Minion::VERSION;
  $msg = "You might want to update your Minion to $latest!"
    if $latest > $Minion::VERSION;
  say $msg;
}

=head1 NAME

Minion::Command::minion::version - Minion version command

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

   Usage:  APPLICATIION minion version

   Options:
       -h, --help   Show this summary of available options

=head1 ATTRIBUTES

=head2 description

   my $description = $v->description;
   $v              = $v->description('Foo');
 
Short description of this command, used for the command list.

=head2 usage

   my $usage = $v->usage;
   $v        = $v->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

=head2 run

   $v->run(@ARGV);
 
Run this command.

=cut

=head1 AUTHOR

Bob Faist, C<< <bfaist at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Most of this code borrows heavily from L<Mojolicious::Command::version> written by sri.

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Bob Faist.

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

1; # End of Minion::Command::minion::version
