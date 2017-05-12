#! /usr/bin/perl

BEGIN {
	unshift(@INC, './lib');
}

use strict;
use Echo::StreamServer::EQLShell;

my $shell = new Echo::StreamServer::EQLShell();
$shell->start;

1;
__END__

=head1 NAME

eql_shell.pl - Echo Query Language Shell

=head1 SYNOPSIS

  [user]$ eql_shell.pl
  ...
  SEARCH> scope:http://www.example.com/*

=head1 DESCRIPTION

This script is the C<Echo Query Language Shell>. It requires an Echo::StreamServer::Account.
The EQL Shell supports queries on the C<Items API> and the C<Users API>.

The eql_shell reads Echo::StreamServer::Settings and loads the default account.

=head1 SEE ALSO

Echo::StreamServer::Settings

=head1 AUTHOR

Andrew Droffner, E<lt>adroffne@advance.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Andrew Droffner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
