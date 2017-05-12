package Errno::AnyString;
use strict;
use warnings;

=head1 NAME

Errno::AnyString - put arbitrary strings in $!

=head1 VERSION

Version 1.03

=cut

our $VERSION = '1.03';

=head1 SYNOPSIS

C<Errno::AnyString> allows you to place an arbitrary error message in the special C<$!> variable, without disrupting C<$!>'s ability to pick up the result of the next system call that sets C<errno>.

It is useful if you are writing code that reports errors by setting C<$!>, and none of the standard system error messages fit.

  use Errno qw/EIO/;
  use Errno::AnyString qw/custom_errstr/;

  $! = custom_errstr "My hovercraft is full of eels";
  print "$!\n"; # prints My hovercraft is full of eels

  my $saved_errno = $!;

  open my $fh, "<", "/no/such/file";
  print "$!\n"; # prints No such file or directory

  $! = EIO;
  print "$!\n"; # prints Input/output error

  $! = $saved_errno;
  print "$!\n"; # prints My hovercraft is full of eels

You can also set the error strings for particular error numbers, for the lifetime of the Perl interpreter:

  use Errno::AnyString qw/register_errstr/;

  register_errstr "Wetware failure", 339864;

  $! = 339864;
  print "$!\n"; # prints Wetware failure



=head1 BACKGROUND

Perl's special C<$!> variable provides access to  C<errno>, the "error number", which is an integer variable used by C library functions to record what went wrong when they fail. See L<perlvar/ERRNO> and L<Errno>.

There is a fixed error message for each C<errno> value in use, and a C library function to translate C<errno> values into error messages. The magical C<$!> variable always holds the current value of C<errno> if you use it in a numeric context, and the corresponding error message if you use it in a string context.

  open my $fh, "<", "/no/such/file"; # the failing open sets errno to 2
  my $errno = $! + 0;  # $errno now contains 2
  my $err = "$!";      # $err now contains "No such file or directory"

You can also assign a number to C<$!>, to set the value of C<errno>. An C<errno> value of 22 means "invalid argument", so:

  $! = 22;
  $errno = $! + 0;  # $errno now contains 22
  $err = "$!";      # $err now contains "Invalid argument"

What you can't do however is assign a string of your own choice to C<$!>. If you try, Perl just converts your string to an integer as best it can and puts that in C<errno>.

  $! = "You broke it";
  # gives an "Argument isn't numeric" warning and sets errno to 0

=head1 DESCRIPTION

C<Errno::AnyString> allows you to set the error message strings that correspond to particular C<errno> values. It makes a change to the C<$!> magic so that the correct string is returned when C<errno> takes a value for which a string has been registered. The change to C<$!> is global and lasts until the Perl interpreter exits.

=cut

use Exporter;
use Carp;
use Scalar::Util qw/dualvar tainted/;

require XSLoader;
XSLoader::load('Errno::AnyString', $VERSION);

our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/custom_errstr register_errstr CUSTOM_ERRSTR_ERRNO/;

our (%Errno2Errstr, %_string2errno);

Errno::AnyString::_install_my_magic($!);

=head1 EXPORTS

Nothing is exported by default. The following are available for export.

=head2 CUSTOM_ERRSTR_ERRNO

A constant with the value 458513437. This is the C<errno> value used by this module to indicate that a custom error string set with custom_errstr() is active. This value was chosen at random, to avoid picking an C<errno> value that something else uses.

=cut

sub CUSTOM_ERRSTR_ERRNO () { return 458513437; }

our $_next_registered_errno = CUSTOM_ERRSTR_ERRNO() + 1;

=head2 custom_errstr ( ERROR_STRING )

Returns a value which will set the specified custom error string when assigned to C<$!>. 

The returned value is actually a dual valued scalar with C<CUSTOM_ERRSTR_ERRNO> as its numeric value and the specified error string as its string value. It's not just magical variables like C<$!> that can hold a number and a string at the same time, ordinary Perl scalars can do it as well. See L<Scalar::Util/dualvar>.

With C<Errno::AnyString> loaded, the C<$!> magic responds specially to a scalar with a numeric value of CUSTOM_ERRSTR_ERRNO being assigned to C<$!>: the string value of the scalar gets recorded as the registered string for C<errno> value CUSTOM_ERRSTR_ERRNO, replacing any previous registered string for that value.

This way of setting the custom error string was chosen because it works well with code that saves and restores the value of C<$!>.

  $! = custom_errstr "Test string";

  my $saved_errno = $!;
  do_other_things();
  $! = $saved_errno;

  print "$!\n"; # prints Test string

When C<$!> is copied to C<$saved_errno>, C<$saved_errno> becomes dual valued with a number value of CUSTOM_ERRSTR_ERRNO and a string value of "Test string". When C<$saved_errno> gets copied back to C<$!> at the end, the number value of CUSTOM_ERRSTR_ERRNO triggers the modified C<$!> magic to register the string value of "Test string" as the custom error string for CUSTOM_ERRSTR_ERRNO.

This is important because code called from within do_other_things() might itself use custom_errstr() to set custom error strings, overwriting the registered error string of "Test string". Since C<$saved_errno> saves the error message string as well as the C<errno> value, the C<$!> magic can put the correct string back in place when the C<$saved_errno> value is restored.

=cut

sub custom_errstr ($) {
    tainted $_[0] and croak "Tainted error string used with Errno::AnyString";

    return dualvar CUSTOM_ERRSTR_ERRNO, "$_[0]";
}

=head2 register_errstr ( ERROR_STRING [,ERRNO_VALUE] )

register_errstr() can be used in a similar way to custom_errstr():

  $! = register_errstr "An error string";

The difference is that register_errstr() permanently (i.e. for the lifetime of the Perl interpreter) assigns an C<errno> value to that error string. The error string is stored away, and will be used as the string value of C<$!> any time that C<errno> value is set in future. By default, register_errstr() picks a large C<errno> value that it has not yet assigned to any other string. 

If you call register_errstr() repeatedly with the same error string, it will notice and use the same C<errno> value each time. That means it's safe to do something like:

  $! = register_errstr "Too many foos defined";

in code that could be called a large number of times, and register_errstr() will store only one copy of the string and use up only one C<errno> value.

You can specify the C<errno> value to use as a second parameter to register_errstr(), for example:

  $! = register_errstr "my error string", 999999;

This sets the error string for C<errno> value 999999 (replacing any previously set error string for 999999) and assigns it to C<$!>. You can also call register_errstr() simply to register a bunch of new error codes, without assigning the return value to C<$!> each time:

  register_errstr "Invalid foodb file",      -20000;
  register_errstr "Invalid foodb parameter", -20001;
  register_errstr "foodb out of key slots",  -20002;

  # ...

  $! = -20001;
  print "$!\n"; # prints Invalid foodb parameter

It is also possible to use register_errstr() to replace the standard system error messages. For example, to replace the "Permission denied" message;

  use Errno qw/EACCES/;
  register_errstr "I'm sorry, Dave. I'm afraid I can't do that", EACCES;

  open my $fh, ">/no_permission_to_write_here";
  print "$!\n"; prints "I'm sorry, Dave. I'm afraid I can't do that"

This is not something I'd recommend, as it's likely to cause confusion. In general, when specifying the C<errno> value to register_errstr() one should take care to avoid values that are likely to be used for any other purpose.

Internally, the error strings registered by register_errstr() are kept in the C<%Errno::AnyString::Errno2Errstr> hash. You shouldn't go poking around in this hash yourself, but by localising it you can limit the scope of a register_errstr() registration:
  
  {
      local %Errno::AnyString::Errno2Errstr = %Errno::AnyString::Errno2Errstr;

      register_errstr "I'm sorry, Dave. I'm afraid I can't do that", EACCES;

      # here you have a silly error message in place of "Permission denied"
  }
  # here sanity is restored

=cut

sub register_errstr ($;$) {
    my ($str, $num) = @_;

    tainted $str and croak "Tainted error string used with Errno::AnyString";

    unless (defined $num) {
        $num = $_string2errno{$str};
        unless (defined $num) {
            $num = $_next_registered_errno++;
            $_string2errno{$str} = $num;
        }
    }
    $Errno2Errstr{$num} = "$str";

    return dualvar $num, $str;
}

=head1 INTER-OPERATION

This section is aimed at the authors of other modules that alter C<$!>'s behaviour, as a guide to ensuring clean inter-operation between Errno::AnyString and your module.

Errno::AnyString works by adding two instances of uvar magic to C<$!>, one at the head of the list and one at the tail. It does not modify or remove any existing magic from C<$!>. It should inter-operate cleanly with anything else that adds more magic to C<$!>, so long magic is added in a way that preserves existing uvar magic.

Emptying the C<%Errno::AnyString::Errno2Errstr> hash effectively turns off this module's interference with C<$!>, so you can get a "real" C<$!> value with:

  my $e = do { local %Errno::AnyString::Errno2Errstr ; $! };

=head1 AUTHOR

Dave Taylor, C<< <dave.taylor.cpan at gmail.com> >>

=head1 BUGS AND LIMITATIONS

=head2 C LEVEL STRERROR CALLS

If C level code attempts to get a textual error message based on C<errno> while a custom error string is set, it will get something like the following, depending on the platform:

  Unknown error 458513437

=head2 PURE NUMERIC RESTORE

If the string part of a saved custom_errstr() C<$!> value is lost, then restoring that value to C<$!> restores the string most recently set with custom_errstr(), which is not necessarily the string that was set when the C<$!> value was saved.

  $! = custom_errstr "String 1";
  my $saved_errno = 0 + $!;

  $! = custom_errstr "String 2";

  $! = $saved_errno;
  print "$!\n"; # prints String 2

Note that the Perl code that saved the error number had to go out of its way to discard the string part of C<$!>, so I think this combination is fairly unlikely in practice.

Error strings set with register_errstr() are not effected by this issue, since each gets its own unique C<errno> value. For this reason, register_errstr() should be used in preference to custom_errstr() if you have a small number of fixed error strings:

  $! = register_errstr "Attempt to frob without a foo"; # good

However, register_errstr() uses up an C<errno> value and permanently stores the string each time it is called with a string it has not seen before. If your code could generate a large number of different error strings over the lifetime of the Perl interpreter, then using register_errstr() could cost a lot of memory. In such cases, custom_errstr() would be a better choice.

  $! = register_errstr "failed at $line in $file: $why"; # less good 

=head2 TAINT MODE

I'm currently unable to find a good way to propagate the taintedness of custom error strings through C<$!>, due to an interaction between taint magic, C<$!>'s dualvar behaviour and the SvPOK flag in some Perl versions. If Perl is in taint mode then passing a tainted error string to custom_errstr() or register_errstr() will cause an immediate croak with the message:

  Tainted error string used with Errno::AnyString

=head2 OTHER BUGS

Please report any other bugs or feature requests to C<bug-errno-anystring at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Errno::AnyString>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Errno::AnyString

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Errno::AnyString>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Errno::AnyString>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Errno::AnyString>

=item * Search CPAN

L<http://search.cpan.org/dist/Errno::AnyString>

=back

=head1 SEE ALSO

L<Errno>, L<perlvar/ERRNO>, L<Scalar::Util>, L<perlguts>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dave Taylor, all rights reserved.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Errno::AnyString
