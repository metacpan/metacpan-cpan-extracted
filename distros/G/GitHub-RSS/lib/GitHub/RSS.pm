package GitHub::RSS;
use strict;
use 5.010;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use PerlX::Maybe;

use IO::Socket::SSL;
use Net::GitHub;
use DBI;
use JSON;

use Data::Dumper;

our $VERSION = '0.04';

=head1 NAME

GitHub::RSS - collect data from Github.com for feeding into RSS

=head1 SYNOPSIS

    my $gh = GitHub::RSS->new(
        dbh => {
            dsn => "dbi:SQLite:dbname=$store",
        },
    );

    my $last_updated = $gh->last_check;
    $gh->fetch_and_store( $github_user => $github_repo, $last_updated );
    if( $verbose ) {
        print "Updated from $last_updated to " . $gh->last_check, "\n";
    };

=head1 DESCRIPTION

This module provides a cache database for GitHub issues and scripts to
periodically update the database from GitHub.

This is mainly used for creating an RSS feed from the database, hence the
name.

=head1 METHODS

=head2 C<< ->new >>

  my $gh = GitHub::RSS->new(
      dbh => {
          dsn => 'dbi:SQLite:dbname=db/issues.sqlite',
      },
  );

Constructs a new GitHub::RSS instance

=over 4

=item *

B<gh> - instance of L<Net::GitHub>

=cut

has 'gh' => (
    is => 'ro',
    default => sub( $self ) {
        Net::GitHub->new(
            maybe access_token => $self->token
        ),
    },
);

=item *

B<token_file> - name and path of the JSON-format token file containing the
GitHub API token By default, that file is searched for under the name
C<github.credentials> in C<.>, C<$ENV{XDG_DATA_HOME}>, C<$ENV{USERPROFILE}>
and C<$ENV{HOME}>.

=cut

has 'token_file' => (
    is => 'lazy',
    default => \&_find_gh_token_file,
);

=item *

B<token> - GitHub API token. If this is missing, it will be attempted to read
it from the C<token_file>.

=cut

has 'token' => (
    is => 'lazy',
    default => \&_read_gh_token,
);

=item *

B<default_user> - name of the GitHub user whose repos will be read

=cut

has default_user => (
    is => 'ro',
);

=item *

B<default_repo> - name of the GitHub repo whose issues will be read

=cut

has default_repo => (
    is => 'ro',
);

=item *

B<dbh> - premade database handle or alternatively a hashref containing
the L<DBI> arguments

  dbh => $dbh,

or alternatively

  dbh => {
      user     => 'scott',
      password => 'tiger',
      dsn      => 'dbi:SQLite:dbname=db/issues.sqlite',
  }

=cut

has dbh => (
    is       => 'ro',
    required => 1,
    coerce   => \&_build_dbh,
);

sub _build_dbh( $args ) {
    return $args if ref($args) eq 'DBI::db';
    ref($args) eq 'HASH' or die 'Not a DB handle nor a hashref';
    return DBI->connect( @{$args}{qw/dsn user password options/} );
}

=item *

B<fetch_additional_pages> - number of additional pages to fetch from GitHub.
This is relevant when catching up a database for a repository with many issues.

=back

=cut

has fetch_additional_pages => (
    is => 'ro',
    default => '1',
);

sub _find_gh_token_file( $self, $env=undef ) {
    $env //= \%ENV;

    my $token_file;

    # This should use File::User
    for my $candidate_dir ('.',
                           $ENV{XDG_DATA_HOME},
                           $ENV{USERPROFILE},
                           $ENV{HOME}
    ) {
        next unless defined $candidate_dir;
        if( -f "$candidate_dir/github.credentials" ) {
            $token_file = "$candidate_dir/github.credentials";
            last
        };
    };

    return $token_file
}

sub _read_gh_token( $self, $token_file=undef ) {
    my $file = $token_file // $self->token_file;

    if( $file ) {
        open my $fh, '<', $file
            or die "Couldn't open file '$file': $!";
        binmode $fh;
        local $/;
        my $json = <$fh>;
        my $token_json = decode_json( $json );
        return $token_json->{token};
    } else {
        # We'll run without a known account
        return
    }
}

sub fetch_all_issues( $self,
    $user = $self->default_user,
    $repo = $self->default_repo,
    $since=undef ) {
    my @issues = $self->fetch_issues( $user, $repo, $since );
    my $gh = $self->gh;
    while ($gh->issue->has_next_page) {
        push @issues, $gh->issue->next_page;
    }
    @issues
}

sub fetch_issues( $self,
    $user = $self->default_user,
    $repo = $self->default_repo,
    $since=undef ) {
    my $gh = $self->gh;
    my @issues = $gh->issue->repos_issues($user => $repo,
                                          { sort => 'updated',
                                          direction => 'asc', # so we can interrupt any time
                                          state => 'all', # so we find issues that got closed
                                          maybe since => $since,
                                          }
                                         );
};

=head2 C<< ->fetch_issue_comments >>

=cut

sub fetch_issue_comments( $self, $issue_number,
        $user=$self->default_user,
        $repo=$self->default_repo
    ) {
    # Shouldn't this loop as well, just like with the issues?!
    return $self->gh->issue->comments($user, $repo, $issue_number );
}

sub write_data( $self, $table, @rows) {
    my @columns = sort keys %{ $rows[0] };
    my $statement = sprintf q{replace into "%s" (%s) values (%s)},
                        $table,
                        join( ",", map qq{"$_"}, @columns ),
                        join( ",", ('?') x (0+@columns))
                        ;
    my $sth = $self->dbh->prepare( $statement );
    eval {
        $sth->execute_for_fetch(sub { @rows ? [ @{ shift @rows }{@columns} ] : () }, \my @errors);
    } or die Dumper \@rows;
    #if( @errors ) {
    #    warn Dumper \@errors if (0+@errors);
    #};
}

sub store_issues_comments( $self, $user, $repo, $issues ) {
    # Munge some columns:
    for (@$issues) {
        my $u = $_->{user};
        @{ $_ }{qw( user_id user_login user_gravatar_id )}
            = @{ $u }{qw( id login gravatar_id )};

        # Squish all structure into JSON, for later
        for (values %$_) {
            if( ref($_) ) { $_ = encode_json($_) };
        };
    };

    for my $issue (@$issues) {
        #$|=1;
        #print sprintf "% 6d %s\r", $issue->{number}, $issue->{updated_at};
        my @comments = $self->fetch_issue_comments( $issue->{number}, $user => $repo );

        # Squish all structure into JSON, for later
        for (@comments) {
            for (values %$_) {
                if( ref($_) ) { $_ = encode_json($_) };
            };
        };
        $self->write_data( 'comment' => @comments )
            if @comments;
    };

    # We wrote the comments first so we will refetch them if there is a problem
    # when writing the issue
    $self->write_data( 'issue' => @$issues );
};

=head2 C<< ->fetch_and_store($user, $repo, $since) >>

  my $since = $gh->last_check;
  $gh->fetch_and_store($user, $repo, $since)

Fetches all issues and comments modified after the C<$since> timestamp.
If C<$since> is missing or C<undef>, all issues will be retrieved.

=cut

sub fetch_and_store( $self,
                     $user  = $self->default_user,
                     $repo  = $self->default_repo,
                     $since = undef) {
    my $dbh = $self->dbh;
    my $gh = $self->gh;

    my $can_fetch_more = $self->fetch_additional_pages;

FETCH:
    my @issues = $self->fetch_issues( $user => $repo, $since );
    my $has_more = $gh->issue->has_next_page;
    $self->store_issues_comments( $user => $repo, \@issues );

    if( $has_more and (!defined($can_fetch_more) or $can_fetch_more-- > 0)) {
        $since = $issues[-1]->{updated_at};
        goto FETCH;
    }
}

sub refetch_issues( $self,
                     $user  = $self->default_user,
                     $repo  = $self->default_repo,
                     @issue_numbers) {
    my $dbh = $self->dbh;
    my $gh = $self->gh;

    my @issues = map { scalar $gh->issue->issue($user => $repo, $_) } @issue_numbers;
    $self->store_issues_comments( $user => $repo, \@issues );
}

sub inflate_fields( $self, $item, @fields ) {
    for (@fields) {
        $item->{$_} = $item->{$_} ? decode_json( $item->{$_} ) : $item->{$_};
    }
}

sub issues_and_comments( $self, $since ) {
    map {
        $self->inflate_fields( $_, qw(user closed_by));
        $_
    }
    @{ $self->dbh->selectall_arrayref(<<'SQL', { Slice => {}}, $since, $since) }
        select
               i.id
             , i.user
             , i.html_url
             , i.body
             , i.created_at
             , i.updated_at
             , i.title as issue_title
             , i.number as issue_number
          from issue i
         where i.updated_at >= ?
      union all
        select
               c.id
             , c.user
             , c.html_url
             , c.body
             , c.created_at
             , c.updated_at
             , i.title as issue_title
             , i.number as issue_number
          from comment c
          join issue i on c.issue_url=i.url
         where c.updated_at >= ?
      order by i.updated_at, html_url
SQL
}

sub issues_with_patches( $self ) {
    map {
        $self->inflate_fields( $_, qw(user closed_by));
        $_
    }
    @{ $self->dbh->selectall_arrayref(<<'SQL', { Slice => {}}) }
        select distinct
               i.* -- later, expand to explicit list
          from issue i
          join comment c on c.issue_url=i.url
         where c.body like '%```diff%'
           and i.state = 'open'
      order by i.url
SQL
}

sub issue( $self, $issue ) {
    $self->dbh->selectall_arrayref(<<'SQL', { Slice => {}}, $issue)->[0]
        select
               * -- later, expand to explicit list
          from issue i
         where i.number = ?
      order by i.url
SQL
}

sub comments( $self, $issue ) {
    @{ $self->dbh->selectall_arrayref(<<'SQL', { Slice => {}}, $issue) }
        select
               c.* -- later, expand to explicit list
          from comment c
          join issue i on c.issue_url=i.url
         where i.number = ?
      order by c.url
SQL
}

=head2 C<< ->last_check >>

  my $since = $gh->last_check;

Returns the timestamp of the last stored modification or C<undef>
if no issue or comment is stored.

=cut


sub last_check( $self,
                $user = $self->default_user,
                $repo = $self->default_repo ) {
    my $last = $self->dbh->selectall_arrayref(<<'SQL', { Slice => {} });
        select
            max(updated_at) as updated_at
          from issue
SQL
    if( @$last ) {
        return $last->[0]->{updated_at}
    } else {
        return undef # empty DB
    }
}

1;
