package Devel::Backtrace;
use strict;
use warnings;
use Devel::Backtrace::Point;
use Carp;

use overload '""' => \&to_string;

=head1 NAME

Devel::Backtrace - Object-oriented backtrace

=head1 VERSION

This is version 0.12.

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

    my $backtrace = Devel::Backtrace->new;

    print $backtrace; # use automatic stringification
                      # See EXAMPLES to see what the output might look like

    print $backtrace->point(0)->line;

=head1 METHODS

=head2 Devel::Backtrace->new()

Optional parameters: -start => $start, -format => $format

If only one parameter is given, it will be used as $start.

Constructs a new C<Devel::Backtrace> which is filled with all the information
C<caller($i)> provides, where C<$i> starts from C<$start>.  If no argument is
given, C<$start> defaults to 0.

If C<$start> is 1 (or higher), the backtrace won't contain the information that
(and where) Devel::Backtrace::new() was called.

=cut

sub new {
    my $class = shift;
    my (@opts) = @_;

    my $start;
    my %pointopts;

    if (1 == @opts) {
        $start = shift @opts;
    }
    while (my $opt = shift @opts) {
        if ('-format' eq $opt) {
            $pointopts{$opt} = shift @opts;
        } elsif ('-start' eq $opt) {
            $start = shift @opts;
        } else {
            croak "Unknown option $opt";
        }
    }

    if (defined $start) {
        $pointopts{'-skip'} = $start;
    } else {
        $start = 0;
    }

    my @backtrace;
    for (my $deep = $start; my @caller = caller($deep); ++$deep) {
	push @backtrace, Devel::Backtrace::Point->new(
            \@caller,
            -level => $deep,
            %pointopts,
        );
    }

    return bless \@backtrace, $class;
}

=head2 $backtrace->point($i)

Returns the i'th tracepoint as a L<Devel::Backtrace::Point> object (see its documentation
for how to access every bit of information).

Note that the following code snippet will print the information of
C<caller($start+$i)>:

    print Devel::Backtrace->new($start)->point($i)

=cut

sub point {
    my $this = shift;
    my ($i) = @_;
    return $this->[$i];
}

=head2 $backtrace->points()

Returns a list of all tracepoints.  In scalar context, the number of
tracepoints is returned.

=cut

sub points {
    my $this = shift;
    return @$this;
}

=head2 $backtrace->skipme([$package])

This method deletes all leading tracepoints that contain information about calls
within C<$package>.  Afterwards the C<$backtrace> will look as though it had
been created with a higher value of C<$start>.

If the optional parameter C<$package> is not given, it defaults to the calling
package.

The effect is similar to what the L<Carp> module does.

This module ships with an example "skipme.pl" that demonstrates how to use this
method.  See also L</EXAMPLES>.

=cut

sub skipme {
    my $this = shift;
    my $package = @_ ? $_[0] : caller;

    my $skip = 0;
    my $skipped;
    while (@$this and $package eq $this->point(0)->package) {
        $skipped = shift @$this;
        $skip++;
    }
    $this->_adjustskip($skip);
    return $skipped;
}

sub _adjustskip {
    my ($this, $newskip) = @_;

    $_->_skip($newskip + ($_->_skip || 0)) for $this->points;
}

=head2 $backtrace->skipmysubs([$package])

This method is like C<skipme> except that it deletes calls I<to> the package
rather than calls I<from> the package.

Before discarding those calls, C<skipme> is called.  This is because usually
the topmost call in the stack is to Devel::Backtrace->new, which would not be
catched by C<skipmysubs> otherwise.

This means that skipmysubs usually deletes more lines than skipme would.

C<skipmysubs> was added in Devel::Backtrace version 0.06.

See also L</EXAMPLES> and the example "skipme.pl".

=cut

sub skipmysubs {
    my $this = shift;
    my $package = @_ ? $_[0] : caller;

    my $skipped = $this->skipme($package);
    my $skip = 0;
    while (@$this and $package eq $this->point(0)->called_package) {
        $skipped = shift @$this;
        $skip++;
    }
    $this->_adjustskip($skip);
    return $skipped;
}

=head2 $backtrace->to_string()

Returns a string that contains one line for each tracepoint.  It will contain
the information from C<Devel::Backtrace::Point>'s to_string() method.  To get
more information, use the to_long_string() method.

Note that you don't have to call to_string() if you print a C<Devel::Backtrace>
object or otherwise treat it as a string, as the stringification operator is
overloaded.

See L</EXAMPLES>.

=cut

sub to_string {
    my $this = shift;
    return join '', map "$_\n", $this->points;
}


=head2 $backtrace->to_long_string()

Returns a very long string that contains several lines for each trace point.
The result will contain every available bit of information.  See
L<Devel::Backtrace::Point/to_long_string> for an example of what the result
looks like.

=cut

sub to_long_string {
    my $this = shift;
    return join "\n", map $_->to_long_string, $this->points;
}


1
__END__

=head1 EXAMPLES

A sample stringification might look like this:

    Devel::Backtrace::new called from MyPackage (foo.pl:30)
    MyPackage::test2 called from MyPackage (foo.pl:28)
    MyPackage::test1 called from main (foo.pl:18)
    main::bar called from main (foo.pl:6)
    main::foo called from main (foo.pl:13)

If MyPackage called skipme, the first two lines would be removed.  If it called
skipmysubs, the first three lines would be removed.

If you don't like the format, you can change it:

    my $backtrace = Devel::Backtrace->new(-format => '%I. %s');

This would produce a stringification of the following form:

    0. Devel::Backtrace::new
    1. MyPackage::test2
    2. MyPackage::test1
    3. main::bar
    4. main::foo

=head1 SEE ALSO

L<Devel::StackTrace> does mostly the same as this module.  I'm afraid I hadn't
noticed it until I uploaded this module.

L<Carp::Trace> is a simpler module which gives you a backtrace in string form.

L<Devel::DollarAt> comes with this distribution and is a nice application of
this module.  You can use it for debugging to get a backtrace out of $@.

=head1 AUTHOR

Christoph Bussenius <pepe@cpan.org>

If you use this module, I'll be glad if you drop me a note.
You should mention this module's name in the subject of your mails, in order to
make sure they won't get lost in all the spam.

=head1 LICENSE

This module is in the public domain.

If your country's law does not allow this module being in the public
domain or does not include the concept of public domain, you may use the
module under the same terms as perl itself.

=cut
