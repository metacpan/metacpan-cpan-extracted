use 5.008001;
use strict;
use warnings;

package Types::Path::Tiny;
# ABSTRACT: Path::Tiny types and coercions for Moose and Moo

our $VERSION = '0.006';

use Path::Tiny qw();
use Type::Library 0.008 -base, -declare => qw( Path AbsPath File AbsFile Dir AbsDir );
use Type::Utils;
use Types::Standard qw( Str ArrayRef );
use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };

#<<<
class_type Path, { class => "Path::Tiny" };

declare AbsPath,
    as Path, where { $_->is_absolute },
    inline_as { $_[0]->parent->inline_check($_) . "&& ${_}->is_absolute" },
    message {
        is_Path($_) ? "Path '$_' is not absolute" : Path->get_message($_);
    };

declare File,
    as Path, where { $_->is_file },
    inline_as { $_[0]->parent->inline_check($_) . "&& (-f $_)" },
    message {
        is_Path($_) ? "File '$_' does not exist" : Path->get_message($_);
    };

declare Dir,
    as Path, where { $_->is_dir },
    inline_as { $_[0]->parent->inline_check($_) . "&& (-d $_)" },
    message {
        is_Path($_) ? "Directory '$_' does not exist" : Path->get_message($_);
    };

declare AbsFile,
    as intersection([AbsPath, File]),
    message {
        is_AbsPath($_) ? File->get_message($_) : AbsPath->get_message($_);
    };

declare AbsDir,
    as intersection([AbsPath, Dir]),
    message {
        is_AbsPath($_) ? Dir->get_message($_) : AbsPath->get_message($_);
    };
#>>>

for my $type ( Path, File, Dir ) {
    coerce(
        $type,
        from Str()        => q{ Path::Tiny::path($_) },
        from Stringable() => q{ Path::Tiny::path($_) },
        from ArrayRef()   => q{ Path::Tiny::path(@$_) },
    );
}

for my $type ( AbsPath, AbsFile, AbsDir ) {
    coerce(
        $type,
        from Path         => q{ $_->absolute },
        from Str()        => q{ Path::Tiny::path($_)->absolute },
        from Stringable() => q{ Path::Tiny::path($_)->absolute },
        from ArrayRef()   => q{ Path::Tiny::path(@$_)->absolute },
    );
}

### optionally add Getopt option type (adapted from MooseX::Types:Path::Class
##eval { require MooseX::Getopt; };
##if ( !$@ ) {
##    MooseX::Getopt::OptionTypeMap->add_option_type_to_map( $_, '=s', )
##      for ( 'Path::Tiny', Path );
##}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::Path::Tiny - Path::Tiny types and coercions for Moose and Moo

=head1 VERSION

version 0.006

=head1 SYNOPSIS

Example with Moose:

  ### specification of type constraint with coercion

  package Foo;

  use Moose;
  use Types::Path::Tiny qw/Path AbsPath/;

  has filename => (
    is => 'ro',
    isa => Path,
    coerce => 1,
  );

  has directory => (
    is => 'ro',
    isa => AbsPath,
    coerce => 1,
  );

  ### usage in code

  Foo->new( filename => 'foo.txt' ); # coerced to Path::Tiny
  Foo->new( directory => '.' ); # coerced to path('.')->absolute

Example with Moo:

    ### specification of type constraint with coercion

    package Foo;

    use Moo;
    use Types::Path::Tiny qw/Path AbsPath/;

    has 'directory' => (
        is       => 'rw',
        isa      => AbsPath,
        required => 1,
        coerce   => AbsPath->coercion,
    );

    ### usage in code

    Foo->new( directory => '.' ); # coerced to path('.')->absolute

=head1 DESCRIPTION

This module provides L<Path::Tiny> types for Moose, Moo, etc.

It handles two important types of coercion:

=over 4

=item *

coercing objects with overloaded stringification

=item *

coercing to absolute paths

=back

It also can check to ensure that files or directories exist.

=for Pod::Coverage method_names_here

=head1 SUBTYPES

This module uses L<Type::Tiny> to define the following subtypes.

=head2 Path

C<Path> ensures an attribute is a L<Path::Tiny> object.  Strings and
objects with overloaded stringification may be coerced.

=head2 AbsPath

C<AbsPath> is a subtype of C<Path> (above), but coerces to an absolute path.

=head2 File, AbsFile

These are just like C<Path> and C<AbsPath>, except they check C<-f> to ensure
the file actually exists on the filesystem.

=head2 Dir, AbsDir

These are just like C<Path> and C<AbsPath>, except they check C<-d> to ensure
the directory actually exists on the filesystem.

=head1 CAVEATS

=head2 Path vs File vs Dir

C<Path> just ensures you have a L<Path::Tiny> object.

C<File> and C<Dir> check the filesystem.  Don't use them unless that's really
what you want.

=head2 Usage with File::Temp

Be careful if you pass in a File::Temp object. Because the argument is
stringified during coercion into a Path::Tiny object, no reference to the
original File::Temp argument is held.  Be sure to hold an external reference to
it to avoid immediate cleanup of the temporary file or directory at the end of
the enclosing scope.

A better approach is to use Path::Tiny's own C<tempfile> or C<tempdir>
constructors, which hold the reference for you.

    Foo->new( filename => Path::Tiny->tempfile );

=head1 SEE ALSO

=over 4

=item *

L<Path::Tiny>

=item *

L<Moose::Manual::Types>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/types-path-tiny/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/types-path-tiny>

  git clone https://github.com/dagolden/types-path-tiny.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Hobbestigrou Toby Inkster

=over 4

=item *

Hobbestigrou <hobbestigrou@erakis.eu>

=item *

Hobbestigrou <natal.ngetal@novapost.fr>

=item *

Toby Inkster <tobyink@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
