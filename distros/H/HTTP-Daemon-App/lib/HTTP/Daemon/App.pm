package HTTP::Daemon::App;

use strict;
use warnings;

use version;our $VERSION = qv('0.0.9');

use HTTP::Daemon;
use HTTP::Daemon::SSL;
use HTTP::Response;
use Acme::Spork;
use Unix::PID;
use File::Spec;

use base 'Exporter';
our @EXPORT_OK = qw(run decode_basic_auth send_basic_auth_request);

sub send_basic_auth_request {
	my ($c, $realm)      = @_;
	$realm               = 'Restricted Area' if !$realm;
	my $auth_request_res = HTTP::Response->new(401, 'Unauthorized');
	$auth_request_res->header('WWW-Authenticate' => qq{Basic realm="$realm"});
	$auth_request_res->is_error(1);
    $auth_request_res->error_as_HTML(1);
	$c->send_response($auth_request_res);
}

sub decode_basic_auth {
	my ($auth) = @_;
	no warnings 'uninitialized';
    $auth = ( split /\s+/, $auth->header('Authorization') )[1] if ref $auth;
    require MIME::Base64;
    return split(/:/, MIME::Base64::decode( $auth ), 2);
}

sub run {
    my($daemons_hashref, $conf) = @_;  
    
    $conf              = {} if ref $conf ne 'CODE';
    $conf->{'pid_dir'} = File::Spec->catdir(qw(/ var run)) if !$conf->{'pid_dir'};
    $conf->{'pid_ext'} = '.pid' if !$conf->{'pid_ext'};
    $conf->{'self'}    = "perl $0" if !$conf->{'self'};
    
    my $additional = '';
    for my $opt (sort keys %{ $conf->{'opts'} }) {
        if($opt eq '--start' || $opt eq '--stop' || $opt eq '--restart') {
            delete $conf->{'opts'}{$opt};
            next;
        }
        $additional .= "|$opt";
    }

    $ARGV[0] = '--help' if !defined $ARGV[0]; # no uninit warnings and logical visual clue to coders of what will happen if its not specified...
    if($ARGV[0] eq '--restart') {
        system qq($conf->{'self'} --stop $$);
        sleep 1;
        system qq($conf->{'self'} --start);
        exit;	
    }
        
    if($ARGV[0] eq '--start') {
    	for my $daemon (sort keys %{ $daemons_hashref }) {
            next if ref $daemons_hashref->{$daemon}{'handler'} ne 'CODE';
    	    next if ref $daemons_hashref->{$daemon}{'daemon'} ne 'HASH';
    	    
            my $pidfile = File::Spec->catfile($conf->{'pid_dir'}, "$daemon$conf->{'pid_ext'}");
            
    	    my $objkt = $daemons_hashref->{$daemon}{'ssl'} 
    	                ? HTTP::Daemon::SSL->new( %{ $daemons_hashref->{$daemon}{'daemon'} } )
    	                : HTTP::Daemon->new( %{ $daemons_hashref->{$daemon}{'daemon'} } )
    	                ;
            if(!$objkt) {
                print "$daemon: $!\n";
    	        next;
            }

    	    print "Starting $daemons_hashref->{$daemon}{'label'}: <URL:" . $objkt->url . ">\n"
    	        if defined $daemons_hashref->{$daemon}{'label'};

    		my $http_pid = spork(
    		    sub {
    		        my($handler, $d, $name, $pidfile, $conf) = @_;
                    local $0 = $name;
                	while (my $c = $d->accept) {
                	    $conf->{'pre_fork'}->(@_) if ref $conf->{'pre_fork'} eq 'CODE';
                	    
	                    if(my $kid = fork()) {
		                    $c->can('get_cipher') ? $c->close('SSL_no_shutdown' => 1) : $c->close;
	                	    undef($c);
	                    }
	                    else {
	                        $conf->{'get_tmpfile'} = sub { return } if ref $conf->{'get_tmpfile'} ne 'CODE';
		               	    while (my $r = $c->get_request( $conf->{'get_tmpfile'}->( $conf ) )) {
                	            $handler->($d, $c, $r, $conf);
                            }
                            # $c->can('get_cipher') ? $c->close('SSL_no_shutdown' => 1) : $c->close;	
	                        # undef($c);
	                        exit 0;
                	    }
                	    
                	    $conf->{'pst_fork'}->(@_) if ref $conf->{'pst_fork'} eq 'CODE';
                	}
		        }, $daemons_hashref->{$daemon}{'handler'}, $objkt, $daemon, $pidfile, $conf,
    		);

    		Unix::PID->new()->pid_file_no_unlink($pidfile, $http_pid)
    		    or die "The PID in $pidfile is still running.";
    	}
    }
    elsif($ARGV[0] eq '--stop') {
    	for my $daemon (sort keys %{ $daemons_hashref }) {
    	    my $pidfile = File::Spec->catfile($conf->{'pid_dir'}, "$daemon$conf->{'pid_ext'}");

            my $uxp = Unix::PID->new();
    	    my $pid = $uxp->kill_pid_file($pidfile);

    	    if($pid == 1) {
    	        print "$daemon is not running\n";
    	    }
    	    elsif($pid eq '-1') {
                print "$daemon pidfile: $!\n";
            }
            else {
    	        print "$daemon ($pid) was stopped\n";
    	    }   

            print "\tCollecting $daemon children...\n";
            for my $kid ($uxp->get_pidof($daemon) ) {
	            next if defined $ARGV[1] && $kid eq $ARGV[1];
	            $uxp->kill( $kid ) or print "\t\tCould not kill $daemon child $kid: $!\n";
            }
    	}
    }
    elsif(exists $conf->{'opts'}{$ARGV[0]}) {
        $conf->{'opts'}->{$ARGV[0]}->(@_);
    }
    else {
    	print "Useage: $0 [--start|--stop||--restart$additional]\n";
    	print "$conf->{'help'}\n" if $conf->{'help'};
    }
}

1;

__END__

=head1 NAME

HTTP::Daemon::App - Create 2 or 3 line, fully functional (SSL) HTTP server(s)

=head1 SYNOPSIS

    use HTTP::Daemon::App;
    use MyServers::Foo;
    HTTP::Daemon::App::run($MyServers::Foo::daemons, $MyServers::Foo::config);

=head1 DESCRIPTION

You can describe one or more HTTP daemons in a simple hash and *instantly* 
have a [--start|--stop|--restart] capable daemon that can optionally be SSL aware.

Its also easy to add command line options and has integrated help. 

=head2 EXPORT

Each function can be exported but nothing is by default.

=head1 FUNCTIONS

=head2 run

Takes 2 arguments, both hashrefs. The first describes tha daemons to run, the second is for config.

=head3 daemon hashref

Hopefully these are self descriptive, this example does two daemons SSL and non-SSL:

    {
        'thingy-ssl' => {
            'label'   => 'HTTPS Thingy',
            'ssl'     => 1, # true: HTTP::Daemon::SSL, false: HTTP::Daemon
            'daemon'  => {
                # arguments HTTP::Daemon[::SSL]->new()
                'LocalPort' => 4279,
            },
            'handler' => sub {
                my($d, $c, $r, $conf_hr) = @_; # $d, $c, $r from HTTP::Daemon
                # handle request
            },
        },
        'thingy' => {
            'label'   => 'HTTP Thingy',
            'ssl'     => 0, # true: HTTP::Daemon::SSL, false: HTTP::Daemon
            'daemon'  => {
                # arguments HTTP::Daemon[::SSL]->new()
                'LocalPort' => 4278,
            },
            'handler' => sub {
                my($d, $c, $r, $conf_hr) = @_; # $d, $c, $r from HTTP::Daemon
                # handle request
            },
        },
    },

=head3 config hashref

    {
        'pre_fork' => '', # set to a code ref it gets called before it forks the child process,  its args are ($handler, $d, $name, $pidfile, $conf)
        'pst_fork' => '', # same as pre_fork but run after the fork is done
        'pid_dir' => '/var/run/', # default shown
        'pid_ext' => '.pid', # default shown
        'verbose' => 0, # example of your custom option that can be used by your handlers and set via 'opts' like below
        # 'lang'    => 'Locale::Maketext::Utils handle', not used yet
        'help'    => '', # default shown, this is added to the useage output.
        'opts'    => {
            # default {}, cannot use --stop, --start, or --restart, automagically added to useage line
            '--version'  => sub { print "$0 v1.0\n" },
            '--verbose' => sub { my($daemons_hashref, $conf) = @_;$conf->{'verbose'} = 1; },
        },
        'self' => "perl $0", # default shown, command used to call --stop & --start on --restart
    }

=head2 decode_basic_auth

Given the encoded basic auth passed by the browser 
(or given the "$r" object from HTTP::Daemon, the 'Authorization' header's value) 
this will return the username an password.

    my ($auth_user, $auth_pass) = decode_basic_auth( $encoded_basic_auth_from_browser );
    my($user, $encpass, $uid, $gid, $homedir) = (getpwnam($auth_user))[0, 1, 2, 3, 7];
    
    if($auth_user && $encpass eq crypt($auth_pass, $encpass) && $user eq $auth_user) {
        ... # continue on as authenticated user

=head2 send_basic_auth_request

Takes two arguments: the "$c" object from HTTP::Request, the realm's name (has lame default if not specified)

It does a 401 that incites the client's authentication challenge (E.g. a browser's drop down login box)

        ... # continue on as authenticated user
	}
	else {
	    HTTP::Daemon::App::send_basic_auth_request($c, 'Vault of secrets');
	}

=head1 SEE ALSO

L<HTTP::Daemon>

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut