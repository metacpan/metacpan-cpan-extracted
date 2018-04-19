########################################################################
# housekeeping
########################################################################

package Exporter::Proxy v1.8.1;

use v5.20;

use Carp;

use List::Util  qw( first           );
use Symbol      qw( qualify_to_ref  );

########################################################################
# package variables
########################################################################

my $disp_list   = 'DISPATCH_OK';

########################################################################
# utility functions
########################################################################

########################################################################
# methods (public interface)
########################################################################

sub import
{
    state $stub = sub{};

    # discard this package.
    # left on the stack are assignment operators and 
    # exported names.

    shift;

    # use "$source" avoid colliding with '$caller' in the 
    # exported subs.

    my $source  = caller;
    my @exportz = grep { ! /=/ } @_;
    my %argz
    = map
    {
        split /=/, $_, 2 
    }
    grep /=/, @_;

    # maybe carp about extraneous arguments here?

    my $disp        = delete $argz{ dispatch    } || '';
    my $preproc     = delete $argz{ prefilter   } || '';
    my $postproc    = delete $argz{ postfilter  } || '';
    my $inst_import = delete $argz{ import      } // 1;

    # if a dispatcher is being used then it must
    # be exported. in most cases this will be the
    # only thing exported.

    if( $disp )
    {
        my $list    = qualify_to_ref $disp_list, $source;

        first { $disp eq $_ } @exportz 
        or push @exportz, $disp;

        unless( $source->can( $disp ) )
        {
            my $sub = qualify_to_ref $disp, $source;
            my $can = qualify_to_ref $disp_list, $source;

            if( my $sanity = *{ $can }{ ARRAY } )
            {
                *$sub
                = sub
                {
                    my $op      = splice @_, 1, 1;

                    first { $op eq $_ } @$sanity
                    or do
                    {
                        local $"    = ' ';

                        confess "Bogus $disp: '$op' not in @$sanity"
                    };

                    # this could happen if someone plays with
                    # the symbol table after installing the sub.

                    my $handler = $source->can( $op )
                    or croak "Bogus $disp: $source cannot '$op'";

                    goto &$handler
                };
            }
            else
            {
                *$sub
                = sub
                {
                    my $op      = splice @_, 1, 1;

                    my $handler = $source->can( $op )
                    or croak "Bogus $disp: $source cannot '$op'";

                    goto &$handler
                };
            }
        }
    }

    @exportz
    or carp "Oddity: nothing requested for export!";

    my $exports = qualify_to_ref 'exports', $source;

    undef &$exports;

    *$exports
    = sub
    {
        # avoid giving away ref's to the closed-over
        # variable.

        wantarray
        ?   @exportz
        : [ @exportz ]
    };

    $inst_import
    and
    do
    {
        my $import  = qualify_to_ref 'import',  $source;

        undef &$import;

        my $find_pre    
        = $preproc
        ?   sub 
            {
                $source->can( $preproc )
                or die "Unusable $source: cannot '$preproc'";
            }
        : $stub
        ;

        my $find_post    
        = $postproc
        ?   sub 
            {
                $source->can( $postproc )
                or die "Unusable $source: cannot '$postproc'";
            }
        : $stub
        ;

        *$import
        = sub
        {
            # these are delayed since the "use E::P" is 
            # usually dealt with before the subs are defined
            # in the caller.

            state $pre_handler  = $find_pre->();
            state $post_handler = $find_post->();

            # discard the package as first argument:
            # $pkg->import

            shift;

            my $caller  = caller;
            
            # allow the caller to pre-process the arguments.
            # notice this happens *before* ":noexport" is 
            # processed.

            &$pre_handler
            if $pre_handler;

            # empty list => use @exportz.
            # :noexport  => use empty list.

            if( first { ':noexport' eq $_ } @_ )
            {
                @_  = ();
            }
            elsif( @_ )
            {
                # nothing more for the moment.
            }
            else
            {
                @_  = @exportz;
            }

            # resolve these at runtime to account for
            # possible autoloading, etc.

            for my $arg ( @_ )
            {
                index $arg, ':'
                or next;

                if( first { $arg eq $_ }  @exportz )
                {
                    my $source  = qualify_to_ref $arg, $source;
                    my $install = qualify_to_ref $arg, $caller;

                    *$install   = *$source;
                }
                else
                {
                    die "Bogus $source: '$arg' not exported";
                }
            }

            goto &$post_handler
            if $post_handler;
        };
    };

    return
}

# keep require happy

1

__END__

=head1 NAME

Exporter::Proxy - Simplified symbol export & proxy dispatch.

=head1 SYNOPSIS

    package My::Module;

    use Exporter::Proxy qw( foo Bar );

    # at this point users of My::Module will get
    # *My::Module::foo and *My::Module::Bar 
    # installed.
    #
    # My::Module also gets an 'exports' method
    # that lists the exported items; array refs
    # are exported as copies by value.

    my @exported    = My::Module->exports;

    my $object      = My::Module->construct;

    my $exported    = $object->exports;

    package Some::Other;

    use My::Module qw( foo );   # only exports foo
    use My::Module qw( Bar );   # only exports Bar

    use My::Module qw( bar );   # croaks, 'bar' is not exported.

    # caller can specify the items to export by 
    # name -- not type. foo might be used as a
    # subroutine, Bar as an array, or foo may 
    # be overloaded with &foo, %foo, @foo, $foo.

    $value eq $Bar[0]
    or croak "Invalid '$value'";

    delete $foo{ somekey }
    or croak "Oops: foo is missing 'somekey'";

    my $bletch  = $foo || 'oops, no $foo';

    # if the caller does not want to import
    # anything from the module by default:

    use My::Module qw( :noexport );

    # there are times when it is easier to use
    # a dispatcher for things like service classes
    # than to pollute the caller's namespace with 
    # all of the available methods.

    use Exporter::Proxy qw( dispatch=do_something );

    # at this point 'do_something' is installed in 
    # My::Module. it splices out the second
    # argument, uses My::Module->can( $name ) to
    # check if the module has the service availble
    # and then dispatches to it via goto.
    #
    # My::Module->exports will include the dispatcher,
    # in the last example it will have only the
    # dispatcher since no other names were included.
    #
    # now modules use-ing this one look like:

    use My::Module;

    my $object  = My::Module->construct;

    $object->do_something( foo => @foo_args );

    my @test_these  = $object->exports;

    my $test_ref    = $objeect->exports;

    # @test_these will be qw( do_something )
    # $test_ref will be an arrayref of a 
    # copy of the exported values (i.e., 
    # modifying $test_ref does not affect
    # the exported items.

    # some modules may want to use their own import, pulling
    # in only exports and the dispatcher.

    package Foo::Bar;

    use Exporter::Proxy qw( import=0 );

    sub import
    {
        # left as-is, package has to implement its own
        # export utility for @exports.

        ...
    }

=head1 DESCRIPTION

This installs 'import' and 'exports' subroutines 
into the callers namespace. The 'import' does 
the usual deed: exporting symbols by name; 
'exports' simplifies introspection by listing 
the exported symbols (useful for testing).

The optional "dispather=name" argument is used
to install a dispatcher. This allows the module
to offer a variety of services without polluting
the caller's namespace with too many of them. All
it does is check for $module->can( $name ) and 
goto &$handler if the module can handle the 
request.

=head2 Public Interface

=over 4

=item import

The arguments to this are the symbol names to 
export with an optional "dispatch=<name>" or 
"import=<name>" for installing the dispatcher 
and extra import handler.

=back

=head2 Installed methods

=over 4

=item import

Import handles two optional directives: "dispatch"
and "filter". The former installs a dispatch and
adds its name to the exports, the latter allows pre-
processing the arguments to import without having to
write an entire import sub to override this one
(see examples below).

With no arguments the import uses the original
exports list, pushing all of the symbols into
the caller's space.

The optional argument ':noexport' avoids exporting
any symbols to the caller's space.

Other than ':noexport' any arguments with leading
colons are silently ignored by import.

Anything without a leading colon is assumed to
be a name, and is checked againsed the exports
list. If it is on the list then the caller's 
$name symbol is aliased to the source module's.

Note that this is not a copy-by-value into
the caller's space, it is aliaing via the symbol
table. 

i.e., 

    my $dest    = qualify_to_ref $name, $caller;
    my $src     = qualify_to_ref $name, $source;

    *$dest  = *$src;

Callers modifying their copy of the item will be
modifiying a global copy. 

Aside: Once read-only references are avaialble
then they will be an option.

=item exports

Mainly for testing, calling:

    $module->exports;

or

    $object->exports

returns an array[ref] copy of the exported names.

=item dispatch=... (optional)

When exporting a large number of symbols is
problematic, a dispatcher can be installed 
instead. This splices off the second argument,
checks that the module can perform the name,
and does a goto.

Calls to the dispatcher look like:

    $module->$dispatch( $name => @name_argz );

The dispatcher splices $name off the stack,
checks that $module->can( $name ) (or $object
can), croaks if it cannot or does a goto &$handler.

Note that the dispatcher can only be exported
once: the last dispatch=name will be the only
one installed.

For example:

    package Query::Services;

    use Exporter::Proxy qw( dispatch=query );

    sub lookup
    {
        ...
    }

    sub modify
    {
        ...
    }

    sub insert_returning
    {
        ...
    }

allows the caller to:

    use Query::Services;

    # caller now can 'query', which can dispatch
    # calls to lookup, modify, and insert_returning.

    __PACKAGE__->query( modify => $sql, @argz );

    $object->query( lookup => @lookup_argz );

=item prefilter 

Where present this gets first crack at the stack via
&$subref. This allows the caller to deal with any 
extra ":foo" arguments without having to write a
complete import sub. Since Exporter::Proxy's import
silently ignores anything with a leading colon (other
than ":noexport") directives can be handled without 
haviing to munge the stack.

Normal use of this will be the usuall sorts of side-effects
handled in import subs like reading config files or installing
variables. This can also deal with any specialized directives 
by pushing standard lists of exports onto the stack.

    use Exporter::Proxy qw( prefilter=add_groups bim bam foo bar );

    sub bim{}
    sub bam{}

    sub foo{}
    sub bar{}

    sub add_groups
    {
        state $groupz =
        {
            default => [ qw( bim bam ) ],
            others  => [ qw( foo bar ) ],
        };

        for my $i ( 0 .. $#_ )
        {
            my ( $name ) = $_[$i] =~ m{^ : (\w+) }x
            or next;

            my $altz    = $groupz->{ $name }
            or die "Bogus group: '$name' unknown";

            splice @_, $i, 1, @$altz;

            redo
        }
    }

The prefilter can consume or munge the stack as necessary. Whatever
is left will be treated as names for export.

    use Exporter::Proxy qw( prefilter=read_config bim bam foo bar );

    sub read_config
    {
        for my $i ( 0 .. $#_ )
        {
            my ( $path ) = $_[$i] =~ m{^ : (\w+) }x
            or next;

            splice @_, $i, 1;

            -e $path    or die "Missing config: '$path'";

            do_something_with $path;

            redo
        }
    }

Aside: In later versions of perl

    while( my ( $i, $val ) = each @_ ){ ... }

makes it easier to get $i and the value.

The postfilter is called as a final step in the import sub
via goto &$post_handler. It cannot affect the stack used by 
import but will have access to caller() for determining the
calling class. THi can be usefuil for cases where some 
information is managed by class such as default files or 
per-package counts:

    use Exporter::Proxy qw( postfilter=store_exports ... );

    sub store_exports
    {
        # this returns the package calling import

        my $caller  = caller;

        $info{ $caller } = ...
    }

=back

A more general use of this is combining a number of 
service classes with a single 'dispatcher' class that
users others. In this case various separate My::Query::* 
modules help break up what would otherwise be a 
monstrosity into manageable chunks. They can use 
fairly short names that are obvious in context 
becuase the names only propagate up to My::Query. 

My::Query can even use "if" to limit the number
of services available (e.g., only packages that
already have an 'IsSafe' method have the modify 
calls available).

=over 4

    package My::Query::Handle;

    use Exporter::Proxy 
    qw
    (
        connect
        prepare
        disconnect
        fetch
        non_fetch
        insert_returning
    );

    # implementations...


    package My::Query::Lookup

    use Exporter::Proxy
    qw
    (
        lookup
        single_vale
    );

    ...

    package My::Query::Modify

    use Exporter::Proxy
    qw
    (
        insert
        insert_returning
        update
    );

    ...

    # all this needs is to install a dispatcher
    # and pull in the modules that implement the
    # methods it dispatches into.

    package My::Query;

    use Exporter::Proxy qw( dispatch=query );

    use My::Query::Handle;
    use My::Query::Lookup;

    use if $::can_modify, 'My::Query::Modify';

    __END__


    # the object class use-ing My::Query gets a
    # "query" method without having its namespace
    # polluted with "insert", "modify", etc.

    use My::Query;

    ...

    $object->query( lookup => $sql, @valz );

=back

=head2 Simple Test

The exports method provides a simple technique for
baseline testing of modules: check that they can
be used and actually can do what they've claimed
to export.

Say your tests are standardized as '00-Module-Name-Here.t'.

    use Test::More;
    use File::Basename;

    # whatever your naming convention is, 
    # munge it into a package name.

    my $madness = basename $0, '.t';

    $madness    =~ s/^ \d+ - //;
    $madness    =~ s/-/::/g;

    use_ok $madness;

    my @methodz = 
    (
        qw
        (
            import
            exports
        ),
        $madness->exports
    );

    ok $madness->can( $_ ), "$madness can '$_'"
    for @methodz;

    done_testing;

    __END__

Symlink this to whatever modules you need testing 
and "prove t/00*.t" will give a quick, standard
first pass as to whether they compile and are 
minimally usable.

=head1 SEE ALSO

=over 4

=item Symbol

Used to export symbols w/o turning off strict.

=back

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 LICENSE

Copyright (C) 2009-2016 Workhorse Computing.
This code is released under the same terms as Perl 5.22,
or any later version of Perl, itself.
