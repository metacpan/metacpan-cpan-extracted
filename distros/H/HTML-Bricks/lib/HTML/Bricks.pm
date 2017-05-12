#-----------------------------------------------------------------------------
# File: Bricks.pm
#
# I dedicate this Perl module to Jeff K, the Dallas techno DJ whose turntable
# madness influenced so many of us back in the 1990s.  Edgeclub still kicks
# ass without you, Jeff, but I'll always remember it when you were host.
#
#-----------------------------------------------------------------------------

package HTML::Bricks;

use 5.004;
use strict;

use Carp;
use Apache::Constants qw(:common);
use Apache::Cookie;
use HTML::Bricks::Mappings;
use HTML::Bricks::Args;
use HTML::Bricks::Users;
use Data::Dumper;			# for debugging

#-----------------------------------------------------------------------------
# package variables
#-----------------------------------------------------------------------------

our $VERSION = '0.03';
our $enable_output;			# output enable flag
our %global_args;                       # hash of global args
our %session;                           # session hash
our $session_id;                        # sesison id
our $ruser;                             # reference to current user hash
our @discarded_rassemblies;             # array of discared assemblies
our $rmatches;                          # exposed for standard/newbutton.mc

my @loaders = ( 'Brick_mason' );

my $user_bricks_path = '/user';
my @paths = ( '/standard', $user_bricks_path );

#-----------------------------------------------------------------------------
# traverse_loaders
#-----------------------------------------------------------------------------
sub traverse_loaders
{
  my $func = shift;

  foreach (@loaders) {

    my $ref = {};

    my $module = "HTML/Bricks/$_.pm";
    require $module;
    bless $ref, "HTML::Bricks::$_";

    last if !defined $ref->$func();
    
  }

  return undef;
}

#-----------------------------------------------------------------------------
# get_user_bricks_path
#-----------------------------------------------------------------------------
sub get_user_bricks_path() {
  return $user_bricks_path;
}

#-----------------------------------------------------------------------------
# get_bricks_list
#-----------------------------------------------------------------------------
sub get_bricks_list() 
{
  my @list;

  traverse_loaders(sub { push @list, @{$_[0]->get_bricks_list(\@paths)}; return 1 });

  return \@list;
}

#-----------------------------------------------------------------------------
# get_assemblies_list
#-----------------------------------------------------------------------------
sub get_assemblies_list()
{
  my @list;

  traverse_loaders(sub { push @list, @{$_[0]->get_assemblies_list(\@paths)}; return 1 });

  return \@list;
}

#-----------------------------------------------------------------------------
# get_class_data
#-----------------------------------------------------------------------------
sub get_class_data 
{
  my $brick_name = shift;

  my $r = Apache->request;

  if ((!defined $brick_name) || ($brick_name eq '')) {
    die "Bricks::get_class_data called with blank brick_name\n";
  }

  foreach (@loaders) {

    my $ref = {};

    my $module = "HTML/Bricks/$_.pm";
    require $module;
    bless $ref, "HTML::Bricks::$_";

    my $rclass_data = $ref->get_class_data(\@paths,$brick_name);

    return $rclass_data;
  }

  return undef;
}

#-----------------------------------------------------------------------------
# fetch
#
# fetch a brick
#-----------------------------------------------------------------------------
sub fetch
{
  my $brick_name = shift;

  my $r = Apache->request;

  if ((!defined $brick_name) || ($brick_name eq '')) {
    croak sprintf q{Bricks::fetch called with blank brick_name via package "%s"}, ref($_[0]);
  }

  foreach (@loaders) {

    my $ref = {};

    my $module = "HTML/Bricks/$_.pm";
    require $module;
    bless $ref, "HTML::Bricks::$_";

    my $rbrick = $ref->fetch(\@paths,$brick_name);

    return $rbrick if defined $rbrick;
  }

  return undef;

}

#-----------------------------------------------------------------------------
# do_redirect 
#-----------------------------------------------------------------------------
sub do_redirect {
  
  my $redirect = shift;

  my $old_enable_output = $enable_output;
  $enable_output = 1;

  print("<html>\n");
  print("<head>\n");
  print("<title>bricks site builder</title>\n");
  print("</head>\n");
  print("<body>\n");

  &$redirect();

  print("</body>\n");
  print("</html>\n");

  $enable_output = $old_enable_output;
}
    
#-----------------------------------------------------------------------------
# check_discards
#-----------------------------------------------------------------------------
sub check_discards {
  my ($rARGS,$rsub_ARGS,$uri,$rredirect) = @_;

  my %ARGS2;
  my $rsa;

  if ((defined $rsub_ARGS) && (defined $$rsub_ARGS{0})) {
    my $ra = $$rsub_ARGS{0};
    %ARGS2 = %{$$ra{rARGS}};
    $rsa = $$ra{rsub_ARGS};
  }

  $ARGS2{fn} = 'close';

  my @a;

  push @a, @{$session{discarded_rassemblies}} if exists $session{discarded_rassemblies};
  push @a, @discarded_rassemblies;

  delete $session{discarded_rassemblies};
  undef @discarded_rassemblies;

  while (my $rnode = $a[0]) {

    my $rbrick = fetch($$rnode{name});

    $rbrick->thaw($rnode);
    $$rbrick{name} = $$rnode{name};

    if ($rbrick->get_modified()) {
 
      $rbrick->process(undef,undef,\%ARGS2,$rsa,'0',\$uri,'view',$rredirect);
      if (defined $$rredirect) {
        $a[0] = $rbrick->freeze();
        $session{discarded_rassemblies} = \@a;
        return 1;
      } 
    }

    shift @a;
  }

# print STDERR "check_discards: setting discards to ", Dumper($session{discarded_rassemblies});
  $session{discarded_rassemblies} = \@a;

  return undef;
}

#-----------------------------------------------------------------------------
# set_logout
#-----------------------------------------------------------------------------
sub set_logout {
  
  undef $session{username};
  
}

#-----------------------------------------------------------------------------
# handler
#-----------------------------------------------------------------------------
sub handler {

  #
  # initialize globals
  #

  %global_args = my %h;
  %session = %h;
  $session_id = undef;                        
  $ruser = undef;
  @discarded_rassemblies = ();
  $rmatches = undef;

  #
  # Check for URIs handled Bricks::Magick
  #
  # Wrapped in Eval because we want Bricks to mostly work even if the user
  # hasn't installed Image::Magick
  #
  
  eval {
    require "HTML/Bricks/Magick.pm";
    return OK if HTML::Bricks::Magick::handler(@_) == OK;
  };

  #
  # Not a picture to be modified
  #

  my $r = shift;

  #
  # Bricks only processes documents ending in .htm or .html (not case-sensitive)
  #

  return DECLINED if $r->uri !~ /.*\.[hH][tT][mM][lL]?/;

  # print STDERR "BEGIN_XACTION\n";

  #
  # get session info
  #

  my %cookies = Apache::Cookie->fetch;
  my $cookie = $cookies{SESSION_ID};

  if (defined $cookie) {

    use Apache::Session::File;

    my %tsession;
    eval {
      tie %tsession, 'Apache::Session::File', $cookie->value, {
        Directory => '/tmp',
        LockDirectory => '/tmp'
      };

      %session = %tsession;

      untie %tsession;
    };

    $session_id = $session{_session_id};
  }

  #
  # do the transaction
  #

  $rmatches = [];
  my $retval = do_transaction($rmatches);

  #
  # update session information
  #

  if (defined $session_id) {

    #
    # Note: we used to freeze only modified nodes, but then discovered that
    # some nodes need to have their state saved even if they aren't modified.
    # for example, if a node is doing some editing operation that may not
    # modify the node, and that operation takes multiple steps, we need
    # to save the state.
    #
    # A more general method of saving state needs to be designed
    #

    my @matches;
    foreach (@$rmatches) {
#     if ($_->get_modified()) {
        push @matches, [ $$_{name}, $_->freeze() ];
#     }
#     else {
#       push @matches, [ $$_{name}, undef ]; 
#     }
    }

    $session{rprev_matches} = \@matches;
    $session{stamp} = $session{stamp} + 1;

    use Apache::Session::File;

    eval {
      my %tsession;

      tie %tsession, 'Apache::Session::File', $session_id, {
        Directory => '/tmp',
        LockDirectory => '/tmp'
      };

      %tsession = %session;
      untie %tsession;
    };

  }

  # print STDERR "END XACTION $session{_session_id}\n";

  return $retval;
}


#-----------------------------------------------------------------------------
# do_transaction
#-----------------------------------------------------------------------------
sub do_transaction {

  my $rmatches = shift;

  my $r = Apache->request;
  my $rroot_brick;
  my $rprev_matches;
  my $redirect;
  my $uri;
  my $username;

BEGIN_TRANSACTION:

  $redirect = undef;
  $uri = $r->uri . '?';
  $username = $session{username};

  if (defined $session_id) {

    #
    # store session id cookie on client
    #

    my $cookie = Apache::Cookie->new( $r, -name => 'SESSION_ID', -value => $session_id);    
    $cookie->bake;
  }

  #
  # get a list of mappings for this uri
  #

  my $mapper = HTML::Bricks::Mappings->new();
  my @match_names = $mapper->get_matches($r->uri);

  #
  # get arguments from http posts and the uri line
  #

  my ($ra, $rsa) = HTML::Bricks::Args::process_args();

  #
  # Admin logging out -- may put up multiple 'save changes?' dialogs
  #

  if (defined $session{logging_out}) {

    # print STDERR "Bricks::do_transaction: logging out\n";

    if (check_discards($ra,$rsa,$uri,\$redirect)) {
      do_redirect($redirect);
      delete $session{rprev_matches};
      return OK;
    };

    # print STDERR "logging out: check_discards, redirect=$redirect\n";
  }

  #
  # read in the bricks
  #

  if (defined $username) {           # if the admin is logged in

    $rprev_matches = $session{rprev_matches};
    @$rprev_matches = [] if !defined $rprev_matches;

    my $rmatch = (defined $$rprev_matches[1]) ? $$rprev_matches[1] : undef; 
    my $rassy = (defined $rmatch) ? $$rmatch[1] : undef;

    if (($r->uri eq '/new_brick.html') && (defined $rassy)) {
      @match_names = $$rassy{name}; 
    }
    elsif (exists $global_args{bricks_edit_assy}) {

      #
      # if admin is editing an assembly, override @match_names
      #
  
      @match_names = $global_args{bricks_edit_assy};
      $uri .= 'g:bricks_edit_assy=' . $global_args{bricks_edit_assy} . '&';
    }

    #
    # get user information
    #

    use HTML::Bricks::Users;
    my $usermgr = HTML::Bricks::Users->new();
    $ruser = $usermgr->get($session{username});

    #
    # display the authorbar when administrator is logged in
    #

    unshift @match_names, 'authorbar';

    #
    # now traverse previous and current matches, selecting from prev_matches or loading from disk
    #

    for (my $i=0; $i <= $#match_names; $i++) {

      my $rprev_match = shift @$rprev_matches;

      if (defined $rprev_match) {
        my $name = $$rprev_match[0];
        my $rassy = $$rprev_match[1];

        if (($name eq $match_names[$i]) && (defined $rassy)) {
          # print STDERR "loading from prev_matches $match_names[$i]\n";

          my $rbrick = fetch($$rassy{name});
          $rbrick->thaw($rassy);

          if ($rbrick->is_blank()) {
            $rbrick = fetch($$rbrick{name});
            $rbrick->new();
          }

          push @$rmatches, $rbrick;
          next;
        }
        elsif (defined $rassy) {
          push @discarded_rassemblies, $rassy  # rassy is frozen
        }
      }

      # print STDERR "loading from disk $match_names[$i]\n";
      my $rmatch = fetch($match_names[$i]);
      $rmatch->new();

      push @$rmatches, $rmatch;
    }

    #
    # if $#$rprev_matches > $#match_names, we'll have some left over; discard them.
    #

    foreach (@$rprev_matches) {
      push @discarded_rassemblies, $$_[1] if defined $$_[1];
    }

    $#$rprev_matches = -1;
  }
  else {
 
    # 
    # admin not logged in, load the bricks
    #

    foreach (@match_names) {
      my $rbrick = fetch($_);
      $rbrick->new();
      push @$rmatches, $rbrick; 
    }

    delete $session{rprev_matches};   # necessary ?
    delete $session{mode};            # necessary ?

  }

  #
  # if nothing matched, and there's no filename that matches the request, return 404
  #

  if ($#$rmatches == -1) {
    return DECLINED;
  }

  #
  # link the bricks together 
  #

  for (my $i=0; $i < $#$rmatches; $i++) {
    $$rmatches[$i]->set_next($$rmatches[$i+1]);
  }

  #
  # process input
  #

  foreach (keys %global_args) {
    ${$$rsa{rARGS}}{$_} = $global_args{$_};   # copy global args into args
  }

  $rroot_brick = $$rmatches[0];

  $rroot_brick->process(undef,undef,$ra,$rsa,undef,\$uri,'view',\$redirect);

  if ($username ne $session{username}) {

    #
    # the user logged in or logged out
    #

    # print STDERR "logged in/out: $session_id\n";

    if (!defined $session{username}) {

      foreach (@$rmatches) {
        push @discarded_rassemblies, $_->freeze() if $_->get_modified();
      }

      $session{logging_out} = 1;
    }

    undef $rmatches;
    goto BEGIN_TRANSACTION;

  }

  #
  # check discards
  #
  # redirect will be set if there are any discards
  #

  if (check_discards($ra,$rsa,$uri,\$redirect)) {
    $session{rprev_matches} = $rmatches;
  };

  #
  # send the header
  #

  $r->content_type('text/html');
  $r->send_http_header;
  return OK if $r->header_only;

  #
  # enable output
  #

  $enable_output = 1;

  #
  # check to see if during process a brick wanted to redirect output
  #

  if (defined $redirect) {
    do_redirect($redirect);
    $session{rprev_matches} = $rmatches;
    $enable_output = undef;
    return OK;
  }

  #
  # render it
  #

  $rroot_brick->render(undef,$rroot_brick,$ra,$rsa,undef,undef,$uri,'view');

  # 
  # disable output
  #

  $enable_output = undef;

  #
  # If any assemblies have been modified, save them.  
  #
  # This happens when an assembly decided to modify its state because, for example, it
  # discovered a new file on disk or whatnot.
  #
  # if $username is defined, meaning that the admin is logged in, we don't save.  Instead
  # the admin has the option of saving via the 'save' button on the authorbar.
  #
    
  $rroot_brick->save() if (!defined $username) && ($rroot_brick->get_modified());

  return OK;
}

#-----------------------------------------------------------------------------

1;

