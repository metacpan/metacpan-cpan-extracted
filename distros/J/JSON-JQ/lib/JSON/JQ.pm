package JSON::JQ;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';
# internal flags
our $DEBUG       = 0;
our $DUMP_DISASM = 0;

use FindBin ();
FindBin::again();
use POSIX qw/isatty/;
use Path::Tiny qw/path/;
use JSON qw/from_json/;

# jv_print_flags in jv.h
use enum qw/BITMASK:JV_PRINT_ PRETTY ASCII COLOR SORTED INVALID REFCOUNT TAB ISATTY SPACE0 SPACE1 SPACE2/;
# jq.h
use enum qw/:JQ_DEBUG_=1 TRACE TRACE_DETAIL TRACE_ALL/;

use XSLoader;
XSLoader::load('JSON::JQ', $VERSION);

sub new {
    my ( $pkg, $param ) = @_;

    croak "script or script_file parameter required" unless exists $param->{script} or exists $param->{script_file};
    my $self = {};
    # script string or script file
    $self->{script} = $param->{script} if exists $param->{script};
    $self->{script_file} = $param->{script_file} if exists $param->{script_file};
    # script initial arguments
    $self->{variable} = exists $param->{variable} ? $param->{variable} : {};
    # internal attributes
    $self->{_attribute}->{JQ_ORIGIN} = path($FindBin::Bin)->realpath if $FindBin::Bin;
    $self->{_attribute}->{JQ_LIBRARY_PATH} = exists $param->{library_paths} ? $param->{library_paths} :
        [ '~/.jq', '$ORIGIN/../lib/jq', '$ORIGIN/lib' ];
    $self->{_attribute}->{PROGRAM_ORIGIN} = exists $param->{script_file} ? path($param->{script_file})->parent->stringify : '.';
    # error callback will push error messages into this array
    $self->{_errors} = [];
    # debug callback print flags
    my $dump_opts = JV_PRINT_INDENT_FLAGS(2);
    $dump_opts |= JV_PRINT_SORTED;
    $dump_opts |= JV_PRINT_COLOR | JV_PRINT_ISATTY if isatty(*STDERR);
    $self->{_dumpopts} = $dump_opts;
    # jq debug flags
    $self->{jq_flags} = exists $param->{debug_flag} ? $param->{debug_flag} : 0;
    bless $self, $pkg;
    unless ($self->_init()) {
        croak "jq_compile_args() failed with errors:\n  ". join("\n  ", @{ $self->{_errors} });
    }
    return $self;
}

sub process {
    my ( $self, $param ) = @_;

    my $input;
    if (exists $param->{data}) {
        $input = $param->{data};
    }
    elsif (exists $param->{json}) {
        $input = from_json($param->{json}, { utf8 => 1 });
    }
    elsif (exists $param->{json_file}) {
        my $file = path($param->{json_file});
        $input = from_json($file->slurp_utf8, { utf8 => 1 });
    }
    else {
        croak "JSON::JQ::process(): required parameter not found, check method documentation";
    }
    my $output = [];
    my $rc = $self->_process($input, $output);
    # treat it as option EXIT_STATUS is on
    $rc -= 10 if $rc >= 10;
    if ($rc == 1) {
        # NOTE: treat this case as successful run
        warn "JSON::JQ::process(): returned null/false (undef output), perhaps the input is undef.\n";
    }
    elsif ($rc != 0) {
        croak "JSON::JQ::process(): failed with return code = $rc and errors:\n  ". join("\n  ", @{ $self->{_errors} });
    }
    return wantarray ? @$output : $output;
}

=head1 NAME

JSON::JQ - jq (https://stedolan.github.io/jq/) library binding

=head1 SYNOPSIS

  use JSON::JQ;
  my $jq = JSON::JQ->new({ script => '.' });
  # 1. process perl data
  my $results = $jq->process({ data => { foo => 'bar' }});
  # 2. process json string
  my $results = $jq->process({ json => '{ "foo": "bar" }'});
  # 3. process json file
  my $results = $jq->process({ json_file => 'foo.json' });
  # check items in @$results


=head1 DESCRIPTION

This is L<jq|https://stedolan.github.io/jq/> library binding, making it possible to process
data using jq script/filter/module. Check jq homepage for detail explanation and documentation.


=head1 METHODS

=head2 new({ parameter => value, ... })

Construct a jq engine instance and return it, jq script must be provided by either I<script> or
I<script_file> parameter.

=over 4

=item * script

A string of jq script. The simplist one is '.', which does data 'echo'.

=item * script_file

A path to file which contains jq script. Shell-bang on first line will be ignored safely.

=item * variable

A hash reference with pre-defined variables and their values, they can be used by jq script
later. Complex data structure like nested array and/or hash is acceptable.

Check jq official documentation on how to reference variables inside script.

=item * library_paths

An array reference with one or more directory paths inside. They will be used to search jq
library/module when needed.

The default search paths are I<'~/.jq'> I<'$ORIGIN/../lib/jq'> I<'$ORIGIN/lib'>, which
confirm with jq executable.

Check jq officiall documentation on how to use this functionality in script.

=back

=head2 process({ parameter => value, ... })

Process given input and return results as array reference. The input data must be provided
via one of the prameters below.

=over 4

=item * data

A perl variable representing JSON formed data. The straigh way to understand its equivalent
is the return of C<JSON::from_json> call.

Any other type of data which jq engine will accept can do. Such as I<undef>, which says Null
input. It is useful when the output data is created sorely by script itself.

Bare in mind that jq engine cannot understand (blessed) perl objects, with one exception - object
returned via C<JSON::true()> or C<JSON::false()>. They will be handled by underlying XS code
properly before passing them to jq engine.

Check I<SPECIAL DATA MAPPING> section below.

=item * json

A json encoded string. It will be decoded using C<JSON::from_json> before handling to jq engine.
Which also means, it must fully confirm with JSON speculation.

=item * json_file

Similar to I<json> parameter above, instead read the JSON string from given file.

=back

=head1 SPECIAL DATA MAPPING

Following JSON values are mapped to corresponding Perl values:

=over 4

=item * true: C<JSON::true>

=item * false: C<JSON::false>

=item * null: C<undef>

=back

=head1 CALLBACKS

The following jq engine callbacks are implemented:

=over 4

=item error callback

Any error message raised by jq engine during its initialization and execution will be
pushed into perl instance's private I<_error> attribute. It is transparent to user,
each method will croak on critical errors and show them.

=item debug callback

This is a builtin debug feature of the engine. It prints out debug messages when triggered.
Check jq official docucmentation for more detail.

=back

=head1 DEBUG

Limited debug functionality is implemented via following module variables:

=over 4

=item C<$JSON::JQ::DUMP_DISASM> [default: off]

When on, print out the jq script disassembly code using C<jq_dump_disassembly>.

=item C<$JSON::JQ::DEBUG> [default: off]

B<Internal use only>. When on, print out debug messages from XS code.

=back

=head1 BUGS

Please report bug to https://github.com/dxma/perl5-json-jq/issues

=head1 AUTHOR

    Dongxu Ma
    CPAN ID: DONGXU
    dongxu _dot_ ma _at_ gmail.com
    https://github.com/dxma

=head1 COPYRIGHT

This program is free software licensed under the...

	The MIT License

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

   * L<jq official wiki|https://github.com/stedolan/jq/wiki>

=cut

1;
