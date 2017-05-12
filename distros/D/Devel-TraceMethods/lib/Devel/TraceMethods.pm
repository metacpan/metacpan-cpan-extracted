package Devel::TraceMethods;

use strict;

use vars '$VERSION';
$VERSION = '1.00';

sub import
{
	my $package = shift;

	while (@_)
	{
		my $traced = shift;
		my $logger = ref $_[0] eq 'CODE' && defined &{ $_[0] } ? shift : undef;
		_wrap_symbol( $traced, $logger );
	}
}

sub _wrap_symbol
{
	my ($traced, $logger) = @_;
	my $src;

	# get the calling package symbol table name
	{
		no strict 'refs';
		$src = \%{ $traced . '::' };
	}

	# loop through all symbols in calling package, looking for subs
	for my $symbol ( keys %$src )
	{
		# get all code references, make sure they're valid
		my $sub = *{ $src->{$symbol} }{CODE};
		next unless defined $sub and defined &$sub;

		# save all other slots of the typeglob
		my @slots;

		for my $slot (qw( SCALAR ARRAY HASH IO FORMAT ))
		{
			my $elem = *{ $src->{$symbol} }{$slot};
			next unless defined $elem;
			push @slots, $elem;
		}

		# clear out the source glob
		undef $src->{$symbol};

		# replace the sub in the source
		$src->{$symbol} = sub
		{
			my @args = @_;
			_log_call->( 
				name   => "${traced}::$symbol",
				logger => $logger,
				args   => [ @_ ]
			);
			return $sub->(@_);
		};

		# replace the other slot elements
		for my $elem (@slots)
		{
			$src->{$symbol} = $elem;
		}
	}
}

{
	my $logger = sub { require Carp; Carp::carp( join ', ', @_ ) };

	# set a callback sub for logging
	sub callback
	{
		# should allow this to be a class method :)
		shift if @_ > 1;

		my $coderef = shift;
		unless( ref($coderef) eq 'CODE' and defined(&$coderef) )
		{
			require Carp;
			Carp::croak( "$coderef is not a code reference!" );
		}

		$logger = $coderef;
	}

	# where logging actually happens
	sub _log_call
	{
		my %args    = @_;
		my $log_sub = $args{logger} || $logger;

		$log_sub->( $args{name}, @{ $args{args} });
	}
}

1;

__END__

=head1 NAME

Devel::TraceMethods - Perl module for tracing module calls

=head1 SYNOPSIS

  use Devel::TraceMethods qw( PackageOne PackageTwo );

=head1 DESCRIPTION

Devel::TraceMethods allows you to attach a logging subroutine of your choosing
to all of the methods and functions within multiple packages or classes.  You
can use this to trace execution.  It even respects inheritance.

To enable logging, pass the name of the packages you wish to trace on the line
where you use Devel::TraceMethods.  It will automatically install logging for
all functions in the named packages.

You can also call C<import()> after you have C<use()>d the module if you want
to log functions and methods in another package.

You can specify per-package (or per-class) logging subroutines.  For example:

  Devel::TraceMethods( SomePackage => \&log_one, OtherPackage => \&log_two );

=head2 callback( $subroutine_reference )

By default, Devel::TraceMethods uses C<Carp::carp()> to log a method call.  You
can change this with the C<set_logger()> function.  Pass a subroutine reference
as the only argument, and all subsequent calls to logged methods will use the
new subroutine reference instead of C<carp()>.

The first argument to the logging subroutine is the full name of the logged
method.  The rest of the arguments are copies of those being passed to the
logged method.  You can modify them in the logging subroutine without
disturbing your call.

=head1 TODO

=over

=item Unlog packages.

=item Attach to calling package if nothing is specified in @_?  Something like:

	push @_, scalar caller() unless @_;

=item Attach only to specified methods.

=item Add ability to disable logging on certain methods.

=item Allow multiple logging subs.

=item Allow per-method logging sub?

=item Don't copy other slots of typeglob?  (Could be tricky, an internals
wizard will have to look at this.)

=back

=head1 COPYRIGHT and AUTHOR

Copyright (c) 2001, 2005 chromatic C<< chromatic at wgz dot org >>.

Thanks to Tye McQueen for the initial suggestion, grinder at Perl Monks for the
callback suggestion, and Podmaster for a suggestion on enhancing the default
logging subroutine

=head1 SEE ALSO

perl(1).

=cut
