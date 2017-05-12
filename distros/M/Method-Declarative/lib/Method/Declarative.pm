package Method::Declarative;
use strict;
use warnings;
use Carp;

our $VERSION=0.03;

=pod

=head1 NAME

Method::Declarative - Create methods with declarative syntax

=head1 SYNOPSIS

  use Method::Declarative
  (
    '--defaults' =>
    {
      precheck =>
      [
        [ qw(precheck1 arg1 arg2) ],
        # ...
      ],
      postcheck =>
      [
        [ qw(postcheck1 arg3 arg4) ],
        # ...
      ],
      init =>
      [
        [ 'initcheck1' ],
        # ...
      ],
      end =>
      [
        [ 'endcheck1' ],
        # ...
      ],
      once =>
      [
        [ 'oncecheck1' ],
      ] ,
      package => '__CALLER__::internal',
    },
    method1 =>
    {
      ignoredefaults => [ qw(precheck end once) ],
      code => '__method1',
    },
  ) ;


=head1 DESCRIPTION

The B<Method::Declarative> module creates methods in a using class'
namespace.  The methods are created using a declarative syntax and
building blocks provided by the using class.  This class does B<not>
create the objects themselves.

The using class invokes B<Method::Declarative>, passing it list of
key-value pairs, where each key is the name of a method to declare (or
the special key '--default') and a hash reference of construction
directives.  The valid keys in the construction hash refs are:

=over 4

=item code

The value corresponding to C<code> key is a method name or code reference
to be executed as the method.  It is called like this:

  $obj->$codeval(@args)

where C<$obj> is the object or class name being used, C<$codeval> is the
coresponding reference or method name, and C<@args> are the current
arguments for the invocation.  If C<$codeval> is a method name, it
needs to be reachable from C<$obj>.

A C<code> key in a method declaration will override any C<code> key
set in the C<--defaults> section.

=item end

The value corresponding to the C<end> key is an array reference, where
each entry of the referenced array is another array ref.  Each of the
internally referenced arrays starts with a code reference or method name.
The remaining elements of the array are used as arguments.

Each method declared by the arrays referenced from C<end> are called on
the class where the declared method resides in an B<END> block when
B<Method::Declarative> unloads.

Each method is called like this:

$pkg->$codeval($name[, @args]);

where C<$pkg> is the package or class name for the method, C<$name> is
the method name, and C<@args> is the optional arguments that can be listed
in each referenced list.

C<end> blocks are run in the reverse order of method declaration (for
example, if I<method1> is declared before I<method2>, I<method2>'s C<end>
declaration will be run before I<method1>'s), and for each method they
are run in the order in which they are declared.

Note that this is B<not> an object destructor, and no objects of a
particular class may still exist when these methods are run.

=item ignoredefaults

The value corresponding to the C<ignoredefaults> key is an array reference
pointing to a list of strings.  Each string must corespond to a valid
key, and indicates that any in-force defaults for that key are to be
ignored.  See the section on the special C<--defaults> method for details.

=item init

The value corresponding to the C<init> key is identical in structure
to that corresponding to the C<end> key.  The only difference is that the
declared methods/code refs are executed as soon as the method is available,
rather than during an B<END> block.

=item once

The value corresponding to the C<once> key is identical in structure
to that corresponding to the C<end> key.  The values are used when the
method is invoked, however.

If the method is invoked on an object based on a hash ref, or on the
class itself, and it has not been invoked before on that object or hash
ref, the methods and code refs declared by this key are executed one at
a time, like this:

$obj->$codeval($name, $isscalar, $argsref[, @args ]);

where C<$obj> is the object or class on which the method is being invoked,
C<$codeval> is the method name or code reference supplied, C<$name> is
the name of the method, C<$isscalar> is a flag to specify if the declared
method itself is being executed in a scalar context, C<$argsref> is a
reference to the method arguments (C<\@_>, in other words), and C<@args>
are any optional arguments in the declaration.

The return value of each method or code reference call is used as the new
arguments array for successive iterations or the declared method itself
(including the object or class name).  Yes, that means that these functions
can change the the object or class out from under successive operations.

Any method or code ref returning an empty list will cause further processing
for the method to abort, and an empty list or undefined value (as appropriate
for the context) will be returned as the declared method's return value.

=item package

The value coresponding to the C<package> key is a string that determines
where the declared method is created (which is the caller's package by
default, unless modified with a C<--defaults> section).  The string
'__CALLER__' can be used to specify the caller's namespace, so constructions
like the one in the synopsis can be used to create methods in a namespace
based on the calling package namespace.

=item postcheck

The value coresponding to the C<postcheck> key is identical in structure
to that coresponding to the C<end> key.  The C<postcheck> operations are
run like this:

$obj->$codeval($name, $isscalar, $vref[, @args ]);

where C<$obj> is the underlying object or class, C<$codeval> is the
method or code ref from the list, C<$name> is the name of the declared
method, C<$isscalar> is the flag specifying if the declared method was
called in a scalar context, C<$vref> is an array reference of the
currently to-be-returned values, and C<@args> is the optional arguments
from the list.

Each method or code reference is expected to return the value(s) it
wishes to have returned from the method.  Returning a null list does NOT
stop processing of later C<postcheck> declarations.

=item precheck

The C<precheck> phase operates similarly to the C<once> phase, except
that it's triggered on all method calls (even if the underlying object is
not a hash reference or a class name).

=back

Any illegal or unrecognized key will cause a warning, and processing of
the affected hashref will stop.  This means a C<--defaults> section will
be ineffective, or a declared method won't be created.

=head2 The --defaults section

The values in a hashref tagged with the key C<--defaults> (called "The
--defaults section") provide defaults for each of the keys.  For the keys
that take array references pointing to lists of array refs, the values are
prepended.  For example, if the following declaration were encountered:

  use Method::Declarative
  (
    '--defaults' =>
    {
      package => 'Foo',
      precheck => [ [ '__validate' ] ],
    },
    new =>
    {
      ignoredefaults => [ 'precheck' ],
      code => sub { return bless {}, (ref $_[0]||$_[0]); },
    },
    method1 =>
    {
      precheck => [ [ '__firstcanfoo', 'shortstop' ] ],
      code => '__method1_guts',
    }
  ) ;

then the methods new() and method1() would be created in the package
B<Foo>.  The following code fragment:

  my $res = Foo->new()->method1($arg);

would actually be expanded like this:

  my $obj = Foo->new(); # Returns a blessed hashref
  my @aref = $obj->__validate('method1', 1, [ $obj, $arg ]);
  @aref = $aref[0]->__firstcanfoo('method1', 1, \@aref, 'shortstop');
  my $res = $aref[0]->__method1_guts(@aref[1..$#aref]);

=head1 MOTIVATION

This module was born out of my increasing feeling of "there just
I<has> to be a better way" while I was grinding out yet another
`leven-teen hundred little methods that differed just enough that I
couldn't conveniently write a universal template for all of them, but
that were similar enough that I saw a huge amount of duplicated code.

Take, for example a subclass of B<CGI::Application> that's responsible
for the presentation of a moderately complex web app with three sections -
a general section, a members's only section, and an administration section.
The methods that present the general section only need to load the
appropriate templates (and possibly validate some form data or update
a database), while the methods that present the member's only and
admin sections need to validate credentials against a database first,
and the methods for the administrative section also need to check
the admin user against a capabilities table.  Add in some basic
sanity checking (making sure the object methods aren't called as class
methods, check for a database connection, etc.), and real soon you
have a whole hoard of methods that pretty much look alike except for
about a half dozen lines each.

With B<Method::Declarative>, you can stick much of the pre- and post-
processing into the '--defaults' section, and forget about it.

=head1 EXAMPLE

Following the B<MOTIVATION> section above, for the general section of the
site, we may need to do something like this:

  BEGIN { our ($dbuser,$dbpasswd) = qw(AUserName APassword); }
  use Method::Declarative
  (
    '--defaults' =>
    {
      precheck =>
      [
        [ '__load_rm_template' ],
        [ '__populate_template' ],
      ],
      code => 'output',
    },
    main => { },
    home => { },
    aboutus => { },
    faq =>
    {
      ignoredefaults => [ 'precheck' ],
      precheck =>
      [
        [ '__connect_to_database', $dbuser, $dbpasswd ],
        [ '__load_rm_template' ],
        [ '__load_faq' ],
        [ '__populate_template' ],
      ],
    }
  ) ;

In this particular example, you could have the C<__load_rm_template> load
an B<HTML::Template> object and return it, , with the template to be
loaded determined from the run mode, have C<__populate_template> fill out
common run mode-dependent parameters in the template (and return the
template as the new argument array), and have C<__connect_to_database>
and C<__load_faq> do the obvious things.

With that, the run mode methods main(), home(), and aboutus() become
trivial, and faq() isn't that much more complicated.  When the home()
method is invoked, it results in this series of calls:

  # This returns ($obj, $tmpl)
  $obj->__load_rm_template('main', 1, [ $obj ]);
  # This returns ($tmpl)
  $obj->__populate_template('main', 1, [ $obj, $tmpl ]);
  # This returns the HTML
  $tmpl->output;

Adding authentication checking wouldn't be that much more complex:

  BEGIN { our ($dbuser,$dbpasswd) = qw(AUserName APassword); }
  use Method::Declarative
  (
    '--defaults' =>
    {
      precheck =>
      [
        [ '__connect_to_database', $dbuser, $dbpasswd ],
        [ '__load_rm_template' ],
        [ '__check_auth' ],
        [ '__populate_template' ],
      ],
      code => 'output',
    },
    login => { },
    account_view => { },
    account_update =>
    {
        ignoredefaults => 'precheck',
        precheck =>
      precheck =>
      [
        [ '__connect_to_database', $dbuser, $dbpasswd ],
        [ '__check_update_auth' ],
        [ '__update_account' ],
        [ '__load_rm_template' ],
        [ '__populate_template' ],
      ],
    }
  ) ;

We can even go futher, and add capabilities:

  BEGIN { our ($dbuser,$dbpasswd) = qw(AUserName APassword); }
  use Method::Declarative
  (
    '--defaults' =>
    {
      precheck =>
      [
        [ '__connect_to_database', $dbuser, $dbpasswd ],
        [ '__check_auth' ],
      ],
      code => 'output',
    },
    login => { code => '__process_admin_login' },
    chpasswd =>
    {
      precheck =>
      [
        [ '__has_capability', 'change_password' ],
        [ '__change_password' ],
      ],
    },
  ) ;

=head1 CAVEATS

This module is S-L-O-W.  That's because the main engine of the module
is essentially an interpreter that loops through the given data structures
every time a method is called.

The B<Method::Declarative> module will use the
C<__Method__Declarative_done_once> key of hashref-based objects to scoreboard
calls to methods with a C<once> phase declaration.  This probably won't
cause a problem unless your object happens to be tied or restricted.

=head1 BUGS

Please report bugs to E<lt>perl@jrcsdevelopment.comE<gt>.

=head1 AUTHOR

    Jim Schneider
    CPAN ID: JSCHNEID
    perl@jrcsdevelopment.com

=head1 COPYRIGHT

Copyright (c) 2006 by Jim Schneider.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

perl(1)
CGI::Application(3)
HTML::Template(3).

=cut

my @end_decls = ();
my %once_decls = ();

# The destructor
END
{
    my $decl;
    while($decl = shift @end_decls)
    {
        my ($pkg, $meth, $spec) = @$decl;
        do_global_op($pkg, $meth, $spec);
    }
}

# Return a copy of a list from its reference
sub clone_list
{
    my ($lref) = @_;
    return [ @$lref ];
}

# Return a copy of a list of lists
sub clone_listoflist
{
    my ($lref) = @_;
    my $res = [];
    my $ocarplevel = $Carp::CarpLevel;
    $Carp::CarpLevel = 2;
    eval { push @$res, clone_list($_) foreach @$lref; };
    croak $@ if $@;
    $Carp::CarpLevel = $ocarplevel;
    $res;
}

# Merge two lists of lists
sub merge_listoflists
{
    my ($ref1, $ref2) = @_;
    my $res = [];
    my $ocarplevel = $Carp::CarpLevel;
    $Carp::CarpLevel = 2;
    eval { push @$res, clone_list($_) foreach @$ref1, @$ref2; };
    croak $@ if $@;
    $Carp::CarpLevel = $ocarplevel;
    $res;
}

# The heart of the package - create the declared methods.
sub import
{
    my ($pkg, @args) = @_;
    my ($realdefclass) = caller();
    my %h;
    if(@args % 2)
    {
        carp "Expected a list of key-value pairs\n";
        return unless @args==1;
        eval { %h = %{$args[0]}; };
        croak $@ if $@;
        if($h{'--defaults'})
        {
            @args = ('--defaults', delete $h{'--defaults'});
            @args = (@args, %h);
        }
        else
        {
            @args = %h;
        }
    }
    my %defaults = (package => $realdefclass);
    while(@args)
    {
        my ($key, $href);
        ($key, $href, @args) = @args;
        eval { %h = %$href; };
        croak $@ if $@;
        if($key eq '--defaults')
        {
            my %defs = ( package => $realdefclass );
            for my $k (qw(end init once precheck postcheck))
            {
                if($h{$k})
                {
                    $defs{$k} = clone_listoflist(delete $h{$k});
                }
            }
            if($h{package})
            {
                $defs{package} = delete $h{package};
            }
            if($h{code})
            {
                $defs{code} = delete $h{code};
            }
            carp "Illegal keys in --defaults section" and next if %h;
            %defaults = %defs;
            next;
        }
        my %res;
        my %curdefs = %defaults;
        if($h{ignoredfaults})
        {
            for my $k (@{$h{ignoredefaults}})
            {
                delete $curdefs{$k};
                if($k eq 'package')
                {
                    $curdefs{package} = $realdefclass;
                }
            }
            delete $h{ignoredefaults};
        }
        for my $k qw(package code)
        {
            if($h{$k}) { $curdefs{$k} = delete $h{$k}; }
        }
        for my $k (qw(end init once precheck postcheck))
        {
            if($h{$k} or $curdefs{$k})
            {
                $res{$k} = merge_listoflists($curdefs{$k}, delete $h{$k});
            }
        }
        carp "Illegal keys in declaration of $key" and next if %h;
        my $pkg = $curdefs{package};
        $res{code} = $curdefs{code};
        if($pkg =~ /__CALLER__/)
        {
            $pkg = join '', map {$_ eq '__CALLER__'?$realdefclass:$_ }
                split /::/, $pkg;
        }
        if($res{end})
        {
            push @end_decls, [ $pkg, $key, clone_listoflist($res{end}) ];
        }
        my $symname = $pkg . '::' . $key;
        no strict 'refs';
        *{$symname} = sub
        {
            my ($obj) = @_;
            do_method($obj, $key, \@_, @res{qw(once precheck code postcheck)});
        } ;
        if($res{init})
        {
            do_global_op($pkg, $key, $res{init});
        }
    }
}

sub do_global_op
{
    my ($pkg, $name, $spec) = @_;
    my $ocarplevel = $Carp::CarpLevel;
    $Carp::CarpLevel = 2;
    eval { no warnings "void"; @$spec; };
    croak $@ if $@;
    for my $op (@$spec)
    {
        my ($meth, @args);
        eval { ($meth, @args) = @$op; };
        croak $@ if $@;
        $pkg->$meth($name, @args);
    }
}

sub apply_before
{
    my ($obj, $name, $isscalar, $argsref, $spec) = @_;
    my $ocarplevel = $Carp::CarpLevel;
    $Carp::CarpLevel = 3;
    eval { no warnings "void"; @$spec; };
    croak $@ if $@;
    for my $op (@$spec)
    {
        eval { no warnings "void"; @$op; };
        croak $@ if $@;
        my ($meth, @args) = @$op;
        my @res = $obj->$meth($name, $isscalar, $argsref, @args);
        $argsref = [ @res ];
        $obj = $res[0];
        last unless $obj;
    }
    $Carp::CarpLevel = $ocarplevel;
    return @$argsref;
}

sub do_method
{
    my ($obj, $name, $argsref, $once, $pre, $code, $post) = @_;
    my $ocarplevel = $Carp::CarpLevel;
    $Carp::CarpLevel = 2;
    my $isscalar = not wantarray;
    # Do the "once" ops
    if($once)
    {
        if(ref $obj)
        {
            my $skip = 1;
            eval { $skip = $obj->{__Method__Declarative_done_once}{$name}; };
            unless($skip)
            {
                # In case the object gets prestidigitated away...
                my $orig_obj = $obj;
                my @args =
                    apply_before($obj, $name, $isscalar, $argsref, $once);
                $obj = $args[0];
                $argsref = [ @args ];
                $orig_obj->{__done_once}{$name} = 1;
            }
        }
        else
        {
            unless($once_decls{$obj}{$name})
            {
                # In case the object gets prestidigitated away...
                my $orig_obj = $obj;
                my @args =
                    apply_before($obj, $name, $isscalar, $argsref, $once);
                $obj = $args[0];
                $argsref = [ @args ];
                $once_decls{$orig_obj}{$name} = 1;
            }
        }
        # We bail out here, if we don't have an object
        unless($obj)
        {
            carp "Initializer lost the object, aborting call to $name";
            $Carp::CarpLevel = $ocarplevel;
            return;
        }
    }
    # Do the "precheck" ops
    if($pre)
    {
        my @args = apply_before($obj, $name, $isscalar, $argsref, $pre);
        unless(@args)
        {
            carp "Validation lost the object, aborting call to $name";
            $Carp::CarpLevel = $ocarplevel;
            return ;
        }
        $obj = $args[0];
        $argsref = [ @args ];
    }
    # Do the "code" operation
    my @res;
    if($code)
    {
        if($isscalar)
        {
            $res[0] = $obj->$code(@{$argsref}[1..$#{$argsref}]);
        }
        else
        {
            @res = $obj->$code(@{$argsref}[1..$#{$argsref}]);
        }
    }
    # Do the "postcheck" operation
    if($post)
    {
        eval { no warnings "void"; @$post; };
        croak $@ if $@;
        for my $op (@$post)
        {
            my ($meth, @args);
            eval
            {
                ($meth, @args) = @$op;
                @res = $obj->$meth($name, $isscalar, \@res, @args);
            } ;
            croak $@ if $@;
        }
    }
    $Carp::CarpLevel = $ocarplevel;
    return unless defined wantarray;
    return $res[0] if $isscalar;
    return @res;
}

1;
