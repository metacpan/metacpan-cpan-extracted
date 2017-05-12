use strict;
use warnings;
package Dist::Zilla::Plugin::CheckChangesHasContent;
# ABSTRACT: Ensure Changes has content before releasing
our $VERSION = '0.010';

# Dependencies
use Dist::Zilla 2.100950 (); # XXX really the next release after this date
use autodie 2.00;
use File::pushd 0 ();
use Moose 0.99;
use namespace::autoclean 0.09;

# extends, roles, attributes, etc.

with 'Dist::Zilla::Role::BeforeRelease';

has changelog => (
  is => 'ro',
  isa => 'Str',
  default => 'Changes'
);

has trial_token => (
  is => 'ro',
  isa => 'Str',
  default => '-TRIAL'
);

# methods

sub before_release {
  my $self = shift;
  my $changes_file = $self->changelog;
  my $newver = $self->zilla->version;

  $self->log("Checking Changes");

  $self->zilla->ensure_built_in;

  # chdir in
  my $wd = File::pushd::pushd($self->zilla->built_in);

  if ( ! -e $changes_file ) {
    $self->log_fatal("No $changes_file file found");
  }
  elsif ( $self->_get_changes ) {
    $self->log("$changes_file OK");
  }
  else {
    $self->log_fatal("$changes_file has no content for $newver");
  }

  return;
}

# _get_changes copied and adapted from Dist::Zilla::Plugin::Git::Commit
# by Jerome Quelin
sub _get_changes {
    my $self = shift;

    # parse changelog to find commit message
    my $changelog = Dist::Zilla::File::OnDisk->new( { name => $self->changelog } );
    my $newver    = $self->zilla->version;
    my $trial_token = $self->trial_token;
    my @content   =
        grep { /^$newver(?:$trial_token)?(?:\s+|$)/ ... /^\S/ } # from newver to un-indented
        split /\n/, $changelog->content;
    shift @content; # drop the version line
    # drop unindented last line and trailing blank lines
    pop @content while ( @content && $content[-1] =~ /^(?:\S|\s*$)/ );

    # return number of non-blank lines
    return scalar @content;
} # end _get_changes

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CheckChangesHasContent - Ensure Changes has content before releasing

=head1 VERSION

version 0.010

=head1 SYNOPSIS

  # in dist.ini

  [CheckChangesHasContent]

=head1 DESCRIPTION

This is a "before release" Dist::Zilla plugin that ensures that your Changes
file actually has some content since the last release.  If it doesn't find any,
it will abort the release process.

This can be contrasted to L<Dist::Zilla::Plugin::Test::ChangesHasContent>, which
generates a test to perform the check.

The algorithm is very naive.  It looks for an unindented line starting with
the version to be released.  It then looks for any text from that line until
the next unindented line (or the end of the file), ignoring whitespace.

For example, in the file below, algorithm will find "- blah blah blah":

  Changes file for Foo-Bar

  {{$NEXT}}

    - blah blah blah

  0.001  Wed May 12 13:49:13 EDT 2010

    - the first release

If you had nothing but whitespace between C<{{$NEXT}}> and C<0.001>,
the release would be halted.

If you name your change log something other than "Changes", you can configure
the name with the C<changelog> argument:

  [CheckChangesHasContent]
  changelog = ChangeLog

=for Pod::Coverage before_release

=head1 SEE ALSO

* L<Dist::Zilla::Plugin::Test::ChangesHasContent>
* L<Dist::Zilla>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Dist-Zilla-Plugin-CheckChangesHasContent/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Dist-Zilla-Plugin-CheckChangesHasContent>

  git clone https://github.com/dagolden/Dist-Zilla-Plugin-CheckChangesHasContent.git

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords David Golden Randy Stauner

=over 4

=item *

David Golden <xdg@xdg.me>

=item *

Randy Stauner <randy@magnificent-tears.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
