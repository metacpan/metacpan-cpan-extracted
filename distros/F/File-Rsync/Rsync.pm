# -*- perl -*-
# vim:ft=perl foldlevel=1
#      __
#     /\ \ From the mind of
#    /  \ \
#   / /\ \ \_____ Lee Eakin  ( Leakin at dfw dot Nostrum dot com )
#  /  \ \ \______\       or  ( Leakin at cpan dot org )
# / /\ \ \/____  /       or  ( Leakin at japh dot net )
# \ \ \ \____\/ /        or  ( Lee at Eakin dot Org )
#  \ \ \/____  /  Wrapper module for the rsync program
#   \ \____\/ /   rsync can be found at http://rsync.samba.org/rsync/
#    \/______/

package File::Rsync;
require 5.008;    # it might work with older versions of 5 but not tested

use FileHandle;
use IPC::Run3 'run3';
use Carp 'carp';
use Scalar::Util qw(blessed);
use Data::Dumper;

use strict;
use vars qw($VERSION);

$VERSION = '0.49';

=head1 NAME

File::Rsync - perl module interface to rsync(1) F<http://rsync.samba.org/rsync/>

=head1 SYNOPSIS

    use File::Rsync;

    $obj = File::Rsync->new(
        archive      => 1,
        compress     => 1,
        rsh          => '/usr/local/bin/ssh',
        'rsync-path' => '/usr/local/bin/rsync'
    );

    $obj->exec( src => 'localdir', dest => 'rhost:remotedir' )
        or warn "rsync failed\n";

=head1 DESCRIPTION

Perl Convenience wrapper for the rsync(1) program.  Written for I<rsync-2.3.2>
and updated for I<rsync-3.1.1> but should perform properly with most recent
versions.

=head2 File::Rsync::new

    $obj = new File::Rsync;

        or

    $obj = File::Rsync->new;

        or

    $obj = File::Rsync->new(@options);

Create a I<File::Rsync> object.
Any options passed at creation are stored in the object as defaults for all
future I<exec> calls on that object.
Options may be passed in the style of a hash (key/value pairs) and are the
same as the long options in I<rsync(1)> without the leading double-hyphen.
Any leading single or double-hyphens are removed, and you may use underscore
in place of hyphens in option names to simplify quoting and avoid possible
equation parsing (subtraction).

Although options are key/value pairs, as of version 0.46 the order is now
preserved.  Passing a hash reference is still supported for backwards
compatibility, but is deprecated as order cannot be preserved for this case.

An additional option of B<path-to-rsync> also exists which can be used to
override the using PATH environemt variable to find the rsync command binary,
and B<moddebug> which causes the module methods to print some debugging
information to STDERR.

There are also 2 options to wrap the source and/or destination paths in
double-quotes: these are B<quote-src> and B<quote-dst>, which may be useful
in protecting the paths from shell expansion (particularly useful for paths
containing spaces).  This wraps all source and/or destination paths in
double-quotes to limit remote shell expansion.  It is similar but not
necessarily the same result as the B<protect-args> option in rsync itself.

The B<outfun> and B<errfun> options take a function reference, called once
for each line of output from the I<rsync> program with the output line passed
in as the first argument, the second arg is either 'out' or 'err' depending
on the source.
This makes it possible to use the same function for both and still determine
where the output came from.

If options are passed as a hash reference (deprecated), the B<exclude>
needs an array reference as it's value since there cannot be duplicate keys
in a hash.  Since order cannot be preserved in a hash, this module currently
limits the use of B<exclude> or B<include> together.
They can be mixed together if options are in the form of a list or array ref.

Use the '+ ' or '- ' prefix trick to put includes in an B<exclude> array, or
to put excludes in an B<include> array (see I<rsync(1)> for details).

Include/exclude options form an ordered list.
The order must be retained for proper execution.
There are also B<source> and B<dest> keys.
The key B<src> is also accepted as an equivalent to B<source>, and B<dst> or
B<destination> may be used as equivalents to B<dest>.
The B<source> option may take a scalar or an array reference.
If the source is the local system then multiple B<source> paths are allowed.
In this case an array reference should be used.
There is also a method for passing multiple source paths to a remote system.
This method may be triggered in this module by passing the remote hostname to
the B<srchost> key and passing an array reference to the B<source> key.
If the source host is being accessed via an Rsync server, the remote hostname
should have a single trailing colon on the name.
When rsync is called, the B<srchost> value and the values in the B<source>
array will be joined with a colon resulting in the double-colon required for
server access.
The B<dest> key only takes a scalar since I<rsync> only accepts a single
destination path.

Version 2.6.0 of I<rsync(1)> provides a new B<files-from> option along with
a few other supporting options (B<from0>, B<no-relative>, and
B<no-implied-dirs>).
To support this wonderful new option at the level it deserves, this module
now has an additional parameter.
As of version 0.46 the value of B<files-from> may be an array reference.
The contents of the array are passed to B<files-from> the same as the
below method using B<infun> but implemented inside the module.

If B<files-from> is set to '-' (meaning read from stdin) you can define
B<infun> to be a reference to a function that prints your file list to the
default file handle.
The output from the function is attached to stdin of the rsync call during
exec.
If B<infun> is defined it will be called regardless of the value of
B<files-from>, so it can provide any data expected on stdin, but keep in mind
that stdin will not be attached to a tty so it is not very useful for sending
passwords (see the I<rsync(1)> and I<ssh(1)> man pages for ways to handle
authentication).
The I<rsync(1)> man page has a more complete description of B<files-from>.
Also see L<File::Find> for ideas to use with B<files-from> and B<infun>.

The B<infun> option may also be used with the B<include-from> or
B<exclude-from> options, but this is generally more clumsy than using the
B<include> or B<exclude> arrays.

Version 2.6.3 of I<rsync(1)> provides new options B<partial-dir>,
B<checksum-seed>, B<keep-dirlinks>, B<inplace>, B<ipv4>, and B<ipv6>.
Version 2.6.4 of I<rsync(1)> provides new options B<del>, B<delete-before>
B<delete-during>, B<delay-updates>, B<dirs>, B<filter>, B<fuzzy>,
B<itemize-changes>, B<list-only>, B<omit-dir-times>, B<remove-sent-files>,
B<max-size>, and B<protocol>.

Version 0.38 of this module also added support for the B<acls> option that
is not part of I<rsync(1)> unless the patch has been applied, but people do
use it.
It also includes a new B<literal> option that takes an array reference
similar to B<include>, B<exclude>, and B<filter>.
Any arguments in the array are passed as literal arguments to rsync, and are
passed first.
They should have the proper single or double hyphen prefixes and the elements
should be split up the way you want them passed to exec.
The purpose of this option is to allow the use of arbitrary options added by
patches, and/or to allow the use of new options in rsync without needing an
imediate update to the module in addtition to I<rsync(1)> itself.

=cut

sub new {
   my $class = shift;

   # seed the options hash, booleans, scalars, excludes, source, dest, data,
   # status, stderr/stdout storage for last exec
   my $self = {
      # these are the boolean flags to rsync, all default off, including them
      # in the args list turns them on
      flag => {
         map { $_ => 0 }
            qw(8-bit-output acls append append-verify archive backup
            blocking-io checksum compress copy-dirlinks copy-links
            copy-unsafe-links crtimes cvs-exclude daemon del delay-updates
            delete delete-after delete-before delete-delay delete-during
            delete-excluded delete-missing-args devices dirs dry-run
            executability existing fake-super fileflags force force-change
            force-delete force-schange force-uchange from0 fuzzy group groups
            hard-links help hfs-compression ignore-errors ignore-existing
            ignore-missing-args ignore-non-existing ignore-times inc-recursive
            inplace ipv4 ipv6 keep-dirlinks links list-only msgs2stderr
            munge-links new-compress no-blocking-io no-detach no-devices
            no-dirs no-groups no-iconv no-implied-dirs no-inc-recursive
            no-links no-motd no-owner no-partial no-perms no-progress
            no-protect-args no-recursive no-relative no-specials no-super
            no-times no-whole-file numeric-ids old-compress old-dirs
            omit-dir-times omit-link-times owner partial perms preallocate
            progress protect-args protect-decmpfs prune-empty-dirs recursive
            relative remove-source-files safe-links size-only sparse specials
            stats super times update version whole-file xattrs)
      },
      # these have simple scalar args we cannot easily check
      # use 'string' so I don't forget and leave keyword scalar unqouted
      string => {
         map { $_ => '' }
            qw(address backup-dir block-size bwlimit checksum-seed chown
            compress-level config contimeout csum-length debug files-from
            groupmap iconv info log-file log-file-format log-format max-delete
            max-size min-size modify-window only-write-batch out-format outbuf
            partial-dir password-file port protocol read-batch rsh rsync-path
            skip-compress sockopts suffix temp-dir timeout usermap
            write-batch)
      },
      # these are not flags but counters, each time they appear it raises the
      # count, so we keep track and pass them the same number of times
      counter => {
         map { $_ => 0 }
            qw(human-readable itemize-changes one-file-system quiet verbose)
      },
      # these can be specified multiple times and are additive, the doc also
      # specifies that it is an ordered list so we must preserve that order
      list => {
         'chmod'         => [],
         'compare-dest'  => [],
         'copy-dest'     => [],
         'dparam'        => [],
         'exclude'       => [],
         'exclude-from'  => [],
         'filter'        => [],
         'include'       => [],
         'include-from'  => [],
         'link-dest'     => [],
         'literal'       => [],
         'remote-option' => [],
      },
      code => {    # input/output user functions
         'errfun' => undef,
         'outfun' => undef,
         # function to prvide --*-from=- data via pipe
         'infun' => undef,
      },
      _perlopts => {
         # the path name to the rsync binary (default is to use $PATH)
         'path-to-rsync' => 'rsync',
         # hostname of source, used if 'source' is an array reference
         'srchost' => '',
         # double-quote source and/or destination paths
         'quote-src' => 0,
         'quote-dst' => 0,
         # whether or not to print debug statements
         'moddebug' => 0,
      },
      # source host and/or path names
      'source' => '',
      # destination host and/or path
      'dest' => '',
      # return status from last exec
      '_status'     => 0,
      '_realstatus' => 0,
      # last rsync command-line executed
      '_lastcmd' => undef,
     # stderr from last exec in array format (messages from remote rsync proc)
      '_err' => 0,
      # stdout from last exec in array format (messages from local rsync proc)
      '_out' => 0,
      # this flag changes error checking in 'exec' when called by 'list'
      '_list_mode' => 0,
      # this array used to preserve arg order
      '_args' => [],
   };
   bless $self, $class;    # bless it first so defopts can find out the class
   if (@_) {
      &defopts($self, @_) or return;
   }
   return $self;
}

=head2 File::Rsync::defopts

    $obj->defopts(@options);

        or

    $obj->defopts(\@options);

Set default options for future exec calls for the object.
See I<rsync(1)> for a complete list of valid options.
This is really the internal method that I<new> calls but you can use it too.
The B<verbose> and B<quiet> options to rsync are actually counters.
When assigning the perl hash-style options you may specify the counter value
directly and the module will pass the proper number of options to rsync.

=cut

sub defopts {
   # this method has now been split into 2 sub methods (parse and save)
   # _saveopts and _parseopts should only be used via defopts or exec
   my $self = shift;
   &_saveopts($self, &_parseopts($self, @_));
}

sub _parseopts {
   # this method checks and converts it's args into a reference to a hash
   # of valid options and returns it to the caller
   my $self    = shift;
   my $pkgname = ref $self;
   my $href;
   my %OPT = ();    # this is the hash we will return a ref to

   # make sure we are passed the proper number of args
   if (@_ == 1) {
      if (my $reftype = ref $_[0]) {
         if ($reftype eq 'HASH') {
            carp "$pkgname: hash reference is deprecated, use array or list."
               if $^W;
            @_ = %{$_[0]};
            $href++;
         } elsif ($reftype eq 'ARRAY') {
            @_ = @{$_[0]};
         } else {
            carp "$pkgname: invalid reference type ($reftype) option.";
            return;
         }
      } else {
         carp "$pkgname: invalid option ($_[0]).";
         return;
      }
   }
   if (@_ % 2) {
      carp
         "$pkgname: invalid number of options passed (must be key/value pairs).";
      return;
   }

   # now process the options given, we handle debug first
   for (my $i = 0; $i < @_; $i += 2) {
      if ($_[$i] eq 'moddebug') {
         $OPT{moddebug} = $_[ $i + 1 ];
         warn "setting debug flag\n" if $OPT{moddebug};
         last;
      }
   }

   my @order;
   while (my ($inkey, $val) = splice @_, 0, 2) {
      (my $key = $inkey) =~ tr/_/-/;
      $key =~ s/^--?//;    # remove any leading hyphens if found
      $key = 'source' if $key eq 'src';
      $key = 'dest' if $key eq 'dst' or $key eq 'destination';
      next if $key eq 'moddebug';    # we did this one already
      warn "processing option: $inkey\n"
         if $OPT{moddebug}
         or $self->{_perlopts}{moddebug};
      if (  exists $self->{flag}{$key}
         or exists $self->{string}{$key}
         or exists $self->{counter}{$key}
         or exists $self->{_perlopts}{$key})
      {
         if ($key eq 'files-from' and ref $val eq 'ARRAY') {
            push @order, $key, '-', 'infun', $val;    # --files-from=- <\@
            $OPT{$key} = '-';
            $OPT{infun} = $val;

         } else {
            push @order, $key, $val;
            $OPT{$key} = $val;
         }
         next;
      }
      if (exists $self->{list}{$key} or $key eq 'source') {
         if (my $reftype = ref $val) {
            if ($reftype eq 'ARRAY') {
               push @order, $key, $val;
               $OPT{$key} = $val;
               next;
            } elsif ($key eq 'source' && blessed $val) {
               # if it's blessed, assume it returns a string
               $val = [$val];
               push @order, $key, $val;
               $OPT{$key} = $val;
               next;
            } else {
               carp "$pkgname: invalid reference type for $inkey option.";
               return;
            }
         } elsif ($key eq 'source') {
            $val = [$val];
            push @order, $key, $val;
            $OPT{$key} = $val;
            next;
         } else {
            carp "$pkgname: $inkey value is not a reference.";
            return;
         }
      }
      if ($key eq 'dest') {
         push @order, $key, $val;
         $OPT{$key} = $val;
         next;
      }
      if (exists $self->{code}{$key}) {
         if (ref $val eq 'CODE') {
            push @order, $key, $val;
            $OPT{$key} = $val;
            next;
         } elsif ($key eq 'infun' and ref $val eq 'ARRAY') {
            # IPC::Run3 lets us pass an array ref as stdin :)
            push @order, $key, $val;
            $OPT{$key} = $val;
            next;
         } else {
            carp "$pkgname: $inkey option is not a function reference.";
            return;
         }
      }

      carp "$pkgname: $inkey - unknown option.";
      return;
   }
   $OPT{_args} = \@order unless $href;
   return \%OPT;
}

sub _saveopts {
   # save the data from the hash passed in the object
   my $self    = shift;
   my $pkgname = ref $self;
   my $opts    = shift;
   return unless ref $opts eq 'HASH';
SO: for my $opt (keys %$opts) {
      for my $type (qw(flag string counter list code _perlopts)) {
         if (exists $self->{$type}{$opt}) {
            $self->{$type}{$opt} = $opts->{$opt};
            next SO;
         }
      }
      if (  $opt eq 'source'
         or $opt eq 'dest'
         or $opt eq '_args')
      {
         $self->{$opt} = $opts->{$opt};
      } else {
         carp "$pkgname: unknown option: $opt.";
         return;
      }
   }    # end SO
   return 1;
}

=head2 File::Rsync::getcmd

    my $cmd = $obj->getcmd(@options);

        or

    my $cmd = $obj->getcmd(\@options);

        or

    my ($cmd, $infun, $outfun, $errfun, $debug) = $obj->getcmd(\@options);

I<getcmd> returns a reference to an array containing the real rsync command
that would be called if the exec function were called.
The last example above includes a reference to the optional stdin function,
stdout function, stderr function, and the debug setting.
This is the form used by the I<exec> method to get the extra parameters it
needs to do its job.
The function is exposed to allow a user-defined exec function to be used, or
for debugging purposes.

=cut

sub getcmd {
   my $self    = shift;
   my $pkgname = ref $self;
   my $merged  = $self;
   my $list    = $self->{_list_mode};
   $self->{_list_mode} = 0;
   if (@_) {
      # If args are passed to exec then we have to merge the saved
      # (default) options with those passed, for any conflicts those passed
      # directly to exec take precidence
      my $execopts = &_parseopts($self, @_);
      return unless ref $execopts eq 'HASH';
      my %runopts = ();
      # first copy the default info from $self
      for my $type (qw(flag string counter list code _perlopts)) {
         for my $opt (keys %{$self->{$type}}) {
            $runopts{$type}{$opt} = $self->{$type}{$opt};
         }
      }
      for my $opt (qw(source dest)) {
         $runopts{$opt} = $self->{$opt};
      }
      @{$runopts{_args}} = @{$self->{_args}};
      # now allow any args passed directly to exec to override
   OPT: for my $opt (keys %$execopts) {
         for my $type (qw(flag string counter list code _perlopts)) {
            if (exists $runopts{$type}{$opt}) {
               $runopts{$type}{$opt} = $execopts->{$opt};
               next OPT;
            }
         }
         if ($opt eq '_args') {
            # only preserve order if we already have order
            push @{$runopts{$opt}}, @{$execopts->{$opt}}
               if @{$runopts{$opt}};
         } elsif ($opt eq 'source' or $opt eq 'dest') {
            $runopts{$opt} = $execopts->{$opt};
         } else {
            carp "$pkgname: unknown option: $opt.";
            return;
         }
      }
      $merged = \%runopts;
   }

   if (
      !@{$merged->{_args}}    # include and exclude allowed if ordered args
      && ( (@{$merged->{list}{exclude}} != 0)
         + (@{$merged->{list}{include}} != 0)
         + (@{$merged->{list}{filter}} != 0) > 1)
      )
   {
      carp "$pkgname: 'exclude' and/or 'include' and/or 'filter' "
         . "options specified, only one allowed.";
      return;
   }

   my $srchost = $merged->{srchost};
   $srchost .= ':' if $srchost and substr($srchost, 0, 8) ne 'rsync://';

   # build the real command
   my @cmd = ($merged->{_perlopts}{'path-to-rsync'});

   if (@{$merged->{_args}}) {    # prefer ordered args if we have them
      my $gotsrc;
      for (my $e = 0; $e < @{$merged->{_args}}; $e += 2) {
         my $key = $merged->{_args}[$e];
         my $val = $merged->{_args}[ $e + 1 ];
         if ($key eq 'literal') {
            push @cmd, ref $val eq 'ARRAY' ? @$val : $val;
         } elsif (exists $merged->{flag}{$key}) {
            push @cmd, "--$key" if $val;
         } elsif (exists $merged->{string}{$key}) {
            push @cmd, "--$key=$val" if $val;
         } elsif (exists $merged->{counter}{$key}) {
            for (my $i = 0; $i < $val; $i++) {
               push @cmd, "--$key";
            }
         } elsif (exists $merged->{list}{$key}) {
            push @cmd, ref $val eq 'ARRAY'
               ? map "--$key=$_", @$val
               : "--$key=$val";
         } elsif ($key eq 'source') {
            if ($merged->{srchost}) {
               push @cmd, $srchost . join ' ',
                  $merged->{'quote-src'}
                  ? map ("\"$_\"", ref $val eq 'ARRAY' ? @$val : $val)
                  : ref $val eq 'ARRAY' ? @$val
                  :                       $val;
            } else {
               push @cmd,
                  $merged->{'quote-src'}
                  ? map ("\"$_\"", ref $val eq 'ARRAY' ? @$val : $val)
                  : ref $val eq 'ARRAY' ? @$val
                  :                       $val;
            }
            $gotsrc++;
         } elsif ($key eq 'dest') {
            if ($list) {
               if (not $gotsrc) {
                  if ($merged->{srchost}) {
                     push @cmd, $srchost;
                  } else {
                     carp "$pkgname: no 'source' specified.";
                     return;
                  }
               }
            } elsif (not $gotsrc) {
               carp
                  "$pkgname: option 'dest' specified without 'source' option.";
               return;
            } else {
               push @cmd, $merged->{'quote-dst'} ? "\"$val\"" : $val;
            }
         }
      }
   } else {
      # we do a bunch of extra work here to support hash refs,
      # they don't work well here, no order, we do what we can
      # put any literal options first
      push @cmd, @{$merged->{list}{literal}} if @{$merged->{list}{literal}};

      for my $opt (sort keys %{$merged->{flag}}) {
         push @cmd, "--$opt" if $merged->{flag}{$opt};
      }
      for my $opt (sort keys %{$merged->{string}}) {
         push @cmd, "--$opt=$merged->{string}{$opt}"
            if $merged->{string}{$opt};
      }
      for my $opt (sort keys %{$merged->{counter}}) {
         for (my $i = 0; $i < $merged->{counter}{$opt}; $i++) {
            push @cmd, "--$opt";
         }
      }
      for my $opt (sort keys %{$merged->{list}}) {
         next if $opt eq 'literal';
         for my $val (@{$merged->{list}{$opt}}) {
            push @cmd, "--$opt=$val";
         }
      }

      if ($merged->{source}) {
         if ($merged->{srchost}) {
            push @cmd, $srchost . join ' ',
               $merged->{'quote-src'}
               ? map { "\"$_\"" } @{$merged->{source}}
               : @{$merged->{source}};
         } else {
            push @cmd,
               $merged->{'quote-src'}
               ? map { "\"$_\"" } @{$merged->{source}}
               : @{$merged->{source}};
         }
      } elsif ($merged->{srchost} and $list) {
         push @cmd, $srchost;
      } else {
         if ($list) {
            carp "$pkgname: no 'source' specified.";
            return;
         } elsif ($merged->{dest}) {
            carp "$pkgname: option 'dest' specified without 'source' option.";
            return;
         } else {
            carp "$pkgname: no source or destination specified.";
            return;
         }
      }
      unless ($list) {
         if ($merged->{dest}) {
            push @cmd, $merged->{'quote-dst'}
               ? "\"$merged->{dest}\""
               : $merged->{dest};
         } else {
            carp "$pkgname: option 'source' specified without 'dest' option.";
            return;
         }
      }
   }

   return (
      wantarray
      ? (\@cmd,                   $merged->{code}{infun},
         $merged->{code}{outfun}, $merged->{code}{errfun},
         $merged->{_perlopts}{moddebug}
         )
      : \@cmd
   );
}

=head2 File::Rsync::exec

    $obj->exec(@options) or warn "rsync failed\n";

        or

    $obj->exec(\@options) or warn "rsync failed\n";

This is the method that does the real work.
Any options passed to this routine are appended to any pre-set options and
are not saved.
They effect the current execution of I<rsync> only.
In the case of conflicts, the options passed directly to I<exec> take
precedence.
It returns B<1> if the return status was zero (or true), if the I<rsync>
return status was non-zero it returns B<0> and stores the return status.
You can examine the return status from I<rsync> and any output to stdout and
stderr with the methods listed below.

=cut

sub exec {
   my $self = shift;

   my ($cmd, $infun, $outfun, $errfun, $debug) = $self->getcmd(@_);
   return unless $cmd;
   warn "exec: @$cmd\n" if $debug;
   my $input;
   if (ref $infun eq 'CODE') {
      my $pid = open my $fh, '-|';
      if ($pid) {    # parent grabs output
         my @in = <$fh>;
         close $fh;
         chomp @in;
         $input = \@in;
      } else {    # child runs infun
         &{$infun};
         exit;
      }
   } else {
      $input = $infun;
   }
   run3($cmd, $input, \my $stdout, \my $stderr);
   $self->{_lastcmd}    = $cmd;
   $self->{_realstatus} = $?;
   $self->{_status}     = $? & 127 ? $? & 127 : $? >> 8;
   $self->{_out}        = $stdout ? [ split /^/m, $stdout ] : '';
   $self->{_err}        = $stderr ? [ split /^/m, $stderr ] : '';
   if ($outfun and $self->{_out}) {
      for (@{$self->{_out}}) { $outfun->($_, 'out') }
   }
   if ($errfun and $self->{_err}) {
      for (@{$self->{_err}}) { $errfun->($_, 'err') }
   }
   return ($self->{_status} ? 0 : 1);
}

=head2 File::Rsync::list

    $out = $obj->list(@options);

        or

    $out = $obj->list(\@options);

        or

    @out = $obj->list(\@options);

This is a wrapper for I<exec> called without a destination to get a listing.
It returns the output of stdout like the I<out> function below.
When no destination is given rsync returns the equivalent of 'ls -l' or
'ls -lr' modified by any include/exclude/filter parameters you specify.
This is useful for manual comparison without actual changes to the
destination or for comparing against another listing taken at a different
point in time.

(As of rsync version 2.6.4-pre1 this can also be accomplished with the
'list-only' option regardless of whether a destination is given.)

=cut

sub list {
   my $self = shift;
   $self->{_list_mode}++;
   $self->exec(@_);
   if ($self->{_out}) {
      return (wantarray ? @{$self->{_out}} : $self->{_out});
   } else {
      return;
   }
}

=head2 File::Rsync::status

    $rval = $obj->status;

Returns the status from last I<exec> call right shifted 8 bits.

=cut

sub status {
   my $self = shift;
   return $self->{_status};
}

=head2 File::Rsync::realstatus

    $rval = $obj->realstatus;

Returns the real status from last I<exec> call (not right shifted).

=cut

sub realstatus {
   my $self = shift;
   return $self->{_realstatus};
}

=head2 File::Rsync::err

    $aref = $obj->err;

In scalar context this method will return a reference to an array containing
all output to stderr from the last I<exec> call, or zero (false) if there
was no output.
In an array context it will return an array of all output to stderr or an
empty list.
The scalar context can be used to efficiently test for the existance of output.
I<rsync> sends all messages from the remote I<rsync> process and any error
messages to stderr.
This method's purpose is to make it easier for you to parse that output for
appropriate information.

=cut

sub err {
   my $self = shift;
   if ($self->{_err}) {
      return (wantarray ? @{$self->{_err}} : $self->{_err});
   } else {
      return;
   }
}

=head2 File::Rsync::out

    $aref = $obj->out;

Similar to the I<err> method, in a scalar context it returns a reference to an
array containing all output to stdout from the last I<exec> call, or zero
(false) if there was no output.
In an array context it returns an array of all output to stdout or an empty
list.
I<rsync> sends all informational messages (B<verbose> option) from the local
I<rsync> process to stdout.

=cut

sub out {
   my $self = shift;
   if ($self->{_out}) {
      return (wantarray ? @{$self->{_out}} : $self->{_out});
   } else {
      return;
   }
}

=head2 File::Rsync::lastcmd

    $aref = $obj->lastcmd;

Returns the actual system command used by the last I<exec> call, or '' before
any calls to I<exec> for the object.
This can be useful in the case of an error condition to give a more
informative message or for debugging purposes.
In an array context it return an array of args as passed to the system, in
a scalar context it returns a space-seperated string.
See I<getcmd> for access to the command before execution.

=cut

sub lastcmd {
   my $self = shift;
   if ($self->{_lastcmd}) {
      return wantarray ? @{$self->{_lastcmd}} : join ' ',
         @{$self->{_lastcmd}};
   } else {
      return;
   }
}

=head1 Author

Lee Eakin E<lt>leakin@dfw.nostrum.comE<gt>

=head1 Credits

The following people have contributed ideas, bug fixes, code or helped out
by reporting or tracking down bugs in order to improve this module since
it's initial release.
See the Changelog for details:

Greg Ward

Boris Goldowsky

James Mello

Andreas Koenig

Joe Smith

Jonathan Pelletier

Heiko Jansen

Tong Zhu

Paul Egan

Ronald J Kimball

James CE Johnson

Bill Uhl

Peter teStrake

Harald Flaucher

Simon Myers

Gavin Carr

Petya Kohts

Neil Hooey

Erez Schatz

Max Maischein

=head1 Inspiration and Assistance

Gerard Hickey                             C<PGP::Pipe>

Russ Allbery                              C<PGP::Sign>

Graham Barr                               C<Net::*>

Andrew Tridgell and Paul Mackerras        rsync(1)

John Steele   E<lt>steele@nostrum.comE<gt>

Philip Kizer  E<lt>pckizer@nostrum.comE<gt>

Larry Wall                                perl(1)

I borrowed many clues on wrapping an external program from the PGP modules,
and I would not have had such a useful tool to wrap except for the great work
of the B<rsync> authors.  Thanks also to Graham Barr, the author of the libnet
modules and many others, for looking over this code.  Of course I must mention
the other half of my brain, John Steele, and his good friend Philip Kizer for
finding B<rsync> and bringing it to my attention.  And I would not have been
able to enjoy writing useful tools if not for the creator of the B<perl>
language.

=head1 Copyrights

      Copyright (c) 1999-2015 Lee Eakin.  All rights reserved.

      This program is free software; you can redistribute it and/or modify
      it under the same terms as Perl itself.

=cut

1;
