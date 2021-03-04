package Log::Any::Adapter::JSON;

our $VERSION = '1.07';

use strict;
use warnings;
use feature 'say';

use Carp qw/ croak confess /;
use JSON::MaybeXS;
use Path::Tiny;
use Time::Moment;
use strictures 2;

use Log::Any::Adapter::Util 'make_method';

use parent 'Log::Any::Adapter::Base';

my $trace_level = Log::Any::Adapter::Util::numeric_level('trace');

sub new {
    my ($class, $filename_or_handle, %args) = @_;

    my $handle;
    my $ref = ref($filename_or_handle);

    if ( $ref && $ref ne 'GLOB' ) {
        croak('Died: Not a filehandle');
    }
    elsif ($ref) {
        $handle = $filename_or_handle;
    }
    else {
        $handle = path($filename_or_handle)->opena;
    }

    $handle->autoflush;

    my $encoding = delete($args{encoding}) || 'UTF-8';
    binmode $handle, ":encoding($encoding)";

    $args{handle}      = $handle;
    $args{log_level} //= $trace_level;

    return $class->SUPER::new(%args);
}

sub structured {
    my $self = shift;
    my ($level, $category, $string, @items) = @_;

    return if Log::Any::Adapter::Util::numeric_level($level) > $self->{log_level};

    my $log_entry = _prepare_log_entry(@_);

    select $self->{handle};
    say $log_entry;
    select STDOUT;
}

sub _prepare_log_entry {
    my ($level, $category, $string, @items) = @_;

    confess 'Died: A log message is required' if ! $string;

    my %log_entry = (
        time     => Time::Moment->now->strftime('%FT%T%5f'),
        level    => $level,
        category => $category,
    );

    # Process pattern and values if present
    my $num_tokens =()= $string =~ m/%s|%d/g;

    if ( $num_tokens ) {
        my @vals = grep { ! ref } splice @items, 0, $num_tokens;

        if ( @vals < $num_tokens ) {
            my $inflected = $num_tokens == 1 ? 'value is' : 'values are';
            confess sprintf('Died: %s scalar %s required for this pattern', $num_tokens, $inflected);
        }

        $log_entry{message} = sprintf($string, @vals);
    }
    else {
        $log_entry{message} = $string;
    }

    # Process structured data and additional messages if present.
    # The first hashref encountered has its keys promoted to top-level.
    my $seen_href;

    for my $item ( @items ) {

        if ( ref($item) eq 'HASH' ) {
            # special handling for Log::Any's context hash
            if ( $item->{context} ) {
                $log_entry{context} = delete $item->{context};
            }

            if ( ! $seen_href ) {
                for my $key ( keys %{ $item } ) {
                    if ( $key =~ /^(?:time|level|category|message)$/ ) {
                        confess sprintf(
                            'Died: %s is a reserved key name and may not be passed in the first hashref',
                            $key,
                        );
                    }

                    $log_entry{$key} = $item->{$key};
                }
                $seen_href++;
            }
            else {
                push @{ $log_entry{hash_data} }, $item;
            }
        }
        elsif ( ref($item) eq 'ARRAY' ) {
            push @{ $log_entry{list_data} }, $item;
        }
        else {
            push ( @{ $log_entry{additional_messages} }, $item);
        }
    }

    my $serializer = JSON::MaybeXS->new(
        utf8      => 0,
        pretty    => 0,
        indent    => 0,
        canonical => 1,
    );

    return $serializer->encode( \%log_entry );
}

#-- Methods required by the base class --------------------------------#

sub init {
    my $self = shift;
    if ( $self->{log_level} && $self->{log_level} =~ /\D/ ) {
        my $numeric_level = Log::Any::Adapter::Util::numeric_level( $self->{log_level} );

        if ( ! defined($numeric_level) ) {
            croak sprintf('Invalid log level [%s]', $self->{log_level});
        }

        $self->{log_level} = $numeric_level;
    }

    if ( ! defined $self->{log_level} ) {
        $self->{log_level} = $trace_level;
    }
}

for my $method ( Log::Any->detection_methods ) {
    my $base = substr($method, 3);
    my $method_level = Log::Any::Adapter::Util::numeric_level( $base );

    make_method( $method, sub {
        return !!(  $method_level <= $_[0]->{log_level} );
    });
}



1; # return true

__END__

=pod

=head1 VERSION

version 1.07

=encoding utf8

=head1 NAME

Log::Any::Adapter::JSON - One-line JSON logging of arbitrary structured data

=head1 SYNOPSIS

Get a logger and specify the output destination:

  use Log::Any '$log';
  use Log::Any::Adapter ('JSON', '/path/to/file.log');

  # or

  use Log::Any '$log';
  use Log::Any::Adapter;

  my $handle = ...; # FH, pipe, etc

  Log::Any::Adapter->set('JSON', $handle);

Log some data:

  $log->info('Hello, world');
  $log->info('Hello, %s', $name);
  $log->debug('Blabla', { tracking_id => 42 });
  $log->debug('Blorgle', { foo => 'bar' }, [qw/a b c/], 'last thing');

=head1 DESCRIPTION

This L<Log::Any> adapter logs formatted messages and arbitrary structured
data in a single line of JSON per entry. You must pass a filename or an open
handle to which the entries will be printed.

Optionally you may pass an C<encoding> argument which will be used to apply
a C<binmode> layer to the output handle. The default encoding is C<UTF-8>.

=head1 OUTPUT

=head2 Logged data fields

The adapter expects a string and an optional list C<@items>.

If the string has no formatting tokens, it is included in the log
entry in the C<message> field as-is.

If the string has formatting tokens, C<@items> is checked to verify
that the next C<N> values are scalars, where C<N> is the number of
tokens in the string. If the number is the same, the string and
tokens are combined using C<sprintf()> and the resulting string is
included in the log entry in the C<message> field. If the token
and value counts don't match, the adapter croaks.

After the format processing, the remainder of the C<items> array is
processed. It may hold arrayrefs, which are included in a top-
level key named C<list_data>; additional scalars, which are pushed
into the C<additional_messages> key; and hashrefs. The first hashref
encountered has its keys promoted to top-level keys in the log entry,
while additional hashrefs are included in a top-level key named
C<hash_data>.

=head2 Other fields

In addition, the log entry will have the following fields:

=over

=item C<time>

=item C<level>

=item C<category>

=back

=head1 EXAMPLES

=head2 Plain text message

  $log->debug('a simple message');

Output is a B<single line> with JSON like:

  {
    "category":"main",
    "level":"debug",
    "message":"hello, world",
    "time":"2021-03-03T17:23:25.73124"
  }

=head2 Formatted message

  my $val = "string";
  my $num = 2;

  $log->debug('a formatted %s with %d tokens', $val, $num);

Output is a B<single line> with JSON like:

  {
    "category":"main",
    "level":"debug",
    "message":"a formatted string with 2 tokens",
    "time":"2021-03-03T17:23:25.73124"
  }

=head2 Single hashref

The first hashref encountered has its keys elevated to the top level.

  $log->debug('the message', { tracker => 42 });

Output is a B<single line> with JSON like:

    {
      "category":"main",
      "level":"debug",
      "message":"the message",
      "time":"2021-03-03T17:23:25.73124",
      "tracker":42
    }

Reserved key names that may not be used in the first hashref include:

  * category
  * context
  * level
  * message
  * time

=head2 Additional hashrefs and arrayrefs

  $log->debug('the message', { tracker => 42 }, { foo => 'bar'});

Output is a B<single line> with JSON like:

  {
    "category":"main",
    "hash_data":{
      "foo":"bar"
    },
    "level":"debug",
    "message":"the message",
    "time":"2021-03-03T17:23:25.73124",
    "tracker":42
  }

Another example:

  $log->debug('the message', { tracker => 42 }, {foo => 'bar'}, [1..3]);

Output is a B<single line> with JSON like:

  {
    "category":"main",
    "hash_data":[
      {"foo":"bar"}
    ],
    "level":"debug",
    "list_data":[
      [1,2,3]
    ],
    "message":"the message",
    "time":"2021-03-03T17:23:25.73124",
    "tracker":42
}

=head2 Additional messages

Any scalars that are passed that are not consumed as the values of formatting
tokens will be included in an C<additional_messages> key.

  $log->debug('a simple message', 'foo', 'bar');

Output is a B<single line> with JSON like:

  {
    "additional_messages":[
      'foo',
      'bar'
    ],
    "category":"main",
    "level":"debug",
    "message":"hello, world",
    "time":"2021-03-03T17:23:25.73124"
  }

=head1 SEE ALSO

L<Log::Any>

L<Log::Any::Adapter>

=head1 AUTHOR

Nick Tonkin <tonkin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Nick Tonkin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
