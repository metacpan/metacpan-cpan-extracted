package Dist::Zilla::Plugin::Config::Git;

our $VERSION = '0.92'; # VERSION
# ABSTRACT: Plugin configuration containing settings for a Git repo

#############################################################################
# Modules

use Moose;
use MooseX::Types::Moose qw(Str ArrayRef RegexpRef);

with 'Dist::Zilla::Role::Plugin';

#############################################################################
# Regular Expressions (for subtypes)

### NOTE: Subtypes are responsible for using ^$ ###

# RegExp rule based on git-check-ref-format
my $valid_ref_name = qr%
   (?!
      # begins with
      /|                # (from #6)   cannot begin with /
      # contains
      .*(?:
         [/.]\.|        # (from #1,3) cannot contain /. or ..
         //|            # (from #6)   cannot contain multiple consecutive slashes
         @\{|           # (from #8)   cannot contain a sequence @{
         \\             # (from #9)   cannot contain a \
      )
   )
                        # (from #2)   (waiving this rule; too strict)
   [^\040\177 ~^:?*[]+  # (from #4-5) valid character rules

   # ends with
   (?<!\.lock)          # (from #1)   cannot end with .lock
   (?<![/.])            # (from #6-7) cannot end with / or .
%x;

# based mostly on git-clone
### XXX: While not technically valid, we're making \s illegal everywhere for sanity ###

my $valid_git_repo = qr%
   # standard ref name
   # XXX: This is probably wrong, but it works for now.
   $valid_ref_name|

   # valid URL (with standard git schemes)
   (?:
      (?:ssh|git|https?|ftps?|rsync|file)://   # scheme
      (?:[^\s@]+\@)?     # user
      [\w\d\.\[\]\:]+    # host/port
      /*\S+              # dir/file
   )|

   # non-scheme URL format
   (?:
      (?:[^\s@]+\@)?     # user
      [\w\d\.\[\]]+      # host
      :
      /*\S+              # dir/file
   )|

   # filename
   (?:
      (?:\.\.)?[\\/]+  # ../ or ..\ or / or \
      \S+              # (Thanks UNIX!)
   )
%x;

#############################################################################
# Subtypes

use MooseX::Types -declare => [qw(
   GitRepo
   GitBranch
)];

subtype GitRepo,
   as Str,
   where { /^$valid_git_repo$/ }
;

subtype GitBranch,
   as Str,
   where { /^$valid_ref_name$/ }
;
use namespace::clean;

#############################################################################
# Attributes

has remote => (
   is       => 'ro',
   isa      => GitRepo,
   default  => 'origin',
);

has local_branch => (
   is       => 'ro',
   isa      => GitBranch,
   default  => 'master',
);

has remote_branch => (
   is       => 'ro',
   isa      => GitBranch,
   lazy     => 1,
   default  => sub { shift->local_branch },
);

has allow_dirty => (
   is      => 'ro',
   isa     => ArrayRef[Str|RegexpRef],
   lazy    => 1,
   default => sub { [ 'dist.ini', shift->changelog ] },
);

has changelog => (
   is       => 'ro',
   isa      => Str,
   default  => 'Changes',
);

sub mvp_multivalue_args { qw(allow_dirty) }

#############################################################################
# Pre/post-BUILD

sub BUILDARGS {
   my ($class, @arg) = @_;
   my %copy = ref $arg[0] ? %{$arg[0]} : @arg;

   my $zilla = delete $copy{zilla};

   # Morph allow_dirty REs
   if (defined $copy{allow_dirty}) {
      my @new;
      my @allow_dirty = ref $copy{allow_dirty} ? @{ $copy{allow_dirty} } : ($copy{allow_dirty});
      foreach my $filespec (@allow_dirty) {
         if ($filespec =~ m!
            # Mimic a real Perl qr with delimiters
            ^qr(?:
               <.+>|\(.+\)|\[.+\]||\{.+\}|   # <>, (), [], {}
               ([^\w\s]).+\1                 # any non-word/space character
            )$
         !x) {
            my $re = substr($filespec, 3, -1);
            push @new, qr/$re/;
         }
         else {
            push @new, $filespec;
         }
      }

      $copy{allow_dirty} = \@new;
   }

   return {
      zilla => $zilla,
      %copy,
   };
}

42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Config::Git - Plugin configuration containing settings for a Git repo

=head1 SYNOPSIS

    [Config::Git / Git::main]
    remote        = origin
    local_branch  = master
    remote_branch = master
    allow_dirty   = dist.ini
    allow_dirty   = README
    allow_dirty   = qr{\w+\.ini}
    changelog     = Changes
 
    [Git::CheckFor::CorrectBranch]
    git_config = Git::main
 
    [@Git]
    git_config = Git::main
 
    ; etc.

=head1 DESCRIPTION

This is a configuration plugin for Git repoE<sol>branch information.  A configuration plugin is sort of like a Stash, but is better suited
for intra-plugin data sharing, using distro (not user) data.

Why use this?  To provide a standard set of information to other Git plugins easily, especially if the repo data is non-standard, or if
you need more than one set of data.

=for Pod::Coverage mvp_multivalue_args

=head1 OPTIONS

=head2 remote

Name of the remote repo, in standard Git repo format (refspec or git URL).

Default is C<<< origin >>>.

=head2 local_branch

Name of the local branch name.

Default is C<<< master >>>.

=head2 remote_branch

Name of the remote branch name.

Default is C<<< master >>>.

=head2 allow_dirty

Filenames of files in the local repo that are allowed to have modifications prior to a write action, such as a commit.  Multiple lines
are allowed.  Any strings in standard C<<< qr >>> notation are interpreted as regular expressions.

Default is C<<< dist.ini >>> and whatever L<changelog> is set to.

=head2 changelog

Name of your change log.

Default is C<<< Changes >>>.

=head1 ACKNOWLEDGEMENTS

Kent Fredric and Karen Etheridge for implementation discussion.  Graham Knop for continuous code reviews.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Dist-Zilla-Plugin-Config-Git>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Plugin::Config::Git/>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and talk to this person for help: SineSwiper.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests via L<https://github.com/SineSwiper/Dist-Zilla-Plugin-Config-Git/issues>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 CONTRIBUTOR

Graham Knop <haarg@haarg.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
