=head1 NAME

ExtUtils::CXX - support C++ XS files

=head1 SYNOPSIS

 use ExtUtils::CXX;
 use ExtUtils::MakeMaker;

 # wrap calls to WriteMakefile or MakeMaker that are supposed to use
 # C++ XS files into extutils_cxx blocks:

 extutils_cxx {
    WriteMakefile (
       ...  put your normal args here
    );
 };

=head1 DESCRIPTION

This module enables XS extensions written in C++. It is meant to be useful
for the users and installers of c++ modules, rather than the authors, by
having a single central place where to patch things, rather than to have
to patch every single module that overrides CC manually. That is, in the
worst case, you need to patch this module for your environment before
being able to CPAN-install further C++ modules; commonly, only setting a
few ENV variables is enough; and in the best case, it just works out of
the box.

(Comments on what to do and suggestions on how to achieve these things
better are welcome).

At the moment, it works by changing the values in C<%Config::Config>
temporarily. It does the following things:

=over 4

=item 1. It tries to change C<$Config{cc}> and C<$Config{ld}> into a C++ compiler.

If the environment variable C<$CXX> is set, then it's value will be used
to replace both (except if C<$PERL_CXXLD> is set, then that will be used for
C<$Config{ld}>.

(There is also a C<$PERL_CXX> which takes precedence over C<$CXX>).

The important thing is that the chosen C++ compiler compiles files with
a F<.c> ending as C++ - a generic compiler wrapper such as F<gcc> that
detects the lafguage by the file extension will I<not> work.

In the absence of these variables, it will do the following
transformations on what it guesses will be the compiler name:

   gcc   => g++
   clang => clang++
   xlc   => xlC
   cc    => g++
   c89   => g++

=back

=over 4

=cut

package ExtUtils::CXX;

use common::sense;

our $VERSION = '1.0';

use Exporter 'import';

our @EXPORT = qw(extutils_cxx);

use ExtUtils::MakeMaker::Config ();

=item extutils_cxx BLOCK;

This function temporarily does hideous things so you can call
C<WriteMakefile> or similar functions in the BLOCK normally. See the
description, above, for more details.

=cut

use Config;

our %cc = (
   gcc   => "g++",
   clang => "clang++",
   xlc   => "xlC",
   cc    => "g++",
   c89   => "g++",
);

our $PREFIX = qr{(?:\S+[\/\\])? (?:ccache|distcc)}x;

sub _ccrepl {
   my ($cfgvar, $env) = @_;

   my $tie = tied %Config;

   my $env = $ENV{"PERL_$env"} || $ENV{$env};

   my $val = $tie->{$cfgvar};

   if ($env) {
      $val =~ s/^\S+/$env/;
   } else {
      keys %cc;
      while (my ($k, $v) = each %cc) {
         $val =~ s/^ ((?:$PREFIX\s+)? \S*[\/\\])? $k (-|\s|\d|$) /$1$v$2/x
            and goto done;
      }

      $val =~ s/^($PREFIX\s+)? \S+/$1g++/x;

      done: ;
   }

   $tie->{$cfgvar} = $val;
}

sub extutils_cxx(&) {
   my ($cb) = @_;

   # make sure these exist
   @Config{qw(cc ld)};

   my $tie = tied %Config;

   # now dive into internals of Config and temporarily patch those values

   local $tie->{cc} = $Config{cc}; _ccrepl cc => "CXX";
   local $tie->{ld} = $Config{ld}; _ccrepl ld => ($ENV{PERL_CXXLD} ? "CXXLD" : "CXX");

   local $ExtUtils::MakeMaker::Config::Config{cc} = $tie->{cc};
   local $ExtUtils::MakeMaker::Config::Config{ld} = $tie->{ld};

   eval {
      $cb->();
   };
   die if $@;
}

=back

=head2 WHAT YOU HAVE TO DO

This module only makes your F<.xs> files compile as C++. It does not
provide magic C++ support for objects and typemaps, and does not help with
portability or writing your F<.xs> file. All of these you have to do -
google is your friend.

=head2 LIMITATIONS

Combining C++ and C is an art form in itself, and there is simply no
portable way to make it work - the platform might have a C compiler, but
no C++ compiler. The C++ compiler might be binary incompatible to the C
compiler, or might not run for other reasons, and in the end, C++ is more
of a moving target than C.

=head2 SEE ALSO

There is a module called C<ExtUtils::XSpp> that says it gives you C++ in
XS, by changing XS in some ways. I don't know what exactly it's purpose
is, but it might be a useful addition for C++ Xs development for you,
so you might want to look at it. It doesn't have C<ExtUtils::MakeMaker>
support, and there is a companion module that only supports the obsolete
(and very broken) C<Module::Build>, sour YMMV.

=head1 AUTHOR/CONTACT

 Marc Lehmann <schmorp@schmorp.de>
 http://software.schmorp.de/pkg/extutils-cxx.html

=cut

1

