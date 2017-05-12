package Devel::Profiler::Apache;

use 5.006;
use strict;
use warnings;

use File::Path qw(rmtree mkpath);

our $VERSION = 0.01;

sub import {
    my $pkg = shift;
    die "Invalid import options for Devel::Profiler::Apache " . 
      "- must be a list of key-value pairs."
        if @_ % 2;
    our %OPT = @_;

    die "Inavlid import option to Devel::Profiler::Apache " . 
      "- output_file not allowed."
        if exists $OPT{output_file};

    my $path = Apache->server_root_relative("logs/profiler");
    rmtree($path) if -d $path;
    Apache->push_handlers(PerlChildInitHandler => \&handler);
}

sub handler {
    my $r = shift;
    our %OPT;

    # for some reason this handler is being called multiple times for
    # the same child process.  make sure we only initialize
    # Devel::Profiler once.
    our %DONE;
    return if exists $DONE{$$};
    $DONE{$$} = 1;
    
    my $dir = Apache->server_root_relative("logs/profiler/$$");
    File::Path::mkpath($dir);

    $r->log_error("Devel::Profiler::Apache => $dir/tmon.out");

    # setup options
    $OPT{output_file} = "$dir/tmon.out";
    $OPT{package_filter} = [] unless exists $OPT{package_filter};
    $OPT{package_filter} = [ $OPT{package_filter} ]
      unless ref $OPT{package_filter} eq 'ARRAY';
    push @{$OPT{package_filter}}, \&package_filter;

    # load Devel::Profiler and initialize
    require Devel::Profiler;
    Devel::Profiler->import(%OPT);
    Devel::Profiler::init();

    return 0;
}

# exclude Apache:: due to problems with misbehavin' Apache XS modules
sub package_filter {
    my $pkg = shift;
    return 0 if $pkg =~ /^Apache/ or $pkg =~ /^mod_perl/;
    return 1;
}

1;
__END__

=head1 NAME

Devel::Profiler::Apache - Hook Devel::Profiler into mod_perl

=head1 SYNOPSIS

 # in httpd.conf
 PerlModule Devel::Profiler::Apache;

 # or in startup.pl
 use Devel::Profiler::Apache;

=head1 DESCRIPTION

The Devel::Profiler::Apache module will run a Devel::Profiler profiler
inside each child server and write the I<tmon.out> file in the
directory I<$ServerRoot/logs/profiler/$$> when the child is shutdown.
The next time the parent server pulls in Devel::Profiler::Apache (via
soft or hard restart), the I<$ServerRoot/logs/dprof> is cleaned out
before new profiles are written for the new children.

Devel::Profiler::Apache currently uses the package_filter option to
avoid profiling any modules that begin with Apache::.  This necessary
to avoid profiling sensitive Apache XS code that do strange things
with their symbol tables (storing arrays in the CODE slots, for one!).
At some point this will be refined to only exclude the problem modules
within Apache::.

=head1 USAGE

Most users of Devel::Profiler can simply copy the code from the
SYNPOSIS and use that as-is.  However, if you need to modify the way
Devel::Profiler works then you can pass Devel::Profiler::Apache the
same options that are used with Devel::Profiler:

  use Devel::Profiler::Apache buffer_size => 1024;

=head1 ACKNOWLEDGMENTS

This module is based heavily on Apache::DProf by Doug MacEachern which
provides equivalent functionality for Apache::DProf.

=head1 AUTHOR

Sam Tregar

=head1 SEE ALSO

L<Devel::Profiler|Devel::Profiler>, L<Apache::DProf|Apache::DProf>

=cut
