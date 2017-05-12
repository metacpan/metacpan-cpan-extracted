use ExtUtils::MakeMaker;

use strict;
use Config;

my %extras;

eval { local $SIG{'__WARN__'}; require Test::More };
if ($@)
{
    print "Test::More is not installed: All tests will be skipped\n";
    # XXX Why can't I reset this to not do any tests?
    $extras{test} = {TESTS => undef};
}

# Check that the current GD has TTF support, and that it works.
eval
{
    local $SIG{'__WARN__'};
    require GD;
    require File::Spec;
    require Cwd;

    GD::Image->can('stringTTF') 
	or die "One";
    GD::Image->stringTTF(0, 'foo', 10, 0, 0, 0, 'foo');
    $@ =~ /TrueType font support/i 
     	and die "Two";
    my $test_font = File::Spec->catfile(Cwd::cwd(), "Dustismo_Sans.ttf");
    GD::Image->stringTTF(0, $test_font, 10, 0, 0, 0, 'foo')
	or die "Three: $@";
};
if ($@ && $@ =~ /^Three/)
{
    # We seem to have one of those rare GD installations that claims it
    # can do TTF, but that fails when we try.
    warn <<EOW;

Your GD installation claims to support TTF fonts, but it fails to load
the included test font. The module tests will also fail because of this.
If you are certain that you have correct TTF support in your GD module,
please contact the author of this module with as much information you
can provide about your installation.

Continuing...

EOW
}


WriteMakefile(
    'DISTNAME'		=> 'GDTextUtil',
    'NAME'		=> 'GD::Text',
    'VERSION_FROM' 	=> 'Text.pm',
    'PREREQ_PM'		=> { 'GD' => 1 },
	($] >= 5.005 ? (
	     'ABSTRACT'     => 'text utilities for GD',
	     'AUTHOR'       => 'Martien Verbruggen (mgjv@comdyn.com.au)',
	    ):()
	),
    clean			=> {FILES => "GDWrap.png"},
    %extras,
);

sub MY::postamble
{
qq(
.PHONY: demo
demo: pure_all GDWrap.png
GDWrap.png: demo/GDWrap.pl
	\@$Config{'perlpath'} -Mblib demo/GDWrap.pl demo/GDWrap.png
)
}

# $Id: Makefile.PL,v 1.14 2003/06/19 00:57:44 mgjv Exp $
