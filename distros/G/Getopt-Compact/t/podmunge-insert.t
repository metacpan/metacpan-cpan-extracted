#!/usr/bin/perl
# test PodMunger insert()

use strict;
use lib qw(../lib lib);
use Test::More;
use File::Spec;

use constant DEFAULT_POD => 'pod1.pod';

my @testdata = 
    # test usage is inserted in correct position
    (['USAGE', 'foo', [qw/NAME SYNOPSIS USAGE DESCRIPTION AUTHOR/]],
     # test unknown sections are inserted at the end
     ['FOOBAR', 'blah', [qw/NAME SYNOPSIS DESCRIPTION AUTHOR FOOBAR/]],
     # test sections aren't clobbered
     ['DESCRIPTION', 'baz', [qw/NAME SYNOPSIS DESCRIPTION AUTHOR/]],
     # test undefined content isn't added
     ['NOTES', undef, [qw/NAME SYNOPSIS DESCRIPTION AUTHOR/]],
     # test verbatim sections
     ['USAGE', 'foo', [qw/NAME SYNOPSIS USAGE DESCRIPTION AUTHOR/], 1],
     # test inserting sections when leading sections are missing
     ['USAGE', 'foo', [qw/USAGE DESCRIPTION AUTHOR/], 0, 'pod2.pod'],
     );
my $p;

plan tests => 3 + scalar(@testdata);

eval {
    require Getopt::Compact::PodMunger;
    $p = new Getopt::Compact::PodMunger();
};
ok($p, "Instantiated Getopt::Compact::PodMunger()");
diag($@) if $@;

SKIP: {
    skip $@, scalar(@testdata) if $@;

    chdir('t') if -d 't';
    for my $t (@testdata) {
	my($sectname, $content, $expected, $verbatim, $file) = @$t;
	$p->parse_from_file(File::Spec->catfile('data', $file || DEFAULT_POD));
	$p->insert($sectname, $content, $verbatim);
	my $pod = $p->as_string;
	my @sections = find_sections($pod);
	is_deeply(\@sections, $t->[2], 
		  "insert $t->[0]: returned correct sections");
	if($verbatim) {
	    # check that content has been indented
	    my $c = section_content($pod, $sectname);
	    ok(defined $c && $c !~ /^\S/m, "content has been indented");
	}
    }

    # test inserting sections into empty pod
    $p = new Getopt::Compact::PodMunger();
    $p->insert("SYNOPSIS", 'abc');
    $p->insert("NAME", 'def');
    $p->insert("DESCRIPTION", 'ghi');
    is_deeply([find_sections($p->as_string)], [qw/NAME SYNOPSIS DESCRIPTION/],
	      "inserting sections into empty pod");
}

sub find_sections {
    my $pod = shift;
    my(@sects) = $pod =~ /^=head1\s+(.*?)$/mg;
    return @sects;
}
sub section_content {
    my($pod, $section) = @_;
    my($content) = $pod =~ /=head1\s+$section(.*?)(=head1|\$)/s;
    return $content;
}
