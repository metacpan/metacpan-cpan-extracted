#!/usr/bin/perl -c

package Fatal::Exception;

=head1 NAME

Fatal::Exception - Succeed or throw exception

=head1 SYNOPSIS

  use Fatal::Exception 'Exception::System' => qw< open close >;
  open my $fh, "/nonexistent";   # throw Exception::System

  use Exception::Base 'Exception::My';
  sub juggle { ... }
  Fatal::Exception->import('Exception::My' => 'juggle');
  juggle;          # succeed or throw exception
  Fatal::Exception->unimport('juggle');
  juggle or die;   # restore original behavior

=head1 DESCRIPTION

L<Fatal::Exception> provides a way to conveniently replace functions
which normally return a false value when they fail with equivalents
which raise exceptions if they are not successful.  This is the same as
L<Fatal> module from Perl 5.8 and previous but it throws
L<Exception::Base> object on error.

=cut


use 5.006;
use strict;
use warnings;

our $VERSION = 0.05;


use Symbol ();


use Exception::Base (
    '+ignore_package' => __PACKAGE__,
);
use Exception::Argument;
use Exception::Fatal;


# Switch to enable dump for created wrapper functions
our $Debug;


# Cache for not fatalized functions. The key is "$sub".
our %Not_Fatalized_Functions;


# Cache for fatalized functions. The key is "$sub:$exception:$void".
our %Fatalized_Functions;


# Export the wrapped functions to the caller
sub import {
    my $pkg = shift;
    my $exception = shift || return;

    Exception::Argument->throw(
        message => 'Not enough arguments for "' . __PACKAGE__ . '->import"',
    ) unless @_;

    my $mod_version = $exception->VERSION || 0;
    if (not $mod_version) {
        eval "use $exception;";
        if ($@) {
            Exception::Fatal->throw(
                message => "Cannot find \"$exception\" exception class",
            );
        };
    };

    my $callpkg = caller;
    my $void = 0;

    foreach my $arg (@_) {
        if ($arg eq ':void') {
            $void = 1;
        }
        else {
            my $sub = $arg =~ /::/
                      ? $arg
                      : $callpkg . '::' . $arg;
            (my $name = $sub) =~ s/^&?(.*::)?//;

            __make_fatal(
                exception => $exception,
                name      => $name,
                pkg       => $callpkg,
                sub       => $sub,
                void      => $void,
            );
        };
    };

    return 1;
};


# Restore the non fatalized functions to the caller
sub unimport {
    my $pkg = shift;

    my $callpkg = caller;

    foreach my $arg (@_) {
        next if ($arg eq ':void');

        my $sub = $arg =~ /::/
                ? $arg
                : $callpkg . '::' . $arg;
        (my $name = $sub) =~ s/^&?(.*::)?//;

        __make_not_fatal(
            name => $name,
            pkg  => $callpkg,
            sub  => $sub
        );
    };

    return 1;
};


# Create the wrapper. Stolen from Fatal.
sub __make_fatal {
    # args:
    #   exception - exception class name
    #   name - base name of sub
    #   pkg  - current package name
    #   sub  - full name of sub
    #   void - is function called in scalar context?
    my (%args) = @_;

    # check args
    Exception::Argument->throw(
        message => 'Not enough arguments for "' . __PACKAGE__ . '->__make_fatal"',
    ) if grep { not defined } @args{qw< exception name pkg sub >};

    Exception::Argument->throw(
        message => 'Bad subroutine name for "' . __PACKAGE__ . '": ' . $args{name},
    ) if not $args{name} =~ /^\w+$/;

    my ($proto, $code_proto, $call, $core, $argvs);
    my $cache_key = "$args{sub}:$args{exception}:" . ($args{void} ? 1 : 0);
    if (defined $Fatalized_Functions{$cache_key} and defined $Not_Fatalized_Functions{$args{sub}}) {
        # already wrapped: restore from cache
        undef *{ Symbol::qualify_to_ref($args{sub}) };
        return *{ Symbol::qualify_to_ref($args{sub}) } = $Fatalized_Functions{$cache_key};
    }
    elsif (defined(&{$args{sub}}) and not eval { prototype "CORE::$args{name}" }) {
        # user subroutine
        $call = "&{\$" . __PACKAGE__ . "::Not_Fatalized_Functions{\"$args{sub}\"}}";
        $proto = prototype $args{sub};
        $Not_Fatalized_Functions{$args{sub}} = \&{$args{sub}}
            unless defined $Not_Fatalized_Functions{$args{sub}};
    }
    else {
        # CORE subroutine
        $core = 1;
        $call = "CORE::$args{name}";
        $proto = eval { prototype $call };

        # not found as CORE subroutine
        Exception::Argument->throw(
            message => "\"$args{sub}\" is not a Perl subroutine",
        ) unless $proto;

        # create package's function
        if (not defined &{$args{sub}}) {
            # not package's function yet
            $argvs = __fill_argvs($proto);
            my $name = "__$args{name}__Fatal__Exception__not_wrapped";
            my $code = "package $args{pkg};\n"
                     . "sub $name ($proto) {\n"
                     . "    no strict 'refs';\n"
                     .      __write_invocation(
                                %args,
                                argvs => $argvs,
                                call  => $call,
                                orig  => 1,
                            )
                     . "}\n";
            print STDERR $code if $Debug;

            eval $code;
            if ($@) {
                Exception::Fatal->throw(
                    message => "Cannot create \"$args{sub}\" subroutine",
                );
            };

            my $sub = "$args{pkg}::$name";
            print STDERR "*{ $args{sub} } = \\&$sub;\n" if $Debug;
            undef *{ Symbol::qualify_to_ref($args{sub}) };
            *{ Symbol::qualify_to_ref($args{sub}) } = \&$sub;
        };

        if (not defined $Not_Fatalized_Functions{$args{sub}}) {
            $Not_Fatalized_Functions{$args{sub}} = \&{$args{sub}};
        };
    };

    if (defined $proto) {
        $code_proto = " ($proto)";
    }
    else {
        $code_proto = '';
        $proto = '@';
    };

    $argvs = __fill_argvs($proto) if not defined $argvs;

    # define new named subroutine (anonymous would be harder to debug from stacktrace)
    my $name = "__$args{name}__Fatal__Exception__$args{exception}" . ($args{void} ? '_void' : '') . "__wrapped";
    $name =~ tr/:/_/;

    my $code = "package $args{pkg};\n"
             . "sub $name$code_proto {\n"
             . "    no strict 'refs';\n"
             .      __write_invocation(
                        %args,
                        argvs => $argvs,
                        call  => $call,
                    )
             . "}\n";
    print STDERR $code if $Debug;

    my $newsub = eval $code;
    if ($@) {
        Exception::Fatal->throw(
            message => "Cannot create \"$args{sub}\" subroutine",
        );
    };

    my $sub = "$args{pkg}::$name";
    print STDERR "*{ $args{sub} } = \\&$sub;\n" if $Debug;

    undef *{ Symbol::qualify_to_ref($args{sub}) };
    return *{ Symbol::qualify_to_ref($args{sub}) } = $Fatalized_Functions{$cache_key} = \&$sub;
};


# Restore the not-fatalized function.
sub __make_not_fatal {
    # args:
    #   name - base name of sub
    #   pkg  - current package name
    #   sub  - full name of sub
    my (%args) = @_;

    # check args
    Exception::Argument->throw(
        message => 'Not enough arguments for "' . __PACKAGE__ . '->__make_non_fatal"',
    ) if grep { not defined } @args{qw< name pkg sub >};

    Exception::Argument->throw(
        message => 'Bad subroutine name for "' . __PACKAGE__ . '": ' . $args{name},
    ) if not $args{name} =~ /^\w+$/;

    # not wrapped - do nothing
    return unless defined $Not_Fatalized_Functions{$args{sub}};

    undef *{ Symbol::qualify_to_ref($args{sub}) };
    return *{ Symbol::qualify_to_ref($args{sub}) } = $Not_Fatalized_Functions{$args{sub}};
};


# Fill argvs array based on function prototype. Stolen from Fatal.
sub __fill_argvs {
    my $proto = shift;

    my $n = -1;
    my (@code, @protos, $seen_semi);

    while ($proto =~ /\S/) {
        $n++;
        if ($seen_semi) {
            push(@protos,[$n,@code]);
        };
        if ($proto =~ s/^\s*\\([\@%\$\&])//) {
            push(@code, $1 . "{\$_[$n]}");
            next;
        };
        if ($proto =~ s/^\s*([*\$&])//) {
            push(@code, "\$_[$n]");
            next;
        };
        if ($proto =~ s/^\s*(;\s*)?\@//) {
            push(@code, "\@_[$n..\$#_]");
            last;
        };
        if ($proto =~ s/^\s*;//) {
            $seen_semi = 1;
            $n--;
            next;
        };
        Exception::Argument->throw(
            message => "Unknown prototype letters: \"$proto\"",
        );
    };
    push @protos, [$n+1, @code];
    return \@protos;
};


# Write subroutine invocation. Stolen from Fatal.
sub __write_invocation {
    # args:
    #   argvs - ref to prototypes stored as array of array of calling arguments
    #   call  - called sub full name
    #   exception - exception class name
    #   name  - base name of sub
    #   orig  - is function called as non-fatalized version?
    #   void  - is function called in scalar context?
    my (%args) = @_;

    # check args
    Exception::Argument->throw(
        message => 'Not enough arguments for "' . __PACKAGE__ . '->__write_invocation"',
    ) if grep { not defined } @args{qw< argvs call exception name >};

    my @argvs = @{ $args{argvs} };

    my $code;

    if (@argvs == 1) {
        # No optional arguments
        my @argv = @{ $argvs[0] };
        shift @argv;
        $code =
            "    "
            . __one_invocation(
                %args,
                argv => \@argv,
              )
            . ";\n";
    }
    else {
        my $else = "    ";
        my (@out, @argv, $n);
        while (@argvs) {
            @argv = @{shift @argvs};
            $n = shift @argv;
            push @out, "${else}if (\@_ == $n) {\n";
            $else = "    }\n    els";
            push @out,
                "        return "
                . __one_invocation(
                    %args,
                    argv      => \@argv,
                  )
                . ";\n";
        }
        push @out,
            "    };\n"
          . "    Exception::Argument->throw(\n"
          . "        ignore_level => 1,\n"
          . "        message => \"$args{name}: Do not expect to get \" . scalar \@_ . \" arguments\"\n"
          . "    );\n";
        $code = join '', @out;
    };

    return $code;
};


# Write subroutine invocation. Stolen from Fatal.
sub __one_invocation {
    # args:
    #   argv - ref to prototypes stored as array of calling arguments
    #   call - called sub full name
    #   exception - exception class name
    #   name - base name of sub
    #   orig - is function called as non-fatalized version?
    #   void - is function called in scalar context?
    my (%args) = @_;

    # check args
    Exception::Argument->throw(
        message => 'Not enough arguments for "' . __PACKAGE__ . '->__one_invocation"',
    ) if grep { not defined } @args{qw< argv call exception name >};

    my $argv = join ', ', @{$args{argv}};

    my $code;

    if ($args{orig}) {
        return "$args{call}($argv)";
    }
    elsif ($args{void}) {
        $code = "(defined wantarray)\n"
             . "            ? $args{call}($argv)\n"
             . "            : do {\n"
             . "                  my \$return = eval {\n"
             . "                      $args{call}($argv);\n"
             . "                  };\n"
             . "                  if (\$@) {\n"
             . "                      Exception::Fatal->throw(\n"
             . "                          ignore_level => 1,\n"
             . "                          message      => \"Cannot $args{name}\",\n"
             . "                      );\n"
             . "                  };\n"
             . "                  \$return;\n"
             . "              } || $args{exception}->throw(\n"
             . "                       ignore_level => 1,\n"
             . "                       message      => \"Cannot $args{name}\",\n"
             . "                   )";
    }
    else {
        $code = "$args{call}($argv)\n"
             . "            || $args{exception}->throw(\n"
             . "                   ignore_level => 1,\n"
             . "                   message      => \"Cannot $args{name}\"\n"
             . "               )";
        $code = "(defined wantarray)\n"
             . "            ? do {\n"
             . "                  my \@return = eval {\n"
             . "                      $args{call}($argv);\n"
             . "                  };\n"
             . "                  if (\$@) {\n"
             . "                      Exception::Fatal->throw(\n"
             . "                          ignore_level => 1,\n"
             . "                          message      => \"Cannot $args{name}\",\n"
             . "                      );\n"
             . "                  };\n"
             . "                  \@return;\n"
             . "              } || $args{exception}->throw(\n"
             . "                       ignore_level => 1,\n"
             . "                       message      => \"Cannot $args{name}\",\n"
             . "                   )\n"
             . "            : do {\n"
             . "                  my \$return = eval {\n"
             . "                      $args{call}($argv);\n"
             . "                  };\n"
             . "                  if (\$@) {\n"
             . "                      Exception::Fatal->throw(\n"
             . "                          ignore_level => 1,\n"
             . "                          message      => \"Cannot $args{name}\",\n"
             . "                      );\n"
             . "                  };\n"
             . "                  \$return;\n"
             . "              } || $args{exception}->throw(\n"
             . "                       ignore_level => 1,\n"
             . "                       message      => \"Cannot $args{name}\",\n"
             . "                   )";
    };

    return $code;
};


1;


__END__

=for readme stop

=head1 IMPORTS

=over

=item use Fatal::Exception I<Exception> => I<function>, I<function>, ...

Replaces the original functions with wrappers which provide do-or-throw
equivalents.  You may wrap both user-defined functions and overridable CORE
operators (except exec, system which cannot be expressed via prototypes) in
this way.

If wrapped function occurs fatal error, the error is converted into
L<Exception::Fatal> exception.

If the symbol C<:void> appears in the import list, then functions named
later in that import list raise an exception only when these are called
in void context.

You should not fatalize functions that are called in list context, because
this module tests whether a function has failed by testing the boolean truth
of its return value in scalar context.

If the exception class is not exist, its module is loaded with "use
I<Exception>" automatically.

=item no Fatal::Exception I<function>, I<function>, ...

Restores original functions for user-defined functions or replaces the
functions with do-without-die wrappers for CORE operators.

In fact, the CORE operators cannot be restored, so the non-fatalized
alternative is provided instead.

The functions can be wrapped and unwrapped all the time.

=back

=head1 PERFORMANCE

The L<Fatal::Exception> module was benchmarked with other implementations.
The results are following:

  ---------------------------------------------------------------
  | Module                      | Success       | Failure       |
  ---------------------------------------------------------------
  | eval/die                    |      289616/s |      236308/s |
  ---------------------------------------------------------------
  | Fatal                       |       94627/s |        8967/s |
  ---------------------------------------------------------------
  | Fatal::Exception            |      143479/s |        9677/s |
  ---------------------------------------------------------------

=head1 SEE ALSO

This module is a fork of L<Fatal> module from Perl 5.8.  The latest Perl
will replace the L<Fatal> module with L<autodie> module which is similar
to C<Fatal::Exception>.

The C<Fatal::Exception> doesn't work with lexical scope, yet.  It also
doesn't support L<perlfunc/system> or L<perlfunc/exec> core functions
and extra import tags.  It throws L<Exception::Base>-d exceptions on
failure so they can be handled as other L<Exception::Base>-d exceptions.

More details:

L<Fatal>, L<autodie>, L<Exception::Base>, L<Exception::System>

=head1 BUGS

If you find the bug, please report it.

=for readme continue

=head1 AUTHOR

Piotr Roszatycki E<lt>dexter@debian.orgE<gt>

=head1 LICENSE

Copyright (C) 2007, 2008 by Piotr Roszatycki E<lt>dexter@debian.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
