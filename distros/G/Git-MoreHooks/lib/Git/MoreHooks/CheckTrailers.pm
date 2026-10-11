package Git::MoreHooks::CheckTrailers;

use strict;
use warnings;

# ABSTRACT: GitHooks plugin to enforce a commit message trailer policy

our $VERSION = '0.020';

use utf8;
use Encode   qw( encode );
use English  qw( -no_match_vars );
use Log::Any qw( $log );
use Git::Hooks 4.0;
use List::Util qw( any first );
use Path::Tiny qw( path );

my $PKG = __PACKAGE__;
my $CFG = __PACKAGE__ =~ s/.*::/githooks./rmsx;

# The kinds of commit which may be exempted from the 'require' check.
my @KINDS = qw( merge revert fixup );

# Reported at most once per process, however many commits a push carries.
my $announced_no_interpret_trailers = 0;

#############
# Grok hook configuration, check it and set defaults.

sub _setup_config {
    my ($git) = @_;

    # Drop anything parsed from a previous call. A hook process calls this once,
    # but a test (or any caller exercising several configurations through one
    # repository object) calls it again after changing the configuration, and a
    # cache that outlived the change would answer for the old one.
    delete $git->cache('checktrailers')->{'specs'};

    my $config = $git->get_config();
    $config->{ lc $CFG } //= {};
    my $default = $config->{ lc $CFG };

    # NO trailer names are defaulted. An unconfigured plugin does nothing: the
    # spelling of a disclosure trailer is not settled across projects, so every
    # repository names its own.
    $default->{'deny'}         //= [];
    $default->{'require'}      //= [];
    $default->{'order'}        //= [];
    $default->{'deny-in-body'} //= ['false'];
    $default->{'require-skip'} //= [@KINDS];

    my $errors = 0;

    # Report a broken specification once, here, rather than per commit.
    foreach my $option (qw( deny require )) {
        foreach my $spec ( $git->get_config( $CFG => $option ) ) {
            my ( undef, $why ) = _parse_spec($spec);
            next if !defined $why;
            $git->fault( "Cannot understand a $option specification: $why",
                { prefix => $PKG, option => $option, details => $spec } );
            $errors++;
        }
    }

    foreach my $kind ( $git->get_config( $CFG => 'require-skip' ) ) {
        next if $kind eq 'none';
        next if any { $_ eq $kind } @KINDS;
        $git->fault( 'Unknown require-skip value. It must be one of: ' . ( join q{, }, @KINDS, 'none' ),
            { prefix => $PKG, option => 'require-skip', details => $kind } );
        $errors++;
    }

    # A token in both lists can never be satisfied.
    my %denied;
    foreach my $spec ( $git->get_config( $CFG => 'deny' ) ) {
        my ($parsed) = _parse_spec($spec);
        next if !defined $parsed;
        next if !defined $parsed->{'token'};
        $denied{ lc $parsed->{'token'} } = 1;
    }

    foreach my $spec ( $git->get_config( $CFG => 'require' ) ) {
        my ($parsed) = _parse_spec($spec);
        next if !defined $parsed;
        my $token = $parsed->{'token'};
        next if !defined $token;
        next if !$denied{ lc $token };
        $git->fault( "The trailer '$token' is both denied and required, which no commit message can satisfy.",
            { prefix => $PKG, option => 'require', details => $spec } );
        $errors++;
    }

    $log->debugf( "$PKG: configuration has %d problem(s)", $errors );
    return;
}

# One field of a specification: either qr<delim>...<delim> or a bare trailer
# token. Returns ( $matcher, $literal_token_or_undef, $error_or_undef ).
#
# Both are compiled case-insensitively and with nothing else. A field carrying
# trailing flags (qr/x/msx) does not end in its own delimiter, so it falls
# through to the token branch and is reported as a configuration error rather
# than silently losing the flags. Somebody wanting other flags writes
# qr/(?x: ... )/.
my %CLOSER = ( '{' => '}', '(' => ')', '[' => ']', '<' => '>' );

sub _parse_field {
    my ($field) = @_;

    # qr<delim>...<delim>, with the paired delimiters spelled the usual way.
    # A field carrying trailing flags does not end in its own closing
    # delimiter, so it falls through to the token branch and is reported rather
    # than silently losing them.
    if ( my ( $open, $pattern, $closer ) = $field =~ m/\Aqr(.)(.*)(.)\z/msx ) {
        if ( $closer eq ( $CLOSER{$open} // $open ) ) {
            ## no critic (RegularExpressions::RequireDotMatchAnything) -- a user pattern; /s would change what their regex means
            ## no critic (RegularExpressions::RequireExtendedFormatting) -- likewise for /x, which would make their whitespace vanish
            ## no critic (RegularExpressions::RequireLineBoundaryMatching) -- and likewise for /m
            my $matcher = eval { qr/$pattern/i };
            return ( undef, undef, "the regular expression qr/$pattern/ does not compile", 1 )
              if !defined $matcher;
            return ( $matcher, undef, undef, 1 );
        }
    }

    # A bare token, held to git's own trailer-token character set.
    if ( my ($token) = $field =~ m/\A([[:alnum:]][[:alnum:]-]*)\z/msx ) {
        return ( qr/\A\Q$token\E\z/imsx, $token, undef, 0 );
    }

    return ( undef, undef, "'$field' is neither a trailer token nor a qr// pattern", 0 );
}

# TOKENMATCH [whitespace VALUEMATCH].
#
# Split on whitespace first: a trailer token can never contain any, so a token
# pattern that did could never match a real trailer, and splitting first makes
# each field's qr// unambiguous to parse.
sub _parse_spec {
    my ($spec) = @_;

    return ( undef, 'the specification is empty' ) if !defined $spec || $spec !~ m/\S/msx;

    my $trimmed = $spec;
    $trimmed =~ s/\A\s+//msx;
    $trimmed =~ s/\s+\z//msx;

    my ( $token_field, $value_field ) = split /\s+/msx, $trimmed, 2;

    my ( $token_re, $token, $token_error ) = _parse_field($token_field);
    return ( undef, $token_error ) if defined $token_error;

    my $value_re;
    if ( defined $value_field ) {
        my ( $matcher, undef, $value_error, $was_pattern ) = _parse_field($value_field);

        # A broken qr// is an error: somebody wrote a pattern and meant it, so
        # quietly matching their regex source as a literal string would be the
        # worst of both. Anything that is not a pattern at all is a literal
        # substring, which is what most value matches want to be.
        return ( undef, $value_error ) if defined $value_error && $was_pattern;
        if ( defined $value_error ) {
            $matcher = qr/\Q$value_field\E/imsx;
        }
        $value_re = $matcher;
    }

    return ( { raw => $spec, token => $token, token_re => $token_re, value_re => $value_re }, undef );
}

# The parsed specifications, cached per repository object so that a push of many
# commits parses the configuration once.
sub _specs {
    my ($git) = @_;

    my $cache = $git->cache('checktrailers');
    return $cache->{'specs'} if exists $cache->{'specs'};

    my %specs = ( deny => [], require => [], order => [] );
    foreach my $option (qw( deny require )) {
        foreach my $spec ( $git->get_config( $CFG => $option ) ) {
            my ($parsed) = _parse_spec($spec);

            # A broken specification is already reported by _setup_config, which
            # fails the hook; skip it here rather than complain twice.
            next if !defined $parsed;
            push @{ $specs{$option} }, $parsed;
        }
    }

    foreach my $token ( $git->get_config( $CFG => 'order' ) ) {
        push @{ $specs{'order'} }, $token;
    }

    $specs{'deny_in_body'} = $git->get_config_boolean( $CFG => 'deny-in-body' ) ? 1 : 0;
    $specs{'skip'}         = { map { $_ => 1 } $git->get_config( $CFG => 'require-skip' ) };

    $cache->{'specs'} = \%specs;
    return $cache->{'specs'};
}

sub _commit_encoding {
    my ($git) = @_;
    return $git->get_config( i18n => 'commitEncoding' ) || 'utf-8';
}

sub _paragraphs {
    my ($msg) = @_;
    return split /\n{2,}/msx, $msg;
}

# THE TRAILERS, AS GIT ITSELF READS THEM.
#
# Not Git::Message, which CheckLog uses: its footer parser accepts the final
# block only when EVERY line of it is a trailer, so a body line above the
# trailers, a space before a colon, or a folded value all make it report no
# trailers at all. Git parses those messages fine and the forges mint a
# contributor from them, so believing Git::Message would mean missing exactly
# the commits this plugin exists to catch -- the GitHub squash-merge shape among
# them, since "Squash and merge" collects Co-authored-by from what it squashes.
#
# `--parse` is `--only-trailers --only-input --unfold`. `--only-input` matters:
# without it a repository's own trailer.* configuration could add trailers that
# are not in the message, and we would reject a commit for something nobody
# wrote.
sub _trailers {
    my ( $git, $msg ) = @_;

    my @paragraphs = _paragraphs($msg);
    return [] if scalar @paragraphs < 2;

    # No subprocess for the common case. `^` with /m, not `\A`: the trailer need
    # not be the first line of its paragraph.
    return [] if $paragraphs[-1] !~ m/^[[:alnum:]][[:alnum:]-]*[ \t]*:/msx;

    my $out = eval { $git->run( qw( interpret-trailers --parse ), { input => $msg } ) };
    if ( !defined $out ) {
        my $error = $EVAL_ERROR;
        if ( !$announced_no_interpret_trailers ) {
            $announced_no_interpret_trailers = 1;
            $git->fault(
                'Cannot read the commit message trailers. `git interpret-trailers --parse` failed, '
                  . 'so this plugin cannot tell whether the message complies.',
                { prefix => $PKG, details => $error }
            );
        }
        return [];
    }

    my @trailers;
    foreach my $line ( split /\n/msx, $out ) {
        if ( my ( $token, $trailer_value ) = $line =~ m/\A([^:]+):[ ]?(.*)\z/msx ) {
            push @trailers, { token => $token, value => $trailer_value };
        }
    }

    $log->debugf( "$PKG: git reads %d trailer(s)", scalar @trailers );
    return \@trailers;
}

# Lines that LOOK like a trailer and that git did not return.
#
# git does not read these as trailers, so they create no false attribution yet.
# They will the moment the message is reflowed, squash-merged, or gains a
# Signed-off-by -- and the same scan is what lets the 'require' check say
# "you wrote it, but not where git can see it", which is the message that saves
# somebody a puzzled quarter of an hour.
#
# The final paragraph only, by default: the title is never a trailer block, and
# widening to the whole body starts matching prose. The commit that adds a
# deny rule to a repository will discuss the forbidden token in prose.
sub _suspect_lines {
    my ( $git, $msg, $trailers ) = @_;

    # Everything after the TITLE, which is the first line -- not after the first
    # paragraph. A trailer written with no blank line above it shares the title's
    # paragraph, and that shape is one of the ones worth catching: git does not
    # read it as a trailer, so it is invisible to the authoritative source.
    my $body = $msg;
    $body              =~ s/\A[^\n]*\n?//msx;
    $body              =~ s/\A\n+//msx;
    return [] if $body !~ m/\S/msx;

    my @paragraphs = _paragraphs($body);
    my @scope      = _specs($git)->{'deny_in_body'} ? @paragraphs : ( $paragraphs[-1] );

    my @suspects;
    foreach my $paragraph (@scope) {
        foreach my $line ( split /\n/msx, $paragraph ) {
            if ( my ( $token, $trailer_value ) = $line =~ m/\A([[:alnum:]][[:alnum:]-]*)[ \t]*:[ \t]*(.*)\z/msx ) {
                next if _accounted_for( $trailers, $token, $trailer_value );
                push @suspects, { token => $token, value => $trailer_value, line => $line };
            }
        }
    }
    return \@suspects;
}

# Is this line one git already told us about?
#
# Not simply equality: `--parse` unfolds, so a trailer written over two lines
# comes back with the continuation appended, and the raw first line's value is
# then a prefix of it. Without allowing for that, every folded trailer would be
# reported as a suspect line as well as a real one.
sub _accounted_for {
    my ( $trailers, $token, $trailer_value ) = @_;

    foreach my $trailer ( @{$trailers} ) {
        next     if lc $trailer->{'token'} ne lc $token;
        return 1 if $trailer->{'value'} eq $trailer_value;
        return 1 if index( $trailer->{'value'}, $trailer_value . q{ } ) == 0;
    }
    return 0;
}

sub _commit_kinds {
    my ( $git, $commit, $msg ) = @_;

    my @kinds;
    if ( defined $commit ) {
        my @parents = $commit->parent;
        if ( scalar @parents > 1 ) {
            push @kinds, 'merge';
        }
    }
    elsif ( -f path( $git->git_dir() )->child('MERGE_HEAD') ) {
        push @kinds, 'merge';
    }

    if ( $msg =~ m/^This[ ]reverts[ ]commit[ ][[:xdigit:]]{7,40}/msx ) {
        push @kinds, 'revert';
    }
    if ( $msg =~ m/\A(?:fixup|squash|amend)!\s/msx ) {
        push @kinds, 'fixup';
    }

    return \@kinds;
}

sub _matches {
    my ( $spec, $trailer ) = @_;

    return 0 if $trailer->{'token'} !~ $spec->{'token_re'};
    return 1 if !defined $spec->{'value_re'};
    return $trailer->{'value'} =~ $spec->{'value_re'} ? 1 : 0;
}

sub deny_errors {
    my ($ctx) = @_;

    my $git    = $ctx->{'git'};
    my $specs  = _specs($git);
    my $errors = 0;

    foreach my $spec ( @{ $specs->{'deny'} } ) {
        my @hits = grep { _matches( $spec, $_ ) } @{ $ctx->{'trailers'} };
        if (@hits) {
            my $details = join "\n", map { $_->{'token'} . q{: } . $_->{'value'} } @hits;
            $git->fault(
                <<'EOS',
This commit's message carries a trailer this repository forbids.
Please, amend your commit to remove it.
EOS
                { prefix => $PKG, commit => $ctx->{'id'}, option => 'deny', details => $details }
            );
            $errors++;
        }

        my @suspects = grep { _matches( $spec, $_ ) } @{ $ctx->{'suspects'} };
        next if !scalar @suspects;
        my $details = join "\n", map { $_->{'line'} } @suspects;
        $git->fault(
            <<'EOS',
This commit's message has a line that looks like a trailer this repository
forbids. git does not read it as a trailer yet, because it is not in a
trailer block, so it creates no false attribution yet. It will, as soon as
the message is reflowed, squash-merged, or gains a Signed-off-by.
Please, amend your commit to remove the line.
EOS
            { prefix => $PKG, commit => $ctx->{'id'}, option => 'deny', details => $details }
        );
        $errors++;
    }

    return $errors;
}

sub require_errors {
    my ($ctx) = @_;

    my $git   = $ctx->{'git'};
    my $specs = _specs($git);
    return 0 if !scalar @{ $specs->{'require'} };

    # A merge, a revert and a fixup are not places to disclose anything: the
    # first two have no footer of their own and the third is transient.
    my $skipped = first { $specs->{'skip'}->{$_} } @{ $ctx->{'kinds'} };
    if ( defined $skipped ) {
        $log->debugf( "$PKG: not requiring a trailer of a %s commit", $skipped );
        return 0;
    }

    my $errors = 0;
    foreach my $spec ( @{ $specs->{'require'} } ) {
        next if any { _matches( $spec, $_ ) } @{ $ctx->{'trailers'} };

        my $named = $spec->{'token'} // $spec->{'raw'};

        # Written, but not where git can see it. Much the most likely mistake,
        # and the one worth its own message.
        my $misplaced = first { $_->{'token'} =~ $spec->{'token_re'} } @{ $ctx->{'suspects'} };
        if ( defined $misplaced ) {
            $git->fault(
                <<"EOS",
This commit's message mentions '$named', but git does not read it as a
trailer, because it is not in a paragraph of its own at the end of the
message. Please, amend your commit to put a blank line before it.
EOS
                { prefix => $PKG, commit => $ctx->{'id'}, option => 'require', details => $misplaced->{'line'} }
            );
            $errors++;
            next;
        }

        # Present, but its value is not one this repository accepts.
        my $wrong_value = first { $_->{'token'} =~ $spec->{'token_re'} } @{ $ctx->{'trailers'} };
        if ( defined $wrong_value ) {
            $git->fault(
                <<"EOS",
This commit's trailer '$named' has a value this repository does not accept.
EOS
                {
                    prefix  => $PKG,
                    commit  => $ctx->{'id'},
                    option  => 'require',
                    details => $wrong_value->{'token'} . q{: } . $wrong_value->{'value'},
                }
            );
            $errors++;
            next;
        }

        $git->fault(
            <<"EOS",
This commit's message does not have a trailer this repository requires.
Please, amend your commit to add '$named' as the last paragraph.
EOS
            { prefix => $PKG, commit => $ctx->{'id'}, option => 'require' }
        );
        $errors++;
    }

    return $errors;
}

# The required relative order of those trailers a repository cares about.
#
# Git::Message cannot express this at all: it rebuilds the footer in
# lexicographic order with signed-off-by forced last, so the order the author
# actually wrote is gone before any check could read it. `interpret-trailers`
# preserves it.
#
# Only trailers named by an 'order' entry are constrained; the rest are ignored,
# unless '*' is configured, which stands for "any other trailer" and is how
# "the sign-off comes last" is said.
sub order_errors {
    my ($ctx) = @_;

    my $git   = $ctx->{'git'};
    my $specs = _specs($git);
    my @order = @{ $specs->{'order'} };
    return 0 if !scalar @order;

    my $wildcard = first { $order[$_] eq q{*} } 0 .. $#order;

    my @ranked;
    foreach my $trailer ( @{ $ctx->{'trailers'} } ) {
        my $rank = first { lc $order[$_] eq lc $trailer->{'token'} } 0 .. $#order;
        $rank //= $wildcard;
        next if !defined $rank;
        push @ranked, { rank => $rank, token => $trailer->{'token'} };
    }

    # Report the first inversion only: one fault per commit is enough to act on.
    foreach my $i ( 1 .. $#ranked ) {
        next if $ranked[$i]->{'rank'} >= $ranked[ $i - 1 ]->{'rank'};
        my $earlier = $ranked[$i]->{'token'};
        my $later   = $ranked[ $i - 1 ]->{'token'};
        $git->fault(
            <<"EOS",
This commit's message trailers are not in the order this repository requires.
'$earlier' must come before '$later'.
Please, amend your commit to reorder them.
EOS
            {
                prefix  => $PKG,
                commit  => $ctx->{'id'},
                option  => 'order',
                details => q{Configured order: }
                  . ( join q{, }, @order )
                  . qq{\nFound order:      }
                  . ( join q{, }, map { $_->{'token'} } @ranked ),
            }
        );
        return 1;
    }

    return 0;
}

sub message_errors {
    my ( $git, $commit, $msg ) = @_;

    my $specs = _specs($git);

    # Unconfigured means inert, and costs nothing: no subprocess, no parsing.
    return 0
      if !scalar @{ $specs->{'deny'} }
      && !scalar @{ $specs->{'require'} }
      && !scalar @{ $specs->{'order'} };

    return 0 if !defined $msg || $msg !~ m/\S/msx;

    # The client path hands us decoded characters and the server path hands us
    # bytes. Everything below works in bytes: feeding characters to a
    # subprocess warns and mangles them, and configuration values are bytes too.
    my $text = utf8::is_utf8($msg) ? encode( _commit_encoding($git), $msg ) : $msg;
    $text =~ s/\r\n/\n/gmsx;

    my $trailers = _trailers( $git, $text );
    my $ctx      = {
        git      => $git,
        id       => defined $commit ? $commit->commit : q{},
        msg      => $text,
        trailers => $trailers,
        suspects => _suspect_lines( $git, $text, $trailers ),
        kinds    => _commit_kinds( $git, $commit, $text ),
    };

    return deny_errors($ctx) + require_errors($ctx) + order_errors($ctx);
}

sub check_message_file {
    my ( $git, $msg ) = @_;
    return message_errors( $git, undef, $msg );
}

sub check_ref {
    my ( $git, $ref ) = @_;

    my $errors = 0;
    foreach my $commit ( $git->get_affected_ref_commits($ref) ) {
        $errors += message_errors( $git, $commit, $commit->message );
    }
    return $errors;
}

sub check_patchset {
    my ( $git, $branch, $commit ) = @_;
    return message_errors( $git, $commit, $commit->message );
}

# Install hooks
my $options = { config => \&_setup_config };

GITHOOKS_CHECK_AFFECTED_REFS( \&check_ref, $options );
GITHOOKS_CHECK_PATCHSET( \&check_patchset, $options );
GITHOOKS_CHECK_MESSAGE_FILE( \&check_message_file, $options );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::MoreHooks::CheckTrailers - GitHooks plugin to enforce a commit message trailer policy

=head1 VERSION

version 0.020

=head1 SYNOPSIS

Use package via
L<Git::Hooks|Git::Hooks>
interface (git config file).

=head1 DESCRIPTION

=for Pod::Coverage deny_errors order_errors require_errors

=for stopwords AI Aider Codex Copilot Gerrit reflowed unfold unfolded forge forges
=for stopwords autosquash cherry squashed submodule

=head1 STATUS

Package Git::MoreHooks is currently being developed so changes in the existing
hooks are possible.

=for test_synopsis BEGIN { die "SKIP: Git config below."; }

    [githooks]
        plugin = Git::MoreHooks::CheckTrailers
    [githooks "checktrailers"]
        deny = Co-Authored-By
        require = AI-assisted-by

=for stopwords DCO GitLab LLVM fixup

Check the B<trailers> of a commit message -- the C<Token: value> lines in its
last paragraph -- against a policy the repository sets. Three independent
things can be asked for: that named trailers are B<absent>, that named trailers
are B<present>, and that they appear in a given B<order>.

The plugin ships with B<no trailer names at all> and does nothing until a
repository names its own. That is deliberate: there is no settled spelling for a
disclosure trailer -- the Linux kernel, Fedora and LLVM say C<Assisted-by:>,
other projects say C<AI-assisted-by:> -- and a hook has no business holding an
opinion about it.

=head2 Why a plugin, when C<CheckLog> has C<match>

L<Git::Hooks::CheckLog|Git::Hooks::CheckLog> can already reject a message
matching a pattern, and for a simple ban that is enough. What it cannot do is
distinguish a line git reads as a trailer from one that merely looks like it,
which this plugin needs for both its clearest error message and its C<order>
check, nor can it tell C<Signed-off-by: a person> from
C<Signed-off-by: a program>.

=head2 What this is for

The case it was written for is a tool writing C<Co-Authored-By:> into a commit
it helped with. That trailer is an B<authorship> trailer carrying
C<Name E<lt>emailE<gt>>, and GitHub and GitLab turn it into contributor
attribution -- so naming a program there asserts that a person co-authored the
commit, and mints a contributor who does not exist. A disclosure trailer of the
repository's own choosing says the true thing instead.

It generalises: any trailer a project wants kept out of, or insisted upon in,
its history.

=head2 How the trailers are read

By C<git interpret-trailers --parse>, not by parsing the message here. The harm
this plugin prevents is whatever B<git and the forges> read as a trailer, and the
only parser guaranteed not to drift from git is git. In particular a message
whose last paragraph holds a body line above its trailers, or a space before a
colon, or a value folded over two lines, is parsed by git perfectly well while a
stricter reading sees no trailers at all.

Lines that look like trailers but which git does B<not> read as such are
reported separately and more mildly -- see
L</githooks.checktrailers.deny-in-body BOOL>.

=head1 USAGE

As a C<Git::Hooks> plugin, enabled by name:

=for test_synopsis BEGIN { die "SKIP: Git config below."; }

    [githooks]
        plugin = Git::MoreHooks::CheckTrailers

It hooks itself to:

=over

=item * B<commit-msg>, B<applypatch-msg>

Locally, as the commit is made.

=item * B<update>, B<pre-receive>, B<ref-update>, B<commit-received>, B<submit>

In the remote repository, once per affected reference.

=item * B<patchset-created>, B<draft-published>

For Gerrit.

=back

B<The server side is the real gate.> C<git rebase>, C<git filter-branch> and
non-interactive C<git cherry-pick> do not run C<commit-msg> at all, so a
client-side check is incomplete by nature, and C<git commit --no-verify> is
always available. Enable the plugin in the bare repository too.

B<This plugin never rewrites a message.> A C<prepare-commit-msg> hook that
stripped an unwanted trailer would run B<before> the tool appended it, and would
silently edit what the author wrote. Checking and failing is the only honest
behaviour, and every message it emits names the amendment to make.

=head1 CONFIGURATION

The plugin is configured by the following options.

=head2 githooks.checktrailers.deny SPEC

May be specified more than once. Reject the commit if a matching trailer is
B<present>. No default: with none configured, nothing is denied.

=head2 githooks.checktrailers.require SPEC

May be specified more than once. Reject the commit if no matching trailer is
B<present>. No default.

Leave it unset in a repository where only some commits are AI-assisted: a
commit written by a person should not be made to claim otherwise. To require a
trailer on one branch only, scope the plugin with C<githooks.ref> rather than
relaxing the rule. The literal value C<undef> clears any inherited setting:

=for test_synopsis BEGIN { die "SKIP: Git config below."; }

    [githooks "checktrailers"]
        require = undef

=head2 SPEC syntax

=for test_synopsis BEGIN { die "SKIP: Git config below."; }

    SPEC ::= TOKENMATCH [ whitespace VALUEMATCH ]

C<TOKENMATCH> is either a trailer token (letters, digits and C<->, as git
itself allows) or a C<qr//> pattern. C<VALUEMATCH>, if given, is a C<qr//>
pattern or a literal substring. Both are matched B<case-insensitively>, and the
spacing around the colon never matters, because git normalises it before this
plugin sees it.

=for test_synopsis BEGIN { die "SKIP: Git config below."; }

    deny    = Co-Authored-By
    deny    = Signed-off-by qr/(?i:claude|copilot|gemini|codex|cursor|aider)/
    require = AI-assisted-by

The second line is the reason C<VALUEMATCH> exists: a sign-off by a person is
exactly what a DCO wants, and a sign-off by a program is what the Linux kernel
forbids. Only the latter is rejected.

A C<qr//> must end at its own delimiter, so trailing flags
(C<qr/.../msx>) are a configuration error rather than something silently
dropped. Write C<qr/(?x: ... )/> instead.

Not matched, deliberately: C<Co_Authored_By>, C<CoAuthoredBy> and other
spellings git does not parse as trailers. They cannot create a false
attribution, so they are prose. A repository that wants them caught anyway
writes a pattern: C<deny = qr/co[-_]?authored[-_]?by/>.

=head2 githooks.checktrailers.order TOKEN

May be specified more than once; the order of the options is the required
relative order of the trailers. No default.

Only trailers named here are constrained, and a trailer that is absent is never
an error -- that is what C<require> is for. The special value C<*> stands for
"any other trailer", which is how "the sign-off comes last" is said:

=for test_synopsis BEGIN { die "SKIP: Git config below."; }

    [githooks "checktrailers"]
        order = *
        order = AI-assisted-by
        order = Signed-off-by

=head2 githooks.checktrailers.deny-in-body BOOL

Default B<false>. A C<deny> check also looks at lines which merely B<look> like
the forbidden trailer -- at column zero, with a C<Token: value> shape -- and
reports them separately, because git will start reading them as trailers the
moment the message is reflowed, squash-merged or gains a C<Signed-off-by>.

By default only the B<last> paragraph is examined that way. Setting this option
true examines every paragraph after the title, which catches more and also
starts matching prose: the commit which adds a C<deny> rule to a repository
usually has to name the forbidden trailer in order to explain itself.

=head2 githooks.checktrailers.require-skip KIND

May be specified more than once. Default: B<merge revert fixup>. Kinds of commit
which the C<require> check does not apply to. C<deny> is never skipped.

=over

=item * B<merge> -- a merge commit has no footer of its own. Note that C<deny>
deliberately still applies: GitHub's "Squash and merge" B<collects>
C<Co-authored-by> trailers from the commits it squashes, which is the most
likely way an unwanted trailer reaches a protected branch.

=item * B<revert> -- C<git revert> writes its own message.

=item * B<fixup> -- a C<fixup!> or C<squash!> commit is transient.

=item * B<none> -- skip nothing. Needed because this option, unlike C<deny> and
C<require>, has a default that C<undef> cannot clear.

=back

=head2 githooks.checktrailers.help-on-error MESSAGE

Not an option of this plugin but of L<Git::Hooks|Git::Hooks> itself, and the
right place for a repository's own explanation:

=for test_synopsis BEGIN { die "SKIP: Git config below."; }

    [githooks "checktrailers"]
        help-on-error = "Co-Authored-By names a human co-author. Disclose AI \
            assistance with 'AI-assisted-by:' instead. See AI_DISCLOSURE.md."

=head1 EXPORTS

This module exports the routines below, which can be used directly without the
rest of the Git::Hooks infrastructure. Each returns a count of the problems it
found and reports them through C<$git-E<gt>fault>.

=head2 check_message_file GIT, MSG

Implements the C<commit-msg> and C<applypatch-msg> hooks.

=head2 check_ref GIT, REF

Implements the C<update> and C<pre-receive> hooks, checking every commit
affecting C<REF>.

=head2 check_patchset GIT, BRANCH, COMMIT

Implements the Gerrit hooks.

=head2 message_errors GIT, COMMIT, MSG

The whole check for one message. C<COMMIT> may be undefined, as it is on the
client side.

=head1 REFERENCES

=over

=item * L<git-interpret-trailers|https://git-scm.com/docs/git-interpret-trailers>

How git decides what a trailer is. This plugin asks it rather than guessing.

=item * L<Git::Hooks::CheckLog|Git::Hooks::CheckLog>

The general commit-message checks -- title, width, spelling, C<Signed-off-by>
presence. This plugin is about trailer policy specifically and composes with it.

=back

=head1 AUTHOR

'Mikko Koivunalho <mikkoi@cpan.org>'

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
