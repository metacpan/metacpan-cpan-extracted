#!/usr/bin/perl -w
# vim: set ts=4 sw=4 tw=78 et si:
#
use strict;

use GeNUScreen::Config;
use Getopt::Long;
use Pod::Usage;

my %opt;

my $defaultcfg = 'config.hdf'; # default file unless --config given

GetOptions(\%opt,'config|cfg=s', 'help', 'man');

pod2usage(-exitstatus => 0, -input => \*DATA)                if $opt{help};
pod2usage(-exitstatus => 0, -verbose => 2, -input => \*DATA) if $opt{man};

my $cmd = shift;

pod2usage(0) unless $cmd;

my $cfg = GeNUScreen::Config->new();

if ($opt{config}) {
    $cfg->read_config($opt{config});
}
elsif (-r $defaultcfg) {
    $cfg->read_config($defaultcfg);
}

if ($cmd =~ /^print$/i) {
    foreach my $key (sort $cfg->get_keys()) {
        printout($key, $cfg->get_value($key) || '');
    }
}
elsif ($cmd =~ /^diff$/i) {
    my $otherfile = shift;
    pod2usage(-message => "please specify another config file for diff"
             ,-exitval => 1
             ) unless $otherfile;
    my $othercfg = GeNUScreen::Config->new();
    $othercfg->read_config($otherfile);
    my $diff = $cfg->diff($othercfg);
    print "configurations are equal\n" if $diff->is_empty();
    foreach (sort $diff->get_keys()) {
        printf "%s\n", $_;
        printout('  this', $diff->get_this_value($_) || '');
        printout('  that', $diff->get_that_value($_) || '');
    }
}
else {
    pod2usage(-message => "unknown command: $cmd"
             ,-exitval => 1
             );
}

sub printout {
    my ($key,$val) = @_;

    if ($val =~ /\n.*\n/) {
        printf "%s << EOM\n%sEOM\n", $key, $val;
    }
    else {
        printf "%s = %s\n", $key, $val;
    }
}

__END__

=head1 NAME

genuscreen-config - work with GeNUScreen config files

=head1 VERSION

This document describes genuscreen-config version v0.0.11

=head1 SYNOPSIS

  genuscreen [options] command [command options]

  options:

   -config filename - read configuration from that file

  commands:

    diff thatconfig - compare this configuration with that
    print           - print the configuration

=head1 DESCRIPTION

=head1 OPTIONS AND ARGUMENTS

=head2 Options

=head3 -config filename

Use the configuration file I<filename> for all commands.

If no option C<-config> was given and there is a file named I<config.hdf> in
the working directory, this is taken instead.

=head2 Commands

=head3 diff thatconfig

Compare the configuration given in option I<< -config >> with
I<< thatconfig >> and print the difference.

=head3 print

Print the configuration values.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 AUTHOR

Mathias Weidner C<< mamawe@cpan.org >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Mathias Weidner C<< mamawe@cpan.org >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
