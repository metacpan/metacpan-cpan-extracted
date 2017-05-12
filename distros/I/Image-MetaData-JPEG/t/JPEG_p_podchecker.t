BEGIN { my $root    = "lib/Image/MetaData";
	my $name    = "JPEG";
	@::docfiles = map { "$root/$_" } ( "$name.pod",
					   "$name/Structures.pod",
					   "$name/TagLists.pod",
					   "$name/MakerNotes.pod"); }

use Test::More;

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    plan skip_all => "test only run during release process";
  }
  my $Available = eval { require Pod::Checker; 1 };
	if (! $Available) {
	  plan skip_all => 'Pod::Checker unavailable';
	}

  plan tests => 0+@::docfiles;
}

BEGIN { require 't/test_setup.pl'; }

my $itsme = exists $ENV{USER} && $ENV{USER} eq 'bettelli';

#=======================================
diag "Checking documentation syntax with Pod::Checker";
#=======================================

for my $filename (@docfiles) {
    # this is the real test in this script
    my $syntax_problems =
	Pod::Checker::podchecker($filename, \*STDERR, -warnings => 10);
    is( $syntax_problems, 0, "Checking $filename" );
    # this is executed only at my site 
    if ($itsme) {
	# this only print the index for each pod
	my %c; open FH, $filename;
	while (<FH>) { next unless /=head(.)\s(.*)$/;
		       ++$c{$1}; @c{1+$1..100} = ();
		       printf "%*s %s\n", 5*$1, join(".",@c{1..$1}), $2; }
	# this creates search.cpan.org-like documentation
	next unless grep {/html/} @ARGV;
	eval { require Pod::HtmlEasy } || die "Pod::HtmlEasy is missing!\n";
	my $targetdir  = "$ENV{PWD}/html";
	my $targetfile = "$targetdir/$filename.html";
	my $modulename = 'Image::MetaData::JPEG';
	my $p = -1; while (-1 != ($p = index $targetfile, "/", 1+$p)) {
	    my $path = substr($targetfile, 0, $p); -d $path || mkdir $path; }
	print "Creating $targetfile\n";
	Pod::HtmlEasy->new( on_L => sub {
	    my ($this, $page) = @_; $page =~ tr/\n/ /;
	    my ($text, $section) = ('', '');
	    $page =~ /^(.*)\|(.*)$/ && ($text    = $1, $page = $2);
	    $page =~ /^(.*)\/(.*)$/ && ($section = $2, $page = $1);
	    $text = $section || $page unless $text;
	    $section = "#$section" if $section; $section =~ s/[ :\"\(\)\.]/-/g;
	    my ($init, $end) = ("<i><a href='", "$section'>$text</a></i>");
	    ($page =~ /$modulename/ || ! $page) || 
		return "${init}http://search.cpan.org/perldoc?$page${end}";
	    $page =~ s/::/\//g; $page = "lib/$page.pod";
	    $page = $filename if $page eq "lib/.pod";
	    return "${init}file://$targetdir/$page.html${end}";
	})->pod2html($filename, $targetfile, index_item => 1,
		top => "from <font color='#CC0000'><h1>$filename</h1></font>");
    }
}

#cover -delete
#HARNESS_PERL_SWITCHES=-MDevel::Cover DEVEL_COVER_OPTIONS=+ignore,/usr/,-coverage,statement,branch,condition,subroutine make test
#cover

### Local Variables: ***
### mode:perl ***
### End: ***
