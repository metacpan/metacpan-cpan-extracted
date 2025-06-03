package Debug::Helper::Flag;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(DEBUG_FLAG);

use Carp;

our $strict = $ENV{PERL_DEBUG_HELPER_FLAG_STRICT};

my $Value;

sub import {
  my $caller = shift;
  my @args = @_;

  croak("Too many args") if @args > 3;

  my $exp;
  if (@args % 2) {
    $exp = shift(@args) // croak("Undefined module argument");
    $exp eq 'DEBUG_FLAG' or croak("'$exp': invalid module argument");
  }
  my ($want_define, $val);
  if (@args) {
    croak("Undefined module argument") if !defined($args[0]);
    croak("'$args[0]': invalid module argument") if $args[0] ne 'DEBUG_FLAG';
    $want_define = 1;
    $val = !!$args[1];
  }
  if ($want_define) {
    if (defined($Value)) {
      croak("Attempt to redefine DEBUG_FLAG with different value") if $val ne $Value;
    }
    else {
      $Value = $val;
      {
        no strict 'refs';         ## no critic (ProhibitNoStrict)
        my $const_val = $val;
        *{__PACKAGE__ . "::DEBUG_FLAG"} = sub () {$const_val};
      }
    }
  }
  if ($exp) {
    if (!defined($Value)) {
      state $msg = "Attempt to export while constant is not yet defined";
      if ($strict) {
        croak($msg);
      } else {
        carp($msg);
      }
    }
    __PACKAGE__->export_to_level(1, $caller, $exp)
  }
}



1; # End of Debug::Helper::Flag


__END__

=head1 NAME

Debug::Helper::Flag - Define and import boolean constant DEBUG_FLAG helping to optimize code.


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

In main script (or a module you use early):

  use Debug::Helper::Flag DEBUG_FLAG => BOOL_VAL;

Where I<C<BOOL_VAL>> is a boolean value. In your module do:

  use Debug::Helper::Flag 'DEBUG_FLAG';

  # ...
  sub Foo {
    if (DEBUG_FLAG) { do_argument_check }
    # ...
  }



=head1 DESCRIPTION

This module lets you set a constant C<Debug::Helper::Flag::DEBUG_FLAG> which is
imported on demand. Intended to be used to optimze code like this:

  use Debug::Helper::Flag 'DEBUG_FLAG';

  # ...
  sub Foo {
    if (DEBUG_FLAG) { do_argument_check }
    # ...
  }

If C<DEBUG_FLAG> is I<true>, then C<do_argument_check> is executed but if
it is I<false> then the perl compiler will completely optimize away the
statement, including the surrounding C<if(...)> construction. The constant
must be set to I<true> or I<false> before you can import it. The
constant should be specified in the main script or on the command line.

  use Debug::Helper::Flag DEBUG_FLAG => 0;

or

  use Debug::Helper::Flag DEBUG_FLAG => 1;


or on the command line

  perl -MDebug::Helper::Flag=DEBUG_FLAG,1 ...

If you need to specify B<and> use the constant in the same script, then you
can do:

  use Debug::Helper::Flag 'DEBUG_FLAG', DEBUG_FLAG => 1;

B<Note:> using this

  use Debug::Helper::Flag DEBUG_FLAG => EXPRESSION;

multiple times is not a problem provided that I<C<EXPRESSION>> always
evaluates to the same boolean value. Otherwise the script terminates with
error message C<Attempt to redefine DEBUG_FLAG with different value>.

B<Note:> only load this module directly via C<use> or in a C<BEGIN> block and
never try to load it at runtime, otherwise the optimization will not work!

If you try to import C<DEBUG_FLAG> while it is not yet defined, the warning
"Attempt to export while constant is not yet defined" is printed. If you want
a fatal error instead, set the environment variable
C<PERL_DEBUG_HELPER_FLAG_STRICT> (or C<$Debug::Helper::Flag::strict>) to a
I<true> value. This is a warning by default to avoid problems when using
L<Perl::LanguageServer> with e.g. the corresponding VS Code plugin.


=head1 SEE ALSO

L<https://metacpan.org/pod/Getopt::constant>

=head1 AUTHOR

Abdul al Hazred, C<< <451 at gmx.eu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-debug-helper-flag at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Debug-Helper-Flag>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Debug::Helper::Flag


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Debug-Helper-Flag>


=item * Search CPAN

L<https://metacpan.org/release/Debug-Helper-Flag>

=item * GitHub Repository

L<https://github.com/AAHAZRED/perl-Debug-Helper-Flag>

=back



=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Abdul al Hazred.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut
