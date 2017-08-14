package MToken; # $Id: MToken.pm 43 2017-07-31 13:04:58Z minus $
use strict;

=head1 NAME

MToken - Tokens processing system (Security)

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use MToken;

=head1 DESCRIPTION

This module provides main functionality for mtoken tool.

For internal use only

=head2 FUNCTIONS

=over 8

=item B<init>

Initialize the Token device

=item B<test>

Test function. Do not use it

=item B<void>

Void function. Do not use it

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<LWP>, C<mod_perl2>, L<CTK>, C<openssl>, C<gnupg>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<CTK>, L<mod_perl2>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw/ $VERSION /;
$VERSION = "1.00";

use CTKx;
use CTK qw/ :BASE /;
use CTK::Util qw/ :BASE :UTIL /;
use MToken::Helper;
use MToken::Util;

sub void {
    #debug("VOID CONTEXT");
    1;
}
sub test {
    #debug("Testing...");
    #debug;

    #my $c = CTKx->instance->c;
    #my %cmd = @_;

    #my @arguments = @{$cmd{arguments}};

    #debug("Argumens: ", join("; ",@arguments) || 'none' );
    #$c->info("Arguments:", @arguments);

    #debug("Input params:");
    #debug(Data::Dumper::Dumper(\%cmd));

    # CTK debug
    #my $config = $c->config;
    #if (verbosemode) {
    #    debug("CTK object:");
    #    debug(Data::Dumper::Dumper($c));
    #}

    #debug(Data::Dumper::Dumper($c->options));

    #
    # . . .
    #

    1;
}
sub init {
    my %cmd = @_;
    my @arguments = @{$cmd{arguments}};
    my $prj = shift(@arguments);
    my $c = CTKx->instance->c;
    my $dir  = $c->options->{directory} || undef;

    my $h = new MToken::Helper (
        -project    => $prj,
        -dir        => $dir,
    );
    say sprintf("Initializing device \"%s\"...", $h->{project});

    # Building
    my $hstat = $h->build();
    unless ($hstat) {
        carp("ERROR. Can't initialize the device");
        return 1;
    }

    say "Done.";
    1;
}

1;
