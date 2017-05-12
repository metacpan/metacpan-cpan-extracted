package Mediawiki::Blame;
use 5.008;
use utf8;
use strict;
use warnings;
use Algorithm::Annotate qw();
use Carp qw(croak);
use Class::Spiffy qw(-base field const);
use DateTime qw();
use DateTime::Format::ISO8601 qw();
use LWP::UserAgent qw();
use Mediawiki::Blame::Revision qw();
use Mediawiki::Blame::Line qw();
use Params::Validate qw(validate_with SCALAR);
use Regexp::Common qw(number URI);
use Readonly qw(Readonly);
use XML::Twig qw();
our $VERSION = '0.0.3';

field 'export';
field 'page';
field 'ua_timeout';
field '_revisions';     # hashref whose keys are r_ids and values are hashrefs
field '_initial';       # r_id of the initial revision
field '_lwp';           # LWP instance

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;

    validate_with(
        params => \@_,
        on_fail => sub {
            chomp (my $p = shift);
            croak $p;
        },
        spec => {
            export => {
                regex => qr/\A $RE{URI} \z/msx
            },
            page => {
                type => SCALAR,
            },
        },
    );

    my %P = @_; # params as hash

    $self->export($P{export});
    $self->page($P{page});

    {
        my $lwp_name;
        eval q{
            use LWPx::ParanoidAgent qw();
        };
        if ($@) {
            $lwp_name = 'LWP::UserAgent';
        } else {
            $lwp_name = 'LWPx::ParanoidAgent';
        };

        $self->_lwp($lwp_name->new);
        $self->_lwp->agent(
            "Mediawiki::Blame/$VERSION (http://search.cpan.org/dist/Mediawiki-Blame/)"
        );
        push @{ $self->_lwp->requests_redirectable }, 'POST';
    };

    $self->ua_timeout(30);  # seconds
    $self->_revisions({});

    $self->_xml_to_revisions(
        $self->_post(
            $self->_post_params({
                after => 1980,  # one revision after 1980, i.e. the initial
                limit => 1,
            })
        )
    );

    $self->_initial(
        [$self->revisions]->[0]->r_id
    );

    $self->_revisions({});  # reset

    return $self;
};

sub _is_now_or_a_datetime {
    my $p = shift;
    if ($p eq 'now') {
        return 1;
    };
    _is_a_datetime($p);
    return 1;
};

sub _is_a_datetime {
    eval {
        DateTime::Format::ISO8601->parse_datetime(shift)
    };
    if ($@) {
        croak substr $@, 0, (index $@, ' at '); # clean up stacktrace
    };
    return 1;
};

sub _is_greater_or_equal_to_2 {
    my $p = shift;
    return ($p =~ /\A $RE{num}{int} \z/msx and $p >= 2);
};

sub _offset {
    my $self = shift;
    my $P    = shift;   # hashref

    for my $k ('before', 'after') {
        if (exists $P->{$k}) {
            Readonly my $STRF => '%FT%TZ';  # 2007-07-23T21:43:56Z
            if (($k eq 'before') and ($P->{$k} eq 'now')) {
                return DateTime->now->strftime($STRF);
            };
            return DateTime::Format::ISO8601
                ->parse_datetime($P->{$k})
                ->strftime($STRF);
        };
    };
};

sub _post_params {
    my $self = shift;
    my $P    = shift;   # hashref

    my $offset = $self->_offset($P);

    my %post_params = (
        pages  => $self->page,
        offset => $offset,
    );

    if (exists $P->{before}) {
        $post_params{dir} = 'desc';
    };

    if (exists $P->{limit}) {
        $post_params{limit} = $P->{limit};
    };

    return \%post_params;
};

sub fetch {
    my $self = shift;

    validate_with(
        params => \@_,
        on_fail => sub {
            chomp (my $p = shift);
            croak $p;
        },
        spec => {
            before => {
                optional  => 1,
                callbacks => {
                    'is now or a datetime' => \&_is_now_or_a_datetime,
                },
            },
            after => {
                optional  => 1,
                callbacks => {
                    'is a datetime' => \&_is_a_datetime,
                },
            },
            limit => {
                optional  => 1,
                callbacks => {
                    'is greater or equal to 2' => \&_is_greater_or_equal_to_2,
                },
            },
        },
    );

    my %P = @_; # params as hash

    if (exists $P{before} and exists $P{after}) {
        croak 'before and after mutually exclusive';
    };

    if (!exists $P{before} and !exists $P{after}) {
        croak 'either before or after needed';
    };

    my ($revision_counter, $revision_duplicates)
        = $self->_xml_to_revisions(
            $self->_post(
                $self->_post_params(\%P)
            )
        );

    return ($revision_counter, $revision_duplicates);
};

sub _xml_to_revisions {
    my $self = shift;
    my $xml  = shift;

    my $revision_counter    = 0;
    my $revision_duplicates = 0;

    eval {
        XML::Twig->new(twig_handlers => {'revision' => sub {
            my $twig = shift;
            my $elt  = shift;

            $revision_counter++;

            my $r_id = $elt->first_child_text('id');

            if (exists $self->_revisions->{$r_id}) {
                $revision_duplicates++;
            } else {
                my $contrib_node = $elt->first_child('contributor');

                my $contributor;
                if ($contrib_node->first_child_text('username')) {
                    $contributor
                        = $contrib_node->first_child_text('username');
                } else {
                    $contributor
                        = $contrib_node->first_child_text('ip');
                };

                $self->_revisions->{$elt->first_child_text('id')} = [
                    $elt->first_child_text('timestamp'),
                    $contributor,
                    [
                        split /(?<=\n)/,    # at line breaks, but don't remove
                        $elt->first_child_text('text')
                    ],
                ];
            };
            $twig->purge;
        }})->parse($xml)->purge
    };

    if ($@) {
# XML::Parser dies, not croaks with some especially dirty error message,
# so I have to do a good scrubbing
        my $e = $@;
        $e = substr $e, 1;  # remove leading "\n"

        croak 'XML parsing failed: '
            . substr $e, 0, (       # clean up stacktrace
            index $e, ' at ', 1+(   # next ' at ' (discard at this position)
                index $e, ' at '    # first ' at ' (keep it)
            )
        );
    };

    return ($revision_counter, $revision_duplicates);
};

sub _post {
    my $self        = shift;
    my $post_params = shift; # hashref

    $self->_lwp->timeout($self->ua_timeout);

    my $response = $self->_lwp->post($self->export, $post_params);
    if (not $response->is_success) {
        croak 'POST request to ' . $self->export . ' failed: '
          . $response->status_line;
    };

    return $response->decoded_content;
};

sub revisions {
    my $self = shift;

    my @r;
    foreach my $r_id (sort {$a <=> $b} keys %{ $self->_revisions }) {
        push @r, Mediawiki::Blame::Revision->_new(
            $r_id,
            @{ $self->_revisions->{$r_id} } # 3 elements
        );
    };

    return @r;
};

sub blame {
    my $self = shift;

    validate_with(
        params => \@_,
        on_fail => sub {
            chomp (my $p = shift);
            croak $p;
        },
        spec => {
            revision => {
                optional => 1,
                callbacks => {
                    'is a valid r_id' => sub {
                        return exists $self->_revisions->{shift()};
                    },
                },
            },
        },
    );

    my %P = @_; # params as hash

    my @r_ids = sort {$a <=> $b} keys %{ $self->_revisions };
    my $last_r_id;
    if ($P{revision}) {
        $last_r_id = $P{revision};
    } else {
        $last_r_id = $r_ids[-1];
    };

    my $ann = Algorithm::Annotate->new;
    for my $r_id (grep {$_ <= $last_r_id} @r_ids) {
        $ann->add(
            $r_id,
            $self->_revisions->{$r_id}[2]     # text
        );
    };

    my @last_revision_text = @{ $self->_revisions->{$last_r_id}[2] };
    my $first_revision     = $r_ids[0];

    return map {
        my $id = $ann->result->[$_];
        if ($id == $first_revision and $id != $self->_initial) {
            Mediawiki::Blame::Line->_new(
                undef,
                $self->_revisions->{$id}->[0],
                undef,
                $last_revision_text[$_],
            );
        } else {
            Mediawiki::Blame::Line->_new(
                $id,
                $self->_revisions->{$id}->[0],
                $self->_revisions->{$id}->[1],
                $last_revision_text[$_],
            );
        };
    } 0..$#last_revision_text;
};

1;
__END__

=encoding UTF-8

=head1 NAME

Mediawiki::Blame - see who is responsible for each line of page content


=head1 VERSION

This document describes Mediawiki::Blame version 0.0.3


=head1 SYNOPSIS

    use Mediawiki::Blame qw();
    my $mb = Mediawiki::Blame->new(
        export => 'http://example.org/wiki/Special:Export',
        page   => 'User:The Demolished Man',
    );
    $mb->fetch(
        before => 'now',
    );
    my @revisions = $mb->revisions;
    my @blame = $mb->blame;

=head1 DESCRIPTION

In Mediawiki, it is really easy to see who was responsible for a certain edit.
But what if you want to know who is responsible for a piece of content? That
would require you to go through all revisions manually.

This module does the work for you by using a dump of the revision history and
shows for each line of a Mediawiki page source who edited it last.


=head1 INTERFACE

=over

=item new

Takes a hash with the keys C<export> and C<page>.

The value to C<export> is a URL to the export page of the Mediawiki
installation you want to query. Typical examples are
C<http://example.org/wiki/Special:Export> or
C<http://example.org/w/index.php?title=Special:Export>.

The value to C<page> is the name of the page you want to examine.

Returns a Mediawiki::Blame object.

=item fetch

Fetches some revisions from the Mediawiki, looking backward or forward from
some point in time.

Takes a hash with the keys either C<before> or C<after>, and optionally
C<limit>.

The values to C<before> or C<after> are ISO 8601 timestamps as used in
Mediawiki, for instance C<2007-07-23T21:43:56Z>. Times are in the UTC timezone.
You can also pass the string value C<now> to the key C<before>, then the
current date and time is used.

The value to C<limit> is a natural number greater or equal to 2, and
specifies how many revisions are fetched for examination. Smaller numbers mean
faster download and analysis, but less useful results. There is a server-side
hard limitation of 100.

Returns an array of two elements. At index 0 is a number indicating how many
revisions have been fetched. At index 1 is a number indicating how many
revisions from the fetching are duplicates, that is were already existing in
the internal store.

You cannot know that the L<revisions|Mediawiki::Blame::Revision> are without
gaps if you are not careful how you L</"fetch">. Gaps in the revision history
ruin the analysis and blame the wrong contributor.

=item ua_timeout

Takes a natural number, indicating the amount of seconds fetching revisions can
take before the program gives up. Default is 30.

=item revisions

Returns an array of L<revisions|Mediawiki::Blame::Revision>, sorted oldest
first.

=item blame

Takes optionally a single element hash with the key C<revision>.

The value to C<revision> is a
L<Mediawiki revision id|Mediawiki::Blame::Revision/"r_id">.

If no revision is specified, the youngest/most recent is assumed.

Returns an array of L<blame lines|Mediawiki::Blame::Line>.

=back


=head1 EXPORTS

Nothing.


=head1 DIAGNOSTICS

=over

=item C<< before and after mutually exclusive >>

Call L</"fetch"> with one of either C<before> or C<after>, but not both.

=item C<< either before or after needed >>

Call L</"fetch"> with one of either C<before> or C<after>.

=item C<< XML parsing failed: %s >>

The server returned broken XML that the parser could not understand.
Most likely, it did not return XML at all, but something different.

=item C<< POST request to %s failed: %s >>

Various things can go wrong during a HTTP request: DNS lookup failures,
hosts that do not accept connections, Not Found status messages (check
the URL for mistakes or typos) and various other HTTP failures beyond
your control. If you get a read timeout, increase the L</"ua_timeout">.

=back

From L<Params::Validate>: L<new|/"new">, L<fetch|/"fetch">, L<blame|/"blame">
die if they are passed assorted rubbish as parameters.

From L<DateTime::Format::ISO8601>: L<fetch|/"fetch"> dies if it is passed an
invalid date format.


=head1 CONFIGURATION AND ENVIRONMENT

Mediawiki::Blame requires no configuration files or environment variables.


=head1 DEPENDENCIES

Core modules: L<Carp>

CPAN modules: L<Algorithm::Annotate>, L<Class::Spiffy>, L<DateTime>,
L<DateTime::Format::ISO8601>, L<LWPx::ParanoidAgent>, L<Params::Validate>,
L<Regexp::Common>, L<Readonly>, L<XML::Twig>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-mediawiki-blame@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 TO DO

=over

=item * import offline XML dumps

=item * restore tests against a local Mediawiki

=item * migrate from L<Class::Spiffy> and L<Params::Validate> to L<Moose>

=item * migrate author tests to L<Test::XT>

=back

Suggest more future plans by L<filing a
bug|/"BUGS AND LIMITATIONS">.


=head1 AUTHOR

Lars Dɪᴇᴄᴋᴏᴡ  C<< <daxim@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright © 2007-2009, Lars Dɪᴇᴄᴋᴏᴡ C<< <daxim@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.8.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE »AS IS« WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 SEE ALSO

The B<Levitation> project L<http://levit.at/ion> duplicates some features of
this module.

L<Mediawiki::Blame::Revision>, L<Mediawiki::Blame::Line>
