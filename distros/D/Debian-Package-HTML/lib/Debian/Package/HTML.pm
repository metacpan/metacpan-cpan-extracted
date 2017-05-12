#!/usr/bin/perl

# debian-package-html -> generates HTML output for Debian packages and sources
# originally written by Jose Parrella <joseparrella@cantv.net>
# this program is free for anyone to use it and modify it

package Debian::Package::HTML;
$VERSION = "0.1";

use strict;
use warnings;

use HTML::Template;

# Constructor
sub new {
	my ($class, @args) = @_;

	# Bless my anonymous hash, please
	my $object = bless {}, $class;

	# Default null values
	%$object = (
		"binary"		=>	"",
		"control"		=>	"",
		"source"		=>	"",
		"diff"			=>	"",
		"changes"		=>	""
	);

	# Get input from the constructor
        while (@args) {
                $object->{$args[0]} = $args[1] if defined($args[1]);
                shift @args; shift @args;
        }

	die "At least a DSC file is needed!\n" unless defined($object->{control});

	return $object;
}

# Main execution
sub output {
	my ($object, @args) = @_;

	# Context default values
	my %context = (
                "briefing"              =>      "0",
                "charset"               =>      "ISO-8859-1",
                "resultTemplate"        =>      "result.tmpl",
                "pageStyle"             =>      "",
                "doChecks"              =>      "0",
		"dump"			=>	"index.html"
        );

        # Get input from the constructor
        while (@args) {
                $context{$args[0]} = $args[1] if defined($args[1]);
                shift @args; shift @args;
        }

	my ($packageName, $packageVersion, $maintainerName, $maintainerMail);

	my @packageVars = parseControl ($object);

	if ($context{doChecks}) {
			system("linda -v -i $object->{control} > $packageVars[0]-checks.txt");
			system("lintian -v -i $object->{control} >> $packageVars[0]-checks.txt");
	}

	doTheOutput ($object, @packageVars, %context);
}

# parseControl: Parses control file
sub parseControl {
	my $packageFiles = shift;
	my ($packageName, $packageVersion, $maintainerName, $maintainerMail);
	die "Couldn't FIND a proper DSC file\n" unless defined($packageFiles->{"control"});
	open (CONTROL, $packageFiles->{"control"}) or die "Couldn't OPEN a proper DSC file\n";

	while (<CONTROL>) {
		chomp;
		$packageName = $1 if ($_ =~ /^Source: ([\w-]+)/);
		$packageVersion = $1 if ($_ =~ /^Version: (.*)/ && !defined($packageVersion));
		$maintainerName = $1 if ( ($_ =~ /^Maintainer: ([\w ]+) .*/) && !defined($maintainerName) );
		$maintainerMail = $1 if ( ($_ =~ /^Maintainer: [\w ]+ \<(.+)\>/) && !defined($maintainerMail) );
	}

	close CONTROL;
	return ($packageName, $packageVersion, $maintainerName, $maintainerMail);
}

# doTheOutput: Outputs HTML
sub doTheOutput {
	my($packageFiles, $packageName, $packageVersion, $maintainerName, $maintainerMail, %context) = @_;

	# Call to the constructor method on $resultTemplate
	my $template = HTML::Template->new(filename => $context{resultTemplate});

	my $currentDate = `date +%c`;
	chomp $currentDate;

	my $maintainerPlus = maintainerInfo($maintainerName);

	sub maintainerInfo {
		my $maintainerName = @_;
		my @maintainerParts = split(" ", $maintainerName);
		return join("+", @maintainerParts);
	}

	my @packagef;

	for (keys(%$packageFiles)) {
		push @packagef,
		{ packagefile => $packageFiles->{$_} }
		if (defined($packageFiles->{$_}) && $packageFiles->{$_} ne "");
	};

	$template->param(
	        		packageName	=>	$packageName,
				packageVersion	=>	$packageVersion,
				maintainerName	=>	$maintainerName,
				maintainerMail	=>	$maintainerMail,
				maintainerPlus	=>	$maintainerPlus,
				pageCharset	=>	$context{pageCharset},
				pageStyle	=>	$context{pageStyle},
				packagef	=>	\@packagef,
				date		=>	$currentDate,
				doChecks	=>	$context{doChecks},
				briefing	=>	$context{briefing}
	);

	if (defined($context{dump}) && $context{dump} ne "") {
		no warnings;
		local *DUMPIT;
		open (DUMPIT, ">", "$context{dump}") or die "Couldn't open $context{dump} for write.\n";
		print $template->output(print_to => *DUMPIT);
		close DUMPIT;
	}
	else {
		die "Weird argument in context's dump option. No output will be produced\n";
	}
}

1;

# Documentation

=head1 Debian::Package::HTML

Debian::Package::HTML - Generates a webpage information (and Linda/Lintian checks) about a Debian binary or source package using HTML::Template

=head1 SYNOPSIS

  use strict;
  use Debian::Package::HTML;
  my $package = Debian::Package::HTML->new(%packageHash);
  $package->output(%contextHash);

=head1 REQUIRES

HTML::Template

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

This module outputs a webpage using HTML::Template templates which
resumes the information of a normal build environment for a package
in Debian (source files, binary packages and changelogs) using 
Linda/Lintian for sanity checks. It is useful for making unified presentation
webpages for those packages which are being sponsorized by someone in Debian.

=head1 METHODS

=head2 Constructor

=over 4

=item * $object->new(%packageHash)

Constructs an $object with all information concerning the 
package, including location for binary/source files, changelogs, 
diffs, pristine sources, as well as templates, charsets and other
settings.

Possible elements for the hash are:

"binary", "control", "source", "diff", "changes", each one of 
them specifying one of the five possible files generated by a 
package building process in Debian.

"control" is mandatory.

=back

=head2 Output

=over 4

=item * $object->output(%contextHash)

Does the actual XHTML output. Possible elements for the hash are:

"briefing" (boolean): if TRUE, WebInfo will look for a briefing.html 
in the current directory, and will include the content in the resulting 
output. Useful for introducing commentaries without touching the final 
HTML. Defaults to FALSE.

"charset": determines the output charset. Defaults to "ISO-8859-1".

"resultTemplate": specifies the location of an HTML::Template style 
template for output. This is mandatory, and defaults to "result.tmpl"

"pageStyle": specifies the location of a CSS file which might be
included.

"doChecks" (boolean): if TRUE, WebInfo will run linda and lintian over 
the control file and will generate a ${packageName}-checks.txt file which 
will be included in the final output. Defaults to FALSE.

"dump": determines where to put the resulting HTML output. Defaults to
index.html

=head1 DIAGNOSTICS

=head2 No DSC could be found/open

You need to specify a DSC control file using the "control" parameter for the
new() method. If you don't, WebInfo can't do much. The package will inform if 
the file could not be FOUND or could not be OPEN.

Please report the bugs, I'd love to work on them.

=head1 CUSTOMIZATION

=head2 Template customization

You can customize the final output using your own HTML::Template template
file and specifying it as a parameter for the output() method. The following 
template variable names are honored by WebInfo:

packageName: the name of the package

packageVersion: the version of the package

maintainerName: the name of the maintainer

maintainerMail: the e-mail address of the maintainer

maintainerPlus: a "+" separated name/surname for the maintainer (useful for 
URL searching)

pageCharset: the page charset (customizable in the output() method)

pageStyle: the CSS file (customizable in the output() method)

packagef: the available package files as an array reference, so HTML::Template 
should iterate over the "packagefile" variable.

date: the date specified by the current locale

doChecks: a boolean variable specifying if Linda/Lintian checks were made

briefing: a boolean variable specifying if a briefing.html file should be included

=head2 Example template

An example template is in:
http://debian.bureado.com.ve/package-info/result.tmpl

HTML outputs with that template and no CSS look like:
http://debian.bureado.com.ve/falselogin/

=head1 EXAMPLES

=head2 Only a control file

  #!/usr/bin/perl

  use strict;
  use warnings;

  use Debian::Package::HTML;

  my $package = Debian::Package::HTML->new( "control" => "falselogin.dsc" );
  $package->output ( "resultTemplate" => "result.tmpl", "dump" => "index.html" );

=head2 A complete building environment

  #!/usr/bin/perl

  use strict;
  use warnings;

  use Debian::Package::HTML;

  my $package = Debian::Package::HTML->new("control" => "falselogin.dsc", 
  "binary" => "falselogin.deb",
  "diff" => "falselogin.diff.gz",
  "source" => "falselogin.orig.tar.gz",
  "changes" => "falselogin.changes"
  ;

  $package -> output ( "resultTemplate" => "anotherTemplate.tmpl",
  "style" => "groovy-style.css",
  "charset" => "UTF-8",
  "doChecks" => "1",
  "dump" => "firstPackage.html"
  );

=head2 Some ideas

Well, throw the files generated by your compilations (dpkg-buildpackage, i.e.)
in a /var/www/<my package> served by your webserver of choice and run a small
program using Debian::Package::HTML and a nice CSS/Template. You will have a great webpage 
for all your Debian packages, really useful if you're not yet a Developer and need 
to handle several packages with your sponsors.

=head1 AUTHOR

Jose Parrella (joseparrella@cantv.net) wrote the original code, then modularized and OOed the code.

Thanks go to Christian Sánchez (csanchez@unplug.org.ve) who helped with the original HTML::Template'ing

=head1 COPYRIGHT

Copyright 2006 Jose Parrella. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), HTML::Template.

=cut
