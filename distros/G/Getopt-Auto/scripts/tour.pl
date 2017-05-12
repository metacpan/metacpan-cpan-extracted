#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  tour.pl
#
#        USAGE:  ./tour.pl
#
#  DESCRIPTION:  A Tour of Getopt::Auto's facilities
#
#       AUTHOR:  Geoffrey Leach (), geoff@hughes.net
#      VERSION:  1.0
#      CREATED:  09/06/2009 04:37:59 PM
#===============================================================================

use strict;
use warnings;

# OK, so I lied. We're only going to tour the "magic" of Getopt::Auto.
# If you need to use the list parameters, you should be able to
# backfit them from what follows.  Or not.

use Getopt::Auto( { 'nobare' => 1, 'init' => \&init, 'okerror' => 1 } );
use Pod::Usage;
use 5.006;

# Checking the return vaue from a print statement?
# Give me a break!
## no critic (RequireCheckedSyscalls)

# Here's the version that Getopt::Auto will look for.
# "our" is not necessary, as the value is obtained by scanning the source.
# However, perlcritic complains if it's _not_ there. So ...
our $VERSION = "1.0";

# This is where the single-use options show up.
# Notice the "our". It's necessary. Perlcritic complains! Sigh!

our %options;    ## no critic (ProhibitPackageVars)

# These subs are here only because that's how I like to organize.
# However, you could say that they are here because they are
# executed by Getopt::Auto (if called out by options) before the
# actual execution starts. Now, how cool is that?

my $did_itemopt;

sub init {
    print "Did init\n";
    return;
}

sub itemopt {
    my $itemval = shift @ARGV;
    if ( $itemval =~ m{^\d+$/}sxm ) {
        print "Your itemopt value is: $itemval\n";
    }
    else {
        print "Itemopt value $itemval is not integer\n";
    }
    $did_itemopt = 1;
    delete $options{'--itemopt'};
    return;
}

sub usage {
    pod2usage( -verbose => 99, -sections => 'DESCRIPTION' );
    exit 0;
}

sub help {
    pod2usage( -verbose => 2 );
    exit 0;
}

# Program execution starts here, even though some of the
# subs may have been executed aready

# Process the single-use options
# The opions are deleted so that the "Undefined option"
# processing does not complain about them.

if ( ( !@ARGV ) && ( not keys %options ) && ( not defined $did_itemopt ) ) {
    print "What, no options?\n";
    exit 0;
}

if ( exists $options{'--nodef'} ) {
    print "You selected '--nodef', but it was not defined!\n";
    delete $options{'--nodef'};
}

if ( exists $options{'--cutup'} ) {
    print "You selected '--cutup'\n";
    delete $options{'--cutup'};
}

if ( exists $options{'-c'} ) {
    print "You selected '-c'\n";
    delete $options{'-c'};
}

foreach ( keys %options ) {
    print "Option: $_ => $options{$_}\n";
}

foreach (@ARGV) {
    print "Unused command-line data: $_\n";
}

exit 0;

__END__

=pod

=begin stopwords
notfound
notwanted
builtin
nobare
itemopt
=end stopwords

=head1 SYNOPSIS

Shows the use of C<Getopt::Auto>.

    ./tour.pl <options>

=head1 DESCRIPTION

Some things to try.

The options listed below. Pretty obvious.

C<tour.pl> without any options. Notice how we check for that.
Notice C<use Getopt::Auto> has a hashref as argument. The C<okerror> allows
some additional processing after command-line errors (such as "not a registered option")
are detected.

C<tour.pl -food>: Notice how it's split up.

C<tour.pl --notexpected notfound - notwanted>. Notice that --notexpected (double dash) is left on the
command line, whereas -notexpected (single dash) would not be. "notfound" is something that might have been 
processed by --notexpected, had it been expected. "notwanted" would not be processed in
any case because it follows the "Cease and Desist" marker, "-".

C<tour.pl --itemopt 12 --itemopt xy> demonstrates multiple uses of a single option (not very
exciting) and how an option can process its values. Complexity limited only by your
imagination (and tolerance for user errors!)

C<tour.pl --item work>, just to prove that the documentation does not lie.

C<tour.pl --nodef>. What a surprise! Where's the =head2? 

=head1 OPTIONS

Ok, here we go.

=head2 -u, --usage - Prints the DESCRIPTION.

=head2 -h, --help - Overrides the builtin.

=head2 -c, --cutup - The c option

=head2 -f - The f option, part of the -food demo

Cutup (and c) do not have subs, so to see that they are called, we must
check %options.

As we're going to all this trouble to create POD, it seems a shame not
to use it. Note that help() is not called in the code. It happens before
anything else.

=head2 work - do the work!

This would be a bare option, except that we've said 'nobare'
in the configuration
to outlaw bareness. This is not a nude beach, after all.

=head2 --item options

Note that there is no ' - ', so not an option
What follows is an option that is introduced by "=item".

=over 4

=item --itemopt - Which is an option in an item

Note that there is no '-i'
This option has an integer argument.

=back

=cut
