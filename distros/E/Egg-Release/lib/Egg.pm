package Egg;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Egg.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use Egg::Exception;
use Carp qw/ croak /;
use base qw/
  Egg::Util
  Egg::Component
  /;
use Egg::Manager::View;
use Egg::Manager::Model;
use Egg::Request;
use Egg::Response;

*egg_startup= \&_startup;

our $VERSION= '3.04';

sub import {
	shift;
	my $p= $ENV{EGG_IMPORT_PROJECT} || caller(0) || return 0;
	   $p=~s{\:+trigger$} [];
	return if ($p eq 'main' or $p eq __PACKAGE__);
	local $SIG{__DIE__}= sub { Egg::Error->throw(@_) };
	my (%flags, @plugins);
	for (@_) {
		if (/^(\-.+)/) {
			$flags{lc($1)}= 1;
		} else {
			my $load= /^=(.+)/ ? do { $_= $1; 0 }: 1;
			my $p_class= /^\+([A-Z].+)/ ? $1: "Egg::Plugin::$_";
			push @plugins, [$load, $p_class];
		}
	}
	no strict 'refs';  ## no critic
	my $isa= \@{"${p}::ISA"};
	push @{"${p}::ISA"}, $_ for qw/
	  Egg::Manager::View
	  Egg::Manager::Model
	  Egg::Request
	  Egg::Response
	  Egg
	  /;
	$p->initialize;
	$p->init_model;
	$p->init_view;
	for (qw/ global _dispatch_map uc_namespace lc_namespace is_exception /)
	    { $p->mk_classdata($_) unless $p->can($_) }
	my $name_uc= $p->uc_namespace(uc $p);
	$p->lc_namespace(lc $p);
	my $g= $p->global({ flag=> \%flags });
	no warnings 'redefine';
	*{"${p}::project_name"}= $p->can('namespace');
	$p->isa_register(@$_) for @plugins;
	my $name= "${name_uc}_DISPATCH_CLASS";
	my $d_class;
	if (defined($ENV{$name})) {
		if ($d_class= $ENV{$name}) { $p->isa_register(2, $d_class) }
	} else {
		$d_class= "${p}::Dispatch";
		$p->isa_register(0, $d_class);
		$d_class->use or die "$p - $@";
	}
	$g->{dispatch_class}= $d_class || "";
	$p->mk_classdata('dispatch_map') unless $p->can('dispatch_map');
	$p->isa_terminator(__PACKAGE__);
	$p->_import;
}
sub _startup {
	local $SIG{__DIE__}= sub { Egg::Error->throw(@_) };
	my $class= shift;
	my $c= $class->config($class->_load_config(@_));
	my $e= $class->_egg_context( egg_startup=> 1 );
	$e->_setup_comp;
	$e->setup_model;
	$e->setup_view;
	my $report= $e->_setup_methods;
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	# Create Stash Accessor.
	my $accessors= $c->{accessor_names} || [];
	for my $accessor ('template', @$accessors) {
		*{__PACKAGE__."::$accessor"}= sub {
			my $egg= shift;
			return $egg->stash->{$accessor} || "" unless @_;
			$egg->stash->{$accessor}= shift || "";
		  };
	}
	$e->_setup($c);
	$report->($e);
	$class;
}
sub new {
	my $class= shift;
	my $r= shift || undef;
	my $e= $class->_egg_context;
	$e->start_bench;
	$e->model_manager->reset($e);
	$e->view_manager->reset($e);
	$e->request($r);
	$e;
}
sub run {
	my $e= shift->new(@_);
	eval { $e->_start_engine };
	if ($@) {
		$e->is_exception(1);
		$e->error($@);
		$e->_finalize_error;
	}
	$e->_result;
}
sub finished {
	my $e= shift;
	return $e->{finished} unless @_;
	if (my $status= shift) {
		$status= $e->response->status($status)
		      || croak q{ It tried to set illegal status. };
		$e->log->error(@_) if (@_ and $status== 500);
		return $e->{finished}= 1;
	} else {
		$e->response->status(0);
		return $e->{finished}= 0;
	}
}
sub dispatch {
	croak q{ I want 'dispatch' method to be setup. };
}
sub _egg_context {
	my $class= shift;
	bless {
	  namespace => $class->namespace,
	  stash     => {},
	  snip      => [],
	  action    => [],
	  finished  => 0,
	  @_,
	  }, $class;
}
sub _start_engine_main {
	my($e)= @_;
	$e->_prepare;
	$e->_dispatch;
	$e->_action_start;
	$e->_action_end;
	$e->_finalize;
	$e->_output;
	$e->_finish;
	$e;
}
sub _dispatch {
	my($e)= @_;
	$e->{finished} || $e->dispatch->_start;
	$e;
}
sub _action_start {
	my($e)= @_;
	return $e if ($e->{finished} or $e->response->body);
	$e->dispatch->_action;
	$e->view->output if (! $e->{finished} and ! $e->response->body);
	$e;
}
sub _action_end {
	my($e)= @_;
	return $e unless $e->{finished};
	$e->dispatch->_finish;
	$e;
}
sub _finalize_error {
	my($e)= @_;
	my $status= $e->response->status || 500;
	my $error = $e->errstr || 'Internal Error.';
	$e->debug_end("${status}: ${error}");
	$e->debug_screen;
	$e;
}
sub _output {
	my($e)= @_;
	my $body  = $e->response->body || \"";
	my $header= $e->response->header($body);
	$e->request->output($header, $body);
}
sub _result {
	$_[0]->request->result;
}
sub _setup_methods {
	my $e= shift;
	my $p= shift || $e->namespace;
	my($bench, $report);
	if ($e->debug) {
		require Egg::Util::Debug;
		$bench= Egg::Util::Debug->_setup($e, $p);
		$report= \&Egg::Util::Debug::_report;
	} else {
		$bench= $e->_setup_method_main($p);
		$report= sub {};
	}
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	*{"${p}::start_bench"}= sub { $bench->(@_) };
	$report;
}
sub _setup_method_main {
	my($e, $p)= @_;
	$e->_setup_log($p);
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{"${p}::_start_engine"}= \&_start_engine_main;
	*{"${p}::debug_screen"}= $e->config->{allow_debug_screen} ? do {
		$SIG{__DIE__}= sub { Egg::Error->throw(@_) };
		my $dbgscreen=
		   $ENV{"${p}_DEBUG_SCREEN_CLASS"} || 'Egg::Util::DebugScreen';
		$dbgscreen->require or die $@;
		$dbgscreen->can('_debug_screen');
	  }: sub {};
	*{"${p}::debug_out"}= sub {};
	*{"${p}::debug_end"}= sub {};
	*{"${p}::egg_warn"} = sub {
		my @c= caller();
		warn qq{ I want you to delete warning of $c[0] line $c[2]. };
	 };
	*{"${p}::bench"}= sub {};
}
sub _setup_log {
	my($e, $p)= @_;
	my $l_class= $ENV{uc($p). '_LOG_CLASS'} || 'Egg::Log::STDERR';
	$l_class->require or die $@;
	my $log= $l_class->new($e);
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{"${p}::log"}= sub { $log };
}

1;

__END__

=head1 NAME

Egg - MVC Framework.

=head1 DESCRIPTION

Egg is WEB application framework with the control facilit of Model/View/Controller.

The specification changed with v2.x system and a former version.
Therefore, interchangeability is not secured.

=head1 HELPER

The helper script is first generated to use Egg, and the project file complete
set is generated with the script.

And, the application is constructed with the change of the setting of the project
and the addition of the module.

=head2 Generation of helper script.

  % perl -MEgg::Helper -e 'Egg::Helper->helper_script' > egg_helper.pl

When Egg::Helper is as mentioned above started, the helper script is generated
to the current directory.

It is convenient for the generated script to copy onto the place that manages
easily and to set the execution attribute.

  % cp ./egg_helper.pl /usr/bin
  % chmod 755 /usr/bin/egg_helper.pl

=head2 Making of project.

 % egg_helper.pl project MyApp

It becomes a project name that the part of MyApp newly generates.

However, please do not include ':' in the name by the form that is sure to be
permitted as a module name of perl.

Please specify passing putting '-o' option when you want to specify the output
destination.

  % egg_helper.pl project MyApp -o/path/to

It generates it to the current directory at the unspecification.

Moreover, when the same directory as the project name already exists at the output
destination, generation is discontinued.

=head2 Confirmation such as generation files.

I think the project to have been made in the directory of/path/to/MyApp in this
example. Please confirm the generation file.

  % cd /path/to/MyApp
  % ls -la
  drwxr-xr-x  *** .
  drwxr-xr-x  *** ..
  drwxr-xr-x  *** bin
  -rw-r--r--  *** Build.PL
  drwxr-xr-x  *** cache
  -rw-r--r--  *** Changes
  drwxr-xr-x  *** comp
  drwxr-xr-x  *** etc
  drwxr-xr-x  *** htdocs
  drwxr-xr-x  *** lib
  -rw-r--r--  *** Makefile.PL
  -rw-r--r--  *** MANIFEST
  -rw-r--r--  *** MANIFEST.SKIP
  -rw-r--r--  *** README
  drwxr-xr-x  *** root
  drwxr-xr-x  *** t
  drwxr-xr-x  *** tmp

It deletes if it is unnecessary and it doesn't care though Build.PL, Changes,
Makefile.PL, MANIFEST, MANIFEST.SKIP, README, and t are files among these needed
when the project file complete set is assumed to be perl module and the packaging
is done.

=over 4

=item * bin

There is a script that seems to be necessary to treat the project it.

=item * cache

For accumulation of cash data. The authority is set when using it.

=item * comp

It is a directory that assumes the common part of the template is arranged.

=item * etc

It is a configuration file and others, and a place to use it multipurpose.

=item * htdocs

It is a place where static contents are set up. It is good to make here
'DocumentRoot' of the WEB server.

=item * lib

It becomes a library passing for the project project that includes the controller,
the configuration, and the dispatch, etc. of the project beforehand.

=item * root

It is a place to arrange the template. There is index.tt of the sample.

=item * tmp

Please use it temporarily as a place where the work file is put.

=back

=head2 Confirming the operation of project.

Please confirm whether to operate normally first of all in the state of default
when the project is generable.

 % cd bin
 % ./trigger.cgi

'trigger.cgi' is a script when operating as usual CGI.

I think that default operates normally if this script outputs the HTML source.

Egg demonstrates the highest performance of origins such as mod_perl and FastCGI.
A practicable performance is not obtained by usual CGI.

Please use 'trigger.cgi' when using it from Apache::Registry and Apache::PerlRun.

'dispatch.fcgi' is used when using it with FastCGI.

Moreover, it is necessary to set 'mod_rewrite'.
It explains in detail at the following.

=head2 Construction of application.

The method of constructing the application makes it omit in this document.
It takes up and it explains an easy example in L<Egg::Release>.

It explains the role etc. of the system configuration and 'Egg.pm' of Egg in
this document.

=head1 SYSTEM

The main of the system of Egg is a project module.
The file is /path/to/MyApp/lib/MyApp.pm.

In a word, it becomes a controller to whom this file sets loading the configuration
and the plugin etc.

Egg is started from this controller.
And, the configuration is taken by initial operation.
Afterwards, it registers in @ISA of the project after the plug-in is loaded one
by one, and it registers in end @ISA.

As a result, it comes to be able to call the method of all modules by way of the
object of the project at what time.
Moreover, the plug-in module can add original processing picking up the hook that
Egg calls at what time.

The model and the view are registered with this @ISA Cdacdacata.
And, those modules are treated with more peculiar @ISA Cdacdacata to the handler
object of the model and the view though the model and the view can treat two or
more modules at the same time.

It is a system that treats the object that masses by the @ISA base like this and
outputs contents.

=head1 METHOD CALL

Egg does the following calls and outputs contents.

=over 4

=item * _setup

It is a call only when starting being called from 'import' of Egg.

=item * _prepare

It is a call for the preparation starting processing. Any Egg is not done.

=item * _dispatch

If $e-E<gt>finished has defined it, nothing has already been done though whether
$e-E<gt>dispatch-E<gt>_start is done and what action you do are decided.

=item * _action_start

If $e-E<gt>finished or $e-E<gt>response-E<gt>body has defined it, nothing has
already been done though $e-E<gt>dispatch-E<gt>_action is done and the decided
action is processed.

=item * _action_end

If $e-E<gt>finished has defined it, nothing has already been done though the
processing of dispatch is completed by $e-E<gt>dispatch-E<gt>_finish.

=item * _finalize

It is a call for the processing end. Any Egg is not done.

=item * _output

Contents are output.

=item * _finish

It is a call to complete all processing. Any Egg is not done.

=item * _finalize_error

When some errors occur, 'finish' is called. The content of the error can be
acquired in 'errstr' method.

=item * _result

It is a call to return the return value of run. Even whenever the exception is generated, it 
is called. Please confirm whether $e-E<gt>is_exception is confirmed and the exception was
generated when you process the hook by this.

=back

* Egg doesn't define $e-E<gt>finished.
Please note that $e-E<gt>finished always returns undefined as long as not defined on the 
application side etc.

=head1 METHODS

This module is L<Egg::Util>, L<Egg::Component>, L<Egg::Base>. It succeeds to.

=head2 new

Constructor. This is usually called from the 'handler' method.

  use MyApp;
  my $e= MyApp->new;

=head2 handler

It is a handler for processing to the WEB request to begin.

Egg is generated an appropriate handler by the composition at that time and 
stands by.

This method succeeds processing to the 'run' method.
A series of processing concerning the request is done by this.

  use MyApp;
  MyApp->handler;

=head2 run

This method is usually called from the handler method and does a series of
processing to the request.

=head2 egg_startup ([CONFIGURATION])

To start the project, it sets it up.


=head2 finished ([HTTP_RESPONSE_STATYS])

When processing is ended, it sets it.

When finished returns true, Egg cancels some processing.

The argument is sent to $e-E<gt>response->status as it is.
In a word, the HTTP response status is given when setting it.
see L<Egg::Response>.

'0' However, when Azca is gotten, it is initialized with $e-E<gt>response-E<gt>status.

  # Forbidden is returned and it ends.
  $e->finished(403);
  
  # finished A is canceled.
  $e->finished(0);

Please note that Egg doesn't set 'finished'.

=head2 dispatch

If 'dispatch' is called when the 'dispatch' method is not built into the project,
the exception is generated.


see L<Egg::Dispatch::Standard>, L<Egg::Dispatch::Fast>

=head2 project_name

The project name returns.

This method is an alias to the method of 'namespace' of L<Egg::Component>.

=head2 is_exception

When the exception is generated, true is restored.

=head2 request

The object of L<Egg::Request> is returned.

  my $req= $e->request;

Alias: req

see L<Egg::Request>,

=head2 response

The object of L<Egg::Response> is returned.

  my $res= $e->response;

Alias: res

see L<Egg::Response>

=head2 model_manager

L<Egg::Manager::Model> is returned.

=head2 view_manager

L<Egg::Manager::View> is returned.

=head2 debug_out ([MESSAGE_STRING])

The debugging message is output while operating by debug mode.
It is $e-E<gt>log-E<gt>notes to actually output.

It is replaced with the method of not doing anything when debug mode is invalid.

=head2 bench ([LABEL_STRING])

It is a method for the bench mark.

It is replaced with the method of not doing anything when debug mode is invalid.

see L<Egg::Util::BenchMark>.

=head1 PLUGIN

The module name when the plugin of Egg is loaded only has to specify only the part
of Egg::Plugin::PLUGIN_NAME in PLUGIN_NAME.

  # This specified Egg::Plugin::PluginAny.
  use Egg qw/ PluginAny /;

It specifies it by the full name putting '+' on the head to load an original plugin.

  use Egg qw/
    .......
    +Hoge::Plugin
    /;

=head2 About the method of making the plugin.

'use strict' is applied applying the package name to the plugin without fail.

  package Egg::Plugin::Any;
  use strict;

Moreover, without forgetting $VERSION

  our $VERSION = '0.01';

This $VERSION must be referred to when you the plugin load debug mode.

Please add the code as liked now.

  sub mymethod {
     my($e)= @_;
     .....
     .....  The code of the plug-in is written here.
     .....
     $e;
  }

It comes to be able to call it with $e-E<gt>mymethod when making it to such 
feeling.

However, it is already a thing that the method of the definition is not 
overwrited that wants you to note it.

If the plugin that puts interrupt on the call of the method of Egg is made,
it is necessary to have it by using $e-E<gt>next::method over the following.

  sub _prepare {
     my($e)= @_;
     .....
     .....  The code of the plug-in is written here.
     .....
     $e->next::method;
  }

The order of interrupt is done in order that the plugin is loaded.
The plugin to want to interrupt at the end makes it loaded as much as possible at
the end as much as possible.

If it wants to process the plugin produced with oneself from which plugin at the end,
the thing written as follows can be done.

  sub _prepare {
    my($e)= shift->next::method;
     .....
     .....  The code of the plugin is written here.
     .....
     $e;
  }

However, I think that there is a thing that comes for the user not to use it easily
thus.

Processing in which the default value etc. beforehand are defined putting interrupt
on '_setup' is recommended.
Every time, you can not check the configuration when putting it thus. 

  sub _setup {
     my($e)= @_;
     my $c= $e->config->{plugin_any} ||= {};
     $c->{hoge} ||= 'default1';
     $c->{foo}  ||= 'default2';
     $e->next::method;
  }

Interrupt can be put on the call of all the methods of Egg by such feeling.

=head2 Plugin list of standard appending.

=over 4

=item * L<Egg::Plugin::Charset>

It converts into the set character-code and contents are output.

=item * L<Egg::Plugin::ConfigLoader>

The configuration of another define the file is read.

=item * L<Egg::Plugin::Banner::Rotate>

Rotation display of banner.

=item * L<Egg::Plugin::Debug::Bar>

The bar for debugging is buried under the output contents.

=item * L<Egg::Plugin::Encode>

The and others of the method of converting the character-code is offered.

=item * L<Egg::Plugin::File::Rotate>

Rotation management in saved file.

=item * L<Egg::Plugin::FillInForm>

L<HTML::FillInForm> can be treated.

=item * L<Egg::Plugin::Filter>

The filter of input data is processed.

=item * L<Egg::Plugin::FormValidator::Simple>

L<FormValidator::Simple> can be treated.

=item * L<Egg::Plugin::HTTP::BrowserDetect>

The browser judgment that client uses.

=item * L<Egg::Plugin::HTTP::HeadParser>

Analysis of HTTP header.

=item * L<Egg::Plugin::Mason>

Plugin for L<HTML::Mason>.

=item * L<Egg::Plugin::Prototype>

L<HTML::Prototype> can be treated.

=item * L<Egg::Plugin::rc>

The run control file is read.

=item * L<Egg::Plugin::Response::Error>

The error document is output.

=item * L<Egg::Plugin::Response::Redirect>

The screen for redirect is output.

=item * L<Egg::Plugin::Tools>

Method collection for various processing.

=item * L<Egg::Plugin::Upload>

The file upload function is offered.

=item * L<Egg::Plugin::WYSIWYG::FCKeditor>

Plugin to use FCKeditor.

=item * L<Egg::Plugin::YAML>

YAML can be treated.

=back

=head2 Recommendation module not included in standard.

=over 4

=item * L<Egg::Plugin::Cache>

Various cache is availably done.

=item * L<Egg::Plugin::Crypt::CBC>

L<Crypt::CBC> is made available.

=item * L<Egg::Plugin::EasyDBI>

DBI can be easily treated.  see L<Egg::Release::Model::DBI>.

=item * L<Egg::Plugin::LWP>

LWP is made available.

=item * L<Egg::Plugin::MailSend>

The Mail Sending function is offered.

=item * L<Egg::Plugin::SessionKit>

The session function is offered.

=item * L<Egg::Release::JSON>

It comes to be able to treat JSON easily.

=item * L<Egg::Release::XML::FeedPP>

L<XML::FeedPP> can be treated.

=back

=head1 WEB SERVER

It is necessary to move it under mod_perl and the FastCGI environment to obtain
 the best response speed in Egg.

To our regret, a practicable response speed is not obtained by usual CGI.

=head2 Apache::Registry or Apache::PerlRun

'trigger.cgi' that exists in the 'bin' directory of the project is moved to a
 suitable place and the execution attribute is given. And, mod_rewite is set by
 the following feeling.

  RewriteEngine On
  # RewriteLogLevel 5
  # RewriteLog /var/log/httpd/rewrite.log
  RewriteRule ^/trigger\.cgi  /  [R,L]
  RewriteRule ^/([^\.]+)?([\?\#].*)?$  /trigger.cgi/$1$2  [L]  

It is assumed to arrange 'trigger.cgi' in the document route.
URI that doesn't contain the dot in this regular expression is treated as 
dynamic contents.
When the dot is contained, everything is not matched to the pattern as static 
contents.
Please change this regular expression when you want to change the evaluation.

The setting of Apache::Registry and Apache::PerlRun is omitted.

=head2 Apache Handler

The setting by the Apache handler has a set sample in the etc directory and refer
to that, please.

  % less etc/mod_perl2.conf.example

The sample is for 'mod_perl2'.

=head2 FastCGI

A set sample is in the etc directory and refer, please.
The sample targeted lighttpd.

  % less etc/lighttpd+fastcgi.conf.example

Please arrange 'dispatch.fcgi' that exists in the bin directory in a suitable place.
It is a setting that assumes the document route in the sample.

And, the execution attribute is given.

Please add the setting of the sample to the setting of lighttpd when the above-
mentioned work ends.

=head2 PersistentPerl (SpeedyCGI)

'speedy.cgi' of the 'bin' directory is moved to a suitable place and the execution
attribute is given. And, 'mod_rewrite' like Apache::Registry is set.
Please do not forget to set for CGI to operate by the WEB server.

=head1 DEBUG

It operates by debug mode in setting the Debug flag when Egg is loaded.

  use Egg qw/
   -Debug
   /;

Moreover, it is possible to use it even by other usages because it is treated as
a flag when '-' is applied to the head regardless of the flag for debugging.

When the flag is invalidated, it is not necessary to delete it.
If another '-' is added, the flag becomes undefined.

  use Egg qw/
   --Debug
   /;

=head2 Improvement of development efficiency.

If the change in the module basically loaded doesn't reactivate the WEB server,
Egg is not reflected.

Moreover, the WEB server for development is not included. Therefore, it will do
to the development of the application by the thing moved on WEB servers such as
'Apache' or 'lighttpd'.

However, if Egg doesn't reactivate the WEB server at the change in the module,
the change is not reflected.
With this, because the development efficiency is very bad, I think that the 
following devices are indispensable.

When PersistentPerl is used, the introduction of L<Module::Refresh> is very 
effective. 'speedy.cgi' is changed as follows when using it.

  #!/usr/bin/perperl
  use Module::Refresh;
  use MyApp;
  Module::Refresh->refresh();
  MyApp->handler;

The change in the module comes to be reflected by this immediately.

However, neither the dynamic function definition that 'Import' and '_setup'
method do nor the change of a set value are reflected.
It seem not to be about the one related to these symbol tables though it does
very. Please do 'speedy.cgi' in touch in such a case.

  % touch /path/to/MyApp/htdocs/speedy.cgi

L<Module::Refresh> seems not to work well in FastCGI.
Please try L<Egg::Plugin::Debug::Bar> when you use FastCGI.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Request>,
L<Egg::Response>,
L<Egg::Manager::Model>,
L<Egg::Manager::View>,
L<Egg::Component>,
L<Egg::Util>,
L<Egg::Util::Debug>,
L<Egg::Util::DebugScreen>,
L<Egg::Log::STDERR>,
L<Egg::Exception>

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

