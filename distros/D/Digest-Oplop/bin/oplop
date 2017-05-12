#!/usr/bin/perl

use strict;
use warnings;
use Digest::Oplop qw(oplop);
use IO::Prompt;
use Getopt::Long;
use Pod::Usage;

my $validate = 0;
my $help     = 0;

GetOptions(
	'validate!' => \$validate,
	'help|?'    => \$help,
) or pod2usage(2) ;

pod2usage(1) if $help;

my $label = shift || prompt('Label: ');

my $master = prompt( 'Master: ', -e => '*' );

if ($validate) {
	if ($master ne prompt( 'Master: ', -e => '*' )) {
		die "Master passwords do not match.\n";
	}
}

my $password = oplop( $master, $label );

eval {
    require Clipboard;
    Clipboard->import();
    Clipboard->copy($password);
};

print "$password\n";

exit 0;

__END__

=head1 NAME

oplop - Generate account passwords based on a nickname and a master password

=head1 DESCRIPTION

Oplop makes it easy to create unique passwords for every account you
have. By using some math, Oplop only requires of you to remember account
nicknames and a master password to create a very safe and secure password
just for you.

If the account label is not specified, oplop will prompt you to enter it.

When Clipboad L<http://search.cpan.org/~king/Clipboard-0.13/> is also
installed, the password will be copied into the clipboard for you.

=head1 SYNOPSIS

oplop [--validate] [label]

=head1 OPTIONS

=over 4

=item B<--validate>

Validate the master password by asking twice.

=back

=head1 SEE ALSO

=over 4

=item * How it works

L<http://code.google.com/p/oplop/wiki/HowItWorks>

=item * Threat Model

L<http://code.google.com/p/oplop/wiki/ThreatModel>

=item * FAQ

L<http://code.google.com/p/oplop/wiki/FAQ>

=item * Why choose oplop?

L<http://code.google.com/p/oplop/wiki/WhyChooseOplop>

=item * Implementations

L<http://code.google.com/p/oplop/wiki/Implementations>

=back

=head1 ACKNOWLEDGEMENTS

L<http://code.google.com/p/oplop/>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mario Domgoergen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information

