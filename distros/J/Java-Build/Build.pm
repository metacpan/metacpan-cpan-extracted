package Java::Build;

use strict;
use warnings;

use Carp;

our $VERSION = '0.05';

sub import {
    croak "Java::Build is a documentation only module.\n"
        . "Try Java::Build::JVM or Java::Build::Tasks\n";
}

1;
__END__

=head1 NAME

Java::Build - a family of modules which you can use instead of Ant

=head1 SYNOPSIS

    use Java::Build::JVM;  # access to the javac compiler in one jvm
    use Java::Build::Tasks;  # some helpful methods similar to Ant tasks

    my $source_files = build_file_list(
        BASE_DIR         => $some_path,
        INCLUDE_PATTERNS => [ qr/\.java$/ ],
    );
    my $dirty_sources = what_needs_compiling(
        SOURCE_FILE_LIST => $source_files,
    );
    if (@$dirty_sources) {
        my $compiler = Java::Ant::JVM->getCompiler();
        $compiler->destination($base_dir);
        $compiler->classpath($base_dir);
        $compiler->compile($dirty_sources);

        my $class_files = build_file_list(
                BASE_DIR         => $some_path,
                INCLUDE_PATTERNS => [ qr/\.class$/ ],
                EXCLUDE_PATTERNS => [ qr/Test/ ],
                EXCLUDE_DEFAULTS => 1,
                STRIP_BASE_DIR   => 1,
        );
        jar(
            JAR_FILE  => $jar_file_name,
            FILE_LIST => $class_files,
            BASE_DIR  => $some_path,
       );
    }

=head1 ABSTRACT

  This family of modules helped me move away from Ant to a proper scripting
  language, namely Perl.  With it you can use a single JVM for compiling
  your java programs.  It provides many useful methods to help you build
  lists of files, package them with jar, etc.  Currently the modules are
  unix centric.  If you make them work elsewhere, please send in patches.

=head1 DESCRIPTION

With the modules in this distribution, you can aviod Ant.  This gives you
the following benefits:

=over 4

=item *

Variables instead of properties.

=item *

Flow of control structures.

=item *

The ability to write functions.

=item *

Cleaner build files (you don't have to code in XML)

=item *

All the other benefits of Perl (CPAN, regexes, etc.)

=back

=head1 SEE ALSO

You will need to install recent versions of Inline and Inline::Java.

See Java::Build::JVM and Java::Build::Tasks for more details about their
methods.

=head1 REQUIRES

  Inline
  Inline::Java
  Carp;
  File::Find;
  Cwd;
  File::Temp;
  Exporter;

=head1 AUTHOR

Phil Crow, E<lt>philcrow2000@yahoo.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.8.0 itself. 

=cut
