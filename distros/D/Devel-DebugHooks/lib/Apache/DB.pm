package Apache::DB;

use 5.005;
use strict;
use DynaLoader ();

BEGIN {
	use constant MP2 => eval {
        exists $ENV{MOD_PERL_API_VERSION} and $ENV{MOD_PERL_API_VERSION} >= 2
    };
	die "mod_perl is required to run this module: $@" if $@;

	if (MP2) {
		require APR::Pool;
		require Apache2::RequestRec;
	}

}

{
    no strict;
    @ISA = qw(DynaLoader);
    $VERSION = '0.14';
    __PACKAGE__->bootstrap($VERSION);
}

$Apache::Registry::MarkLine = 0;

sub init {

    if(init_debugger()) {
  warn "[notice] Apache::DB initialized in child $$\n";

      {
         local $@;
         my $loaded_db;

         if ($ENV{PERL5DB}) {
             $loaded_db = eval "$ENV{ PERL5DB }; 1";
             warn $@   if $@;
         }

         if (!$loaded_db) {
             # Fallback
             require 'Apache/perl5db.pl';
         }
      }

    }

    1;
}

sub handler {
    my $r = shift;


	if( MP2 ) { 
		if (ref $r) {

    $SIG{INT} = \&DB::ApacheSIGINT();
		$r->pool->cleanup_register(sub {
      $SIG{ INT } =  undef;
		});
   }
	}
	else {
		if (ref $r) {
		$SIG{INT} = \&DB::catch;
		$r->register_cleanup(sub { 
			$SIG{INT} = \&DB::ApacheSIGINT();
		});
		}
	}

  DB::state( 'stack' )->[ -2 ]{ single } =  1   unless $DB::options{ NonStop };
  return 0;

}

1;
__END__

=head1 NAME

Apache::DB - Run the interactive Perl debugger under mod_perl

=head1 SYNOPSIS

 <Location /perl>
  PerlFixupHandler +Apache::DB

  SetHandler perl-script
  PerlHandler +Apache::Registry
  Options +ExecCGI
 </Location>

=head1 DESCRIPTION

Perl ships with a very useful interactive debugger, however, it does not run
"out-of-the-box" in the Apache/mod_perl environment.  Apache::DB makes a few
adjustments so the two will cooperate.

=head1 FUNCTIONS

=over 4

=item init

This function initializes the Perl debugger hooks without actually
starting the interactive debugger.  In order to debug a certain piece
of code, this function must be called before the code you wish debug
is compiled.  For example, if you want to insert debugging symbols
into code that is compiled at server startup, but do not care to debug
until request time, call this function from a PerlRequire'd file:

 #where db.pl is simply:
 # use Apache::DB ();
 # Apache::DB->init;
 PerlRequire conf/db.pl

 #where modules are loaded
 PerlRequire conf/init.pl

If you are using mod_perl 2.0 you will need to use the following 
as your db.pl: 

  use APR::Pool (); 
  use Apache::DB (); 
  Apache::DB->init(); 

=item handler

This function will start the interactive debugger.  It will invoke
I<Apache::DB::init> if needed.  Example configuration:

 <Location /my-handler>
  PerlFixupHandler Apache::DB
  SetHandler perl-script
  PerlHandler My::handler
 </Location>

=back

=head1 SELinux

Security-enhanced Linux (SELinux) is a mandatory access control system
many linux distrobutions are implementing.  This new security scheme
can assist you with protecting a server, but it doesn't come without
its own set of issues.  Debugging applications running on a box with
SELinux on it takes a couple of extra steps and unfortunately the
instructions that follow have only been tested on RedHat/Fedora.

1) You need to edit/create the file "local.te" and add the following:

if (httpd_tty_comm) {
    allow { httpd_t } admin_tty_type:chr_file { ioctl getattr }; }

2) Reload your security policy.

3) Run the command "setsebool httpd_tty_comm true".

You should be aware as you debug applications on a system with SELinux
your code may very well be correct, but the system policy is denying your
actions.  

=head1 CAVEATS

=over 4

=item -X

The server must be started with the C<-X> to use Apache::DB.

=item filename/line info

The filename of Apache::Registry scripts is not displayed.

=back

=head1 SEE ALSO

perldebug(1)

=head1 AUTHOR

Originally written by Doug MacEachern

Currently maintained by Frank Wiles <frank@wiles.org>

=head1 LICENSE 

This module is distributed under the same terms as Perl itself. 

