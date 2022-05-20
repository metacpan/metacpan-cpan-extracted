# NAME

ExtUtils::MakeMaker::META\_MERGE::GitHub - Perl package to generate ExtUtils::MakeMaker META\_MERGE for GitHub repositories

# SYNOPSIS

Plugin to your Makefile.PL

    use ExtUtils::MakeMaker;
    use ExtUtils::MakeMaker::META_MERGE::GitHub;
    my $mm = ExtUtils::MakeMaker::META_MERGE::GitHub->new(owner=>"myowner", repo=>"myrepo");
    WriteMakefile(
                  ...
                  $mm->META_MERGE,
                  ...
                 );

Copy and paste into your Makefile.PL

    use ExtUtils::MakeMaker::META_MERGE::GitHub;
    use Data::Dumper qw{Dumper};
    my $mm = ExtUtils::MakeMaker::META_MERGE::GitHub->new(owner=>"myowner", repo=>"myrepo");
    my %META_MERGE = $mm->META_MERGE;
    print Dumper(\%META_MERGE);

# DESCRIPTION

Generates the META\_MERGE key and hash value for a normal GitHub repository.

# CONSTRUCTOR

    my $mm = ExtUtils::MakeMaker::META_MERGE::GitHub->new(
               owner => "myowner",
               repo  => "myrepo"
             );

## new

# METHODS

## META\_MERGE

Returns then META\_MERGE key and a hash reference value for a normal git hub repository.

# PROPERTIES

## owner

Sets and returns the GitHub account owner login.

## repo

Sets and returns the GitHub repository name.

## version

Meta-Spec Version

    Default: 2

## type

Resource Repository Type

    Default: git

## base\_url

Base URL for web client requests

    Default: https://github.com

## base\_ssh

Base URL for ssh client requests

    Default: git@github.com

# SEE ALSO

[ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker)

[https://github.com/metacpan/metacpan-web/issues/2408](https://github.com/metacpan/metacpan-web/issues/2408)

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

Copyright (C) 2022 by Michael R. Davis

MIT LICENSE
