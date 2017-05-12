package Mail::Abuse::Reader::GoogleGroups;

require 5.005_62;

use Carp;
use strict;
use warnings;
use Date::Manip;
use WWW::Google::Groups;

use base 'Mail::Abuse::Reader';

				# The code below should be in a single line
our $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

				# This contraption is required to include
				# $VERSION in the BLURB.

BEGIN { $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r } };

use constant GROUP 	=> 'news.admin.net-abuse.sightings';
use constant BLURB 	=> <<EOF;

The message below has been submitted to the &{GROUP} news group
and fetched using Mail::Abuse::Reader::GoogleGroups $VERSION

EOF
    ;
=pod

=head1 NAME

Mail::Abuse::Reader::GoogleGroups - Reads Mail::Abuse::Report from NANAS via Google Groups

=head1 SYNOPSIS

  use Mail::Abuse::Report;
  use Mail::Abuse::Reader::GoogleGroups;
  my $r = new Mail::Abuse::Reader::GoogleGroups;
  my $report = new Mail::Abuse::Report (reader => $r);

=head1 DESCRIPTION

THIS CODE SHOULD NOT BE USED IN PRODUCTION YET. SEE bin/google-gather
INSTEAD, FOR AN ALTERNATE MECHANISM OF FETCHING REPORTS FROM NANAS
VIA GOOGLE GROUPS.

This module uses the news.admin.net-abuse.sightings archive kindly
provided by the Google(tm) Groups service to feed public complaints
into the C<Mail::Abuse> package.

The general idea is that a search is going to be performed and each
result will be fed into the C<Mail::Abuse> engine. The parameters of
the process can be configured by the following keys in the
configuration file.

=over 4

=item B<google groups search>

Regexp to search for in the text of each article.

=cut

    use constant QUERY	=> 'google groups search';

=pod

=item B<google groups max messages>

Maximum number of messages to read in a single run. Defaults to 50.

=cut

    use constant MAX	=> 'google groups max messages';

=pod

=item B<google groups oldest message>

Controls the maximum age of a message. Messages that are older
(accorging to its Date: header) will be skipped and not counted. This
defaults to five days.

=cut

    use constant OLDEST	=> 'google groups oldest message';

=pod

=item B<google groups server>

The name of the Google(tm) Groups server to use. Defaults to
C<groups.google.com>.

=cut

    use constant SERVER	=> 'google groups server';

=pod

=item B<google groups proxy>

The proxy server to use.

=cut

    use constant PROXY	=> 'google groups proxy';

=pod

=item B<debug google groups>

When set to a true value, causes debug information to be sent to
STDERR.

=cut

    use constant DEBUG	=> 'debug google groups';

=pod

=back

The following methods are implemented within this class.

=over

=item C<read($report)>

Populates the text of the given C<$report> using the C<-E<gt>text>
method. Must return true if succesful or false otherwise.

=cut

sub read
{
    my $self	= shift;
    my $rep	= shift;

    my $config	= $rep->config;

    unless ($config->{&QUERY})
    {
	carp "Not enough config info for GoogleGroups reader";
	return;
    }

    my $search = qr/$config->{&QUERY}/;

    unless ($self->agent)
    {
	$self->agent( new WWW::Google::Groups
		      (
		       server => $config->{&SERVER} || 'groups.google.com',
		       $config->{&PROXY} ? (proxy => $config->{&PROXY}) : (),
		       )
		      );
	
	$self->count(0);
	$self->group($self->agent->select_group(&GROUP));
#	$self->group($self->agent->search(query => "group:" . 
#					  &GROUP . " " . $config->{&QUERY},
#					  limit => 100));

    }

    unless ($self->before)
    {
	my $date_before;

	Date_Init('TZ=UTC');

	eval 
	{
	    if (ref $config->{&OLDEST} eq 'ARRAY')
	    {
		$date_before =  ParseDate(join(' ', @{$config->{&OLDEST}}));
	    }
	    else {
		$date_before = ParseDate($rep->config->{&OLDEST} 
					 || "5 days ago");
	    }
	};

	warn "M::A::R::GoogleGroups parser said $@"
	    if $@ and $config->{&DEBUG};
	die "M::A::R::GoogleGroups: Cannot parse '" . &OLDEST . "\n"
	    unless $date_before;
	$self->before(UnixDate($date_before, '%s'));
	die "M::A::R::GoogleGroups: Times before the epoch are not supported" 
	    if $self->before < 0;
	warn "M::A::R::GoogleGroups: Ignoring posts older than ", 
	$self->before, "\n" if $config->{&DEBUG};
    }

    while ($self->thread($self->group->next_thread), $self->thread)
    {
	warn "M::A::R::GoogleGroups: Mining thread '", 
	$self->thread->title, "'\n" 
	    if $config->{&DEBUG};

	my $mid = undef;

	while ($self->article($self->thread->next_article), $self->article)
	{
	    if ($mid and $mid eq $self->article->header('Message-Id'))
	    {
		warn "M::A::R::GoogleGroups: Looks like we pulled the "
		    . "same message twice\n"
			if $config->{&DEBUG};
		last;
	    }

	    $mid = $self->article->header('Message-Id');

	    return unless $self->count < ($config->{&MAX} || 50);

	    my $date = $self->article->header('Date');
	    my $article_date = undef;

	    warn "M::A::R::GoogleGroups: Fetched article ", 
	    $self->article->header('Message-Id'), "/$date\n"
		if $config->{&DEBUG};

	    eval 
	    {
		$article_date = UnixDate(ParseDate($date), '%s');
	    };
				# Only if parsing succeeded, will we filter
				# this article
	    unless ($@)
	    {
		if ($article_date < $self->before)
		{
		    warn "M::A::R::GoogleGroups filtered article ",
		    "($date/$article_date)\n" 
			if $config->{&DEBUG};
		    last;
		}
	    }

	    if ($self->article->body =~ m/$search/i)
	    {
		$self->count($self->count + 1);
		my $buffer = 'From: ' . $self->article->header('From')	. "\n";
		$buffer .= 'Id: ' . $self->article->header('Message-ID'). "\n";
		$buffer .= 'Date: ' . $self->article->header('Date')	. "\n";
		$buffer .= $self->article->header('Subject')	. "\n\n";
		$buffer .= &BLURB;
		$buffer .= $self->article->body;
		$rep->text(\$buffer);
		return 1;
	    }
	}
	warn "M::A::R::GoogleGroups: Thread exhausted. Going to the next one\n"
	    if $config->{&DEBUG};
    }

    warn "M::A::R::GoogleGroups: Group exhausted.\n"
	if $config->{&DEBUG};

    return;
}

__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.2 with options

  -ACOXcfkn
	Mail::Abuse
	-v
	0.01

=back


=head1 LICENSE AND WARRANTY

This code and all accompanying software comes with NO WARRANTY. You
use it at your own risk.

This code and all accompanying software can be used freely under the
same terms as Perl itself.

=head1 AUTHOR

Luis E. Muñoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1).

=cut
