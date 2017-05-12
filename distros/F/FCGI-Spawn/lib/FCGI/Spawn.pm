package FCGI::Spawn;

use vars qw($VERSION);

BEGIN {
    $VERSION              = '0.16.7';
    $FCGI::Spawn::Default = 'FCGI::Spawn';
}

=pod

=head1 NAME

 FCGI::Spawn - FastCGI server for CGI-like applications effective multiprocessing

=head1 SYNOPSIS

Minimum unrecommended way to illustrate it working:

	FCGI::Spawn->new->spawn;

Never put this in production use. The C<fcgi_spawn> script supplied should care about sadly mandatory whistles and bells, at least the security is a king in sight of this:

FCGI::Spawn code should be run as its own user id, and the web server should be configured to request its FastCGI; in the case the local socket file is used, the web server should have the read and write permissions on it, the default name is /tmp/spawner.sock.
Consider about sock_chmod/sock_chown parameters for this, too.


In the case if you request via TCP care should be taken on network security like DMZ/VPN/firewalls setup instead of sock_* parameters.

About the ready to run applications compatibility refer to C<fcgi_spawn> docs.

Every other thing is explained in L<FCGI::ProcManager|FCGI::ProcManager> docs.

=head1 DESCRIPTION

The overall idea is to make Perl server-side scripts as convinient for newbies and server administrators as PHP in FastCGI mode.

FCGI::Spawn is used to serve as a FastCGI process manager.
Besides  the features the FCGI::ProcManager posess itself, the FCGI::Spawn is targeted as web server admin understandable instance for building the own fastcgi server with copy-on-write memory sharing among forks and with single input parameters like the limits on the number of processes and maximum requests per fork.

Another thing to mention is that it is able to execute any file pointed by Web server ( FastCGI requester ).
So we have the daemon that is hot ready for hosting providing :-)

The definitive care is taken in FCGI::Spawn on security.
Besides the inode settings on local UNIX socket taken as input parameter, it is aware to avoid hosting users from changing the max_requests parameter meant correspondent to MaxRequests Apache's forked MPM parameter, and the respective current requests counter value as well.

The aforementioned max_requests parameter takes also care about the performance to avoid forks' memory leaks to consume all the RAM accounted on your hardware.

For shared hosting it is assumed that system administrator controls the process manager daemon script contents with those user hardware consumption limits and executes it with a user's credentials.
E. g., the user should be able to send signal to the daemon to initiate graceful restart on his/her demand ( this is yet to be done ) or change the settings those administrator can specifically allow in the daemon starter script without restart ( both of those features are about to be done in the future ).

The call stack lets you set up your own code reference for your scripts execution. Also, feature exists that you can cache some object, like the template or XSLT processor and the recompilation to happen only on the template or xsl file(s) change. Environment variables can be preserved from changing in CGI programs, too. Those features are new in 0.16.

Seeking for convention between high preformance needs that the perl compile cache possess and the convinience of debugging with recompilation on every request that php provides, the C<stats> feature allows you not to recompile the tested source like those of DBI and frameworks but focus the development on your application only, limiting the recompilation with your application(s) namespace(s) only.
This may be useful in both development environment to make the recompilation yet faster and on a production host to make the details of code adaptaion to hosting clear in a much less time needed.

=head1 Behind the scenes of fcgi_spawn

Here are the details for those unsatisfied with C<fcgi_spawn> but trying with FCGI::Spawn anyway:

=over

=item * You must configure socket

with %ENV or shell and tweak the CGI.pm with the patch supplied, if need, at early before use FCGI::Spawn.  

%ENV and @INC can be tweaked in the special BEGIN block or you can eval "use FCGI::Spawn;" otherwise.
This is because of setting up the socket communication in the CGI::Fast, which is the part of Perl core distribution, right in the BEGIN block, e. g. right before the compilation.

=item * You should beware about CGI::Fast IS NOT included

at the moment this module is being used, e. g. IS ABSENT in the %INC global hash.

=item * CGI scripts ( if not CGI.pm ) must be tweaked to use $FCGI::Spawn::fcgi instead of new CGI or CGI->new.

In other case they will not be able to process HTTP POST.

In some caeses ( e. g. Bugzilla that derives CGI.pm ) the sources should be changed, too.
Hope your code obfuscators are not that complex to allow such a tweak. ;-)
FastCGI scripts do take the FastCGI object as a parameter, so it is obviously supplied in the callout code reference ( see below ).

=back

=head2 Why not mod_perl/mod_perl2/mod_fcgid?

=over

=item * Memory consumption

With FCGI::Spawn every fork weghts less in your "top".
Thus it is less hard to see the system load while forks' memory being swapped out and losing its copy-on-write kernel facility.
Every fork stops sharing its memory in this case.

=item * Memory sharing

With mod_fcgid, the compiled Perl code is not being shared among forks by far.

=item * Too much need for root

The startup.pl providing the memory sharing among forks is aimed to be run as root, at least when you need to listen binded to ports numbered less than 1024, for example, 80.
And, the root user ( the human ) is often too busy to check if that massive code is secure enough to be run as root system user ( the effective UID ) Thus, it's no much deal to accelerate Perl on mod_perl steroids if the startup.pl includes rather small code for reuse.

Root is needed to recompile the Perl sources, at least with the useful Registry handler.
It is obvious to gracefully restart Apache once per N minutes and this is what several hosting panel use to do but it is not convinient to debug code that is migrated from developer's hosting to production's  as it is needed to be recompiled on webmaster's demand that use to happen to be no sense for server's admin.
And, with no ( often proprietary ) hosting panel software onboard, Apache doesn't even gracefully restart on a regular basis without special admin care taken at server setup time.
On the uptime had gone till the need of restart after launch it is not an admin favor to do this, even gracefully.
Apache::Reload can save from this but it's not a production feature, too.

=item * File serving speed loss

Apache itself is well known to serve the static files too slowly.
Despite the promises of "we do this too" on sendfile and kqueue features.

=item * More stuff on your board overheads administering

The unclear differences between the bundled PerlHandler-s environments among with the more code to compile and depend on, causes the root changes are needed in the existing, mostly CGI, programs.

=back

=head2 Why still mod_perl?

=over

=item * the Habit

.

=item * Apache::DBI

Persistent connections feature makes it slightly faster for skip connect to DB stage on every request.

=item * Apache::Request, Apache::Session, etc.

HTTP input promises to be much more effective than the CGI.pm's one, used in CGI::Fast, too.
You may need also more information about request, like full incoming headers, too.
Those are obvious to be contained in the Apache internal structures rather than outsourced with application protocol from web server.

=back

=head2 Why not simply FCGI::ProcManager?

Targeted as a library for a single particular application or applications' framework, it takes you to make FCGI::Spawn and fcgi_spawn to obtain the ready to use application-agnostic daemon.
It seems to require too much in Perl knowledge from regular system administrator ( same as for startup.pl audit goes here ), in comparison to php's fastcgi mode.
Even with that, it is not as mock as FCGI::Spawn for software developer.
You will need to be me if you will need its features, if you are a sysadmin, while I'm the both.

=head1 PREREQUISITES

Be sure to have L<FCGI::ProcManager|FCGI::ProcManager>.

=head1 METHODS


=head2 new({hash parameters})

Class method.
Constructs a new process manager.
 Takes an option hash of the sock_name and sock_chown initial parameter values, and passes the entire hash rest to ProcManager's constructor.
The parameters are:

=over

=item * $ENV{FCGI_SOCKET_PATH} 

Not a hash parameter but the enironment variable.
Should be set before module compilation, to know where the socket resides.
Can be in the host:port or even :port notation for TCP, as FCGI.pm's remote.fpl states.
Default: /tmp/spawner.sock.

You can set environment value with your shell like this:

FCGI_SOCKET_PATH=/var/lib/fcgi.sock ./fcgi_spawn.pl <parameters>

or you can enclose it into the eval() like that:

 $ENV{FCGI_SOCKET_PATH}  = '/var/lib/fcgi.sock';
 eval( "use FCGI::Spawn;" ); die $@ if $@;

=item * sock_chown 

is the array reference which sets the parameters for chown() builtin on newly created socket, when needed.
Default: none.

=item * readchunk 

is the buffer size for user's source reading in plsrc function.
Deprecated and will be removed in future versions.
Default: 4096.

=item * maxlength 

is the maximumum user's file size for the same.
Default: 100000.

=item * max_requests 

is the maximum requests number served by every separate fork.
Default: 20.

=item * stats 

Whether to do or not to do the stat() on every file on the %INC to recompile on change by mean of removal from %INC.
Default: 1.

=item * stats_policy 

Array reference that defines what kind of changes on the every module file stat()'s change to track and in what order.
Default: FCGI::Spawn::statnames_to_policy( 'mtime' ) ( statnames_to_policy() function is described below ).

=item * x_stats  and x_stats_policy

Same as stats and stats_policy but for xinc() feature ( see below ).

=item * clean_inc_hash 

when set to 1 points to clean out the requested via FastCGI file from %INC after every procesed request.

when set to 2 points to clean out  after every procesed request the every %INC change that the FastCGI requested file did.

Default: 0.

=item * clean_main_space

when set to true points to clean out the %main:: changes ( unset the global variables ) at the same time.
Default: 0.

=item * clean_inc_subnamespace

Points which namespace, and beneath, should be cleaned in the moment between callouts ( e. g., Bugzilla, WebGUI, MyApp::MyClass etc., depending upon what is your applications name ).

when is a scalar, makes the %INC to clean if the begin of the key equals to it.

when is array reference, treats every element as a scalar and does the same for every item, just the same if it was the scalar itself

You can use :: namespace separator, as well as / as it is in the %INC, both MyApp::MyNS and MyApp/MyNS are pretty valid.
You can use full file names, like this: 'path/required_lib.pl' for this argument, too.

As of high-load systems it is strongly discouraged that the hosting user ( who can happen to be a really bad programmer ) to control this parameter, as it can lead to the same as clean_inc_hash=2 and can steal server performance at the moment just unwanted for system administrator.
ulimit is a good thing to keep from such a bothering too, but it's just not always sufficient alone. And, no ulimit on Cygwin by far.
Default: empty.

=item * callout 

is the code reference to include the user's file by your own.
Its input parameters are the script name with full path and the FastCGI object, the CGI::Fast instance.
Default is to use trivial do() builtin this way:

  sub{  
    do shift;
  }

If use C<fcgi_spawn>, you must define your own callout with exit() redefinition  and it should contain the CALLED_OUT label inside.

=item * save_env

should the %ENV ( environment variables ) be restored after every callout.
Default: 1.

=item * procname

should the $0 ( executed file name in the OS process list ) be set to called out file name before and restored back after every callout.
Default: 1.

=back

Every other parameter is passed "as is" to the FCGI::ProcManager's constructor.
Except for addition about the  n_processes, which defaults to 5.

=head2 prepare

Instance method.
Performs C<fork()>s by mean of L<FCGI::ProcManager/pm_manage> and necessary preparational steps. It is executed, if not yet, by:

=head2 spawn

Instance method.
Fork a new process handling request like that being processed by web server. Performs prepare() if object is not yet prepared.

=head2 callout

Instance method.
performs user's code execution. Isolates the max_requests, environment and current requests counter values from changing in the user's source. Performs the remembering of the included Perl modules files and the files for the xinc() feature, too.

=head2 xinc( '/path/to/file', $ref );

Static function.
Returns the previous result of the function referenced by $ref called with file as the argument.
Typical usage is the template compilation.
Those get recompiled in the case the files were changed. Depends on x_stats and x_stats_policy properties.

If the $ref is an array reference, then it is expected to contain the file names with full path those depend on the followed parameter, file name.
This is useful in the case when one template file includes another, and so on.
For example, the included file should be the '/path/to/header_or_footer_file'  in this case, and the next parameter is [ '/path/to/index_page_template', '/path/to/landing_page_template', ... ] with all the dependent files mentioned.
Those dependent files should be xinc()'ed  at the end of the every xinc() chain with the code reference.

=head2 plsrc

Static function.
Reads the supplied parameter up to "maxlength" bytes size chunked by "readchunk" bufer size and returns string reference.
Deprecated and will be removed in future versions.

=head2 statnames_to_policy( 'mtime', 'ctime', ... );

Static function.
Convert the list of file inode attributes' names checked by stat() builtin to the list of numbers for it described in the perldoc -f stat .
 In the case if the special word 'all' if met on the list, all the attributes are checked besides 'atime' (8).
Also, you can define the order in which the stats are checked to reload perl modules: if the change is met, no further checks of this list for particular module on particular request are made as a decision to recompile that source is already taken.
This is the convinient way to define the modules reload policy, the 'stat_policy' object property, among with the need in modules' reload itself by the 'stats' property checked as boolean only.

=head1 Thanks, Bugs, TODOs, Pros and Contras ( The Etcetera )

=head2 The Inclusion

Arbitrary source file can be included to supply the response in this way:

=over

=item the built-in: do()

.

=item system() or exec()

Useful for debugging.
Makes your FastCGI server to act as the simple CGI, except POST input requires complex trick:

 use Time::Local qw/timegm/;
 use POSIX qw/strftime/;

 use IPC::Run3;
 use IPC::Run::SafeHandles;
 use CGI::Util qw/escape/;
 use IO::File;
 use HTTP::Request::Common;
	...

  $spawn->{	callout } = sub{ 
    my( $sn, $fcgi ) = @_; 
    my( $in, $out, $err ) ;
    IF( $env{'REQUEST_METHOD'} eq 'POST' ){
    		$in = HTTP::Request::Common::POST( $ENV{'REQUEST_URI'},
    			"Content_Type" => $ENV{'CONTENT_TYPE'},
    			"Content" => [ 
    				map { 
    							my $val = $FCGI::Spawn::fcgi->param( $_ );
    							if( 'Fh' eq ref $val ){
    								$val =  [ ${ $FCGI::Spawn::fcgi->{'.tmpfiles'}->{
    										 ${ $FCGI::Spawn::fcgi->param( $_ ) }
    									}->{name} },
    									$FCGI::Spawn::fcgi->param( $_ ) ,
    								];
    							}
    							$_ => $val 
    						}
    							$FCGI::Spawn::fcgi->param
    			],   
    		)->content;
    		$ENV{ CONTENT_LENGTH } = 
    		$ENV{ HTTP_CONTENT_LENGTH } = 
    		length $in;
    }
    my $pid = run3( $sn, \$in, \$out, \$out ) or die $!;
    print $out;
  };

One also can write the own inclusion code it by self defining the:

=item your own CODE ref

is able to be set by the "callout" initial parameter and/or "callout" object property.

=back

=head2 Bugs and TODOs

Tracked and to be reported at:

L<http://bugs.vereshagin.org/product/FCGI%3A%3ASpawn>

Development repository is at: L<git://github.com/petr999/fcgi-spawn.git>.


=head2 Tested Environments

Nginx everywhere.

=over

=item * FreeBSD and local UNIX sockets

.

=item * Win32 and TCP sockets

No surprise, Cygwin rocks.
No ActiveState Perl can do this, sorry --- as it can't FCGI::ProcManager which is a must.
And, surprise, the response time difference over CGI is dramatically better because of it's way more expensive on resources to launch a new process on this platform ( Cygwin emulates fork()s with native threads those are much faster ).

=back

=head2 Downloads

Tar.gz at CPAN, as always.

Sourceforge has latest development snapshot: L<http://fcgi-spawn.git.sourceforge.net/git/gitweb.cgi?p=fcgi-spawn/fcgi-spawn;a=snapshot;h=HEAD;sf=tgz> .

=head1 AUTHOR, LICENSE

Peter Vereshagin <peter@vereshagin.org>, L<http://vereshagin.org>.

License: same as FCGI::ProcManager's one. More info on FCGI::Spawn at: L<http://fcgi-spawn.sf.net>.

=cut

use strict;
use warnings;

use File::Basename;
use FCGI::ProcManager;
use base qw/Exporter/;

our @EXPORT_OK = qw/statnames_to_policy/;

our $fcgi = undef;
my %xinc = ();

my $maxlength = 100000;

BEGIN {
    die "CGI::Fast made its own BEGIN already!"
        if defined $INC{'CGI/Fast.pm'};
    $ENV{FCGI_SOCKET_PATH} = '/tmp/spawner.sock'
        if not exists $ENV{FCGI_SOCKET_PATH};
    if ( -e $ENV{FCGI_SOCKET_PATH} ) {
        ( [ -S $ENV{FCGI_SOCKET_PATH} ] && unlink $ENV{FCGI_SOCKET_PATH} )
            or die "Exists "
            . $ENV{FCGI_SOCKET_PATH}
            . ": not a socket or unremoveable";
    }
    eval("use CGI::Fast;");
    die $@ if $@;
}

my $readchunk = 4096;

# Deprecated and will be removed in future versions. And readchunk too.
sub plsrc {
    my $sn = shift;
    unless ( open PLSRC, $sn ) { exit $!; }
    my $plsrc = "";
    while ( my $rv = read( PLSRC, my $buf, $readchunk ) ) {
        unless ( defined $rv ) { exit $!; }
        $plsrc .= $buf;
        exit if length($plsrc) > $maxlength;
    }
    close PLSRC;
    return \$plsrc;
}

my $defaults = {
    n_processes            => 5,
    max_requests           => 20,
    clean_inc_hash         => 0,
    clean_main_space       => 0,
    clean_inc_subnamespace => [],
    callout                => sub {
        do shift;
    },
    stats          => 1,
    stats_policy   => statnames_to_policy('mtime'),
    x_stats        => 1,
    x_stats_policy => statnames_to_policy('mtime'),
    state          => {},
    seed_rand      => 1,
    save_env       => 1,
    procname       => 1,
    is_prepared    => 0,
};

sub statnames_to_policy {
    my %policies
        = qw/dev 0 ino 1 mode 2 nlink 3 uid 4 gid 5 rdev 6 size 7 atime 8 mtime 9 ctime 10 blksize 11 blocks 12/;
    grep( { $_ eq 'all' } @_ )
        ? [ 0 .. 7, 9 .. 12 ]
        : [ map( { $policies{$_} } @_ ) ];
}

sub new {
    my $class = shift;
    my ( $new_properties, $properties );
    if ( $properties = shift ) {
        $properties = { %$defaults, %$properties };
    }
    else {
        $properties = $defaults;
    }
    my $proc_manager = FCGI::ProcManager->new($properties);
    my $sock_name    = $ENV{FCGI_SOCKET_PATH};
    if ( defined $properties->{sock_chown} ) {
        chown( @{ $properties->{sock_chown} }, $sock_name )
            or die $!;
    }
    if ( defined $properties->{sock_chmod} ) {
        chmod( $properties->{sock_chmod}, $sock_name )
            or die $!;
    }
    defined $properties->{readchunk}
        and $readchunk = $properties->{readchunk};
    defined $properties->{maxlength}
        and $maxlength = $properties->{maxlength};

    $class->make_clean_inc_subnamespace($properties);

    $properties->{proc_manager} = $proc_manager;
    bless $properties, $class;
}

sub make_clean_inc_subnamespace {
    my ( $self, $properties ) = @_;
    my $cisns = $properties->{clean_inc_subnamespace};
    if ( '' eq ref $cisns ) {
        $cisns = [$cisns];
    }
    foreach (@$cisns) {
        $_ =~ s!::!/!g
            if '' eq ref $_;
    }
    $properties->{clean_inc_subnamespace} = $cisns;
}

sub _callout {
    my $self = shift;
    my %save_env = %ENV if $self->{save_env};
    my $procname;
    if ( $self->{procname} ) {
        $procname = $0;
        $0        = $_[0];
    }
    $self->{callout}->(@_);
    $0   = $procname if $self->{procname};
    %ENV = %save_env if $self->{save_env};
}

sub callout {
    my $self = shift;
    $self->_callout(@_);
    $self->postspawn_dispatch;
}

sub clean_inc_particular {
    my $self = shift;
    map {
        my $subnamespace_to_clean = $_;
        map { delete $INC{$_} }
            grep {
            $subnamespace_to_clean eq substr $_, 0,
                length $subnamespace_to_clean
            }
            keys %INC
    } @{ $self->{clean_inc_subnamespace} };
}

sub prepare {
    my $self         = shift;
    my $proc_manager = $self->{proc_manager};
    $proc_manager->pm_manage();
    $self->set_state( 'fcgi_spawn_main', {%main::} )
        if $self
            ->{clean_main_space}; # remember global vars set for cleaning in loop
    $self->set_state( 'fcgi_spawn_inc', {%INC} )
        if $self->{clean_inc_hash}
            == 2;                 # remember %INC to wipe out changes in loop
    srand if $self->{seed_rand};    # make entropy different among forks
    $self->{is_prepared} = 1;
}

sub spawn {
    my $self = shift;
    $self->prepare unless $self->{is_prepared};
    my ( $proc_manager, $max_requests, )
        = map { $self->{$_} } qw/proc_manager max_requests/;
    my $req_count = 0;

    #eval " use CGI::Fast; "; die $@ if $@;
    while ( $fcgi = new CGI::Fast ) {
        $proc_manager->pm_pre_dispatch();
        my $sn = $ENV{SCRIPT_FILENAME};
        my $dn = dirname $sn;
        my $bn = basename $sn;
        chdir $dn;
        $self->prespawn_dispatch( $fcgi, $sn );

       # Commented code is real sugar for nerds ;)
       #map { $ENV{ $_ } = $ENV{ "HTTP_$_" } } qw/CONTENT_LENGTH CONTENT_TYPE/
       #  if $ENV{ 'REQUEST_METHOD' } eq 'POST';	# for nginx-0.5
       # do $sn ; #or print $!.$bn; # should die on unexistent source file
       #	my $plsrc=plsrc $sn;	# should explanatory not
       #	eval $$plsrc;
        $self->_callout( $sn, $fcgi );
        $req_count++;
        CORE::exit if $req_count > $max_requests;
        $self->postspawn_dispatch;
        $proc_manager->pm_post_dispatch();
        undef $fcgi
            ; # CGI->new is likely to happen on CGI::Fast->new when CGI.pm is patched
    }
}

sub get_inc_stats {
    my $stat_src  = shift;
    my %inc_state = ();
    my $fns       = [ defined($stat_src) ? keys(%$stat_src) : values %INC ];
    foreach my $src_file (@$fns) {
        next unless defined($src_file) and -f $src_file;
        my $stat = [ stat $src_file ];
        $inc_state{$src_file} = $stat;
    }
    return \%inc_state;
}

sub set_state_stats {
    my ( $self, $pref, $stat_src ) = @_;
    my $stats_name = 'stats';
    $stats_name = $pref . "_$stats_name" if defined $pref;
    my $stats = get_inc_stats $stat_src;
    $self->set_state( $stats_name, $stats );
}

sub delete_inc_by_value {
    my $module   = shift;
    my @keys_arr = keys %INC;
    foreach my $key (@keys_arr) {
        my $value = $INC{$key};
        delete $INC{$key} if $value eq $module;
    }
}

sub postspawn_dispatch {
    my $self = shift;
    $self->set_state_stats
        if $self->{stats};    # remember %INC to wipe out changes in loop
    $self->set_state_stats( 'x', \%xinc )
        if $self->{x_stats};    # remember %xinc to wipe out changes in loop
}

sub prespawn_dispatch {
    my ( $self, $fcgi, $sn ) = @_;
    $fcgi->initialize_globals;  # to get rid of CGI::save_request consequences
    delete $INC{$sn}
        if exists( $INC{$sn} )
            and $self->{clean_inc_hash}
            == 1;               #make %INC to forget about the script included
      #map { delete $INC{ $_ } if not exists $fcgi_spawn_inc{ $_ } } keys %INC
    if ( $self->{clean_inc_hash} == 2 ) {   #if %INC change is unwanted at all
        my $fcgi_spawn_inc = $self->get_state('fcgi_spawn_inc');
        %INC = %$fcgi_spawn_inc;
    }
    $self->clean_inc_particular;
    $self->clean_inc_modified  if $self->{stats};
    $self->clean_xinc_modified if $self->{x_stats};
    if ( $self->{clean_main_space} ) {      # actual cleaning vars
        foreach ( keys %main:: ) {
            delete $main::{$_}
                unless $self->defined_state( 'fcgi_spawn_main', $_ );
        }
    }
}

sub xinc {
    my ( $fn, $cref ) = @_;
    my $rv = undef;
    if ( defined($fn) and defined($cref) and 'CODE' eq ref $cref ) {
        my $fref = ref $fn;
        if ( $fref eq '' ) {
            if ( defined $xinc{$fn} ) {
                $rv = $xinc{$fn};
            }
            else {
                $rv = $cref->($fn);
                $xinc{$fn} = $rv;
            }
        }
        elsif ( ( $fref eq 'ARRAY' ) and scalar @$fn ) {
            if ( defined $xinc{ $fn->[0] } ) {
                $rv = $xinc{ $fn->[0] };
            }
            else {
                $rv = $cref->(@$fn);
                $xinc{ $fn->[0] } = $rv;
            }
            if ( scalar @$fn > 1 ) {
                for ( my $i = 1; $i < scalar @$fn; $i++ ) {
                    my $arr_fn = $fn->[$i];
                    if ( defined( $xinc{$arr_fn} ) ) {
                        if ( 'ARRAY' eq ref $xinc{$arr_fn} ) {
                            push( @{ $xinc{$arr_fn} }, $fn->[0] )
                                unless grep { $_ eq $fn->[0] }
                                    @{ $xinc{$arr_fn} };
                        }
                        else {
                            die
                                "xinc: dependence $arr_fn is previously defined";
                        }
                    }
                    else {
                        $xinc{$arr_fn} = [ $fn->[0] ];
                    }
                }
            }
        }
    }
    return $rv;
}

sub clean_xinc_modified {
    my $self      = shift;
    my $old_stats = $self->get_state('x_stats');
    my $new_stats = get_inc_stats \%xinc;
    my $policy    = $self->{x_stats_policy};
    foreach my $item ( keys %$new_stats ) {
        my $modified = 0;
        if ( defined $old_stats->{$item} ) {
            my $new_stat = $new_stats->{$item};
            my $old_stat = $old_stats->{$item};
            foreach my $i (@$policy) {
                unless (defined( $new_stat->[$i] )
                    and defined( $old_stat->[$i] ) )
                {
                    $modified = 1;
                    last;
                }
                my $new_element = $new_stat->[$i];
                my $old_element = $old_stat->[$i];
                unless ( $new_element == $old_element ) {
                    $modified = 1;
                    last;
                }
            }
        }
        else {
            $modified = 1;
        }
        if ($modified) {
            if ( 'ARRAY' eq ref $xinc{$item} ) {
                map { delete( $xinc{$_} ) if defined $xinc{$_}; }
                    @{ $xinc{$item} };
            }
            delete $xinc{$item};
        }
    }
}

sub clean_inc_modified {
    my $self      = shift;
    my $old_stats = $self->get_state('stats');
    my $new_stats = get_inc_stats;
    my $policy    = $self->{stats_policy};
    foreach my $module ( keys %$new_stats ) {
        my $modified = 0;
        if ( defined $old_stats->{$module} ) {
            my $new_stat = $new_stats->{$module};
            my $old_stat = $old_stats->{$module};
            foreach my $i (@$policy) {
                unless (defined( $new_stat->[$i] )
                    and defined( $old_stat->[$i] ) )
                {
                    $modified = 1;
                    last;
                }
                my $new_element = $new_stat->[$i];
                my $old_element = $old_stat->[$i];
                unless ( $new_element == $old_element ) {
                    $modified = 1;
                    last;
                }
            }
        }
        delete_inc_by_value($module) if $modified;
    }
}

sub defined_state {
    my ( $self, $key ) = @_;
    defined $self->{state}->{$key};
}

sub get_state {
    my ( $self, $key ) = @_;
    $self->{state}->{$key};
}

sub set_state {
    my ( $self, $key, $val ) = @_;
    $self->{state}->{$key} = $val;
}

1;
