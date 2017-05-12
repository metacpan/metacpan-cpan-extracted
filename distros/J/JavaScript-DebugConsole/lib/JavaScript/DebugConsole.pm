package JavaScript::DebugConsole;

use 5.005;
use strict;

use vars qw($VERSION);
$VERSION = '0.01';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = ($#_ == 0) ? shift : { @_ };
	$self->{debug} = 1 if ( ! defined $self->{debug} || $self->{debug} !~ /^(0|1)$/ );
	return bless $self,$class;
}

sub debugConsole {
	my $self = shift;
	my %args = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;

	$args{'title'} ||= 'POPUPConsole';
	$args{'auto_open'} = 1 if ! defined $args{'auto_open'};
	$args{'id'} = defined $args{'id'} || ( $$ . '_' . ++$self->{'popup_count'} );
	$args{'content'} ||= $self->{'content'};
	$args{'env'} ||= \%ENV;
	$args{debug} = $self->{debug} if ( ! defined $args{debug} || $args{debug} !~ /^(0|1)$/ );
	$args{'popup_options'} ||= 'height=250,width=500,scrollbars=1,resizable=1,dependent,screenX=250,screenY=200,top=200,left=250';

	# create javascript code
	my $str = <<EOM;
<SCRIPT LANGUAGE="JavaScript1.2">
<!--
function OpenDebugConsole_$args{'id'}(title, caption, options) {  
	def_options = '$args{'popup_options'}';

	if ( !options )
		options = def_options;

	// if our debug window is already open, just switch to it and navigate 
	var win = top.debugWin ;
	if ( win && win.body && (! win.closed) ) {
		win.focus();
	}
	// open debug win and write
	else {
		var win = window.open("",caption,options);
		win.focus();
	}
EOM
	$str .= "win.document.writeln(\"<PRE>\")\n" if $args{'pre'};

	# print debug info
	if ( $args{'debug'} ) {
		$args{'content'} .= <<EOM;
<TABLE BGCOLOR="#8888FF" BORDER="0" CELLPADDING="1" CELLSPACING="1">
	<TR ALIGN="LEFT">
		<TH COLSPAN="2"><FONT FACE="VERDANA,ARIAL" SIZE="4" COLOR="#FFFFFF">CGI/form environment</FONT></TH>
	</TR>
	<TR BGCOLOR="#CCCCCC">
		<TH COLSPAN="2" ALIGN="LEFT"><FONT FACE="VERDANA,ARIAL" SIZE="3">FORM PARAMS</FONT></TH>
	</TR>
	<TR BGCOLOR="#EEEEEE"> 
		<TD><FONT FACE="VERDANA,ARIAL" SIZE="-1">
EOM
		$args{'content'} .= _HashVariables($args{'form'},"</FONT></TD>\n </TR>\n <TR BGCOLOR=\"#EEEEEE\">\n  <TD><FONT FACE=\"VERDANA,ARIAL\" SIZE=\"-1\">","</FONT></TD>\n  <TD><FONT FACE=\"VERDANA,ARIAL\" SIZE=\"-1\">");
		$args{'content'} .= <<EOM;
		</FONT></TD>
		<TD></TD>
	</TR>
		<TR BGCOLOR="#CCCCCC">
		<TH COLSPAN="2" ALIGN="LEFT"><FONT FACE="VERDANA,ARIAL" SIZE="3">ENVIRONMENT VARIABLES</FONT></TH>
	</TR>
	<TR BGCOLOR="#EEEEEE"> 
		<TD><FONT FACE="VERDANA,ARIAL" SIZE="-1">
EOM
		$args{'content'} .= _HashVariables($args{'env'},"</FONT></TD>\n\t</TR>\n <TR BGCOLOR=\"#EEEEEE\">\n  <TD><FONT FACE=\"VERDANA,ARIAL\" SIZE=\"-1\">","</FONT></TD>\n  <TD><FONT FACE=\"VERDANA,ARIAL\" SIZE=\"-1\">");
		$args{'content'} .= <<EOM;
		</FONT></TD>
		<TD></TD>
	</TR>
</TABLE>
<BR>
EOM
	}
	
	foreach my $debug_line( split(/\n/,$args{'content'}) ) {
		$debug_line =~ s/cM//g;
		$debug_line =~ s/\r//g;
		$debug_line =~ s/'/\\'/g;
		$debug_line =~ s/"/\\"/g;
		$str .= "\twin.document.writeln(\"$debug_line\");\n";
	}
	$str .= "win.document.writeln(\"</PRE>\")\n" if $args{'pre'};	
	$str .= <<EOM;
	win.document.close();
}
EOM
	# Store JS function call into object property
	$self->{'link'} = "OpenDebugConsole_$args{'id'}('$args{'title'}', '$args{'title'}','$args{'popup_options'}')";

	if ( $args{'auto_open'} ) {
	$str .= <<EOM;
// open js console
$self->{'link'}
EOM
	}
	$str .= <<EOM;
//-->
</SCRIPT>
EOM
	$self->{'console'} = $str;
}

sub add {
	my ($self) = shift;
	$self->{content} .= join "\n", @_;
}

sub link {
	my $self = shift;
	return 'javascript:' . $self->{'link'};
}

sub console {
	my $self = shift;
	$self->{'console'};
}

sub _HashVariables {
	my($hash,$separator,$equal) = @_;
	my $str = '';
	$equal = ' = ' unless $equal;
	eval { $hash->can('param') };
	if ( $@ ) {
		foreach(sort keys %$hash) {
			$str .= $_ . $equal . $hash->{$_} . $separator;
		}
	}
	else {
		foreach(sort $hash->param) {
			$str .= $_ . $equal . $hash->param($_) . $separator;
		}
	}
	return $str;
}

1;

__END__

=pod

=head1 NAME

JavaScript::DebugConsole - Perl extension to generate JavaScript popups with
custom text and typical web development useful informations

=head1 SYNOPSIS

   use JavaScript::DebugConsole;
   my $jdc = new JavaScript::DebugConsole;
   $jdc->add('Some', 'text');
   print $jdc->debugConsole();

=head1 DESCRIPTION

I packaged some my old and simple functions inside a Perl module (I was tired to
do cut&paste each time :-) ) to generate the necessary JavaScript code in order
to open a popup window with custom text and typical web development useful infos
(like form params, environment variables, HTTP headers and so on).

=head1 INSTALLATION

In order to install and use this package you will need Perl version 5.005 or
higher.

Installation as usual:

   % perl Makefile.PL
   % make
   % make test
   % su
     Password: *******
   % make install

=head1 DEPENDENCIES

No thirdy-part modules are required.

=head1 CONSTRUCTOR

=over 4

=item * new( %args )

It's possible to create a new C<JavaScript::DebugConsole> by invoking the
C<new> method. Parameters are passed as hash array:

=over 4

=item C<debug> boolean

Enable CGI form parameters and environment prints. Default value is 1.

=back

=head1 METHODS

=over 4

=item * add( 'Some', 'Text', [...] )

Add text to be rendered with JavaScript C<writeln> calls.

=item * debugConsole(%args)

Returns JavaScript code in order to open popup with custom text.
Parameters are passed as hash array:

=over 4

=item C<content> string

Allows to set the content which will be render by Javascript
C<document.writeln> statement. The parameter isn't mandatory. It overrides text
previously added with calls to C<add> method.

=item C<title> string

Popup title. Default vaule is I<POPUPConsole>.

=item C<auto_open> boolean

Appends to JavaScript generated code, the necessary call in order to open 
popup automatically when page is loaded. Default value is C<1>.

=item C<form> object or hashref

Reference to the form data. This can either be a hash reference, or a
CGI.pm-like object. In particular, the object must have a param() method that
works like the one in CGI.pm does. CGI::Simple and Apache::Request objects are
known to work. 

=item C<env> hashref

Hash reference to environment variables. Default is C<%ENV>.

=item C<id> string

Unique identifier in order to use it to name JavaScript function that creates
popup. This allow more that one popup calls in same page without conflicts.
Default is C<$$> (process PID).

=item C<popup_options> string

Popup options. Default value is:

C<height=250,width=450,scrollbars=1,resizable=1,dependent,screenX=250,screenY=200,top=200,left=250>. 

See the JavaScript reference manual for more info about C<window.open> method.

=item C<pre> boolean

Print popup content inside I<E<lt>PREE<gt> E<lt>/PREE<gt>> HTML tag.
Default values is 0.

=item C<debug> boolean

Enable CGI form parameters and environment prints. Ovverride C<debug> object property
value only for method invocation.

=back

The method returns the generated JavaScript code.

=back

=head1 INTEGRATING IN Template Toolkit

During initial development, Sam Vilain asked me to include also a
Template::Plugin::JS::DebugConsole plugin in order to use this class in Template
Toolkit environment.

Since the wrapper wouldn't have added nothing of special, I used successfully
C<Template::Plugin::Class> plugin, by avoiding to write e new one at the cost
of one line only of additional code:

   [% USE c = Class('JavaScript::DebugConsole') %]
   [% jdc = c.new %]
   [% jdc.debugConsole( content => "Popup text",
                        title => "Debug title", auto_open => 0 ) %]
   <p>Click <a href="[% jdc.link %]">here</a> to open the console!</p>

Following code use CGI plugin in order to print also CGI form params:

   [% USE q = CGI %]
   [% USE c = Class('JavaScript::DebugConsole') %]
   [% jdc = c.new %]
   [% jdc.debugConsole( content => "Popup text", title => "Debug title", 
                        auto_open => 1, form => q ) %]

=head1 EXAMPLES

   #!/usr/local/bin/perl

   use JavaScript::DebugConsole;
   use CGI qw/:standard/;
   my $q = new CGI;
   print header;
   
   # create new object
   my $jdc = new JavaScript::DebugConsole;
   print $jdc->debugConsole( content => 'My debug infos', title => 'Debug Test', 
                             auto_open => 0, form => $q );
   print '<a href="' . $jdc->link . '">Open the console!</A>';

=head1 BUGS 

Please submit bugs to CPAN RT system at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JavaScript-DebugConsole or by
email at bug-javascript-debugconsole@rt.cpan.org

Patches are welcome and I'll update the module if any problems will be found.

=head1 VERSION

Version 0.01

=head1 SEE ALSO

perl

=head1 AUTHOR

Enrico Sorcinelli, E<lt>enrico at sorcinelli.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Enrico Sorcinelli

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
