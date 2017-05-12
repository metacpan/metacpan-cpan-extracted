# NAME

ExtUtils::MakeMaker::CPANfile - cpanfile support for EUMM

# SYNOPSIS

    # Makefile.PL
    use ExtUtils::MakeMaker;
    use ExtUtils::MakeMaker::CPANfile;
    
    WriteMakefile(
      NAME => 'Foo::Bar',
      AUTHOR => 'A.U.Thor <author@cpan.org>',
    );
    
    # cpanfile
    requires 'ExtUtils::MakeMaker' => '6.17';
    on test => sub {
      requires 'Test::More' => '0.88';
    };

# DESCRIPTION

ExtUtils::MakeMaker::CPANfile loads C<cpanfile> in your distribution
and modifies parameters for C<WriteMakefile> in your Makefile.PL.
Just use it after L<ExtUtils::MakeMaker>, and prepare C<cpanfile>.

# LIMITATION

As of this writing, complex version ranges in the cpanfile are
simply ignored.

# LICENSE

Copyright (C) Kenichi Ishigaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kenichi Ishigaki <ishigaki@cpan.org>
