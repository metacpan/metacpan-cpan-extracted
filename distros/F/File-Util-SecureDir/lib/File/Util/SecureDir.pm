########################################################################
# housekeeping
########################################################################
package File::Util::SecureDir v0.1.0;
use v5.36;

use Carp        qw( carp croak );
use Config;
use List::Util  qw( first       );

our @CARP_NOT   = ( __PACKAGE__ );

########################################################################
# state: assigned once from the #! code at use-time, never reset.
# $script is captured when this module is first compiled.
########################################################################

my $script  = $0;
my $default = 'other_no_write';
my $filter  = '';
my $handler = '';
my $verbose = 0;
my $debug   = 0;

########################################################################
# Win32 self-relative SD parser.  Returns undef on a malformed buffer.
#
# This is 'our' only so tests can feed it hand-packed buffers on any
# platform:  $File::Util::SecureDir::parse_sd->( $sd ).  It is not part
# of the interface.  The Win32 handler calls $sd_parser, a lexical copy
# taken here at load time, so reassigning the package variable later
# does not change what the filter does.
########################################################################

our $parse_sd
= sub( $sd )
{
    my $len = length $sd;
    $len >= 20 or return;

    my ( $rev, $sbz1, $control, $off_owner, undef, undef, $off_dacl )
    = unpack 'C C v V V V V', $sd;

    my $owner_sid
    = $off_owner
    ? do
      {
          $off_owner + 2 <= $len                          or return;
          my $sub_count = unpack 'C', substr $sd, $off_owner + 1, 1;
          my $sid_len   = 8 + 4 * $sub_count;
          $off_owner + $sid_len <= $len                   or return;
          substr $sd, $off_owner, $sid_len
      }
    : ''
    ;

    my $null_dacl
    = ! ( $control & 0x0004 )
    || ! $off_dacl
    ;

    my @acez
    = $null_dacl
    ? ()
    : do
      {
          $off_dacl + 8 <= $len                           or return;

          my ( undef, undef, undef, $ace_count )
          = unpack 'C C v v', substr $sd, $off_dacl, 8;

          my $off     = $off_dacl + 8;
          my @result  = ();

          for ( 1 .. $ace_count )
          {
              $off + 4 <= $len                            or return;

              my ( $ace_type, $ace_flags, $ace_size )
              = unpack 'C C v', substr $sd, $off, 4;

              $ace_size >= 4                              or return;

              unless( $ace_flags & 0x08 )
              {
                  if( $ace_type == 0 )
                  {
                      $off + 12 <= $len                   or return;

                      my $mask      = unpack 'V', substr $sd, $off + 4, 4;
                      my $sub_count = unpack 'C', substr $sd, $off + 9, 1;
                      my $sid_len   = 8 + 4 * $sub_count;

                      $off + 8 + $sid_len <= $len         or return;

                      push @result,
                      [
                          $ace_type
                        , $mask
                        , substr $sd, $off + 8, $sid_len
                      ];
                  }
              }

              $off += $ace_size;
          }

          @result
      }
    ;

    {
        owner     => $owner_sid
      , acez      => \@acez
      , null_dacl => $null_dacl
    }
};

my $sd_parser = $parse_sd;

########################################################################
# Win32 identity of the running process: the user SID in the process
# token.
#
# Why the token: the access token is what the kernel evaluates every
# DACL against, so comparing a directory's owner with the token's SID
# asks the question the OS itself will answer when the directory is
# used.  It is the Win32 counterpart of the effective uid ($>) on Unix:
# the identity the process is actually running as, which differs from
# the login identity under RunAs, services, and elevation.  Nothing
# here is derived from names or from the environment, so an attacker
# who controls %ENV (USERDOMAIN, USERNAME) or who creates a look-alike
# account cannot change which SID counts as "me".  Handles are
# pointer-wide, which is why the prototypes switch to 'Q' on 64-bit
# perls.
#
# If the token cannot be read on some target (a perl without 64-bit
# integers cannot pass 'Q', or OpenProcessToken is refused in a sandbox)
# $choose_sid below falls back, with a warning, to resolving the login
# name.  That does not use %ENV either, but a bare name is ambiguous when
# a local and a domain account share it, and it reports the login
# identity rather than the token's.  So the token is always tried first
# and the fallback is used only when the token fails or yields a
# malformed SID, never to second-guess a token that works.  It is never
# silent: the identity source is part of the security decision.
#
# 'our' only so tests can call these step by step, e.g.
# $File::Util::SecureDir::process_sid->(); they are not part of the
# interface.  Handlers use the lexical copies taken at load time.
########################################################################

our $process_sid
= sub
{
    require Win32::API;

    my $wide        = $Config{ ptrsize } == 8;
    my $handle      = $wide ? 'Q' : 'N';
    my $handle_fmt  = $wide ? 'Q' : 'V';
    my $TOKEN_QUERY = 0x0008;
    my $TOKEN_USER  = 1;

    my $GetCurrentProcess
    = Win32::API->new( 'kernel32', 'GetCurrentProcess', '', $handle )
    or die "Cannot import GetCurrentProcess: $^E";

    my $OpenProcessToken
    = Win32::API->new( 'advapi32', 'OpenProcessToken', "${handle}NP", 'N' )
    or die "Cannot import OpenProcessToken: $^E";

    my $GetTokenInformation
    = Win32::API->new( 'advapi32', 'GetTokenInformation', "${handle}NPNP", 'N' )
    or die "Cannot import GetTokenInformation: $^E";

    my $CloseHandle
    = Win32::API->new( 'kernel32', 'CloseHandle', $handle, 'N' )
    or die "Cannot import CloseHandle: $^E";

    my $token_buf = pack $handle_fmt, 0;

    $OpenProcessToken->Call( $GetCurrentProcess->Call(), $TOKEN_QUERY, $token_buf )
    or die "OpenProcessToken: $^E";

    my $token  = unpack $handle_fmt, $token_buf;
    my $needed = pack 'V', 0;
    my $buf    = "\0";

    # the first call only reports the size needed.

    $GetTokenInformation->Call( $token, $TOKEN_USER, $buf, 0, $needed );

    my $size = unpack 'V', $needed;

    $size
    or do
    {
        $CloseHandle->Call( $token );
        die "GetTokenInformation size: $^E";
    };

    $buf = "\0" x $size;

    my $ok = $GetTokenInformation->Call( $token, $TOKEN_USER, $buf, $size, $needed );

    $ok
    or do
    {
        $CloseHandle->Call( $token );
        die "GetTokenInformation: $^E";
    };

    $CloseHandle->Call( $token );

    # TOKEN_USER starts with a pointer to the SID, which lives inside
    # the same buffer; turn the pointer into an offset and bounds check
    # it before copying the SID out.

    my $sid_ptr = unpack $handle_fmt, $buf;
    my $buf_ptr = unpack $handle_fmt, pack 'P', $buf;
    my $offset  = $sid_ptr - $buf_ptr;

    $offset > 0 && $offset + 8 <= $size
    or die "Token SID lies outside the token buffer";

    my $sub_count = unpack 'C', substr $buf, $offset + 1, 1;
    my $sid_len   = 8 + 4 * $sub_count;

    $offset + $sid_len <= $size
    or die "Token SID is truncated";

    substr $buf, $offset, $sid_len
};

# Fallback: the SID of the login name, from the OS and not the environment.

our $login_sid
= sub
{
    require Win32;

    my ( $sid, $domain, $type ) = ( '', '', '' );

    Win32::LookupAccountName( '', Win32::LoginName(), $sid, $domain, $type )
    or die "LookupAccountName: $^E";

    $sid
};

# A SID is: revision 1, a sub-authority count, then 8 + 4 * count bytes.

my $sid_ok
= sub( $sid )
{
    defined $sid
    && length( $sid ) >= 8
    or return 0;

    my ( $rev, $count ) = unpack 'C C', $sid;

    $rev == 1 && length( $sid ) == 8 + 4 * $count
};

# First getter that returns a well formed SID wins.  A getter that dies
# or returns junk is skipped, and if a later one is used the failures
# are reported.  If none works the filter cannot know who "me" is, so
# it dies rather than guess.

our $choose_sid
= sub( @getterz )
{
    my @failz = ();

    for my $getter ( @getterz )
    {
        my $sid = eval { $getter->() };

        $sid_ok->( $sid )
        or do
        {
            push @failz, $@ || 'returned a malformed SID';
            next
        };

        @failz
        and carp 'Process identity: preferred source failed ('
        . join( '; ' => map { s/\s+\z//r } @failz )
        . '), using the fallback';

        return $sid
    }

    die 'No usable process identity: '
    . join( '; ' => map { s/\s+\z//r } @failz )
    . "\n"
};

my $sid_chooser     = $choose_sid;
my $token_getter    = $process_sid;
my $login_getter    = $login_sid;

########################################################################
# handler builders.  Only the selected filter is ever built, so a Win32
# setup failure dies in the #! code's 'use', before anything is filtered.
#
# $level: 1 = other_no_write, 2 = group_no_write, 3 = same_owner.
# Each handler reads its metadata once per directory, so the checks
# for all levels come from the same snapshot.
########################################################################

my $make_unix_handler
= sub( $level )
{
    my $mask = $level > 1 ? 0022 : 0002;

    sub( $path )
    {
        my @st = stat $path
        or do
        {
            carp "Failed reading directory '$path': $!";
            return 0
        };

        $st[2] & $mask      and return 0;
        $level < 3          and return 1;

        # The effective uid ($>) defines who the process is running as:
        # under sudo or a setuid program the real uid ($<) is the invoker,
        # whose directories are exactly the ones not to trust.  Read it
        # on every call since it can change (seteuid) after load.  Root
        # is accepted along with the process owner; VMS equivalence of
        # uid 0 is unverified.

        my $owner = $st[4];

        $owner == $> || $owner == 0
    }
};

my $make_win32_handler
= sub( $level )
{
    require Win32;
    require Win32::API;

    my $build_sid
    = sub( $str )
    {
        my ( undef, $rev, $auth, @sub ) = split /-/, $str;
        pack 'C C x4 n V*', $rev, scalar @sub, $auth, @sub
    };

    my @other_sids
    = map
    {
        $_->$build_sid
    }
    qw( S-1-1-0 S-1-5-11 S-1-5-32-545 );

    my @root_sids
    = map
    {
        $_->$build_sid
    }
    qw( S-1-5-18 S-1-5-32-544 );

    my $curr_sid = $sid_chooser->( $token_getter, $login_getter );

    my $write_mask
    =   0x0002
    |   0x0004
    |   0x0010
    |   0x0040
    |   0x0100
    |   0x00010000
    |   0x00040000
    |   0x00080000
    |   0x10000000
    |   0x40000000
    ;

    my $GetFileSecurity
    = Win32::API->new( 'advapi32', 'GetFileSecurityA', 'PNPNP', 'N' )
    or die "Cannot import GetFileSecurityA: $^E";

    my $fetch_sd
    = sub( $path )
    {
        my $needed = pack 'V', 0;
        my $size   = 512;
        my $buf    = "\0" x $size;

        if( $GetFileSecurity->Call( $path, 0x5, $buf, $size, $needed ) )
        {
            return substr $buf, 0, unpack 'V', $needed;
        }

        Win32::GetLastError() == 122
        or do
        {
            carp "GetFileSecurityA '$path': $^E";
            return
        };

        $size = unpack 'V', $needed;
        $buf  = "\0" x $size;

        $GetFileSecurity->Call( $path, 0x5, $buf, $size, $needed )
        or do
        {
            carp "GetFileSecurityA '$path': $^E";
            return
        };

        substr $buf, 0, unpack 'V', $needed
    };

    sub( $path )
    {
        my $sd   = $path->$fetch_sd     or return 0;
        my $info = $sd->$sd_parser
        or do
        {
            carp "Malformed security descriptor for directory '$path'";
            return 0
        };

        $info->{ null_dacl }                and return 0;

        my $owner = $info->{ owner } // '';

        for my $ace ( $info->{ acez }->@* )
        {
            my ( undef, $mask, $sid ) = @$ace;

            $mask & $write_mask             or next;

            grep { $_ eq $sid } @other_sids and return 0;

            $level > 1                      or next;

            $sid ne $owner
            && ! grep { $_ eq $sid } @root_sids
            and return 0;
        }

        $level > 2                          or return 1;
        $owner ne ''                        or return 0;

        !! grep { $_ eq $owner } ( $curr_sid, @root_sids )
    }
};

my $make_handler
= $^O eq 'MSWin32'
? $make_win32_handler
: $make_unix_handler
;

########################################################################
# named filters, least to most restrictive.  Names resolve only here.
########################################################################

my @filterz
= (
    [ all            => sub { sub { 1 } }               ]
  , [ other_no_write => sub { $make_handler->( 1 ) }    ]
  , [ group_no_write => sub { $make_handler->( 2 ) }    ]
  , [ same_owner     => sub { $make_handler->( 3 ) }    ]
);

########################################################################
# private utilities
########################################################################

# 'filter', 'filter=NAME', 'verbose[=0|1]', 'debug[=0|1]'.
# 'filter' alone makes the default explicit.

my $extract_argz
= sub( @argz )
{
    my %argz = ();

    for my $arg ( @argz )
    {
        $arg =~ m
        {
            \A
            (?<key> filter | verbose | debug )
            (?: = (?<val> .* ) )?
            \z
        }xs
        or croak
        "Botched import: unknown '$arg'"
        . ' (use filter[=NAME], verbose[=0|1], debug[=0|1])';

        $argz{ $+{ key } } = $+{ val } // ( $+{ key } eq 'filter' ? '' : 1 );
    }

    \%argz
};

my $set_filter
= sub( $name = '' )
{
    state $valid = join ' ' => map { $_->[0] } @filterz;

    $filter
    and croak
    "Bogus filter: already '$filter'"
    . ' (set earlier, or latched as the default by a module that filtered)'
    . '; "use File::Util::SecureDir qw( filter=NAME )" must come first';

    length $name
    or $name = $default;

    my $entry
    = first { $name eq $_->[0] } @filterz
    or croak "Botched filter: unknown '$name' (valid: $valid)";

    # build first: a failed setup leaves nothing assigned.

    my $code = $entry->[1]->();

    ( $filter, $handler ) = ( $name, $code );

    say STDERR "File::Util::SecureDir: $filter"
    if $verbose;

    return
};

########################################################################
# interface
########################################################################

sub new
{
    __PACKAGE__
}

# read-only: the name of the filter, '' if none is set yet.

sub filter( $pkg, @extra )
{
    @extra
    and croak 'Botched filter: read-only, set via "use ... filter=NAME"';

    $filter
}

sub verbose( $pkg, @argz )
{
    @argz
    ? $verbose = !! $argz[0]
    : $verbose
}

sub debug( $pkg, @argz )
{
    @argz
    ? $debug = !! $argz[0]
    : $debug
}

sub filter_dirs( $pkg, @dirz )
{
    # first use latches the default when the #! code did not choose.

    $handler
    or $set_filter->();

    if( $debug )
    {
        no warnings 'once';

        $DB::single = 1;
    }

    $verbose || $debug
    or return grep { $_->$handler } @dirz;

    grep
    {
        my $ok = $_->$handler;

        my $verdict = $ok ? 'accept' : 'reject';

        say STDERR "File::Util::SecureDir: $filter: $verdict '$_'"
        if $debug || ! $ok;

        $ok
    }
    @dirz
}

sub import( $pkg, @argz )
{
    my $argz = $extract_argz->( @argz );

    exists $argz->{ verbose }   and $verbose = !! $argz->{ verbose };
    exists $argz->{ debug   }   and $debug   = !! $argz->{ debug   };

    if( exists $argz->{ filter } )
    {
        my $file = ( caller )[1];

        $file eq $script
        or croak "Botched filter: can only be set from '$script', not '$file'";

        $argz->{ filter }->$set_filter;
    }

    return
}

1
__END__

=head1 NAME

File::Util::SecureDir - process-wide, set-once directory security filter.

=head1 SYNOPSIS

  # In any module with directories to check; no arguments.

  use File::Util::SecureDir;

  state $secure = File::Util::SecureDir->new;  # the singleton.
  my    @clean  = $secure->filter_dirs( @candidates );

  say 'filtering with ' . $secure->filter;     # name only, read-only.

  # In the #! code, only to pick something other than the default;
  # it must come before any module that filters directories.

  #!/usr/bin/env perl
  use v5.36;

  use File::Util::SecureDir qw( filter=same_owner );

  # In any module, any time; verbose and debug can be reset.

  use File::Util::SecureDir qw( verbose );

=head1 DESCRIPTION

The #! code defines the security context.  It may select one of the
named filters with C<use File::Util::SecureDir qw( filter=NAME )>; the
file making the request is checked against C<$0>, so any other caller
supplying C<filter> croaks.  If the #! code says nothing, the first call
to C<filter_dirs> installs the default.  Either way the filter is
assigned once and cannot be changed or replaced afterwards, so a
C<filter=NAME> that arrives after another module has already filtered
croaks rather than being silently ignored.

Filters, least to most restrictive:

  all             accept everything (testing only).
  other_no_write  reject world-writable directories (default).
  group_no_write  also reject group-writable directories.
  same_owner      also require the owner to be the effective user
                  of the process (or root / Administrators).

C<filter> or C<filter=> with no name selects the default explicitly.

C<verbose[=0|1]> reports the selected filter and every rejected
directory on STDERR; C<debug[=0|1]> reports every decision.  Either can
be given by any module, any time, and be reset.

=head1 EXAMPLE

A module that builds a search path from directories it did not choose,
such as L<FindBin::libs>, uses the filter with no arguments, so a script
that only loads that module gets the default level without knowing this
module exists:

  package FindBin::libs;

  use File::Util::SecureDir;      # no arguments: nothing is selected here.

  sub import
  {
      my    @libz   = ...;        # candidate directories.
      state $secure = File::Util::SecureDir->new;

      # the first call installs the default if the #! code chose none.

      if( my @clean = $secure->filter_dirs( @libz ) )
      {
          # use @clean for @INC, PERL5LIB, LD_LIBRARY_PATH...
      }
  }

A script that wants a different level, including C<all>, says so first:

  #!/usr/bin/env perl
  use v5.36;

  use File::Util::SecureDir qw( filter=all );
  use FindBin::libs;

If it puts the line after C<use FindBin::libs>, the default has already
been installed and the C<filter=all> croaks instead of being ignored.

=head1 METHODS

=over 4

=item new

Returns the singleton (the package name).

=item filter

Name of the filter in effect ('' if unset).  Read-only.

=item filter_dirs( @dirs )

Returns the directories that pass, in order.  Unreadable directories
fail.

=item verbose, debug

Get or set the flag.

=back

=head1 LIMITS

Code in the same interpreter can always redefine subroutines; the
guarantee is that the API cannot weaken the filter.  The check that
C<filter=> comes from the #! code compares the caller's file name to
C<$0>: C<perl -M> and C<PERL5OPT> pass it (they report the script, line
0) and a C<# line> directive in a module can spoof it.  Whoever controls
the command line or environment already controls the process.  Only the directory
itself is checked: not its parents, and symlinks are followed.  A
directory can change between the check and its use.

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 LICENSE

Same terms as Perl v5.36 or any later version of Perl.
