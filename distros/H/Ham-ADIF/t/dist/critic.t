# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-12-17 11:12:34 +0000 (Mon, 17 Dec 2012) $
# Id:            $Id: 00-critic.t 15 2012-12-17 11:12:34Z rmp $
# $HeadURL$
#
package critic;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 15 $ =~ /\d+/smxg); sprintf '%d.'.'%03d' x $#r, @r };

if ( not $ENV{TEST_AUTHOR} ) {
  my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
  plan( skip_all => $msg );
}

eval {
  require Test::Perl::Critic;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Perl::Critic not installed';

} else {
  Test::Perl::Critic->import(
			     -severity => 3,
			     -exclude  => [qw(CodeLayout::RequireTidyCode
					      NamingConventions::Capitalization
					      PodSpelling
					      ValuesAndExpressions::RequireConstantVersion)],
			    );
  all_critic_ok(qw(lib scripts bin));
}

1;
