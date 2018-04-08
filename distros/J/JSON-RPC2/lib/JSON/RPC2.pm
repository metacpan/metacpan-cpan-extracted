package JSON::RPC2;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.1.2';


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

JSON::RPC2 - Transport-independent implementation of JSON-RPC 2.0


=head1 VERSION

This document describes JSON::RPC2 version v2.1.2


=head1 SYNOPSIS

See L<JSON::RPC2::Server> and L<JSON::RPC2::Client> for usage examples.


=head1 DESCRIPTION

This module implement JSON-RPC 2.0 protocol in transport-independent way.
It was very surprising for me to find on CPAN a lot of transport-dependent
implementations of (by nature) transport-independent protocol!

Also it support non-blocking client remote procedure call and both
blocking and non-blocking server method execution. This can be very useful
in case server methods will need to do some RPC or other slow things like
network I/O, which can be done in parallel with executing other server
methods in any event-based environment.


=head1 INTERFACE

See L<JSON::RPC2::Server> and L<JSON::RPC2::Client> for details.


=head1 RATIONALE

There a lot of other RPC modules on CPAN, most of them has features doesn't
provided by this module, but they either too complex and bloated or lack
some features I need.

=over

=item L<RPC::Lite>

Not transport-independent.

=item L<RPC::Simple>

Not transport-independent.
Do eval() of perl code received from remote server.

=item L<RPC::Async>

Not transport-independent.
Not event-loop-independent.

=item L<JSON::RPC>

=item L<RPC::JSON>

=item L<RPC::Object>

=item L<Event::RPC>

=item L<RPC::Serialized>

=item L<XML::RPC>

=item L<RPC::XML>

Not transport-independent.
Blocking on remote function call.

=item L<JSON::RPC::Common>

In theory it's doing everything... but I failed to find out how to use it
(current version is 0.05) - probably it's incomplete yet. Even now it's
too complex and bloated for me, I prefer small and simple solutions.

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-JSON-RPC2/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-JSON-RPC2>

    git clone https://github.com/powerman/perl-JSON-RPC2.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=JSON-RPC2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/JSON-RPC2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JSON-RPC2>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=JSON-RPC2>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/JSON-RPC2>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
