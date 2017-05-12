package Log::Any::Adapter::Dupstd;

#
# Cunning adapter for logging to a duplicate of STDOUT or STDERR
#

use 5.008001;
use strict;
use warnings;
use utf8::all;

our $VERSION = '0.02';

#---

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Dupstd - Cunning adapter for logging to a duplicate of
STDOUT or STDERR


=head1 SYNOPSIS

    # Log to a duplicate of stdout or stderr

    use Log::Any::Adapter ('Dupout');
    use Log::Any::Adapter ('Duperr');

    # or

    use Log::Any::Adapter;
    ...
    Log::Any::Adapter->set('Dupout');
    Log::Any::Adapter->set('Duperr');
     
    # with minimum level 'warn'
     
    use Log::Any::Adapter ('Dupout', log_level => 'warn' );
    use Log::Any::Adapter ('Duperr', log_level => 'warn' );

    # and later

    open(STDOUT, ">/dev/null");
    open(STDERR, ">/dev/null");


=head1 DESCRIPTION

Adapters Dupstd are intended to log messages into duplicates of standard
descriptors STDOUT and STDERR.

Logging into a duplicate of standard descriptor might be needed in special
occasions when you need to redefine or even close standard descriptor but you
want to continue displaying messages wherever they are displayed by a standard
descriptor. 

For instance, your script types something in STDERR, and you want to redirect
that message into a file. If you redirect STDERR into a file, warnings C<warn>
and even exceptions C<die> will be redirected there as well. But that is not
always convenient. In many cases it is more convenient to display warnings and
exceptions on the screen.

    # Redirect STDERR into a file
    open(STDERR, '>', 'stderr.txt');

    # This message will go to the file, not on the screen (you want this)
    print STDERR 'Some message';

    # This warning will go to the file too (and that is what you don't want)
    warn('Warning!');

You can try to display warning or exception on the screen by yourself using
adapter Stderr from the distributive Log::Any. But adapter Stderr types message
on STDERR so the message will anyway be in the file and not on the screen.

    # Adapter Stderr
    use Log::Any::Adapter ('Stderr');

    # Redirect STDERR into a file
    open(STDERR, '>', 'stderr.txt')

    # This message will go to the file, not on the screen (you want this)
    print STDERR 'Some message';

    # Oops, warning will go to the file (again it's not what you expected)
    $log->warning('Warning!')

You can display message on the screen using adapter Stdout, which is also in the
distributive Log::Any. Warning will be displayed on the screen as expected, but
that will be "not real" warning because it will be displayed through STDOUT.
That warning will be impossible to filter in the shell.

    # That won't be working!
    $ script.pl 2> error.log

That is the situation when you need adapter Dupstd. Warnings and exceptions sent
using these adapters will be "real". They can be filtered in the shell just as
if they would have been sent to usual STDERR. 

    # Adapter Duperr (definitely PRIOR TO redirecting STDERR)
    use Log::Any::Adapter ('Duperr');

    # Redirect STDERR into a file
    open(STDERR, '>', 'stderr.txt')

    # This message will go to the file, not on the screen (you want this)
    print STDERR 'Some message';

    # Warning will be displayed on the screen (that is what you want)
    $log->warning('Warning!')


=head1 ATTENTION

Adapters Dupstd must be initialized prior to standard descriptors being redefined or closed.

Standard descriptor can't be reopened, that's why the duplicate must be made in advance.


=head1 ADAPTERS

In this distributive there are two cunning adapters - Dupout and Duperr.

These adapters work similarly to ordinary adapters from distributive Log::Any - 
L<Stdout|Log::Any::Adapter::Stdout> and L<Stderr|Log::Any::Adapter::Stderr> (save that inside are used descriptors duplicates).


=head1 SEE ALSO

L<Log::Any|Log::Any>, L<Log::Any::Adapter|Log::Any::Adapter>, L<Log::Any::For::Std|Log::Any::For::Std>

=head1 AUTHORS

=over 4

=item *

Mikhail Ivanov <m.ivanych@gmail.com>

=item *

Anastasia Zherebtsova <zherebtsova@gmail.com> - translation of documentation
into English

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Mikhail Ivanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
