package Egg::Release;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Release.pm 342 2008-05-29 16:05:06Z lushe $
#
use strict;
use warnings;

our $VERSION = '3.14';

our $DISTURL = 'http://egg.bomcity.com/';


1;

__END__

=head1 NAME

Egg::Release - Version of Egg WEB Application Framework. 

=head1 DESCRIPTION

Egg is MVC framework that is influenced from L<Catalyst> and developed.

I want you to see the document of L<Egg> in detail.

=head1 TUTORIAL

It introduces the example of making the tinyurl site as a tutorial.

Tinyurl registers long URL beforehand, and is the one to call and to redirect
URL that corresponds by the thing accessed specifying the registration ID for
URL that is.

=head2 project

First of all, a suitable project is made.
It generates it here as 'MyApp'.

  % egg_helper.pl project MyApp -o/path/to

* 'egg_helper.pl' is a helper script generated beforehand.
 Please look at the document of Egg about the making method.

The authority of the directory is set.

  % cd /path/to/MyApp
  
  % chmod 777 cache tmp
  
  or
  
  % chown webserver cache tmp
  
  The access authority from the WEB server is set.

=head2 Model

L<Egg::Model::DBI> is used for the model. And, SQLite is used for DBD.

The data base is '/path/to/MyApp/etc/myapp.db'.

The table is prepared as follows.

  CREATE TABLE tiny_url (
    id text primary key,
    url text
    );

Please do not forget to make it read and write by the authority of the WEB server.

And, the configuration of the model is done.

  % vi /path/to/MyApp/lib/MyApp/config.pm
  
  MODEL => [
    [ DBI => { dsn=> 'dbi:SQLite;dbname=<e.dir.etc>/myapp.db' } ]
    ],

It is a description of the replace function of <e.***> Egg because to use it.

Please see at the document of L<Egg::Util> in detail. 

=head2 View

L<Egg::View::Mason> is used for the view.

Then, the configuration of the view is done.

  % vi /path/to/MyApp/lib/MyApp/config.pm
  
  VIEW => [
    [ Mason => {
      comp_root=> [
        [ main   => '<e.dir.template>' ],
        [ private=> '<e.dir.comp>' ],
        ],
      data_dir=> '<e.dir.tmp>',
      } ],
    ],

=head2 Controller

The following plugins are used.

  Egg::Plugin::ConfigLoader
  Egg::Plugin::Tools
  Egg::Plugin::Filter
  Egg::Plugin::FillInForm
  Egg::Plugin::EasyDBI
  Egg::Plugin::Mason

Then, the controller is changed to the following feeling.

  % vi /path/to/MyApp/lib/MyApp.pm
  
  use Egg qw/ -Debug
   ConfigLoader
   Tools
   Filter
   FillInForm
   EasyDBI
   Mason
   /;

'Egg::Plugin' part of the module name is omitted and described like this.

For instance, when an original plugin such as 'MyApp::Plugin::Hoge' is loaded,
the full name is specified putting '+' on the head.

  use Egg qw/ -Debug
   .....
   +MyApp::Plugin::Hoge
   /;

=head2 Dispatch

As for dispatch, MyApp::Dispatch is usually used.
To change this, the module name is set to environment variable 'MYAPP_DISPATCH_CLASS'.

Then, dispatch is changed to the following feeling.

  % vi /path/to/MyApp/lib/MyApp/Dispatch.pm
  
  MyApp->dispatch_map(
  
  _default => sub {},
  
  r => sub {
    my($e)= @_;
    my $id= $e->snip->[1] || return $e->finished('403 Forbidden');
    my $url= $e->db->tiny_url->scalar('url', 'id = ?', $id)
                          || return $e->finished('404 Not Found');
    $e->response->redirect($url);
    },
  
  );

'_default' specified '/index.tt' when writing so. 

In the code when you want to specify a suitable template

  _default => sub {
   my($e)= @_;
   $e->template('/top-page.tt');
   },

It specifies it by feeling.

The registration of URL is accepted in this 'index.tt'. 

And, 'r' is a place accessed by registration ID.

  http://ho.com/r/abc12

It is a setting that assumes URL.

If it is usual dispatch.

  r=> {
    abc12 => sub {},
    },

Then, because the part of abc12 cannot be specified in the specification of this
tutorial, the template cannot be prepared beforehand though r/abc12.tt is
recognized as a template.

Therefore, 'r' makes for the code reference, and acquires registration ID in that.

Besides, it is sure to go as follows well.

  r=> {
   _default=> sub { $_[0]->finished('403 Forbidden') },
   qr{^([a-f0-9]{5})$}=> sub {
     my($e, $d, $s)= @_;
     my $url= $e->db->tiny_url->scalar('url', 'id = ?', $s->[0])
                           || return $e->finished('404 Not Found');
     $e->response->redirect($url);
     },
   },

This is an example of acquiring the match character string by using the regular
expression for dispatch.
In this case, I think that the processing when the request is put right under 'r'
is also necessary.
When this is omitted, top '_default' obtains it.
It only has to use both favors.

The following contexts are passed for the code reference of dispatch as an 
argument.

  1. Object of project.
  2. Object of dispatch handler.
  3. When the regular expression is used, the matched character string is listed.

There is data to divide request URI by '/' in $e->snip. The element of 0 of this
data is 'r', and the element of one is sure to have registration ID.
If ID cannot be acquired, all Forbidden is returned and processing is ended.

   my $url= $e->db->tiny_url->scalar('url', 'id = ?', $id)
                         || return $e->finished('404 Not Found');
   $e->response->redirect($url);

It looks for corresponding URL from the data base by this code, and it redirects
it to acquired URL.

=head2 Template

'index.tt' that exists in '/path/to/MyApp/root' is edited as follows.

  % vi /path/to/MyApp/root/index.tt
  
  <%init>
  my $ms= $e->mason->prepare(
    page_title=> 'TineURL',
    );
  my $req= $e->request;
  $ms->code_action(sub {
    $e->referer_check(1) || return 0;
    my $mode= $req->param('mode') || return 0;
    return 0 unless $mode eq 'regist';
    $e->filter( url => [qw/ hold hold_html uri /] );
    my $url= $req->param('url') || return $e->error('URL is enmpty.');
    $url=~m{^https?\://.+} || return $e->error('Format error of URL.');
    my $turl= $e->db->tiny_url;
    $turl->scalar('id', 'url = ?', $url)
           and return $e->error('It has registered.');
    $turl->find_insert( id=> $e->create_id(5), url=> $url )
            || return $ms->error_complete('SYSTEM-ERROR', 'Failure of registration.');
    $ms->complete('Complete', <<END_INFO);
  <a href="/">Please click.</a>
  END_INFO
    });
  $ms->code_entry(sub {
    $req->param( mode=> 'regist' );
    $e->fillin_ok(1);
    });
  $ms->exec;
  </%init>
  %
  <& /html-header.tt &>
  <& /body-header.tt &>
  <div id="content">
  %
  % if ($ms->is_complete) {
  %
   <h2><% $ms->complete_topic %></h2>
   <p><% $ms->complete_info %></p>
  %
  % } else {
  %
  % if (my $error= $e->errstr) {
   <div id="warning"><% $error %></div>
  % } # $e->errstr end.
  <form method="POST" action="<% $req->path %>">
  <input type="hidden" name="mode" id="mode" />
  URL : <input type="text" name="url" id="url" maxlength="300" size="50" />
  <input type="submit" value="REGIST" />
  </form>
  %
  % } # $s->{complete} end.
  %
  </div><!-- content end. -->
  <& /body-side.tt &>
  <& /body-footer.tt &>
  <& /html-footer.tt &>

Please look at http://www.masonhq.com/about the grammar of L<HTML::Mason>.

$e-E<gt>mason is a method that L<Egg::Plugin::Mason> makes available.
This object is acquired from the prepare method of $e-E<gt>mason.

  # Bad code.
  my $m= $e->mason->prepare(
     .....

I think that this moves actually well like this though it is time when it uses '$m'.
However, the object of L<HTML::Mason> is not set in '$m' as a global value and
do not use '$m' so as not to cause confusion, please.

The code registers the following two kinds.

  1. code_action ..... Action when registration button is pushed.
  2. code_entry  ..... Code for access usually.

'code_action' decides whether to check first of all and to process 'HTTP_REFERER'
and 'REQUEST_METHOD'.  And, it registers in the data base through the input check etc.

'code_entry' doesn't have the so much work.  Processing is only added deflecting
because the value of mode is checked with 'code_action'.  If mode is not checked,
'code_entry' becomes there is no necessity.

And, a series of processing is done with $ms-E<gt>exec.

The part of the HTML source especially omits explaining.

=head2 Confirm

It confirms the operation when the above-mentioned work is finished.

First of all, 'bin/trigger.cgi' is stricken from the console.

 % cd /path/to/MyApp/bin
 % perl trigger.cgi

It deals at the right time if the error occurs by this.

The work file of L<HTML::Mason> is temporarily deleted if normally displayed.

  % rm -rf /path/to/MyApp/tmp/*
  
  # It is also good to change the owner.
  % chown -R webserver /path/to/MyApp/tmp

Because this tutorial explains the method of constructing the application, the
method of setting these is omitted only though it is made to set 'mod_perl' and
'FastCGI' and to display by a browser now. Please see at the document of L<Egg>
in detail.

Perhaps, if 'trigger.cgi' normally returns contents when the error is returned
by displaying a browser, the problem concerns the setting and the authority, etc.
Please adjust and try these.

=head2 End

If the application is added to the project further, it is a translation that
adds the plugin to the controller, registers the code in dispatch, and makes the
template.

Egg - The project production that uses the MVC framework is advanced based on the
above-mentioned work.

=head1 SEE ALSO

L<Egg>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

