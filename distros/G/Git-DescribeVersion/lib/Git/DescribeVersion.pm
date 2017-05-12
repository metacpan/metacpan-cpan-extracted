# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Git-DescribeVersion
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Git::DescribeVersion;
{
  $Git::DescribeVersion::VERSION = '1.015';
}
# git description: v1.014-6-g81d7192

BEGIN {
  $Git::DescribeVersion::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: Use git-describe to show a repo's version

use Carp (); # core
use version 0.82 ();

our %Defaults = (
  first_version   => 'v0.1',
  match_pattern   => 'v[0-9]*',
  format      => 'decimal',
  version_regexp  => '([0-9._]+)'
);

# Git::Repository is easier to install than Git::Wrapper
my @delegators = qw(
  git_repository
  git_wrapper
  git_backticks
);


sub new {
  my $class = shift;
  # accept a hash or hashref
  my %opts = ref($_[0]) ? %{$_[0]} : @_;
  my $self = {
    %Defaults,
    # restrict accepted arguments
    map { $_ => $opts{$_} } grep { exists($opts{$_}) } keys %Defaults
  };

  $self->{directory} = $opts{directory} || '.';
  bless $self, $class;

  # accept a Git::Repository or Git::Wrapper object (or command to exec)
  # or a simple '1' (true value) to indicate which one is desired
  foreach my $mod ( @delegators ){
    if( $opts{$mod} ){
      $self->{git} = $mod;
      # if it's just a true value leave it blank so we create later
      # TODO: should this be checking ref?
      $self->{$mod} = $opts{$mod}
        unless $opts{$mod} eq '1';
      # test that requested method "works"
      eval { $self->$mod('--version') };
      if( $@ ){
        Carp::carp qq[Failed to execute $mod (will attempt other methods): $@];
        delete @$self{(git => $mod)};
      }
    }
  }
  return $self;
}


sub format_version {
  my ($self, $vobject) = @_;
  my $format = $self->{format} =~ /dot|normal|v|string/ ? 'normal' : 'numify';
  my $version = $vobject->$format;
  $version =~ s/^v// if $self->{format} =~ /no.?v/;
  return $version;
}


# NOTE: the git* subs are called in list context

sub git {
  my ($self) = @_;
  unless( $self->{git} ){
    for my $method ( @delegators ){
      $self->{git} ||= eval {
        # confirm method works (without dying)
        $self->$method('--version');
        $method;
      };
    }
    Carp::croak("All git methods failed.  Is `git` installed?\n".
      "Consider installing Git::Repository or Git::Wrapper.\n")
      unless $self->{git};
  }
  goto &{$self->{git}};
}

sub git_backticks {
  my ($self, $command, @args) = @_;
  warn("'directory' attribute not supported when using backticks.\n" .
    "Consider installing Git::Repository or Git::Wrapper.\n")
      if $self->{directory} && $self->{directory} ne '.';

  @args = map { ref $_ ? @$_ : $_ } @args;

  @args = map { quotemeta } @args
    unless $^O eq 'MSWin32';

  my $exec = join(' ',
      # the external app to run
      ($self->{git_backticks} ||= 'git'),
      $command,
      @args
  );

  return (`$exec`);
}

sub git_repository {
  my ($self, $command, @args) = @_;
  # Git::Repository 1.22 fails with alternate $/ (rt-71621)
  local $/ = "\n";
  (
    $self->{git_repository} ||=
    do {
      require Git::Repository;
      Git::Repository->new(work_tree => $self->{directory})
    }
  )
    ->run($command,
      map { ref $_ ? @$_ : $_ } @args
    );
}

sub git_wrapper {
  my ($self, $command, @args) = @_;
  $command =~ tr/-/_/;
  (
    $self->{git_wrapper} ||=
    do {
      require Git::Wrapper;
      Git::Wrapper->new($self->{directory})
    }
  )
    ->$command({
      map { ($$_[0] =~ /^-{0,2}(.+)$/, $$_[1]) }
        map { ref $_ ? $_ : [$_ => 1] } @args
    });
}



sub parse_version {
  my ($self, $prefix, $count) = @_;

  # This is unlikely as it should mean that both git commands
  # returned unexpected output.  If it does happen, don't die
  # trying to parse it, default to first_version.
  $prefix = $self->{first_version}
    unless defined $prefix;
  $count ||= 0;

  # If still undef (first_version explicitly set to undef)
  # don't die trying to parse it, just return nothing.
  unless( defined $prefix ){
    warn("Version could not be determined.\n");
    return;
  }

  # s//$1/ requires the regexp to be anchored.
  # Doing a match and then assigning to $1 does not.
  if( $self->{version_regexp} && $prefix =~ /$self->{version_regexp}/ ){
    $prefix = $1;
  }

  my $vstring = "v$prefix.$count";

  # quote 'version' to reference the module and not call the local sub
  my $vobject = eval {
    # don't even try to parse it if it doesn't look like a version
    'version'->parse($vstring)
      if version::is_lax($vstring);
  };

  # Don't die if it's not parseable, just return nothing.
  if( my $error = $@ || !$vobject ){
    $error = $self->prepare_warning($error);
    warn("'$vstring' is not a valid version string.\n$error");
    return;
  }

  return $self->format_version($vobject);
}

# normalize error message

sub prepare_warning {
  my ($self, $error) = @_;
  return '' unless $error;
  $error =~ s/ at \S+?\.pm line \d+\.?\s*$//;
  chomp($error);
  return $error . "\n";
}


sub version {
  my ($self) = @_;
  return $self->version_from_describe() ||
    $self->version_from_count_objects();
}


sub version_from_describe {
  my ($self) = @_;
  my ($ver) = eval {
    $self->git('describe',
      ['--match' => $self->{match_pattern}], qw(--tags --long)
    );
  };
  # usually you'll expect a tag to be found, so warn if it isn't
  if( my $error = $@ ){
    $error = $self->prepare_warning($error);
    warn("git-describe: $error");
  }

  # return nothing so we know to move on to count-objects
  return unless $ver;

  # ignore the -gSHA
  my ($tag, $count) = ($ver =~ /^(.+?)-(\d+)-(g[0-9a-f]+)$/);

  return $self->parse_version($tag, $count);
}


sub version_from_count_objects {
  my ($self) = @_;
  my @counts = $self->git(qw(count-objects -v));
  my $count = 0;
  local $_;
  foreach (@counts){
    /(count|in-pack): (\d+)/ and $count += $2;
  }
  return $self->parse_version($self->{first_version}, $count);
}

1;


__END__
=pod

=encoding utf-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS repo repo's todo cpan testmatrix url
annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata
placeholders metacpan

=head1 NAME

Git::DescribeVersion - Use git-describe to show a repo's version

=head1 VERSION

version 1.015

=head1 SYNOPSIS

  use Git::DescribeVersion ();
  print Git::DescribeVersion->new({opt => 'value'})->version();

=head1 DESCRIPTION

Use C<git describe> to determine a git repo's version.

This is the main module,
though it's probably more useful run from the shell:

  $ git describe-version

The included C<git-describe-version> script
wraps L<Git::DescribeVersion::App>.

B<NOTE>: This module requires git version C<1.5.5> or greater.

The version is determined by counting the commits since the most recent tag
(matching the L</match_pattern>)
and using that count as the final part of the version.

So to create a typical three part version (C<v1.2.3>)
repo tags should be made of the first two parts (C<v1.2>)
and the number of commits counted by C<git-describe>
will become the third part (C<v1.2.35>).

=head1 METHODS

=head2 new

The constructor accepts a hash or hashref of options:

  Git::DescribeVersion->new({opt => 'value'});
  Git::DescribeVersion->new(opt1 => 'v1', opt2 => 'v2');

See L</OPTIONS> for an explanation of the available options.

=head2 format_version

Format the supplied version object
according to the L</format> attribute.

=head2 git

A method to wrap the git commands.
Attempts to use L<Git::Repository> or L<Git::Wrapper>.
Falls back to using backticks.

=head2 parse_version

A method to take the version parts found and return the end result.

Uses the L<version|version> module to parse.

=head2 version

The C<version> method is the main method of the class.
It attempts to return the repository version.

It will first use L</version_from_describe>.

If that fails it will try to simulate
the functionality with L</version_from_count_objects>
and will start the count from the L</first_version> option.

=head2 version_from_describe

Use C<git-describe> to count the number of commits since the last
tag matching L</match_pattern>.

It effectively calls

  git describe --match "${match_pattern}" --tags --long

If no matching tags are found (or some other error occurs)
it will return undef.

=head2 version_from_count_objects

Use C<git-count-objects> to count the number of commit objects
in the repository.  It then appends this count to L</first_version>.

It effectively calls

  git count-objects -v

and sums up the counts for 'count' and 'in-pack'.

=for Pod::Coverage git_backticks git_repository git_wrapper prepare_warning

=head1 OPTIONS

These options can be passed to L</new>:

=head2 directory

Directory in which git should operate.  Defaults to ".".

=head2 first_version

If the repository has no tags at all, this version
is used as the first version for the distribution.

Then git objects will be counted
and appended to create a version like C<v0.1.5>.

If set to C<undef> then L</version> will return undef
if L</version_from_describe> cannot determine a value.

Defaults to C<< v0.1 >>.

=head2 format

Specify the output format for the version number.

I had trouble determining the most reasonable names
for the formats so a few variations are possible.
(Pick the one which makes the most sense to you.)

=over 4

=item *

I<dotted>, I<normal>, I<v-string> or I<v>

for values like C<< v1.2.3 >>.

=item *

I<no-v-string> (or I<no-v> or I<no_v>)

to discard the opening C<v> for values like C<< 1.2.3 >>.

=item *

I<decimal>

for values like C<< 1.002003 >>.

=back

Defaults to I<decimal> for compatibility.

=head2 version_regexp

Regular expression that matches a tag containing
a version.  It must capture the version into C<$1>.

Defaults to C<< ([0-9._]+) >>
which will simply capture the first dotted-decimal found.
This matches tags like C<v0.1>, C<rev-1.2>
and even C<release-2.0-skippy>.

=head2 match_pattern

A shell-glob-style pattern to match tags.
This is passed to C<git-describe> to help it
find the right tag from which to count commits.

Defaults to C<< v[0-9]* >>.

=head1 HISTORY / RATIONALE

This module started out as a line in a Makefile:

  VERSION = $(shell (cd $(srcdir); \
    git describe --match 'v[0-9].[0-9]' --tags --long | \
    grep -Eo 'v[0-9]+\.[0-9]+-[0-9]+' | tr - . | cut -c 2-))

As soon as I wanted it in another Makefile
(in another repository) I knew I had a problem.

Then when I started learning L<Dist::Zilla>
I found L<Dist::Zilla::Plugin::Git::NextVersion>
but missed the functionality I was used to with C<git-describe>.

I started by forking L<Dist::Zilla::Plugin::Git> on github,
but realized that if I wrote the logic into a L<Dist::Zilla> plugin
it wouldn't be available to my git repositories that weren't Perl distributions.

So I wanted to extract the functionality to a module,
make a separate L<Dist::Zilla::Role::VersionProvider> plugin,
and include a quick version that could be run with a minimal
command line statement (so that I could put I<that> in my Makefiles).

=head1 TODO

=over 4

=item *

Allow using git-log to count commits affecting a subdirectory

=item *

Allow for more complex regexps (multiple groups) if there is a need.

=item *

Options for raising errors versus swallowing them?

=item *

Consider a dynamic installation to test C<`git --version`>.

=back

=head1 SEE ALSO

=over 4

=item *

L<Git::DescribeVersion::App>

=item *

L<Dist::Zilla::Plugin::Git::DescribeVersion>

=item *

L<Git::Repository> or L<Git::Wrapper>

=item *

L<http://www.git-scm.com>

=item *

L<version>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Git::DescribeVersion

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Git-DescribeVersion>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Git-DescribeVersion>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Git-DescribeVersion>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/G/Git-DescribeVersion>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Git-DescribeVersion>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Git::DescribeVersion>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-git-describeversion at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Git-DescribeVersion>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Git-DescribeVersion>

  git clone https://github.com/rwstauner/Git-DescribeVersion.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

