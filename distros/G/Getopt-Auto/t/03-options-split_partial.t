#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  03-options-split_partial.t
#
#  DESCRIPTION:  Test splitting a short option where there's a sub for one of the components
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      COMPANY:
#      VERSION:  1.9.8
#      CREATED:  Tue Dec 29 16:12:56 PST 2009
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 7;
use Test::Output;

## no critic (RequireLocalizedPunctuationVars)
## no critic (ProhibitPackageVars)
## no critic (ProtectPrivateVars)
## no critic (ProtectPrivateSubs)

use 5.006;
our $VERSION = '1.9.8';
our %options;

use Getopt::Auto{ 'nohelp' => 1 };

my $is_b_called;
sub b { $is_b_called = 1; return; }

@ARGV = qw(-bar);
stderr_is(
    \&Getopt::Auto::_parse_args,
    "Getopt::Auto: -r (from -bar) is not a registered option\n",
    '-r (from -bar) correctly reported not a registered option'
);

ok( defined($is_b_called),                   'b() called' );
ok( Getopt::Auto::test_option('-bar') == 0, '-bar is not an option' );
ok( !defined $options{'-bar'},               '-bar is not set' );
ok( !defined $options{'-b'},                 '-b is not set' );
ok( defined $options{'-a'},                  '-a is set' );
ok( !defined $options{'-r'},                 '-r is not set' );

exit 0;

__END__

=pod

=head2 --bar - do a bar

=head2 -b - do b for -bar

=head2 -a - set a in options

=cut
