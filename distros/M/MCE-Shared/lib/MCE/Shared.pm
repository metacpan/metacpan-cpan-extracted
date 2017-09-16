###############################################################################
## ----------------------------------------------------------------------------
## MCE extension for sharing data supporting threads and processes.
##
###############################################################################

package MCE::Shared;

use strict;
use warnings;

use 5.010001;

no warnings qw( threads recursion uninitialized once );

our $VERSION = '1.829';

## no critic (BuiltinFunctions::ProhibitStringyEval)
## no critic (Subroutines::ProhibitSubroutinePrototypes)
## no critic (TestingAndDebugging::ProhibitNoStrict)

use Carp;

$Carp::Internal{ (__PACKAGE__) }++;

no overloading;

use MCE::Shared::Server ();
use Scalar::Util qw( blessed refaddr );

our @CARP_NOT = qw(
   MCE::Shared::Array    MCE::Shared::Hash     MCE::Shared::Queue
   MCE::Shared::Cache    MCE::Shared::Minidb   MCE::Shared::Scalar
   MCE::Shared::Condvar  MCE::Shared::Object   MCE::Shared::Sequence
   MCE::Shared::Handle   MCE::Shared::Ordhash  MCE::Shared::Server
);

sub import {
   no strict 'refs'; no warnings 'redefine';
   *{ caller().'::mce_open' } = \&open;

   return;
}

###############################################################################
## ----------------------------------------------------------------------------
## Share function.
##
###############################################################################

my ($_count, %_lkup) = (0);

sub share {
   shift if (defined $_[0] && $_[0] eq 'MCE::Shared');

   # construction via module option
   if ( ref $_[0] eq 'HASH' && $_[0]->{module} ) {
      my $_params = shift;

      return MCE::Shared->condvar(@_)
         if ( $_params->{module} eq 'MCE::Shared::Condvar' );
      return MCE::Shared->handle(@_)
         if ( $_params->{module} eq 'MCE::Shared::Handle' );
      return MCE::Shared->queue(@_)
         if ( $_params->{module} eq 'MCE::Shared::Queue' );

      $_params->{class} = ':construct_module:';

      return MCE::Shared::Server::_new(
         $_params, [ @_, delete $_params->{new} || 'new' ]
      );
   }

   my $_params = ref $_[0] eq 'HASH' && ref $_[1] ? shift : {};
   my ($_class, $_ra, $_item) = (blessed($_[0]), refaddr($_[0]));

   # class construction failed: e.g. share( class->new(...) )
   return '' if @_ && !$_[0] && $!;

   # safety for circular references to not loop endlessly
   return $_lkup{ $_ra } if defined $_ra && exists $_lkup{ $_ra };

   $_count++;

   # blessed object, \@array, \%hash, or \$scalar
   if ( $_class ) {
      _incr_count($_[0]), return $_[0] if $_[0]->can('SHARED_ID');
      $_params->{'class'} = $_class;

      $_item = MCE::Shared::Server::_new($_params, $_[0]);
   }
   elsif ( ref $_[0] eq 'ARRAY' ) {
      if ( tied(@{ $_[0] }) && tied(@{ $_[0] })->can('SHARED_ID') ) {
         _incr_count(tied(@{ $_[0] })), return tied(@{ $_[0] });
      }
      $_item = $_lkup{ $_ra } = MCE::Shared->array($_params, @{ $_[0] });
      @{ $_[0] } = ();  tie @{ $_[0] }, 'MCE::Shared::Object', $_item;
   }
   elsif ( ref $_[0] eq 'HASH' ) {
      if ( tied(%{ $_[0] }) && tied(%{ $_[0] })->can('SHARED_ID') ) {
         _incr_count(tied(%{ $_[0] })), return tied(%{ $_[0] });
      }
      $_item = $_lkup{ $_ra } = MCE::Shared->hash($_params, %{ $_[0] });
      %{ $_[0] } = ();  tie %{ $_[0] }, 'MCE::Shared::Object', $_item;
   }
   elsif ( ref $_[0] eq 'SCALAR' && !ref ${ $_[0] } ) {
      if ( tied(${ $_[0] }) && tied(${ $_[0] })->can('SHARED_ID') ) {
         _incr_count(tied(${ $_[0] })), return tied(${ $_[0] });
      }
      $_item = $_lkup{ $_ra } = MCE::Shared->scalar($_params, ${ $_[0] });
      undef ${ $_[0] }; tie ${ $_[0] }, 'MCE::Shared::Object', $_item;
   }

   # synopsis
   elsif ( ref $_[0] eq 'REF' ) {
      _croak('A "REF" type is not supported');
   }
   else {
      if ( ref $_[0] eq 'GLOB' ) {
         _incr_count(tied(*{ $_[0] })), return $_[0] if (
            tied(*{ $_[0] }) && tied(*{ $_[0] })->can('SHARED_ID')
         );
      }
      _croak('Synopsis: blessed object, \@array, \%hash, or \$scalar');
   }

   %_lkup = () unless --$_count;

   $_item;
}

###############################################################################
## ----------------------------------------------------------------------------
## Public functions.
##
###############################################################################

sub AUTOLOAD {
   # $AUTOLOAD = MCE::Shared::<method_name>
   my $_fcn = substr($MCE::Shared::AUTOLOAD, 13);

   shift if ( defined $_[0] && $_[0] eq 'MCE::Shared' );

   return MCE::Shared::Object::_init(@_) if $_fcn eq 'init';
   return MCE::Shared::Server::_start() if $_fcn eq 'start';
   return MCE::Shared::Server::_stop() if $_fcn eq 'stop';

   if ( $_fcn eq 'array' || $_fcn eq 'hash' ) {
      _use( 'MCE::Shared::'.ucfirst($_fcn) );
      my $_params = ref $_[0] eq 'HASH' ? shift : {};

      my $_item = ( $_fcn eq 'array' )
         ? &share($_params, MCE::Shared::Array->new())
         : &share($_params, MCE::Shared::Hash->new());

      if ( scalar @_ ) {
         $_params->{_DEEPLY_} = 1;
         if ( $_fcn eq 'array' ) {
            for ( my $i = 0; $i <= $#_; $i += 1 ) {
               &_share($_params, $_item, $_[$i]) if ref($_[$i]);
            }
         } else {
            for ( my $i = 1; $i <= $#_; $i += 2 ) {
               &_share($_params, $_item, $_[$i]) if ref($_[$i]);
            }
         }
         $_item->assign(@_);
      }

      return $_item;
   }
   elsif ( $_fcn eq 'handle' ) {
      require MCE::Shared::Handle unless $INC{'MCE/Shared/Handle.pm'};

      my $_item = &share( MCE::Shared::Handle->new([]) );
      my $_fh   = \do { no warnings 'once'; local *FH };

      tie *{ $_fh }, 'MCE::Shared::Object', $_item;
      if ( @_ ) { $_item->OPEN(@_) or return ''; }

      return $_fh;
   }
   elsif ( $_fcn eq 'pdl' ||
      $_fcn =~ /^pdl_(byte|u?short|.*long|float|double|ones|sequence|zeroes|indx)$/
   ) {
      $_fcn = $1 if ( $_fcn ne 'pdl' );
      push @_, $_fcn; _use('PDL') or _croak($@);

      return MCE::Shared::Server::_new({ 'class' => ':construct_pdl:' }, [ @_ ]);
   }

   # cache, condvar, minidb, ordhash, queue, scalar, sequence, et cetera
   $_fcn = 'sequence' if $_fcn eq 'num_sequence';

   my $_pkg = ucfirst( lc $_fcn ); local $@;

   if ( $INC{"MCE/Shared/$_pkg.pm"} || eval "use MCE::Shared::$_pkg (); 1" ) {
      $_pkg = "MCE::Shared::$_pkg";

      return &share({}, $_pkg->new(_shared => 1, @_)) if $_fcn eq 'cache';
      return &share({}, $_pkg->new(@_));
   }

   _croak("Can't locate object method \"$_fcn\" via package \"MCE::Shared\"");
}

sub open (@) {
   shift if ( defined $_[0] && $_[0] eq 'MCE::Shared' );
   require MCE::Shared::Handle unless $INC{'MCE/Shared/Handle.pm'};

   my $_item;
   if ( ref $_[0] eq 'GLOB' && tied *{ $_[0] } &&
        ref tied(*{ $_[0] }) eq 'MCE::Shared::Object' ) {

      $_item = tied *{ $_[0] };
   }
   elsif ( @_ ) {
      if ( ref $_[0] eq 'GLOB' && tied *{ $_[0] } ) {
         close $_[0] if defined ( fileno $_[0] );
      }
      $_item = &share( MCE::Shared::Handle->new([]) );
      $_[0]  = \do { no warnings 'once'; local *FH };
      tie *{ $_[0] }, 'MCE::Shared::Object', $_item;
   }

   shift; _croak("Not enough arguments for open") unless @_;

   if ( !defined wantarray ) {
      $_item->OPEN(@_) or _croak("open error: $!");
   } else {
      $_item->OPEN(@_);
   }
}

###############################################################################
## ----------------------------------------------------------------------------
## TIE support.
##
###############################################################################

sub TIEARRAY {
   shift; ( ref($_[0]) eq 'HASH' && exists $_[0]->{'module'} )

      ? _tie('TIEARRAY', @_) : MCE::Shared->array(@_);
}

sub TIEHANDLE {
   shift; require MCE::Shared::Handle unless $INC{'MCE/Shared/Handle.pm'};

   # Tie *FH, 'MCE::Shared', { module => 'MCE::Shared::Handle' }, '>>', \*STDOUT
   # doesn't work on the Windows platform. We'd let OPEN handle the ref instead.

   shift if ref($_[0]) eq 'HASH' && $_[0]->{'module'} eq 'MCE::Shared::Handle';

   if ( ref($_[0]) eq 'HASH' && exists $_[0]->{'module'} ) {
      if ( @_ == 3 && ref $_[2] && defined( my $_fd = fileno($_[2]) ) ) {
         _tie('TIEHANDLE', $_[0], $_[1]."&=$_fd");
      } else {
         _tie('TIEHANDLE', @_);
      }
   }
   else {
      my $_item = &share( MCE::Shared::Handle->new([]) );
      if ( @_ ) { $_item->OPEN(@_) or return ''; }

      $_item;
   }
}

sub TIEHASH {
   shift;

   return _tie('TIEHASH', @_) if (
      ref($_[0]) eq 'HASH' && exists $_[0]->{'module'}
   );

   my ($_cache, $_ordered);

   if ( ref $_[0] eq 'HASH' ) {
      if ( $_[0]->{'ordered'} || $_[0]->{'ordhash'} ) {
         $_ordered = 1; shift;
      } elsif ( exists $_[0]->{'max_age'} || exists $_[0]->{'max_keys'} ) {
         $_cache = 1;
      }
   }
   else {
      if ( @_ < 3 && ( $_[0] eq 'ordered' || $_[0] eq 'ordhash' ) ) {
         $_ordered = $_[1]; splice(@_, 0, 2);
      } elsif ( @_ < 5 && ( $_[0] eq 'max_age' || $_[0] eq 'max_keys' ) ) {
         $_cache = 1;
      }
   }

   return MCE::Shared->cache(@_) if $_cache;
   return MCE::Shared->ordhash(@_) if $_ordered;
   return MCE::Shared->hash(@_);
}

sub TIESCALAR {
   shift; ( ref($_[0]) eq 'HASH' && exists $_[0]->{'module'} )

      ? _tie('TIESCALAR', @_) : MCE::Shared->scalar(@_);
}

###############################################################################
## ----------------------------------------------------------------------------
## Private functions.
##
###############################################################################

sub _croak {
   $_count = 0, %_lkup = ();

   if ( $INC{'MCE.pm'} ) {
      goto &MCE::_croak;
   } else {
      require MCE::Shared::Base unless $INC{'MCE/Shared/Base.pm'};
      goto &MCE::Shared::Base::_croak;
   }
}

sub _incr_count {
   # increments counter for safety during destroy
   MCE::Shared::Server::_incr_count($_[0]->SHARED_ID);
}

sub _share {
   $_[2] = &share($_[0], $_[2]);

   MCE::Shared::Object::_req2(
      'M~DEE', $_[1]->SHARED_ID()."\n", $_[2]->SHARED_ID()."\n"
   );
}

sub _tie {
   my ( $_fcn, $_params ) = ( shift, shift );

   _use( my $_module = $_params->{'module'} ) or _croak("$@\n");

   _croak("Can't locate object method \"$_fcn\" via package \"$_module\"")
      unless eval qq{ $_module->can('$_fcn') };

   $_params->{class} = ':construct_module:';
   $_params->{tied } = 1;

   my $_item = MCE::Shared::Server::_new($_params, [ @_, $_fcn ]);

   if ( $_item && $_item->[2] ) {
      ##
      # Set encoder/decoder automatically for supported DB modules.
      # - AnyDBM_File, DB_File, GDBM_File, NDBM_File, ODBM_File, SDBM_File,
      # - CDB_File, SQLite_File, Tie::Array::DBD, Tie::Hash::DBD,
      # - BerkeleyDB::*, KyotoCabinet::DB, TokyoCabinet::*
      ##
      $_item->[2] = MCE::Shared::Server::_get_freeze(),
      $_item->[3] = MCE::Shared::Server::_get_thaw();
   }

   $_item;
}

sub _use {
   my $_class = $_[0];

   if ( $_class =~ /(.*)::_/ ) {
      # e.g. MCE::Hobo::_hash
      eval "require $1" unless $INC{ join('/',split(/::/,$1)).'.pm' };
   }
   elsif ( $_class =~ /^(BerkeleyDB)::(?:Btree|Hash|Queue|Recno)$/ ) {
      eval "require $1" unless $INC{"$1.pm"};
   }
   elsif ( $_class =~ /^(TokyoCabinet|KyotoCabinet)::[ABH]?DB$/ ) {
      eval "require $1" unless $INC{"$1.pm"};
   }
   elsif ( $_class =~ /^Tie::(?:Std|Extra)Hash$/ ) {
      eval "require Tie::Hash" unless $INC{'Tie/Hash.pm'};
   }
   elsif ( $_class eq 'Tie::StdArray' ) {
      eval "require Tie::Array" unless $INC{'Tie/Array.pm'};
   }
   elsif ( $_class eq 'Tie::StdScalar' ) {
      eval "require Tie::Scalar" unless $INC{'Tie/Scalar.pm'};
   }

   return 1 if eval q{
      $_class->can('new') ||
      $_class->can('TIEARRAY') || $_class->can('TIEHANDLE') ||
      $_class->can('TIEHASH')  || $_class->can('TIESCALAR')
   };

   if ( !exists $INC{ join('/',split(/::/,$_class)).'.pm' } ) {
      # remove tainted'ness from $_class
      ($_class) = $_class =~ /(.*)/;

      eval "use $_class (); 1" or return '';
   }

   return 1;
}

1;

__END__

###############################################################################
## ----------------------------------------------------------------------------
## Module usage.
##
###############################################################################

=head1 NAME

MCE::Shared - MCE extension for sharing data supporting threads and processes

=head1 VERSION

This document describes MCE::Shared version 1.829

=head1 SYNOPSIS

 # OO construction.

 use MCE::Shared;

 my $ar = MCE::Shared->array( @list );
 my $ca = MCE::Shared->cache( max_keys => 500, max_age => 60 );
 my $cv = MCE::Shared->condvar( 0 );
 my $fh = MCE::Shared->handle( '>>', \*STDOUT ) or die "$!";
 my $ha = MCE::Shared->hash( @pairs );
 my $oh = MCE::Shared->ordhash( @pairs );
 my $db = MCE::Shared->minidb();
 my $qu = MCE::Shared->queue( await => 1, fast => 0 );
 my $va = MCE::Shared->scalar( $value );
 my $se = MCE::Shared->sequence( $begin, $end, $step, $fmt );
 my $ob = MCE::Shared->share( $blessed_object );

 # The Perl-like mce_open function is available since 1.002.

 mce_open my $fh, ">>", "/foo/bar.log" or die "open error: $!";

 # Tie construction. The module API option is available since 1.825.

 use v5.10;
 use MCE::Flow;
 use MCE::Shared;

 my %args  = ( max_keys => 500, max_age => 60 );
 my @pairs = ( foo => 'bar', woo => 'baz' );
 my @list  = ( 'a' .. 'z' );

 tie my $va1, 'MCE::Shared', { module => 'MCE::Shared::Scalar' }, 'foo';
 tie my @ar1, 'MCE::Shared', { module => 'MCE::Shared::Array' }, @list;
 tie my %ca1, 'MCE::Shared', { module => 'MCE::Shared::Cache' }, %args;
 tie my %ha1, 'MCE::Shared', { module => 'MCE::Shared::Hash' }, @pairs;
 tie my %oh1, 'MCE::Shared', { module => 'MCE::Shared::Ordhash' }, @pairs;
 tie my %oh2, 'MCE::Shared', { module => 'Hash::Ordered' }, @pairs;
 tie my %oh3, 'MCE::Shared', { module => 'Tie::IxHash' }, @pairs;
 tie my $cy1, 'MCE::Shared', { module => 'Tie::Cycle' }, [ 1 .. 8 ];
 tie my $va2, 'MCE::Shared', { module => 'Tie::StdScalar' }, 'hello';
 tie my @ar3, 'MCE::Shared', { module => 'Tie::StdArray' }, @list;
 tie my %ha2, 'MCE::Shared', { module => 'Tie::StdHash' }, @pairs;
 tie my %ha3, 'MCE::Shared', { module => 'Tie::ExtraHash' }, @pairs;

 tie my @ary, 'MCE::Shared', qw( a list of values );
 tie my %ca,  'MCE::Shared', { max_keys => 500, max_age => 60 };
 tie my %ha,  'MCE::Shared', key1 => 'val1', key2 => 'val2';
 tie my %oh,  'MCE::Shared', { ordered => 1 }, key1 => 'value';

 tie my $cnt, 'MCE::Shared', 0;
 tie my @foo, 'MCE::Shared';
 tie my %bar, 'MCE::Shared';

 my $mutex = MCE::Mutex->new;

 mce_flow {
    max_workers => 4
 },
 sub {
    my ( $mce ) = @_;
    my ( $pid, $wid ) = ( MCE->pid, MCE->wid );

    # Locking is necessary when multiple workers update the same
    # element. The reason is that it may involve 2 trips to the
    # shared-manager process: fetch and store in this case.

    $mutex->enter( sub { $cnt += 1 } );

    # Otherwise, locking is optional for unique elements.

    $foo[ $wid - 1 ] = $pid;
    $bar{ $pid }     = $wid;

    return;
 };

 say "scalar : $cnt";
 say " array : $_" for (@foo);
 say "  hash : $_ => $bar{$_}" for (sort keys %bar);

 __END__

 # Output

 scalar : 4
  array : 37847
  array : 37848
  array : 37849
  array : 37850
   hash : 37847 => 1
   hash : 37848 => 2
   hash : 37849 => 3
   hash : 37850 => 4

=head1 DESCRIPTION

This module provides data sharing capabilities for L<MCE> supporting threads
and processes. L<MCE::Hobo> provides threads-like parallelization for running
code asynchronously.

=head1 EXTRA FUNCTIONALITY

MCE::Shared enables extra functionality on systems with L<IO::FDPass> installed.
Without it, MCE::Shared is unable to send file descriptors to the shared-manager
process. The use applies to Condvar, Queue, and Handle (mce_open). IO::FDpass
isn't used for anything else.

 use MCE::Shared;

 # One may want to start the shared-manager early.

 MCE::Shared->start();

 # Typically, the shared-manager is started automatically when
 # constructing a shared object.

 my $ca = MCE::Shared->cache( max_keys => 500 );

 # IO::FDPass is necessary for constructing a shared condvar or queue
 # while the manager is running in order to send file descriptors
 # associated with the object.

 # Workers block using a socket handle for ->wait and ->timedwait.

 my $cv = MCE::Shared->condvar();

 # Workers block using a socket handle for ->dequeue and ->await.

 my $q1 = MCE::Shared->queue();
 my $q2 = MCE::Shared->queue( await => 1 );

For platforms where L<IO::FDPass> isn't possible, construct C<condvar> and
C<queue> before other classes. The manager process is delayed until sharing
other classes or started explicitly.

 use MCE::Shared;

 my $has_IO_FDPass = $INC{'IO/FDPass.pm'} ? 1 : 0;

 my $cv  = MCE::Shared->condvar( 0 );
 my $que = MCE::Shared->queue( fast => 1 );

 MCE::Shared->start() unless $has_IO_FDPass;

 my $ha = MCE::Shared->hash();  # started implicitly

Note: MCE starts the shared-manager if not yet started. Ditto for MCE::Hobo.

Regarding mce_open, C<IO::FDPass> is needed for constructing a shared-handle
from a non-shared handle not yet available inside the shared-manager process.
The workaround is to have the non-shared handle made before the shared-manager
is started. Passing a file by reference is fine for the three STD* handles.

 # The shared-manager knows of \*STDIN, \*STDOUT, \*STDERR.

 mce_open my $shared_in,  "<",  \*STDIN;   # ok
 mce_open my $shared_out, ">>", \*STDOUT;  # ok
 mce_open my $shared_err, ">>", \*STDERR;  # ok
 mce_open my $shared_fh1, "<",  "/path/to/sequence.fasta";  # ok
 mce_open my $shared_fh2, ">>", "/path/to/results.log";     # ok

 mce_open my $shared_fh, ">>", \*NON_SHARED_FH;  # requires IO::FDPass

The L<IO::FDPass> module is known to work reliably on most platforms.
Install 1.1 or later to rid of limitations described above.

 perl -MIO::FDPass -le "print 'Cheers! Perl has IO::FDPass.'"

=head1 DATA SHARING

=over 3

=item * array L<MCE::Shared::Array>

=item * cache L<MCE::Shared::Cache>

=item * condvar L<MCE::Shared::Condvar>

=item * handle L<MCE::Shared::Handle>

=item * hash L<MCE::Shared::Hash>

=item * minidb L<MCE::Shared::Minidb>

=item * ordhash L<MCE::Shared::Ordhash>

=item * queue L<MCE::Shared::Queue>

=item * scalar L<MCE::Shared::Scalar>

=item * sequence L<MCE::Shared::Sequence>

=back

Below, synopsis for sharing classes included with MCE::Shared.

 # short form

 use MCE::Shared;

 $ar = MCE::Shared->array( @list );
 $ca = MCE::Shared->cache( max_keys => 500, max_age => 60 );
 $cv = MCE::Shared->condvar( 0 );
 $fh = MCE::Shared->handle( ">>", \*STDOUT ); # see mce_open below
 $ha = MCE::Shared->hash( @pairs );
 $oh = MCE::Shared->ordhash( @pairs );
 $db = MCE::Shared->minidb();
 $qu = MCE::Shared->queue( await => 1, fast => 0 );
 $va = MCE::Shared->scalar( $value );
 $se = MCE::Shared->sequence( $begin, $end, $step, $fmt );

 mce_open my $fh, ">>", \*STDOUT or die "open error: $!";

 # long form, must include class module

 use MCE::Shared::Array;
 use MCE::Shared::Cache;
 use MCE::Shared::Hash;
 use MCE::Shared::Minidb;
 use MCE::Shared::Ordhash;
 use MCE::Shared::Queue;
 use MCE::Shared::Scalar;

 $ar = MCE::Shared->share( MCE::Shared::Array->new( ... ) );
 $ca = MCE::Shared->share( MCE::Shared::Cache->new( ... ) );
 $ha = MCE::Shared->share( MCE::Shared::Hash->new( ... ) );
 $db = MCE::Shared->share( MCE::Shared::Minidb->new( ... ) );
 $oh = MCE::Shared->share( MCE::Shared::Ordhash->new( ... ) );
 $qu = MCE::Shared->share( MCE::Shared::Queue->new( ... ) );
 $va = MCE::Shared->share( MCE::Shared::Scalar->new( ... ) );

The restriction for sharing classes not included with MCE::Shared
is that the object must not have file-handles nor code-blocks.

 use Hash::Ordered;

 $oh = MCE::Shared->share( Hash::Ordered->new( ... ) );

=over 3

=item open ( filehandle, expr )

=item open ( filehandle, mode, expr )

=item open ( filehandle, mode, reference )

In version 1.002 and later, constructs a new object by opening the file
whose filename is given by C<expr>, and associates it with C<filehandle>.
When omitting error checking at the application level, MCE::Shared emits
a message and stop if open fails.

See L<MCE::Shared::Handle> for chunk IO demonstrations.

 # non-shared or local construction for use by a single process
 # shorter, mce_open is an alias for MCE::Shared::Handle::open

 use MCE::Shared::Handle;

 MCE::Shared::Handle->open( my $fh, "<", "file.log" ) or die "$!";
 MCE::Shared::Handle::open  my $fh, "<", "file.log"   or die "$!";

 mce_open my $fh, "<", "file.log" or die "$!";

 # construction for sharing with other threads and processes
 # shorter, mce_open is an alias for MCE::Shared::open

 use MCE::Shared;

 MCE::Shared->open( my $fh, "<", "file.log" ) or die "$!";
 MCE::Shared::open  my $fh, "<", "file.log"   or die "$!";

 mce_open my $fh, "<", "file.log" or die "$!";

Simple examples to open a file for reading:

 # mce_open is exported by MCE::Shared or MCE::Shared::Handle.
 # It creates a shared file handle with MCE::Shared present
 # or a non-shared handle otherwise.

 mce_open my $fh, "< input.txt"     or die "open error: $!";
 mce_open my $fh, "<", "input.txt"  or die "open error: $!";
 mce_open my $fh, "<", \*STDIN      or die "open error: $!";

and for writing:

 mce_open my $fh, "> output.txt"    or die "open error: $!";
 mce_open my $fh, ">", "output.txt" or die "open error: $!";
 mce_open my $fh, ">", \*STDOUT     or die "open error: $!";

=item num_sequence

C<num_sequence> is an alias for C<sequence>.

=back

=head1 DEEPLY SHARING

The following is a demonstration for a shared tied-hash variable. Before
venturing into the actual code, notice the dump function making a call to
C<export> explicitly for objects of type C<MCE::Shared::Object>. This is
necessary in order to retrieve the data from the shared-manager process.

The C<export> method is described later under the Common API section.

 sub _dump {
    require Data::Dumper unless $INC{'Data/Dumper.pm'};
    no warnings 'once';

    local $Data::Dumper::Varname  = 'VAR';
    local $Data::Dumper::Deepcopy = 1;
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Purity   = 1;
    local $Data::Dumper::Sortkeys = 0;
    local $Data::Dumper::Terse    = 0;

    ( ref $_[0] eq 'MCE::Shared::Object' )
       ? print Data::Dumper::Dumper( $_[0]->export ) . "\n"
       : print Data::Dumper::Dumper( $_[0] ) . "\n";
 }

 use MCE::Shared;

 tie my %abc, 'MCE::Shared';

 my @parents = qw( a b c );
 my @children = qw( 1 2 3 4 );

 for my $parent ( @parents ) {
    for my $child ( @children ) {
       $abc{ $parent }{ $child } = 1;
    }
 }

 _dump( tied( %abc ) );

 # Output

 $VAR1 = bless( {
   'c' => bless( {
     '1' => '1',
     '4' => '1',
     '3' => '1',
     '2' => '1'
   }, 'MCE::Shared::Hash' ),
   'a' => bless( {
     '1' => '1',
     '4' => '1',
     '3' => '1',
     '2' => '1'
   }, 'MCE::Shared::Hash' ),
   'b' => bless( {
     '1' => '1',
     '4' => '1',
     '3' => '1',
     '2' => '1'
   }, 'MCE::Shared::Hash' )
 }, 'MCE::Shared::Hash' );

Dereferencing provides hash-like behavior for C<hash> and C<ordhash>.
Array-like behavior is allowed for C<array>, not shown below.

 use MCE::Shared;

 my $abc = MCE::Shared->hash;

 my @parents = qw( a b c );
 my @children = qw( 1 2 3 4 );

 for my $parent ( @parents ) {
    for my $child ( @children ) {
       $abc->{ $parent }{ $child } = 1;
    }
 }

 _dump( $abc );

Each level in a deeply structure requires a separate trip to the shared-manager
process. The included C<MCE::Shared::Minidb> module provides optimized methods
for working with hash of hashes C<HoH> and/or hash of arrays C<HoA>. As such,
do the following when performance is desired.

 use MCE::Shared;

 my $abc = MCE::Shared->minidb;

 my @parents = qw( a b c );
 my @children = qw( 1 2 3 4 );

 for my $parent ( @parents ) {
    for my $child ( @children ) {
       $abc->hset( $parent, $child, 1 );
    }
 }

 _dump( $abc );

For further reading, see L<MCE::Shared::Minidb>.

=head1 OBJECT SHARING

=over 3

=item share

This class method transfers the blessed-object to the shared-manager
process and returns a C<MCE::Shared::Object> containing the C<SHARED_ID>.
Starting with the 1.827 release, the module option sends parameters to the
shared-manager, where the object is then constructed. This is useful for
classes involving a file handle.

 use MCE::Shared;
 use MCE::Shared::Ordhash;

 my $oh1 = MCE::Shared->share( MCE::Shared::Ordhash->new() );
 my $oh2 = MCE::Shared->share({ module => 'MCE::Shared::Ordhash' });
 my $oh3 = MCE::Shared->ordhash();      # same thing

 $oh1->assign( @pairs );
 $oh2->assign( @pairs );
 $oh3->assign( @pairs );

 use Hash::Ordered;

 my ($ho_shared, $ho_nonshared);

 $ho_shared = MCE::Shared->share({ module => 'Hash::Ordered' });
 $ho_shared->push( @pairs );

 $ho_nonshared = $ho_shared->export();   # back to non-shared
 $ho_nonshared = $ho_shared->destroy();  # including destruction

The following provides long and short forms for constructing a shared array,
hash, or scalar object.

 use MCE::Shared;

 use MCE::Shared::Array;    # Loading helper classes isn't necessary
 use MCE::Shared::Hash;     # when using the shorter form or via the
 use MCE::Shared::Scalar;   # module option.

 my $a1 = MCE::Shared->share( MCE::Shared::Array->new( @list ) );
 my $a2 = MCE::Shared->share({ module => 'MCE::Shared::Array' }, @list );
 my $a3 = MCE::Shared->share( [ @list ] );  # sugar syntax
 my $a4 = MCE::Shared->array( @list );

 my $h1 = MCE::Shared->share( MCE::Shared::Hash->new( @pairs ) );
 my $h2 = MCE::Shared->share({ module => 'MCE::Shared::Hash' }, @pairs );
 my $h3 = MCE::Shared->share( { @pairs } ); # sugar syntax
 my $h4 = MCE::Shared->hash( @pairs );

 my $s1 = MCE::Shared->share( MCE::Shared::Scalar->new( 20 ) );
 my $s2 = MCE::Shared->share({ module => 'MCE::Shared::Scalar' }, 20 );
 my $s3 = MCE::Shared->share( \do{ my $o = 20 } );
 my $s4 = MCE::Shared->scalar( 20 );

When the C<module> option is given, one may optionally specify the constructor
function via the C<new> option. This is necessary for the CDB_File module,
which provides two different objects. One is created by new (default), and
accessed by insert and finish. The other is created by TIEHASH, and accessed
by FETCH.

 use MCE::Hobo;
 use MCE::Shared;

 # populate CDB file
 my $cdb = MCE::Shared->share({ module => 'CDB_File' }, 't.cdb', "t.cdb.$$")
    or die "$!\n";

 $cdb->insert( $_ => $_ ) for ('aa'..'zz');
 $cdb->finish;

 # use CDB file
 my $cdb1 = tie my %hash, 'MCE::Shared', { module => 'CDB_File' }, 't.cdb';

 # same thing, without involving TIE and extra hash variable
 my $cdb2 = MCE::Shared->share(
    { module => 'CDB_File', new => 'TIEHASH' }, 't.cdb'
 );

 print $hash{'aa'}, "\n";
 print $cdb1->FETCH('bb'), "\n";
 print $cdb2->FETCH('cc'), "\n";

 # rewind may be omitted on first use for parallel iteration
 $cdb2->rewind;

 for ( 1 .. 3 ) {
    mce_async {
       while ( my ($k,$v) = $cdb2->next ) {
          print "[$$] $k => $v\n";
       }
    };
 }

 MCE::Hobo->waitall;

=back

=head1 DBM SHARING

Construting a shared DBM object is possible starting with the 1.827 release.
Supported modules are L<AnyDBM_File>, L<BerkeleyDB>, L<CDB_File>, L<DB_File>,
L<GDBM_File>, L<NDBM_File>, L<ODBM_File>, L<SDBM_File>, L<SQLite_File>,
L<Tie::Array::DBD>, and L<Tie::Hash::DBD>. The list includes
L<Tokyo Cabinet|http://fallabs.com/tokyocabinet/> and
L<Kyoto Cabinet|http://fallabs.com/kyotocabinet/>. Also, see forked version
by L<Altice Labs|https://github.com/alticelabs/kyoto>. It contains an updated
C<kyotocabinet> folder that builds successfully with recent compilers.

Freeze-thaw during C<STORE>-C<FETCH> (for complex data) is handled
automatically using Serial 3.015+ (if available) or Storable. Below, are
constructions for sharing various DBM modules. The construction for
C<CDB_File> is given in the prior section.

=over 3

=item AnyDBM_File

 use MCE::Shared;
 use Fcntl;
 use AnyDBM_File;

 BEGIN { @AnyDBM_File::ISA = qw( DB_File GDBM_File NDBM_File ODBM_File ); }

 tie my %h1, 'MCE::Shared', { module => 'AnyDBM_File' },
    'foo_a', O_CREAT|O_RDWR or die "open error: $!";

=item BerkeleyDB

 use MCE::Shared;
 use BerkeleyDB;

 tie my %h1, 'MCE::Shared', { module => 'BerkeleyDB::Hash' },
    -Filename => 'foo_a', -Flags => DB_CREATE
       or die "open error: $!";
   
 tie my %h2, 'MCE::Shared', { module => 'BerkeleyDB::Btree' },
    -Filename => 'foo_b', -Flags => DB_CREATE
       or die "open error: $!";

 tie my @a1, 'MCE::Shared', { module => 'BerkeleyDB::Queue' },
    -Filename => 'foo_c', -Flags => DB_CREATE
       or die "open error: $!";

 tie my @a2, 'MCE::Shared', { module => 'BerkeleyDB::Recno' },
    -Filename => 'foo_d', -Flags => DB_CREATE -Len => 20
       or die "open error: $!";

=item DB_File

 use MCE::Shared;
 use Fcntl;
 use DB_File;

 # Use pre-defined references ( $DB_HASH, $DB_BTREE, $DB_RECNO ).

 tie my %h1, 'MCE::Shared', { module => 'DB_File' },
    'foo_a', O_CREAT|O_RDWR, 0640, $DB_HASH or die "open error: $!";

 tie my %h2, 'MCE::Shared', { module => 'DB_File' },
    'foo_b', O_CREAT|O_RDWR, 0640, $DB_BTREE or die "open error: $!";

 tie my @a1, 'MCE::Shared', { module => 'DB_File' },
    'foo_c', O_CREAT|O_RDWR, 0640, $DB_RECNO or die "open error: $!";

 # Changing defaults - see DB_File for valid options.

 my $opt_h = DB_File::HASHINFO->new();
 my $opt_b = DB_File::BTREEINFO->new();
 my $opt_r = DB_File::RECNOINFO->new();

 $opt_h->{'cachesize'} = 12345;

 tie my %h3, 'MCE::Shared', { module => 'DB_File' },
    'foo_d', O_CREAT|O_RDWR, 0640, $opt_h or die "open error: $!";

=item KyotoCabinet

=item TokyoCabinet

 use MCE::Shared;
 use KyotoCabinet;
 use TokyoCabinet;

 # file extension denotes hash database

 tie my %h1, 'MCE::Shared', { module => 'KyotoCabinet::DB' }, 'foo.kch',
    KyotoCabinet::DB::OWRITER | KyotoCabinet::DB::OCREATE
       or die "open error: $!";

 tie my %h2, 'MCE::Shared', { module => 'TokyoCabinet::HDB' }, 'foo.tch',
    TokyoCabinet::HDB::OWRITER | TokyoCabinet::HDB::OCREAT
       or die "open error: $!";

 # file extension denotes tree database

 tie my %h3, 'MCE::Shared', { module => 'KyotoCabinet::DB' }, 'foo.kct',
    KyotoCabinet::DB::OWRITER | KyotoCabinet::DB::OCREATE
       or die "open error: $!";

 tie my %h4, 'MCE::Shared', { module => 'TokyoCabinet::BDB' }, 'foo.tcb',
    TokyoCabinet::BDB::OWRITER | TokyoCabinet::BDB::OCREAT
       or die "open error: $!";

 # on-memory hash database

 tie my %h5, 'MCE::Shared', { module => 'KyotoCabinet::DB' }, '*';
 tie my %h6, 'MCE::Shared', { module => 'TokyoCabinet::ADB' }, '*';

 # on-memory tree database

 tie my %h7, 'MCE::Shared', { module => 'KyotoCabinet::DB' }, '%#pccap=256m';
 tie my %h8, 'MCE::Shared', { module => 'TokyoCabinet::ADB' }, '+';

=item Tie::Array::DBD

=item Tie::Hash::DBD

 use MCE::Shared;
 use Tie::Array::DBD;
 use Tie::Hash::DBD;

 # A valid string is required for the DSN argument, not a DBI handle.
 # Do not specify the 'str' option for Tie::(Array|Hash)::DBD.
 # Instead, see encoder-decoder methods described under Common API.

 tie my @a1, 'MCE::Shared', { module => 'Tie::Array::DBD' },
    'dbi:SQLite:dbname=foo_a.db', {
       tbl => 't_tie_analysis',
       key => 'h_key',
       fld => 'h_value'
    };

 tie my %h1, 'MCE::Shared', { module => 'Tie::Hash::DBD' },
    'dbi:SQLite:dbname=foo_h.db', {
       tbl => 't_tie_analysis',
       key => 'h_key',
       fld => 'h_value'
    };

 tie my %h2, 'MCE::Shared', { module => 'Tie::Hash::DBD'},
    'dbi:CSV:f_dir=.;f_ext=.csv/r;csv_null=1;csv_decode_utf8=0', {
       tbl => 'mytable',
       key => 'h_key',
       fld => 'h_value'
    };

 # By default, Sereal 3.015+ is used for serialization if available.
 # This overrides serialization from Sereal-or-Storable to JSON::XS.

 use JSON::XS ();

 tied(%ha2)->encoder( \&JSON::XS::encode_json );
 tied(%ha2)->decoder( \&JSON::XS::decode_json );

 $h2{'foo'} = 'plain value';
 $h2{'bar'} = { @pairs };
 $h2{'baz'} = [ @list ];

=back

=head1 DBM SHARING (CONT)

DB cursors, filters, and duplicate keys are not supported, just plain array and
hash functionality. The OO interface provides better performance when needed.
Use C<iterator> or C<next> for iterating over the elements.

 use MCE::Hobo;
 use MCE::Shared;
 use Fcntl;
 use DB_File;

 unlink 'foo_a';

 my $ob = tie my %h1, 'MCE::Shared', { module => 'DB_File' },
    'foo_a', O_CREAT|O_RDWR, 0640, $DB_HASH or die "open error: $!";

 $h1{key} = 'value';
 my $val = $h1{key};

 while ( my ($k, $v) = each %h1 ) {
    print "1: $k => $v\n";
 }

 # object oriented fashion, faster

 tied(%h1)->STORE( key1 => 'value1' );
 my $val1 = tied(%h1)->FETCH('key1');

 $ob->STORE( key2 => 'value2' );
 my $val2 = $ob->FETCH('key2');

 # non-parallel iteration

 my $iter = $ob->iterator;
 while ( my ($k, $v) = $iter->() ) {
    print "2: $k => $v\n";
 }

 # parallel iteration

 sub task {
    while ( my ($k, $v) = $ob->next ) {
       print "[$$] $k => $v\n";
       sleep 1;
    }
 }

 MCE::Hobo->create(\&task) for 1 .. 3;
 MCE::Hobo->waitall;

 $ob->rewind;

 # undef $ob and $iter before %h1 when destroying manually

 undef $ob;
 undef $iter;

 untie %h1;

See also L<Tie::File Demonstration|/"TIE::FILE DEMONSTRATION">, at the end
of the documentation.

=head1 PDL SHARING

=over 3

=item * pdl_byte

=item * pdl_short

=item * pdl_ushort

=item * pdl_long

=item * pdl_longlong

=item * pdl_float

=item * pdl_double

=item * pdl_ones

=item * pdl_sequence

=item * pdl_zeroes

=item * pdl_indx

=item * pdl

=back

C<pdl_byte>, C<pdl_short>, C<pdl_ushort>, C<pdl_long>, C<pdl_longlong>,
C<pdl_float>, C<pdl_double>, C<pdl_ones>, C<pdl_sequence>, C<pdl_zeroes>,
C<pdl_indx>, and C<pdl> are sugar syntax for PDL construction take place
under the shared-manager process.

 use PDL;                 # must load PDL before MCE::Shared
 use MCE::Shared;

 # makes extra copy/transfer and unnecessary destruction
 my $ob1 = MCE::Shared->share( zeroes( 256, 256 ) );

 # do this instead, efficient
 my $ob1 = MCE::Shared->zeroes( 256, 256 );

=over 3

=item ins_inplace

The C<ins_inplace> method applies to shared PDL objects. It supports
three forms for writing elements back to the PDL object, residing under
the shared-manager process.

 # --- action taken by the shared-manager process
 # ins_inplace(  1 arg  ):  ins( inplace( $this ), $what, 0, 0 );
 # ins_inplace(  2 args ):  $this->slice( $arg1 ) .= $arg2;
 # ins_inplace( >2 args ):  ins( inplace( $this ), $what, @coords );

 # --- use case
 $o->ins_inplace( $result );                    #  1 arg
 $o->ins_inplace( ":,$start:$stop", $result );  #  2 args
 $o->ins_inplace( $result, 0, $seq_n );         # >2 args

Operations such as C< + 5 > will not work on shared PDL objects. At this
time, the OO interface is the only mechanism for communicating with the
PDL piddle. For example, call C<slice>, C<sever>, or C<copy> to fetch
elements. Call C<ins_inplace> to update elements.

 # make a shared PDL piddle
 my $b = MCE::Shared->pdl_sequence(20,20);

 # fetch, add 10 to row 2 only
 my $res1 = $b->slice(":,1:1") + 10;
 $b->ins_inplace($res1, 0, 1);

 # fetch, add 10 to rows 4 and 5
 my $res2 = $b->slice(":,3:4") + 10;
 $b->ins_inplace($res2, 0, 3);

 # make non-shared object, export-destroy the shared object
 $b = $b->destroy;

 print "$b\n";

The following provides parallel demonstrations using C<MCE::Flow>.

 use PDL;  # must load PDL before MCE::Shared

 use MCE::Flow;
 use MCE::Shared;

 my $a = MCE::Shared->pdl_sequence(20,20);
 my $b = MCE::Shared->pdl_zeroes(20,20);

 # with chunking disabled

 mce_flow_s {
    max_workers => 4, chunk_size => 1
 },
 sub {
    my $row = $_;
    my $result = $a->slice(":,$row:$row") + 5;
    $b->ins_inplace($result, 0, $row);
 }, 0, 20 - 1;

 # with chunking enabled

 mce_flow_s {
    max_workers => 4, chunk_size => 5, bounds_only => 1
 },
 sub {
    my ($row1, $row2) = @{ $_ };
    my $result = $a->slice(":,$row1:$row2") + 5;
    $b->ins_inplace($result, 0, $row1);
 }, 0, 20 - 1;

 # make non-shared object, export-destroy the shared object

 $b = $b->destroy;

 print "$b\n";

See also L<PDL::ParallelCPU> and L<PDL::Parallel::threads>. For further
reading, the MCE-Cookbook on Github provides two PDL demonstrations.

L<https://github.com/marioroy/mce-cookbook>

=back

=head1 COMMON API

=over 3

=item blessed

Returns the real C<blessed> name, provided by the shared-manager process.

 use Scalar::Util qw(blessed);
 use MCE::Shared;

 use MCE::Shared::Ordhash;
 use Hash::Ordered;

 my $oh1 = MCE::Shared->share( MCE::Shared::Ordhash->new() );
 my $oh2 = MCE::Shared->share( Hash::Ordered->new() );

 print blessed($oh1), "\n";    # MCE::Shared::Object
 print blessed($oh2), "\n";    # MCE::Shared::Object

 print $oh1->blessed(), "\n";  # MCE::Shared::Ordhash
 print $oh2->blessed(), "\n";  # Hash::Ordered

=item destroy ( { unbless => 1 } )

=item destroy

Exports optionally, but destroys the shared object entirely from the
shared-manager process. The unbless option is passed to export.

 my $exported_ob = $shared_ob->destroy();

 $shared_ob;     # becomes undef

=item encoder ( CODE )

=item decoder ( CODE )

Override freeze/thaw routines. Applies to STORE and FETCH only, particularly
for TIE'd objects. These are called internally for shared DB objects.

Current API available since 1.827.

 use MCE::Shared;
 use BerkeleyDB;
 use DB_File;

 my $file1 = 'file1.db';
 my $file2 = 'file2.db';

 tie my @db1, 'MCE::Shared', { module => 'DB_File' }, $file1,
    O_RDWR|O_CREAT, 0640 or die "open error '$file1': $!";

 tie my %db2, 'MCE::Shared', { module => 'BerkeleyDB::Hash' },
    -Filename => $file2, -Flags => DB_CREATE
    or die "open error '$file2': $!";

 # Called automatically by MCE::Shared for DB files.
 # tied(@db1)->encoder( MCE::Shared::Server::_get_freeze );
 # tied(@db1)->decoder( MCE::Shared::Server::_get_thaw );
 # tied(%db2)->encoder( MCE::Shared::Server::_get_freeze );
 # tied(%db2)->decoder( MCE::Shared::Server::_get_thaw );
 # et cetera.

 $db1[0] = 'foo';   # store plain and complex structure
 $db1[1] = { key => 'value' };
 $db1[2] = [ 'complex' ];

 $db2{key} = 'foo'; # ditto, plain and complex structure
 $db2{sun} = [ 'complex' ];

=item export ( { unbless => 1 }, keys )

=item export

Exports the shared object as a non-shared object. One must export the shared
object when passing into any dump routine. Otherwise, the C<shared_id value>
and C<blessed name> is all one will see. The unbless option unblesses any
shared Array, Hash, and Scalar object to a non-blessed array, hash, and
scalar respectively.

 use MCE::Shared;
 use MCE::Shared::Ordhash;

 sub _dump {
    require Data::Dumper unless $INC{'Data/Dumper.pm'};
    no warnings 'once';

    local $Data::Dumper::Varname  = 'VAR';
    local $Data::Dumper::Deepcopy = 1;
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Purity   = 1;
    local $Data::Dumper::Sortkeys = 0;
    local $Data::Dumper::Terse    = 0;

    print Data::Dumper::Dumper($_[0]) . "\n";
 }

 my $oh1 = MCE::Shared->share( MCE::Shared::Ordhash->new() );
 my $oh2 = MCE::Shared->ordhash();  # same thing

 _dump($oh1);
    # bless( [ 1, 'MCE::Shared::Ordhash' ], 'MCE::Shared::Object' )

 _dump($oh2);
    # bless( [ 2, 'MCE::Shared::Ordhash' ], 'MCE::Shared::Object' )

 _dump( $oh1->export );  # dumps object structure and content
 _dump( $oh2->export );

C<export> can optionally take a list of indices/keys for what to export.
This applies to shared array, hash, and ordhash.

 use MCE::Shared;

 my $h1 = MCE::Shared->hash(           # shared hash
    qw/ I Heard The Bluebirds Sing by Marty Robbins /
      # k v     k   v         k    v  k     v
 );

 my $h2 = $h1->export( qw/ I The / );  # non-shared hash

 _dump($h2);

 # Output

 $VAR1 = bless( {
   'I' => 'Heard',
   'The' => 'Bluebirds'
 }, 'MCE::Shared::Hash' );

Specifying the unbless option exports a non-blessed data structure instead.
Unbless applies to shared MCE::Shared::{ Array, Hash, and Scalar } objects.

 my $h2 = $h1->export( { unbless => 1 }, qw/ I The / );
 my $h3 = $h1->export( { unbless => 1 } );

 _dump($h2);
 _dump($h3);

 # Output

 $VAR1 = {
   'The' => 'Bluebirds',
   'I' => 'Heard'
 };

 $VAR1 = {
   'Marty' => 'Robbins',
   'Sing' => 'by',
   'The' => 'Bluebirds',
   'I' => 'Heard'
 };

=item next

The C<next> method provides parallel iteration between workers for shared
C<array>, C<hash>, C<ordhash>, and C<sequence>. In list context, returns the
next key-value pair. This applies to C<array>, C<hash>, and C<ordhash>.
In scalar context, returns the next item. The C<undef> value is returned
after iteration has completed.

Internally, the list of keys to return is set when the closure is constructed.
Later keys added to the shared array or hash are not included. Subsequently,
the C<undef> value is returned for deleted keys.

The following example iterates through a shared array in parallel.

 use MCE::Hobo;
 use MCE::Shared;

 my $ob = MCE::Shared->array( 'a' .. 'j' );

 sub demo1 {
    my ( $id ) = @_;
    while ( my ( $index, $value ) = $ob->next ) {
       print "$id: [ $index ] $value\n";
       sleep 1;
    }
 }

 sub demo2 {
    my ( $id ) = @_;
    while ( defined ( my $value = $ob->next ) ) {
       print "$id: $value\n";
       sleep 1;
    }
 }

 MCE::Hobo->new( \&demo2, $_ ) for 1 .. 3;

 # ... do other work ...

 MCE::Hobo->waitall();

 # Output

 1: a
 2: b
 3: c
 2: f
 1: d
 3: e
 2: g
 3: i
 1: h
 2: j

The form is similar for C<sequence>. For large sequences, the C<bounds_only>
option is recommended. Also, specify C<chunk_size> accordingly. This reduces
the amount of traffic to and from the shared-manager process.

 use MCE::Hobo;
 use MCE::Shared;

 my $N   = shift || 4_000_000;
 my $pi  = MCE::Shared->scalar( 0.0 );

 my $seq = MCE::Shared->sequence(
    { chunk_size => 200_000, bounds_only => 1 }, 0, $N - 1
 );

 sub compute_pi {
    my ( $wid ) = @_;

    while ( my ( $beg, $end ) = $seq->next ) {
       my ( $_pi, $t ) = ( 0.0 );
       for my $i ( $beg .. $end ) {
          $t = ( $i + 0.5 ) / $N;
          $_pi += 4.0 / ( 1.0 + $t * $t );
       }
       $pi->incrby( $_pi );
    }

    return;
 }

 MCE::Hobo->create( \&compute_pi, $_ ) for ( 1 .. 8 );

 # ... do other stuff ...

 MCE::Hobo->waitall();

 printf "pi = %0.13f\n", $pi->get / $N;

 # Output

 3.1415926535898

=item rewind ( index, [, index, ... ] )

=item rewind ( key, [, key, ... ] )

=item rewind ( "query string" )

Rewinds the parallel iterator for L<MCE::Shared::Array>, L<MCE::Shared::Hash>,
or L<MCE::Shared::Ordhash> when no arguments are given. Otherwise, resets the
iterator with given criteria. The syntax for C<query string> is described in
the shared module.

 # array
 $ar->rewind;

 $ar->rewind( 0, 1 );
 $ar->rewind( "val eq some_value" );
 $ar->rewind( "key >= 50 :AND val =~ /sun|moon|air|wind/" );
 $ar->rewind( "val eq sun :OR val eq moon :OR val eq foo" );
 $ar->rewind( "key =~ /$pattern/" );

 while ( my ( $index, $value ) = $ar->next ) {
    ...
 }

 # hash, ordhash
 $oh->rewind;

 $oh->rewind( "key1", "key2" );
 $oh->rewind( "val eq some_value" );
 $oh->rewind( "key eq some_key :AND val =~ /sun|moon|air|wind/" );
 $oh->rewind( "val eq sun :OR val eq moon :OR val eq foo" );
 $oh->rewind( "key =~ /$pattern/" );

 while ( my ( $key, $value ) = $oh->next ) {
    ...
 }

=item rewind ( { options }, begin, end [, step, format ] )

=item rewind ( begin, end [, step, format ] )

Rewinds the parallel iterator for L<MCE::Shared::Sequence> when no arguments
are given. Otherwise, resets the iterator with given criteria.

 $seq->rewind;

 $seq->rewind( { chunk_size => 10, bounds_only => 1 }, 1, 100 );

 while ( my ( $beg, $end ) = $seq->next ) {
    for my $i ( $beg .. $end ) {
       ...
    }
 }

 $seq->rewind( 1, 100 );

 while ( defined ( my $num = $seq->next ) ) {
    ...
 }

=item store ( key, value )

Deep-sharing a non-blessed structure recursively is possible with C<store>,
an alias to C<STORE>.

 use MCE::Shared;

 my $h1 = MCE::Shared->hash();
 my $h2 = MCE::Shared->hash();

 # auto-shares deeply
 $h1->store( 'key', [ 0, 2, 5, { 'foo' => 'bar' } ] );
 $h2->{key}[3]{foo} = 'baz';   # via auto-vivification

 my $v1 = $h1->get('key')->get(3)->get('foo');  # bar
 my $v2 = $h2->get('key')->get(3)->get('foo');  # baz
 my $v3 = $h2->{key}[3]{foo};                   # baz

=back

=head1 SERVER API

=over 3

=item init

This method is called automatically by each MCE or Hobo worker immediately
after being spawned. The effect is extra parallelism during inter-process
communication. The optional ID (an integer) is modded internally in a
round-robin fashion.

 MCE::Shared->init();
 MCE::Shared->init( ID );

=item start

Starts the shared-manager process. This is done automatically.

 MCE::Shared->start();

=item stop

Stops the shared-manager process, wiping all shared data content. This is
called by the C<END> block automatically when the script terminates.

 MCE::Shared->stop();

=back

=head1 LOCKING

Application-level advisory locking is possible with L<MCE::Mutex>.

 use MCE::Hobo;
 use MCE::Mutex;
 use MCE::Shared;

 my $mutex = MCE::Mutex->new();

 tie my $cntr, 'MCE::Shared', 0;

 sub work {
    for ( 1 .. 1000 ) {
       $mutex->lock;

       # The next statement involves 2 IPC ops ( get and set ).
       # Thus, locking is required.
       $cntr++;

       $mutex->unlock;
    }
 }

 MCE::Hobo->create('work') for ( 1 .. 8 );
 MCE::Hobo->waitall;

 print $cntr, "\n"; # 8000

However, locking is not necessary when using the OO interface. This is possible
as MCE::Shared is implemented using a single-point of entry for commands sent
to the shared-manager process. Furthermore, the shared classes include sugar
methods for combining set and get in a single operation.

 use MCE::Hobo;
 use MCE::Shared;

 my $cntr = MCE::Shared->scalar( 0 );

 sub work {
    for ( 1 .. 1000 ) {
       # The next statement increments the value without having
       # to call set and get explicitly.
       $cntr->incr;
    }
 }

 MCE::Hobo->create('work') for ( 1 .. 8 );
 MCE::Hobo->waitall;

 print $cntr->get, "\n"; # 8000

Another possibility when running threads is locking via L<threads::shared>.

 use threads;
 use threads::shared;

 use MCE::Flow;
 use MCE::Shared;

 my $mutex : shared;

 tie my $cntr, 'MCE::Shared', 0;

 sub work {
    for ( 1 .. 1000 ) {
       lock $mutex;

       # the next statement involves 2 IPC ops ( get and set )
       # thus, locking is required
       $cntr++;
    }
 }

 MCE::Flow->run( { max_workers => 8 }, \&work );
 MCE::Flow->finish;

 print $cntr, "\n"; # 8000

Of the three demonstrations, the OO interface yields the best performance.
This is from the lack of locking at the application level. The results were
obtained from a MacBook Pro (Haswell) running at 2.6 GHz, 1600 MHz RAM.

 CentOS 7.2 VM

    -- Perl v5.16.3
    MCE::Mutex .... : 0.528 secs.
    OO Interface .. : 0.062 secs.
    threads::shared : 0.545 secs.

 FreeBSD 10.0 VM

    -- Perl v5.16.3
    MCE::Mutex .... : 0.367 secs.
    OO Interface .. : 0.083 secs.
    threads::shared : 0.593 secs.

 Mac OS X 10.11.6 ( Host OS )

    -- Perl v5.18.2
    MCE::Mutex .... : 0.397 secs.
    OO Interface .. : 0.070 secs.
    threads::shared : 0.463 secs.

 Solaris 11.2 VM

    -- Perl v5.12.5 installed with the OS
    MCE::Mutex .... : 0.895 secs.
    OO Interface .. : 0.099 secs.
    threads::shared :              Perl not built to support threads

    -- Perl v5.22.2 built with threads support
    MCE::Mutex .... : 0.788 secs.
    OO Interface .. : 0.086 secs.
    threads::shared : 0.895 secs.

 Windows 7 VM

    -- Perl v5.22.2
    MCE::Mutex .... : 1.045 secs.
    OO Interface .. : 0.312 secs.
    threads::shared : 1.061 secs.

Beginning with MCE::Shared 1.809, the C<pipeline> method provides another way.
Included in C<Array>, C<Cache>, C<Hash>, C<Minidb>, and C<Ordhash>, it combines
multiple commands for the object to be processed serially. For shared objects,
the call is made atomically due to single IPC to the shared-manager process.

The C<pipeline> method is fully C<wantarray>-aware and receives a list of
commands and their arguments. In scalar or list context, it returns data from
the last command in the pipeline.

 use MCE::Mutex;
 use MCE::Shared;

 my $mutex = MCE::Mutex->new();
 my $oh = MCE::Shared->ordhash();
 my @vals;

 # mutex locking

 $mutex->lock;
 $oh->set( foo => "a_a" );
 $oh->set( bar => "b_b" );
 $oh->set( baz => "c_c" );
 @vals = $oh->mget( qw/ foo bar baz / );
 $mutex->unlock;

 # pipeline, same thing done atomically

 @vals = $oh->pipeline(
    [ "set", foo => "a_a" ],
    [ "set", bar => "b_b" ],
    [ "set", baz => "c_c" ],
    [ "mget", qw/ foo bar baz / ]
 );

 # ( "a_a", "b_b", "c_c" )

There is also C<pipeline_ex>, same as C<pipeline>, but returns data for every
command in the pipeline.

 @vals = $oh->pipeline_ex(
    [ "set", foo => "a_a" ],
    [ "set", bar => "b_b" ],
    [ "set", baz => "c_c" ]
 );

 # ( "a_a", "b_b", "c_c" )

=head1 PYTHON DEMONSTRATION

Sharing a Python class is possible, starting with the 1.827 release.
The construction is simply calling share with the module option.
Methods are accessible via the OO interface.

 use strict;
 use warnings;

 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # Define Python class.
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 package My::Class;

 use Inline::Python qw( py_eval py_bind_class );

 py_eval ( <<'END_OF_PYTHON_CLASS' );

 class MyClass:
     def __init__(self):
         self.data = [0,0]

     def set (self, key, value):
         self.data[key] = value

     def get (self, key):
         try: return self.data[key]
         except KeyError: return None

     def incr (self, key):
         try: self.data[key] = self.data[key] + 1
         except KeyError: self.data[key] = 1

 END_OF_PYTHON_CLASS

 # Register methods for best performance.

 py_bind_class(
     'My::Class', '__main__', 'MyClass',
     'set', 'get', 'incr'
 );

 1;

 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # Share Python class. Requires MCE::Shared 1.827+.
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 package main;

 use MCE::Hobo;
 use MCE::Shared;

 my $py1 = MCE::Shared->share({ module => 'My::Class' });
 my $py2 = MCE::Shared->share({ module => 'My::Class' });

 MCE::Shared->start;

 $py1->set(0, 100);
 $py2->set(1, 200);

 die "Ooops" unless $py1->get(0) eq '100';
 die "Ooops" unless $py2->get(1) eq '200';

 sub task {
     $py1->incr(0) for 1 .. 50000;
     $py2->incr(1) for 1 .. 50000;
 }

 MCE::Hobo->create(\&task) for 1 .. 3;
 MCE::Hobo->waitall;

 print $py1->get(0), "\n";  # 150100
 print $py2->get(1), "\n";  # 150200

=head1 LOGGER DEMONSTRATION

Often, the requirement may call for concurrent logging by many workers.
Calling localtime or gmtime per each log entry is expensive. This uses
the old time-stamp value until one second has elapsed.

 use strict;
 use warnings;

 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # Logger class.
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 package My::Logger;

 use Time::HiRes qw( time );

 # construction

 sub new {
     my ( $class, %self ) = @_;

     open $self{fh}, ">>", $self{path} or return '';
     binmode $self{fh};

     $self{stamp} = localtime;  # or gmtime
     $self{time } = time;

     bless \%self, $class;
 }

 # $ob->log("message");

 sub log {
     my ( $self, $stamp ) = ( shift );

     if ( time - $self->{time} > 1.0 ) {
         $self->{stamp} = $stamp = localtime;  # or gmtime
         $self->{time } = time;
     }
     else {
         $stamp = $self->{stamp};
     }

     print {$self->{fh}} "$stamp --- @_\n";
 }

 # $ob->autoflush(0);
 # $ob->autoflush(1);

 sub autoflush {
     my ( $self, $flag ) = @_;

     if ( defined fileno($self->{fh}) ) {
          $flag ? select(( select($self->{fh}), $| = 1 )[0])
                : select(( select($self->{fh}), $| = 0 )[0]);

          return 1;
     }

     return;
 }

 # $ob->binmode($layer);
 # $ob->binmode();

 sub binmode {
     my ( $self, $layer ) = @_;

     if ( defined fileno($self->{fh}) ) {
         CORE::binmode $self->{fh}, $layer // ':raw';

         return 1;
     }

     return;
 }

 # $ob->close()

 sub close {
     my ( $self ) = @_;

     if ( defined fileno($self->{fh}) ) {
         close $self->{'fh'};
     }

     return;
 }

 # $ob->flush();

 sub flush {
     my ( $self ) = @_;

     if ( defined fileno($self->{fh}) ) {
         my $old_fh = select $self->{fh};
         my $old_af = $|; $| = 1; $| = $old_af;
         select $old_fh;

         return 1;
     }

     return;
 }

 1;

 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # Main script. Requires MCE::Shared 1.827+.
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 package main;

 use MCE::Hobo;
 use MCE::Shared;

 my $file = "log.txt";
 my $pid  = $$;

 my $ob = MCE::Shared->share( { module => 'My::Logger' }, path => $file )
     or die "open error '$file': $!";

 # $ob->autoflush(1);   # optional, flush write immediately

 sub work {
     my $id = shift;
     for ( 1 .. 250_000 ) {
         $ob->log("Hello from $id: $_");
     }
 }

 MCE::Hobo->create('work', $_) for 1 .. 4;
 MCE::Hobo->waitall;

 # Threads and multi-process safety for closing the handle.

 sub CLONE { $pid = 0; }

 END { $ob->close if $ob && $pid == $$; }

=head1 TIE::FILE DEMONSTRATION

The following presents a concurrent L<Tie::File> demonstration. Each element
in the array corresponds to a record in the text file. JSON, being readable,
seems appropiate for encoding complex objects.

 use strict;
 use warnings;

 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # Class extending Tie::File with two sugar methods.
 # Requires MCE::Shared 1.827+.
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 package My::File;

 use Tie::File;

 our @ISA = 'Tie::File';

 # $ob->append('string');

 sub append {
     my ($self, $key) = @_;
     my $val = $self->FETCH($key); $val .= $_[2];
     $self->STORE($key, $val);
     length $val;
 }

 # $ob->incr($key);

 sub incr {
     my ( $self, $key ) = @_;
     my $val = $self->FETCH($key); $val += 1;
     $self->STORE($key, $val);
     $val;
 }

 1;

 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # The MCE::Mutex module isn't needed unless IPC involves two or
 # more trips for the underlying action.
 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 package main;

 use MCE::Hobo;
 use MCE::Mutex;
 use MCE::Shared;

 use JSON::MaybeXS;

 # Safety for data having line breaks.
 use constant EOL => "\x{0a}~\x{0a}";

 my $file  = 'file.txt';
 my $mutex = MCE::Mutex->new();
 my $pid   = $$;

 my $ob = tie my @db, 'MCE::Shared', { module => 'My::File' }, $file,
     recsep => EOL or die "open error '$file': $!";

 $ob->encoder( \&JSON::MaybeXS::encode_json );
 $ob->decoder( \&JSON::MaybeXS::decode_json );

 $db[20] = 0;  # a counter at offset 20 into the array
 $db[21] = [ qw/ foo bar / ];  # store complex structure

 sub task {
     my $id  = sprintf "%02s", shift;
     my $row = int($id) - 1;
     my $chr = sprintf "%c", 97 + $id - 1;

     # A mutex isn't necessary when storing a value.
     # Ditto for fetching a value.

     $db[$row] = "Hello from $id: ";  # 1 trip
     my $val   = length $db[$row];    # 1 trip

     # A mutex may be necessary for updates involving 2 or
     # more trips (FETCH and STORE) during IPC, from and to
     # the shared-manager process, unless a unique row.

     for ( 1 .. 40 ) {
       # $db[$row] .= $id;         # 2 trips, unique row - okay
         $ob->append($row, $chr);  # 1 trip via the OO interface

       # $mu->lock;
       # $db[20] += 1;             # incrementing counter, 2 trips
       # $mu->unlock;

         $ob->incr(20);            # same thing via OO, 1 trip
     }

     my $len = length $db[$row];   # 1 trip

     printf "hobo %2d : %d\n", $id, $len;
 }

 MCE::Hobo->create('task', $_) for 1 .. 20;
 MCE::Hobo->waitall;

 printf "counter : %d\n", $db[20];
 print  $db[21]->[0], "\n";  # foo

 sub CLONE {
     $pid = 0;       # thread safety for completeness
 }

 END {
     if ( $pid == $$ ) {
         undef $ob;  # important, undef $ob before @db
         untie @db;  # untie @db to flush pending writes
     }
 }

=head1 REQUIREMENTS

MCE::Shared requires Perl 5.10.1 or later. The L<IO::FDPass> module is highly
recommended on UNIX and Windows. This module does not install it by default.

=head1 SOURCE AND FURTHER READING

The source, cookbook, and examples are hosted at GitHub.

=over 3

=item * L<https://github.com/marioroy/mce-shared>

=item * L<https://github.com/marioroy/mce-cookbook>

=item * L<https://github.com/marioroy/mce-examples>

=back

=head1 INDEX

L<MCE|MCE>, L<MCE::Hobo>

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2017 by Mario E. Roy

MCE::Shared is released under the same license as Perl.

See L<http://dev.perl.org/licenses/> for more information.

=cut

