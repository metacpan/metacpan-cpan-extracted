# 00-load-tt.t - Very basic testing of our classes. Test their ability to
# be use()d, and its POD documentation.

# $Id: 00-load-tt.t,v 1.1 2005/11/03 13:51:04 lem Exp $

use Test::More;

my @modules = qw/
  Template::Plugin::Abuse
	/;

plan tests => scalar @modules;

SKIP: {
    eval { require Template::Plugin };
    skip 'Template::Toolkit is missing', scalar @modules
	if $@;
    use_ok($_) for @modules;
};

__END__

$Log: 00-load-tt.t,v $
Revision 1.1  2005/11/03 13:51:04  lem
Added test to conditionally test the TT plugins


