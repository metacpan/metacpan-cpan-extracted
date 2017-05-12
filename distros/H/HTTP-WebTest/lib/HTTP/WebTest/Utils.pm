# $Id: Utils.pm,v 1.9 2003/03/02 11:52:10 m_ilya Exp $

package HTTP::WebTest::Utils;

=head1 NAME

HTTP::WebTest::Utils - Miscellaneous subroutines used by HTTP::WebTest

=head1 SYNOPSIS

    use HTTP::WebTest::Utils;

    *method = make_access_method($field);
    *method = make_access_method($field, $default_value);
    *method = make_access_method($field, sub { ... });

    find_port(hostname => $hostname);
    my $pid = start_webserver(port => $port, server_sub => sub { ... });
    stop_webserver($pid);

    copy_dir($src_dir, $dst_dir);

    load_package($package);

    my $ret = eval_in_playground($code);
    die $@ if $@;

=head1 DESCRIPTION

This packages contains utility subroutines used by
L<HTTP::WebTest|HTTP::WebTest>.  All of them can be exported but none
of them is exported by default.

=head1 SUBROUTINES

=cut

use strict;

use Cwd;
use File::Copy;
use File::Find;
use File::Path;
use File::Spec::Functions;
use HTTP::Daemon;

use base qw(Exporter);

use vars qw(@EXPORT_OK);

@EXPORT_OK = qw(make_access_method find_port
                copy_dir load_package
                eval_in_playground make_sub_in_playground
                start_webserver stop_webserver);

=head2 make_access_method($field, $optional_default_value)

Creates anonymous subroutine which can be used as accessor
method.  Method can be used with objects that are blessed hashes.

Typical usage is

    *method = make_access_method($field, ...);

=head3 Parameters

=over 4

=item * $field

A hash field used for created accessor method.

=item * $optional_default_value

If C<$optional_default_value> is a code reference, uses values returned
by its execution as default for created accessor method.  Otherwise,
uses C<$optional_default_value> as name of method which returns
default value for created accessor method.

=back

=head3 Returns

=cut

sub make_access_method {
    # field name
    my $field = shift;
    # subroutine or method which returns some default value for field
    my $default_value = shift;

    my $sub = sub {
	my $self = shift;

	if(@_) {
	    $self->{$field} = shift;
	}

	unless(defined $self->{$field}) {
	    if(defined $default_value) {
		if(ref($default_value) eq 'CODE') {
		    $self->{$field} = $default_value->($self);
		} else {
		    $self->{$field} = $self->$default_value();
		}
	    }
	}

	return $self->{$field};
    };
}

=head2 find_port (hostname => $hostname)

=head3 Returns

Free port number for network interface specified by C<$hostname>.

=cut

sub find_port {
    my %param = @_;

    my $hostname = $param{hostname};

    my $daemon =
	    HTTP::Daemon->new(($hostname ? (LocalAddr => $hostname) : ()));

    if(defined $daemon) {
	my $port = $daemon->sockport;
	$daemon->close;
	return $port;
    }

    return undef;
}

=head2 start_webserver(%params)

Starts separate process with a test webserver.

=head3 Parameters

=over 4

=item port => $port

A port number where the test webserver listens for incoming connections.

=item server_sub => $server_sub

A reference on a subroutine to handle requests. It get passed two
named parameters: C<connect> and C<request>.

=back

=cut

sub start_webserver {
    my %param = @_;

    my $daemon = HTTP::Daemon->new(LocalPort => $param{port}, Reuse => 1)
	or die;

    # create daemon process
    my $pid = fork;
    die unless defined $pid;
    return $pid if $pid != 0;

    # when we are run under debugger do not stop and call debugger at
    # the exit of the forked process. This helps to workaround problem
    # when forked process tries to takeover and to screw the terminal
    $DB::inhibit_exit = 0;

    # if we are running with Test::Builder do not let it output
    # anything for daemon process
    if(Test::Builder->can('new')) {
        Test::Builder->new->no_ending(1);
    }

    # set 'we are working' flag
    my $done = 0;

    # exit on SIGTERM
    $SIG{TERM} = sub { $done = 1 };
    # handle connections closed by client
    $SIG{PIPE} = 'IGNORE';

    # handle requests till process is killed
    eval {
	until($done) {
	    # wait one tenth of second for connection
	    my $rbits = '';
	    vec($rbits, $daemon->fileno, 1) = 1;
	    my $nfound = select $rbits, '', '', 0.1;

	    # handle incoming connections
	    if($nfound > 0) {
		my $connect = $daemon->accept;
		die unless defined $connect;

		while (my $request = $connect->get_request) {
                    $param{server_sub}->(connect => $connect,
                                         request => $request);
		}
		$connect->close;
	    }
	}
    };
    # in any event try to shutdown daemon nicely
    $daemon->close;
    if($@) { die $@ };

    exit 0;
}

=head2 stop_webserver($pid)

Kills a test webserver specified by its PID.

=cut

sub stop_webserver {
    my $pid = shift;

    return kill 'SIGTERM', $pid;
}

=head2 copy_dir ($src_dir, $dst_dir)

Copies directiory recursively.

=cut

sub copy_dir {
    my $src_dir = shift;
    my $dst_dir = shift;

    my $cwd = getcwd;

    $dst_dir = catdir($cwd, $dst_dir)
	unless file_name_is_absolute($dst_dir);

    # define subroutine that copies files to destination directory
    # directory
    my $copytree = sub {
	my $filename = $_;

	my $rel_dirname = $File::Find::dir;

	if(-d $filename) {
	    # create this directory in destination directory tree
	    my $path = catdir($dst_dir, $rel_dirname, $filename);
	    mkpath($path) unless -d $path;
	}

	if(-f $filename) {
	    # copy this file to destination directory tree, create
	    # subdirectory if neccessary
	    my $path = catdir($dst_dir, $rel_dirname);
	    mkpath($path) unless -d $path;

	    copy($filename, catfile($path, $filename))
		or die "HTTP::WebTest: Can't copy file: $!";
	}
    };

    # descend recursively from directory, copy files to destination
    # directory
    chdir $src_dir
	or die "HTTP::WebTest: Can't chdir to directory '$src_dir': $!";
    find($copytree, '.');
    chdir $cwd
	or die "HTTP::WebTest: Can't chdir to directory '$cwd': $!";
}

=head2 load_package ($package)

Loads package unless it is already loaded.

=cut

sub load_package {
    my $package = shift;

    # check if package is loaded already (we are asuming that all of
    # them have method 'new')
    return if $package->can('new');

    eval "require $package";

    die $@ if $@;
}

=head2 eval_in_playground ($code)

Evaluates perl code inside playground package.

=head3 Returns

A return value of evaluated code.

=cut

sub eval_in_playground {
    my $code = shift;

    return eval <<CODE;
package HTTP::WebTest::PlayGround;

no strict;
local \$^W; # aka no warnings in new perls

$code
CODE
}

=head2 make_sub_in_playground ($code)

Create anonymous subroutine inside playground package.

=head3 Returns

A reference on anonymous subroutine.

=cut

sub make_sub_in_playground {
    my $code = shift;

    return eval_in_playground("sub { local \$^W; $code }");
}

=head1 COPYRIGHT

Copyright (c) 2001-2003 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

=cut

1;
