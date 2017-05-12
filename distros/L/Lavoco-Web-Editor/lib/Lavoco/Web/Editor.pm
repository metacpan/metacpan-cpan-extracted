package Lavoco::Web::Editor;

use 5.006;

use Moose;

use Data::Dumper;
use DateTime;
use Digest::SHA1  qw(sha1_hex);
use Encode;
use File::Slurp;
use FindBin qw($Bin);
use JSON;
use Log::AutoDump;
use Plack::Handler::FCGI;
use Plack::Request;
use Template;
use Term::ANSIColor;
use Time::HiRes qw(gettimeofday);

$Data::Dumper::Sortkeys = 1;

=head1 NAME

Lavoco::Web::Editor - FastCGI app to edit flat-files.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

$VERSION = eval $VERSION;

=head1 SYNOPSIS

This application was originally designed to aid in the editing of basic templates for a L<Lavoco::Web::App> project.

 use Lavoco::Web::Editor;
 
 my $editor = Lavoco::Web::Editor->new;
 
 my $action = lc( $ARGV[0] );   # (start|stop|restart)
 
 $editor->$action;

=cut

=head1 METHODS

=head2 Class Methods

=head3 new

Creates a new instance of the editor object.

=head2 Attributes

=cut

has  processes => ( is => 'rw', isa => 'Int',  default => 5         );
has _base      => ( is => 'rw', isa => 'Str',  lazy => 1, builder => '_build__base'     );
has _pid       => ( is => 'rw', isa => 'Str',  lazy => 1, builder => '_build__pid'      );
has _socket    => ( is => 'rw', isa => 'Str',  lazy => 1, builder => '_build__socket'   );
has  filename  => ( is => 'rw', isa => 'Str',  lazy => 1, builder => '_build_filename'  );
has  config    => ( is => 'rw', isa => 'HashRef' );

sub _build__base
{
    return $Bin;
}

sub _build__pid
{
    my $self = shift;

    return $self->_base . '/editor.pid';
}

sub _build__socket
{
    my $self = shift;

    return $self->_base . '/editor.sock';
}

sub _build_filename
{
    my $self = shift;

    return $self->_base . '/editor.json';
}

=head3 processes

Number of FastCGI process to spawn, 5 by default.

=head3 filename

Filename for the config file, default is C<editor.json> and only JSON is currently supported.

=head3 config

The loaded config as a hash-reference.

=head2 Instance Methods

=head3 start

Starts the FastCGI daemon.  Performs basic checks of your environment and config, dies if there's a problem.

=cut

sub start
{
    my $self = shift;

    if ( -e $self->_pid )
    {
        print "PID file " . $self->_pid . " already exists, I think you should kill that first, or specify a new pid file with the -p option\n";
        
        return $self;
    }

    $self->_init;

    print "Building FastCGI engine...\n";
    
    my $server = Plack::Handler::FCGI->new(
        nproc      =>   $self->processes,
        listen     => [ $self->_socket ],
        pid        =>   $self->_pid,
        detach     =>   1,
    );
    
    $server->run( $self->_handler );
}

sub _init
{
    my ( $self, %args ) = @_;

    ###############################
    # make sure there's a log dir #
    ###############################

    printf( "%-50s", "Checking logs directory");

    my $log_dir = $self->_base . '/logs';

    if ( ! -e $log_dir || ! -d $log_dir )
    {
        _print_red( "[ FAIL ]\n" );
        print $log_dir . " does not exist, or it's not a folder.\nExiting...\n";
        exit;
    }

    _print_green( "[  OK  ]\n" );

    ########################
    # load the config file #
    ########################

    printf( "%-50s", "Checking config");

    if ( ! -e $self->filename )
    {
        _print_red( "[ FAIL ]\n" );
        print $self->filename . " does not exist.\nExiting...\n";
        exit;
    }

    my $string = read_file( $self->filename, { binmode => ':utf8' } );

    my $config = undef;

    eval {
        $config = decode_json $string;
    };

    if ( $@ )
    {
        _print_red( "[ FAIL ]\n" );
        print "Config file error...\n" . $@ . "Exiting...\n";
        exit;
    }

    ###################################
    # basic checks on the config file #
    ###################################

    if ( $config->{ password } && ! exists $config->{ salt } )
    {
        _print_red( "[ FAIL ]\n" );
        print "'password' attribute but no 'salt'.\nExiting...\n";
        exit;
    }

    if ( exists $config->{ files } && ref $config->{ files } ne 'ARRAY' )
    {
        _print_red( "[ FAIL ]\n" );
        print "'files' attribute is not a list.\nExiting...\n";
        exit;
    }

    if ( exists $config->{ folders } && ref $config->{ folders } ne 'ARRAY' )
    {
        _print_red( "[ FAIL ]\n" );
        print "'folders' attribute is not a list.\nExiting...\n";
        exit;
    }

    if ( exists $config->{ uploads } && ref $config->{ uploads } ne 'ARRAY' )
    {
        _print_red( "[ FAIL ]\n" );
        print "'uploads' attribute is not a list.\nExiting...\n";
        exit;
    }

    _print_green( "[  OK  ]\n" );

    return $self;
}

sub _print_green 
{
    my $string = shift;
    print color 'bold green'; 
    print $string;
    print color 'reset';
}

sub _print_orange 
{
    my $string = shift;
    print color 'bold orange'; 
    print $string;
    print color 'reset';
}

sub _print_red 
{
    my $string = shift;
    print color 'bold red'; 
    print $string;
    print color 'reset';
}

=head3 stop

Stops the FastCGI daemon.

=cut

sub stop
{
    my $self = shift;

    if ( ! -e $self->_pid )
    {
        return $self;
    }
    
    open( my $fh, "<", $self->_pid ) or die "Cannot open pidfile: $!";

    my @pids = <$fh>;

    close $fh;

    chomp( $pids[0] );

    print "Killing pid $pids[0] ...\n"; 

    kill 15, $pids[0];

    return $self;
}

=head3 restart

Restarts the FastCGI daemon, with a 1 second delay between stopping and starting.

=cut

sub restart
{
    my $self = shift;
    
    $self->stop;

    sleep 1;

    $self->start;

    return $self;
}

=head1 CONFIGURATION

The editor app should be a simple Perl script in a folder with the following structure:

 editor.pl      # see the synopsis
 editor.json    # config, see below
 editor.pid     # generated, to control the process
 editor.sock    # generated, to accept incoming FastCGI connections
 logs/
 
The config file is read for each and every request, so you can reasonably enable editing of the editors own config file.

See the C<examples> directory for a sample JSON config file, similar to the following...

 {
     "files"    : [
         "app.json",
         "site/style.css"
     ],
     "folders"  : [
         "templates/content/organic",
         "templates/content/store"
     ],
     "uploads"  : [
         "site/images"
     ],
     "password" : "foo",
     "salt"     : "abc123"
 }

Three fields which drive the editor are C<files>, C<folders> and C<uploads>, each of which is an array of paths, all relative to the base directory of the editor script.

Files in the C<files> list are editable, but the editor can not create new files in their respective containing directories.

All visible files in the C<folders> are editable, but not sub-directories, you need to add those separately.  The editor can also create new files in each folder.

The editor can upload files into any of the C<uploads> folders.

If there is a defined C<password> in the config, then this will be requested before a user can access the index page (listing all files that can be edited).

When using a C<password>, a C<salt> is also required, just create a random string, it's simply concatenated to the password before SHA-hashing and setting as a cookie.

=cut

# returns a code-ref for the FCGI handler/server.

sub _handler
{
    my $self = shift;

    return sub {

        ##############
        # initialise #
        ##############

        my $req = Plack::Request->new( shift );

        my $res = $req->new_response;

        my %stash = (
            app      => $self,
            req      => $req,
            now      => DateTime->now,
            started  => join( '.', gettimeofday ),
        );

        my $log = Log::AutoDump->new( base_dir => $stash{ app }->_base . '/logs', filename => 'editor.log' );

        $log->debug("Started");

        my $path = $req->uri->path;

        $log->debug( "Requested path: " . $path ); 

        $log->debug( $req->parameters );

        $stash{ app }->_reload_config( log => $log );

        ###############################
        # check for password required #
        ###############################

        my $template = 'login.tt';

        if ( ! exists $stash{ app }->config->{ password } )
        {
            $log->debug( "No password set, so going straight to index.tt" );

            $template = 'index.tt';
        }
        else
        {
            if ( exists $req->parameters->{ password } )
            {
                if ( $req->parameters->{ password } eq $stash{ app }->config->{ password } )
                {
                    $res->cookies->{ password } = sha1_hex( $stash{ app }->config->{ salt } . $stash{ app }->config->{ password } );

                    $template = 'index.tt';
                }
                else
                {
                    $res->cookies->{ password } = '';
                }
            }
            elsif ( $req->cookies->{ password } )
            {
                $log->debug( "We have a cookie for a password" );

                if ( $req->cookies->{ password } eq sha1_hex( $stash{ app }->config->{ salt } . $stash{ app }->config->{ password } ) )
                {
                    $log->debug( "Cookie matches sha1 hash" );

                    $template = 'index.tt';
                }
            }
        }

        if ( $template ne 'login.tt' )
        {
            my @files   = ();
            my @folders = ();
            my @uploads = ();

            #########
            # files #
            #########

            if ( exists $stash{ app }->config->{ files } )
            {       
                foreach my $file ( @{ $stash{ app }->config->{ files } } )
                {
                    $file =~ s/^\///g;   # remove leading slashes
                    $file =~ s/\/$//g;   # remove trailing slashes

                    $log->debug( "Processing file: " . $file );

                    if ( -f $stash{ app }->_base . '/' . $file )
                    {
                        push @files, $file;
                    }
                }
            }

            ###########
            # folders #
            ###########

            if ( exists $stash{ app }->config->{ folders } )
            {
                foreach my $folder ( @{ $stash{ app }->config->{ folders } } )
                {
                    $folder =~ s/^\///g;   # remove leading slashes
                    $folder =~ s/\/$//g;   # remove trailing slashes

                    $log->debug( "Processing folder: " . $folder );

                    my $path = $stash{ app }->_base . '/' . $folder;

                    if ( -d $path )
                    {
                        my %folder = ( path => $folder, files => [ ] );

                        opendir( my $dh, $path ) || $log->debug("Can't opendir $path: $!");

                        push @{ $folder{ files } }, sort { $a cmp $b } grep { ! -d ( $stash{ app }->_base . '/' . $folder . '/' . $_ ) } grep { $_ !~ /^\./ } readdir( $dh );

                        closedir( $dh );

                        push @folders, \%folder;
                    }
                }
            }

            ###########
            # uploads #
            ###########

            if ( exists $stash{ app }->config->{ uploads } )
            {
                foreach my $upload ( @{ $stash{ app }->config->{ uploads } } )
                {
                    $upload =~ s/^\///g;   # remove leading slashes
                    $upload =~ s/\/$//g;   # remove trailing slashes

                    $log->debug( "Processing upload: " . $upload );

                    my $path = $stash{ app }->_base . '/' . $upload;

                    if ( -d $path )
                    {
                        my %upload = ( path => $upload, files => [ ] );

                        opendir( my $dh, $path ) || $log->debug("Can't opendir $path: $!");

                        push @{ $upload{ files } }, sort { $a cmp $b } grep { ! -d ( $stash{ app }->_base . '/' . $upload . '/' . $_ ) } grep { $_ !~ /^\./ } readdir( $dh );

                        closedir( $dh );

                        push @uploads, \%upload;
                    }
                }
            }

            ######################################
            # if we've requested a file, edit it #
            ######################################

            if ( exists $req->parameters->{ file } && ! exists $req->parameters->{ folder } && ! $req->parameters->{ upload } )
            {
                foreach my $file ( @files )
                {
                    next if $file ne $req->parameters->{ file };

                    $stash{ file } = $req->parameters->{ file };

                    $template = 'edit.tt';

                    if ( ! exists $req->parameters->{ content } )
                    {
                        $log->debug( "Reading content of " . $stash{ app }->_base .  '/' . $file );

                        $stash{ content } = read_file( $stash{ app }->_base . '/' . $file, { binmode => ':utf8' } );
                    }
                    else
                    {

                        if ( $req->parameters->{ file } =~ /\.json/ )
                        {
                            $log->debug( "It's a JSON file" );

                            #########################
                            # basic json validation #
                            #########################

                            eval {
                                my $json = JSON->new;

                                $json->relaxed( 1 );

                                $json->decode( $req->parameters->{ content } );
                            };
                            
                            $log->debug( $@ ) if $@;

                            $stash{ error } = $@ if $@;
                        }

                        if ( ! exists $stash{ error } )
                        {
                            write_file( $stash{ app }->_base . '/' . $file, { binmode => ':utf8' }, $req->parameters->{ content } );

                            $stash{ success } = "Saved OK";
                        }

                        $stash{ file } = $req->parameters->{ file };

                        $stash{ content } = $req->parameters->{ content };
                    }                    
                }
            }
            elsif ( exists $req->parameters->{ folder } )
            {
                foreach my $folder ( @folders )
                {
                    next if $folder->{ path } ne $req->parameters->{ folder };

                    $stash{ folder } = $req->parameters->{ folder };

                    $template = 'edit.tt';

                    if ( $req->parameters->{ file } )
                    {
                        foreach my $file ( @{ $folder->{ files } } )
                        {
                            next if $file ne $req->parameters->{ file };

                            $stash{ file } = $req->parameters->{ file };

                            if ( ! exists $req->parameters->{ content } )
                            {
                                $log->debug( "Reading content of " . $stash{ app }->_base . '/' . $folder->{ path } . '/' . $file );

                                $stash{ content } = read_file( $stash{ app }->_base . '/' . $folder->{ path } . '/' . $file, { binmode => ':utf8' } );
                            }
                        }
                    }

                    if ( exists $req->parameters->{ content } )
                    {
                        $log->debug( "We've got some content" );

                        if ( $req->parameters->{ file } =~ /\.json/ )
                        {
                            $log->debug( "It's a JSON file" );

                            #########################
                            # basic json validation #
                            #########################

                            eval {
                                my $json = JSON->new;

                                $json->relaxed( 1 );

                                $json->decode( $req->parameters->{ content } );
                            };
                            
                            $log->debug( $@ ) if $@;

                            $stash{ error } = $@ if $@;
                        }

                        if ( ! exists $stash{ error } )
                        {
                            write_file( $stash{ app }->_base . '/' . $folder->{ path } . '/' . $req->parameters->{ file }, { binmode => ':utf8' }, $req->parameters->{ content } );
                        
                            $stash{ success } = "Saved OK";
                        }

                        $stash{ file } = $req->parameters->{ file };

                        $stash{ content } = $req->parameters->{ content };
                    }
                }
            }
            elsif ( exists $req->parameters->{ upload } )
            {
                foreach my $upload ( @uploads )
                {
                    next if $upload->{ path } ne $req->parameters->{ upload };

                    $stash{ upload } = $req->parameters->{ upload };

                    if ( my $uploaded = $req->upload('file') )
                    {
                        $log->debug( "Moving file from " . $uploaded->path . " to " . $stash{ app }->_base . '/' . $upload->{ path } . '/' . $uploaded->filename );

                        rename $uploaded->path, $stash{ app }->_base . '/' . $upload->{ path } . '/' . $uploaded->filename;

                        $res->redirect( '/' );

                        return $res->finalize;
                    }
    
                    if ( exists $req->parameters->{ delete } )
                    {
                        $log->debug( "Attempting to delete " . $stash{ app }->_base . '/' . $upload->{ path } . '/' . $req->parameters->{ delete } );

                        unlink $stash{ app }->_base . '/' . $upload->{ path } . '/' . $req->parameters->{ delete };

                        $res->redirect( '/' );

                        return $res->finalize;
                    }
                }
            }

            $stash{ files   } = \@files;
            $stash{ folders } = \@folders;
            $stash{ uploads } = \@uploads;
        }

        ##############################
        # responding with a template #
        ##############################

        $stash{ error } =~ s/ at \/.*$// if exists $stash{ error };

        $res->status( 200 );

        my $tt = Template->new( ENCODING => 'UTF-8' );

        $log->debug("Processing template: " . $template );

        my $body = '';

        $tt->process( $stash{ app }->_template_tt( $template ), \%stash, \$body ) or $log->debug( $tt->error );

        $res->content_type('text/html; charset=utf-8');

        $res->body( encode( "UTF-8", $body ) );

        #########
        # stats #
        #########

        $stash{ took } = join( '.', gettimeofday ) - $stash{ started };
        
        $log->debug( "Took " . sprintf("%.5f", $stash{ took } ) . " seconds");

        return $res->finalize;
    }
}

sub _reload_config
{
    my ( $self, %args ) = @_;

    my $log = $args{ log };    

    $log->debug( "Opening config file: " . $self->filename );

    my $string = read_file( $self->filename, { binmode => ':utf8' } );

    my $config = undef;

    eval {
        $self->config( decode_json $string );
    };

    $log->debug( $@ ) if $@;

    return $self;
}

# returns a scalar-ref to feed into TT

sub _template_tt
{
    my ( $self, $template ) = @_;

    my $string = '';

    if ( $template eq 'login.tt' )
    {
        $string = <<EOF;
<html>
    <head>
        <style>
            body { font-family: Tahoma,Arial,Helvetica,sans-serif; }
        </style>
    </head>

    <body>

        <h1>Website Content Editor</h2>

        <form action="/" method="POST">
            <input type="text" name="password" value="" style="float: left; clear: both;">

            <input type="submit" value="Login" style="float: left; clear: both;">
        </form>

    </body>

</html>

EOF
    }
    elsif ( $template eq 'index.tt' )
    {
        $string = <<EOF;
<html>
    <head>
        <style>
            body { font-family: Tahoma,Arial,Helvetica,sans-serif; }
            ul li { margin-top: 5px; }
            a,a:visited { color: #0000EE; }
        </style>
    </head>

    <body>

        <h1>Website Content Editor</h2>

        <h3><a href="/?password=">Logout</a></h3>

        <ul>
[% FOREACH folder IN folders %]
            <li>
                <strong>[% folder.path %]/</strong> [ <a href="/?folder=[% folder.path | uri %]">create new file</a> ]
                <ul>
    [% FOREACH file IN folder.files %]
                    <li><a href="/?folder=[% folder.path | uri %]&amp;file=[% file | uri%]">[% file %]</a></li>
    [% END %]
                </ul>
            </li>
[% END %]
[% IF files.size %]
            <li><strong>/</strong>
                <ul>
    [% FOREACH file IN files %]
                    <li><a href="/?file=[% file | uri%]">[% file %]</a></li>
    [% END %]
                </ul>
            </li>
[% END %]
        </ul>

[% IF uploads.size %]
        <h3>Uploads</h3>
        <ul>
    [% FOREACH upload IN uploads %]
            <li>
                <strong>[% upload.path | html %]/</strong>
                <form action="/" enctype="multipart/form-data" method="post">
                    <input type="hidden" name="upload" value="[% upload.path | html %]">
                    <input type="file" name="file">
                    <input type="submit" value="Upload">
                </form>
                <ul>
    [% FOREACH file IN upload.files %]
                    <li>[% file %] [ <a href="/?upload=[% upload.path | html %]&amp;delete=[% file | html %]">delete</a> ]</li>
    [% END %]
                </ul>
            </li>
    [% END %]
        </ul>
[% END %]
    </body>

</html>

EOF
    }
    elsif ( $template eq 'edit.tt' )
    {
        $string = <<EOF;
<html>
    <head>
        <style>
            body { font-family: Tahoma,Arial,Helvetica,sans-serif; }
            a,a:visited { color: #0000EE; }
        </style>
    </head>

    <body>

        <h1><a href="/">Website Content Editor</a></h2>

        <h2>[% folder %]/[% file %][% IF success %] - <span style="color: #0c0;">[% success %]</span>[% END %][% IF error %] - <span style="color: #f00;">[% error %]</span>[% END %]</h2>

        <form action="/" method="POST">
            [% IF folder %]        
            <input type="hidden" name="folder" value="[% folder | html %]">
            [% END %]
            [% IF file %]
            <input type="hidden" name="file" value="[% file | html %]">
            [% ELSE %]
            <label for="file">New filename</label>
            <input type="text" id="file" name="file" value="" style="margin-bottom: 10px;">
            [% END %]
            <textarea name="content" style="float: left; width: 100%; height: 600px;">[% content | html %]</textarea>

            <input type="submit" value="Save Changes" style="float: left; clear: both;">
        </form>

    </body>

</html>

EOF
    }

    return \$string;
}

=head1 TODO

Allow absolute paths to any part of the filesystem?

=head1 AUTHOR

Rob Brown, C<< <rob at intelcompute.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Rob Brown.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

