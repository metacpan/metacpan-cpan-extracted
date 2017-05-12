package Log::Scrubber;

# See the bottom of this file for the POD documentation.
# Search for the string '=head'.

require 5.8.8;
use strict;
use warnings;
use Carp;
use Clone;
no warnings "redefine"; # We make this a few times
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $SCRUBBER);

@ISA = qw(Exporter);
%EXPORT_TAGS = (
    Carp    => [ qw(scrubber_init) ],
    Syslog  => [ qw(scrubber_init) ],
    all     => [ qw($SCRUBBER scrubber_init scrubber scrubber_enabled
                scrubber_add_scrubber scrubber_remove_scrubber
                scrubber_add_signal scrubber_remove_signal
                scrubber_add_method scrubber_remove_method
                scrubber_add_package scrubber_remove_package
                ) ],
    );

push @{$EXPORT_TAGS{all}}, @{$EXPORT_TAGS{$_}}
for grep { $_ ne 'all' } keys %EXPORT_TAGS;

@EXPORT_OK = @{$EXPORT_TAGS{all}};
@EXPORT = qw(scrubber_init);

$VERSION = '0.15';

###----------------------------------------------------------------###

my $_SDATA = { # will be initialized in import below
    'enabled' => 0,
    'SIG' => {},
    'METHOD' => {},
    };

tie $SCRUBBER, __PACKAGE__;

sub TIESCALAR {
    return bless [], __PACKAGE__;
}

sub FETCH {
    my ($self) = @_;
    $_SDATA;
}

sub STORE {
    my ($self, $val) = @_;
    #print ">>>>Calling STORE with (".(defined($val) ? $val : 'undef').")\n";
    if (! defined $val) {
        $_SDATA = _sdata_copy();
    } elsif (ref($val) eq 'HASH') {
        scrubber_stop();
        $_SDATA = $val;
        scrubber_start() if $_SDATA->{'enabled'};
    } elsif ($val) {
        scrubber_start();
    } else {
        scrubber_stop();
    }
}

###----------------------------------------------------------------###

sub _sdata_copy { # make a non-reference copy
    my ($old_sdata) = @_;
    if ( ! defined $old_sdata ) { $old_sdata = $_SDATA; } # if they didn't specify one, use the current one
    my $new_SDATA = Clone::clone($old_sdata);
    $new_SDATA->{'parent'} = $old_sdata;
    return $new_SDATA;
}

###----------------------------------------------------------------###

sub import {
    my $change;
    for my $i (reverse 1 .. $#_) {
        if ($_[$i] eq ':Carp') {
            scrubber_add_method('croak');
            scrubber_add_method('confess');
            scrubber_add_method('carp');
            scrubber_add_method('cluck');
        } elsif ($_[$i] eq ':Syslog') {
            scrubber_add_method('main::syslog');
        } elsif ($_[$i] =~ /^\+/) {
            scrubber_add_method(substr($_[$i],1,999));
            splice @_, $i, 1, ();
        } elsif ($_[$i] =~ /^(dis|en)able$/) {
            my $val = $1 eq 'dis' ? 0 : 1;
            splice @_, $i, 1, ();
            die 'Cannot both enable and disable $SCRUBBER during import' if defined $change && $change != $val;
            $change = $val;
        }
    }

    scrubber_add_signal('WARN');
    scrubber_add_signal('DIE');
    scrubber_add_method('warnings::warn');
    scrubber_add_method('warnings::warnif');
    if ((! defined $change) || $change) {
        scrubber_start();
    } else {
        scrubber_stop();
    }

    __PACKAGE__->export_to_level(1, @_);
}

###----------------------------------------------------------------###

sub scrubber_enabled { $_SDATA->{'enabled'} ? 1 : 0 }

sub scrubber_start {
    $_SDATA->{'enabled'} = 1;
    _scrubber_enable_signal( keys %{$_SDATA->{'SIG'}} );
    _scrubber_enable_method( keys %{$_SDATA->{'METHOD'}} );
}

sub scrubber_stop  {
    $_SDATA->{'enabled'} = 0;
    _scrubber_disable_signal( keys %{$_SDATA->{'SIG'}} );
    _scrubber_disable_method( keys %{$_SDATA->{'METHOD'}} );
}

###----------------------------------------------------------------###
# This is the core of our protection. Replace
# the data by the value provided

sub _scrubber {
    my $msg = $_[0];

    my @stack = ($msg);
    my @stack_done = ();
    my @data = ();
    my @hashes = ();

    while ( my $sub_msg = pop @stack ) {
        push @stack_done, "$sub_msg";
        if ( ref $sub_msg eq 'ARRAY' ) {
            foreach my $v ( @{$sub_msg} ) {
                if (ref $v) {
                    my $found = 0;
                    foreach (@stack_done) { if ("$v" eq $_) { $found = 1; last; } }
                    push @stack, $v unless $found;
                } else {
                    push @data, \$v;
                }
            }
        } elsif ( ref $sub_msg eq 'HASH' ) {
            push @hashes, $sub_msg;
            foreach my $k ( keys %{$sub_msg} ) {
                if (ref $sub_msg->{$k}) {
                    my $found = 0;
                    foreach (@stack_done) { if ("$sub_msg->{$k}" eq $_) { $found = 1; last; } }
                    push @stack, $sub_msg->{$k} unless $found;
                } else {
                    push @data, \$sub_msg->{$k};
                }
            }
        } elsif (ref $sub_msg) {
            # TODO: currently only ARRAY, HASH and SCALAR are supported
        } else {
            push @data, \$msg;
        }
    }

    foreach my $sub_msg ( @data ) {
        next if ! defined $$sub_msg;
        foreach ( keys %{$_SDATA->{'scrub_data'}}) {
            ref $_SDATA->{'scrub_data'}{$_} eq 'CODE' ? $$sub_msg = $_SDATA->{'scrub_data'}{$_}->($_,$$sub_msg) : $$sub_msg =~ s/$_/$_SDATA->{'scrub_data'}{$_}/g;
        }
    }

    foreach my $hash ( @hashes ) {
        foreach my $k ( keys %$hash ) {
            my $tmp_val = $hash->{$k};
            my $tmp_key = $k;
            foreach ( keys %{$_SDATA->{'scrub_data'}}) {
                ref $_SDATA->{'scrub_data'}{$_} eq 'CODE' ? $tmp_key = $_SDATA->{'scrub_data'}{$_}->($_,$tmp_key) : $tmp_key =~ s/$_/$_SDATA->{'scrub_data'}{$_}/g;
            }
            delete $hash->{$k};
            $hash->{$tmp_key} = $tmp_val;
        }
    }

    return $msg;
}

sub scrubber {
    my $copy = Clone::clone(\@_);
    if ($#$copy == 0) { return _scrubber $$copy[0]; }
    return map { _scrubber $_ } @$copy;
}

###----------------------------------------------------------------###
# Add/Remove text values that will be scrubbed

sub scrubber_remove_scrubber {
    my $x = $_[0];
    if (defined $x) {
        foreach ( keys %$x ) {
            delete $_SDATA->{'scrub_data'}{$_} if $_SDATA->{'scrub_data'}{$_} = $x->{$_};
        }
    }
}

sub scrubber_add_scrubber {
    my $x = $_[0];
    if (defined $x) {
        foreach ( keys %$x ) {
            next if ! defined $_ || $_ eq ''; # scrubbing nothing is VERY bad, ignore empty scrubbers
            $_SDATA->{'scrub_data'}{$_} = $x->{$_};
        }
    }
}

###----------------------------------------------------------------###
# Add/Remove signals (ie DIE and WARN) to the scrubber

sub _scrubber_disable_signal {
    foreach ( @_ ) {
        if (defined $_SDATA->{'SIG'}{$_}{'scrubber'} && defined $SIG{$_} && $SIG{$_} eq $_SDATA->{'SIG'}{$_}{'scrubber'}) {
            $SIG{$_} = $_SDATA->{'SIG'}{$_}{'old'};
            $_SDATA->{'SIG'}{$_}{'old'} = undef;
            $_SDATA->{'SIG'}{$_}{'scrubber'} = undef;
        } elsif ( defined $_SDATA->{'SIG'}{$_}{'old'} ) {
            carp 'Log::Scrubber cannot disable the '.$_.' signal, it has been overridden somewhere else';
        }
    }
}

sub scrubber_remove_signal {
    foreach ( @_ ) {
        _scrubber_disable_signal($_);
        delete $_SDATA->{'SIG'}{$_};
    }
}

sub _scrubber_enable_signal {
    return if ! $_SDATA->{'enabled'};
    foreach ( @_ ) {
    my $sig_name = $_;
        next if defined $SIG{$sig_name} && defined $_SDATA->{'SIG'}{$sig_name}{'scrubber'} && $SIG{$sig_name} eq $_SDATA->{'SIG'}{$sig_name}{'scrubber'};

        $_SDATA->{'SIG'}{$sig_name}{'old'} = $SIG{$sig_name};

        if ($sig_name eq '__WARN__') {
            $_SDATA->{'SIG'}{$sig_name}{'scrubber'} = sub {
                            @_ = scrubber @_;
                            defined $_SDATA->{'SIG'}{$sig_name}{'old'} && $_SDATA->{'SIG'}{$sig_name}{'old'} ne '' ? $_SDATA->{'SIG'}{$sig_name}{'old'}->(@_) : CORE::warn(@_);
                        };
        }
        if ($sig_name eq '__DIE__') {
            $_SDATA->{'SIG'}{$sig_name}{'scrubber'} = sub {
                            @_ = scrubber @_;
                            defined $_SDATA->{'SIG'}{$sig_name}{'old'} && $_SDATA->{'SIG'}{$sig_name}{'old'} ne '' ? $_SDATA->{'SIG'}{$sig_name}{'old'}->(@_) : CORE::die(@_);
                        };
        }

        $SIG{$sig_name} = $_SDATA->{'SIG'}{$sig_name}{'scrubber'};
    }
}

sub scrubber_add_signal {
    foreach ( @_ ) {
    my $sig_name = '';
        if ($_ eq 'WARN') { $sig_name = '__WARN__'; }
        if ($_ eq '__WARN__') { $sig_name = '__WARN__'; }
        if ($_ eq 'DIE') { $sig_name = '__DIE__'; }
        if ($_ eq '__DIE__') { $sig_name = '__DIE__'; }

        next if defined $_SDATA->{'SIG'}{$sig_name};
        $_SDATA->{'SIG'}{$sig_name} = {};
        _scrubber_enable_signal($sig_name);
    }
}

###----------------------------------------------------------------###
# Add/Remove methods to the scrubber

sub _scrubber_disable_method {
    no strict 'refs'; ## no critic
    foreach my $fullname ( @_ ) {
        my $current_method = \&$fullname;
        if (defined $_SDATA->{'METHOD'}{$fullname}{'scrubber'} && defined $current_method && $current_method eq $_SDATA->{'METHOD'}{$fullname}{'scrubber'}) {
            *$fullname = $_SDATA->{'METHOD'}{$fullname}{'old'};
            $_SDATA->{'METHOD'}{$fullname}{'old'} = undef;
            $_SDATA->{'METHOD'}{$fullname}{'scrubber'} = undef;
        } elsif ( defined $_SDATA->{'METHOD'}{$fullname}{'old'} ) {
            carp 'Log::Scrubber cannot disable the '.$fullname.' method, it has been overridden somewhere else';
        }
    }
}

sub scrubber_remove_method {
    foreach my $fullname ( @_ ) {
        _scrubber_disable_method($fullname);
        delete $_SDATA->{'METHOD'}{$fullname};
    }
}

sub _scrubber_enable_method {
    return if ! $_SDATA->{'enabled'};
    no strict 'refs'; ## no critic
    foreach my $fullname ( @_ ) {
        my $r_orig = \&$fullname;

    if ($fullname eq 'warnings::warnif') { $r_orig = \&warnings::warn; }

        if (! defined $r_orig) { croak "Log::Scrubber Cannot scrub $fullname, method does not exist."; }
        $_SDATA->{'METHOD'}{$fullname}{'old'} = $r_orig;
        $_SDATA->{'METHOD'}{$fullname}{'scrubber'} = sub { @_ = scrubber @_; goto $r_orig };
        *$fullname = $_SDATA->{'METHOD'}{$fullname}{'scrubber'};
    }
}

sub scrubber_add_method {
    foreach my $fullname ( @_ ) {
        next if defined $_SDATA->{'METHOD'}{$fullname};
        $_SDATA->{'METHOD'}{$fullname} = {};
        _scrubber_enable_method($fullname);
    }
}

###----------------------------------------------------------------###
# Add/Remove entire packages

sub scrubber_remove_package {
    no strict 'refs'; ## no critic
    foreach my $package ( @_ ) {
        my @methods = grep { defined &{$package.'::'.$_} } keys %{$package.'::'};
        foreach ( @methods ) {
            scrubber_remove_method($_);
        }
    }
}

sub scrubber_add_package {
    no strict 'refs'; ## no critic
    foreach my $package ( @_ ) {
        my @methods = grep { defined &{$package.'::'.$_} } keys %{$package.'::'};
        foreach ( @methods ) {
            scrubber_add_method($package.'::'.$_);
        }
    }
}

###----------------------------------------------------------------###
# Initilize the scrubber.

sub scrubber_init {
    my $x = $_[0];
    scrubber_stop;
    if (defined $x) {
        $_SDATA = _sdata_copy($_SDATA->{'parent'});
        scrubber_add_scrubber(@_);
    }
    scrubber_start();
    return 1;
}

1;

__END__

=head1 NAME

Log::Scrubber - Perl extension to avoid logging sensitive data

=head1 SYNOPSIS

  use Log::Scrubber;             # Override warn() and die() and import scrubber_init()
  use Log::Scrubber qw(:all);    # Override everything this module knows
  use Log::Scrubber qw(:Carp);   # Only override Carp methods
  use Log::Scrubber qw(:Syslog); # Only override syslog()
  use Log::Scrubber qw(scrubber);# scrubber() for use on your own
  use Log::Scrubber qw(+Custom::Method);# Override any perl method

  use Log::Scrubber qw($SCRUBBER :Carp +My::Logs); # Or combine a few

  Example:

    use Log::Scrubber;
    scrubber_init( { '4007000000027' => 'DELETED' } );
    warn "The card number is 4007000000027.\n";

  Output:

    The card number is DELETED.

=head1 DESCRIPTION

As required by the PCI Security Standards Council, some data is not
acceptable to send to log files.  Most notably CVV data.  However it
is simply a matter of time before a developer accidentally (or on purpose)
logs sensitive data to the error_log, or some other inappropriate location.

This module is a solution for this vulnerability.  It allows you to create
a single location for redaction.  What it does is very simple: It replaces
occurrences of the your sensitive data in the output of any common logging
mechanism such as C<use warnings>, C<warn>, C<use Carp> and C<die> with an
acceptable alternative provided by you.

It does so by overriding the functions with a safer alternative so
that no code needs to be changed.

Note that in order for this protection to be effective, this module
must be C<use>d as the last module (ie, after all the modules it can
override) in order for proper method replacement to occur.

The protection can also be invoked by the C<scrubber> method, which
takes a list of arguments and returns the same list, with all data
safely replaced. This method is provided so that you can call it by yourself.

Typically, you will want to issue an C<use Log::Scrubber qw(:all)> after
the last module is C<use>d in your code, to automatically benefit from
the most common level of protection.

Note: If you are using $SIG{__WARN__} and $SIG{__DIE__} then you
must call scrubber_init() or set $SCRUBBER=1 afterward to maintain
full protection.

=head2 METHODS

Additional methods created by this package.

=over

=item scrubber_init

    Both adds scrubbers to your list, and enables Log::Scrubber

    scrubber_init( { # Initialize the scrubber.
      $ereg1 => $replacementText,
      $ereg2 => $rep2,
      $key1  => sub { my ($key,$val) = @_; $val++; return $val; },
      $key2  => sub { my ($key,$val) = @_; $val =~ s/1/2/; return $val; },
      } )

=item scrubber_start

    Enables scrubbing by overriding all configured methods/signals.

    scrubber_start();
    # or
    $SCRUBBER = 1;

=item scrubber_stop

    Disables scrubbing by removing the method/signal overrides.  When disabled your scripts should function exactly as if Log::Scrubber was never installed.

    scrubber_stop();
    # or
    $SCRUBBER = 0;

=item scrubber_add_scrubber

    Add a new regular expression, or coderef scrubber.  This follows the same format as init_scrubber()

    scrubber_add_scrubber({$ereg=>$replaceTxt});

=item scrubber_remove_scrubber

    Remove a previously added scrubber.

    scrubber_remove_scrubber({$ereg=>$replaceTxt});

=item scrubber

    Allows manual use of the scrubber

    @clean = scrubber( @dirty );
    $clean = scrubber $clean;

=item scrubber_enabled

    if (scrubber_enabled()) { print "Yes it is\n"; }
    # or
    if ($SCRUBBER) { print "Yes it is\n"; }

=item scrubber_add_signal

=item scrubber_remove_signal

    scrubber_add_signal('__WARN__');

=item scrubber_add_method

=item scrubber_remove_method

    scrubber_add_method('Carp::croak');

=item scrubber_add_package

=item scrubber_remove_package

    # Use with caution, it overrides EVERYTHING in the package.  It's usually better to override methods with scrubber_add_method.

    scrubber_add_package('Carp');

=back

=head2 LOCAL SCOPING

The scrubber can be locally modified.

  use Log::Scrubber qw($SCRUBBER);
  # setup the scrubber
  {
    local $SCRUBBER;
    # modify scrubber as needed
  }
  # scrubber is now restored back to what it was

=head2 EXPORT

Many. The methods are exported or overridden according to this

  $SIG{__WARN__}     - Always overridden
  $SIG{__DIE__}      - Always overridden
  warnings::warn()   - Always overridden
  warnings::warnif() - Always overridden

  Carp::croak()      - Only exported with :Carp or :all
  Carp::carp()       - Only exported with :Carp or :all
  Carp::confess()    - Only exported with :Carp or :all
  Carp::cluck()      - Only exported with :Carp or :all

  main::syslog()     - Only exported with :Syslog or :all

  Custom::method()   - Custom methods can also be overridden.

=head1 AUTHOR

Jason Terry <oaxlin@cpan.org>

=head1 SEE ALSO

perl(1), Carp(3), warnings(3), Sys::Syslog(3), Unix::Syslog(3)

=cut
