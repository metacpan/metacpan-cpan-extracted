package Locale::MakePhrase::Print;
our $VERSION = 0.1;
our $DEBUG = 0;

=head1 NAME

Locale::MakePhrase::Print - Overload of C<print> to automate translations

=head1 SYNOPSIS

Using this module, it will override C<print> statements so that your
application automatically gets translated into the target language.

Example:

Your application will have previously instantiated a L<Locale::MakePhrase>
object in some other module.  Now you need to use that instantiation
within a particular module; from here:

  use Locale::MakePhrase::Print;
  ...
  print "Some text to be translated.";

When C<print> is called, the text is automatically fed into the
translation engine.

=head1 DESCRIPTION

The purpose of this module, is to de-couple the use of the translation
engine, from the API of the translation engine.  This saves you from
littering your application code with translation-specific function
calls.  The main benefits are:

=over 2

=item *

makes the code easier to read

=item *

allows you to easily change to a different translation engine

=item *

decouples translation from application design

=back

=head1 API

To use this module, you simply need to C<use> it at the top of your
own module.  You can optionally specify a specific filehandle to print
to (rather than STDOUT), eg:

  use Locale::MakePhrase::Print;
  ...
  print "Some text";

or

  open(FH,">some_output_file.txt") or die;
  use Locale::MakePhrase::Print \*FH;
  ...
  print "Some text";

Will print B<Some text> to STDOUT or the specified filehandle.

To stop overriding C<print>:

  no Locale::MakePhrase::Print;

=cut

use strict;
use warnings;
use utf8;
use Symbol;
use Exporter;
use base qw(Exporter);
use Locale::MakePhrase::Utils qw(die_from_caller);
our $STDOUT;
our $filehandle;
our $print = 1;
our $println = 1;
our $this;

#
# Install a println handler to handle println'ing to a filehandle
#
sub IO::Handle::println {
  my $FH = shift;
  print $FH (@_,$/);
}

#
# Install a println handler to handle println'ing to a stdout
#
sub main::println {
  CORE::print (@_,$/);
}

#
# Handle use/no options
#
sub get_options {
  my $func = shift;
  my $options = shift;
  $options = {} unless (defined $options);
  if (@_ > 1 and not(@_ % 2)) {
    %$options = @_;
  } elsif (@_ == 1 and ref($_[0]) eq "HASH") {
    %$options = %{$_[0]};
  } elsif (@_ == 1 and ref($_[0]) eq "GLOB") {
    $options->{filehandle} = shift;
  } elsif (@_ == 1 and ref($_[0]) eq "" and $_[0] eq "print") {
    $options->{print} = 1;
  } elsif (@_ == 1 and ref($_[0]) eq "" and $_[0] eq "println") {
    $options->{println} = 1;
  } elsif (@_ > 0) {
    die_from_caller "Unknown arguments to '$func ".__PACKAGE__." ...;' call";
  }
  $print = (exists $options->{print}) ? ($options->{print} ? 1 : 0) : $print;
  $println = (exists $options->{println}) ? ($options->{println} ? 1 : 0) : $println;
}

#
# On module import we override printing to STDOUT, by overriding
# the 'print' function, so that translations become automatic. We
# also export the translation-engine-enabled 'println' function.
#
sub import {
  my $class = shift;
  my $caller = caller;
  my $sym = gensym;
  $STDOUT = select unless (defined $STDOUT);

  my %options;
  get_options('use',\%options,@_) if @_;
  $filehandle = (exists $options{filehandle}) ? $options{filehandle} : (defined $filehandle ? $filehandle : $STDOUT);
  die "Invalid filehandle specification" unless (defined $filehandle);

  $this = tie *$sym, $class, $filehandle;
  bless $sym, $class;

  # Override 'print'
  if ($print) {
    select $sym;
  }

  # Override 'println'
  if ($println) {
    no strict 'refs';
    *{$caller."::println"} = \&{$class."::LM_println"};
  }

  return $class;
}

#
# On module unimport we reset printing to STDOUT so that it
# goes back to Perl's default behaviour.  We also reset the exported
# 'println' function so as to not be bound to the translation-engine.
#
sub unimport {
  my $class = shift;
  my $caller = caller;
  get_options('no',undef,@_) if @_;

  # Reset 'print'
  if ($print) {
    select $STDOUT;
  }

  # Reset 'println'
  if ($println) {
    no strict 'refs';
    *{$caller."::println"} = \&{$class."::CORE_println"};
  }

  return $class;
}

#
# Automatically called when the module is imported due to overriding
# the import() sub.
#
sub TIEHANDLE { 
  my $class = shift;
  my $self = bless {}, $class;
  if (@_ > 0) {
    $self->{fh} = shift or die "No filehandle specified in constructor.";
  } else {
    $self->{fh} = select;
  }
  return $self;
}

#
# Install the appropriate mp() function to point to the correct
# implementation, based on debugging settings.
#
local *mp;
if ($DEBUG > 5) {
  *mp = sub { __PACKAGE__.": ",@_ };
} else {
  *mp = \&Locale::MakePhrase::mp;
}

#
# Implement custom 'print' behaviour
#
sub PRINT {
  my $self = shift;
  my $fh = *{ $self->{fh} };
  CORE::print $fh (mp(@_));
}

#
# Implement custom 'println' behaviour
#
sub PRINTLN {
  my $self = shift;
  my $fh = *{ $self->{fh} };
  CORE::print $fh (mp(@_).$/);
}

#
# Setup object->method signatures 
#
no warnings 'once';
*new = *TIEHANDLE;
*print = *PRINT;
*println = *PRINTLN;
use warnings 'once';

#--------------------------------------------------------------------------

#
# Implement generic 'println' behaviour
#
sub CORE_println {
  CORE::print $STDOUT @_,$/;
}

#
# Implement custom 'println' behaviour
#
sub LM_println {
  PRINTLN $this, @_;
}

=head2 println "..." [, ...]

This function is explicatly exported so that users can avoid having
to specify the newline character in the translation key.

Note: when C<no Locale::MakePhrase::Print> is in effect, C<println>
simply prints out the un-translated string, including a the newline.

=cut

#
# 'println' is dyamically linked into the symbol table, based on the
# 'use'/'no' behaviour; see import() sub.
#

1;
__END__
#--------------------------------------------------------------------------

=head1 NOTES

This module overrides C<print> only for the STDOUT filehandle; this
also applies to exported the C<println> function. ie: specifying a
filehandle to C<print> will result in no translation occurring,
or some weired error if used with C<println>.

Thus to specifically avoid using the overridden C<print> function,
explicatly specify the filehandle as in:

  print STDOUT "Some un-translated text.";

=cut
