package File::Finder::Steps;

our $VERSION = '1.00';

use strict;

use Carp qw(croak);

=head1 NAME

File::Finder::Steps - steps for File::Finder

=head1 SYNOPSIS

  ## See File::Finder for normal use of steps

  ## subclassing example:
  BEGIN {
    package My::File::Finder;
    use base File::Finder;

    sub _steps_class { "My::File::Finder::Steps" }
  }
  BEGIN {
    package My::File::Finder::Steps;
    use base File::Finder::Steps;

    sub bigger_than { # true if bigger than N bytes
      my $self = shift;
      my $bytes = shift;
      return sub {
        -s > $bytes;
      }
    }
  }

  my $over_1k = My::File::Finder->bigger_than(1024);
  print "Temp files over 1k:\n";
  $over_1k->ls->in("/tmp");

=head1 DESCRIPTION

C<File::Finder::Steps> provide the predicates being tested for
C<File::Finder>.

=head2 STEPS METHODS

These methods are called on a class or instance to add a "step".  Each
step adds itself to a list of steps, returning the new object.  This
allows you to chain steps together to form a formula.

As in I<find>, the default operator is "and", and short-circuiting is
performed.

Note: the C<user>, C<nouser>, C<group>, C<nogroup>, and C<ls> methods
are not available on Win32 systems.

=over

=item or

Like I<find>'s C<or>.

=cut

sub or { return "or" }

=item left

Like a left parenthesis.  Used in nesting pairs with C<right>.

=cut

sub left { return "left" }
BEGIN { *begin = \&left; }

=item right

Like a right parenthesis.  Used in nesting pairs with C<left>.
For example:

  my $big_or_old = File::Finder
    ->type('f')
      ->left
        ->size("+100")->or->mtime("+90")
      ->right;
  find($big_or_old->ls, "/tmp");

You need parens because the "or" operator is lower precedence than
the implied "and", for the same reason you need them here:

  find /tmp -type f '(' -size +100 -o -mtime +90 ')' -print

Without the parens, the -type would bind to -size, and not to the
choice of -size or -mtime.

Mismatched parens will not be found until the formula is used, causing
a fatal error.

=cut

sub right { return "right" }
BEGIN { *end = \&right; }

=item begin

Alias for C<left>.

=item end

Alias for C<right>.

=item not

Like I<find>'s C<!>.  Prefix operator, can be placed in front of
individual terms or open parens.  Can be nested, but what's the point?

  # list all non-files in /tmp
  File::Finder->not->type('f')->ls->in("/tmp");

=cut

sub not { return "not" }

=item true

Always returns true.  Useful when a subexpression might fail, but
you don't want the overall code to fail:

  ... ->left-> ...[might return false]... ->or->true->right-> ...

Of course, this is the I<find> command's idiom of:

   find .... '(' .... -o -true ')' ...

=cut

sub true { return sub { 1 } }

=item false

Always returns false.

=cut

sub false { return sub { 0 } }

=item comma

Like GNU I<find>'s ",".  The result of the expression (or
subexpression if in parens) up to this point is discarded, and
execution continues afresh.  Useful when a part of the expression is
needed for its side effects, but shouldn't affect the rest of the
"and"-ed chain.

  # list all files and dirs, but don't descend into CVS dir contents:
  File::Finder->type('d')->name('CVS')->prune->comma->ls->in('.');

=cut

sub comma { return "comma" } # gnu extension

=item follow

Enables symlink following, and returns true.

=cut

sub follow {
  my $self = shift;
  $self->{options}{follow} = 1;
  return sub { 1 };
}

=item name(NAME)

True if basename matches NAME, which can be given as a glob
pattern or a regular expression object:

  my $pm_files = File::Finder->name('*.pm')->in('.');
  my $pm_files_too = File::Finder->name(qr/pm$/)->in('.');

=cut

sub name {
  my $self = shift;
  my $name = shift;

  unless (UNIVERSAL::isa($name, "Regexp")) {
    require Text::Glob;
    $name = Text::Glob::glob_to_regex($name);
  }

  return sub {
    /$name/;
  };
}

=item perm(PERMISSION)

Like I<find>'s C<-perm>.  Leading "-" means "all of these bits".
Leading "+" means "any of these bits".  Value is de-octalized if a
leading 0 is present, which is likely only if it's being passed as a
string.

  my $files = File::Finder->type('f');
  # find files that are exactly mode 644
  my $files_644 = $files->perm(0644);
  # find files that are at least world executable:
  my $files_world_exec = $files->perm("-1");
  # find files that have some executable bit set:
  my $files_exec = $files->perm("+0111");

=cut

sub perm {
  my $self = shift;
  my $perm = shift;
  $perm =~ /^(\+|-)?\d+\z/ or croak "bad permissions $perm";
  if ($perm =~ s/^-//) {
    $perm = oct($perm) if $perm =~ /^0/;
    return sub {
      ((stat _)[2] & $perm) == $perm;
    };
  } elsif ($perm =~ s/^\+//) { # gnu extension
    $perm = oct($perm) if $perm =~ /^0/;
    return sub {
      ((stat _)[2] & $perm);
    };
  } else {
    $perm = oct($perm) if $perm =~ /^0/;
    return sub {
      ((stat _)[2] & 0777) == $perm;
    };
  }
}

=item type(TYPE)

Like I<find>'s C<-type>.  All native Perl types are supported.  Note
that C<s> is a socket, mapping to Perl's C<-S>, to be consistent with
I<find>.  Returns true or false, as appropriate.

=cut

BEGIN {
  my %typecast;

  sub type {
    my $self = shift;
    my $type = shift;

    $type =~ /^[a-z]\z/i or croak "bad type $type";
    $type =~ s/s/S/;

    $typecast{$type} ||= eval "sub { -$type _ }";
  }
}

=item print

Prints the fullname to C<STDOUT>, followed by a newline.  Returns true.

=cut

sub print {
  return sub {
    print $File::Find::name, "\n";
    1;
  };
}

=item print0

Prints the fullname to C<STDOUT>, followed by a NUL.  Returns true.

=cut

sub print0 {
  return sub {
    print $File::Find::name, "\0";
    1;
  };
}

=item fstype

Not implemented yet.

=item user(USERNAME|UID)

True if the owner is USERNAME or UID.

=cut

sub user {
  my $self = shift;
  my $user = shift;

  croak 'user not supported on this platform' if $^O eq 'MSWin32';

  my $uid = ($user =~ /^\d+\z/) ? $user : _user_to_uid($user);
  die "bad user $user" unless defined $uid;

  return sub {
    (stat _)[4] == $uid;
  };
}

=item group(GROUPNAME|GID)

True if the group is GROUPNAME or GID.

=cut

sub group {
  my $self = shift;
  my $group = shift;

  croak 'group not supported on this platform' if $^O eq 'MSWin32';

  my $gid = ($group =~ /^\d+\z/) ? $group : _group_to_gid($group);
  die "bad group $gid" unless defined $gid;

  return sub {
    (stat _)[5] == $gid;
  };
}

=item nouser

True if the entry doesn't belong to any known user.

=cut

sub nouser {
  croak 'nouser not supported on this platform' if $^O eq 'MSWin32';
  return sub {
    CORE::not defined _uid_to_user((stat _)[4]);
  }
}

=item nogroup

True if the entry doesn't belong to any known group.

=cut

sub nogroup {
  croak 'nogroup not supported on this platform' if $^O eq 'MSWin32';
  return sub {
    CORE::not defined _gid_to_group((stat _)[5]);
  }
}

=item links( +/- N )

Like I<find>'s C<-links N>.  Leading plus means "more than", minus
means "less than".

=cut

sub links {
  my $self = shift;
  my ($prefix, $n) = shift =~ /^(\+|-|)(.*)/;

  return sub {
    _n($prefix, $n, (stat(_))[3]);
  };
}

=item inum( +/- N )

True if the inode number meets the qualification.

=cut

sub inum {
  my $self = shift;
  my ($prefix, $n) = shift =~ /^(\+|-|)(.*)/;

  return sub {
    _n($prefix, $n, (stat(_))[1]);
  };
}

=item size( +/- N [c/k])

True if the file size meets the qualification.  By default, N is
in half-K blocks.  Append a trailing "k" to the number to indicate
1K blocks, or "c" to indicate characters (bytes).

=cut

sub size {
  my $self = shift;
  my ($prefix, $n) = shift =~ /^(\+|-|)(.*)/;

  if ($n =~ s/c\z//) {
    return sub {
      _n($prefix, $n, int(-s _));
    };
  }
  if ($n =~ s/k\z//) {
    return sub {
      _n($prefix, $n, int(((-s _)+1023) / 1024));
    };
  }
  return sub {
    _n($prefix, $n, int(((-s _)+511) / 512));
  };
}

=item atime( +/- N )

True if access time (in days) meets the qualification.

=cut

sub atime {
  my $self = shift;
  my ($prefix, $n) = shift =~ /^(\+|-|)(.*)/;

  return sub {
    _n($prefix, $n, int(-A _));
  };
}

=item mtime( +/- N )

True if modification time (in days) meets the qualification.

=cut

sub mtime {
  my $self = shift;
  my ($prefix, $n) = shift =~ /^(\+|-|)(.*)/;

  return sub {
    _n($prefix, $n, int(-M _));
  };
}

=item ctime( +/- N )

True if inode change time (in days) meets the qualification.

=cut

sub ctime {
  my $self = shift;
  my ($prefix, $n) = shift =~ /^(\+|-|)(.*)/;

  return sub {
    _n($prefix, $n, int(-C _));
  };
}

=item exec(@COMMAND)

Forks the child process via C<system()>.  Any appearance of C<{}> in
any argument is replaced by the current filename.  Returns true if the
child exit status is 0.  The list is passed directly to C<system>,
so if it's a single arg, it can contain C</bin/sh> syntax.  Otherwise,
it's a pre-parsed command that must be found on the PATH.

Note that I couldn't figure out how to horse around with the current
directory very well, so I'm using C<$_> here instead of the more
traditional C<File::Find::name>.  It still works, because we're still
chdir'ed down into the directory, but it looks weird on a trace.
Trigger C<no_chdir> in C<find> if you want a traditional I<find> full
path.

  my $f = File::Finder->exec('ls', '-ldg', '{}');
  find({ no_chdir => 1, wanted => $f }, @starting_dirs);

Yeah, it'd be trivial for me to add a no_chdir method.  Soon.

=cut

sub exec {
  my $self = shift;
  my @command = @ _;

  return sub {
    my @mapped = @command;
    for my $one (@mapped) {
      $one =~ s/{}/$_/g;
    }
    system @mapped;
    return !$?;
  };
}

=item ok(@COMMAND)

Like C<exec>, but displays the command line first, and waits for a
response.  If the response begins with C<y> or C<Y>, runs the command.
If the command fails, or the response wasn't yes, returns false,
otherwise true.

=cut

sub ok {
  my $self = shift;
  my @command = @ _;

  return sub {
    my @mapped = @command;
    for my $one (@mapped) {
      $one =~ s/{}/$_/g;
    }
    my $old = select(STDOUT);
    $|++;
    print "@mapped? ";
    select $old;
    return 0 unless <STDIN> =~ /^y/i;
    system @mapped;
    return !$?;
  };
}

=item prune

Sets C<$File::Find::prune>, and returns true.

=cut

sub prune {
  return sub { $File::Find::prune = 1 };
}

=item xdev

Not yet implemented.

=item newer

Not yet implemented.

=item eval(CODEREF)

Ah yes, the master escape, with extra benefits.  Give it a coderef,
and it evaluates that code at the proper time.  The return value is noted
for true/false and used accordingly.

  my $blaster = File::Finder->atime("+30")->eval(sub { unlink });

But wait, there's more.  If the parameter is an object that responds
to C<as_wanted>, that method is automatically called, hoping for a
coderef return. This neat feature allows subroutines to be created and
nested:

  my $old = File::Finder->atime("+30");
  my $big = File::Finder->size("+100");
  my $old_or_big = File::Finder->eval($old)->or->eval($big);
  my $killer = File::Finder->eval(sub { unlink });
  my $kill_old_or_big = File::Finder->eval($old_or_big)->ls->eval($killer);
  $kill_old_or_big->in('/tmp');

Almost too cool for words.

=cut

sub eval {
  my $self = shift;
  my $eval = shift;

  ## if this is another File::Finder object... then cheat:
  $eval = $eval->as_wanted if UNIVERSAL::can($eval, "as_wanted");

  return $eval; # just reuse the coderef
}

=item depth

Like I<find>'s C<-depth>.  Sets a flag for C<as_options>, and returns true.

=cut

sub depth {
  my $self = shift;
  $self->{options}{bydepth} = 1;
  return sub { 1 };
}

=item ls

Like I<find>'s C<-ls>.  Performs a C<ls -dils> on the entry to
C<STDOUT> (without forking), and returns true.

=cut

sub ls {
  croak 'ls not supported on this platform' if $^O eq 'MSWin32';
  return \&_ls;
}

=item tar

Not yet implemented.

=item [n]cpio

Not yet implemented.

=item ffr($ffr_object)

Incorporate a C<File::Find::Rule> object as a step. Note that this
must be a rule object, and not a result, so don't call or pass C<in>.
For example, using C<File::Find::Rule::ImageSize> to define a
predicate for image files that are bigger than a megapixel in my
friends folder, I get:

  require File::Finder;
  require File::Find::Rule;
  require File::Find::Rule::ImageSize;
  my $ffr = File::Find::Rule->file->image_x('>1000')->image_y('>1000');
  my @big_friends = File::Finder->ffr($ffr)
    ->in("/Users/merlyn/Pictures/Sorted/Friends");

=cut

sub ffr {
  my $self = shift;
  my $ffr_object = shift;

  my $their_wanted;

  no warnings;
  local *File::Find::find = sub {
    my ($options) = @ _;
    for (my ($k, $v) = each %$options) {
      if ($k eq "wanted") {
  	$their_wanted = $v;
      } else {
  	$self->{options}->{$k} = $v;
      }
    }
  };
  $ffr_object->in("/DUMMY"); # boom!
  croak "no wanted defined" unless defined $their_wanted;
  return $their_wanted;
}

=item contains(pattern)

True if the file contains C<pattern> (either a literal string
treated as a regex, or a true regex object).

  my $plugh_files = File::Finder->type('f')->contains(qr/plugh/);

Searching is performed on a line-by-line basis, respecting the
current value of C<$/>.

=cut

sub contains {
  my $self = shift;
  my $pat = shift;
  return sub {
    open my $f, "<" . $_ or return 0;
    while (<$f>) {
      return 1 if /$pat/;
    }
    return 0;
  };
}


=back

=head2 EXTENDING

A step consists of a compile-time and a run-time component.

During the creation of a C<File::Finder> object, step methods are
called as if they were methods against the slowly-growing
C<File::Finder> instance, including any additional parameters as in a
normal method call.  The step is expected to return a coderef
(possibly a closure) to be executed at run-time.

When a C<File::Finder> object is being evaluated as the C<File::Find>
C<wanted> routine, the collected coderefs are evaluated in sequence,
again as method calls against the C<File::Finder> object.  No
additional parameters are passed.  However, the normal C<wanted>
values are available, such as C<$_>, C<$File::Find::name>, and so on.
The C<_> pseudo-handle has been set properly, so you can safely
use C<-X> filetests and C<stat> against the pseudo-handle.
The routine is expected to return a true/false value, which becomes
the value of the step.

Although a C<File::Finder> object is passed both to the compile-time
invocation and the resulting run-time invocation, only the C<options>
self-hash element is properly duplicated through the cloning process.
Do not be tempted to add additional self-hash elements without
overriding C<File::Finder>'s C<_clone>.  Instead, pass values from the
compile-time phase to the run-time phase using closure variables, as
shown in the synopsis.

For simplicity, you can also just mix-in your methods to the existing
C<File::Finder::Steps> class, rather than subclassing both classes as
shown above.  However, this may result in conflicting implementations
of a given step name, so beware.

=head1 SEE ALSO

L<File::Finder>

=head1 BUGS

None known yet.

=head1 AUTHOR

Randal L. Schwartz, E<lt>merlyn@stonehenge.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003,2004 by Randal L. Schwartz,
Stonehenge Consulting Services, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or, 
at your option, any later version of Perl 5 you may have available.

=cut

## utility subroutines

sub _n {
  my ($prefix, $arg, $value) = @ _;
  if ($prefix eq "+") {
    $value > $arg;
  } elsif ($prefix eq "-") {
    $value < $arg;
  } else {
    $value == $arg;
  }
}

BEGIN {

  my %user_to_uid;
  my %uid_to_user;

  my $initialize = sub {
    while (my ($user, $pw, $uid) = getpwent) {
      $user_to_uid{$user} = $uid;
      $uid_to_user{$uid} = $user;
    }
  };

  sub _user_to_uid {
    my $user = shift;

    %user_to_uid or $initialize->();
    $user_to_uid{$user};
  }

  sub _uid_to_user {
    my $uid = shift;

    %uid_to_user or $initialize->();
    $uid_to_user{$uid};
  }

}

BEGIN {

  my %group_to_gid;
  my %gid_to_group;

  my $initialize = sub {
    while (my ($group, $pw, $gid) = getgrent) {
      $group_to_gid{$group} = $gid;
      $gid_to_group{$gid} = $group;
    }
  };

  sub _group_to_gid {
    my $group = shift;

    %group_to_gid or $initialize->();
    $group_to_gid{$group};
  }

  sub _gid_to_group {
    my $gid = shift;

    %gid_to_group or $initialize->();
    $gid_to_group{$gid};
  }

}

BEGIN {
  ## from find2perl

  my @rwx = qw(--- --x -w- -wx r-- r-x rw- rwx);
  my @moname = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

  sub _sizemm {
    my $rdev = shift;
    sprintf("%3d, %3d", ($rdev >> 8) & 0xff, $rdev & 0xff);
  }

  sub _ls {
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks) = stat(_);
    my $pname = $File::Find::name;

    $blocks
      or $blocks = int(($size + 1023) / 1024);

    my $perms = $rwx[$mode & 7];
    $mode >>= 3;
    $perms = $rwx[$mode & 7] . $perms;
    $mode >>= 3;
    $perms = $rwx[$mode & 7] . $perms;
    substr($perms, 2, 1) =~ tr/-x/Ss/ if -u _;
    substr($perms, 5, 1) =~ tr/-x/Ss/ if -g _;
    substr($perms, 8, 1) =~ tr/-x/Tt/ if -k _;
    if    (-f _) { $perms = '-' . $perms; }
    elsif (-d _) { $perms = 'd' . $perms; }
    elsif (-l _) { $perms = 'l' . $perms; $pname .= ' -> ' . readlink($_); }
    elsif (-c _) { $perms = 'c' . $perms; $size = _sizemm($rdev); }
    elsif (-b _) { $perms = 'b' . $perms; $size = _sizemm($rdev); }
    elsif (-p _) { $perms = 'p' . $perms; }
    elsif (-S _) { $perms = 's' . $perms; }
    else         { $perms = '?' . $perms; }

    my $user = _uid_to_user($uid) || $uid;
    my $group = _gid_to_group($gid) || $gid;

    my ($sec,$min,$hour,$mday,$mon,$timeyear) = localtime($mtime);
    if (-M _ > 365.25 / 2) {
      $timeyear += 1900;
    } else {
      $timeyear = sprintf("%02d:%02d", $hour, $min);
    }

    printf "%5lu %4ld %-10s %3d %-8s %-8s %8s %s %2d %5s %s\n",
      $ino, $blocks, $perms, $nlink, $user, $group, $size,
	$moname[$mon], $mday, $timeyear, $pname;
    1;
  }
}

1;
__END__
