package HTML::Myasp;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw/send_page/;

require 5.005_62;
use strict;
use warnings;

our $VERSION = '0.05';

use Carp;
use Data::Dumper;

my %CACHE;
our $DEBUG = 0;

our %g_hparam;
our %g_hreplace;

#-----------------------------------------------------------------------------------------------
sub add_sub_entry {

%g_hparam = (%g_hparam, @_);

}

#-----------------------------------------------------------------------------------------------
# add an entry in the direct replace hash (the second)
sub add_replace_entry {

%g_hreplace = (%g_hreplace, @_);

}

#-----------------------------------------------------------------------------------------------
sub send_page {

	local $SIG{__DIE__} = \&Carp::confess;

	my ($file, $hparam, $hreplace) = @_;

	map {$hparam->{$_} = $g_hparam{$_} } keys %g_hparam;
	map {$hreplace->{$_} = $g_hreplace{$_} } keys %g_hreplace;

	print STDERR "Sub Routine reference hash is\n"	if $DEBUG;
	warn Dumper $hparam								if $DEBUG;
	print STDERR "Direct replacing hash\n"			if $DEBUG;
	warn Dumper $hreplace							if $DEBUG;

	my $tagprefix;

	my ($source, $string_text);
	if (length($file) > 128) {
		$source = 'string';
		$string_text = $file;
		$file = substr($file,0,255);
	} else {
		$source = 'file';
	}

	warn "Source is coming from a $source" if $DEBUG;

	if (exists $ENV{MOD_PERL}) {
		my $r = Apache->request();
		$file = $r->document_root() . "/$file";  # if mod_perl the document root is prefixed to the file path
		$tagprefix = $r->dir_config("TagPrefix") || 'myasp';
	} else {
		$tagprefix = 'myasp';
	}

	$tagprefix = $ENV{TagPrefix} if $ENV{TagPrefix}; # always environment variables can change behavior

	warn "TagPrefix is $tagprefix" if $DEBUG;

	my $mtime = $source eq 'file' ? (stat($file))[9] : time;

	my ($package,$filename,$line) = caller;
	my $caller_mtime = (stat($filename))[9];

	if (!$CACHE{$file} || $mtime > $CACHE{$file}->{load_time} || $caller_mtime > $CACHE{$file}->{caller_mtime}) {

		warn "File $file reloaded or loaded first time" if $DEBUG;

		if ($source eq 'file') {
			use IO::File;
			my $fh = new IO::File;
			unless ($fh->open("<$file")) {
				print "<p>Archivo no encontrado: $file</p>";
				return;
			}
			local $/ = undef;
			$CACHE{$file}->{f_text} = <$fh>;
			close $fh;
		} else {
			 $CACHE{$file}->{f_text} = $string_text;
		}

		$CACHE{$file}->{load_time} = time;
		$CACHE{$file}->{caller_mtime} = time;
			

		my ($last, @data);

		while ($CACHE{$file}->{f_text} =~ m#(.+?)<$tagprefix:(.+?)(\s.+?)?>(.*?)</$tagprefix:\2>#gs) {

			warn "$2 mark found" if $DEBUG;

			my %arr;
			if ($3) {
				my $aux = $3;
				$aux =~ s/^\s+//; $aux =~ s/\s+$//;

#				while (my ($key, $value) = $aux =~ /(\S+)=("[^"]"|\S+)/gs) {
#					$arr{$key} = $value;
#				}

				%arr = split /=|\s+/, $aux;

				foreach (keys %arr) {
					$arr{$_} =~ s/"//g;
				}
			}
			push @data, {-html => $1, -type=>'html'};
			push @data, {-name=>"-$2", -coderef => $hparam->{"\-$2"}, -type=>'cod', -param_ref => \%arr, -param_body => $4} if $hparam->{"\-$2"};

			$last = $';
		
		}
		if (@data) {
			push @data, {-html => $last, -type=>'html'};
		} else {
			push @data, {-html =>$CACHE{$file}->{f_text}, -type=>'html'};
		}

		$CACHE{$file}->{data} = \@data;

	} else {
		warn "Cache Hit file $file" if $DEBUG;
	}


	# the tags fields in the page are

	print STDERR "Begin parsed data file ***********\n" 	if $DEBUG;
	warn Dumper $CACHE{$file}								if $DEBUG;
	print STDERR "End parsed data file ***********\n" 		if $DEBUG;

	foreach my $x (@{$CACHE{$file}->{data}}) {
		if ($x->{-type} eq 'html') {
			next unless $x->{-html};
			my $temp = $x->{-html};
			print STDERR "Checking HTML replacing keywords\n" if $DEBUG;
			warn $temp								if $DEBUG;

			foreach my $key (keys %$hreplace) {
				warn "Checking key \"${key}\" and replacing with \"$hreplace->{$key}\"" if $DEBUG;
				
				if ($temp =~ s/\b${key}\b/$hreplace->{$key}/gis) {
					warn "String $key replaced" if $DEBUG;
				}
			}
			print $temp;
		} else {

			warn "Calling function $x->{-name}"											if $DEBUG;
			&Carp::cluck ("Stack de llamadas") 											if $DEBUG;
			print STDERR "The atributes of the tag are\n"								if $DEBUG;
			warn Dumper $x->{-param_ref}												if $DEBUG;
			print STDERR "*** Begin body between the marks is \n$x->{-param_body}\n"	if $DEBUG;
			print STDERR "*** End body between the marks\n"								if $DEBUG;

			unless (ref($hparam->{$x->{-name}})) {
				warn "Tag in template but not a handler subroutine defined: key $x->{-name}, template $file, called from $filename line $line";
				next;
			} else {
				&{$hparam->{$x->{-name}}}($x->{-param_ref}, $x->{-param_body});
			}
		}
	
	}

	1;

}




1;
__END__

=head1 NAME

HTML::Myasp - Generate HTML pages based on Templates. JATP (Just Another
Template Parser).

=head1 SYNOPSIS

Create a Template myfile.html

 <html>
 ....
 __user__
 
 __date__
 
 
 <table>
 <tr><td>id</td><td>name</td></tr>
 <xx:users>
 <tr><td>dummy id 1</td><td>dummy name 1</td></tr>
 <tr><td>dummy id 2</td><td>dummy name 2</td></tr>
 </xx:users>
 ..
 <xx:other_data> ...</xx:other_data>
 
 </html>

The httpd.conf file.

 PerlSetVar TagPrefix xx

 <Files *.html>
 
 	SetHandler perl-script
	
 	PerlHandler MyModule

 </Files>


MyModule.pm
 use HTML::Myasp;
 
 package MyModule;

 ...

 sub handler {
 
 my $r = shift;
 $r->send_http_header("text/html");
 
 send_page('myfile.html', 
 {
 	-users => \&list_users,
 	-other_data => sub { print "this is the other data";  ... }
 }, 
 {
 	__user__ => $sesion->current_user,
 	__date__ => localtime(time),
 });

 ...
 
=head1 DESCRIPTION

This library is another template module for the generation of HTML pages. Why ?. Well primarily i wanted a module: light, that keeps mod_perl power and flow control like HTML::Template, good interaction with external contents administrators, have the chance of using naturally the print statement for generating web content, but, for some situations have the chance of directly replace keywords in the template with values.  In some way this module centralizes the feature of a hash with values for replacing that you find in  HTML::Template and the XMLSubsMatch feature of Apache::ASP.

This module keeps the basic mod_perl flow, and permits the replacing with dynamic content using two forms of marking. Is very well suited for working in parallel with the designers team, living each group advance on its own.

HTML::Myasp export the send_page function by default, you can attach the dynamic content using:

=over

=item *

A callback style for special tags delimiting zones.

=item *

Direct replacing of keywords by values.

=back

In order to improve performance it uses a global pages CACHE hash, avoiding parsing files unless modified.

=head1 RECOMMENDED

 The recomended way to use this system is Design the page with a graphic tool and when designing consider:

=over

=item *

Try to keep the maximum of design in the Template. Create the page as it will be in production with dummy data when appropriate,

=item *

Delimit with the special tags the zones of HTML you now you're going to produce dynamically. All the HTML in the zone is considered dummy, but can be used if the application wants.

=item *

Use keywords replacement where you will provide an atomic value, like user name or date.

=back

=head1 PARAMETERS

The send_page function receives three parameters: filename, tags_hash, keywords_replace_hash

=head2 filename

This is the HTML file that acts as a template for the page that will be produced. The physical file is open and taken relative to the $r->document_root call (the Document Root). When not running under mod_perl the file given as parameter is open as it comes.

=head2 tags_hash

The keys of this hash are the tags we put in the HTML file, the values correspond to a reference to subroutines that, for each key, will generate the content for everything between the initial and ending tag. In our Example:

The TagPrefix Parameter of httpd.conf is xx. If not set, is assumed the value myasp. If the environment variable TagPrefix exists it's value superseded all other settings.

In the HTML file we put the mark:

 <xx:users>
 <tr><td>dummy id 1</td><td>dummy name 1</td></tr>
 <tr><td>dummy id 2</td><td>dummy name 2</td></tr>
 </xx:users>
 
 In the call to send_page:
 send_page('myfile.html', 
 {
 	-users => \&list_users,
 	-other_data => sub { print "this is the other data";  ... }
 }, 
 {
 	__user__ => $sesion->current_user,
 	__date__ => localtime(time),
 });

The first key of the second parameter (the tags_hash) is "-users " and it points to a reference of a subroutine. 

All this means this:

"All the content found in the template between the marks <xx:users> and </xx:users>, the marks inclusive, will be replaced with whatever the subroutine "list_users" prints, using the standard print command".

The second key "-other_data", is shown just to illustrate the declaration of an inline anonymous subroutine.

As in the module Apache::ASP, the subroutines will receive as the first parameter a hash reference with the attributes of the tag, and as a second argument the body of the tag. This may be useful in some cases when you want to use a micro template zone, for example, to predesign the rows in a table.

In the case of tables, is suggested to leave the table declaration in the template as in the example, and leave the rows marked, in order to be generate dynamically.

=head2 keywords_replace_hash

This parameter (optional), contains the keywords that will be replaced with the specified content. Note that no printing is allowed here, the value asigned to the keyword will be put in the resulting page. Each keyword will be replace as many times as it appear in the document. 

No prefixing or sufixing is enforced here, the developer (or designer) can chose the keywords to replace at will.

This form is very well suited for the dynamic content associated with atomic values. As shown in the example:

The HTML file:

 <html>
 ....
 __user__
 __date__
 
 With the keywords_replace_hash
 ...
 {
 	__user__ => $sesion->current_user,
 	__date__ => localtime(time),
 });

Will render an HTML file with the result of calling $sesion->current_user instead of the string __user__. __date__ will be replaced with the result of calling localtime(time).

If you allways name the marks with initial and ending double underline __, like in the example, here is the code of a shell script that receives a file as parameter and generate a skeleton keywords hash:

#!/bin/sh

perl -ne 'print "$1\t=>\ttextfield(-name=>\"$2\"),\n" while  /\b(__([\w-]+)__\b)/g' $1

=head1 Global Processing

In the web sites, there are sections that must be present in many pages (if not in all the pages). The system provides two functions that access associative arrays (hashs) that will be allways processed as if they were present in the call to send_page. For example, if you want to allways translate the __user__ mark with the current user and supossing there is some $sesion->current_user method that return this value, you cant at the begining of the request in some handler call:

HTML::Myasp::add_replace_entry(_user__ => $sesion->current_user);

And if you have some sections delimited to replace, you can call:

HTML::Myasp::add_sub_entry("-section" => sub { my ($attr, $body) = @_; my $s = new OV::Section($attr->{id}); $s->home_page_news });

The last call, is an example where there are multiple section marks in the html file, in this case, an electronic newspaper, for example:

<myasp:section id=foo><p>This is dummy data not used for now. Here must be the top foo.</p></myasp:section>
<myasp:section id=bar><p>This is dummy data not used for now. Here must be the bar section.</p></myasp:section>

The id attribute is used to pass a parameter to  the call to the funcion that will produce the content.

=head1 Debugging

At this time, there is a Package variable DEBUG that you can set to see aditional information in standard error (traditionally the file error_log in apache).

$HTML::Myasp::DEBUG=1;

There is only one level of debugging, and shows too much information.

=head1 TODO

Many things. It uses a rude regex based parser i expect to polish it with something better in the future. Do a finer debugging control.

=head1 EXPORT

send_page

=head1 AUTHOR

Hans Poo, hans@opensource.cl

=head1 SEE ALSO

perl(1). Apache::ASP (XMLSubsMatch) HTML::Template



=cut

