package Langertha::Raider::Permissions::ReadOnlyBash;
# ABSTRACT: Internal fixed allowlist of read-only bash commands for the auto permission mode
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Langertha::Raider::Permissions::Rule;


my %PLAIN = map { $_ => 1 } qw(
  ls pwd cat head tail wc echo which uname whoami id basename dirname
  realpath readlink stat du df cut tr nl diff sha256sum sha1sum md5sum cksum
  jq ps uptime nproc cd true false
);

my %GIT_PLAIN = map { $_ => 1 } qw(
  status diff log show blame describe shortlog rev-parse ls-files ls-tree cat-file
);
my @GIT_LONG = qw( output ext-diff open-files-in-pager textconv exec-path );

# Flags with which these only list.
my %GIT_LIST = (
  branch => qr/\A(?:-a|-r|-v|-vv|-l|--all|--remotes|--verbose|--list|--show-current|--contains|--no-contains|--merged|--no-merged|--sort=[\w-]+)\z/,
  remote => qr/\A(?:-v|--verbose)\z/,
  tag    => qr/\A(?:-l|--list|-n\d*|--sort=[\w-]+|--contains|--no-contains|--merged|--no-merged)\z/,
);

my $GREP_REFUSE = qr/\A(?:--(?:pre|pre-glob|hostname-bin)(?:=.*)?|-z|--search-zip)\z/;
my $FIND_REFUSE = qr/\A-(?:exec|execdir|ok|okdir|delete|fprint|fprint0|fprintf|fls)\z/;
my $DATE_OK     = qr/\A(?:\+.*|-u|--utc|--universal|-R|--rfc-email|-I.*|--iso-8601(?:=.*)?|-d|-r)\z/;

# One word: a redirection that writes nothing, plain characters, or a quoted
# string that expands nothing.
my $WORD = qr{
    (?:\d|&)?>/dev/null
  | \d?>&\d
  | [A-Za-z0-9_\@%+=:,./~^{}*?\[\]-]+
  | '[^']*'
  | "[^"\$`\\]*"
}x;

sub covers {
  my ( $class, $command ) = @_;
  return 0 unless defined $command && !ref $command;
  my $shell = Langertha::Raider::Permissions::Rule->shell_parts($command);
  return 0 if $shell->{opaque} || !@{ $shell->{parts} };
  for my $part ( @{ $shell->{parts} } ) {
    return 0 unless $class->part_covered($part);
  }
  return 1;
}


sub part_covered {
  my ( $class, $part ) = @_;
  return 0 unless defined $part;
  my $s = $part;
  $s =~ s/\A\s+//;
  return 0 unless $s =~ s/\A($WORD)//;
  my $cmd = $1;
  my @words;
  push @words, $1 while $s =~ s/\A\s+($WORD)//;
  return 0 if length $s && $s !~ /\A\s*\z/;
  return 0 unless $cmd =~ /\A[a-z][a-z0-9-]*\z/;
  my @args = grep { !/\A(?:\d|&)?>/ } map { $class->_unquote($_) } @words;    # not the redirections to /dev/null

  return 1 if $PLAIN{$cmd};
  return ( grep { !/\A-/ } @args ) <= 1 ? 1 : 0 if $cmd eq 'uniq';
  return ( grep { /\A-[A-Za-z]*o/ || $class->_long_of( $_, qw( output compress-program ) ) } @args ) ? 0 : 1
    if $cmd eq 'sort';
  return ( grep { $_ =~ $GREP_REFUSE } @args ) ? 0 : 1 if $cmd =~ /\A(?:grep|egrep|fgrep|rg)\z/;
  return ( grep { $_ =~ $FIND_REFUSE } @args ) ? 0 : 1 if $cmd eq 'find';
  return $class->_date_ok(@args) if $cmd eq 'date';
  if ( $cmd eq 'git' ) {
    my ( $sub, @rest ) = @args;
    return 0 unless defined $sub;
    return ( grep { /\A-O/ || $class->_long_of( $_, @GIT_LONG ) } @rest ) ? 0 : 1 if $GIT_PLAIN{$sub};
    if ( my $ok = $GIT_LIST{$sub} ) {
      return ( grep { $_ !~ $ok } @rest ) ? 0 : 1;
    }
    return 0;
  }
  return 0;
}

# True when $arg is --NAME, --NAME=x or an abbreviation of one of the long
# options (getopt_long accepts any unambiguous prefix).
sub _long_of {
  my ( $class, $arg, @long ) = @_;
  return 0 unless $arg =~ /\A--([^=]+)(?:=.*)?\z/s;
  my $name = $1;
  return ( grep { index( $_, $name ) == 0 } @long ) ? 1 : 0;
}

# date shows a time; a bare word would set it (MMDDhhmm), so only the display
# flags, a +FORMAT and the value of -d / -r are accepted.
sub _date_ok {
  my ( $class, @args ) = @_;
  my $value = 0;
  for my $a (@args) {
    if ($value) { $value = 0; next }
    if ( $a =~ /\A--(?:date|reference)=/ ) { next }
    if ( $a eq '--date' || $a eq '--reference' ) { $value = 1; next }
    return 0 unless $a =~ $DATE_OK;
    $value = 1 if $a eq '-d' || $a eq '-r';
  }
  return $value ? 0 : 1;
}

sub _unquote {
  my ( $class, $w ) = @_;
  return $1 if $w =~ /\A'(.*)'\z/s || $w =~ /\A"(.*)"\z/s;
  return $w;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Permissions::ReadOnlyBash - Internal fixed allowlist of read-only bash commands for the auto permission mode

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $class = 'Langertha::Raider::Permissions::ReadOnlyBash';
    $class->covers('git status && ls -la');     # 1
    $class->covers('git status; rm x');         # 0
    $class->covers('cat $(which x)');           # 0
    $class->covers('ls > f');                   # 0

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The one place that knows which bash commands the C<auto> permission mode
(ADR 0021, Nachtrag P2) runs without asking. A command is covered only when
B<every> part of it (split as L<Langertha::Raider::Permissions::Rule/shell_parts>
splits: at C<&&>, C<||>, C<;>, C<|>, C<&>, newlines and parentheses) is one
of the commands below, and the command as a whole holds no substitution,
heredoc, redirection into a file (C</dev/null> and C<< 2>&1 >> are fine) or
open quote. The list is fixed and not configurable: a project that wants
more writes allow rules.

A part is C<COMMAND ARG...> where C<COMMAND> is on the list, written
without a path, wrapper or C<VAR=value> before it, and every C<ARG> is a
plain word (letters, digits and C<_@%+=:,./~^{}*?[]->) or a quoted string
without C<$>, backticks or backslashes. Nothing is expanded that could run
code. The list:

=over

=item * Always read-only: C<ls pwd cat head tail wc echo which uname whoami id
basename dirname realpath readlink stat du df cut tr nl diff sha256sum sha1sum
md5sum cksum jq ps uptime nproc cd true false>.

=item * C<date> to show a time (C<+FORMAT>, C<-u>, C<-R>, C<-I>, C<-d STRING>,
C<-r FILE>), never to set it; C<uniq> with at most one file argument (the
second would be written); C<sort> without C<-o> / C<--output> /
C<--compress-program>.

=item * C<grep egrep fgrep rg> without C<--pre>, C<--pre-glob>,
C<--hostname-bin>, C<-z>, C<--search-zip> (these run other programs).

=item * C<find> without C<-exec>, C<-execdir>, C<-ok>, C<-okdir>, C<-delete>,
C<-fprint>, C<-fprint0>, C<-fprintf>, C<-fls>.

=item * C<git> directly followed by C<status>, C<diff>, C<log>, C<show>,
C<blame>, C<describe>, C<shortlog>, C<rev-parse>, C<ls-files>, C<ls-tree>,
C<cat-file> -- no global options (C<-c>, C<-C>, C<--exec-path>) before the
subcommand, and no C<--output>, C<--ext-diff>, C<--open-files-in-pager>,
C<--textconv>, C<--exec-path> (nor an abbreviation of one, which git
accepts); and C<git branch> / C<git remote> / C<git tag> only in their
listing forms.

=back

What stays open, as with any allowlist: git runs what the repository's own
configuration names (a pager, C<core.fsmonitor>, a textconv filter). The mode
trusts the repository the way C<acceptEdits> trusts the root.

=head2 covers

    my $yes = Langertha::Raider::Permissions::ReadOnlyBash->covers($command);

True when every part of the command is on the list and the command holds no
substitution, heredoc, redirection into a file or open quote. Callable on
the class.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Permissions>

=item * L<Langertha::Raider::Permissions::Rule>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

L<https://raudssus.de/>

=cut
