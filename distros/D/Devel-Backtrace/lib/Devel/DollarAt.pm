package Devel::DollarAt;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Devel::Backtrace;

our $VERSION = '0.02';

__PACKAGE__->mk_accessors(
    qw(backtrace err propagated inputline inputhandle filename line)
);

# Note that to_string also internally called if an exception isn't catched by
# any eval and the error must be printed to STDERR.
use overload '""' => \&to_string;

$SIG{__DIE__} = \&_diehandler;

our $FRAME;

# This will be called every time the code says "die".  However it won't be
# called for other errors, such as division by zero.  So we still have to use
# $SIG{__DIE__}.
*CORE::GLOBAL::die = sub (@) {
    my $text = '';
    defined and $text .= $_ for @_;

    my $err = $@;

    if (defined($err) && length($err) && !length $text) {
	# In this case, perl would pass "$@\t...propagated at foo line bar.\n"
	# to the __DIE__ handler.  Because we don't want to parse that, we make
	# perl think $text is not empty.

	# We have to store $err in our NullMessage because perl will cleanse $@
	# before calling the __DIE__ handler.  This is very strange, because it
	# won't get cleansed if we don't override *CORE::GLOBAL::die.
	$text = Devel::DollarAt::NullMessage->_new(propagated=>$err);
    }

    CORE::die($text);
};

sub _diehandler {
    my ($err) = @_;

    my $propagated = $@;

    if (ref($err) && $err->isa('Devel::DollarAt::NullMessage')) {
	$propagated = $err->{propagated};
	$err = '';
    }

    my $backtrace = Devel::Backtrace->new(1);
    my $skip = $backtrace->skipmysubs(); # skips this handler plus our overridden
				         # CORE::GLOBAL::die if possible
    CORE::die "Strange:\n$backtrace" unless $skip;

    my ($inputhandle, $inputline);
    if ($err =~ s/^(.*) at .*?(?:<(.*)> line (\d+)|)\.\n\z/$1/s) {
	($inputhandle, $inputline) = ($2, $3);
    }

    my $dollarat = __PACKAGE__->_new({
	    backtrace => $backtrace,
	    err => $err,
	    filename => $skip->filename,
	    line => $skip->line,
	}
    );

    if (defined $inputline) {
	$dollarat->inputline($inputline);
	$dollarat->inputhandle($inputhandle);
    }

    if (defined $propagated and length $propagated) {
	$dollarat->propagated($propagated);
    }

    CORE::die($dollarat);
}

# Try to appear exactly like the normal $@
sub to_string {
    my $this = shift;

    my $text = $this->err;

    if (defined ($this->propagated)) {
	if (!length($text)) {
	    $text = $this->propagated . "\t...propagated";
	}
    }

    unless ($text =~ /\n\z/) {
	$text .= ' at ' . $this->filename . ' line ' . $this->line;
	if (defined $this->inputline) {
	    $text .= ', <'.$this->inputhandle . '> line ' . $this->inputline;
	}
    }

    $text .= '.';
    $text = "[[$text]]" if $FRAME;
    $text .= "\n";

    return $text;
}

sub _new {
    my $class = shift;
    my $this = $class->SUPER::new(@_);

    return $this;
}

sub import {
    my $class = shift;
    for (@_) {
	if ('frame' eq $_) {
	    $FRAME = 1;
	} else {
	    die 'Unknown parameter for '.__PACKAGE__.": $_";
	}
    };
}

sub redie {
    my $this = shift;
    my ($package, $filename, $line) = caller;
    push @{$this->{redispatch_points}}, Devel::DollarAt::RedispatchPoint->new({
	    package => $package,
	    filename => $filename,
	    line => $line,
	}
    );
    local $SIG{__DIE__};
    CORE::die($this);
}

sub redispatch_points {
    my $this = shift;
    return @{$this->{redispatch_points} || []};
}

package # hide from pause
    Devel::DollarAt::NullMessage;
#use overload '""' => sub {''};
sub _new { shift; bless {@_}; }

package # hide from pause
        Devel::DollarAt::RedispatchPoint;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_ro_accessors(qw(package filename line));

use overload '""' => sub {
    my $this = shift;

    return 'redispatched from '.$this->package.' at '
    .$this->filename.':'.$this->line."\n";
};

1
__END__

=head1 NAME

Devel::DollarAt - Give magic abilities to $@

=head1 SYNOPSIS

    use Devel::DollarAt;

    eval "0/0";
    print $@, $@->backtrace;
    $@->redie;

=head1 DESCRIPTION

Using eval {}, you may catch Perl exceptions almost like you do it with try {}
in Java.  However there are days when you miss some features of exceptions.
The only thing you know about the error that occured is the string $@, which
combines the error message and technical data like the line number.

The Devel::DollarAt module gives some functionality to the $@ scalar.  Once you
say "use Devel::DollarAt", the module is active program-wide.  If an exception
occurs anywhere in any module, $@ will be globally set to an object of class
Devel::DollarAt.  Apart from performance, this shouldn't be a problem because
$@ tries to be downwardly compatible to the normal $@.  However using this
package in CPAN modules or large software projects is discouraged.

=head1 DISCLAIMER

Use this module only for debugging.  Don't think of it as an exception
framework for Perl or something like that.  It just gives magic abilities to
$@, that's all.

=head1 METHODS

=over 8

=item backtrace

Returns a L<Devel::Backtrace> object, which lets you inspect the callers of the
fatality.

=item filename

Returns the name of the file in which the error occured.

=item inputhandle

Returns the file handle which has most recently be read from at the time of the
error.

=item inputline

Returns the line number of C<< $@->inputhandle >> (which is $.) at the time of the
error.

=item line

Returns the number of the line in which the error occured.

=item redie

Redispatches this exception to the next eval{}.

=item redispatch_points

Returns a list of objects with informations about when this exception was
redispatched.  Each object has got the accessors "package", "filename" and
"line".  In string context, the objects will look like "redispatched from
FooPackage at file.pl:17\n".

=item to_string

Returns a string that looks quite like the normal $@, e. g. "Illegal division
by zero at foo.pl line 42, <> line 13."  Devel::DollarAt overloads the ""
(stringification) operator to this method.

=back


=head1 EXAMPLES

A very simple (and pointless) way to use Devel::DollarAt is this oneliner:

    perl -MDevel::DollarAt -e '0/0'

It bails out with "Illegal division by zero at -e line 1." and an exit status
of 1, just like it would have done if you hadn't supplied -MDevel::DollarAt.
This is because the magically modified $@ variable gets stringified when perl
prints it as exit reason.  If you actually want to see the difference, use

    perl -MDevel::DollarAt=frame -e '0/0'

This bails out with "[[Illegal division by zero at -e line 1.]]" so you can see
that something has happened.

=head1 KNOWN PROBLEMS

This module requires that no other code tampers with C<$SIG{__DIE__}> or
C<*CORE::GLOBAL::die>.

A not widely known feature of Perl is that it can propagate $@.  If you call
die() without parameters or with an empty string or an undefined value, the
error message will be "Died".  However, if $@ was set to some value before
this, the previous error message will be used with "\t...propagated" appended:

    perl -e '$@="7"; die"
    7       ...propagated at -e line 1.

Devel::DollarAt emulates this behaviour.

If you use the above example but leave out the double quotes, perl's behaviour
is different as of version 5.8.8:

    perl -e '$@=7; die'
    7 at -e line 1.

Devel::DollarAt does not emulate this behaviour:

    perl -MDevel::DollarAt -e '$@=7; die'
    7       ...propagated at -e line 1.

If a previous $@ is propagated, inputhandle and inputline won't work.  They
won't be interpolated into the stringified $@, either.

If perl comes across syntax errors, $@ appears to be just a string as usual.
Apparently C<$SIG{__DIE__}> won't be called for syntax errors.

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
