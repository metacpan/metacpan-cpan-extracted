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

use Template;
use Devel::ModInfo;

use Getopt::Std;
use Pod::Usage;
use IO::File;
use File::Spec::Functions 'canonpath';
use File::Find;
use File::Path;
use File::Basename 'dirname';
use FindBin;

my $curr_inc_dir;
my @file_list;
my %class2file;
my @dirs_to_make;
my %opts;
getopts('d:fhi:m:rt:x:', \%opts);

if ($opts{h}) {pod2usage(-verbose => 2)}
if (!$opts{m} && !$opts{r}) {pod2usage(-verbose => 2, -message => "Must provide a module name using -m package or specify recurse using -r")}

my $base_dir = canonpath($opts{d});
$base_dir ||= "./";

use constant DOC_TPL => 'modinfo2html.tt';
use constant IDX_TPL => 'modinfo2html_idx.tt';

if ($opts{r}) {
	foreach my $inc_dir ('.') {
		$curr_inc_dir = $inc_dir;
		find(\&proc_file, $inc_dir);
	}
	foreach my $dir_path (@dirs_to_make) {
		mkpath($dir_path, 1);
	}
	foreach my $file_path (@file_list) {
		process_to_file($file_path);
	}
        if ($opts{i}) {
              	my $output = new IO::File(">$base_dir/$opts{i}") 
                   or warn "Couldn't open $base_dir/$opts{i} for output: $!";
	        if ($output->error) {warn $!}
	        else  {
                   my $title = $opts{t} || "Interface Documentation";
                   @classes = sort(keys %class2file);
                   generate_index(
                       \@classes, 
                       $title,
                       $output,
                   );
                }
        }
}
else {
	my $base_class = $opts{m};
	if ($opts{f}) {
		process_to_file($base_class);
	}
	else {
		process($base_class, \*STDOUT);
	}
}

sub proc_file {
	my $file_path = $File::Find::name;
	return if $file_path !~ /\.mfo$/;
        if ($opts{x}) {
           return if $file_path =~ /\Q$opts{x}\E/;
        }
	$file_path =~ s|\Q$curr_inc_dir/\E||;
	print "File path is $file_path\n";
	$dir_path = canonpath($base_dir . '/' . dirname($file_path));
	print "Dir path is $dir_path\n";
	push(@dirs_to_make, $dir_path);

	$file_path =~ s|[\\/]|::|g;
	$file_path =~ s|\.mfo$||;
	push(@file_list, $file_path);
}

sub process_to_file {
	my ($base_class) = @_;
	my $file_name = $base_class;
	$file_name =~ s|::|/|g;
	my $output = new IO::File(">$base_dir/${file_name}.html") or warn "Couldn't open $base_dir/${file_name}.html for output: $!";
	if ($output->error) {warn $!}
	else {
           if ($opts{i}) {$class2file{$base_class} = "$base_dir/${file_name}.html"}
           process($base_class, $output)
        }
}

sub process {
	my ($class, $output) = @_;

	my $modinfo = new Devel::ModInfo($class);
	
        return if !$modinfo;

	my $config = {
	    INCLUDE_PATH => ['.', $FindBin::Bin],  # or list ref
	    INTERPOLATE  => 1,               # expand "$var" in plain text
	    POST_CHOMP   => 1,               # cleanup whitespace
	    EVAL_PERL    => 1,               # evaluate Perl code blocks
	};
	
	# create Template object
	my $template = Template->new($config);
	
	# define template variables for replacement
	my $vars = {
		modinfo => $modinfo,
	};
	
	# process input template, substituting variables
	$template->process(DOC_TPL, $vars, $output) || die $template->error();
}

sub generate_index {
       	my ($classes, $title, $output) = @_;

	my $config = {
	    INCLUDE_PATH => ['.', $FindBin::Bin],  # or list ref
	    INTERPOLATE  => 1,               # expand "$var" in plain text
	    POST_CHOMP   => 1,               # cleanup whitespace
	    EVAL_PERL    => 1,               # evaluate Perl code blocks
	};
	
	# create Template object
	my $template = Template->new($config);
	
	# define template variables for replacement
	my $vars = {
                title => $title,
		class2file => \%class2file,
                classes => $classes,
	};
	
	# process input template, substituting variables
	$template->process(IDX_TPL, $vars, $output) || die $template->error();
}

__END__

=head1 modinfo2html

modinfo2html: convert modinfo into an HTML file or tree of HTML files

=head2 SYNOPSIS

modinfo2html -m MyModule

or

modinfo2html -fd /home/jtillman/html-docs/ -m MyModule

or

modinfo2html -ri index.html -d /home/jtillman/html-docs/

=head2 OPTIONS

=over 4

=item -h	   Display help

=item -m package   Name of the Perl module package to convert
			(If this is the only option provided, output will
			go to STDOUT)

=item -f           Output to a file of the same name as the module, but 
			with an html extension, instead of using STDOUT

=item -r	   Recurse through the entire directory structure, 
			looking for ModInfo files, and convert each one
			This will build a directory structure mimicking
			that of the module path being recursed if -d is 
			provided.

=item -i file_name When provided in conjunction with -r (recurse), this 
                        will cause an index to be created with links to 
                        all the created documentation files

=item -t title     When provided with -i, this is the title to give the index

=item -d dir_path  Directory to place converted files in
                        (If provided, files will be used instead of writing
                     	to STDOUT)

=item -x regex     If provided, "regex" is a regular expression that each 
                        path is compared to before processing.  If it matches 
                        the file is skipped

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
