# (X)Emacs mode: -*- cperl -*-

use 5.005_62;
use strict;
use warnings;

=head1 NAME

make - tools for making makefiles with.

=head1 SYNOPSIS

  use constant MOD_REQS =>
    [
     { name    => 'Pod::Usage',
       version => '1.12', },

     { name    => 'IPC::Run',
       package => 'IPC-Run',
       version => '0.44', },

     { name     => 'DBI::Wrap',
       package  => 'DBI-Wrap',
       version  => '1.00',
       optional => 1, },
    ];

  use constant EXEC_REQS =>
    [
     { name    => 'blastpgp',
       version => '1.50',
       vopt    => '--version', },

     { name    => 'mkprofile', },

     { name    => 'mp3id',
       version => '0.4',
       vopt    => '--help',
       vexpect => 255, },
    ];

  use constant NAME         => 'Module-Name';
  use constant VERSION_FROM => catfile (qw( lib Module Name.pm ));
  use constant AUTHOR       => 'Martyn J. Pearce fluffy@inpharmatica.co.uk';
  use constant ABSTRACT     => 'This module makes chocolate biscuits';

  use make.pm

=head1 DESCRIPTION

This package provides methods and initialization to build standard perl
modules.

The plan is, you define the requirements, and let the module take care of the
rest.

The requirements you must define are:

=over 4

=item MOD_REQS

An arrayref of hashrefs.  Each hashref represents a required Perl module, and
has the following keys:

=over 4

=item name

B<Mandatory> Name of the module used.  The presence of this module is checked,
and an exception is raised if it does not exist.

=item package

B<Optional> Name of the package in which the module is to be found.  If not
defined, the package is assumed to be present in core Perl.

Modules that have been in core Perl since 5.005 need not be listed; the "core
perl" default is for modules such as C<Pod::Usage> which have been added to
the core since 5.005.

=item version

B<Optional> If supplied, the version of the module is checked against this
number, and an exception raised if the version found is lower than that
requested.

=item optional

B<Optional> If true, then failure to locate the package (or a suitable
version) is not an error, but will generate a warning message.

=item message

If supplied, then this message will be given to the user in case of failure.

=back

=item EXEC_REQS

=over 4

=item name

Name of the executable used.  The presence of this executable is checked, and
an exception is raised if it does not exist (in the PATH).

=item package

B<Optional> Name of the package in which the executable is to be found.

=item version

B<Optional> If supplied, the version of the module is checked against this
number, and an exception raised if the version found is lower than that
requested.

If supplied, the L<vopt> key must also be supplied.

=item vopt

B<Optional> This is used only if the C<version> key is also used.  This is the
option that is passed to the executable to ask for its version number.  It may
be the empty string if no option is used (but must be defined if C<version> is
defined).

=item vexpect

B<Optional> This is used only if the C<version> key is also used.  This is the
exit code to expect from the program when polling for its version number.
Defaults to 0.  This is the exit code (value of C<$?> in the shell) to use,
I<not> the value of the C<wait> call.

=item optional

B<Optional> If true, then failure to locate the package (or a suitable
version) is not an error, but will generate a warning message.

=item message

If supplied, then this message will be given to the user in case of failure.

=back

=item NAME

The module name.  It must conform to the established standard; in particular,
it must B<not> contain colon characters.  The usual process, when providing a
single-package module (e.g., to provide C<MIME::Base64>), is to replace the
C<::> occurences with hyphens (hence, C<MIME-Base64>).

=item VERSION_FROM

The module from which to establish the version number.  This module must have
a line of the form C<$VERSION = '0.01';>.  Declarative prefixes (.e.g, C<our>)
are fine; C<our> is the usual one, since C<$VERSION> is almost always a
package variable.

=item AUTHOR

The name of the module author(s), along with an email address.  This is
normally the person primarily responsible for the upkeep of the module.

=item ABSTRACT

A single (concise!) sentence describing the rough purpose of the module.  It
is not expected to be mightily accurate, but is for quick browsing of modules.

=cut

use Config                   qw( %Config );
use Env                      qw( @PATH );
use ExtUtils::MakeMaker 5.45 qw( WriteMakefile );
use File::Find               qw( find );
use File::Spec::Functions    qw( catfile );


# Constants ---------------------------

use constant TYPE_EXEC => 'executable';
use constant TYPE_MOD  => 'module';
use constant TYPES     => [ TYPE_EXEC, TYPE_MOD ];

use constant CONFIG =>
  {
   TYPE_MOD  , { defaults => { package => 'core perl',
                             },
                 find     => sub { eval "require $_[0]"; $@ eq '' },
                 vers     => sub {
                   no strict 'refs';
                   # Fool emacs indenter
                   my $_x = q={=; my $pv = ${"$_[0]::VERSION"};
                   return defined $pv ? $pv : -1;
                 },
               },
   TYPE_EXEC , { defaults => { vexpect => 0, },
                 find     => sub {
                   my ($name) = @_;
                   my $exec;
                 PATH_COMPONENT:
                   for my $path (@PATH) {
                     my $try = catfile $path, $name;
                     if ( -x $try ) {
                       $exec = $try;
                       last PATH_COMPONENT;
                     }
                   }
                   defined $exec;
                 },
                 vers     => sub {
                   my ($name, $vopt, $expect) = @_;
                   die "Cannot test version of $name without vopt\n"
                     unless defined $vopt;
                   my $cmd = join ' ', $name, $vopt;
                   my $vstr = qx($cmd 2>&1);
                   my $rv = $? >> 8;
                   die sprintf "Command $cmd exited with value: $rv\n"
                     if $rv != $expect;
                   if ( $vstr =~ /(?:^|\D)(\d+[\._]\d+)(?!\d)/ ) {
                     (my $version = $1) =~ tr/_/./;
                     return $version;
                   } else {
                     return -1;
                   }
                 },
               },
  };

# Subrs ----------------------------------------------------------------------

sub warn_missing {
  my ($missing) = @_;

  my ($type_max) = sort { $b <=> $a } map length $_->{type}, @$missing;
  my ($name_max) = sort { $b <=> $a } map length $_->{name}, @$missing;

  for (@$missing) {
    my ($type, $name, $pkg, $vers, $pv, $optional, $message) =
      @{$_}{qw( type name package vers_req vers_fnd optional message )};

    if ( defined $pv ) {
      print STDERR sprintf("%-${type_max}s %${name_max}s requires version " .
                           "$vers (found $pv)",
                           $type, $name)
    } else {
      print STDERR sprintf("Couldn't find %${type_max}s %${name_max}s",
                           $type, $name);
    }

    print STDERR " (from $pkg)"
      if defined $pkg;
    print STDERR "\n";

    print STDERR "  ...but this isn't fatal\n"
      if $optional;

    if ( defined $message ) {
      $message =~ s/(^|\n)/$1    /g;
      $message =~ s/([^\n])$/$1\n/;
      print STDERR "\n";
      print STDERR $message;
      print STDERR "\n";
    }
  }
}

# -------------------------------------

sub check {
  my ($items, $verbose) = @_;

  my ($type_max) = sort { $b <=> $a } map length, @{TYPES()};

  my @missing;

  foreach my $item (@$items) {
    my $type = $item->{type};
    my $defaults = CONFIG->{$type}->{defaults};
    $item->{$_} = $defaults->{$_}
      for grep ! exists $item->{$_}, keys %$defaults;
    my ($name, $pkg, $vers, $vopt, $vexpect) =
      @{$item}{qw( name package version vopt vexpect)};
    # Handle multiple '.'s in versions
    defined $vers && $vers  =~ s!\.(\d+)\.!.$1!g;

    printf STDERR "Checking for %${type_max}s %s...", $type, $name
      if $verbose;
    if ( CONFIG->{$type}->{find}->($name) ) {
      print STDERR " found\n"
        if $verbose;

      if ( defined $vers ) {
        my $vfound = CONFIG->{$type}->{vers}->($name, $vopt, $vexpect);

        push @missing, { type     => $type,
                         name     => $name,
                         package  => $pkg,
                         vers_req => $vers,
                         vers_fnd => $vfound,
                         optional => $item->{optional},
                         message  => $item->{message},
                       }
          if $vers > $vfound;
      }
    } else {
      print STDERR " failed\n"
        if $verbose;
      push @missing, { type     => $type,
                       name     => $name,
                       package  => $pkg,
                       vers_req => $vers,
                       optional => $item->{optional},
                       message  => $item->{message},
                     };
    }
  }

  return @missing;
}

# Main -----------------------------------------------------------------------

# Self Test

# Find Module (no version)
check([{ name => 'integer' , type => TYPE_MOD, }])
  and die "Internal Check (1) failed\n";
# Fail module (no version)
check([{ name => 'flubble' , type => TYPE_MOD, }])
  or die "Internal Check (2) failed\n";
# Find module, wrong version
check([{ name => 'IO'      , type => TYPE_MOD, version => '100.0', }])
  or die "Internal Check (3) failed\n";
# Find module, right version
check([{ name => 'IO'      , type => TYPE_MOD, version => '1.00',  }])
  and die "Internal Check (4) failed\n";

# Find exec (no version)
  # Use more (common to dog/windoze too!) (mac?)
check([{ name => 'more'    , type => TYPE_EXEC, }])
  and die "Internal Check (5) failed\n";
# Fail exec (no version)
check([{ name => ' wibwib' , type => TYPE_EXEC, }])
  or die "Internal Check (6) failed\n";

# Could do with one that works on dog/windoze/mac...
if ( $Config{osname} eq 'linux' ) {
  # Find exec, wrong version
  check([{ name => 'cut'     , type => TYPE_EXEC,
           version => '100.0', vopt => '--version', }])
    or die "Internal Check (7) failed\n";
  # Find exec, right version
  check([{ name => 'cut'     , type => TYPE_EXEC,
           version => '1.0', vopt => '--version', }])
    and die "Internal Check (8) failed\n";
}

# -------------------------------------

my @missing;

{
  no strict 'refs';
  die "$_ not defined\n"
    for grep ! defined *$_{CODE}, qw( MOD_REQS EXEC_REQS
                                      NAME VERSION_FROM AUTHOR ABSTRACT );
}

die sprintf(<<'END', NAME) unless NAME =~ /^[A-Za-z0-9-]+$/;
The module name:%s: is illegal (letters, numbers & hyphens only, please)
END

$_->{type} = TYPE_MOD
  for @{MOD_REQS()};
$_->{type} = TYPE_EXEC
  for @{EXEC_REQS()};

push @missing, check(MOD_REQS, 1), check(EXEC_REQS, 1);

warn_missing(\@missing);

exit 2
  for grep ! $_->{optional}, @missing;

my %pm;
find (sub {
        return unless /\.pm$/;
        (my $target = $File::Find::name) =~
          s/^$File::Find::topdir/\$(INST_LIBDIR)/;
        $pm{$File::Find::name} = $target;
      },
      'lib');

sub MY::postamble {
  <<EOF;
check: test
EOF
}

WriteMakefile
  (NAME         => NAME,
   VERSION_FROM => VERSION_FROM,
   AUTHOR       => AUTHOR,
   ABSTRACT     => ABSTRACT,
   PREREQ_PM    => { map (($_->{name} => $_->{version} || 0 ),
                          grep ! $_->{optional}, @{MOD_REQS()})},
   PM           => \%pm,
   EXE_FILES    => [ grep !/(?:CVS|~)$/, glob catfile (qw( bin * )) ],
  );

# ----------------------------------------------------------------------------

=head1 EXAMPLES

Z<>

=head1 BUGS

Z<>

=head1 REPORTING BUGS

Email the author.

=head1 AUTHOR

Martyn J. Pearce C<fluffy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2001, 2002 Martyn J. Pearce.  This program is free software; you
can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Z<>

=cut

1; # keep require happy

__END__
