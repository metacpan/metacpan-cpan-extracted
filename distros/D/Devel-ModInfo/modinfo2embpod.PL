use Config;
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($Config{'osname'} eq 'VMS' or
	    $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
#!$^X -w

!GROK!THIS!

foreach my $dir (@INC) {
    print OUT qq{use lib '$dir';\n};
}

print OUT <<'!NO!SUBS!';

$| = 1;

use Template;
use Devel::ModInfo;
use Devel::ModInfo::Util;

use Getopt::Std;
use Pod::Usage;
use IO::File;
use File::Spec::Functions 'canonpath';
use File::Find;
use File::Path;
use File::Copy 'cp';
use File::Basename 'dirname';
use FindBin;

my $curr_inc_dir;
my @file_list;
my @dirs_to_make;
my %opts;
getopts('hrfm:d:', \%opts);

if ($opts{h}) {pod2usage(-verbose => 2)}
if (!$opts{m} && !$opts{r}) {pod2usage(-verbose=> 2, -message => "Must provide a module name using -m package or specify recurse using -r")}

my $base_dir = canonpath($opts{d});
$base_dir ||= "./";

use constant INPUT => 'modinfo2embpod.tt';

if ($opts{r}) {
	foreach my $inc_dir ('.') {
		$curr_inc_dir = $inc_dir;
		find(\&proc_file, $inc_dir);
	}
	foreach my $file_path (@file_list) {
		process($file_path);
	}
}
else {
	my $base_class = $opts{m};
	process($base_class);
}

print STDERR "Finished\n";

sub proc_file {
	my $file_path = $File::Find::name;
	return if $file_path !~ /\.mfo$/;
	$file_path =~ s|\Q$curr_inc_dir/\E||;
	print "File path is $file_path\n";
	$dir_path = canonpath($base_dir . '/' . dirname($file_path));
	print "Dir path is $dir_path\n";
	push(@dirs_to_make, $dir_path);

	$file_path =~ s|[\\/]|::|g;
	$file_path =~ s|\.mfo$||;
	push(@file_list, $file_path);
}

sub process {
	my ($class, $output) = @_;

	my $modinfo = new Devel::ModInfo($class);
	my $pm_path = $class;
	$pm_path =~ s|::|/|;
	$pm_path .= '.pm';
	$pm_path = findINC($pm_path);
        return if ! -f $pm_path;
	print STDERR "File path is $pm_path.\n";

	my $pm_file_in = new IO::File($pm_path);
	my $pm_file_out = new IO::File('>' . $pm_path . '.out');
	
	my $config = {
	    INCLUDE_PATH => ['.', $FindBin::Bin],  # or list ref
	    INTERPOLATE  => 1,               # expand "$var" in plain text
	    #POST_CHOMP   => 1,               # cleanup whitespace
	    EVAL_PERL    => 1,               # evaluate Perl code blocks
	};
	
	# create Template object
	my $template = Template->new($config);
	
	# define template variables for replacement
	my $vars = {
		modinfo => $modinfo,
	};
	
	# process input template, substituting variables
	while(my $line = <$pm_file_in>) {
		print $pm_file_out $line;
		last if $line =~ /^=head1 INTERFACE/;
	}
	
        print STDERR "Processing template\n";

	$template->process(INPUT, $vars, $pm_file_out) || die "An error occurred: $! - " . $template->error();
	
	my $end_found = 0;
	while(my $line = <$pm_file_in>) {
		$end_found = 1 if $line =~ /^=head1/;
		print $pm_file_out $line if $end_found;
	}

	$pm_file_in->close();
        $pm_file_out->close();

        print STDERR "Renaming ${pm_path} to ${pm_path}.bak\n";
	rename($pm_path, "${pm_path}.bak");
	rename("${pm_path}.out", $pm_path);
	unlink("${pm_path}.out");

}

sub findINC {
	my $file = join('/',@_);
	my $dir;
	$file  =~ s,::,/,g;
	foreach $dir (@INC) {
		my $path;
		return $path if (-e ($path = "$dir/$file"));
	}
	return undef;
}
__END__

=head1 modinfo2embperl.pl

modinfo2embperl.pl: convert modinfo directives into POD and embed it in a specially
marked location in the pm file.

=head2 SYNOPSIS

perl modinfo2embperl.pl -m MyModule

or

perl modinfo2html.pl -d /home/jtillman/html-docs/ -m MyModule

=head2 EMBEDDING DIRECTIVE

See the documentation for ModInfo to learn how to document your module with ModInfo 
directives.  In order to tell modinfo2embperl where to embed the POD it creates, 
simply put this in your POD:

	=head1 INTERFACE

And then make sure that the next thing in your pod is another =head1

modinfo2embperl will insert the generated POD between these two markers in your code.  
Make sure that the = sign is the first character on the line, just as in true POD.

Subsequent runs of the processor will overwrite anything inside these two markers, so 
don't bother editing the POD by hand.

=head2 OPTIONS

=over 4

=item -h		   Display help

=item -m package   Name of the Perl module package to convert
					(If this is the only option provided, output will
						go to STDOUT)

=item -r		   Recurse through the entire directory structure, 
					looking for .pm files, and process each one

=back

=head1 AUTHOR

jtillman@bigfoot.com

tcushard@bigfoot.com

=head1 SEE ALSO

ModInfo

Devel::ModInfo::Tutorial

pl2modinfo.pl

modinfo2xml.pl

perl(1)

!NO!SUBS!
