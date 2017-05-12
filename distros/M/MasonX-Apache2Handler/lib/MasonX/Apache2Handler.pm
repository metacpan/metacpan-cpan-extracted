#------------------------------------------------------------------------
# Changes to HTML::Mason::ApacheHandler for Apache2/mod_perl 2.
#
# Beau E. Cox <beau@beaucox.com>
# April 2004
#
# Changes (C)Copyright 2004 Beau E. Cox.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#------------------------------------------------------------------------

# Copyright (c) 1998-2003 by Jonathan Swartz. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;

#----------------------------------------------------------------------
#
# APACHE-SPECIFIC REQUEST OBJECT
#
package MasonX::Request::Apache2Handler;

use Apache::Const -compile => qw( REDIRECT );

use MasonX::Request2;
use Class::Container;
use Params::Validate qw(BOOLEAN);
Params::Validate::validation_options( on_fail => sub { param_error( join '', @_ ) } );

use base qw(MasonX::Request2);

use HTML::Mason::Exceptions( abbr => [qw(param_error error)] );

use constant OK         => 0;
use constant DECLINED   => -1;
use constant NOT_FOUND  => 404;

if ( $mod_perl::VERSION < 1.99 )
{
    error "you must use mod_perl 2 (version >= 1.99)", __PACKAGE__, "\n";
}

BEGIN
{
    __PACKAGE__->valid_params
	( ah         => { isa => 'MasonX::Apache2Handler',
			  descr => 'An Apache2Handler to handle web requests',
			  public => 0 },

	  apache_req => { isa => 'Apache::RequestRec', default => undef,
			  descr => "An Apache request object",
			  public => 0 },

	  cgi_object => { isa => 'CGI',    default => undef,
			  descr => "A CGI.pm request object",
			  public => 0 },

	  auto_send_headers => { parse => 'boolean', type => BOOLEAN, default => 1,
				 descr => "Whether HTTP headers should be auto-generated" },
	);
}

use HTML::Mason::MethodMaker
    ( read_write => [ map { [ $_ => __PACKAGE__->validation_spec->{$_} ] }
		      qw( ah apache_req auto_send_headers ) ] );

# A hack for subrequests
sub _properties { qw(ah apache_req), shift->SUPER::_properties }

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);  # Magic!

    unless ($self->apache_req or $self->cgi_object)
    {
	param_error __PACKAGE__ . "->new: must specify 'apache_req' or 'cgi_object' parameter";
    }

    return $self;
}

# Override flush_buffer to also call $r->rflush
sub flush_buffer
{
    my ($self) = @_;
    # Only call rflush if flush_buffer returns a true value.
    # (return implemented in MasonX::Request2 and MasonX::Buffer2.)
    $self->SUPER::flush_buffer and $self->apache_req->rflush;
}

sub cgi_object
{
    my ($self) = @_;

    error "Can't call cgi_object() unless 'args_method' is set to CGI.\n"
	unless $self->ah->args_method eq 'CGI';

    if (defined($_[1])) {
	$self->{cgi_object} = $_[1];
    } else {
	# We may not have created a CGI object if, say, request was a
	# GET with no query string. Create one on the fly if necessary.
	$self->{cgi_object} ||= CGI->new('');
    }

    return $self->{cgi_object};
}

#
# Override this method to return NOT_FOUND when we get a
# TopLevelNotFound exception. In case of POST we must trick
# Apache into not reading POST content again. Wish there were
# a more standardized way to do this...
#
sub exec
{
    my $self = shift;
    my $r = $self->apache_req;
    my $retval;

    if ( $self->is_subrequest )
    {
        # no need to go through all the rigamorale below for
        # subrequests, and it may even break things to do so, since
        # $r's print should only be redefined once.
	eval { $retval = $self->SUPER::exec(@_) };
    }
    else
    {
        # ack, this has to be done at runtime to account for the fact
        # that Apache::Filter changes $r's class and implements its
        # own print() method.
        my $real_apache_print = $r->can('print');

	# Remap $r->print to Mason's $m->print while executing
	# request, but just for this $r, in case user does an internal
	# redirect or apache subrequest.
	local $^W = 0;
	no strict 'refs';

        my $req_class = ref $r;
	local *{"$req_class\::print"} = sub {
	    my $local_r = shift;
	    return $self->print(@_) if $local_r eq $r;
	    return $local_r->$real_apache_print(@_);
	};
	eval { $retval = $self->SUPER::exec(@_) };
    }

    if ($@) {
	if (isa_mason_exception($@, 'TopLevelNotFound')) {
	    # Log the error the same way that Apache does (taken from default_handler in http_core.c)
	    $r->log_error("[Mason] File does not exist: ", $r->filename . ($r->path_info ? $r->path_info : ""));
	    return $self->ah->return_not_found($r);
	} else {
	    rethrow_exception $@;
	}
    }

    # On a success code, send headers if they have not been sent and
    # if we are the top-level request. Since the out_method sends
    # headers, this will typically only apply after $m->abort.
    # On an error code, leave it to Apache to send the headers.
    # not needed in mod_per2 (??)
    if (!$self->is_subrequest
	and $self->auto_send_headers
	and !MasonX::Apache2Handler::http_header_sent($r)
	and (!$retval or $retval==200)) {
	#$r->send_http_header();
    }

    return defined($retval) ? $retval : OK;
}

#
# Override this method to always die when top level component is not found,
# so we can return NOT_FOUND.
#
sub _handle_error
{
    my ($self, $err) = @_;

    if (isa_mason_exception($err, 'TopLevelNotFound')) {
	rethrow_exception $err;
    } else {
        if ( $self->error_format eq 'html' ) {
            $self->apache_req->content_type('text/html');
        }
	$self->SUPER::_handle_error($err);
    }
}

sub redirect
{
    my ($self, $url, $status) = @_;
    my $r = $self->apache_req;

    $self->clear_buffer;
    $r->method('GET');
    $r->headers_in->unset('Content-length');
    $r->err_headers_out->{ Location } = $url;
    $self->abort($status || Apache::REDIRECT);
}

#----------------------------------------------------------------------
#
# APACHE-SPECIFIC FILE RESOLVER OBJECT
#
package MasonX::Resolver::File::Apache2Handler;

use strict;

use HTML::Mason::Tools qw(paths_eq);

use HTML::Mason::Resolver::File;
use base qw(HTML::Mason::Resolver::File);
use Params::Validate qw(SCALAR ARRAYREF);

BEGIN
{
    __PACKAGE__->valid_params
	(
	 comp_root =>   # This is optional in superclass, but required for us.
	 { parse => 'list',
	   type => SCALAR|ARRAYREF,
	   descr => "A string or array of arrays indicating the search path for component calls" },
	);
}

#
# Given an apache request object, return the associated component
# path or undef if none exists. This is called for top-level web
# requests that resolve to a particular file.
#
sub apache_request_to_comp_path {
    my ($self, $r) = @_;

    my $file = $r->filename;
    $file .= $r->path_info unless -f $file;

    # Clear up any weirdness here so that paths_eq compares two
    # 'canonical' paths (canonpath is called on comp roots when
    # resolver object is created.  Seems to be needed on Win32 (see
    # bug #356).
    $file = File::Spec->canonpath($file);

    foreach my $root (map $_->[1], $self->comp_root_array) {
	if (paths_eq($root, substr($file, 0, length($root)))) {
	    my $path = substr($file, length $root);
            $path = length $path ? join '/', File::Spec->splitdir($path) : '/';
            chop $path if $path ne '/' && substr($path, -1) eq '/';

            return $path;
	}
    }
    return undef;
}


#----------------------------------------------------------------------
#
# APACHEHANDLER OBJECT
#
package MasonX::Apache2Handler;

use File::Path;
use File::Spec;
use HTML::Mason::Exceptions( abbr => [qw(param_error system_error error)] );
use HTML::Mason::Interp;
use HTML::Mason::Tools qw( load_pkg );
use HTML::Mason::Utils;
use Params::Validate qw(:all);
Params::Validate::validation_options( on_fail => sub { param_error( join '', @_ ) } );

use Apache::Const -compile => qw( OK DECLINED NOT_FOUND );
use APR;
use Apache::ServerUtil;

# Require a mod_perl 2
use mod_perl 1.99;

if ( $mod_perl::VERSION < 1.99 )
{
    error "you must use mod_perl 2 (version >= 1.99)", __PACKAGE__, "\n";
}

use vars qw($VERSION);

$VERSION = 0.05;

use Class::Container;
use base qw(Class::Container);

BEGIN
{
    __PACKAGE__->valid_params
	(
	 apache_status_title =>
         { parse => 'string', type => SCALAR, default => 'HTML::Mason status',
           descr => "The title of the Apache::Status page" },

	 args_method =>
         { parse => 'string',  type => SCALAR,       default => 'mod_perl',
           regex => qr/^(?:CGI|mod_perl)$/,
           descr => "Whether to use CGI.pm or Apache::Request for parsing the incoming HTTP request",
         },

	 decline_dirs =>
         { parse => 'boolean', type => BOOLEAN, default => 1,
           descr => "Whether Mason should decline to handle requests for directories" },

	 # the only required param
	 interp =>
         { isa => 'HTML::Mason::Interp',
           descr => "A Mason interpreter for processing components" },
	);

    __PACKAGE__->contained_objects
	(
	 interp =>
         { class => 'HTML::Mason::Interp',
           descr => 'The interp class coordinates multiple objects to handle request execution'
         },
	);
}

use HTML::Mason::MethodMaker
    ( read_only  => [ 'args_method' ],
      read_write => [ map { [ $_ => __PACKAGE__->validation_spec->{$_} ] }
		      qw( apache_status_title
			  decline_dirs
			  interp ) ]
    );

my ($STARTED);

# hack to let the make_params_pod.pl script work
__PACKAGE__->_startup() if Apache->server;
sub _startup
{
    my $pack = shift;
    return if $STARTED++; # Allows a subclass to call us, without running twice

    if ( my $args_method = $pack->_get_string_param('MasonArgsMethod') )
    {
	if ($args_method eq 'CGI')
	{
	    require CGI unless defined $CGI::VERSION;
	}
	elsif ($args_method eq 'mod_perl')
	{
	    require Apache::Request unless defined $Apache::Request::VERSION;
	}
    }
}

use constant
    HAS_TABLE_API => $mod_perl::VERSION >= 1.99;

my %AH_BY_CONFIG;
sub make_ah
{
    my ($package, $r) = @_;

    my $config = $r->dir_config;

    #
    # If the user has virtual hosts, each with a different document
    # root, then we will have to be called from the handler method.
    # This means we have an active request.  In order to distinguish
    # between virtual hosts with identical config directives that have
    # no comp root defined (meaning they expect to use the default
    # comp root), we append the document root for the current request
    # to the key.
    #
    my $key =
        ( join $;,
          $r->document_root,
          map { $_, HAS_TABLE_API ? sort $config->get($_) : $config->{$_} }
          grep { /^Mason/ }
          keys %$config
        );

    return $AH_BY_CONFIG{$key} if exists $AH_BY_CONFIG{$key};

    my %p = $package->_get_mason_params($r);

    # can't use hash_list for this one because it's _either_ a string
    # or a hash_list
    if (exists $p{comp_root}) {
	if (@{$p{comp_root}} == 1 && $p{comp_root}->[0] !~ /=>/) {
	    $p{comp_root} = $p{comp_root}[0];  # Convert to a simple string
	} else {
            my @roots;
	    foreach my $root (@{$p{comp_root}}) {
		$root = [ split /\s*=>\s*/, $root, 2 ];
		param_error "Configuration parameter MasonCompRoot must be either ".
                            "a single string value or multiple key/value pairs ".
                            "like 'foo => /home/mason/foo'.  Invalid parameter:\n$root"
		    unless defined $root->[1];

                push @roots, $root;
	    }

            $p{comp_root} = \@roots;
	}
    }

    my $ah = $package->new(%p, $r);
    $AH_BY_CONFIG{$key} = $ah if $key;

    return $ah;
}

# The following routines handle getting information from $r->dir_config

sub calm_form {
    # Transform from StudlyCaps to name_like_this
    my ($self, $string) = @_;
    $string =~ s/^Mason//;
    $string =~ s/(^|.)([A-Z])/$1 ? "$1\L_$2" : "\L$2"/ge;
    return $string;
}

sub studly_form {
    # Transform from name_like_this to StudlyCaps
    my ($self, $string) = @_;
    $string =~ s/(?:^|_)(\w)/\U$1/g;
    return $string;
}

sub _get_mason_params
{
    my $self = shift;
    my $r = shift;

    my $config = $r ? $r->dir_config : Apache->server->dir_config;

    # Get all params starting with 'Mason'
    my %candidates;

    foreach my $studly ( keys %$config )
    {
	(my $calm = $studly) =~ s/^Mason// or next;
	$calm = $self->calm_form($calm);

	$candidates{$calm} = $config->{$studly};
    }

    return unless %candidates;

    #
    # We will accumulate all the string versions of the keys and
    # values here for later use.
    #
    return ( map { $_ =>
                   scalar $self->get_param( $_, \%candidates, $config, $r )
                 }
             keys %candidates );
}

sub get_param {
    # Gets a single config item from dir_config.

    my ($self, $key, $candidates, $config, $r) = @_;

    $key = $self->calm_form($key);

    my $spec = $self->allowed_params( $candidates || {} )->{$key}
        or error "Unknown config item '$key'";

    # Guess the default parse type from the Params::Validate validation spec
    my $type = ($spec->{parse} or
		$spec->{type} & ARRAYREF ? 'list' :
		$spec->{type} & SCALAR   ? 'string' :
		$spec->{type} & CODEREF  ? 'code' :
		undef)
        or error "Unknown parse type for config item '$key'";

    my $method = "_get_${type}_param";
    return $self->$method('Mason'.$self->studly_form($key), $config, $r);
}

sub _get_string_param
{
    my $self = shift;
    return scalar $self->_get_val(@_);
}

sub _get_boolean_param
{
    my $self = shift;
    return scalar $self->_get_val(@_);
}

sub _get_code_param
{
    my $self = shift;
    my $p = $_[0];
    my $val = $self->_get_val(@_);

    return unless $val;

    my $sub_ref = eval $val;

    param_error "Configuration parameter '$p' is not valid perl:\n$@\n"
	if $@;

    return $sub_ref;
}

sub _get_list_param
{
    my $self = shift;
    my @val = $self->_get_val(@_);
    if (@val == 1 && ! defined $val[0])
    {
	@val = ();
    }

    return \@val;
}

sub _get_hash_list_param
{
    my $self = shift;
    my @val = $self->_get_val(@_);
    if (@val == 1 && ! defined $val[0])
    {
        return {};
    }

    my %hash;
    foreach my $pair (@val)
    {
        my ($key, $val) = split /\s*=>\s*/, $pair, 2;
        param_error "Configuration parameter $_[0] must be a key/value pair ".
                    qq|like "foo => 'bar'".  Invalid parameter:\n$pair|
                unless defined $key && defined $val;

        $hash{$key} = $val;
    }

    return \%hash;
}

sub _get_val
{
    my ($self, $p, $config, $r) = @_;

    my @val;
    if (wantarray || !$config)
    {
        if ($config)
        {
            my $c = $r ? $r : Apache->server;
            @val = HAS_TABLE_API ? $config->get($p) : $config->{$p};
        }
        else
        {
            my $c = $r ? $r : Apache->server;
            @val = HAS_TABLE_API ? $c->dir_config->get($p) : $c->dir_config($p);
        }
    }
    else
    {
        @val = exists $config->{$p} ? $config->{$p} : ();
    }

    param_error "Only a single value is allowed for configuration parameter '$p'\n"
	if @val > 1 && ! wantarray;

    return wantarray ? @val : $val[0];
}

sub new
{
    my $class = shift;

    # Get $r off end of params if its there
    my $r;
    $r = pop() if @_ % 2;
    my %params = @_;

    my %defaults;
    $defaults{request_class}  = 'MasonX::Request::Apache2Handler'
        unless exists $params{request};
    $defaults{resolver_class} = 'MasonX::Resolver::File::Apache2Handler'
        unless exists $params{resolver};

    my $allowed_params = $class->allowed_params(%defaults, %params);

     if ( exists $allowed_params->{comp_root} and
	 my $req = $r )  # DocumentRoot is only available inside requests
    {
	$defaults{comp_root} = $req->document_root;
    }
=comment
   if ( exists $allowed_params->{comp_root} ) {
	if ( my $req = $r ) {
	# DocumentRoot is only available inside requests
	    $defaults{comp_root} = $req->document_root;
	} else {
	    $defaults{comp_root} =
		Apache->server->dir_config( '_MasonDefaultDocumentRoot' );
	}
    }
=cut

    if (exists $allowed_params->{data_dir} and not exists $params{data_dir})
    {
	# constructs path to <server root>/mason
	my $def = $defaults{data_dir} = Apache->server->server_root_relative('mason');
	param_error "Default data_dir (MasonDataDir) '$def' must be an absolute path"
	    unless File::Spec->file_name_is_absolute($def);
	  
	my @levels = File::Spec->splitdir($def);
	param_error "Default data_dir (MasonDataDir) '$def' must be more than two levels deep (or must be set explicitly)"
	    if @levels <= 3;
    }

    # Set default error_format based on error_mode
    if (exists($params{error_mode}) and $params{error_mode} eq 'fatal') {
	$defaults{error_format} = 'line';
    } else {
	$defaults{error_mode} = 'output';
	$defaults{error_format} = 'html';
    }

    # Push $r onto default allow_globals
    if (exists $allowed_params->{allow_globals}) {
	if ( $params{allow_globals} ) {
	    push @{ $params{allow_globals} }, '$r';
	} else {
	    $defaults{allow_globals} = ['$r'];
	}
    }

    my $self = eval { $class->SUPER::new(%defaults, %params) };

    # We catch & throw this exception just to provide a better error message
    if ( $@ && isa_mason_exception( $@, 'Params' ) && $@->message =~ /comp_root/ )
    {
	param_error "No comp_root specified and cannot determine DocumentRoot." .
                    " Please provide comp_root explicitly.";
    }
    rethrow_exception $@;

    unless ( $self->interp->resolver->can('apache_request_to_comp_path') )
    {
	error "The resolver class your Interp object uses does not implement " .
              "the 'apache_request_to_comp_path' method.  This means that Apache2Handler " .
              "cannot resolve requests.  Are you using a handler.pl file created ".
	      "before version 1.10?  Please see the handler.pl sample " .
              "that comes with the latest version of Mason.";
    }

    # If we're running as superuser, change file ownership to http user & group
    if (!($> || $<) && $self->interp->files_written)
    {
	chown getpwnam( Apache->server->dir_config( '_MasonUser' ) ),
	getgrnam( Apache->server->dir_config( '_MasonGroup' ) ),
	$self->interp->files_written
	    or system_error( "Can't change ownership of files written by interp object: $!\n" );
    }

    $self->_initialize;
    return $self;
}

# Register with Apache::Status at module startup.  Will get replaced
# with a more informative status once an interpreter has been created.
my $status_name = 'mason0001';
if ( load_pkg('Apache::Status') )
{
    Apache::Status->menu_item
	($status_name => __PACKAGE__->allowed_params->{apache_status_title}{default},
         sub { ["<b>(no interpreters created in this child yet)</b>"] });
}


sub _initialize {
    my ($self) = @_;

    if ($self->args_method eq 'mod_perl') {
	unless (defined $Apache::Request::VERSION) {
	    warn "Loading Apache::Request at runtime.  You could " .
                 "increase shared memory between Apache processes by ".
                 "preloading it in your httpd.conf or handler.pl file\n";
	    require Apache::Request;
	}
    } else {
	unless (defined $CGI::VERSION) {
	    warn "Loading CGI at runtime.  You could increase shared ".
                 "memory between Apache processes by preloading it in ".
                 "your httpd.conf or handler.pl file\n";

	    require CGI;
	}
    }

    # Add an HTML::Mason menu item to the /perl-status page.
    if (defined $Apache::Status::VERSION) {
	# A closure, carries a reference to $self
	my $statsub = sub {
	    my ($r,$q) = @_; # request and CGI objects
	    return [] if !defined($r);

	    if ($r->path_info and $r->path_info =~ /expire_code_cache=(.*)/) {
		$self->interp->delete_from_code_cache($1);
	    }

	    return ["<center><h2>" . $self->apache_status_title . "</h2></center>" ,
		    $self->status_as_html
		    (apache_req => $r),
		    $self->interp->status_as_html
		    (ah => $self, $r) ];
	};
	local $^W = 0; # to avoid subroutine redefined warnings
	Apache::Status->menu_item($status_name, $self->apache_status_title, $statsub);
    }

    my $interp = $self->interp;

    #
    # Allow global $r in components
    #
    $interp->compiler->add_allowed_globals('$r')
	if $interp->compiler->can('add_allowed_globals');
}

# Generate HTML that describes Apache2andler's current status.
# This is used in things like Apache::Status reports.

sub status_as_html {
    my ($self, %p) = @_;

    # Should I be scared about this?  =)

    my $comp_source = <<'EOF';
<h3>Apache2Handler properties:</h3>
<blockquote>
 <tt>
<table width="75%">
<%perl>
foreach my $property (sort keys %$ah) {
    my $val = $ah->{$property};
    my $default = ( defined $val && defined $valid{$property}{default} && $val eq $valid{$property}{default} ) || ( ! defined $val && exists $valid{$property}{default} && ! defined $valid{$property}{default} );

    my $display = $val;
    if (ref $val) {
        $display = '<font color="darkred">';
        # only object can ->can, others die
        my $is_object = eval { $val->can('anything'); 1 };
        if ($is_object) {
            $display .= ref $val . ' object';
        } else {
            if (UNIVERSAL::isa($val, 'ARRAY')) {
                $display .= 'ARRAY reference - [ ';
                $display .= join ', ', @$val;
                $display .= '] ';
            } elsif (UNIVERSAL::isa($val, 'HASH')) {
                $display .= 'HASH reference - { ';
                my @pairs;
                while (my ($k, $v) = each %$val) {
                   push @pairs, "$k => $v";
                }
                $display .= join ', ', @pairs;
                $display .= ' }';
            } else {
                $display = ref $val . ' reference';
            }
        }
        $display .= '</font>';
    }

    defined $display && $display =~ s,([\x00-\x1F]),'<font color="purple">control-' . chr( ord('A') + ord($1) - 1 ) . '</font>',eg; # does this work for non-ASCII?
</%perl>
 <tr valign="top" cellspacing="10">
  <td>
    <% $property | h %>
  </td>
  <td>
   <% defined $display ? $display : '<i>undef</i>' %>
   <% $default ? '<font color=green>(default)</font>' : '' %>
  </td>
 </tr>
% }
</table>
  </tt>
</blockquote>

<%args>
 $ah       # The Apache2Handler we'll elucidate
 %valid    # Contains default values for member data
</%args>
EOF

    my $interp = $self->interp;
    my $comp = $interp->make_component(comp_source => $comp_source);
    my $out;

    $self->interp->make_request
	( comp => $comp,
	  args => [ah => $self, valid => $interp->allowed_params],
	  ah => $self,
	  apache_req => $p{apache_req},
	  out_method => \$out,
	)->exec;

    return $out;
}

sub handle_request
{
    my ($self, $r) = @_;

    my $req = $self->prepare_request($r);
    return $req unless ref($req);

    return $req->exec;
}

my $do_filter = sub { $_[0]->filter_register };
my $no_filter = sub { $_[0] };
sub prepare_request
{
    my $self = shift;

    my $r_sub = lc $_[0]->dir_config('Filter') eq 'on' ? $do_filter : $no_filter;

    # This gets the proper request object all in one fell swoop.  We
    # don't want to copy it because if we do something like assign an
    # Apache::Request object to a variable currently containing a
    # plain Apache object, we leak memory.  This means we'd have to
    # use multiple variables to avoid this, which is annoying.

    # for mod_perl2 just pickup Apache::RequestRec
    my $r = $_[0];

    my $interp = $self->interp;

    #
    # If filename is a directory, then either decline or simply reset
    # the content type, depending on the value of decline_dirs.
    #
    # ** We should be able to use $r->finfo here, but finfo is broken
    # in some versions of mod_perl (e.g. see Shane Adams message on
    # mod_perl list on 9/10/00)
    #
    my $is_dir = -d $r->filename;
    my $is_file = -f _;

    if ($is_dir) {
	if ($self->decline_dirs) {
	    return Apache::DECLINED;
	} else {
	    $r->content_type(undef);
	}
    }

    #
    # Compute the component path via the resolver. Return NOT_FOUND on failure.
    #
    my $comp_path = $interp->resolver->apache_request_to_comp_path($r);
    unless ($comp_path) {
	#
	# Append path_info if filename does not represent an existing file
	# (mainly for dhandlers).
	#
	my $pathname = $r->filename;
	$pathname .= $r->path_info unless $is_file;

	warn "[Mason] Cannot resolve file to component: " .
             "$pathname (is file outside component root?)";
	return $self->return_not_found($r);
    }

    my ($args, undef, $cgi_object) = $self->request_args($r);

    #
    # Set up interpreter global variables.
    #
    $interp->set_global( r => $r );

    # If someone is using a custom request class that doesn't accept
    # 'ah' and 'apache_req' that's their problem.
    #
    my $request = eval {
        $interp->make_request( comp => $comp_path,
                               args => [%$args],
                               ah => $self,
                               apache_req => $r,
                             );
    };
    if (my $err = $@) {
        # Mason doesn't currently throw any exceptions in the above, but some
        # subclasses might. So be sure to handle them appropriately. We
        # rethrow everything but TopLevelNotFound, Abort, and Decline errors.
	if ( isa_mason_exception($err, 'TopLevelNotFound') ) {
            # Return a 404.
	    $r->log_error("[Mason] File does not exist: ", $r->filename .
                          ($r->path_info || ""));
	    return $self->return_not_found($r);
	}
        # Abort or decline.
	my $retval = isa_mason_exception($err, 'Abort')   ? $err->aborted_value  :
		     isa_mason_exception($err, 'Decline') ? $err->declined_value :
		     rethrow_exception $err;
	# not needed in mod_perl2 (??)
        #$r->send_http_header unless $retval and $retval != 200;
	return $retval;
    }

    my $final_output_method = ($r->method eq 'HEAD' ?
			       sub {} :
			       $r->can('print'));

    # Craft the request's out method to handle http headers, content
    # length, and HEAD requests.
    my $sent_headers = 0;
    my $out_method = sub {

	# Send headers if they have not been sent by us or by user.
        # We use instance here because if we store $request we get a
        # circular reference and a big memory leak.
	if (!$sent_headers and MasonX::Request2->instance->auto_send_headers) {
	    # not needed in mod_perl2 (??) - just set content type
	    #unless (http_header_sent($r)) {
	    #   $r->send_http_header();
	    #}
	    $sent_headers = 1;
	}

	# We could perhaps install a new, faster out_method here that
	# wouldn't have to keep checking whether headers have been
	# sent and what the $r->method is.  That would require
	# additions to the Request interface, though.

	
	# Call $r->print (using the real Apache method, not our
	# overriden method).
	$r->$final_output_method(grep {defined} @_);
    };

    $request->out_method($out_method);

    $request->cgi_object($cgi_object) if $cgi_object;

    return $request;
}

sub request_args
{
    my ($self, $r) = @_;

    #
    # Get arguments from Apache::Request or CGI.
    #
    my ($args, $cgi_object);
    if ($self->args_method eq 'mod_perl') {
	$args = $self->_mod_perl_args($r);
    } else {
	$cgi_object = CGI->new;
	$args = $self->_cgi_args($r, $cgi_object);
    }

    # we return $r solely for backwards compatibility
    return ($args, $r, $cgi_object);
}

#
# Get $args hashref via CGI package
#
sub _cgi_args
{
    my ($self, $r, $q) = @_;

    # For optimization, don't bother creating a CGI object if request
    # is a GET with no query string
    return {} if $r->method eq 'GET' && !scalar($r->args);

    return HTML::Mason::Utils::cgi_request_args($q, $r->method);
}

#
# Get $args hashref via Apache::Request package.
#
sub _mod_perl_args
{
    my ($self, $r, $request) = @_;

    # for mod_perl2, get back to Apache::Request from Apache::RequestRec
    my $apr = Apache::Request->new( $r );
    my %args;
    foreach my $key ( $apr->param ) {
	my @values = $apr->param($key);
	$args{$key} = @values == 1 ? $values[0] : \@values;
    }

    return \%args;
}

#
# Determines whether the http header has been sent.
#
sub http_header_sent { shift->headers_out->{"Content-type"} }

# Utility function to prepare $r before returning NOT_FOUND.
sub return_not_found
{
    my ($self, $r) = @_;

    if ($r->method eq 'POST') {
	$r->method('GET');
	$r->headers_in->unset('Content-length');
    }
    return Apache::NOT_FOUND;
}

#
# PerlHandler MasonX::Apache2Handler
#
BEGIN
{
    # A mod_perl2 method handler
    my $handler_code = <<'EOF';
sub handler : method
{
    my ($package, $r) = @_;

    my $ah;
    $ah ||= $package->make_ah($r);

    return $ah->handle_request($r);
}
EOF
    eval $handler_code;
    rethrow_exception $@;
}

1;

__END__

=head1 NAME

MasonX::Apache2Handler - experimental (alpha) Mason/mod_perl2 interface

=head1 SYNOPSIS

    use MasonX::Apache2Handler;
 
    my $ah = MasonX::Apache2Handler->new (..name/value params..);
    ...
    sub handler {
     my $r = shift;
     $ah->handle_request($r);
    }

=head1 DESCRIPTION

B<MasonX::Apache2Handler is highly experimental ( alpha ) and
should only be used in a test environment.>

MasonX::Apache2Handler is a clone of HTML::Mason::ApacheHandler
changed to work under a pure mod_perl2 environment. The external
interface is unchanged, see
L<HTML::Mason::ApacheHandler|ApacheHandler>.

The actual changes I made can be found in the distribution in
B<diff/ApacheHandler.diff> ( made with 'diff -Naru' ... ).

A HOTWO for MasonX::Apache2Handler may be found at
L<HOWTO Run Mason with mod_perl2|Mason-with-mod_perl2>.

=head1 PREREQUISITES

You must have the following packages installed:

    mod_perl        => 1.9910
    HTML::Mason'    => 1.25
    libapreq2       => 2.02-dev

Please refer to the original packages' documentation
for instructions.

=head1 SEE ALSO

My documents, including:
L<HOWTO Run Mason with mod_perl2|Mason-with-mod_perl2>,
L<MasonX::Request::WithApache2Session|WithApache2Session>,
L<MasonX::Request::WithMulti2Session|WithMulti2Session>,

Original Mason documents, including:
L<HTML::Mason::ApacheHandler|ApacheHandler>,
L<MasonX::Request::WithApacheSession|WithApacheSession>,
L<MasonX::Request::WithMultiSession|WithMultiSession>.

Also see the Mason documentation at L<http://masonhq.com/docs/manual/>.

=head1 AUTHOR

Beau E. Cox <beau@beaucox.com> L<http://beaucox.com>.

The real authors (I just made mod_perl2 changes) are the Mason crew, including:
Jonathan Swartz <swartz@pobox.com>,
Dave Rolsky <autarch@urth.org>,
Ken Williams <ken@mathforum.org>.

Version 0.05 as of April, 2004.

=cut
