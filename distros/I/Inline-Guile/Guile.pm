package Inline::Guile;

use strict;
use warnings;

require Inline;
our @ISA = qw(Inline);

our $VERSION = '0.001';

use Guile;
use Carp qw(croak confess);

# register for Inline
sub register {
  return {
          language => 'Guile',
          aliases  => ['GUILE'],
          type     => 'interpreted',
          suffix   => 'go',
         };
}

# check options
sub validate {
  my $self = shift;

  while(@_ >= 2) {
    my ($key, $value) = (shift, shift);
    croak("Unsupported option found: \"$key\".");
  }
}

# required method - doesn't do anything useful
sub build {
  my $self = shift;

  # magic dance steps to a successful Inline compile...
  my $path = "$self->{API}{install_lib}/auto/$self->{API}{modpname}";
  my $obj = $self->{API}{location};
  $self->mkpath($path) unless -d $path;
  $self->mkpath($self->{API}{build_dir}) unless -d $self->{API}{build_dir};

  # touch my monkey
  open(OBJECT, ">$obj") or die "Unable to open object file: $obj : $!";
  close(OBJECT)         or die "Unable to close object file: $obj : $!";
}

# load the code into the interpreter
sub load {
  my $self = shift;  
  my $code = $self->{API}{code};
  my $pkg = $self->{API}{pkg} || 'main';

  # append testing mark
  $code .= "\n1\n";

  # try evaluating the code
  my $result;
  eval { $result = Guile::eval_str($code);  };
  croak("Inline::Guile : Problem evaluating Guile code:\n$code\n\nReason: $@")
    if $@;
  croak("Inline::Guile : Problem evaluating Guile code:\n$code\n")
    unless $result == 1;

  # look for possible global defines
  while($code =~ /define\s+(\S+)/g
        # + cperl-mode, I hate you.
       ){
    my $name = $1;
    
    # try to lookup a procedure object
    my $proc = Guile::lookup($name);

    if (Guile::procedure_p($proc)) {
      # got a live one, register it
      no strict 'refs';
      *{"${pkg}::$name"} = sub { Guile::apply($proc, [@_]); }
    }
  }
  
}

# no info implementation yet
sub info { }


1;
__END__

=pod

=head1 NAME

Inline::Guile - Inline module for the GNU Guile Scheme interpreter

=head1 SYNOPSIS

  use Inline::Guile => <<END;
     (define square (x) (* x x))
  END

  my $answer = square(10); # returns 100

=head1 DESCRIPTION

This module allows you to add blocks of Scheme code to your Perl
scripts and modules.  Any procedures you define in your Scheme code
will be available in Perl.

For information about handling Guile data in Perl see L<Guile>.  This
module is mostly a wrapper around Guile::eval_str() with a little
auto-binding magic for procedures.

For details about the Inline interface, see L<Inline>.

=head1 BUGS

=head2 Error Messages

The error messages you get from this module are pretty useless.  They
don't mention anything about where they came from.  This is something
I will be addressing in the next release.

=head2 Procedure Binding

The module is pretty dumb about finding procedures to bind.  It just
scans through your code looking for things that might be a "(define
foo ...)."  It then trys a Guile::lookup() on "foo" and binds any
resulting procedure.  This is sufficient for simple cases but it won't
catch module imports, macros that call define behind the scenes or any
other such trickery.  Any suggestions for improvement would be
appreciated!

=head2 Guile.pm Bugs

Guile.pm is in an early alpha state.  It has some pretty nasty bugs
that you should know about if you're using Inline::Guile.  Check out
the BUGS section in the Guile.pm docs.

=head1 GETTING INVOLVED

This project is just starting and the more people that get involved
the better.  For the time being we can use the Inline mailing-list to
get organized.  Send a blank message to inline-subscribe@perl.org to
join the list.

If you just want to report a bug (just one?) or tell how sick the
whole idea makes you then you can email me directly at sam@tregar.com.

=head1 SEE ALSO

Inline

=head1 LICENSE

Inline::Guile : Inline module for the GNU Guile Scheme interpreter
Copyright (C) 2001 Sam Tregar (sam@tregar.com)

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,
or

b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file ARTISTIC.  If not, I'll be glad to provide one.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

=cut

=head1 AUTHOR

Sam Tregar, sam@tregar.com

=head1 SEE ALSO

Guile, Inline

=cut
