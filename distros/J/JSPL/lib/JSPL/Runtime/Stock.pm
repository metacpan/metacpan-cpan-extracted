package JSPL::Runtime::Stock;
use strict;
use warnings;

use IO::File;
use Carp qw(cluck carp);

push @JSPL::Context::CARP_NOT, __PACKAGE__;

my %services = (
    'Env'    => \%ENV,
    'warn'   => sub { carp @_; },
    'print'  => sub { print map defined($_) ? $_ : 'undefined', @_ },
    'say'    => sub { print map defined($_) ? $_ : 'undefined', @_ , "\n" },
    'sprintf'=> sub {
	    my $format = shift || ''; 
	    sprintf($format, map defined($_) ? $_ : 'undefined', @_);
    },
    'peval'  => sub {
	JSPL::Context->check_privileges;
	my $res = eval "@_" or die $@; $res;
    }, 
    'system' => sub {
	JSPL::Context->check_privileges;
	system @_;
    },
    'caller' => sub { caller($_[0]) },
    'load' => sub {
	JSPL::Context->check_privileges;
	for(@_) {
	    eval "require $_;" or die $@;
	}
	return scalar(@_);
    },
    'install' => sub {
	no strict 'refs';
	my ($bind, $package, $con) = @_;
	my $ctl = JSPL::Context->current->get_controller;
	if(defined $con) {
	    $ctl->install($bind, [$package, $con]);
	} else {
	    $ctl->install($bind, $package);
	}
    },
    'include' => sub {
	my $file = shift;
	my $restricted = shift;
	my $ctx = JSPL::Context->current;
	local $ctx->{Restricted} = $restricted if $restricted;
	$ctx->eval_file($file);
    },
    'unlink' => sub {
	JSPL::Context->check_privileges;
	unlink @_;
    },
    'sysvar' => {
	PID => \$$,
	Version => \$^V, 
	INC => \@INC,
    }, 
);

$services{'require'} = sub {
    $services{load}->($_[1]);
    $services{install}->(@_);
};

sub _ctxcreate {
    my $ctx = shift;
    my $sys = $JSPL::_gruntime
	? $ctx->jsc_eval($ctx->get_global, q|perl;|)
	: $ctx->jsc_eval($ctx->get_global, q|var Sys = this; Sys;|);
    for(keys %services) {
	$sys->{$_} = $services{$_};
    }
    my $ctl = $ctx->get_controller;
    my $prefix = $JSPL::_gruntime ? 'perl' : 'Sys';
    $ctl->install("$prefix.IO.File" => 'IO::File');
}

sub _mainprg {
    my $ctx = shift;
    my $prgname = shift;
    $ctx->bind_all(
	Argv => \@ARGV,
	PrgName => \$prgname
    );
}

$JSPL::Runtime::Plugins{stock} = {
    ctxcreate => \&_ctxcreate,
    main => \&_mainprg,
};

1;
__END__
=head1 NAME

JSPL::Runtime::Stock - Plugin that install stock services for JavaScript side

=head1 JAVASCRIPT INTERFACE

This plugins automatically install the following services in the global object of
every context created in the referenced runtime.

To use any of the methods marked as B<Restricted> you must call in a unrestricted
context, otherwise the method invocation throws an error.

=over 4

=item Sys                                          B<Object>

Alias to the global object, so if in a different scope you need to reference
any of the following services, you can use C<Sys.> as a prefix. Think in the 
C<window> object when in the browser.

=item Env                                          B<Object>

The environment variables under which your program is running. You can change
the properties on this object to modify the environment.

This object is an alias to perl's L<perlvar/%ENV>.

=item IO                                           B<Object>

Used to aggregate all properties related to I/O

=item IO.File ( FILENAME [,MODE [, PERMS]] )  	   B<Constructor Function>

Returns a new instance of a L<IO::File> perl object. Please read 
L<IO::File/METHODS>, L<IO::HANDLE> and L<IO::Seekable> for all the details.

=item IO.File.new_tmpfile ( )                      B<Function>

Returns a new instance of a L<IO::File> opened for read/write on a newly created
temporary file.  On systems where this is possible, the temporary file is anonymous
(i.e. it is unlinked after creation, but held open).

=item print ( STRING [, ... ])                     B<Function>

Write to STDOUT. Alias to L<perlfunc/print>.

=item say ( STRING [, ...])                        B<Function>

Like C<print> but adds a newline at the end of its arguments.
Alias to L<perlfunc/say> in perl 5.10+

=item sprintf ( FORMAT, LIST );                    B<Function>

Returns a string formatted by the usual "printf" conventions of the C library
function "sprintf". This is implemented by L<perlfunc/sprintf>.

=item peval ( STRING )                             B<Function Restricted>

Perl eval. Eval the I<STRING> as perl code using L<perlfunc/eval>. Returns the value
of the last statement in STRING. If perl's eval fails, throws an exception.

=item system ( COMMAND [, ARG1 [, ... ]] )         B<Function Restricted>

Alias for perl's L<perlfunc/system>.

=item caller                                       B<Function>

Alias for perl's L<perlfunc/caller>.

=item include ( FILENAME )                         B<Function>

Includes some other javascript file I<filename>

=item require ( BIND, PACKAGE [, CONSTRUCTOR] )    B<Function Restricted>

Load the perl library named I<PACKAGE> and bind it to the javascript property
C<BIND>. The value bound will be either a C<PerlSub> if a constructor was found
in the perl package or a C<Stash> otherwise. You must read the discussion on
L<JSPL::Controller/install>.

Example, requiring a package with a constructor:

    require('INET', 'IO::Socket::INET');
    // INET instanceOf PerlSub === true
    var conn = new INET(...);

When a C<Stash> is bound it can be used to call class methods on it, among
other things.

Example, requiring a package without a constructor:

    require('DBI', 'DBI');
    var conn = DBI.connect(...);

See L<JSPL::Controller> and L<JSPL::Stash> for the details.

=item load ( MODULE [, ... ])                         B<Function Restricted>

The require service described above is actually implemented in terms of two
lower-level services: load and install.

The load service makes the given list of perl libraries to be loaded in the
perl side.  The return value of load is the number of modules loaded. If a
module fails to load an exception will be thrown.

This service doesn't make the modules to be available to the javascript side.
To make them available see C<install> below.

=item install ( BIND, PACKAGE [, CONSTRUCTOR] )       B<Function>

As discussed above, C<require> is defined in terms of C<load> and C<install>.
Install makes a perl module to be available on the perl side. The module should
be previously been loaded using L</load>. You should read the discussion on
L<JSPL::Controller/install>.

Separating the L</load> and the C<install> operations is useful in certain
cases. For example, for perl libraries that make available more than one perl
package. Take, for example, the Gtk2 module. Loading the Gtk2 module makes
available several other namespaces: Gtk2::Window, Gtk2::Button, etc...  Making
this module available to javascript you need to do a single load operation for
Gtk2, and a bunch of install operations for the namespaces interesting to you.
You should read the discussion on L<JSPL::Controller/install>.

=item warn ( STRING [, ... ])                         B<Function>

Emit a warning message to STDERR. Alias to L<perlfunc/warn>.

=back
