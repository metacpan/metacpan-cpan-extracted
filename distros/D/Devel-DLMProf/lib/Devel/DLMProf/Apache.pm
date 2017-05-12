package Devel::DLMProf::Apache;
use vars qw(%initial_modules $memory_before);
use Carp;
use Path::Class qw(file);
use Fcntl;

use constant WIN32   => $^O eq 'MSWin32';
use constant SOLARIS => $^O eq 'solaris';
use constant LINUX   => $^O eq 'linux';
use constant BSD_LIKE => $^O =~ /(darwin|bsd|aix)/i;

BEGIN {

    # Load Devel::NYTProf before loading any other modules
    # in order that $^P settings apply to the compilation
    # of those modules.

    if ( !$ENV{DLMPROF} ) {
        $ENV{DLMPROF} = "/tmp/dlmprof.$$.out";
        warn "Defaulting DLMPROF env var to '$ENV{DLMPROF}'";
    }

    if (LINUX) {

        # need to be fixed to support older kernel
        #unless ( eval { require Linux::Smaps } ) {
        #    croak 'you must install Linux::Smaps';
        #}
    }
    elsif (BSD_LIKE) {
        unless ( eval { require BSD::Resource } ) {
            croak 'you must install BSD::Resource';
        }
    }
    else {
        croak 'Not supported OS';
    }

    require Devel::DLMProf;
}

use strict;

use constant MP2 =>
    ( exists $ENV{MOD_PERL_API_VERSION} && $ENV{MOD_PERL_API_VERSION} == 2 )
    ? 1
    : 0;

sub child_init {
    $memory_before = get_current_process_memory_size();
    $initial_modules{$_}++ for keys %INC;
}

sub child_exit {
    profile_dynamic_loaded_modules();
    profile_memory_diff();
    return MP2 ? Apache2::Const::OK() : Apache::Constants::OK();
}

sub get_current_process_memory_size {
    my $memory_size = 0;
    if (LINUX) {
        $memory_size = _get_linux_process_memory_size();
    }
    elsif (BSD_LIKE) {
        $memory_size = _get_bsd_process_memory_size();
    }
    $memory_size;
}

# return process size (in KB)
sub _get_linux_process_memory_size {
    if ( eval { require Linux::Smaps } and Linux::Smaps->new($$) ) {
        return _get_new_kernel_linux_process_memory_size();
    }
    else {
        return _get_old_kernel_linux_process_memory_size();
    }
}

sub _get_new_kernel_linux_process_memory_size {
    my $map         = Linux::Smaps->new($$);
    my $memory_size = $map->all->size;
    $memory_size;
}

sub _get_old_kernel_linux_process_memory_size {
    my ( $size, $resident, $share ) = ( 0, 0, 0 );

    my $file = "/proc/self/statm";
    if ( open my $fh, "<$file" ) {
        ( $size, $resident, $share ) = split /\s/, scalar <$fh>;
        close $fh;
    }
    else {
        croak "Fatal Error: couldn't access $file";
    }

    # linux on intel x86 has 4KB page size...
    return $size * 4;
}

sub _get_bsd_process_memory_size {
    my @results     = BSD::Resource::getrusage();
    my $memory_size = $results[2];
    $memory_size;
}

sub profile_dynamic_loaded_modules {
    my @dynamic_loaded_modules = grep { !$initial_modules{$_} } keys %INC;
    my $dynamic_loaded_modules = join "\n", @dynamic_loaded_modules;
    _write_log(
        "### Dynamic Loaded Modules ###\n" . $dynamic_loaded_modules );
}

sub profile_memory_diff {
    my $memory_after = get_current_process_memory_size();
    my $memory_diff  = $memory_after - $memory_before;
    _write_log( "### memory (after-before) ###\n" . $memory_diff . " byte" );
}

sub _write_log {
    my $text = shift;
    warn $text;
    $text = "\n" . $text;
    my $file = "/tmp/dlmprof.$$.out";
    sysopen( FH, $file, O_WRONLY | O_CREAT | O_APPEND )
        or die "can't open $file: $!";
    print FH $text;
    close FH;
}

# arrange for the profile to be enabled in each child
# and cleanly finished when the child exits
if (MP2) {
    require mod_perl2;
    require Apache2::ServerUtil;
    require Apache2::Const;
    my $s = Apache2::ServerUtil->server;
    $s->push_handlers( PerlChildInitHandler => \&child_init );
    $s->push_handlers( PerlChildExitHandler => \&child_exit );
}
else {
    Carp::carp("mod_perl1.x isn't supported");
}

1;

__END__

=head1 NAME

Devel::DLMProf::Apache - Find dynamic loaded modules in mod_perl applications with Devel::DLMProf

=head1 SYNOPSIS

    # in your Apache config file with mod_perl installed
    PerlPassEnv DLMPROF
    PerlModule Devel::DLMProf::Apache

    # the case you use startup.pl

    PerlPostConfigRequire /path/to/startup.pl
    PerlPassEnv DLMPROF
    PerlModule Devel::DLMProf::Apache

=head1 DESCRIPTION

This module allows mod_perl applications to be profiled using
C<Devel::DLMProf>. 

If the DLMPROF environment variable isn't set I<at the time
Devel::DLMProf::Apache is loaded> then Devel::DLMProf::Apache will issue a
warning and default it to:

	/tmp/dlmprof.$$.out

Try using C<PerlPassEnv> so you can set the DLMPROF environment variable externally.

Each profiled mod_perl process will need to have terminated before you can
successfully read the profile data file. The simplest approach is to start the
httpd, make some requests (e.g., 100 of the same request), then stop it and
process the profile data.

Alternatively you could send a TERM signal to the httpd worker process to
terminate that one process. The parent httpd process will start up another one
for you ready for more profiling.

=head2 Example httpd.conf

It's often a good idea to use just one child process when profiling, which you
can do by setting the C<MaxClients> to 1 in httpd.conf.

Using an C<IfDefine> blocks lets you leave the profile configuration in place
and enable it whenever it's needed by adding C<-D DLMPROF> to the httpd startup
command line.

    <IfDefine DLMPROF>
        MaxClients 1
        PerlModule Devel::DLMProf::Apache
    </IfDefine>


=head1 SEE ALSO

L<Devel::DLMProf>

=head1 AUTHOR

B<Takatoshi Kitano>, C<< <kitano.tk at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Takatoshi Kitano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

