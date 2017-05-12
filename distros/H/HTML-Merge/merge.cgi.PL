##################################
# merge.pl - merge main script 	 #
# written by: Roi Illouz	 #
# Updated: Ariel Brush		 #
##################################
use strict;
my $code = <<'ENDOFPERLCODE';
# Modules ########################

use lib qw(private/perl);
use CGI qw/:standard/;
use strict qw(subs vars);

# My modules #####################

use HTML::Merge::Compile;
use HTML::Merge::Error;
use HTML::Merge::Engine;
use HTML::Merge::Development;

# Globals ########################

use vars qw(%code $mod_perl);

##################################
BEGIN 
{
	my $stash = eval("*HTML::Merge::Ini::");

	unless (%$stash) 
	{
		print "Status: 501 Config file not found or incorrect\n";
		print "Content-type: text/plain\n\n";
		print "Merge could not find the configuration file.\n";
		exit;
	}

	if (exists $ENV{'GATEWAY_INTERFACE'} &&
		($ENV{'GATEWAY_INTERFACE'} =~ /^CGI-Perl\//)) 
	{
		$mod_perl = 1;
	}

}
# Main ###########################

my $content_type_param=param('content_type') || $HTML::Merge::Ini::CONTENT_TYPE;
my $content_type=$content_type_param ? $content_type_param : 'text/html';
my $input;              # the input template
my $output;             # the perl compiled output
my $candidate;
my $private;
my $path;

print "Content-type: $content_type\n\n" if $ENV{'REQUEST_METHOD'} && 
	uc($content_type) ne 'NONE';

if (param('__default__')) 
{
	my $sub = param("sub");
	my $fun = "Default$sub";
	my $code = UNIVERSAL::can('HTML::Merge::Development', $fun);

	if ($code) 
	{
		&$code;
		exit;
	}

	HTML::Merge::Development::DefaultError("Improper use of Merge internal");
	exit;
}

$HTML::Merge::context = [];

&HTML::Merge::Engine::ReadConfig;


my $template = param('template') || $HTML::Merge::Ini::DEF_TEMPLATE;

$HTML::Merge::template = $template;

unless ($mod_perl) 
{
	my $candidate = $ENV{'PATH_INFO'};
	# CAUTION - this can contain the session id
	if ($candidate && $candidate =~ /\./) 
	{
		$template = $candidate;
	}
}

if ($HTML::Merge::Ini::SESSION_METHOD eq 'U') 
{
	my $e = HTML::Merge::Engine->CreateObject;
	require HTML::Merge::Filter;
	require Symbol;
	my $sym = Symbol::gensym();
	untie *$sym if (tied(*$sym));
	tie *$sym, 'HTML::Merge::Filter', $e, select;
	select $sym;
}
 
if ($template) 
{
	if ($HTML::Merge::Ini::DB_DATABASE && $HTML::Merge::Ini::SESSION_DB
			&& $HTML::Merge::Ini::USE_SECURITY) 
	{
		my $signal = 'STOP';

		eval {
			my $engine = HTML::Merge::Engine->CreateObject;
			$HTML::Merge::context = [$template, 0];

			unless ($engine->CanEnter) 
			{
				$template = $HTML::Merge::Ini::SECURITY_ACCESS_DENIED_TEMPLATE;
				unless ($template) 
				{
					&HTML::Merge::Development::DefaultForbidden;
					die $signal;                    
				}
			}
		};
		exit if ($@ =~ /$signal/);
	}

	# put all posible paths in importents order for checking
	$input = HTML::Merge::Compile::GetTemplateFromPath($template);
	$output = "$HTML::Merge::Ini::CACHE_PATH/$template.pl";

	my $candidate = "$HTML::Merge::Ini::PRECOMPILED_PATH/$template.pl";
	if (-e $candidate) 
	{
		$output = $candidate;
		$input = [];
	}
}

# private_ convention is obsolete

my %candidates = ('log' => $HTML::Merge::Ini::MERGE_ERROR_LOG_PATH,
		  'error' => $HTML::Merge::Ini::MERGE_ERROR_PATH,
		  'toolbox' => $HTML::Merge::Ini::TOOLBOX_PATH);

if (undef) 
{
	while (($private, $path) = each %candidates) 
	{
		$candidate = param("private_$private");
		last if $candidate;
	}


	if ($candidate && ($HTML::Merge::Ini::DEVELOPMENT
		|| $private eq 'error')) 
	{
		if ($private eq 'toolbox' || $private eq 'log') 
		{
			HTML::Merge::Error::ForceError("private_$private deprecated");
			exit;
		}

		$template = $candidate;
		$input = "$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH/$path/$template";
		$output = "$HTML::Merge::Ini::CACHE_PATH/private/$private/$template.pl";
	}
}

# check for security britch
foreach (split/\//, $template) 
{
	if ($_ eq '..') 
	{
		HTML::Merge::Error::ForceError("Template name $template is invalid");
		exit; # Under mod_perl calls Apache::exit
		print "Status: 403 Permission denied\n";
		print "Content-type: text/plain\n\n";
		print "Template name $template is invalid\n";
		exit;
	}
}

&HTML::Merge::Compile::safecreate($output) unless -e $output;

# Force parameters to be extracted
my @keys = param;
foreach (@keys) 
{
	my $dummy = param($_);
}

unless (ref($input)) 
{
	unless (-f $input || !$input) 
	{
		HTML::Merge::Error::ForceError("$template not found");
		exit; # Under mod_perl calls Apache::exit
		print "Status: 404 File not found\n";
		print "Content-type: text/plain\n\n";
		print "$template not found\n";
		exit;
	}

	my $source = &date($input);
	my $dest = &date($output);

	$HTML::Merge::context = [$template, 0];

	if ($source > $dest || $HTML::Merge::Ini::ALWAYS_COMPILE) 
	{
		# Clear extensions in case we are under mod_perl

		foreach (keys %HTML::Merge::Ext) {
			undef &{"HTML::Merge::Ext::$_"};
		}

		&HTML::Merge::Engine::ReadConfig;
		eval {
			&HTML::Merge::Compile::CompileFile($input, $output);
		} if $input;

		if ($@) 
		{
			unlink $output;
			HTML::Merge::Error::ForceError("$template: $@");
			exit; # Under mod_perl calls Apache::exit
			print "Status: 501 Merge errors\n";
			print "Content-type: text/plain\n\n";
			print $@;
			exit;
		}
	}
}

if ($HTML::Merge::Ini::DEVELOPMENT && !$candidate && $input) 
{
	HTML::Merge::Error::OpenMergeErrorLog();
}

if ($candidate || param('__MERGE_DEV_LIVE__')) 
{
	$HTML::Merge::Ini::STOP_ON_ERROR = undef;
}

@HTML::Merge::cleanups = ();

# auto flush STDIN not used for preformance reason
#$| = 1;

if ($input) 
{
	if ($mod_perl) 
	{
		eval ' do $output; ';
	} 
	else 
	{
		eval ' require $output; ';
	}
} 
else 
{
	&HTML::Merge::Development::DefaultPage;
}

my $error = $@;

if ($@ && $@ !~ /STOP_ON_ERROR/) 
{
	eval 'HTML::Merge::Error::HandleError("ERROR", $error);';
}

foreach (@HTML::Merge::cleanups) 
{
	if (UNIVERSAL::isa($_, 'CODE')) 
	{
		eval '&$_';
	} 
	else 
	{
		eval $_;
	}
}

if ($HTML::Merge::Ini::DEVELOPMENT && !$candidate) 
{
	HTML::Merge::Error::CloseMergeErrorLog() if $input;

	unless (param('__MERGE_DEV_LIVE__') || $candidate || $error) 
	{
		my $re = $HTML::Merge::Ini::DEV_EXTENSION;
		$re =~ s/,\s*/|/g;

		if ($template =~ /\.($re)$/
				|| !$input) 
		{
			HTML::Merge::Development::OpenToolBox();
		}
	}
}

my $fh = select;
my $candidate = tied(*$fh); 
if ($candidate && UNIVERSAL::isa($candidate, 'HTML::Merge::Filter'))
{
	select $candidate->{'out'};
	$candidate->Close;
	untie *$fh;
}
# Functions #################################
sub date 
{
	my @s = stat(shift);
	$s[9];
}
############################################
ENDOFPERLCODE

use Config;
my $shebang = $Config{'startperl'};
$ARGV[0] = 'merge.cgi' unless $ARGV[0];
open(O, ">$ARGV[0]") || die $!;
print O "$shebang\n$code";
close(O);
chmod 0755, $ARGV[0];
