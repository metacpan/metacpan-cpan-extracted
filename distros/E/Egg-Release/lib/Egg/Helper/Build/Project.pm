package Egg::Helper::Build::Project;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Project.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.04';

sub _start_helper {
	my($self)= @_;

	my $project_name= shift(@ARGV)
	   || return $self->_helper_help(' I want project name. ');

	my $o= $self->_helper_get_options;
	$o->{help} and return $self->_helper_help;

	$project_name=~m{^[A-Z][A-Za-z0-9_]+$}
	   || return $self->_helper_help(' Bad format of project name. ');

	my $version= $o->{version} || '0.01';
	$version=~m{^\d+\.\d\d+}
	   || return $self->_helper_help(' Bad format of version number. ');

	my $c= $self->config;
	$c->{project_name}= $project_name;
	$c->{root} = $o->{output_path} || '.';
	$c->{root}.= "/${project_name}";
	-e $c->{root}
	  and return $self->_helper_help(qq{'$c->{root}' already exists.});
	my $files= [$self->helper_yaml_load(join '', <DATA>)];
	my $param= $self->helper_prepare_param({ module_version => $version });
	$self->helper_chdir($c->{root}, 1);
	$param->{project_root}= $self->helper_current_dir;
	$self->helper_generate_files(
	  param        => $param,
	  create_files => $files,
	  create_dirs  => [qw/ bin root comp etc t htdocs cache tmp /],
	  makemaker_ok => ($o->{unmake} ? 0: 1),
	  errors       => { rmdir=> [$c->{root}] },
	  complete_msg => "Project generate is completed.\n\n"
	               .  "output path : $c->{root}",
	  );

	if (my $test= $self->config->{helper_option}{test_code}) {
		$test->($self, $param, $files);
	}
	$self;
}
sub _helper_get_options {
	shift->next::method(' v-version= m-unmake ');
}
sub _helper_help {
	my $self= shift;
	my $msg = shift || "";
	$msg= "ERROR: ${msg}\n\n" if $msg;
	print <<END_HELP;
${msg}% perl egg_helper.pl project [NEW_PROJECT_NAME] [-o OUTPUT_PATH]

END_HELP
}

1;

=head1 NAME

Egg::Helper::Build::Project - Helper to generate project.

=head1 SYNOPSIS

  % egg_helper.pl project MyApp -o /path/to

=head1 DESCRIPTION

It is a helper to generate the project.

First of all, please generate the helper script to use it.

The method of generating the helper script is in the document of L<Egg>.

The mode and the made project name are passed to the generated helper script and
it starts.

  % egg_helper.pl project [PROJECT_NAME]

PROJECT_NAME is made for the current directory by this, and the file complete set
is generated in that.

PROJECT_NAME specifies the name that can be used as a module name of Perl.
Moreover, the form of the subclass including ':' is not accepted.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Helper>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut


__DATA__
---
filename: lib/<e.project_name>.pm
filetype: module
value: |
  package <e.project_name>;
  #
  # <e.revision>
  #
  # This is controller.
  #
  use strict;
  use warnings;<e.egg_inc>
  use Egg qw/
    -Debug
    ConfigLoader
    /;
  
  our $VERSION= '<e.module_version>';
  
  __PACKAGE__->egg_startup;
  
  1;
  
  __END__
  
  < $e.document >
---
filename: lib/<e.project_name>/Dispatch.pm
filetype: module
value: |
  package <e.project_name>::Dispatch;
  #
  # < e.revision >
  #
  # This is dispatch.
  #
  use strict;
  use warnings;<e.egg_inc>
  use base qw/ Egg::Dispatch::Standard /;
  
  our $VERSION= '0.01';
  
  <e.project_name>->dispatch_map(
  
    _default => sub {
      my($e, $dispatch)= @_;
      require Egg::Util::BlankPage;
      $e->response->body( Egg::Util::BlankPage->out($e) );
      },
  
  #  _default => sub {},
  #  sitemap  => sub {},
  #  contact  => sub {},
  #  help     => {
  #    _default=> sub {},
  #    },
  
    );
  
  1;
  
  __END__
  
  <e.document>
---
filename: lib/<e.project_name>/config.pm
filetype: module
value: |
  package <e.project_name>::config;
  #
  # <e.revision>
  #
  use strict;
  use warnings;
  
  sub out {  {
  
  # Project Title.
  title=> '< e.project_name >',
  
  # Project root directory. (Absolutely path only)
  root => '< e.project_root >',
  
  # Directory configuration.
  static_uri=> '/',
  
  dir => {
    lib      => '\<e.root>/lib',
    htdocs   => '\<e.root>/htdocs',
    etc      => '\<e.root>/etc',
    cache    => '\<e.root>/cache',
    tmp      => '\<e.root>/tmp',
    template => '\<e.root>/root',
    comp     => '\<e.root>/comp',
    },
  
  # Character code for processing.
  #  character_in         => 'euc',  # euc or sjis or utf8
  #  disable_encode_query => 0,
  
  # Template.
  #  template_default_name => 'index',
  #  template_extension    => '.tt',
  template_path=> [qw/ \<e.dir.template> \<e.dir.comp> /],
  
  # Default content type and language.
  #  charset_out      => 'euc-jp',
  #  content_type     => 'text/html',
  #  content_language => 'ja',
  
  # Regular expression of Content-Type that doesn't send Content-Length.
  #  no_content_length_regex => qr{(?:^text/|/(?:rss\+)?xml)},
  
  # Upper bound of request directory hierarchy.
  #  max_snip_deep => 10,
  
  # Regular expression in part that wants to be erased from Request PATH always.
  #  request_path_trim => qr{^/?speedy\.cgi},
  
  # Accessor to stash. * Do not overwrite a regular method.
  #  accessor_names => [qw/hoge/],
  
  # Cookie default setup.
  #  cookie_default => {
  #    domain  => 'mydomain',
  #    path    => '/',
  #    expires => 0,
  #    secure  => 0,
  #    },
  
  # MODEL => [
  # [ DBI => {
  #   dsn      => 'dbi:SQLite;dbname=\<e.dir.etc>/<e.lc_project_name>.db',
  #   user     => '',
  #   password => '',
  #   options  => { AutoCommit=> 1, RaiseError=> 0 },
  #   } ],
  # ],
  
  # VIEW => [
  # [ Mason => {
  #   comp_root=> [
  #     [ main   => '\<e.dir.template>' ],
  #     [ private=> '\<e.dir.comp>' ],
  #     ],
  #   data_dir=> '\<e.dir.tmp>',
  #   } ],
  # [ HT => {
  #   path=> ['\<e.dir.template>', '\<e.dir.comp>'],
  #   global_vars=> 1,
  #   die_on_bad_params=> 0,
  # # cache=> 1,
  #   } ],
  # ],
  
  # request => {
  #   DISABLE_UPLOADS => 0,
  #   TEMP_DIR        => '\<e.dir.tmp>',
  #   POST_MAX        => 10240,
  #   },
  
  # * For ErrorDocument plugin.
  # plugin_error_document=> {
  #   view_name => 'Mason',
  #   template  => 'error/document.tt',
  #   },
  
  # * For FillInForm plugin.
  # plugin_fillinform=> {
  #   ignore_fields => [qw{ ticket }],
  #   fill_password => 0,
  #   },
  
  }  }
  
  1;
---
filename: Makefile.PL
filetype: text
value: |
  use inc::Module::Install;
  
  name          '<e.project_name>';
  all_from      'lib/<e.project_name>.pm';
  abstract_from 'lib/<e.project_name>.pm';
  version_from  'lib/<e.project_name>.pm';
  author        '<e.author>';
  license       '<e.license>';
  
  requires 'Egg::Release' => <e.egg_release_version>;
  
  build_requires 'Test::More'         => 0;
  build_requires 'Test::Pod'          => 0;
  # build_requires 'Test::Perl::Critic  => 0;
  # build_requires 'Test::Pod::Coverage => 0;
  
  use_test_base;
  auto_include;
  WriteAll;
---
filename: bin/trigger.cgi
filetype: script
value: |
  #!<e.perl_path>
  package <e.project_name>::trigger;
  # use FindBin;
  # use lib "$FindBin::Bin/../lib";
  use lib qw{ <e.project_root>/lib };
  use <e.project_name>;
  
  <e.project_name>->handler;
  
---
filename: bin/dispatch.fcgi
filetype: script
value: |
  #!<e.perl_path>
  package EggRelease::trigger;
  BEGIN {
    $ENV{<e.uc_project_name>_REQUEST_CLASS} ||= 'Egg::Request::FastCGI';
  #  $ENV{<e.uc_project_name>_FCGI_LIFE_COUNT} = 0;
  #  $ENV{<e.uc_project_name>_FCGI_LIFE_TIME}  = 0;
  #  $ENV{<e.uc_project_name>_FCGI_REBOOT}     = 0;
    };
  use FindBin;
  use lib "$FindBin::Bin/../lib";
  use <e.project_name>;
  
  <e.project_name>->handler;
  
---
filename: bin/speedy.cgi
filetype: script
value: |
  #!/usr/bin/perperl
  package <e.project_name>::trigger;
  # use FindBin;
  # use lib "$FindBin::Bin/../lib";
  use lib qw{ <e.project_root>/lib };
  use <e.project_name>;
  
  <e.project_name>->handler;
  
---
filename: bin/<e.lc_project_name>_helper.pl
filetype: script
value: |
  #!<e.perl_path>
  use FindBin;
  use lib "$FindBin::Bin/../lib";
  use Egg::Helper;
  
  Egg::Helper->run( shift(@ARGV), {
    project_name_orign => '<e.project_name>',
    project_root => '<e.project_root>',
    } );
  
---
filename: bin/<e.lc_project_name>_tester.pl
filetype: script
value: |
  #!<e.perl_path>
  use FindBin;
  use lib "$FindBin::Bin/../lib";
  use Egg::Helper;
  
  Egg::Helper->run(
   'Util::Tester',
    project_name_orign => '<e.project_name>',
    project_root => '<e.project_root>',
    );
  
---
filename: etc/mod_perl2.conf.example
filetype: text
value: |
  LoadModule perl_module modules/mod_perl.so
  
  <VirtualHost *:80>
    ServerName  hostname.example.com
    DocumentRoot <e.project_root>/htdocs
  
    PerlOptions  +Parent
    PerlSwitches -I<e.dir.lib>
    PerlModule   mod_perl2
    PerlModule   <e.project_name>
  
    <LocationMatch "^/([^\.]+)?$">
     SetHandler  perl-script
     PerlHandler <e.project_name>
    </LocationMatch>
  
  </VirtualHost>
  #
  # When proxy such as Pound is put on frontend, it is likely to need it.
  #
  # * The reference ahead. -> http://stderr.net/apache/rpaf/ 
  #
  # LoadModule rpaf_module modules/mod_rpaf-X.X.so
  # RPAFenable On
  # RPAFsethostname Off
  # RPAFproxy_ips 255.255.255.255
  
---
filename: etc/lighttpd+fastcgi.conf.example
filetype: text
value: |
  $HTTP["host"] == "mydomain.name" {
  #  $HTTP["remoteip"] !~ "^255\.255\.255\.0$" {
  #    url.access-deny = ("")
  #    }
    server.document-root = "<e.project_root>/htdocs"
    url.rewrite-once = (
      "^/([^\.]+)?([\?\#].*)?$" => "/dispatch.fcgi/$1$2",
      )
    fastcgi.server = ( "/dispatch.fcgi" => ((
      "socket"   => "<e.project_root>/tmp/fcgi.socket",
      "bin-path" => "<e.project_root>/htdocs/dispatch.fcgi",
      "max-procs" => 1,
  #    "idle-timeout" => 10
      ))
    )
  }
  
---
filename: t/00_<e.project_name>.t
filetype: text
value: |
  use Test::More tests => 1;
  use FindBin;
  use lib (
    "$FindBin::Bin/lib",
    "$FindBin::Bin/../lib",
    "$FindBin::Bin/../../lib",
    );
  BEGIN { use_ok('<e.project_name>') };
  
---
filename: t/01_< $e.project_name >-config.t
filetype: text
value: |
  use Test::More tests => 1;
  use FindBin;
  use lib (
    "$FindBin::Bin/lib",
    "$FindBin::Bin/../lib",
    "$FindBin::Bin/../../lib",
    );
  BEGIN { use_ok('<e.project_name>::config') };
  
---
filename: t/02_<e.project_name>-dispatch.t
filetype: text
value: |
  use Test::More tests => 12;
  use FindBin;
  use lib (
    "$FindBin::Bin/lib",
    "$FindBin::Bin/../lib",
    "$FindBin::Bin/../../lib",
    );
  use <e.project_name>;
  
  ok my $e= <e.project_name>->new;
  isa_ok $e, 'Egg';
  isa_ok $e, 'Egg::Request';
  isa_ok $e, 'Egg::Response';
  isa_ok $e, 'Egg::Util';
  isa_ok $e, 'Egg::Manager::Model';
  isa_ok $e, 'Egg::Manager::View';
  isa_ok $e, 'Egg::Component';
  isa_ok $e, '<e.project_name>::Dispatch';
  
  can_ok $e, 'dispatch_map';
  isa_ok $e->dispatch_map, 'HASH';
  isa_ok $e->dispatch_map->{_default}, 'CODE';
  
---
filename: t/89_pod.t~
filetype: text
value: |
  use Test::More;
  eval "use Test::Pod 1.00";
  plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
  all_pod_files_ok();
---
filename: t/98_perlcritic.t~
filetype: text
value: |
  use strict;
  use Test::More;
  eval q{ use Test::Perl::Critic };
  plan skip_all => "Test::Perl::Critic is not installed." if $@;
  all_critic_ok("lib");
  #
  # Please install Test::Perl::Critic to do this test effectively.
  # - perl -MCPAN -e "install Test::Perl::Critic"
  #
---
filename: t/99_pod_coverage.t~
filetype: text
value: |
  use Test::More;
  eval "use Test::Pod::Coverage 1.00";
  plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
  all_pod_coverage_ok();
---
filename: Changes
filetype: text
value: |
  Revision history for Perl extension <e.project_name>.
  
  <e.module_version>  <e.gmtime_string>
  	- original version; created by <e.created>
  	   with module name <e.project_name>.
---
filename: README
filetype: text
value: |
  <e.project_name>.
  =================================================
  
  The README is used to introduce the module and provide instructions on
  how to install the module, any machine dependencies it may have (for
  example C compilers and installed libraries) and any other information
  that should be provided before the module is installed.
  
  A README file is required for CPAN modules since CPAN extracts the
  README file from a module distribution so that people browsing the
  archive can use it get an idea of the modules uses. It is usually a
  good idea to provide version information here so that people can
  decide whether fixes for the module are worth downloading.
  
  INSTALLATION
  
  To install this module type the following:
  
     perl Makefile.PL
     make
     make test
     make install
  
  AUTHOR
  
  <e.author>
  
  COPYRIGHT AND LICENCE
  
  Put the correct copyright and licence information here.
  
  Copyright (C) <e.year> by <e.copyright>.
  
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version <e.perl_version> or,
  at your option, any later version of Perl 5 you may have available.
---
filename: MANIFEST.SKIP
filetype: text
value: |
  \bRCS\b
  \bCVS\b
  ^MANIFEST\.
  ^MakeMaker-\d
  ^Makefile$
  ^_build/
  ^blib/
  ^pm_to_blib
  ^t/9\d+_.*\.t
  Build$
  \.cvsignore
  \.?svn*
  ^\%
  ^(bin|etc)/
  (~|\-|\.(old|save|back))$
---
filename: htdocs/css/index.css
filetype: text
value: |
  body {
  	margin:0px;
  	background:#AAA;
  	font:normal 12pt sans-serif;
  	color:#000;
  	text-align:center;
  	}
  a   { color:#05F }
  img { border:0px }
  
  /* ---------------------------------------------- */
  h1, h2, h3 {
  	margin: 5px;
  	font: bold 25px Times,sans-serif;
  	text-decoration: underline;
  	}
  h2, h3 { font-size: 14px }
  h3     { margin-top: 0px }
  pre {
  	margin: 2px 10px 5px 0px;
  	padding: 10px;
  	background: #FFF7E5;
  	font: normal 12px sans-serif;
  	border: #C99158 solid 1px;
  	}
  /* ---------------------------------------------- */
  
  #container {
  	width:780px;
  	padding:0px;
  	margin:0px auto 0px auto;
  	background:#EB0;
  	border:#000 solid 2px;
  	}
  #header {
  	text-align:left;
  	height:73px;
  	border-bottom:#000 solid 2px;
  	background:#FD0;
  	}
  #header .logo {
  	float:left;
  	}
  #header .descript {
  	padding:20px;
  	height:73px;
  	border-left:#000 solid 2px;
  	}
  #content {
  	padding:10px;
  	width:522px;
  	float:right;
  	border:#000 solid 2px;
  	border-top:0px;
  	border-right:0px;
  	background:#FFF;
  	text-align:left;
  	}
  #side_content {
  	width:234px;
  	float:left;
  	}
  #menu a {
  	display:block;
  	border-bottom:#740 solid 1px;
  	text-decoration:none;
  	color:#333;
  	}
  #menu a:hover {
  	color:#000;
  	background:#FC0;
  	}
  #footer {
  	clear:both;
  	padding:1px 3px 3px 3px;
  	font-size:8pt;
  	}
  #footer a {
  	text-decoration:none;
  	color:#555;
  	}
  #footer a:hover {
  	text-decoration:underline;
  	color:#000;
  	}
  #copyright {
  	font:italic 10pt Times;
  	color:#555;
  	}
---
filename: comp/html-header.tt
filetype: text
value: |
  <%init>
  my $lang= $e->response->content_language;
  </%init>
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
              "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml" lang="<% $lang %>">
  <head>
  <meta http-equiv="Content-Language" content="<% $lang %>" />
  <meta http-equiv="Content-Type" content="<% $e->response->content_type %>" />
  <title><% $e->page_title %></title>
  <meta http-equiv="Content-Style-Type" content="text/css" />
  <link rel="stylesheet" type="text/css" href="/css/index.css" />
  %
  % if ($s->{load_prototype}) {
  <script type="text/javascript" src="/js/prototype.js"></script>
  % } # $s->{load_prototype} end.
  %
  % if ($s->{javascript}) {
  <script type="text/javascript><!-- //
  <% $s->{javascript} %>
  // --></script>
  % } # $s->{javascript} end.
  %
  <% $s->{extend_header} %>
  </head>
---
filename: comp/body-header.tt
filetype: text
value: |
  <body>
  <div id="container">
  <div id="header">
  <a href="/" class="logo"><img src="/images/egg_logo.gif"></a>
  <div class="descript">
  The content of site is described.
  </div><!-- descript end. -->
  </div><!-- header end. -->
---
filename: comp/body-side.tt
filetype: text
value: |
  <div id="side_content">
  <div id="menu">
  <a href="/">Home</a>
  <a href="/sitemap">Site map</a>
  <a href="/contact">Contact</a>
  <a href="/help">Help</a>
  <!--
  
    Other menu links.
  
  -->
  </div><!-- menu end. -->
  <% $s->{side_content} %>
  </div><!-- side_content end. -->
---
filename: comp/body-footer.tt
filetype: text
value: |
  <div id="footer">
  <% $s->{footer_content_left} %>
   <a href="/">Home</a>
   &nbsp; | &nbsp;
   <a href="/Contact">Contact</a>
   &nbsp; | &nbsp;
   <a href="/sitemap">Site map</a>
   &nbsp; | &nbsp;
   <a href="/help">Help</a>
  <% $s->{footer_content_right} %>
  </div>
  </div><!-- container end. -->
  <div id="copyright">Copyright (C) <% $e->page_title %>.</div>
---
filename: comp/html-footer.tt
filetype: text
value: |
  </html>
---
filename: root/index.tt
filetype: text
value: |
  <%init>
  require Egg::Release;
  $s->{egg_version}   = Egg::Release->VERSION;
  $s->{example_code}  = $e->dispatch->_example_code;
  $s->{dispatch_class}= ref($e->dispatch);
  $s->{dispatch_class}=~s{\::handler$} [];
  $s->{side_content}= <<END_CONTENT;
  <ul>
  <li><a target="_blank" href="http://search.cpan.org/dist/Egg-Release/">Refer to CPAN.</a></li>
  <li><a target="_blank" href="$Egg::Release::DISTURL">Original distribution.</a></li>
  </ul>
  <img src="/images/egg224x33.gif" width="224" height="33" />
  END_CONTENT
  $s->{footer_content_left}= <<END_CONTENT;
  <img src="/images/egg80x15.gif" width="80" height="15" style="float:right" />
  END_CONTENT
  </%init>
  %
  <& /html-header.tt &>
  <& /body-header.tt &>
  <style type="text/css">
  div.pathinfo {
  	background: #FFF7E9;
  	margin:2px 25px 2px 10px;
  	padding:2px 2px 2px 7px;
  	font-size:14px;
  	border:#FF8F00 solid 2px;
  	}
  ul {
  	margin: 10px 2px 10px 30px;
  	text-align:left;
  	font:normal 10pt Times;
  	}
  ul a { color:#000 }
  </style>
  <div id="content">
  
  <h1>&nbsp; BLANK PAGE &nbsp;</h1>
  
  <p>
  <h2>Project name and version - <% $e->project_name %> - <% $e->VERSION || '0.01' %></h2>
  <div class="pathinfo">Request PATH: &nbsp; <b><% $e->request->path %></b></div>
  </p>
  
  <h3>Example of dispatch code. &nbsp; for <% $s->{dispatch_class} %>.</h3>
  <pre><% $s->{example_code} %></pre>
  
  </div><!-- content end. -->
  <& /body-side.tt &>
  <& /body-footer.tt &>
  <& /html-footer.tt &>
---
filename: root/sitemap.tt
filetype: text
value: |
  <%init>
  $e->res->is_expires('+1d');
  $e->res->last_modified('+1d');
  </%init>
  %
  <& /html-header.tt &>
  <& /body-header.tt &>
  <div id="content">
  
  <h1>&nbsp; Example of site map &nbsp;</h1>
  
  <ul>
  <li><a href="/">Home</a></li>
  <li><a href="/contact">Contact</a></li>
  <li><a href="/help">Help</a>
    <ul>
    <li>Hoge</li>
    <li>Fooo</li>
    </ul>
  </li>
  </ul>
  
  </div><!-- content end. -->
  <& /body-side.tt &>
  <& /body-footer.tt &>
  <& /html-footer.tt &>
---
filename: root/contact.tt
filetype: text
value: |
  <%init>
  # ------------------------------------------------
  my $subject= 'Inquiry';
  my $to_addr= 'to_addr@mydomain.com';
  # ------------------------------------------------
  $e->response->no_cache(1);
  my $check= sub {
  #
  # > If you load 'Egg::Plugin::Net::Scan'.
  #	my $scan= $e->port_scan(qw/ localhost 25 /);
  #	return 0 if $scan->is_success;
  #	$s->{complete}= "The mail server is stopping now.";
  #
    };
  my $exec= sub {
  	return 0;
  #
  # > If you load 'Egg::Plugin::Tools'.
  #	$e->referer_check(1) || return 0;
  #
  # > If you load 'Egg::Plugin::SessionKit'.
  #	$e->ticket_check || return 0;
  #
  	my $pm= $e->request->params;
  	$pm->{nickname} ||= 'N/A';
  	$pm->{email}    ||= 'none@localhost';
  	$pm->{mailbody} ||= 'N/A';
  #
  # > If you load 'Egg::Plugin::MailSend'.
  #	$e->mail->send(
  #	  to=> $to_addr, from=> $pm->{email},
  #	  subject => $subject, body=> <<END_MAILBODY
  #	  );
  # Email : $pm->{email}
  # NickName : $pm->{nickname}
  # $pm->{mailbody}
  #END_MAILBODY
  #
  	$s->{complete}= 'Mail was transmitted.';
    };
  my $form= sub {
  #
  # > If you load 'Egg::Plugin::SessionKit'.
  #	$e->request->param( ticket=> $e->ticket_id(1) );
  #
  # > If you load 'Egg::Plugin::FillInForm'.
  #	$e->fillin_ok(1);
  #
    };
  $check->() || $exec->() || $form->();
  </%init>
  %
  <& /html-header.tt &>
  <& /body-header.tt &>
  <div id="content">
  
  <h1>&nbsp; Example of Contact &nbsp;</h1>
  
  % if ($s->{complete}) {
  %
  <h2><% $s->{complete} %></h2>
  %
  % } else {
  %
  <form method="POST" action="<% $e->request->path %>">
  <input type="hidden" name="ticket" />
  
  <h2>Your name.</h2>
  <input type="text" name="nickname" id="nickname" maxlength="100" style="width:80%" />
  <h2>Your Email address.</h2>
  <input type="text" name="email" id="email" maxlength="100" style="width:80%" />
  <h2>Mail content</h2>
  <textarea name="mailbody" id="mailbody" style="width:80%;height:100px"></textarea>
  <p><input type="submit" value="Contact" /></p>
  </form>
  %
  % } # $s->{complete} end.
  %
  </div><!-- content end. -->
  <& /body-side.tt &>
  <& /body-footer.tt &>
  <& /html-footer.tt &>
---
filename: root/help/index.tt
filetype: text
value: |
  <%init>
  $e->res->is_expires('+1d');
  $e->res->last_modified('+1d');
  </%init>
  %
  <& /html-header.tt &>
  <& /body-header.tt &>
  <div id="content">
  
  <h1>&nbsp; Example of Help page &nbsp;</h1>
  
  <ul>
  <li><a href="/help">Help</a>
    <ul>
    <li>Hoge</li>
    <li>Fooo</li>
    </ul>
  </li>
  </ul>
  
  </div><!-- content end. -->
  <& /body-side.tt &>
  <& /body-footer.tt &>
  <& /html-footer.tt &>
---
filename: htdocs/favicon.ico
filetype: bin
value: |
  iVBORw0KGgoAAAANSUhEUgAAABAAAAAQBAMAAADt3eJSAAAAMFBMVEX///+BgYGRkZFkZGRERESq
  qqqbm5vq6urm5eXf39/T09P4+Pi2trbIyMgeHh4AAADzKT/kAAAAYUlEQVQImWNgwAsYhZQdQDRr
  ekfnYhBDYvdu7jlAIebbQA73AwYGW5BoxwcGBp8CBgaO+wsYGJ6u6Ojozb/AwHA/t+Na/p8NDAyt
  39Ly/54GquM6//9XFNjgVRWrNmCzEADJgh27oQZ5dwAAAABJRU5ErkJggg==
---
filename: htdocs/images/egg_logo.png
filetype: bin
value: |
  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
  ZQAAAABJRU5ErkJggg==
---
filename: htdocs/images/egg_logo.jpg
filetype: bin
value: |
  /9j/4AAQSkZJRgABAgAAZABkAAD/7AARRHVja3kAAQAEAAAAMgAA/+4AIUFkb2JlAGTAAAAAAQMA
  EAMDBgkAAAS1AAAJEgAADGD/2wCEAAgGBgYGBggGBggMCAcIDA4KCAgKDhANDQ4NDRARDA4NDQ4M
  EQ8SExQTEg8YGBoaGBgjIiIiIycnJycnJycnJycBCQgICQoJCwkJCw4LDQsOEQ4ODg4REw0NDg0N
  ExgRDw8PDxEYFhcUFBQXFhoaGBgaGiEhICEhJycnJycnJycnJ//CABEIAEkA7AMBIgACEQEDEQH/
  xADRAAACAgMBAQAAAAAAAAAAAAAAAwQHAgUIAQYBAQEBAAAAAAAAAAAAAAAAAAABAhAAAAYBAwEH
  AwUAAAAAAAAAAAECAxMFBBARBhIgMDMVNgcXQDEiUGAjFBYRAAIBAgMEBgUKAwkAAAAAAAECAwAR
  MRIEIZEyE0FRYSJyBRAgYoMUMHGBobHSI5OzNcFCUkCSsjNDYyQ0FRIBAAAAAAAAAAAAAAAAAAAA
  YBMBAAIBAgYBBQEBAQAAAAAAAQARIfAxEEFRcdHhYSAwgZGhQGCx/9oADAMBAAIRAxEAAAC9/R4g
  eCByzExwhoqTSx4IH/Pm5KLxL2M2CB4IHggeCB4IHhHJEIc9DwXks98b4RlPTCVtTluMku2K/sCv
  zkntfiju4d8P91xMXPbtW3OaOpPnYRfH1wAAAAQpsIc9DxOOUeJeKgFerMMU55bn1Ltiv7Ar85J7
  G45vIv7gbv7ig683nNH35Sd0fBa06rOfOgwAAAIU2EOeh4jXbaPEb3BMZa6ZlLptpLlmcjHWbm10
  NeeGuX9/8+Wn8VqnnyNi6Rx9TUthaU9s6ukll+Vk8sc1uyCFNhDMnggeEfySEYkhH9eCB4IHggeC
  B4IHggeCB4IHggeEfGUH/9oACAECAAEFAf1Hb6r/2gAIAQMAAQUB/Zf/2gAIAQEAAQUB/JaoxGIx
  GIxGIxGIxGIxGIxGIxGIxGIxGIxGIxGIxGIxGoSfg32N9gaxIYlUCfCVJUWt3Z+T1h+5X8afcxJq
  QtLiO9b1MxsNgZA9NzSaT6i05t6YPwGKqsNhKUpTyHlGJx8N+46HV4D+Xks29rjU2D8lsCmts22R
  229DPYi0MGD0UGi2b05t6YPwMfwByCwVZ3HAqFrGwx7i2CnrLg1C3aZvcN6OfYhuDMGD0JPWvXm3
  pg/AZ5HQkyszNoU3R5QOZdX+l9u+jyPuG9F/YjG430MLcJIaWEnvrzb0wfgYHHOJsPkZGXIa9VXc
  VfIsxfF+BZ+Zn13uJXqZsuF3p1j/ABCzt8jkXbb0WDM0GTiTHUQU+gg5kLUCSozaSYRrc1ibit+N
  mOj40YCCJtPIuMYnIC+NGBx2gRx/GuKzFt8D40YFDw5uiz9NyLst6GFI3BsiAQCAEyEt7AiFljHl
  4B1Ns81k06l49mm58pyn7ojdw7V9vITeG2zi2hqxWL1xvJwsvOp8tjkDbL+LeSqTyVOTDyVDGTh3
  jzOBL/T13jVM2JWxK2JGhI0OtoSNCRoStiVsTNiZsTNiZsTNiZsTNiZsTNiZsTNiZsTNiZsTNiZs
  TNiVIjV0fXf/2gAIAQICBj8BF//aAAgBAwIGPwEX/9oACAEBAQY/ASAbKMTXG2+uNt9cbb64231x
  tvrjbfXG2+uNt9cbb64231xtvrjbfXG2+uNt9cbb64231xtvrjbfXG2+uNt9cbb64231xtvrjbfX
  G2+uNt9cbb67rm/btrNbvYW7afxH1dgrCuiu8N1XX1J/MuVzuTl/DzZb5nVOKzf1dVB//MxJFuf1
  W/2u2gG8sst9p599nzcqlkQ3RwGU9YO0H5X3lP4j6bD1swoMOn0673X60dJ43+xKjJ0UHCP9JOr5
  qCqLKNgAwA6hUSSIZ9RLtEKm1k/qJ29NLFF5ZI8jmyoslySegAJXN1el+EY8MZcO1vasABUmu1XC
  uxEGLucFFftz/mj7tDUSeXNpNMwukkknebqITKDbt9f3lP4j8ko7PTrvdfrR0njf7EqLwL9no1er
  JupcpF4E7q/UKHnE631OovyL/wAkeFx2t9noh8uU/h6ZM7D25Nv+G1PrdUubTaS1kODyHaL9i47v
  kPeU/iPo+n18vR0+prvdfrR0njf7EqMHzGAEKLjOOqmaPaSpKW+bZ6NBy+D4eLLbwD0a/PjdN3LS
  31VJl4viHz/3U/h8h7yn8R+Qt0+rrvdfrR0njf7EqDVS+dQy5CrmF5YQCRtse911cbQcDWq0pFlz
  l4u1H7y/Vsqfy3SSiLXaMFlkLWY6cXduX7S4W6q1Mmtned1myq0huQMqm22ofMVH4WpTIx9uPZ9a
  2qfROVC6sfgmQ2QTgHJmPQGwJqfR+Yat5hGkoZCxKZ1YDYPX95T+I+nsrGsaxqybB1+tN5c0nKE2
  X8QC9srq+Gz+mgn/AKD7CT/ljpt7XZX7i/5Q+9SR3wFh9FRNI5gnh2CZRe6n+UjZ04V+4v8Alj71
  S6ZJzPzX5mYrltsC2xPVUmi1exG2rJ0owwYXr9xf8ofeo65dW05KNHlKZeIg3vc9Xp2+p7yn8R+T
  1GnTjdDyz1ONqH6GArV8+I/8jTanVCPMDbV6lDCIR4U2VDHFon5YM+ZfhtKGVnWMK4jUpH/LsbGt
  ImkVl1ll55hIOUiM3tndMwz+1215jLG04+GjfO3c5QtoVkAQcXM57X2C1OWjlcBdSunGoMbSZXWH
  KHykrtdXt2VOIxqeeZj3wYjFy87ZDCmdGNktcEihJqY5WnmXy+SUkxmINHJDz+7fYwsTsHzVy9S8
  0d3g5r5o82bv/EGIre0Z7uW+2tHpdXmabPAdVw3IVhnLdHbUTaRpmmaSZpBdCECv+CoUsgylOnb8
  xqWWKecf9l44wyZcyyR/DLYjAoWNa+QZ2VC0mmj7nLcJKjRoGz370V1Pd/hTCd5JCknLvAYw7oEd
  lkXPYC8jqG+bqqaTOTqxNpvh0YjkDKkDPJYbdkmeoecJBLl/EExBfN03K7N3p95RvwnbfqrGsaxr
  GsaxrGsaxrGsaxrGsaxrGsaxrGsaxrGsaxrGsaxru949Qr275vp/t/8A/9oACAECAwE/EONy/vP+
  Dn9xJmZh/qf/2gAIAQMDAT8Q/wCL/9oACAEBAwE/EFUzaDdeYM1fSavpNX0mr6TV9Jq+k1fSavpN
  X0mr6TV9Jq+k1fSavpNX0mr6TV9Jq+k1fSavpNX0mr6TV9Jq+k1fSavpNX0iGaLa1Jf5jn/hNV2+
  hG5qUcyPJER5f1EP/VX/ABlqLOfU7/Rpx7lFZRT+n9q7vqlRTAOwtlKLrpcPEQewKHcfvdV245f2
  ML5jwAiQu2k/vwwdkAT8/T5wSRV1UVRILygwAKAMAEJsRMsLFxQRRjOekHigwsoQKsGYfbVC90Pi
  2JAtPOI79r8FvLhhrsCEhVhWHVXxf2Oq7cLh58uE+gM5oz29H95+nzhpHRwbkKLsGrO9j8rAPlFG
  2vcJd/Dq8EoVwuHeJ8CndhTms25D1AWOvRc2wfY6rtwWPZFDhFFGVHIz29PzB6fT5wJNGl4gs3j8
  2gytbI4VHXsyuHz5s70uE5W5JveO/wBPs9V24Zs/UvB68LKxTfwvl07wwo3cr1ZS+nzge5J0ildq
  Nxz2gJwFhkR5kWeLNYVadlb5GIY21cxQb/dL5SzYsOJh5LY8WmMwbR7lOzNt4XagrbachiDe1cF6
  1FDdY2+x1XbgLItat7k2EdnDEy0H5nUvaXAf0S8Nqw1XAgQ4Mez4HzSbXhvFMev96prh4c5SdmFC
  F1LVpCXlLmxuyxnrAMgcu9IMC0JLaCJLawSjctzH9LOctyQLRzhhyA41oKC0C8Zdj6eq7cBcHkhv
  KPwlekD0hnKBySiYvj+kv3Qjbunhe4efltnfeGp7qM/SZZKp0qUjEWUWBsUW4brLIuFSiTGHKhfA
  s+IFUKhDtysdi5SZQjDYrGHme1SLpZUWnpPtG6rqWd5cEOzLZQ5sEF2vlhjoF6C1G82f+gsVK1dq
  1lGItxthoKG8hc1nkRgcINY3hSLTKq3kAt522du6CurxaydTE3PAbZ2MGZURoFBijz9uTArkbfRs
  0K9Bmzvc0R8TVHxNcfE1R8TRHxNUfE0R8TVHxNcfE1R8TRHxNEfE0R8TRHxNEfE0R8TRHxNEfE0R
  8TRHxNEfE0R8TRHxNEfE0R8TRHxNEfEduybAzqfwa/3v/9k=
---
filename: htdocs/images/egg_logo.gif
filetype: bin
value: |
  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
---
filename: htdocs/images/egg468x60.gif
filetype: bin
value: |
  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
---
filename: htdocs/images/egg88x31.jpg
filetype: bin
value: |
 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
---
filename: htdocs/images/egg80x15.gif
filetype: bin
value: |
  R0lGODlhUAAPALMAACEhIfzKC/f28nt7e/2gHfvaZk9OTri4uJWVldjX1wcHBz8+Pmppaf2ANP//
  /+vr6yH5BAAAAAAALAAAAABQAA8AQAT/sMlJq704682nS04ojqIAPgyCMiszLO8DL/JQ07jKsLSr
  PgoF4AFUsB4AIXHpkJAEhYC0ICA5ltisdsvlBofdbLNhLZPC6PQytQy6i0Gk+zg226/qvHow2P3Q
  dQ4CD1BShlRMVwwGBjZ6Wws6R1pfRAxBBw8HQZMPdYMJCYRVgg+hBwlVK5arM0SROK8IsZGtKAZt
  c18GCgucAD9jHcPExcYVd8nKy8zNIk7OeI/TlG4KaoEiUYYBVKQh1OFYlURuuEm9mZ5OhCGFBAQF
  nqWeKAgHKYwPuLGM/Lj+ZDCotUifih/kyPm6hqUOkW9lTJxYhCABix0tePSR8WpjDlsGOhiomzMg
  iIEDB5KAYQKtVAKUMFGlErFK04KTHGmgWMDDEs99A3UwOqITjqUgvjb1MkIkW7SnUKM2iQAAOw==
---
filename: htdocs/images/egg125x125.gif
filetype: bin
value: |
  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
  +LgdSRWP+5gDRNUxQzWQBFmQPSUBEQAAOw==
---
filename: htdocs/images/egg224x33.gif
filetype: bin
value: |
  R0lGODlh4AAhALMAANDQz2VlZfj497OyrISDg+vr6Dk5OfHx78XEw6SjoOLi4JaVk9vb2by8ugAA
  AP///yH5BAAAAAAALAAAAADgACEAQAT/8MlJq7046827/2AojmTpCahwrGuhFCJCyAhDLAQz5HOy
  yDiBrEcgJB6J20xSxBUIDZlpSt0QHFisAQFgeAsCCa5Ivk0U5bICdPikWK0DoEqv2++Ya9ZhALQn
  ew4BCDATelkNDH8gKgUMCGspkpIHDD4LCwkJA1wKB0JZhwEABoINpIIBfAxhWAtYCK6upQG0qgav
  DrEOuQqyuq4JsL8LtLSsV31YBKi5xYLGqXy3uXxYAc7DDsyl3ayGgbiZCQAoqnsGDNePgdt6hHjx
  8vP09fb3+Pn6VIftvPsSwnR4A6eAi0UcZDCQIGMHggNFhgBIsqOAwgc3cCCZsQTjgh3I/6AAxNeP
  jx8KB9otiOJJQEkDA06BAbFwAyU4chgY/PRAVa1fqAYFvaUgTDc+ArRgGXDUHZ9cDI4GEHAUlxY9
  DG5hKdCUgNFlWQwk21oq7LIGSgmUQlBKnQNf1gw8CEsLC08m/rIseFBWS1EKwvYkQBgCxQEXXgAo
  RsC4cWPFXl6sEPhATqdHAApUYtxlcacwlRRDRnCqiwIAURQrOJ0482nFmhmIBqBAdmfXol/Itl1U
  AOvXml9D3g1ZtSPIBiEDD20cdujEMx8IeNSguvXqNcJMJ309yrcCALhfPzmyvPnz6KkQbKGZcowm
  hKfYQMDkSHqS7QLoD0Dg7/0K67G3Gv8IQCQgBEdcGJEJAQMkoYlFzGBkxBFJzFefQg2M8x8eL5E3
  QUrtDMBASyUJ8oV7G8SXQYCHuYDihhIksYCKMJbQIULnZJEAJALBlUUAp9CogQCFcMDiYTVJUEoS
  SGERVRZM7bEXCcmwZcCLFhjQBylXepDMAljaU4pXFtxIQSA5uNfPFkUyssJCkgQ0CRxENhhTF+2N
  VRVbWXC1xyhtDPCTAwCAxUs0+j2lDSYLWDJoodvksosziBZV5TUIJDDoMz91uqZWgijKi5OY9rWA
  hyXuR04B1VxzQFkEvBoIA2jZFSaAKtSGGicjrkZrg5oEu0lMNbyQQhZ88vLkMn1tcxL/qLt0w2dZ
  moqKwAA6AgDtOe8EJgifnSJjkisKvFIWp4hqq8Up1+TCzCE/kGvLNouUuEesKthrYiXN7gFPYYax
  Z9DAA7OQQj0q3JXwrTXmM8nD7kGMwgQSM9zwxRhnrPHGHD/QQBppCNnxyCSHoK8WIusDMQsEW4xB
  Q0s8spBiB9TwyAPhtfGII0IgABpjHRlBs80PlfzBSzFh902NRyIWggxJAE0DDQpqwmAOEmVEwEYW
  YrRjDprsYPTR4WQWJxL+DCJQv0+1WQeLA/vXwUUPUF3DDT4QMRGECxnRAIU80Oe1QgBMOLaXZRNW
  4o60HZZfatGdcELALB/0Ad0H4GCg/4Q25MCqSBcVHiHUQTMaBg6CH25F4hS0agqPSgaSQCIpX+Ay
  xZSzl6TqvIODjod8oUP7BN66QsjtFbgwee6HvWBIfx/vVUS5ZFBfRAMmRI/G1h9sDwIO2I8E/gVm
  AnIv8GvCPoLbGNwEhx8TB68WH4Ep0M0MY97yhwK1jMIXLmLBiFj0AxE+NEBLBulfG/hngFHUKgBM
  MUACGzgHtRCAgLELQAK0hAOINPAIFtQP/wLQhg0GUEsCFKBiahGr/+FgTGoJH17Q8ZHqrCEQAZAb
  RgIBPDc8wBPSad+RSGMcFCQDVnxIVjqaxYw2YCEwBfjFBqHhFKsQ6olbweJblpELSP8FZoo/aeGl
  tLCkJ0ZjfkWYBh/K6IAvajGKZAyFInznDwN4IkdYKMcBceGWH8GgFnI5wWEyI52KGUwOPghbJz6B
  rbrQIig1mFc6wgAtQ6FLGlbcxQVH0RRNBkaTs6BiAMSljG0gAFSX7NQt9qMVLYnqHctIlokogzTs
  +MFHoShLDkuin7LM0UhIQk05VuaIATAqWHfSySeSspRzLWsb3ejGSa6hjXM1JVGZVIodqQkMQUhK
  KW1EFCkh1Z+6HEqUtNADLbClRkGwsyyatB8Vy0FHf3Cvj2Yx0RPaAU/2ta95tiHNAAZK0IImjTMj
  ao8ELMIr1EACPNVZTBSI2IaaRSGrCrGMAi0eEx7PyGaitCGNSKmjGO841KRcYAwrttMFxrwgPCJd
  DExnSh2V1hQ1iVCASLnwiId2lAtF2gErh7qA3hRgqPtJ0wEEhdRB+HNFCTOIr7xA1aquZifLpEAj
  PnGYZbaocgqVAMsGSRvNPKc9CTPYVinXHpx4Fa04EcjCJiOdOLhVrWtN68IMA1ev0olijqiqYKNz
  gNoIVifaCaxgdQiwik2id5CtUQQAADs=
