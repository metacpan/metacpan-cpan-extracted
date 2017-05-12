#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  05-nobundle.t
#
#  DESCRIPTION:  Test advanced option "nobundle"
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      COMPANY:
#      VERSION:  1.9.8
#      CREATED:  Tue Dec 29 16:13:06 PST 2009
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 7;
use Test::Output;

## no critic (RequireLocalizedPunctuationVars)
## no critic (ProtectPrivateSubs)
## no critic (ProtectPrivateVars)
## no critic (ProhibitPackageVars)

use 5.006;
our $VERSION = '1.9.8';
our %options;

use Getopt::Auto( { 'nobundle' => 1, 'nohelp' => 1 } );

my $is_bar_called;
sub bar { $is_bar_called = 1; return; }

# Option is "--bar" but we're saying "-bar" here
@ARGV = qw(-bar);
stderr_is(
    \&Getopt::Auto::_parse_args,
    "Getopt::Auto: -bar is not a registered option\n",
    '-bar correctly reported not a registered option'
);

ok( !defined($is_bar_called),                'bar() not called' );
ok( Getopt::Auto::test_option('-bar') == 0, '-bar is not an option' );
ok( !defined $options{'-bar'},               '-bar is not set' );
ok( !defined $options{'-b'},                 '-b is not set' );
ok( !defined $options{'-a'},                 '-a is not set' );
ok( !defined $options{'-r'},                 '-r is not set' );

exit 0;

__END__

=pod

=head2 --bar - do a bar

=cut
