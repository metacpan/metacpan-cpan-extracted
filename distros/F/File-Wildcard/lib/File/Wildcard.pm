
package File::Wildcard;
use strict;

our $VERSION = '0.11';

=head1 NAME

File::Wildcard - Enhanced glob processing

=head1 SYNOPSIS

  use File::Wildcard;
  my $foo = File::Wildcard->new(path => "/home/me///core");
  while (my $file = $foo->next) {
     unlink $file;
  }
  
=head1 DESCRIPTION

When looking at how various operating systems do filename wildcard expansion
(globbing), VMS has a nice syntax which allows expansion and searching of
whole directory trees. It would be nice if other operating systems had 
something like this built in. The best Unix can manage is through the
utility program C<find>.

This module provides this facility to Perl. Whereas native VMS syntax uses
the ellipsis "...", this will not fit in with POSIX filenames, as ... is a
valid (though somewhat strange) filename. Instead, the construct "///" is
used as this cannot syntactically be part of a filename, as you do not get
three concurrent filename separators with nothing between (three slashes
are used to avoid confusion with //node/path/name syntax).

You don't have to use this syntax, as you can do the splitting yourself and
pass in an arrayref as your path.

The module also forms a B<regular expression> for the whole of the wildcard
string, and binds a series of back references ($1, $2
etc.) which are available to construct new filenames.

=head2 new

C<File::Wildcard->new( $wildcard, [,option => value,...]);>

  my $foo = File::Wildcard->new( path => "/home/me///core");
  my $srcfnd = File::Wildcard->new( path => "src///*.cpp",
               match => qr(^src/(.*?)\.cpp$),
               derive => ['src/$1.o','src/$1.hpp']);

This is the constructor for File::Wildcard objects. At a simple level,
pass a single wildcard string as a path. 

For more complicated operations, you can supply your own match regexp, or
use the derive option to specify regular expression captures to form 
the basis of other filenames that are constructed for you.

The $srcfnd example gives you object files and header files corresponding
to C++ source files.

Here are the options that are available:

=over 4

=item C<path> 

This is the input parameter that specifies the range
of files that will be looked at. This is a glob spec which can also contain
the ellipsis '///' (it could contain more than one ellipsis, but the benefit
of this is questionable, and multiple ellipsi would cause a performance hit).

Note that the path can be relative or absolute. B<new> will do the right
thing, working out that a path starting with '/' is absolute. In order
to recurse from the current directory downwards, specify './//foo'.

As an alternative, you can supply an arrayref with the path constituents
already split. If you do this, you need to tell B<new> if the path is absolute.
Include an empty string for an ellipsis. For example:

  'foo///bar/*.c' is equivalent to ['foo','','bar','*.c']

You can also construct a File::Wildcard without a path. A call to
B<next> will return undef, but paths can be added using the append and prepend
methods.

=item C<absolute>

This is ignored unless you are using a pre split path. If you
are passing a string as the path, B<new> will work out whether the path is
absolute or relative. Pass a true value for absolute paths.

If your original filespec started with '/' before you split it, specify
absolute => 1. B<absolute> is not required for Windows if the path contains
a drive specification, e.g. C:/foo/bar.

=item C<case_insensitive>

By default, the module will use L<Filesys::Type> to determine whether the
file system of your wildcard is defined. This is an optional module (see
L<Module::Optional>), and File::Wildcard will guess at case sensitivity
based on your operating system. This will not always be correct, as the
file system might be VFAT mounted on Linux or ODS-5 on VMS.

Specifying the option C<case_insensitive> explicitly forces this behaviour
on the wildcard.

Note that File::Wildcard will use the file system of the current working
directory if the path is not absolute. If the path is absolute, you should
specify the case_sensitivity option explicitly.

=item C<exclude>

You can provide a regexp to apply to any generated paths, which will cause
any matching paths not to be processed. If the root of a directory tree
matches, no processing is done on the entire tree.

This option can be useful for excluding version control repositories, e.g. 

  exclude => qr/.svn/

=item C<match>

Optional. If you do not specify a regexp, you get all the files
that match the glob; in addition, B<new> will set up a regexp for you, to
provide a capture for each wildcard used in the path.

If you do provide a match parameter, this will be used instead, and will
filter the results.

=item C<derive>

Supply an arrayref with a list of derived filenames, which
will be constructed for each matching file. This causes B<next> to return
an arrayref instead of a scalar.

=item C<follow>

If given a true value indicates that symbolic links are to be followed. Otherwise,
the symbolic link target itself is presented, but the ellipsis will not traverse
the link.

This module detects a looping symlink that points to a directory higher up, and
will only present the tree once.

=item C<ellipsis_order>

This can take one of the following values: normal, breadth-first, inside-out.
The default option is normal. This controls how File::Wildcard handles
the ellipsis. The default is a normal depth first search, presenting the
name of each containing directory before the contents. 

The inside-out order presents the contents of directories first before 
the directory, which is useful when you want to remove files and directories
(all O/S require directories to be empty before rmdir will work). See 
t/03_absolute.t as this uses inside-out order to tidy up after the test.

Breadth-first is rarely needed (but I do have an application for it). Here,
the whole directory contents is presented before traversing any subdirectories.

Consider the following tree:
   a/
   a/bar/
   a/bar/drink
   a/foo/
   a/foo/lish

breadth-first will give the following order: qw(a/ a/bar/ a/foo/ a/bar/drink 
a/foo/lish). normal gives the order in which the files are listed. 
inside-out gives the following: qw(a/bar/drink a/bar/ a/foo/lish a/foo/ a/).

=item C<sort>

By default, globbing returns the list of files in the order in which they 
are returned by the dirhandle (internally). If you specify sort => 1, the
files are sorted into ASCII sequence (case insensitively if we are operating
that way). If you specify a CODEREF, this will
be used as a comparison routine. Note that this takes its operands in @_,
not in $a and $b.

=item C<debug> and C<debug_output>

You can enable a trace of the internal states of File::Wildcard by setting
debug to a true value. Set debug_output to an open filehandle to get the
trace in a file. If you are submitting bug reports for File::Wildcard, attaching
debug trace files would be very useful.

debug_output defaults to STDERR.

=back

=head2 match

  my $foo_re = $foo->match;
  $foo->match('bar/core');

This is a get and set method that gives access to the match regexp that
the File::Wildcard object is using. It is possible to change the regex
on the fly in the middle of a search (though I don't know why anyone would
want to do this).

=head2 append

  $foo->append(path => '/home/me///*.tmp');

appends a path to an object's todo list. This will be globbed
after the object has finished processing the existing wildcards.

=head2 prepend

  $srcfnd->prepend(path => $include_file);

This is similar to append, but prepends the path to the todo list. In other
words, the current wildcard operation is interrupted to serve the new path,
then the previous wildcard operation is resumed when this is exhausted.

=head2 next

  while (my $core = $foo->next) {
      unlink $core;
  }
  my ($src,$obj,$hdr) = @{$srcfnd->next};

The C<next> method is an iterator, which returns successive files. Returns
matching files if there was no derive option passed to new. If there was
a derive option, returns an arrayref containing the matching filespec and
all derived filespecs. The derived filespecs do not have to exist.

Note that C<next> maintains an internal cursor, which retains context and
state information. Beware if the contents of directories are changing while
you are iterating with next; you may get unpredictable results. If you are
intending to change the contents of the directories you are scanning (with unlink 
or rename), you are better off deferring this operation until you have processed
the whole tree. For the pending delete or rename operations, you could always
use another File::Wildcard object - see the spike example below:

=head2 all

  my @cores = $foo->all;

C<all> returns an array of matching files, in the simple case. Returns an
array of arrays if you are constructing new filenames, like the $srcfnd
example.

Beware of the performance and memory implications of using C<all>. The
method will not return until it has read the entire directory tree. Use of
the C<all> method is not recommended for traversing large directory trees
and whole file systems. Consider coding the traversal using the iterator
C<next> instead.

=head2 reset

C<reset> causes the wildcard context to be set to re-read the first filename
again. Note that this will cause directory contents to be re-read.

Note also that this will cause the path to revert to the original path
specified to B<new>. Any additional paths appended or prepended will be 
forgotten.

=head2 close

Release all directory handles associated with the File::Wildcard object.
An object that has been closed will be garbage collected once it goes out
of scope. Wildcards that have been exhausted are automatically closed, 
(i.e. C<all> was used, or c<next> returned undef).

Subsequent calls to C<next> will return undef. It is possible to call 
C<reset> after C<close> on the same File::Wildcard object, which will cause 
it to be reopened.

=head1 EXAMPLES

=over 4

=item *
B<The spike>

  my $todo = File::Wildcard->new;

  ...

  $todo->append(path => $file);

  ...

  while (my $file = $todo->next) {
  ...
  }

You can use an empty wildcard to store a list of filenames for later
processing. The order in which they will be seen depends on whether append
or prepend is used.

=item *
B<Shell style globbing>

  my $wc_args = File::Wildcard->new;

  $wc_args->append(path => $_) for @ARGV;

  while ($wc_args->next) {
  ...
  }

On Unix, file wildcards on the command line are globbed by the shell before 
perl sees them, unless the wildcards are escaped or quoted. This is not true
of other operating systems. MS-DOS does no globbing at all for example.

File::Wildcard gives you the bonus of elliptic globbing with '///'.

=back

=head1 CAVEAT

This module takes POSIX filenames, which use forward slash '/' as a
path separator. All operating systems that run Perl can manage this type
of path. The module is not designed to work with B<native> file specs.
If you want to write code that is portable, convert native filespecs to
the POSIX form. There is of course no difference on Unix platforms.
  
=head1 BUGS

Please report bugs to http://rt.cpan.org

=head1 AUTHOR

	Ivor Williams
	ivorw-file-wildcard010 at xemaps.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

glob(3), L<File::Find>, L<File::Find::Rule>.

=cut

use Params::Validate::Dummy qw();
use Module::Optional qw(Params::Validate :all);

package Filesys::Type::Dummy;
use strict;

sub case {
    return 'insensitive' if $^O =~ /win|dos/i;
    return 'lower'       if $^O =~ /vms/i;
    return 'sensitive';
}

package File::Wildcard;
use Module::Optional qw(Filesys::Type);
use File::Spec;
use Carp;

sub new {
    my $pkg = shift;

    my %par = validate(
        @_,
        {   derive   => 0,
            path     => { type => SCALAR | ARRAYREF, optional => 1 },
            follow   => 0,
            absolute => 0,
            match    => { type => SCALARREF, optional => 1 },
            exclude  => { type => SCALARREF, optional => 1 },
            sort     => { type => SCALAR | CODEREF | UNDEF, optional => 1 },
            ellipsis_order => {
                type     => SCALAR,
                regex    => qr/(normal|breadth-first|inside-out)/,
                optional => 1,
            },
            case_insensitive => { type => SCALAR, optional => 1 },
            debug            => { type => SCALAR, optional => 1 },
            debug_output     => 0,
        }
    );

    $par{ellipsis_order} ||= 'normal';
    my $path = $par{path};    # $par{path} is about to be chopped up
    ( $par{path}, $par{absolute} )
        = $pkg->_split_path( @par{qw/path absolute follow/} );
    if ( exists( $par{path} ) && !defined $par{case_insensitive} ) {
        my $fspath = $par{absolute} ? $path : File::Spec->curdir;
        my $fscase = eval { Filesys::Type::case($fspath) }
            || Filesys::Type::Dummy::case;
        $par{case_insensitive} = $fscase eq 'sensitive';
    }

    $par{debug_output} ||= \*STDERR if $par{debug};

    unless ( exists $par{match} ) {
        my $match_re = $par{absolute} ? '^/' : '^';
        for ( @{ $par{path} } ) {
            my $comp = quotemeta $_;
            $comp =~ s!((?:\\\?)+)!'(.{'.(length($1)/2).'})'!eg;
            $comp =~ s!\\\*!([^/]*)!g;
            $match_re .= ( $comp || '(.*?)' ) . '/';
        }
        $match_re =~ s!/$!\$!;
        $par{match} = $par{case_insensitive} ? qr/$match_re/i : qr/$match_re/;
    }

    bless \%par, $pkg;
}

sub _debug {
    my ( $self, $mess ) = @_;

    return unless $self->{debug};
    my $dbug = $self->{debug_output};

    print $dbug $mess;
}

sub next {
    my $self = shift;

    $self->_set_state( state => 'initial' ) unless exists $self->{state};

    while ( !exists $self->{retval} ) {
        $self->_debug( "In state " . $self->{state} . "\n" );
        my $method = "_state_" . $self->{state};
        $self->$method;
    }
    $self->_debug( "Returned " . ( $self->{retval} || 'undef' ) . "\n" );
    my $rv = $self->{retval};
    delete $self->{retval};

    $rv;
}

sub all {
    my $self = shift;

    my @out;

    while ( my $match = $self->next ) {
        push @out, $match;
    }

    @out;

}

sub close {
    my $self = shift;

    delete $self->{stack};
    delete $self->{dir};
    delete $self->{seen_symlink};
    $self->_set_state( state => 'finished' );
}

sub reset {
    my $self = shift;

    $self->close;
    $self->_set_state( state => 'initial' );
}

sub _derived {
    my $self = shift;

    return $self->{resulting_path} unless exists $self->{derive};

    my @out = ( $self->{resulting_path} );
    my $re  = $self->{match};
    $self->{resulting_path} =~ /$re/;
    for ( @{ $self->{derive} } ) {
        push @out, eval(qq("$_"));
    }

    \@out;
}

sub match {
    my $self = shift;

    my ($new_re) = validate_pos( @_, { type => SCALARREF, optional => 1 } );

    $new_re ? ( $self->{match} = $new_re ) : $self->{match};
}

sub append {
    my $self = shift;

    my %par = validate(
        @_,
        {   path     => { type => SCALAR | ARRAYREF },
            follow   => 0,
            absolute => 0,
        }
    );
    my %new;

    @new{qw/ path_remaining absolute follow /}
        = $self->_split_path( @par{qw/ path absolute follow /} );
    $new{state} = 'nextdir';
    $new{resulting_path} = $new{absolute} ? '/' : '';

    unshift @{ $self->{state_stack} }, \%new;

    $self->_pop_state if !$self->{state} || ( $self->{state} eq 'finished' );
}

sub prepend {
    my $self = shift;

    my %par = validate(
        @_,
        {   path     => { type => SCALAR | ARRAYREF },
            follow   => 0,
            absolute => 0,
        }
    );

    $self->_push_state;

    my ( $pr, $abs, $fol )
        = $self->_split_path( @par{qw/ path absolute follow /} );
    $self->{path_remaining} = $pr;
    $self->{absolute}       = $abs;
    $self->{follow}         = $fol;
    $self->{resulting_path} = $self->{absolute} ? '/' : '';
    $self->_set_state( state => 'nextdir' );
}

sub _split_path {
    my $self = shift;

    my ( $path, $abs, $follow ) = validate_pos( @_, 0, 0, 0 );

    return ( $path, $abs, $follow ) if !defined($path) || ref $path;

    $path =~ s!//!/!g;
    $abs = $path =~ s!^/!!;
    $path =~ s!^\./!/!;
    my @out = split m(/), $path, -1;    #/ (syntax highlighting)
    shift @out if $out[0]  eq '';
    pop @out   if $out[-1] eq '';

    ( \@out, $abs, $follow );
}

sub _set_state {
    my $self = shift;

    my %par = validate(
        @_,
        {   state => { type => SCALAR },
            dir   => { type => GLOBREF | CODEREF, optional => 1 },
            wildcard => 0,
        }
    );
    $self->{$_} = $par{$_} for keys %par;
}

sub _push_state {
    my $self = shift;

    $self->_debug( "Push state: "
            . $self->{state}
            . " resulting_path: "
            . $self->{resulting_path}
            . " Wildcard: "
            . ( $self->{wildcard} || '' )
            . " path_remaining: "
            . join( '/', @{ $self->{path_remaining} } )
            . "\n" );
    push @{ $self->{state_stack} }, {
        map {
            $_, ( ref( $self->{$_} ) eq 'ARRAY' )
                ? [ @{ $self->{$_} } ]
                : $self->{$_}
            } qw/ state path_remaining dir resulting_path /
    };
}

sub _pop_state {
    my $self = shift;

    $self->{state_stack} ||= [];
    my $newstate
        = @{ $self->{state_stack} }
        ? pop( @{ $self->{state_stack} } )
        : { state => 'finished', dir => undef };
    $self->{$_} = $newstate->{$_} for keys %$newstate;
    $self->_debug( "Pop state to "
            . $self->{state}
            . " resulting_path: "
            . $self->{resulting_path}
            . " Wildcard: "
            . ( $self->{wildcard} || '' )
            . " path_remaining: "
            . join( '/', @{ $self->{path_remaining} } )
            . "\n" );
}

sub _state_initial {
    my $self = shift;

    $self->{resulting_path} = $self->{absolute} ? '/' : '';
    $self->{path_remaining} = [ @{ $self->{path} } ];

    $self->_set_state( state => 'nextdir' );
}

sub _state_finished {
    my $self = shift;

    $self->{retval} = undef;    # Autovivification optimises this away :(
}

sub _state_nextdir {
    my $self = shift;

    unless ( @{ $self->{path_remaining} } ) {
        $self->_debug("Exhaused path\n");
        my $re = $self->{match};
        $self->{retval} = $self->_derived
            if ( -e $self->{resulting_path} )
            && ( $self->{resulting_path} =~ /$re/ );
        $self->_pop_state;
        return;
    }

    my $pathcomp = shift @{ $self->{path_remaining} };
    $self->_debug("Path component '$pathcomp'\n");
    if ( $pathcomp eq '' ) {
        my $order = $self->{ellipsis_order};
        $self->_set_state(
            state => ( $order eq 'inside-out' ) ? 'nextdir' : 'ellipsis' );
        if ( $order ne 'breadth-first' ) {
            $self->_push_state;
            $self->_set_state(
                state => ( $order eq 'inside-out' )
                ? 'ellipsis'
                : 'nextdir'
            );
        }

    }
    elsif ( $pathcomp !~ /\?|\*/ ) {
        $self->{resulting_path} .= $pathcomp;
        my $rp = $self->{resulting_path};
        if ( exists( $self->{exclude} ) && $rp =~ /$self->{exclude}/ ) {
            $self->_pop_state;
            return;
        }
        my $sl = readlink $rp;
        if ($sl) {
            my $slpath = File::Spec->rel2abs( $sl, $rp );
            if ( exists $self->{seen_symlink}{$slpath} ) {
                $self->_pop_state;
                return;
            }
            $self->{seen_symlink}{$slpath}++;
            $self->{path_remaining} = [] unless $self->{follow};
        }
        $self->{resulting_path} .= '/' if -d $self->{resulting_path};
    }
    else {
        my $wcdir;
        if ( !opendir $wcdir, $self->{resulting_path} || '.' ) {
            $self->_pop_state;
            return;
        }
        my $wc_re = quotemeta $pathcomp;
        $wc_re =~ s!((?:\\\?)+)!'(.{'.(length($1)/2).'})'!eg;
        $wc_re =~ s!\\\*!([^/]*)!g;
        my %newstate = (
            state    => 'wildcard',
            dir      => $wcdir,
            wildcard => $self->{case_insensitive}
            ? qr(^$wc_re$)i
            : qr(^$wc_re$)
        );
        if ( $self->{sort} ) {
            my @wcmatch = grep {
                       ( $_ ne '.' )
                    && ( $_ ne '..' )
                    && ( $self->{case_insensitive} ? /$wc_re/i : /$wc_re/ )
            } readdir($wcdir);

            if ( $^O =~ /vms/i ) {
                s/\.dir$// for @wcmatch;
            }

            @wcmatch
                = ( ref( $self->{sort} ) eq 'CODE' )
                ? ( sort { &{ $self->{sort} }( $a, $b ) } @wcmatch )
                : $self->{case_insensitive}
                ? ( sort { lc($a) cmp lc($b) } @wcmatch )
                : ( sort @wcmatch );
            if ( $self->{exclude} ) {
                @wcmatch = grep {
                    ( $self->{path_remaining} . $_ )
                        !~ /$self->{exclude}/
                } @wcmatch;
            }
            $newstate{state} = 'wildcard_sorted';
            $newstate{dir}   = sub {
                my $fil = ( shift @wcmatch ) || '';
                my $rem = join ' ', @wcmatch;
                $self->_debug("wildcard_sorted yields $fil remaining $rem\n");
                return $fil;
            };
        }
        $self->_set_state(%newstate);
    }
}

sub _state_wildcard {
    my $self = shift;

    my $fil = '.';
    my $re  = $self->{wildcard};
    while (
           ( $fil eq '.' )
        || ( $fil eq '..' )
        || ( $fil !~ /$re/ )
        || ( exists( $self->{exclude} )
            && ( $self->{resulting_path} . $fil =~ /$self->{exclude}/ ) )
        )
    {
        $fil = readdir $self->{dir};
        return $self->_pop_state unless defined $fil;
    }
    $fil =~ s/.dir$// if $^O =~ /vms/i;
    $self->_push_state;
    unshift @{ $self->{path_remaining} }, $fil;
    $self->_set_state( state => 'nextdir' );
}

sub _state_wildcard_sorted {
    my $self = shift;

    my $fil = &{ $self->{dir} };
    return $self->_pop_state unless $fil;
    $self->_push_state;
    unshift @{ $self->{path_remaining} }, $fil;
    $self->_set_state( state => 'nextdir' );
}

sub _state_ellipsis {
    my $self = shift;

    if ( $self->{ellipsis_order} eq 'breadth-first' ) {
        unshift @{ $self->{path_remaining} }, '*', '';
        $self->_set_state( state => 'nextdir' );
        $self->_push_state;
        splice @{ $self->{path_remaining} }, 1, 1;
    }
    else {
        unshift @{ $self->{path_remaining} }, '*', '';
        $self->_set_state( state => 'nextdir' );
    }
}

1;    #this line is important and will help the module return a true value
__END__

