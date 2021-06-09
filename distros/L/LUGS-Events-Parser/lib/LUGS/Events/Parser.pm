package LUGS::Events::Parser;

use strict;
use warnings;
use base qw(LUGS::Events::Parser::Filter);
use boolean qw(true false);

use Carp qw(croak);
use DateTime ();
use List::MoreUtils qw(all);
use LUGS::Events::Parser::Event ();
use Params::Validate ':all';

our $VERSION = '0.12';

validation_options(
    on_fail => sub
{
    my ($error) = @_;
    chomp $error;
    croak $error;
},
    stack_skip => 2,
);

sub new
{
    my $class = shift;

    my $self = bless {}, ref($class) || $class;
    $self->_init(@_);

    $self->_fetch_content;
    $self->_parse_content;

    return $self;
}

sub _init
{
    my $self = shift;
    validate_pos(@_, { type => SCALAR, callbacks => { 'is a file' => sub { -f shift } } },
                     { type => HASHREF, optional => true });

    my ($file, $opts) = @_;

    $self->{Input} = $file;

    if (ref $opts eq 'HASH') {
        my $valid_handlers = sub
        {
            my ($data) = @_;

            return false unless ref $data eq 'HASH';

            foreach my $tagname (keys %$data) {
                return false unless ref $data->{$tagname} eq 'ARRAY';
                return false unless scalar @{$data->{$tagname}};

                foreach my $entry (@{$data->{$tagname}}) {
                    return false unless ref $entry eq 'HASH';

                    my %keys = map { $_ => true } keys %$entry;

                    return false unless scalar keys %keys == 2;
                    return false unless all { exists $keys{$_} } qw(rewrite fields);

                    return false unless ref \$entry->{rewrite} eq 'SCALAR';
                    return false unless ref  $entry->{fields}  eq 'ARRAY';

                    return false unless scalar @{$entry->{fields}};
                }
            }

            return true;
        };

        my @args = %$opts;
        validate(@args, {
            filter_html => {
                # SCALARREF due to boolean.pm's implementation
                type => BOOLEAN | SCALARREF,
            },
            tag_handlers => {
                type => HASHREF,
                callbacks => {
                    'valid data' => sub
                    {
                        $valid_handlers->(shift);
                    },
                },
            },
            purge_tags => {
                type => ARRAYREF,
                optional => true,
            },
            strip_text => {
                type => ARRAYREF,
                optional => true,
            },
        });

        foreach my $opt (qw(filter_html purge_tags strip_text tag_handlers)) {
            $self->{ucfirst $opt} = $opts->{$opt};
        }

        $self->{Purge_tags} ||= [];
        $self->{Strip_text} ||= [];
    }

    if ($self->{Filter_html}) {
        $self->{parser} = $self->_init_parser;
    }
}

sub _fetch_content
{
    my $self = shift;

    open(my $fh, '<', $self->{Input}) or croak "Cannot open `$self->{Input}': $!";
    $self->{content} = do { local $/; <$fh> };
    close($fh);
}

sub _parse_content
{
    my $self = shift;

    my @events = $self->{content} =~ /(^event .*? ^endevent)/gmsx;
    my (@data, %ids);

    foreach my $event (@events) {
        my @fields = split /\n/, $event;
        my %fields;

        foreach my $field (@fields) {
            if (my ($text) = $field =~ /^event \s+ (.+)/x) {
                $fields{event} = $text;
            }
            elsif ($field =~ /^endevent \z/x) {
                last;
            }
            else {
                my ($name, $text) = $field =~ /^\s+ (\w+?) \s+ (.*)/x;
                if ($self->{Filter_html}) {
                    my @html;
                    $self->_parse_html($text, \@html);
                    if (@html) {
                        $self->_strip_html(\@html);
                        push @{$fields{_html}->{$name}}, @html;
                    }
                }
                my $exists = exists $fields{$name};
                $fields{$name} .= $exists ? " $text" : $text;
            }
        }

        if ($self->{Filter_html}) {
            $self->_strip_text(\%fields);
            $self->_rewrite_tags(\%fields);
            $self->_purge_tags(\%fields);
            $self->_decode_entities(\%fields);
            $self->_encode_safe(\%fields);
        }

        my ($year, $month, $day) = $fields{event} =~ /^(\d{4})(\d{2})(\d{2})$/;
        my $dt = DateTime->new(year => $year, month => $month, day => $day);
        my $i = 1;
        my %weekdays = map { $i++ => $_ } qw(Mo Di Mi Do Fr Sa So);

        $fields{day}     ||= $1 if $day =~ /^0?(.+)$/;
        $fields{weekday} ||= $weekdays{$dt->day_of_week};

        my ($event, $color) = map $fields{$_}, qw(event color);
        my $id = $ids{$event}->{$color}++;
        $fields{anchor} = join '_', ($event, $id, $color);

        push @data, LUGS::Events::Parser::Event->new(%fields);
    }

    if ($self->{Filter_html}) {
        $self->_eof_parser;
    }

    $self->{data} = \@data;
}

sub next_event
{
    my $self = shift;

    return $self->{data}->[$self->{index}++];
}

1;
__END__

=head1 NAME

LUGS::Events::Parser - Event parser for the Linux User Group Switzerland

=head1 SYNOPSIS

 use LUGS::Events::Parser;

 $parser = LUGS::Events::Parser->new($events_file);

 while ($event = $parser->next_event) {
     $date = $event->get_event_date;
     ...
 }

=head1 DESCRIPTION

C<LUGS::Events::Parser> parses the events file of the Linux User Group
Switzerland (LUGS). It offers according accessor methods and may optionally
filter HTML markup.

=head1 CONSTRUCTOR

=head2 new

Creates a new C<LUGS::Events::Parser> object.

Without options:

 $parser = LUGS::Events::Parser->new('/path/to/events_file');

With filtering options (example):

 $parser = LUGS::Events::Parser->new('/path/to/events_file', {
           filter_html  => 1,
           tag_handlers => {
               'a href' => [ {
                   rewrite => '$TEXT - $HREF',
                   fields  => [ qw(location responsible) ],
               } ],
           },
           purge_tags => [ qw(responsible) ],
           strip_text => [ 'mailto:' ],
 });

=over 4

=item * C<filter_html>

Extract HTML and rewrite it. Accepts a boolean.

=item * C<tag_handlers>

Handlers for rewriting HTML. See L<TAG HANDLERS> for a format explanation.

=item * C<purge_tags>

Optionally purge all remaining tags without attribute values. Accepts an
array reference with field names.

=item * C<strip_text>

Optionally strip text from filtered content. Accepts an array reference
with literals.

=back

=head1 METHODS

=head2 next_event

 $event = $parser->next_event;

Returns a C<LUGS::Events::Parser::Event> object.

=head2 get_event_date

 $date = $event->get_event_date;

Fetch the full C<'event'> date field.

=head2 get_event_year

 $year = $event->get_event_year;

Fetch the event year.

=head2 get_event_month

 $month = $event->get_event_month;

Fetch the event month.

=head2 get_event_day

 $day = $event->get_event_day;

Fetch the event day.

=head2 get_event_simple_day

 $simple_day = $event->get_event_simple_day;

Fetch the event C<'day'> field (without zeroes).

=head2 get_event_weekday

 $weekday = $event->get_event_weekday;

Fetch the event C<'weekday'> field.

=head2 get_event_time

 $time = $event->get_event_time;

Fetch the event C<'time'> field.

=head2 get_event_title

 $title = $event->get_event_title;

Fetch the event C<'title'> field.

=head2 get_event_color

 $color = $event->get_event_color;

Fetch the event C<'color'> field.

=head2 get_event_location

 $location = $event->get_event_location;

Fetch the event C<'location'> field.

=head2 get_event_responsible

 $responsible = $event->get_event_responsible;

Fetch the event C<'responsible'> field.

=head2 get_event_more

 $more = $event->get_event_more;

Fetch the event C<'more'> field.

=head2 get_event_anchor

 $anchor = $event->get_event_anchor;

Fetch the unique event anchor.

=head1 FILTERING AND REWRITING

Filtering HTML markup and separating it from plaintext is optional and may
be enabled via the C<filter_html> option. The C<filter_html> option set on
its own does not suffice since no according tag handlers are defined which
must be provided by the C<tag_handlers> option. Remaining tags without
attribute values may be purged by the C<purge_tags> option. The C<strip_text>
option may contain literal strings to be removed from the filtered and
rewritten content.

The order of processing is: HTML markup is filtered first and then being
rewritten by the according tag handlers. Next tags are purged if requested.
Then literal strings as specified are stripped from the content. Finally,
HTML entities are unconditionally decoded and furthermore, some field values
encoded to UTF-8.

C<LUGS::Events::Parser> internally uses L<HTML::Parser> to push tags and text
on a stack. If tags are nested, the innermost tag will be retrieved first and
the outermost tag last. The top of the stack will be removed after the data
for each tag set has been gathered completely.

=head1 TAG HANDLERS

HTML markup is rewritten through the tag handlers provided within the options
of the constructor. The handlers of a tag group are referenced by either its
tagname or its tagname and an attribute name. Each handler must consist of a
mandatory C<rewrite> and C<fields> entry. The C<rewrite> entry defines the
substitute pattern for HTML markup (i.e., start tag, text and end tag) found.
The pattern may consist of placeholders (e.g., C<$NAME>), simple text or both.
It may also be empty (which has the effect of removing the markup and text
entirely).

For tags which enclose text, the placeholder C<$TEXT> will represent the
enclosed text. If attributes are available, for example C<href>, then C<$HREF>
will contain the value of the C<href> attribute. Placeholders provided for
standalone tags will not be substituted.

The C<fields> entry contains the field names to which rewriting applies.
Specifying a literal C<*> will match all field names.

=head1 SEE ALSO

L<http://www.lugs.ch/lugs/>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
