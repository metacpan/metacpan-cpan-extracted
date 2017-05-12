package Log::Log4perl::Warn::Multiple::EasyInit;
BEGIN {
  $Log::Log4perl::Warn::Multiple::EasyInit::DIST = 'Log-Log4perl-Warn-Multiple-EasyInit';
}
BEGIN {
  $Log::Log4perl::Warn::Multiple::EasyInit::VERSION = '0.0.1';
}
# ABSTRACT: trap multiple calls to Log::Log4perl::easy_init
use strict;
use warnings;

use Carp;
use Log::Log4perl;

our ($package, $filename, $line);

sub set_trap {
    my $code = \&Log::Log4perl::easy_init;
    no warnings 'redefine';
    *Log::Log4perl::easy_init = sub {
        if(Log::Log4perl->initialized) {
            carp( "Log::Log4perl already initialised with easy_init() [at $filename, line $line]" );
        }
        else {
            # store our first initialisation
            ($package, $filename, $line) = caller;
        }
        # run the original function
        &$code($@);
    };
}

BEGIN {
    set_trap;
}

1;


=pod

=head1 NAME

Log::Log4perl::Warn::Multiple::EasyInit - trap multiple calls to Log::Log4perl::easy_init

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

  BEGIN {
    use Log::Log4perl::Warn::Multiple::EasyInit;
  }

=head1 DESCRIPTION

Have you ever found yourself scratching your head wondering why your
L<Log::Log4perl> output isn't going to the file(s) you expected?

Often the culprit is a call to C<easy_init()> somewhere in the landscape of
modules being used.

You could grep-hunt for the causes, or you could get your scripts and modules
to keep an eye out for you.

=head1 EXPERIMENTAL

B<This module is experimental, and possible jsut mental>

=head1 EXAMPLE

=head2 foo/multiple_init.pl

This script uses the test libraries for the module:

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use FindBin::libs;
    use lib "${FindBin::Bin}/../t/lib";
    
    BEGIN {
        use Log::Log4perl::Warn::Multiple::EasyInit;
    }
    
    use foo;
    use bar;
    use baz;
    use quux;

=head2 Script Output

Slightly reformatted for readability:

    Log::Log4perl already initialised with easy_init()
      [at /tmp/example/script/../t/lib/foo.pm, line 6]
        at /tmp/example/script/../t/lib/bar.pm line 6
    Log::Log4perl already initialised with easy_init()
      [at /tmp/example/script/../t/lib/foo.pm, line 6]
        at /tmp/example/script/../t/lib/quux.pm line 6
    Log::Log4perl already initialised with easy_init()
      [at /tmp/example/script/../t/lib/foo.pm, line 6]
        at /tmp/example/script/../t/lib/baz.pm line 8

=head1 AUTHOR

Chisel Wright <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

