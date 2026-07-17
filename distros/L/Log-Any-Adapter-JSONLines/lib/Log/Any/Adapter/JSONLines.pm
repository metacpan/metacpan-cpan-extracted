package Log::Any::Adapter::JSONLines;
use strict;
use warnings;
use 5.008_001;

# ABSTRACT: One-line JSON logging of arbitrary structured data in JSON Lines format.

our $VERSION = '0.001';

use Carp qw( croak );
use JSON;

use Log::Any::Adapter::Util 'make_method';

use Log::Any::Adapter::Base;
our @ISA = qw/Log::Any::Adapter::Base/;    ## no critic (ClassHierarchies::ProhibitExplicitISA)

my $DEFAULT_CANONICAL   = 0;
my $DEFAULT_LOG_LEVEL   = Log::Any::Adapter::Util::numeric_level('trace');
my $DEFAULT_FILE_HANDLE = \*STDOUT;
my $DEFAULT_ENCODING    = 'UTF-8';

sub structured {
    my ( $self, $level, $category, @args ) = @_;

    return if Log::Any::Adapter::Util::numeric_level($level) > $self->{log_level};

    my $log_entry = $self->_prepare_log_entry( $level, $category, @args );

    if ( exists $self->{handle} ) {
        print { $self->{handle} } $log_entry, "\n" or croak('Cannot write JSON to open handle');
    }
    else {
        open my $handle, ">>:encoding($self->{encoding})", $self->{file}
          or croak( sprintf 'Cannot open file "%s" for appending', $self->{file} );
        $handle->autoflush;
        print {$handle} $log_entry, "\n"
          or croak( sprintf 'Cannot write JSON to file "%s"', $self->{file} );
        close $handle or croak( sprintf 'Cannot close file "%s" after opening it', $self->{file} );
    }
    return;
}

sub _prepare_log_entry {
    my ( $self, $level, $category, @args ) = @_;

    my %log_entry;

    # The assumption is that a "normal" case would involve
    # one SCALAR (text) and one HASH, the structured data.
    # => text goes to "message" and hash properties are promoted
    # to top level.
    # (If user is using logging context, Log::Any places them
    # as the last item in @args. If there already is a HASH, they are
    # added to it.
    # In any other case, all @items are pushed to array
    # in JSON property "messages".

    ## no critic (ControlStructures::ProhibitCascadingIfElse)
    if ( @args == 1 && ref $args[0] eq q{} ) {
        $log_entry{message} = $args[0];
    }
    elsif ( @args == 1 && ref $args[0] eq 'HASH' ) {
        %log_entry = %{ $args[0] };
    }
    elsif ( @args == 1 && ref $args[0] eq q{ARRAY} ) {
        $log_entry{messages} = $args[0];
    }
    elsif ( @args == 2 && ref $args[0] eq q{} && ref $args[1] eq 'HASH' ) {
        $log_entry{message} = $args[0];
        %log_entry = ( %log_entry, %{ $args[1] } );
    }
    else {
        for my $item (@args) {
            if ( ref($item) eq 'CODE' ) {
                push @{ $log_entry{messages} }, $item->();
            }
            else {
                push @{ $log_entry{messages} }, $item;
            }
        }
    }

    foreach my $hook ( @{ $self->{hooks}->{before} } ) {
        $hook->( $level, $category, \%log_entry );
    }

    return $self->{serializer}->encode( \%log_entry );
}

#-- Methods required by the base class --------------------------------#

sub init {
    my ($self) = @_;
    if ( defined $self->{log_level} && $self->{log_level} =~ /\D/msx ) {
        my $numeric_level = Log::Any::Adapter::Util::numeric_level( $self->{log_level} );
        if ( !defined $numeric_level ) {
            croak( sprintf 'Invalid log level "%s"', $self->{log_level} );
        }
        $self->{log_level} = $numeric_level;
    }
    elsif ( !defined $self->{log_level} ) {
        $self->{log_level} = $DEFAULT_LOG_LEVEL;
    }
    $self->{canonical}       = $self->{canonical}       ? $self->{canonical}       : $DEFAULT_CANONICAL;
    $self->{encoding}        = $self->{encoding}        ? $self->{encoding}        : $DEFAULT_ENCODING;
    $self->{hooks}           = $self->{hooks}           ? $self->{hooks}           : { before => [], proxy => [], };
    $self->{hooks}->{before} = $self->{hooks}->{before} ? $self->{hooks}->{before} : [];
    $self->{hooks}->{proxy}  = $self->{hooks}->{proxy}  ? $self->{hooks}->{proxy}  : [];
    if ( exists $self->{file} ) {
        my $ref = ref $self->{file};
        if ( $ref && $ref ne 'GLOB' ) {
            croak( sprintf 'Invalid file "%s"', $self->{file} );
        }
        elsif ($ref) {

            # File is an open filehandle
            $self->{handle} = $self->{file};
        }
        else {
            # A quick test to see we can open the file for writing.
            open my $handle, ">>:encoding($self->{encoding})", $self->{file}
              or croak( sprintf 'Cannot open file "%s" for appending', $self->{file} );
            close $handle or croak( sprintf 'Cannot close file "%s" after opening it', $self->{file} );
        }
    }
    else {
        $self->{handle} = $DEFAULT_FILE_HANDLE;
    }
    ## no critic (ValuesAndExpressions::ProhibitLongChainsOfMethodCalls)
    my $serializer = JSON->new->utf8(1)->pretty(0)->indent(0)->space_before(0)->space_after(0)
      ->canonical( $self->{canonical} )    # sort keys? no, avoid overhead!
      ;
    $self->{serializer} = $serializer;
    return;
}

# Create detection methods: is_debug, is_info, etc.
#
foreach my $method ( Log::Any::Adapter::Util::detection_methods() ) {
    my $base         = ( $method =~ m/^is_(\w+)$/msx )[0];
    my $method_level = Log::Any::Adapter::Util::numeric_level($base);
    make_method(
        $method,
        sub {
            return !!( $method_level <= $_[0]->{log_level} );
        }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::JSONLines - One-line JSON logging of arbitrary structured data in JSON Lines format.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    # Print to STDOUT:
    use Log::Any::Adapter( 'JSONLines' );

    # Print to a filehandle:
    use Log::Any::Adapter( 'JSONLines', file => \*STDERR, );

    # Print to a file, define logging level and JSON encoding, and
    # sort JSON properties alphabetically:
    use Log::Any::Adapter( 'JSONLines',
        file => 'out.json',
        log_level => 'fatal',
        encoding => 'UTF-8',
        canonical => 1,
    );

    # JSONLines uses hooks:
    use Log::Any::Adapter ('JSONLines', hooks => {
      before => [ \&add_pid, ],
    });
    sub add_pid {
      my ($level, $category, $data) = @_;
      $data->{pid} = $$;
      return;
    }

=head1 DESCRIPTION

You want to write the log messages as JSON according to
the L<JSON Lines|https://jsonlines.org/> text file format.

This L<Log::Any> adapter logs formatted messages and arbitrary structured
data in a single line of JSON per entry. By default,
it writes to STDOUT. You can also write to any file or open filehandle.

By default we write all log levels starting from trace,
but you can set a higher level if needed.

It works with
L<Log::Any Context|https://metacpan.org/pod/Log::Any#Log-context-data>
data as well as any other structured data.

You can "hook into" the printing process right before the JSON
is created if you need to add or remove properties or
alter properties, for example, mask values.

=for Pod::Coverage structured init

=for stopwords debugf

=head1 REQUIREMENTS

=head2 Perl Version

Required perl: 5.8.1 or above. Same as L<Log::Any>.

This module uses L<JSON> (version 4.10 at the point of writing this document).
JSON uses L<JSON::XS> as its backend by default,
and when not available, it falls back on L<JSON::PP>,
which has been in the Perl core since 5.14.

Module L<JSON> can use other backends. Please see
the module docs for more information.

=head2 Dependencies

=over

=item L<JSON>

=item L<Log::Any::Adapter::Util> which is part of L<Log::Any>.

=back

=head1 USAGE

The simplest way to get JSON logs:

    use Log::Any::Adapter( 'JSONLines' );

By default Log::Any::Adapter::JSONLines writes to STDOUT and finishes
every full JSON object with a linefeed, '\n'.
By default, it sets the log level to TRACE, the lowest level.
By default, it sets the category to "all" so it will record
logging messages from every producer.

Place the example above into the script or module which is producing
logs or using other modules which do.

Please see below for explanation of the parameters.

=head2 Hooks

A situation can arise when you would like to modify
the JSON right before it gets printed.

You may pass a C<hooks> parameter to the constructor. It should be a hashref
with keys C<before> and C<proxy>, which should be an arrayref of coderefs.
Each coderef will be called with the C<level>, C<category>, and a hashref
representing the log entry. The coderef may modify the log entry hashref
in place. These will be executed in the order they are written.

The C<proxy> hooks are executed in the logging proxy,
class L<Log::Any::Proxy> or its child class.

The hooks have different arguments.
First three are same: B<level>, B<category> and B<data> (the log entry).
The hook C<proxy> has an additional parameter: B<info>.
This contains two keys: B<calling_sub> and B<proxy>.
B<proxy> is a pointer to the Proxy class in which the hook
is being executed and B<calling_sub> is the name of the subroutine
in which the hook is being executed.
B<calling_sub> is either trace|debug|info|fatal|... or their
"f" (formatting) equivalent.

    use Log::Any::Adapter ('JSONLines', hooks => {
      before => [ \&add_pid, \&shorten ],
      proxy  => [ \&add_location ],
    });
    sub add_pid {
      my ($level, $category, $data) = @_;
      $data->{pid} = $$;
      return;
    }
    sub shorten {
        my ($level, $category, $data) = @_;
        $data->{msg} = delete $data->{message};
        return;
    }
    sub add_location {
        my ($level, $category, $data, $info) = @_;
        my $frames = substr( $info->{calling_sub}, -1, 1 ) eq 'f' ? 2 : 1;
        $data->{file} = (caller $frames)[1];
        $data->{line} = (caller $frames)[2];
        $data->{file} =~ s/\/home\/mikkoi\/tmp\/[\w-]+/\[..\]/gmsx;
    }

=head2 Logging

You are most likely to use structured logging like this:

    use Log::Any qw( $log );
    $log->debug('Create account', { nr=>'12345', user=>'Smith'});

Or, if you use logging context, like this:

    use Log::Any qw( $log );
    $log->context->{user} = 'Smith';
    $log->debug('Create account', { nr=>'12345' });

Or like this:

    use Log::Any qw( $log );
    $log->context->{user} = 'Smith';
    $log->context->{nr} = '12345';
    $log->debug('Create account');

All three would produce the same JSON (subject to changing sorting order):

    {"message":"Create account","nr":"12345","user":"Smith"}

B<A common logging command consists of a plain text string and a possible hash.>

=head2 Caveats

If there is more than two items provided to this Log::Any::Adapter,
we will do things differently:

    use Log::Any qw( $log );
    $log->debug('Create account', 'New Account', { nr=>'12345'}, {user=>'Smith'});

The produced JSON contains property B<messages> instead of B<message>:

    {"messages":["Create account","New Account",{"nr":"12345"},{"user":"Smith"}]}

You also cannot use the formatting functions, e.g. B<debugf>:

    $log->debugf('Create account: %s', '12345', {user=>'Smith'});

This is due to L<Log::Any> standard proxy L<Log::Any::Proxy>
using B<sprintf> function which discards extra attributes.
Log::Any (sprintf) cannot tell that the remaining arguments
are, in fact, additional structures.
If you turn on all warnings, Perl will show a warning
about redundant argument in sprintf.

However, Log::Any context will work as expected.

Other special cases are:

    use Log::Any qw( $log );
    $log->debug([ 1, 2, 3, 4, 5 ]);
    $log->debug(sub { return "Lastname, Firstname"; });
    $log->debug("Person:", sub { return "Lastname, Firstname"; });

    $log->context->{user} = 'Smith';
    $log->context->{nr} = '12345';
    $log->debug({user=>'Johnson'});

Results with:

    {"messages":[1,2,3,4,5]}
    {"message":"Lastname, Firstname"}
    {"messages":["Person:","Lastname, Firstname"]}

    {"nr":"12345","user":"Johnson"}

=head1 PARAMETERS

=head2 file

Stream or open filehandle or a file path.
E.g. B<\*STDERR>,
B<out.json>.

Default: \*STDOUT

=head2 log_level

Set log_level. Allowed values: digits 0-8,
L<level name constants|https://metacpan.org/pod/Log::Any::Adapter::Util#Log-level-constants>
in upper and lower case.

Default: trace

=head2 canonical

Do you want the JSON properties alphabetically sorted?
Set this to "1".
Be warned! Sorting is a time consuming operation.
If you mostly pump the logs somewhere else for analysis,
sorting is unnecessary.

If you need this on terminal during development or debugging,
you might find F<logviewer.pl> in F<examples/> useful.

Default: 0

=head2 encoding

Set encoding of the out file.

Default: UTF-8

=head1 EXAMPLES

    # Use hooks to modify the JSON:
    use Log::Any::Adapter( 'JSONLines',
        hooks => {
            before => [ \&prepare_json, \&mask_card_number, ]
        },
    );
    sub prepare_json {
        my ($level, $category, $log_entry) = @_;
        $log_entry->{epoch}  = time;
        $log_entry->{lvl} = $level;
        $log_entry->{cat} = $category;
        $log_entry->{msg} = delete $log_entry->{message};
        return;
    }
    sub mask_card_number {
        my ($level, $category, $log_entry) = @_;
        my $last_nums = ($log_entry->{card} =~ m/^[0-9]{12}([0-9]{4})$/msx)[0];
        $log_entry->{card} = q{XXXX XXXX XXXX } . $last_nums;
        return;
    }

Please see the directory F<examples> for more examples.
It also contains file F<logviewer.pl>
as an example of how to make the JSON logs readable
in the terminal.

=head1 STATUS

This module is currently being developed so changes in the API are possible.

=head1 THANKS

Big thanks to L<Log::Any::Adapter::JSON> for being an inspiration
and example for this module.

=head1 SEE ALSO

L<Log::Any>

L<Log::Any::Adapter>

L<Log::Any::Adapter::JSON> is similar to this module but
not oriented towards the special case of
L<JSON Lines|https://jsonlines.org/> text file format.

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
