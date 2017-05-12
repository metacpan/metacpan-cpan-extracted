package LaTeXML::Plugin::LtxMojo;
use Mojo::Base 'Mojolicious';
use Mojo::JSON;
use Mojo::IOLoop;
use Mojo::ByteStream qw(b);

use File::Basename 'dirname';
use File::Spec::Functions qw(catdir catfile);
use File::Temp qw(tempdir);
use File::Path qw(remove_tree);

use Archive::Zip qw(:CONSTANTS :ERROR_CODES);
use IO::String;
use Encode;

use LaTeXML::Common::Config;
use LaTeXML::Util::Pathname qw(pathname_protocol);
use LaTeXML;
use LaTeXML::Plugin::LtxMojo::Startup;

our $dbfile  = '.LaTeXML_Mojo.cache';

# Every CPAN module needs a version
our $VERSION = '0.4';

# This method will run once at server start
sub startup {
my $app = shift;
# Switch to installable home directory
$app->home->parse(catdir(dirname(__FILE__), 'LtxMojo'));

# Switch to installable "public" directory
$app->static->paths->[0] = $app->home->rel_dir('public');
# Switch to installable "templates" directory
$app->renderer->paths->[0] = $app->home->rel_dir('templates');

$ENV{MOJO_MAX_MESSAGE_SIZE} = 107374182; # close to 100 MB file upload limit
$ENV{MOJO_REQUEST_TIMEOUT} = 600;# 10 minutes;
$ENV{MOJO_CONNECT_TIMEOUT} = 120; # 2 minutes
$ENV{MOJO_INACTIVITY_TIMEOUT} = 600; # 10 minutes;

# Make signed cookies secure
$app->secrets(['LaTeXML is the way to go!']);

#Prep a LaTeXML Startup instance
my $startup = LaTeXML::Plugin::LtxMojo::Startup->new(dbfile => catfile($app->home,$dbfile));

# Do a one-time check for admin, add if none:
$startup->modify_user('admin', 'admin', 'admin')
  unless $startup->exists_user('admin');

$app->helper(convert_zip => sub {
  my ($self) = @_;
  # Make sure we point to the actual source directory
  my $name = $self->req->headers->header('x-file-name');
  $name =~ s/\.zip$//;
  # HTTP GET parameters hold the conversion options
  my @all_params = @{ $self->req->url->query->params || [] };
  my $opts=[];
  # Ugh, disallow 'null' as a value!!! (TODO: Smarter fix??)
  while (my ($key,$value) = splice(@all_params,0,2)) {
    if ($key=~/^(?:local|path|destination|directory)$/) {
      # You don't get to specify harddrive info in the web service
      next; }
    $value = '' if ($value && ($value  eq 'null'));
    push @$opts, ($key,$value); }

  my $config = LaTeXML::Common::Config->new();
  $config->read_keyvals($opts);
  my @latexml_inputs = ('.',grep {defined} split(':',($ENV{LATEXMLINPUTS}||'')));
  $config->set('paths',\@latexml_inputs);
  $config->set('whatsin','archive');
  $config->set('whatsout','archive');
  $config->set('log',"$name.log");
  $config->set('local',($self->tx->remote_address eq '127.0.0.1'));
  # Only HTML5 for now.
  $config->set('format','html5');
  # Prepare and convert
  my $converter = LaTeXML->get_converter($config);
  $converter->prepare_session($config);
  my $source = $self->req->body;
  $source = "literal:".$source if ($source && (pathname_protocol($source) eq 'file'));
  my $response = $converter->convert($source);
  # Catch errors
  $self->render(text=>'Fatal: Internal Conversion Error, please contact the administrator.') unless
    (defined $response && ($response->{result}));
  # Return
  my $headers = Mojo::Headers->new;
  $headers->add('Content-Type',"application/zip;name=$name.zip");
  $headers->add('Content-Disposition',"attachment;filename=$name.zip");
  $self->res->content->headers($headers);
  return $self->render(data=>$response->{result});
});

  # TODO: Maybe reintegrate IF we support username-based profiles
  # if (!defined $opt->{profile}) {
  #   if (defined $opt->{user}
  #     && $startup->verify_user($opt->{user}, $opt->{password}))
  #   {
  #     $opt->{profile} =
  #       $startup->lookup_user_property($opt->{user}, 'default') || 'custom';
  #   }
  #   else {
  #     $opt->{profile} = 'custom';
  #   }
  # }

$app->helper(convert_string => sub {
  my ($self) = @_;  
  my ($source,$is_jsonp);
  my $get_params = $self->req->url->query->params || [];
  my $post_params = $self->req->body_params->params || [];
  if (scalar(@$post_params) == 1) {
    $source = $post_params->[0];
    $post_params=[];
  } elsif ((scalar(@$post_params) == 2) && ($post_params->[0] !~ /^(?:tex|source)$/)) {
    $source = $post_params->[0].$post_params->[1];
    $post_params=[];
  }
  # We need to be careful to preserve the parameter order, so use arrayrefs
  my @all_params = (@$get_params, @$post_params);
  my $opts = [];
  # Ugh, disallow 'null' as a value!!! (TODO: Smarter fix??)
  while (my ($key,$value) = splice(@all_params,0,2)) {
    # JSONP ?
    if ($key eq 'jsonp') {
      $is_jsonp = $value;
      next;
    } elsif ($key =~ /^(?:tex|source)$/) {
      # TeX is data, separate
      $source = $value unless defined $source;
      next;
    } elsif ($key=~/^(?:local|path|destination|directory)$/) {
      # You don't get to specify harddrive info in the web service
      next;
    } elsif ($key=~/^(?:preamble|postamble)$/) {
      $value = "literal:".$value if ($value && (pathname_protocol($value) eq 'file'));
    }
    $value = '' if ($value && ($value  eq 'null'));
    push @$opts, ($key,$value);
  }
  my $config = LaTeXML::Common::Config->new();
  $config->read_keyvals($opts);
  # We now have a LaTeXML config object - $config.
  my @latexml_inputs = grep {defined} split(':',($ENV{LATEXMLINPUTS}||''));
  $config->set('paths',\@latexml_inputs);
  my $converter = LaTeXML->get_converter($config);

  #Override/extend with session-specific options in $opt:
  $converter->prepare_session($config);
  # If there are no protocols, use literal: as default:
  if ((! defined $source) || (length($source)<1)) {
    $self->render(json => {result => '', status => "Fatal:input:empty No TeX provided on input", status_code=>3,
                           log => "Status:conversion:3\nFatal:input:empty No TeX provided on input"});
  } else {
    $source = "literal:".$source if ($source && (pathname_protocol($source) eq 'file'));
    #Send a request:
    my $response = $converter->convert($source);
    my ($result, $status, $status_code, $log);
    if (defined $response) {
      ($result, $status, $status_code, $log) = map { $response->{$_} } qw(result status status_code log);
    }
    # Delete converter if Fatal occurred
    undef $converter unless defined $result;
    # TODO: This decode business is fishy... very fishy!
    if ($is_jsonp) {
        my $json_result = $self->render(
  	  json => {result => $result, 
  		   status => $status, status_code=>$status_code, log => $log, partial=>1});
        $self->render(data => "$is_jsonp($json_result)", format => 'js');
    } elsif ($config->get('whatsout') eq 'archive') { # Archive conversion returns a ZIP
      $self->render(data => $result);
    } else {
      $self->render(json => {result => $result, status => $status, status_code=>$status_code, log => $log});
    }
  }
});


################################################
##                                            ##
##              ROUTES                        ##
##                                            ##
################################################
my $r = $app->routes;
$r->post('/convert' => sub {
  my $self = shift;
  my $type = $self->req->headers->header('x-file-type');
  if ($type && $type =~ 'zip' && ($self->req->headers->header('content-type') eq 'multipart/form-data')) {
    $self->convert_zip;
  } else {
    $self->convert_string;
  }
});

$r->websocket('/convert' => sub {
  my $self  = shift;
  my $json = Mojo::JSON->new;
  # Connected
  $self->app->log->debug('WebSocket connected.');
  # Increase inactivity timeout for connection a bit
  Mojo::IOLoop->stream($self->tx->connection)->timeout(300);
  $self->on('message' => sub {
	      my ($tx, $bytes) = @_;
	      #TODO: We want the options in the right order, is this Decode safe in this respect?
	      my $opts = $json->decode($bytes);
	      my $source = $opts->{source}; delete $opts->{source};
	      $source = $opts->{tex} unless defined $opts->{source}; delete $opts->{tex};
	      my $config = LaTeXML::Common::Config->new();
        $config->read_keyvals([%$opts]);
	      # We now have a LaTeXML options object - $opt.
	      my $converter = LaTeXML->get_converter($config);
	      #Override/extend with session-specific options in $opt:
	      $converter->prepare_session($config);
	      #Send a request:
	      my $response = $converter->convert($source);
	      my ($result, $status, $log);
	      if (defined $response) {
		      if (! defined $response->{result}) {
		      # Delete converter if Fatal occurred
		      undef $converter;
		      } else {
		        #$response->{result} = decode('UTF-8',$response->{result});
		      }
	      }
	      $tx->send({text=>$json->encode($response)});
	    });
  # Disconnected
  $self->on('finish' => sub {
	      my $self = shift;
	      $self->app->log->debug('WebSocket disconnected.');
	    });
});

$r->get('/login' => sub {
  my $self = shift;
  my $name = $self->param('name') || '';
  my $pass = $self->param('pass') || '';
  return $self->render
    unless ($startup->verify_user($name, $pass) eq 'admin');
  $self->session(name => $name);
  $self->flash(message => "Thanks for logging in $name!");
  $self->redirect_to('admin');
} => 'login');

$r->get('/about' => sub {
  my $self    = shift;
  my $headers = Mojo::Headers->new;
  $headers->add('Content-Type', 'application/xhtml+xml');
  $self->res->content->headers($headers);
  $self->render();
} => 'about');

$r->get('/demo' => sub {
  my $self = shift;
} => 'demo');

$r->get('/editor' => sub {
  my $self    = shift;
  my $headers = Mojo::Headers->new;
  $headers->add('Content-Type', 'application/xhtml+xml');
  $self->res->content->headers($headers);
  $self->render();
} => 'editor');

$r->get('/editor5' => sub {
  my $self    = shift;
  my $headers = Mojo::Headers->new;
  $headers->add('Content-Type', 'text/html');
  $self->res->content->headers($headers);
  $self->render();
} => 'editor5');

$r->get('/ws-editor' => sub {
  my $self    = shift;
  my $headers = Mojo::Headers->new;
  $headers->add('Content-Type', 'application/xhtml+xml');
  $self->res->content->headers($headers);
  $self->render();
} => 'ws-editor');


$r->get('/' => sub {
  my $self = shift;
  return $self->redirect_to('about');
});

$r->get('/logout' => sub {
  my $self = shift;
  $self->session(expires => 1);
  $self->flash(message => "Successfully logged out!");
  $self->redirect_to('login');
});

$r->get('/admin' => sub {
  my $self = shift;
  return $self->redirect_to('login') unless $self->session('name');
  $self->stash(startup => $startup);
  $self->render;
} => 'admin');

$r->get('/help' => sub {
  my $self = shift;
  $self->render;
} => 'help');


$r->get('/upload' => sub {
  my $self = shift;
  $self->render;
} => 'upload');

$r->post('/upload' => sub {
  my $self = shift;
  # TODO: Need a session?
  my $type = $self->req->headers->header('x-file-type');
  if ($type && $type =~ 'zip' && ($self->req->headers->header('content-type') eq 'multipart/form-data')) {
    $self->convert_zip;
  } else {
    #.tex , .sty , .jpg and so on - write to filesystem (when are we done?)
    $self->render(text=>"Uploaded, but ignored!");
  }
});

$r->any('/ajax' => sub {
  my $self = shift;
  return $self->redirect_to('login') unless $self->session('name');
  my $header = $self->req->headers->header('X-Requested-With');
  if ($header && $header eq 'XMLHttpRequest') {

    # Users API:
    my $user_action = $self->param('user_action');
    if ($user_action) {
      my $name    = $self->param('name');
      my $message = 'This request was empty, please resend with Name set!';
      
      if ($user_action eq 'modify') {
        if ($name) {
          my $pass    = $self->param('pass');
          my $role    = $self->param('role');
          my $default = $self->param('default_profile');
          $message = $startup->modify_user($name, $pass, $role, $default);
        }
      }
      elsif ($user_action eq 'add') {
        if ($name) {
          my $pass    = $self->param('pass');
          my $role    = $self->param('role');
          my $default = $self->param('default_profile');
          $message = $startup->modify_user($name, $pass, $role, $default); }
      }
      elsif ($user_action eq 'delete') { $message = $startup->delete_user($name) if $name; }
      elsif ($user_action eq 'startup_users') {
        $self->render(
          json => {
          users => $startup->users
        }
      );}
      elsif ($user_action eq 'overview_users') {
        my $users   = $startup->users;
        my $summary = [];
        push @$summary, $startup->summary_user($_) foreach (@$users);
        $self->render(json => {users => $users, summary => $summary});
      }
      else { $message = "Unrecognized Profile Action!" }
      $self->render(json => {message => $message});
    }

    # Profiles API:
    my $profile_action = $self->param('profile_action');
    if ($profile_action) {
      my $message =
        'This request was empty, please resend with profile_action set!';
      if ($profile_action eq 'startup_profiles') {
        $self->render(
          json => {
            profiles => [@{$startup->profiles}]
          }
        );
      }
      elsif ($profile_action eq 'select') {
        my $pname = $self->param('profile_name');
        $self->render(json => {message => 'Please provide a profile name!'})
          unless $pname;
        my $form  = $startup->summary_profile($pname);
        my $lines = 0;
        $lines++ while ($form =~ /<[tb]r/g);
        my $minh = "min-height: " . ($lines * 5) . "px;";
        my $message = "Selected profile: " . $pname;
        my $json = Mojo::JSON->new;
        open TMP, ">", "/tmp/json.txt";
        print TMP $json->encode(
          {form => $form, style => $minh, message => $message});
        close TMP;
        $self->render(
          text => $json->encode(
            {form => $form, style => $minh, message => $message}
          )
        );
      }
      else {$self->render(json => {message => "Unrecognized Profile Action!"});}
      $self->render(json => {message => $message});
    }
    # General Actions API:
  }
  else {
    $self->render(text => "Only AJAX request are acceptexd at this route!\n");
  }
});

}
1;

__END__

=pod

=head1 NAME

C<ltxmojo> - A web server for the LaTeXML suite.

=head1 DESCRIPTION

L<ltxmojo> is a Mojolicious::Lite web application that builds on LateXML to provide
on demand TeX to XML conversion as a scalable web service.

The service comes together with a collection of convenient interfaces, conversion examples,
as well as an administration system for user and transformation profile management.

=head1 ROUTES

The following routes are supported:

=over 4

=item C< / >

Root route, redirects to /about

=item C</about>

On HTTP GET, provides a brief summary of the web service functionality.

=item C</admin>

On HTTP GET, provides an administrative interface for managing user and profile data, as well
as to examine the overal system status.

=item C</ajax>

Manages AJAX requests for all administrative (and NOT conversion) tasks.

=item C</convert>

Accepts HTTP POST requests to perform conversion jobs.

The request syntax supports the normal key=value option fields for L<LaTeXML>.

Additionally, one can request embeddable snippets via I<embed=1>,
 as well as forced xml:id attributes on every element via I<force_ids=1>.
Supported via L<LaTeXML::Util::Extras>.

The most significant enhancements are in provdiding options for user and conversion profiles,
namely I<user=string>, I<password=string> and I<profile=string>.
Based on the sessioning functionality enabled by L<LaTeXML::Util::Startup>, a user can now
easily perform conversions based on his custom preferences. Moreover, conversion profiles allow
for users to obtain the desired transformation setup with just specifying a single "profile" field.
For a list of predefined profiles, consult L<LaTeXML::Util::Startup>.

The actual TeX/LaTeX source to be converted should be sent serialized as C<tex=content>.

=item C</editor>

Provides an AJAX and jQuery-based editor, originally created by Heinrich Stamerjohanns,
to showcase on-the-fly conversion of LaTeX snippets to XHTML.
A set of illustrating examples is provided, as well as a
convenient integration with LaTeXML's log and status reports.

A jQuery conversion request is as simple as:

 $.post("/convert", { "tex": tex, "profile":"fragment"});

=item C</help>

Help page, providing a guide through the site's functionality.

=item C</login>

A simple login interface.

=item C</logout>

A simple logout route that ends the current session.

=item C</upload>

On HTTP GET, this route provides an interface for converting LaTeX files, or entire setups,
by accepting .zip and .tar.gz archives, as well as mutlipart uploads of several file fragments,
as long as no subdirectories are present. Note that this is achieved with HTML5's native support
for multipart file uploads, hence a modern browser is required.

On HTTP POST, the uploaded bundle is converted by the server, returning an archive with the result.

=back

=head1 DEPLOYMENT

Installation and deployment are described in detail in LaTeXML/webapp/INSTALL.

As a rule of thumb, the regular deployment process for Mojolicious apps applies.


=head1 SEE ALSO

L<latexmls>, L<latexmlc>, L<LaTeXML>

=head1 AUTHOR

Deyan Ginev <d.ginev@jacobs-university.de>

=head1 COPYRIGHT

Public domain software, produced as part of work done by the
United States Government & not subject to copyright in the US.

=cut
