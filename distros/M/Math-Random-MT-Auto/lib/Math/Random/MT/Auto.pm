package Math::Random::MT::Auto; {

require 5.006;

use strict;
use warnings;

our $VERSION = '6.23';
my $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

require Carp;
use Scalar::Util 1.18;

require XSLoader;
XSLoader::load('Math::Random::MT::Auto', $XS_VERSION);

use Object::InsideOut 2.06 ':hash_only';
use Object::InsideOut::Util 'shared_copy';

# Exceptions thrown by this package
use Exception::Class (
    'MRMA::Args' => {
        'isa' => 'OIO::Args',
        'description' =>
            'Math::Random::MT::Auto exception that indicates an argument error',
    },
);


### Inside-out Object Attributes ###

# Object data is stored in these attribute hashes, and is keyed to the object
# by a unique ID that is stored in the object's scalar reference.  For this
# class, that ID is the address of the PRNG's internal memory.
#
# These hashes are declared using the 'Field' attribute.

my %sources_for :Field;   # Sources from which to obtain random seed data
my %seed_for    :Field;   # Last seed sent to the PRNG


# Seed source subroutine dispatch table
my %DISPATCH = (
    'device'     => \&_acq_device,
    'random_org' => \&_acq_www,
    'hotbits'    => \&_acq_www,
    'rn_info'    => \&_acq_www,
);


### Module Initialization ###

# Handle exportation of subroutine names, user-specified and default
# seeding sources.  Also, auto-seeding of the standalone PRNG.
sub import
{
    my $class = shift;   # Not used

    # Exportable subroutines
    my %EXPORT_OK;
    @EXPORT_OK{qw(rand irand shuffle gaussian
                  exponential erlang poisson binomial
                  srand get_seed set_seed get_state set_state)} = undef;

    my $auto_seed = 1;   # Flag to auto-seed the standalone PRNG

    # Handle entries in the import list
    my $caller = caller();
    my @sources;
    while (my $sym = shift) {
        if (exists($EXPORT_OK{lc($sym)})) {
            # Export subroutine names
            no strict 'refs';
            *{$caller.'::'.$sym} = \&{lc($sym)};

        } elsif ($sym =~ /^:(no|!)?auto$/i) {
            # To auto-seed (:auto is default) or not (:!auto or :noauto)
            $auto_seed = not defined($1);

        } else {
            # User-specified seed acquisition sources
            # or user-defined seed acquisition subroutines
            push(@sources, $sym);
            # Add max. source count, if specified
            if (@_ && Scalar::Util::looks_like_number($_[0])) {
                push(@sources, shift);
            }
        }
    }

    # Setup default sources, if needed
    if (! @sources) {
        if (exists($DISPATCH{'win32'})) {
            push(@sources, 'win32');
        } elsif (-e '/dev/urandom') {
            push(@sources, '/dev/urandom');
        } elsif (-e '/dev/random') {
            push(@sources, '/dev/random');
        }
        push(@sources, 'random_org');
    }

    # Create standalone PRNG
    $MRMA::PRNG = Math::Random::MT::Auto->new(
                'SOURCE' => \@sources,
                ($auto_seed) ? () : ( 'SEED' => [ $$, time(), Scalar::Util::refaddr(\$VERSION) ] )
            );
}


### Dual-Interface (Functional and OO) Subroutines ###
#
# The subroutines below work both as regular 'functions' for the functional
# interface to the standalone PRNG, as well as methods for the OO interface
# to PRNG objects.

# Starts PRNG with random seed using specified sources (if any)
sub srand
{
    # Generalize for both OO and standalone PRNGs
    my $obj = (Scalar::Util::blessed($_[0])) ? shift : $MRMA::PRNG;

    if (@_) {
        # If sent seed by mistake, then send it to set_seed()
        if (Scalar::Util::looks_like_number($_[0]) || ref($_[0]) eq 'ARRAY') {
            $obj->set_seed(@_);
            return;
        }

        # Save specified sources
        $sources_for{$$obj} = shared_copy(\@_);
    }

    # Acquire seed from sources
    _acquire_seed($obj);

    # Seed the PRNG
    _seed_prng($obj);
}


# Return ref to PRNG's saved seed (if any)
sub get_seed
{
    # Generalize for both OO and standalone PRNGs
    my $obj = (Scalar::Util::blessed($_[0])) ? shift : $MRMA::PRNG;

    if (wantarray()) {
        return (@{$seed_for{$$obj}});
    }
    return ($seed_for{$$obj});
}


# Apply supplied seed, if given, to the PRNG,
sub set_seed
{
    # Generalize for both OO and standalone PRNGs
    my $obj = (Scalar::Util::blessed($_[0])) ? shift : $MRMA::PRNG;

    # Check argument
    if (! @_) {
        MRMA::Args->throw('message' => q/Missing argument to '->set_seed()'/);
    }

    # Save a copy of the seed
    if (ref($_[0]) eq 'ARRAY') {
        $seed_for{$$obj} = shared_copy($_[0]);
    } else {
        $seed_for{$$obj} = shared_copy(\@_);
    }

    # Seed the PRNG
    _seed_prng($obj);
}


# Return copy of PRNG's current state
sub get_state
{
    # Generalize for both OO and standalone PRNGs
    my $obj = (Scalar::Util::blessed($_[0])) ? shift : $MRMA::PRNG;

    if (wantarray()) {
        return (@{Math::Random::MT::Auto::_::get_state($obj)});
    }
    return (Math::Random::MT::Auto::_::get_state($obj));
}


# Set PRNG to supplied state
sub set_state
{
    # Generalize for both OO and standalone PRNGs
    my $obj = (Scalar::Util::blessed($_[0])) ? shift : $MRMA::PRNG;

    # Input can be array ref or array
    if (ref($_[0]) eq 'ARRAY') {
        Math::Random::MT::Auto::_::set_state($obj, $_[0]);
    } else {
        Math::Random::MT::Auto::_::set_state($obj, \@_);
    }
}


### Inside-out Object Internal Subroutines ###

# Object Constructor
sub _new_prng :ID
{
    return (Math::Random::MT::Auto::_::new_prng());
}

sub _clone_state :Replicate
{
    my ($from_obj, $to_obj) = @_;

    my $state = Math::Random::MT::Auto::_::get_state($from_obj);
    Math::Random::MT::Auto::_::set_state($to_obj, $state);
}

sub _free_prng :Destroy
{
    Math::Random::MT::Auto::_::free_prng(shift);
}

my %init_args :InitArgs = (
    'SOURCE' => {
        'REGEX'   => qr/^(?:source|src)s?$/i,
        'FIELD'   => \%sources_for,
        'TYPE'    => 'LIST',
    },
    'SEED' => {
        'REGEX'   => qr/^seed$/i,
        'DEFAULT' => [],
        'FIELD'   => \%seed_for,
        'TYPE'    => 'LIST',
    },
    'STATE' => {
        'REGEX'   => qr/^state$/i,
        'TYPE'    => 'ARRAY',
    },
);

# Object initializer - for internal use only
sub _init :Init
{
    my $self = $_[0];
    my $args = $_[1];   # Hash ref containing arguments from object
                        # constructor as specified by %init_args above

    # If no sources specified, then use default sources from standalone PRNG
    if (! exists($sources_for{$$self})) {
        my @srcs = @{$sources_for{$$MRMA::PRNG}};
        $self->set(\%sources_for, \@srcs);
    }

    # If state is specified, then use it
    if (exists($args->{'STATE'})) {
        $self->set_state($args->{'STATE'});

    } else {
        # Acquire seed, if none provided
        if (! @{$seed_for{$$self}}) {
            _acquire_seed($self);
        }

        # Seed the PRNG
        _seed_prng($self);
    }
}


### Overloading ###

sub as_string :Stringify :Numerify
{
    return ($_[0]->irand());
}

sub bool :Boolify
{
    return ($_[0]->irand() & 1);
}

sub array :Arrayify
{
    my $self  = $_[0];
    my $count = $_[1] || 1;

    my @ary;
    do {
        push(@ary, $self->irand());
    } while (--$count > 0);

    return (\@ary);
}

sub _code :Codify
{
    my $self = $_[0];
    return (sub { $self->irand(); });
}


### Serialization ###

# Support for ->dump() method
sub _dump :DUMPER
{
    my $obj = shift;

    my @seed    = @{$seed_for{$$obj}};
    # Must filter out code refs from sources
    my @sources = grep { ref($_) ne 'CODE' } @{$sources_for{$$obj}};
    my @state   = $obj->get_state();

    return ({
                'SOURCES' => \@sources,
                'SEED'    => \@seed,
                'STATE'   => \@state,
            });
}

# Support for Object::InsideOut::pump()
sub _pump :PUMPER
{
    my ($obj, $data) = @_;

    $obj->set(\%sources_for, $$data{'SOURCES'});
    $obj->set(\%seed_for,    $$data{'SEED'});
    $obj->set_state($$data{'STATE'});
}


### Internal Subroutines ###

# Constants #

# Size of Perl's integers (32- or 64-bit) and corresponding unpack code
require Config;
my $INT_SIZE    = $Config::Config{'uvsize'};
my $UNPACK_CODE = ($INT_SIZE == 8) ? 'Q' : 'L';
# Number of ints for a full 19968-bit seed
my $FULL_SEED   = 2496 / $INT_SIZE;


# If Windows XP and Win32::API, then make 'win32' a valid source
if (($^O eq 'MSWin32') || ($^O eq 'cygwin')) {
    eval { require Win32; };
    if (! $@) {
        my ($id, $major, $minor) = (Win32::GetOSVersion())[4,1,2];
        if (defined($minor) &&
            (($id > 2) ||
             ($id == 2 && $major > 5) ||
             ($id == 2 && $major == 5 && $minor >= 1)))
        {
            eval {
                # Suppress (harmless) warning about Win32::API::Type's INIT block
                local $SIG{__WARN__} = sub {
                    if ($_[0] !~ /^Too late to run INIT block/) {
                        print(STDERR "$_[0]\n");    # Output other warnings
                    }
                };

                require Win32::API;
            };
            if (! $@) {
                $DISPATCH{'win32'} = \&_acq_win32;
            }
        }
    }
}


# Acquire seed data from specific sources
sub _acquire_seed :PRIVATE
{
    my $prng    = $_[0];

    my $sources = $sources_for{$$prng};
    my $seed    = $seed_for{$$prng};

    # Acquire seed data until we have a full seed,
    # or until we run out of sources
    @{$seed} = ();
    for (my $ii=0;
         (@{$seed} < $FULL_SEED) && ($ii < @{$sources});
         $ii++)
    {
        my $src = $sources->[$ii];
        my $src_key = lc($src);   # Suitable as hash key

        # Determine amount of data needed
        my $need = $FULL_SEED - @{$seed};
        if (($ii+1 < @{$sources}) &&
            Scalar::Util::looks_like_number($sources->[$ii+1]))
        {
            if ($sources->[++$ii] < $need) {
                $need = $sources->[$ii];
            }
        }

        if (ref($src) eq 'CODE') {
            # User-supplied seeding subroutine
            $src->($seed, $need);

        } elsif (defined($DISPATCH{$src_key})) {
            # Module defined seeding source
            # Execute subroutine ref from dispatch table
            $DISPATCH{$src_key}->($src_key, $prng, $need);

        } elsif (-e $src) {
            # Random device or file
            $DISPATCH{'device'}->($src, $prng, $need);

        } else {
            Carp::carp("Unknown seeding source: $src");
        }
    }

    if (! @{$seed}) {
        # Complain about not getting any seed data, and provide a minimal seed
        Carp::carp('No seed data obtained from sources - Setting minimal seed using PID and time');
        push(@{$seed}, $$, time());

    } elsif (@{$seed} < $FULL_SEED) {
        # Complain about not getting a full seed
        Carp::carp('Partial seed - only ' . scalar(@{$seed}) . ' of ' . $FULL_SEED);
    }
}


# Acquire seed data from a device/file
sub _acq_device :PRIVATE
{
    my $device = $_[0];
    my $prng   = $_[1];
    my $need   = $_[2];

    # Try opening device/file
    my $FH;
    if (! open($FH, '<', $device)) {
        Carp::carp("Failure opening random device '$device': $!");
        return;
    }
    binmode($FH);

    # Try to set non-blocking mode (but not on Windows and Haiku)
    if ($^O ne 'MSWin32' && $^O ne 'Haiku') {
        eval {
            require Fcntl;

            my $flags;
            $flags = fcntl($FH, &Fcntl::F_GETFL, 0)
                or die("Failed getting filehandle flags: $!\n");
            fcntl($FH, &Fcntl::F_SETFL, $flags | &Fcntl::O_NONBLOCK)
                or die("Failed setting filehandle flags: $!\n");
        };
        if ($@) {
            Carp::carp("Failure setting non-blocking mode on random device '$device': $@");
        }
    }

    # Read data
    for (1..$need) {
        my $data;
        my $cnt = read($FH, $data, $INT_SIZE);

        if (defined($cnt)) {
            # Complain if we didn't get all the data we asked for
            if ($cnt < $INT_SIZE) {
                Carp::carp("Random device '$device' exhausted");
            }
            # Add data to seed array
            if ($cnt = int($cnt / $INT_SIZE)) {
                push(@{$seed_for{$$prng}}, unpack("$UNPACK_CODE$cnt", $data));
            }
        } else {
            Carp::carp("Failure reading from random device '$device': $!");
        }
    }
    close($FH);
}


# Cached LWP::UserAgent object
my $LWP_UA;

# Subroutine to acquire seed data from Internet sources
sub _acq_www :PRIVATE
{
    my $src  = $_[0];
    my $prng = $_[1];
    my $need = $_[2];

    # First, create user-agent object, if needed
    if (! $LWP_UA) {
        eval {
            require LWP::UserAgent;
            $LWP_UA = LWP::UserAgent->new('timeout' => 5, 'env_proxy' => 1);
        };
        if ($@) {
            Carp::carp("Failure creating user-agent: $@");
            return;
        }
    }

    ### Internal subroutines for processing Internet data

    # Process data from random.org
    my $random_org = sub {
        my $prng    = $_[0];
        my $content = $_[1];

        # Add data to seed array
        push(@{$seed_for{$$prng}}, unpack("$UNPACK_CODE*", $content));
    };

    # Process data from HotBits
    my $hotbits = sub {
        my $prng    = $_[0];
        my $content = $_[1];

        if ($content =~ /exceeded your 24-hour quota/) {
            # Complain about exceeding Hotbits quota
            Carp::carp('You have exceeded your 24-hour quota for HotBits.');
        } else {
            # Add data to seed array
            push(@{$seed_for{$$prng}}, unpack("$UNPACK_CODE*", $content));
        }
    };

    # Process data from RandomNumbers.info
    my $rn_info = sub {
        my $prng    = $_[0];
        my $content = $_[1];

        # Extract digits from web page
        my (@bytes) = $content =~ / ([\d]+)/g;
        # Make sure we have correct number of bytes for complete integers.
        # Also gets rid of copyright year that gets picked up from end of web page.
        do {
            pop(@bytes);
        } while (@bytes % $INT_SIZE);
        while (@bytes) {
            # Construct integers from bytes
            my $num = 0;
            for (1 .. $INT_SIZE) {
                $num = ($num << 8) + pop(@bytes);
            }
            # Add integer data to seed array
            push(@{$seed_for{$$prng}}, $num);
        }
    };

    ### Internet seed source information table
    my %www = (
        'random_org' => {
            'sitename'  => 'random.org',
            'URL'       => 'http://www.random.org/cgi-bin/randbyte?nbytes=',
            'max_bytes' => $FULL_SEED * $INT_SIZE,
            'processor' => $random_org
        },
        'hotbits' => {
            'sitename'  => 'HotBits',
            'URL'       => 'http://www.fourmilab.ch/cgi-bin/uncgi/Hotbits?fmt=bin&nbytes=',
            'max_bytes' => 2048,
            'processor' => $hotbits
        },
        'rn_info' => {
            'sitename'  => 'RandomNumbers.info',
            'URL'       => 'http://www.randomnumbers.info/cgibin/wqrng.cgi?limit=255&amount=',
            'max_bytes' => 1000,
            'processor' => $rn_info
        }
    );

    # Number of bytes to request (observing maximum data limit)
    my $bytes = $need * $INT_SIZE;
    if ($bytes > $www{$src}{'max_bytes'}) {
        $bytes = $www{$src}{'max_bytes'};
    }

    # Request the data
    my $res;
    eval {
        # Create request
        my $req = HTTP::Request->new('GET' => $www{$src}{'URL'} . $bytes);
        # Send the request
        $res = $LWP_UA->request($req);
    };

    # Handle the response
    if ($@) {
        Carp::carp("Failure contacting $www{$src}{'sitename'}: $@");
    } elsif ($res->is_success) {
        # Process the data
        $www{$src}{'processor'}->($prng, $res->content);
    } else {
        Carp::carp("Failure getting data from $www{$src}{'sitename'}: "
                                                    . $res->status_line);
    }
}


# Acquire seed data from Win XP random source
sub _acq_win32 :PRIVATE
{
    my $src   = $_[0];   # Not used
    my $prng  = $_[1];
    my $need  = $_[2];
    my $bytes = $need * $INT_SIZE;

    eval {
        # Import the random source function
        my $func = Win32::API->new('ADVAPI32.DLL',
                                   'SystemFunction036',
                                   'PN', 'I');
        if (! defined($func)) {
            die("Failure importing 'SystemFunction036': $!\n");
        }

        # Acquire the random data
        my $buffer = chr(0) x $bytes;
        if (! $func->Call($buffer, $bytes)) {
            die("'SystemFunction036' failed: $^E\n");
        }

        # Add data to seed array
        push(@{$seed_for{$$prng}}, unpack("$UNPACK_CODE*", $buffer));
    };
    if ($@) {
        Carp::carp("Failure acquiring Win XP random data: $@");
    }
}


# Seeds a PRNG
sub _seed_prng :PRIVATE
{
    my $prng = $_[0];

    my $seed = $seed_for{$$prng};   # Get the seed for the PRNG

    if ($Config::Config{'useithreads'} &&
        $threads::shared::threads_shared &&
        threads::shared::_id($seed))
    {
        # If the seed is thread-shared, then must make a non-shared copy to
        # send to the PRNG
        my @seed = @{$seed};
        Math::Random::MT::Auto::_::seed_prng($prng, \@seed);

    } else {
        # If no thread object sharing, then just send the seed
        Math::Random::MT::Auto::_::seed_prng($prng, $seed);
    }
}

}  # End of package's lexical scope

1;

__END__

=head1 NAME

Math::Random::MT::Auto - Auto-seeded Mersenne Twister PRNGs

=head1 VERSION

This documentation refers to Math::Random::MT::Auto version 6.23

=head1 SYNOPSIS

 use strict;
 use warnings;
 use Math::Random::MT::Auto qw(rand irand shuffle gaussian),
                            '/dev/urandom' => 256,
                            'random_org';

 # Functional interface
 my $die_roll = 1 + int(rand(6));

 my $coin_flip = (irand() & 1) ? 'heads' : 'tails';

 my @deck = shuffle(1 .. 52);

 my $rand_IQ = gaussian(15, 100);

 # OO interface
 my $prng = Math::Random::MT::Auto->new('SOURCE' => '/dev/random');

 my $angle = $prng->rand(360);

 my $decay_interval = $prng->exponential(12.4);

=head1 DESCRIPTION

The Mersenne Twister is a fast pseudorandom number generator (PRNG) that is
capable of providing large volumes (> 10^6004) of "high quality" pseudorandom
data to applications that may exhaust available "truly" random data sources or
system-provided PRNGs such as L<rand|perlfunc/"rand">.

This module provides PRNGs that are based on the Mersenne Twister.  There
is a functional interface to a single, standalone PRNG, and an OO interface
(based on the inside-out object model as implemented by the
L<Object::InsideOut> module) for generating multiple PRNG objects.  The PRNGs
are normally self-seeding, automatically acquiring a (19968-bit) random seed
from user-selectable sources.  (I<Manual> seeding is optionally available.)

=over

=item Random Number Deviates

In addition to integer and floating-point uniformly-distributed random number
deviates (i.e., L<"irand"> and L<"rand">), this module implements the
following non-uniform deviates as found in I<Numerical Recipes in C>:

=over

=over

=item * Gaussian (normal)

=item * Exponential

=item * Erlang (gamma of integer order)

=item * Poisson

=item * Binomial

=back

=back

=item Shuffling

This module also provides a subroutine/method for shuffling data based on the
Fisher-Yates shuffling algorithm.

=item Support for 64-bit Integers

If Perl has been compiled to support 64-bit integers (do
L<perl -V|perlrun/"-V"> and look for C<use64bitint=define>), then this module
will use a 64-bit-integer version of the Mersenne Twister, thus providing
64-bit random integers and 52-bit random doubles.  The size of integers
returned by L</"irand">, and used by L</"get_seed"> and L</"set_seed"> will be
sized accordingly.

Programmatically, the size of Perl's integers can be determined using the
C<Config> module:

 use Config;
 print("Integers are $Config{'uvsize'} bytes in length\n");

=back

The code for this module has been optimized for speed.  Under Cygwin, it's
2.5 times faster than Math::Random::MT, and under Solaris, it's more than
four times faster.  (Math::Random::MT fails to build under Windows.)

=head1 QUICKSTART

To use this module as a drop-in replacement for Perl's built-in
L<rand|perlfunc/"rand"> function, just add the following to the top of your
application code:

 use strict;
 use warnings;
 use Math::Random::MT::Auto 'rand';

and then just use L</"rand"> as you would normally.  You don't even need to
bother seeding the PRNG (i.e., you don't need to call L</"srand">), as that
gets done automatically when the module is loaded by Perl.

If you need multiple PRNGs, then use the OO interface:

 use strict;
 use warnings;
 use Math::Random::MT::Auto;

 my $prng1 = Math::Random::MT::Auto->new();
 my $prng2 = Math::Random::MT::Auto->new();

 my $rand_num = $prng1->rand();
 my $rand_int = $prng2->irand();

B<CAUTION>: If you want to L<require|perlfunc/"require"> this module, see the
L</"Delayed Importation"> section for important information.

=head1 MODULE DECLARATION

The module must always be declared such that its C<-E<gt>import()> method gets
called:

 use Math::Random::MT::Auto;            # Correct

 #use Math::Random::MT::Auto ();        # Does not work because
                                        #   ->import() does not get invoked

=head2 Subroutine Declarations

By default, this module does not automatically export any of its subroutines.
If you want to use the standalone PRNG, then you should specify the
subroutines you want to use when you declare the module:

 use Math::Random::MT::Auto qw(rand irand shuffle gaussian
                               exponential erlang poisson binomial
                               srand get_seed set_seed get_state set_state);

Without the above declarations, it is still possible to use the standalone
PRNG by accessing the subroutines using their fully-qualified names.  For
example:

 my $rand = Math::Random::MT::Auto::rand();

=head2 Module Options

=over

=item Seeding Sources

Starting the PRNGs with a 19968-bit random seed (312 64-bit integers or 624
32-bit integers) takes advantage of their full range of possible internal
vectors states.  This module attempts to acquire such seeds using several
user-selectable sources.

(I would be interested to hear about other random data sources for possible
inclusion in future versions of this module.)

=over

=item Random Devices

Most OSs offer some sort of device for acquiring random numbers.  The
most common are F</dev/urandom> and F</dev/random>.  You can specify the
use of these devices for acquiring the seed for the PRNG when you declare
this module:

 use Math::Random::MT::Auto '/dev/urandom';
   # or
 my $prng = Math::Random::MT::Auto->new('SOURCE' => '/dev/random');

or they can be specified when using L</"srand">.

 srand('/dev/random');
   # or
 $prng->srand('/dev/urandom');

The devices are accessed in I<non-blocking> mode so that if there is
insufficient data when they are read, the application will not hang waiting
for more.

=item File of Binary Data

Since the above devices are just files as far as Perl is concerned, you can
also use random data previously stored in files (in binary format).

 srand('C:\\Temp\\RANDOM.DAT');
   # or
 $prng->srand('/tmp/random.dat');

=item Internet Sites

This module provides support for acquiring seed data from several Internet
sites:  random.org, HotBits and RandomNumbers.info.  An Internet connection
and L<LWP::UserAgent> are required to utilize these sources.

 use Math::Random::MT::Auto 'random_org';
   # or
 use Math::Random::MT::Auto 'hotbits';
   # or
 use Math::Random::MT::Auto 'rn_info';

If you connect to the Internet through an HTTP proxy, then you must set
the L<http_proxy|LWP/"http_proxy"> variable in your environment when using
these sources.  (See L<LWP::UserAgent/"Proxy attributes">.)

The HotBits site will only provide a maximum of 2048 bytes of data per
request, and RandomNumbers.info's maximum is 1000.  If you want to get the
full seed from these sites, then you can specify the source multiple times:

 my $prng = Math::Random::MT::Auto->new('SOURCE' => ['hotbits',
                                                     'hotbits']);

or specify multiple sources:

 use Math::Random::MT::Auto qw(rn_info hotbits random_org);

=item Windows XP Random Data

Under MSWin32 or Cygwin on Windows XP, you can acquire random seed data from
the system.

 use Math::Random::MT::Auto 'win32';

To utilize this option, you must have the L<Win32::API> module
installed.

=item User-defined Seeding Source

A subroutine reference may be specified as a seeding source.  When called, it
will be passed three arguments:  A array reference where seed data is to be
added, and the number of integers (64- or 32-bit as the case may be) needed.

 sub MySeeder
 {
     my $seed = $_[0];
     my $need = $_[1];

     while ($need--) {
         my $data = ...;      # Get seed data from your source
         ...
         push(@{$seed}, $data);
     }
 }

 my $prng = Math::Random::MT::Auto->new('SOURCE' => \&MySeeder);

=back

The default list of seeding sources is determined when the module is loaded.
Under MSWin32 or Cygwin on Windows XP, C<win32> is added to the list if
L<Win32::API> is available.  Otherwise, F</dev/urandom> and then
F</dev/random> are checked.  The first one found is added to the list.
Finally, C<random_org> is added.

For the functional interface to the standalone PRNG, these defaults can be
overridden by specifying the desired sources when the module is declared, or
through the use of the L</"srand"> subroutine.  Similarly for the OO
interface, they can be overridden in the
L<-E<gt>new()|/"Math::Random::MT::Auto-E<gt>new"> method when the PRNG is
created, or later using the L</"srand"> method.

Optionally, the maximum number of integers (64- or 32-bits as the case may
be) to be acquired from a particular source may be specified:

 # Get at most 1024 bytes from random.org
 # Finish the seed using data from /dev/urandom
 use Math::Random::MT::Auto 'random_org' => (1024 / $Config{'uvsize'}),
                            '/dev/urandom';

=item Delayed Seeding

Normally, the standalone PRNG is automatically seeded when the module is
loaded.  This behavior can be modified by supplying the C<:!auto> (or
C<:noauto>) flag when the module is declared.  (The PRNG will still be
seeded using data such as L<time()|perlfunc/"time"> and PID
(L<$$|perlvar/"$$">), just in case.)  When the C<:!auto> option is used, the
L</"srand"> subroutine should be imported, and then run before calling any of
the random number deviates.

 use Math::Random::MT::Auto qw(rand srand :!auto);
   ...
 srand();
   ...
 my $rn = rand(10);

=back

=head2 Delayed Importation

If you want to delay the importation of this module using
L<require|perlfunc/"require">, then you must execute its C<-E<gt>import()>
method to complete the module's initialization:

 eval {
     require Math::Random::MT::Auto;
     # You may add options to the import call, if desired.
     Math::Random::MT::Auto->import();
 };

=head1 STANDALONE PRNG OBJECT

=over

=item my $obj = $MRMA::PRNG;

C<$MRMA::PRNG> is the object that represents the standalone PRNG.

=back

=head1 OBJECT CREATION

The OO interface for this module allows you to create multiple, independent
PRNGs.

If your application will only be using the OO interface, then declare this
module using the L<:!auto|/"Delayed Seeding"> flag to forestall the automatic
seeding of the standalone PRNG:

 use Math::Random::MT::Auto ':!auto';

=over

=item Math::Random::MT::Auto->new

 my $prng = Math::Random::MT::Auto->new( %options );

Creates a new PRNG.  With no options, the PRNG is seeded using the default
sources that were determined when the module was loaded, or that were last
supplied to the L</"srand"> subroutine.

=over

=item 'STATE' => $prng_state

Sets the newly created PRNG to the specified state.  The PRNG will then
function as a clone of the RPNG that the state was obtained from (at the
point when then state was obtained).

When the C<STATE> option is used, any other options are just stored (i.e.,
they are not acted upon).

=item 'SEED' => $seed_array_ref

When the C<STATE> option is not used, this option seeds the newly created
PRNG using the supplied seed data.  Otherwise, the seed data is just
copied to the new object.

=item 'SOURCE' => 'source'

=item 'SOURCE' => ['source', ...]

Specifies the seeding source(s) for the PRNG.  If the C<STATE> and C<SEED>
options are not used, then seed data will be immediately fetched using the
specified sources, and used to seed the PRNG.

The source list is retained for later use by the L</"srand"> method.  The
source list may be replaced by calling the L</"srand"> method.

'SOURCES', 'SRC' and 'SRCS' can all be used as synonyms for 'SOURCE'.

=back

The options above are also supported using lowercase and mixed-case names
(e.g., 'Seed', 'src', etc.).

=item $obj->new

 my $prng2 = $prng1->new( %options );

Creates a new PRNG in the same manner as L</"Math::Random::MT::Auto-E<gt>new">.

=item $obj->clone

 my $prng2 = $prng1->clone();

Creates a new PRNG that is a copy of the referenced PRNG.

=back

=head1 SUBROUTINES/METHODS

When any of the I<functions> listed below are invoked as subroutines, they
operates with respect to the standalone PRNG.  For example:

 my $rand = rand();

When invoked as methods, they operate on the referenced PRNG object:

 my $rand = $prng->rand();

For brevity, only usage examples for the functional interface are given below.

=over

=item rand

 my $rn = rand();
 my $rn = rand($num);

Behaves exactly like Perl's built-in L<rand|perlfunc/"rand">, returning a
number uniformly distributed in [0, $num).  ($num defaults to 1.)

NOTE: If you still need to access Perl's built-in L<rand|perlfunc/"rand">
function, you can do so using C<CORE::rand()>.

=item irand

 my $int = irand();

Returns a random integer.  For 32-bit integer Perl, the range is 0 to
2^32-1 (0xFFFFFFFF) inclusive.  For 64-bit integer Perl, it's 0 to 2^64-1
inclusive.

This is the fastest way to obtain random numbers using this module.

=item shuffle

 my @shuffled = shuffle($data, ...);
 my @shuffled = shuffle(@data);

Returns an array of the random ordering of the supplied arguments (i.e.,
shuffled) by using the Fisher-Yates shuffling algorithm.  It can also be
called to return an array reference:

 my $shuffled = shuffle($data, ...);
 my $shuffled = shuffle(@data);

If called with a single array reference (fastest method), the contents of the
array are shuffled in situ:

 shuffle(\@data);

=item gaussian

 my $gn = gaussian();
 my $gn = gaussian($sd);
 my $gn = gaussian($sd, $mean);

Returns floating-point random numbers from a Gaussian (normal) distribution
(i.e., numbers that fit a bell curve).  If called with no arguments, the
distribution uses a standard deviation of 1, and a mean of 0.  Otherwise,
the supplied argument(s) will be used for the standard deviation, and the
mean.

=item exponential

 my $xn = exponential();
 my $xn = exponential($mean);

Returns floating-point random numbers from an exponential distribution.  If
called with no arguments, the distribution uses a mean of 1.  Otherwise, the
supplied argument will be used for the mean.

An example of an exponential distribution is the time interval between
independent Poisson-random events such as radioactive decay.  In this case,
the mean is the average time between events.  This is called the I<mean life>
for radioactive decay, and its inverse is the decay constant (which represents
the expected number of events per unit time).  The well known term
I<half-life> is given by C<mean * ln(2)>.

=item erlang

 my $en = erlang($order);
 my $en = erlang($order, $mean);

Returns floating-point random numbers from an Erlang distribution of specified
order.  The order must be a positive integer (> 0).  The mean, if not
specified, defaults to 1.

The Erlang distribution is the distribution of the sum of C<$order>
independent identically distributed random variables each having an
exponential distribution.  (It is a special case of the gamma distribution for
which C<$order> is a positive integer.)  When C<$order = 1>, it is just the
exponential distribution.  It is named after A. K. Erlang who developed it to
predict waiting times in queuing systems.

=item poisson

 my $pn = poisson($mean);
 my $pn = poisson($rate, $time);

Returns integer random numbers (>= 0) from a Poisson distribution of specified
mean (rate * time = mean).  The mean must be a positive value (> 0).

The Poisson distribution predicts the probability of the number of
Poisson-random events occurring in a fixed time if these events occur with a
known average rate.  Examples of events that can be modeled as Poisson
distributions include:

=over

=over

=item * The number of decays from a radioactive sample within a given time
period.

=item * The number of cars that pass a certain point on a road within a given
time period.

=item * The number of phone calls to a call center per minute.

=item * The number of road kill found per a given length of road.

=back

=back

=item binomial

 my $bn = binomial($prob, $trials);

Returns integer random numbers (>= 0) from a binomial distribution.  The
probability (C<$prob>) must be between 0.0 and 1.0 (inclusive), and the number
of trials must be >= 0.

The binomial distribution is the discrete probability distribution of the
number of successes in a sequence of C<$trials> independent Bernoulli trials
(i.e., yes/no experiments), each of which yields success with probability
C<$prob>.

If the number of trials is very large, the binomial distribution may be
approximated by a Gaussian distribution. If the average number of successes
is small (C<$prob * $trials < 1>), then the binomial distribution can be
approximated by a Poisson distribution.

=item srand

 srand();
 srand('source', ...);

This (re)seeds the PRNG.  It may be called anytime reseeding of the PRNG is
desired (although this should normally not be needed).

When the L<:!auto|/"Delayed Seeding"> flag is used, the C<srand> subroutine
should be called before any other access to the standalone PRNG.

When called without arguments, the previously determined/specified seeding
source(s) will be used to seed the PRNG.

Optionally, seeding sources may be supplied as arguments as when using the
L<'SOURCE'|/"Seeding Sources"> option.  (These sources will be saved and used
again if C<srand> is subsequently called without arguments).

 # Get 250 integers of seed data from Hotbits,
 #  and then get the rest from /dev/random
 srand('hotbits' => 250, '/dev/random');

If called with integer data (a list of one or more value, or an array of
values), or a reference to an array of integers, these data will be passed to
L</"set_seed"> for use in reseeding the PRNG.

NOTE: If you still need to access Perl's built-in L<srand|perlfunc/"srand">
function, you can do so using C<CORE::srand($seed)>.

=item get_seed

 my @seed = get_seed();
   # or
 my $seed = get_seed();

Returns an array or an array reference containing the seed last sent to the
PRNG.

NOTE: Changing the data in the array will not cause any changes in the PRNG
(i.e., it will not reseed it).  You need to use L</"srand"> or L</"set_seed">
for that.

=item set_seed

 set_seed($seed, ...);
 set_seed(@seed);
 set_seed(\@seed);

When called with integer data (a list of one or more value, or an array of
values), or a reference to an array of integers, these data will be used to
reseed the PRNG.

Together with L</"get_seed">, C<set_seed> may be useful for setting up
identical sequences of random numbers based on the same seed.

It is possible to seed the PRNG with more than 19968 bits of data (312 64-bit
integers or 624 32-bit integers).  However, doing so does not make the PRNG
"more random" as 19968 bits more than covers all the possible PRNG state
vectors.

=item get_state

 my @state = get_state();
   # or
 my $state = get_state();

Returns an array (for list context) or an array reference (for scalar context)
containing the current state vector of the PRNG.

Note that the state vector is not a full serialization of the PRNG.  (See
L</"Serialization"> below.)

=item set_state

 set_state(@state);
   # or
 set_state($state);

Sets a PRNG to the state contained in an array or array reference containing
the state previously obtained using L</"get_state">.

 # Get the current state of the PRNG
 my @state = get_state();

 # Run the PRNG some more
 my $rand1 = irand();

 # Restore the previous state of the PRNG
 set_state(@state);

 # Get another random number
 my $rand2 = irand();

 # $rand1 and $rand2 will be equal.

B<CAUTION>:  It should go without saying that you should not modify the
values in the state vector obtained from L</"get_state">.  Doing so and then
feeding it to L</"set_state"> would be (to say the least) naughty.

=back

=head1 INSIDE-OUT OBJECTS

By using L<Object::InsideOut>, Math::Random::MT::Auto's PRNG objects support
the following capabilities:

=head2 Cloning

Copies of PRNG objects can be created using the C<-E<gt>clone()> method.

 my $prng2 = $prng->clone();

See L<Object::InsideOut/"Object Cloning"> for more details.

=head2 Serialization

PRNG objects can be serialized using the C<-E<gt>dump()> method.

 my $array_ref = $prng->dump();
   # or
 my $string = $prng->dump(1);

Serialized object can then be converted back into PRNG objects:

 my $prng2 = Object::InsideOut->pump($array_ref);

See L<Object::InsideOut/"Object Serialization"> for more details.

Serialization using L<Storable> is also supported:

 use Storable qw(freeze thaw);

 BEGIN {
     $Math::Random::MT::Auto::storable = 1;
 }
 use Math::Random::MT::Auto ...;

 my $prng = Math::Random::MT::Auto->new();

 my $tmp = $prng->freeze();
 my $prng2 = thaw($tmp);

See L<Object::InsideOut/"Storable"> for more details.

B<NOTE:> Code refs cannot be serialized. Therefore, any
L</"User-defined Seeding Source"> subroutines used in conjunction with
L</"srand"> will be filtered out from the serialized results.

=head2 Coercion

Various forms of object coercion are supported through the L<overload>
mechanism.  For instance, you can to use a PRNG object directly in a string:

 my $prng = Math::Random::MT::Auto->new();
 print("Here's a random integer: $prng\n");

The I<stringification> of the PRNG object is accomplished by calling
C<-E<gt>irand()> on the object, and returning the integer so obtained as the
I<coerced> result.

A similar overload coercion is performed when the object is used in a numeric
context:

 my $neg_rand = 0 - $prng;

(See L</"BUGS AND LIMITATIONS"> regarding numeric overloading on 64-bit
integer Perls prior to 5.10.)

In a boolean context, the coercion returns true or false based on whether the
call to C<-E<gt>irand()> returns an odd or even result:

 if ($prng) {
     print("Heads - I win!\n");
 } else {
     print("Tails - You lose.\n");
 }

In an array context, the coercion returns a single integer result:

 my @rands = @{$prng};

This may not be all that useful, so you can call the C<-E<gt>array()> method
directly with a integer argument for the number of random integers you'd like:

 # Get 20 random integers
 my @rands = @{$prng->array(20)};

Finally, a PRNG object can be used to produce a code reference that will
return random integers each time it is invoked:

 my $rand = \&{$prng};
 my $int = &$rand;

See L<Object::InsideOut/"Object Coercion"> for more details.

=head2 Thread Support

Math::Random::MT::Auto provides thread support to the extent documented in
L<Object::InsideOut/"THREAD SUPPORT">.

In a threaded application (i.e., C<use threads;>), the standalone PRNG and
all the PRNG objects from one thread will be copied and made available in a
child thread.

To enable the sharing of PRNG objects between threads, do the following in
your application:

 use threads;
 use threads::shared;

 BEGIN {
     $Math::Random::MT::Auto::shared = 1;
 }
 use Math::Random::MT::Auto ...;

B<NOTE:> Code refs cannot be shared between threads. Therefore, you cannot
use L</"User-defined Seeding Source"> subroutines in conjunction with
L</"srand"> when C<use threads::shared;> is in effect.

Depending on your needs, when using threads, but not enabling thread-sharing
of PRNG objects as per the above, you may want to perform an C<srand>
call on the standalone PRNG and/or your PRNG objects inside the threaded code
so that the pseudorandom number sequences generated in each thread differs.

 use threads;
 use Math::Random:MT::Auto qw(irand srand);

 my $prng = Math::Random:MT::Auto->new();

 sub thr_code
 {
     srand();
     $prng->srand();

     ....
 }

=head1 EXAMPLES

=over

=item Cloning the standalone PRNG to an object

 use Math::Random::MT::Auto qw(get_state);

 my $prng = Math::Random::MT::Auto->new('STATE' => scalar(get_state()));

or using the standalone PRNG object directly:

 my $prng = $Math::Random::MT::Auto::SA_PRNG->clone();

The standalone PRNG and the PRNG object will now return the same sequence
of pseudorandom numbers.

=back

Included in this module's distribution are several sample programs (located
in the F<samples> sub-directory) that illustrate the use of the various
random number deviates and other features supported by this module.

=head1 DIAGNOSTICS

=head2 WARNINGS

Warnings are generated by this module primarily when problems are encountered
while trying to obtain random seed data for the PRNGs.  This may occur after
the module is loaded, after a PRNG object is created, or after calling
L</"srand">.

These seed warnings are not critical in nature.  The PRNG will still be seeded
(at a minimum using data such as L<time()|perlfunc/"time"> and PID
(L<$$|perlvar/"$$">)), and can be used safely.

The following illustrates how such warnings can be trapped for programmatic
handling:

 my @WARNINGS;
 BEGIN {
     $SIG{__WARN__} = sub { push(@WARNINGS, @_); };
 }

 use Math::Random::MT::Auto;

 # Check for standalone PRNG warnings
 if (@WARNINGS) {
     # Handle warnings as desired
     ...
     # Clear warnings
     undef(@WARNINGS);
 }

 my $prng = Math::Random::MT::Auto->new();

 # Check for PRNG object warnings
 if (@WARNINGS) {
     # Handle warnings as desired
     ...
     # Clear warnings
     undef(@WARNINGS);
 }

=over

=item * Failure opening random device '...': ...

The specified device (e.g., /dev/random) could not be opened by the module.
Further diagnostic information should be included with this warning message
(e.g., device does not exist, permission problem, etc.).

=item * Failure setting non-blocking mode on random device '...': ...

The specified device could not be set to I<non-blocking> mode.  Further
diagnostic information should be included with this warning message
(e.g., permission problem, etc.).

=item * Failure reading from random device '...': ...

A problem occurred while trying to read from the specified device.  Further
diagnostic information should be included with this warning message.

=item * Random device '...' exhausted

The specified device did not supply the requested number of random numbers for
the seed.  It could possibly occur if F</dev/random> is used too frequently.
It will occur if the specified device is a file, and it does not have enough
data in it.

=item * Failure creating user-agent: ...

To utilize the option of acquiring seed data from Internet sources, you need
to install the L<LWP::UserAgent> module.

=item * Failure contacting XXX: ...

=item * Failure getting data from XXX: 500 Can't connect to ... (connect: timeout)

You need to have an Internet connection to utilize L</"Internet Sites"> as
random seed sources.

If you connect to the Internet through an HTTP proxy, then you must set the
L<http_proxy|LWP/"http_proxy"> variable in your environment when using the
Internet seed sources.  (See L<LWP::UserAgent/"Proxy attributes">.)

This module sets a 5 second timeout for Internet connections so that if
something goes awry when trying to get seed data from an Internet source,
your application will not hang for an inordinate amount of time.

=item * You have exceeded your 24-hour quota for HotBits.

The L<HotBits|/"Internet Sites"> site has a quota on the amount of data you
can request in a 24-hour period.  (I don't know how big the quota is.)
Therefore, this source may fail to provide any data if used too often.

=item * Failure acquiring Win XP random data: ...

A problem occurred while trying to acquire seed data from the Window XP random
source.  Further diagnostic information should be included with this warning
message.

=item * Unknown seeding source: ...

The specified seeding source is not recognized by this module.

This error also occurs if you try to use the L<win32|/"Windows XP Random Data">
random data source on something other than MSWin32 or Cygwin on Windows XP.

See L</"Seeding Sources"> for more information.

=item * No seed data obtained from sources - Setting minimal seed using PID and time

This message will occur in combination with some other message(s) above.

If the module cannot acquire any seed data from the specified sources, then
data such as L<time()|perlfunc/"time"> and PID (L<$$|perlvar/"$$">) will be
used to seed the PRNG.

=item * Partial seed - only X of Y

This message will occur in combination with some other message(s) above.  It
informs you of how much seed data was acquired vs. how much was needed.

=back

=head2 ERRORS

This module uses C<Exception::Class> for reporting errors.  The base error
class provided by L<Object::InsideOut> is C<OIO>.  Here is an example of the
basic manner for trapping and handling errors:

 my $obj;
 eval { $obj = Math::Random::MT::Auto->new(); };
 if (my $e = OIO->caught()) {
     print(STDERR "Failure creating new PRNG: $e\n");
     exit(1);
 }

Errors specific to this module have a base class of C<MRMA::Args>, and
have the following error messages:

=over

=item * Missing argument to 'set_seed'

L</"set_seed"> must be called with an array ref, or a list of integer seed
data.

=item * Invalid state vector

L</"set_state"> was called with an incompatible state vector.  For example, a
state vector from a 32-bit integer version of Perl being used with a 64-bit
integer version of Perl.

=back

=head1 PERFORMANCE

Under Cygwin, this module is 2.5 times faster than Math::Random::MT, and under
Solaris, it's more than four times faster.  (Math::Random::MT fails to build
under Windows.)  The file F<samples/timings.pl>, included in this module's
distribution, can be used to compare timing results.

If you connect to the Internet via a phone modem, acquiring seed data may take
a second or so.  This delay might be apparent when your application is first
started, or when creating a new PRNG object.  This is especially true if you
specify multiple L</"Internet Sites"> (so as to get the full seed from them)
as this results in multiple accesses to the Internet.  (If F</dev/urandom> is
available on your machine, then you should definitely consider using the
Internet sources only as a secondary source.)

=head1 DEPENDENCIES

=head2 Installation

A 'C' compiler is required for building this module.

This module uses the following 'standard' modules for installation:

=over

=over

=item ExtUtils::MakeMaker

=item File::Spec

=item Test::More

=back

=back

=head2 Operation

Requires Perl 5.6.0 or later.

This module uses the following 'standard' modules:

=over

=over

=item Scalar::Util (1.18 or later)

=item Carp

=item Fcntl

=item XSLoader

=back

=back

This module uses the following modules available through CPAN:

=over

=over

=item Object::InsideOut (2.06 or later)

=item Exception::Class (1.22 or later)

=back

=back

To utilize the option of acquiring seed data from Internet sources, you need
to install the L<LWP::UserAgent> module.

To utilize the option of acquiring seed data from the system's random data
source under MSWin32 or Cygwin on Windows XP, you need to install the
L<Win32::API> module.

=head1 BUGS AND LIMITATIONS

This module does not support multiple inheritance.

For Perl prior to 5.10, there is a bug in the L<overload> code associated with
64-bit integers that causes the integer returned by the C<-E<gt>irand()> call
to be coerced into a floating-point number.  The workaround in this case is to
call C<-E<gt>irand()> directly:

 # my $neg_rand = 0 - $prng;          # Result is a floating-point number
 my $neg_rand = 0 - $prng->irand();   # Result is an integer number

The transfer of state vector arrays and serialized objects between 32- and
64-bit integer versions of Perl is not supported, and will produce an 'Invalid
state vector' error.

Please submit any bugs, problems, suggestions, patches, etc. to:
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Math-Random-MT-Auto>

=head1 SEE ALSO

Math::Random::MT::Auto on MetaCPAN:
L<https://metacpan.org/release/Math-Random-MT-Auto>

Code repository:
L<https://github.com/jdhedden/Math-Random-MT-Auto>

Sample code in the I<examples> directory of this distribution on CPAN.

The Mersenne Twister is the (current) quintessential pseudorandom number
generator. It is fast, and has a period of 2^19937 - 1.  The Mersenne
Twister algorithm was developed by Makoto Matsumoto and Takuji Nishimura.
It is available in 32- and 64-bit integer versions.
L<http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html>

Wikipedia entries on the Mersenne Twister and pseudorandom number generators,
in general:
L<http://en.wikipedia.org/wiki/Mersenne_twister>, and
L<http://en.wikipedia.org/wiki/Pseudorandom_number_generator>

random.org generates random numbers from radio frequency noise.
L<http://random.org/>

HotBits generates random number from a radioactive decay source.
L<http://www.fourmilab.ch/hotbits/>

RandomNumbers.info generates random number from a quantum optical source.
L<http://www.randomnumbers.info/>

OpenBSD random devices:
L<http://www.openbsd.org/cgi-bin/man.cgi?query=arandom&sektion=4&apropos=0&manpath=OpenBSD+Current&arch=>

FreeBSD random devices:
L<http://www.freebsd.org/cgi/man.cgi?query=random&sektion=4&apropos=0&manpath=FreeBSD+5.3-RELEASE+and+Ports>

Man pages for F</dev/random> and F</dev/urandom> on Unix/Linux/Cygwin/Solaris:
L<http://www.die.net/doc/linux/man/man4/random.4.html>

Windows XP random data source:
L<http://blogs.msdn.com/michael_howard/archive/2005/01/14/353379.aspx>

Fisher-Yates Shuffling Algorithm:
L<http://en.wikipedia.org/wiki/Shuffling_playing_cards#Shuffling_algorithms>,
and L<shuffle() in List::Util|List::Util>

Non-uniform random number deviates in I<Numerical Recipes in C>,
Chapters 7.2 and 7.3:
L<http://www.library.cornell.edu/nr/bookcpdf.html>

Inside-out Object Model:
L<Object::InsideOut>

L<Math::Random::MT::Auto::Range> - Subclass of Math::Random::MT::Auto that
creates range-valued PRNGs

L<LWP::UserAgent>

L<Math::Random::MT>

L<Net::Random>

=head1 AUTHOR

Jerry D. Hedden, S<E<lt>jdhedden AT cpan DOT orgE<gt>>

=head1 COPYRIGHT AND LICENSE

A C-Program for MT19937 (32- and 64-bit versions), with initialization
improved 2002/1/26.  Coded by Takuji Nishimura and Makoto Matsumoto,
and including Shawn Cokus's optimizations.

 Copyright (C) 1997 - 2004, Makoto Matsumoto and Takuji Nishimura,
  All rights reserved.
 Copyright (C) 2005, Mutsuo Saito, All rights reserved.
 Copyright 2005 - 2009 Jerry D. Hedden <jdhedden AT cpan DOT org>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

3. The names of its contributors may not be used to endorse or promote
   products derived from this software without specific prior written
   permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 Any feedback is very welcome.
 m-mat AT math DOT sci DOT hiroshima-u DOT ac DOT jp
 http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html

=cut
