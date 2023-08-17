#!perl
use strict;
use warnings;
use Data::Dumper;
use feature 'signatures';
no warnings 'experimental::signatures';
use Getopt::Long;
#use Text::CleanFragment 'clean_fragment';
use GitHub::RSS;
use XML::Feed;
use DateTime;
use DateTime::Format::ISO8601;
use POSIX 'strftime';
use Text::Markdown;
use HTML::Entities 'encode_entities';

our $VERSION = '0.03';

=head1 SYNOPSIS

  generate-rss.pl --user Perl --repo perl5 --dbfile=db/issues.sqlite --output-file Perl-perl5-issues.rss

=head1 OPTIONS

    --token         GitHub API token
    --token-file    filename containing JSON with the GitHub API token
    --user          GitHub user of repository to fetch
    --repo          GitHub repository containing the issues and comments
    --dbfile        Name of the SQLite database to provide the issues
    --output-file   Name of the RSS output file

=cut

GetOptions(
    'filter=s' => \my $issue_regex,
    'issue=s' => \my $github_issue,
    'user=s' => \my $github_user,
    'repo=s' => \my $github_repo,
    'dbfile=s' => \my $store,
    'output-file=s' => \my $output_file,
);

$store //= 'db/issues.sqlite';

my $gh = GitHub::RSS->new(
    dbh => {
        dsn => "dbi:SQLite:dbname=$store",
    },
);

my $since = strftime '%Y-%m-%dT%H:%M:%SZ', gmtime(time()-10*3600*24);

my $feed = XML::Feed->new('RSS');
$feed->title("Github comments for $github_user/$github_repo");
$feed->link("https://github.com/$github_user/$github_repo");
#$feed->self("https://corion.net/github-rss/Perl-perl5.rss");

sub verbatim_section( $s ) {
    my $res = encode_entities($s);
    $res =~ s! !&nbsp;!g;
    return "<code>$res</code>";
}

my @comments =
    map {

    my $entry = XML::Feed::Entry->new('RSS');
    $entry->id( $_->{id} );
    $entry->title( "Comment by $_->{user}->{login}" );
    $entry->link( $_->{html_url} );

    my $issue = $gh->issue( $_->{issue_number} );

    my $header = <<HTML;
<header>
<a href="$issue->{html_url}">$issue->{title}</a> in <a href="https://github.com/$github_user/$github_repo">$github_user/$github_repo</a>
</header>
HTML
    my $footer = <<HTML;
<footer>
<hr />
Created by <a href="https://github.com/Corion/GitHub-RSS">GitHub::RSS</a>
</footer>
HTML

    # Convert from md to html, url-encode
    my $content = $_->{body} || '';
    $content =~ s!\\(.)!$1!g; # unquote, because Github sends us quotemeta'd content?!
    $content =~ s![\x00-\x08\x0B\x0C\x0E-\x1F]!.!g;

    # render ```...``` into verbatim code:
    $content =~ s!^\`\`\`(.*?)\`\`\`!verbatim_section($1)!msge;

    my $body = Text::Markdown->new->markdown( $content );
    $entry->content( join "", $header, $body, $footer );
    $entry->author( $_->{user}->{login} );

    if( $_->{updated_at} ) {
        my $modified = DateTime::Format::ISO8601->parse_datetime(
            $_->{updated_at}
        );
        $entry->modified( $modified );
    };

    my $created = DateTime::Format::ISO8601->parse_datetime(
        $_->{created_at}
    );
    $entry->issued( $created );

    $feed->add_entry( $entry );
}
 $gh->issues_and_comments(
    #Perl => 'perl5'
    $since,
    );

sub update_file( $fn, $content ) {
    my $needs_update = ! -e $fn;
    if( ! $needs_update ) {
        open my $old, '<', $fn
            or die "Couldn't read old content from '$fn': $!";
        binmode $old, ':utf8';
        local $/;
        my $old_content = <$old>;
        $needs_update = $old_content ne $content;
    };

    if( $needs_update ) {
        open my $fh, '>', $fn
            or die "Couldn't create '$fn': $!";
        binmode $fh, ':utf8';
        print {$fh} $content;
    };
}

update_file( $output_file, $feed->as_xml );

=head1 LIVE DEMO

This RSS feed is live at L<https://corion.net/github-rss/Perl-perl5-issues.rss>
if you just want to read the Perl 5 issues as RSS feed.

=cut
