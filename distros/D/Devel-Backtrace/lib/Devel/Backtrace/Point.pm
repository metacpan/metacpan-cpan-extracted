package Devel::Backtrace::Point;
use strict;
use warnings;
our $VERSION = '0.11';
use Carp;
use String::Escape qw(printable);

=head1 NAME

Devel::Backtrace::Point - Object oriented access to the information caller()
provides

=head1 SYNOPSIS

    print Devel::Backtrace::Point->new([caller(0)])->to_long_string;

=head1 DESCRIPTION

This class is a nice way to access all the information caller provides on a
given level.  It is used by L<Devel::Backtrace>, which generates an array of
all trace points.

=cut

use base qw(Class::Accessor::Fast);
use overload '""' => \&to_string;
use constant;

BEGIN {
    my @known_fields = (qw(package filename line subroutine hasargs wantarray
        evaltext is_require hints bitmask hinthash));
    # The number of caller()'s return values depends on the perl version.  For
    # instance, hinthash is not available below perl 5.9.  We try and see how
    # many fields are supported
    my $supported_fields_number = () = caller(0)
        or die "Caller doesn't work as expected";

    # If not all known fields are supported, remove some
    while (@known_fields > $supported_fields_number) {
        pop @known_fields;
    }

    # If not all supported fields are known, add placeholders
    while (@known_fields < $supported_fields_number) {
        push @known_fields, "_unknown".scalar(@known_fields);
    }

    constant->import (FIELDS => @known_fields);
}

=head1 METHODS

=head2 $p->package, $p->filename, $p->line, $p->subroutine, $p->hasargs,
$p->wantarray, $p->evaltext, $p->is_require, $p->hints, $p->bitmask,
$p->hinthash

See L<perlfunc/caller> for documentation of these fields.

hinthash is only available in perl 5.9 and higher.  When this module is loaded,
it tests how many values caller returns.  Depending on the result, it adds the
necessary accessors.  Thus, you should be able to find out if your perl
supports hinthash by using L<UNIVERSAL/can>:

    Devel::Backtrace::Point->can('hinthash');

=cut

__PACKAGE__->mk_ro_accessors(FIELDS);

=head2 $p->level

This is the level given to new().  It's intended to be the parameter that was
given to caller().

=cut

__PACKAGE__->mk_ro_accessors('level');

=head2 $p->called_package

This returns the package that $p->subroutine is in.

If $p->subroutine does not contain '::', then '(unknown)' is returned.  This is
the case if $p->subroutine is '(eval)'.

=cut

sub called_package {
    my $this = shift;
    my $sub = $this->subroutine;

    my $idx = rindex($sub, '::');
    return '(unknown)' if -1 == $idx;
    return substr($sub, 0, $idx);
}

=head2 $p->by_index($i)

You may also access the fields by their index in the list that caller()
returns.  This may be useful if some future perl version introduces a new field
for caller, and the author of this module doesn't react in time.

=cut

sub by_index {
    my ($this, $idx) = @_;
    my $fieldname = (FIELDS)[$idx];
    unless (defined $fieldname) {
        croak "There is no field with index $idx.";
    }
    return $this->$fieldname();
}

=head2 new([caller($i)])

This constructs a Devel::Backtrace object.  The argument must be a reference to
an array holding the return values of caller().  This array must have either
three or ten elements (or eleven if hinthash is supported) (see
L<perlfunc/caller>).

Optional additional parameters:

    -format => 'formatstring',
    -level => $i

The format string will be used as a default for to_string().

The level should be the parameter that was given to caller() to obtain the
caller information.

=cut

__PACKAGE__->mk_ro_accessors('_format');
__PACKAGE__->mk_accessors('_skip');

sub new {
    my $class = shift;
    my ($caller, %opts) = @_;

    my %data;

    unless ('ARRAY' eq ref $caller) {
        croak 'That is not an array reference.';
    }

    if (@$caller == (() = FIELDS)) {
        for (FIELDS) {
            $data{$_} = $caller->[keys %data]
        }
    } elsif (@$caller == 3) {
        @data{qw(package filename line)} = @$caller;
    } else {
        croak 'That does not look like the return values of caller.';
    }

    for my $opt (keys %opts) {
        if ('-format' eq $opt) {
            $data{'_format'} = $opts{$opt};
        } elsif ('-level' eq $opt) {
            $data{'level'} = $opts{$opt};
        } elsif ('-skip' eq $opt) {
            $data{'_skip'} = $opts{$opt};
        } else {
            croak "Unknown option $opt";
        }
    }

    return $class->SUPER::new(\%data);
}

sub _virtlevel {
    my $this = shift;

    return $this->level - ($this->_skip || 0);
}

=head2 $tracepoint->to_string()

Returns a string of the form "Blah::subname called from main (foo.pl:17)".
This means that the subroutine C<subname> from package C<Blah> was called by
package C<main> in C<foo.pl> line 17.

If you print a C<Devel::Backtrace::Point> object or otherwise treat it as a
string, to_string() will be called automatically due to overloading.

Optional parameters: -format => 'formatstring'

The format string changes the appearance of the return value.  It can contain
C<%p> (package), C<%c> (called_package), C<%f> (filename), C<%l> (line), C<%s>
(subroutine), C<%a> (hasargs), C<%e> (evaltext), C<%r> (is_require), C<%h>
(hints), C<%b> (bitmask), C<%i> (level), C<%I> (level, see below).

The difference between C<%i> and C<%I> is that the former is the argument to
caller() while the latter is actually the index in $backtrace->points().  C<%i>
and C<%I> are different if C<-start>, skipme() or skipmysubs() is used in
L<Devel::Backtrace>.

If no format string is given, the one passed to C<new> will be used.  If none
was given to C<new>, the format string defaults to 'default', which is an
abbreviation for C<%s called from %p (%f:%l)>.

Format strings have been added in Devel-Backtrace-0.10.

=cut

my %formats = (
    'default' => '%s called from %p (%f:%l)',
);

my %percent = (
    'p' => 'package',
    'c' => 'called_package',
    'f' => 'filename',
    'l' => 'line',
    's' => 'subroutine',
    'a' => 'hasargs',
    'w' => 'wantarray',
    'e' => 'evaltext',
    'r' => 'is_require',
    'h' => 'hints',
    'b' => 'bitmask',
    'i' => 'level',
    'I' => '_virtlevel',
);

sub to_string {
    my ($this, @opts) = @_;

    my %opts;
    if (defined $opts[0]) { # check that we are not called as stringification
        %opts = @opts;
    }

    my $format = $this->_format();

    for my $opt (keys %opts) {
        if ($opt eq '-format') {
            $format = $opts{$opt};
        } else {
            croak "Unknown option $opt";
        }
    }

    $format = 'default' unless defined $format;
    $format = $formats{$format} if exists $formats{$format};

    my $result = $format;
    $result =~ s{%(\S)} {
        my $percent = $percent{$1} or croak "Unknown symbol %$1\n";
        my $val = $this->$percent();
        defined($val) ? printable($val) : 'undef';
    }ge;

    return $result;
}

=head2 $tracepoint->to_long_string()

This returns a string which lists all available fields in a table that spans
several lines.

Example:

    package: main
    filename: /tmp/foo.pl
    line: 6
    subroutine: main::foo
    hasargs: 1
    wantarray: undef
    evaltext: undef
    is_require: undef
    hints: 0
    bitmask: \00\00\00\00\00\00\00\00\00\00\00\00

hinthash is not included in the output, as it is a hash.

=cut

sub to_long_string {
    my $this = shift;
    return join '',
    map {
	"$_: " .
	(defined ($this->{$_}) ? printable($this->{$_}) : 'undef')
	. "\n"
    } grep {
        ! /^_/ && 'hinthash' ne $_
    } FIELDS;
}

=head2 FIELDS

This constant contains a list of all the available field names.  The number of
fields depends on your perl version.

=cut

1
__END__

=head1 SEE ALSO

L<Devel::Backtrace>

=head1 AUTHOR

Christoph Bussenius <pepe@cpan.org>

=head1 LICENSE

This Perl module is in the public domain.

If your country's law does not allow this module being in the public
domain or does not include the concept of public domain, you may use the
module under the same terms as perl itself.

=cut
