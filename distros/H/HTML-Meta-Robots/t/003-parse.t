## no critic (RequireVersion RequireExplicitPackage ProhibitLongChainsOfMethodCalls)
############################################################################
# A simple HTML meta tag "robots" generator.
# @copyright © 2013, BURNERSK. Some rights reserved.
# @license http://www.perlfoundation.org/artistic_license_2_0 Artistic License 2.0
# @author BURNERSK <burnersk@cpan.org>
############################################################################
# Perl pragmas.
use strict;
use warnings FATAL => 'all';
use utf8;

############################################################################
# Get use of modules.
use Test::More tests => 4;
use Test::NoWarnings;
use HTML::Meta::Robots;

############################################################################
# parse() behaviour.
{
  is_deeply(
    HTML::Meta::Robots->new->index(0)->follow(1)->archive(1)->odp(1)->ydir(1)->snippet(1),
    HTML::Meta::Robots->new->parse('noindex,follow,archive,odp,ydir,snippet'),
    'parse() deny index but allow others'
  );
  is_deeply(
    HTML::Meta::Robots->new->index(1)->follow(0)->archive(1)->odp(1)->ydir(1)->snippet(1),
    HTML::Meta::Robots->new->parse('index,nofollow,archive,odp,ydir,snippet'),
    'parse() deny follow but allow others'
  );
  my $parse3ref =
    HTML::Meta::Robots->new->index(1)->follow(0)->archive(1)->odp(1)->ydir(1)->snippet(1);
  $parse3ref->{unknown_props} = { unknown => 1 };
  my $parse3 =
    HTML::Meta::Robots->new->parse('index,nofollow,archive,odp,ydir,snippet,unknown');
  is_deeply(
    $parse3ref,
    $parse3,
    'parse() deny follow but allow others'
  );
}

############################################################################
1;
