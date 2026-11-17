use v5.16;
use warnings;
use Test::More 0.98;
use File::Temp qw(tempdir);
use File::Spec;

# IO::Factotum::Highlight::sky and ::gnu are the short names of
# IO::Factotum::Highlight::skylighting and ::sourcehighlight

my $dir = tempdir(CLEANUP => 1);
my $lib = File::Spec->rel2abs('lib');
my $file = "$dir/a.c";
{
    open my $fh, '>', $file or die;
    print $fh "int x = 1;\n";
    close $fh;
}

my %command = (sky => 'skylighting', gnu => 'source-highlight');
my %module  = (sky => 'skylighting', gnu => 'sourcehighlight');

for my $name (qw(sky gnu)) {
  SKIP: {
	skip "$command{$name} is not installed", 4
	    unless grep { -x "$_/$command{$name}" } File::Spec->path;

	# load registers the converter, and does not tie ARGV
	my $script = "$dir/$name.pl";
	open my $fh, '>', $script or die;
	print $fh <<"END";
use IO::Factotum;
IO::Factotum::load('Highlight::$name');
print tied(*ARGV) ? "tied\\n" : "not tied\\n";
print IO::Factotum::open_input(shift)->getlines;
END
	close $fh;
	my $out = qx{$^X -I"$lib" "$script" "$file" 2>&1};
	like $out, qr/\Anot tied\n/, "$name: load does not tie ARGV";
	like $out, qr/\e\[/, "$name: load gives colors";

	# the same output as the module of the full name
	(my $full = $script) =~ s/\.pl$/-full.pl/;
	open $fh, '>', $full or die;
	print $fh <<"END";
use IO::Factotum;
IO::Factotum::load('Highlight::$module{$name}');
print "not tied\\n";
print IO::Factotum::open_input(shift)->getlines;
END
	close $fh;
	is $out, scalar qx{$^X -I"$lib" "$full" "$file" 2>&1},
	    "$name: the same as $module{$name}";

	# -M ties ARGV
	$out = qx{$^X -I"$lib" -MIO::Factotum::Highlight::$name -ne 'print "\$ARGV: \$_"' "$file" 2>&1};
	like $out, qr/^\Q$file\E: .*\e\[/, "$name: -M reads the colored text by <>";
    }
}

done_testing;
