## no critic (RequireVersion RequireExplicitPackage)
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
use Test::More tests => 18;
use Test::NoWarnings;
use HTML::Meta::Robots;

############################################################################
# Default behaviour.
{
  my $robots;
  isa_ok(
    $robots = HTML::Meta::Robots->new, 'HTML::Meta::Robots',
    'Default instance'
  );
  is(
    $robots->content,
    'index,follow,archive,odp,ydir,snippet',
    'Default robots content'
  );
  is(
    $robots->meta,
    '<meta name="robots" content="index,follow,archive,odp,ydir,snippet"/>',
    'Default XHTML meta tag'
  );
  is(
    $robots->meta(1),
    '<meta name="robots" content="index,follow,archive,odp,ydir,snippet">',
    'Default HTMLv4 meta tag'
  );
}

############################################################################
# index() have a special behaviour - set all flags to allow/deny.
{
  my $robots = HTML::Meta::Robots->new;
  is(
    $robots->index(0)->content,
    'noindex,nofollow,noarchive,noodp,noydir,nosnippet',
    'index(0) robots content'
  );
  is(
    $robots->index(1)->content,
    'index,follow,archive,odp,ydir,snippet',
    'index(1) robots content'
  );
  is(
    $robots->index(0)->follow(1)->content,
    'noindex,follow,noarchive,noodp,noydir,nosnippet',
    'index(0)->follow(1) robots content'
  );
}

############################################################################
# follow() behaviour.
{
  my $robots = HTML::Meta::Robots->new;
  is(
    $robots->follow(0)->content,
    'index,nofollow,archive,odp,ydir,snippet',
    'follow(0) robots content'
  );
  is(
    $robots->follow(1)->content,
    'index,follow,archive,odp,ydir,snippet',
    'follow(1) robots content'
  );
}

############################################################################
# archive() behaviour.
{
  my $robots = HTML::Meta::Robots->new;
  is(
    $robots->archive(0)->content,
    'index,follow,noarchive,odp,ydir,snippet',
    'archive(0) robots content'
  );
  is(
    $robots->archive(1)->content,
    'index,follow,archive,odp,ydir,snippet',
    'archive(1) robots content'
  );
}

############################################################################
# open_directory_project() behaviour.
{
  my $robots = HTML::Meta::Robots->new;
  is(
    $robots->odp(0)->content,
    'index,follow,archive,noodp,ydir,snippet',
    'odp(0) robots content'
  );
  is(
    $robots->odp(1)->content,
    'index,follow,archive,odp,ydir,snippet',
    'odp(1) robots content'
  );
}

############################################################################
# yahoo() behaviour.
{
  my $robots = HTML::Meta::Robots->new;
  is(
    $robots->ydir(0)->content,
    'index,follow,archive,odp,noydir,snippet',
    'ydir(0) robots content'
  );
  is(
    $robots->ydir(1)->content,
    'index,follow,archive,odp,ydir,snippet',
    'ydir(1) robots content'
  );
}

############################################################################
# snippet() behaviour.
{
  my $robots = HTML::Meta::Robots->new;
  is(
    $robots->snippet(0)->content,
    'index,follow,archive,odp,ydir,nosnippet',
    'snippet(0) robots content'
  );
  is(
    $robots->snippet(1)->content,
    'index,follow,archive,odp,ydir,snippet',
    'snippet(1) robots content'
  );
}

############################################################################
1;
