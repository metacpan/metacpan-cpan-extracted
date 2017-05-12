#!/bin/sh

<<'=cut'

=encoding utf8

=head1 NAME

devel-local.sh - Shell function to invoke the Devel::Local Perl tool.

=head1 SYNOPSIS

In your shell configuration file:

  source `which devel-local.sh`

If you use plenv:

  source `which devel-local.sh`

=head1 DESCRIPTION

This Shell library is used to let Devel::Local set the PERL5LIB and PATH
environment variables.

=head1 AUTHOR

Ingy döt Net

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2014. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl.

See http://www.perl.com/perl/misc/Artistic.html

=cut

devel-local() {
  perl -MDevel::Local -e1 || exit 1
  export PERL5LIB=`perl -MDevel::Local::PERL5LIB -e1 $* || echo $PATH`
  export PATH=`perl -MDevel::Local::PATH -e1 $* || echo $PATH`
}
