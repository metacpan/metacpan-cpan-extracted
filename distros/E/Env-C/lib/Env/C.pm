package Env::C;
$Env::C::VERSION = '0.14';
# ABSTRACT: Get/Set/Unset Environment Variables on the C level

require 5.005;

use strict;

require DynaLoader;

@Env::C::ISA = qw(DynaLoader);

bootstrap Env::C $Env::C::VERSION;

1;

__END__

=pod

=head1 NAME

Env::C - Get/Set/Unset Environment Variables on the C level

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  use Env::C;
  
  my $key = "USER";
  $val = Env::C::getenv($key) || '';
  
  Env::C::setenv($key, "foobar", [$override]);
  $new_val = Env::C::getenv($key) || '';
  
  Env::C::unsetenv($key);
  
  my $ar_env = Env::C::getallenv();
  print join "\n", @$ar_env;

=head1 DESCRIPTION

This module provides a Perl API for getenv(3), setenv(3) and
unsetenv(3). It also can return all the C<environ> variables.

Sometimes Perl invokes modules with underlaying C APIs which rely on
certain environment variables to be set. If these variables are set in
Perl and the glue code doesn't worry to set them on the C level, these
variables might not be seen by the C level. This module shows what
really the C level sees.

=head1 FUNCTIONS

=head2 getenv($key)

Returns the value of the environment variable matching the key or
C<undef>.

=head2 setenv($key, $value, [$override])

The C<setenv()> function adds the variable C<$key> to the environment with the
value C<$value>, if C<$key> does not already exist. If C<$key> does exist in
the environment, then its value is changed to C<$value> if C<$override> is
non-zero; if C<$override> is zero or is not passed, then the value of C<$key>
is not changed.

=head2 unsetenv($key)

The unsetenv() function deletes the variable C<$key> from the
environment.

=head2 getallenv()

  my $ar_env = Env::C::getallenv();
  print join "\n", @$ar_env;

The C<getallenv()> function returns an array reference which includes all
the environment variables.

=for Pod::Coverage using_safe_putenv

=head2 EXPORT

None.

=head1 Thread-safety and Thread-locality

This module should not be used in a threaded enviroment.

The OS, which maintains the struct C<environ>, shares it between all
threads in the process, which means it is not thread-local. So if you
modify it in one thread, all other threads will see the new value.
Something that will most likely break the code.

This module is not thread-safe, since two threads may attempt to
modify/read the struct C<environ> at the same time. I could add
locking if in a threaded environment. However since the lock can't be
seen by other applications, they can still bypass it causing race
condition. But since thread-locality is not maintained, making this
module thread-safe is useless.

If you need to modify the C level of C<%ENV> for all threads to see,
do that before threads are started. (e.g. for mod_perl 2.0, at the
server startup).

=head1 HISTORY

=over 4

=item * Versions 0.01 through 0.08 written and maintained by
Stas Bekman E<lt>stas@stason.orgE<gt>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/env-c>
and may be cloned from L<git://github.com/mschout/env-c.git>

=head1 BUGS

Please report any bugs or feature requests to bug-env-c@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Env-C

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2002 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
