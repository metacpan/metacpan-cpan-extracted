package Hadoop::Inline::ClassLoader;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Carp           qw( croak   );
use File::Basename qw( dirname );
use Ref::Util      qw(
    is_arrayref
    is_hashref
);

use Constant::FromGlobal
    DEBUG => {
        default => 0,
        env     => 1,
        int     => 1,
    },
;

use constant {
    CHAR_COLON        => q{:},
    EMPTY_STRING      => q{ },
    HADOOP_COMMAND    => '/usr/bin/hadoop',
    IJ_DEBUG          => DEBUG && DEBUG > 1,
    PACKAGE_DELIMITER => q{::},
    RE_MULTI_LF       => qr{ \n+ }xms,
    RE_PATH_SEP_CHAR  => qr{ [:] }xms,
    RE_WS             => qr{ \s+ }xms,
};

my $ENV_INITIALIZED;

my %DEFAULT = (
    alias => 1,
);

sub import {
    my($class, @args) = @_;

    my $opt          = @args && is_hashref $args[0] ? shift(@args) : { %DEFAULT };
    my @java_classes = @args or croak 'No java classes were defined';
    my $caller       = $opt->{export_to} || caller 1;

    if ( ! $ENV_INITIALIZED ) {
        my($henv, $paths) = $class->_collect_env( $opt );
        $ENV{$_} = $henv->{ $_ } for keys %{ $henv };

        require Inline;
        require Inline::Java;

        Inline->import(
           Java  => 'STUDY',
           STUDY => [],
           DEBUG => IJ_DEBUG,
        );

        $ENV_INITIALIZED++;
    }

    eval qq{
        package $caller;
        use Inline (
            Java  => 'STUDY',
            STUDY => [],
        ) ;
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        croak sprintf 'Unable to inject Inline::Java into the caller(%s): %s',
                        $caller,
                        $eval_error,
        ;
    };

    # TODO: further checks on the user params?
    Inline::Java::study_classes( \@java_classes , $caller );

    $class->_map_java_imports_to_short_names if $opt->{alias};

    return;
}

sub _capture {
    my @cmd = @_;
    my $rv  = qx{@cmd};
    croak "Failed to execute `@cmd`"     if $?;
    chomp $rv;
    croak "Nothing returned from `@cmd`" if ! $rv;
    return $rv;
}

sub _collect_env {
    my $class = shift;
    my $opt   = shift;

    croak 'Options need to be a HASH' if ! is_hashref $opt;

    my $cmd = $opt->{hadoop_command} || HADOOP_COMMAND;

    if ( ! -e $cmd || ! -x _ ) {
        croak sprintf 'This module requires `%s` to be present as an executable',
                        $cmd,
        ;
    }

    my $q = _capture( $cmd => 'classpath' );

    my @paths = split RE_PATH_SEP_CHAR, $q;

    push @paths, @{ $opt->{extra_classpath} } if is_arrayref $opt->{extra_classpath};

    if ( DEBUG ) {
        print STDERR 'CLASSPATH(before expansion):\n';
        print STDERR "\t$_\n" for @paths;
    }

    # java expects the shell expansion to happen outside as passing the paths
    # with meta characters don't do anything.
    #
    # In short; CLASSPATH is not identical to PERL5LIB and this manual work is
    # needed. It is possible that we may hit some shell limitation on this
    # variable if too many things are pushed above.
    #
    @paths = map { glob $_ } @paths;

    if ( DEBUG ) {
        print STDERR 'CLASSPATH(after expansion):\n';
        print STDERR "\t$_\n" for @paths;
    }

    state $re_path_sep = RE_PATH_SEP_CHAR;
    my %n = do {
        my $native = _capture( $cmd => 'checknative' );
        my @n = split RE_MULTI_LF, $native;
        shift @n;
        map {
            my @k = split RE_WS, $_, 3; ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
            $k[0] =~ s{ $re_path_sep \z }{}xms;
            $k[0] => {
                status => $k[1],
                value  => $k[2],
            };
        } @n;
    };

    my $hadoop = $n{hadoop} || croak 'Failed to collect the hadoop native binary path';
    my $native = dirname $hadoop->{value};
    my $hopts = '-Djava.library.path=' . dirname $native;

    my %henv;
    $henv{CLASSPATH}                    = join CHAR_COLON, @paths;
    $henv{HADOOP_COMMON_LIB_NATIVE_DIR} = $native;
    $henv{HADOOP_OPTS}                  = $ENV{HADOOP_OPTS}
                                        ? $ENV{HADOOP_OPTS} . EMPTY_STRING . $hopts
                                        : $hopts
                                        ;

    # if LD_LIBRARY_PATH is not set:
    #
    # util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable

    for my $path (qw/
        JAVA_LIBRARY_PATH
        LD_LIBRARY_PATH
    /) {
        $henv{ $path } = $ENV{ $path } ? $ENV{ $path } . CHAR_COLON . $native : $native;
    }

    return \%henv, \@paths;
}

sub _map_java_imports_to_short_names {
    my $class = shift;
    # Give somewhat meaningful names to the imported Java classes

    state $package_delimiter = PACKAGE_DELIMITER;

    my $base_ns = 'org::apache::hadoop::';
    my $filter  = do {
        my @rv = split m{ $package_delimiter }xms, $base_ns;
        pop @rv;
        join PACKAGE_DELIMITER, @rv;
    };

    my @ns = $class->_namespace_probe( $base_ns );
    shift @ns;

    @ns = grep { m{ $package_delimiter \z }xms } @ns;

    no strict qw( refs );
    foreach my $class ( @ns ) {
        (my $short_name = $class) =~ s{
            \Q$filter\E
            $package_delimiter
        }{}xms;
        $short_name = join  PACKAGE_DELIMITER,
                            map { ucfirst $_ } split m{ $package_delimiter }xms,
                            $short_name
        ;
        # import() was called multiple times?
        next if %{ $short_name . PACKAGE_DELIMITER };

        printf STDERR 'Mapping %s => %s', $short_name, $class if DEBUG;

        *{ $short_name . PACKAGE_DELIMITER } = \*{ $class };
    }

    return;
}

sub _namespace_probe {
    my $class = shift;
    my $sym   = shift;

    my @names;
    no strict qw( refs );
    foreach my $type (
        grep {
            m{ \A [a-z] }xmsi
        }
        keys %{ $sym }
    ) {
        push @names, $class->_namespace_probe( $sym . $type );
    }

    return $sym, @names;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hadoop::Inline::ClassLoader

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Hadoop::Inline::ClassLoader qw( org.apache.hadoop.conf.Configuration );
    use Hadoop::Inline::ClassLoader \%options, @java_classes;

=head1 DESCRIPTION

Hadoop Java class loader through Inline::Java. This module tries to setup the
environment needed for the Hadoop classes and also has auto-study feature and
short name aliasing for Perl packages' name mappings.

=head1 NAME

Hadoop::Inline::ClassLoader - Hadoop Java class loader through Inline::Java

=head1 IMPORT ARGUMENTS

=head2 Options

You can specify a hashref with the optional options to override some
functionality. When setting this options hash yourself, you will be
disabling most defaults. So, if you set one of them, then you may
need to specify the rest, if you need those to be present.

=head3 alias

Boolean. Enable or disable short name aliasing. This will create short
names for the undelying Java class name mappings.

Enabled by default.

=head3 export_to

By default, the environment and definitions will be in the caller namespace
which can be altered by this option. Normally, you won't need this, but it
can be useful if you'd like to wrap this module.

=head3 extra_classpath

Hadoop configuration might be missing some of the classpaths and if you need
to include them, then this option can be used.

It needs to be an arrayref.

=head3 hadoop_command

The full path to the hadoop command line executable, which will be used
to probe the Hadoop Class Paths and other options to be utilized by this
module.

The default value is C</usr/bin/hadoop>.

=head2 Java Classes

You need to define a list of java classes to be loaded by this module.
they will be auto-studied and will be made available to your program.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
