#===============================================================================
#         FILE:  Games::Go::AGA::Parse
#     ABSTRACT:  parsers for various AGA format files
#       AUTHOR:  Reid Augustin (REID), <reid@lucidport.com>
#      COMPANY:  LucidPort Technology, Inc.
#      CREATED:  12/02/2010 08:51:22 AM PST
#===============================================================================

use 5.002;
use strict;
use warnings;

package Games::Go::AGA::Parse;

our $VERSION = '0.042'; # VERSION

sub new {
    my ($proto, %opts) = @_;

    my $class = ref $proto || $proto;
    my $self = bless {}, $class;
    foreach my $key (qw(
        filename
        handle
        )) {
        if ($opts{$key}) {
            no strict 'refs';   ## no critic
            $self->$key(delete $opts{$key});
        }
    }
    if (%opts) {
        die "unknown option(s): ", join("\n", %opts);
    }

    return $self;
}

sub filename {
    my $self = shift;

    $self->{filename} = $_[0] if(@_);
    return $self->{filename};
}

sub handle {
    my $self = shift;

    $self->{handle} = $_[0] if(@_);
    return $self->{handle};
}

*parse = \&parse_line;  # alias parse to parse_line
sub parse_line {

    Games::Go::AGA::Parse::Exception->throw(
        error => "Don't use Games::Go::AGA::Parse directly, use Games::Go::AGA::Parse::SOMETHING",
    );
}

sub _parse_error {
    my $self = shift;

    Games::Go::AGA::Parse::Exception->throw(
        @_,
        filename => $self->filename,
        handle   => $self->handle,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::Parse - parsers for various AGA format files

=head1 VERSION

version 0.042

=head1 SYNOPSIS

  use Games::Go::AGA::Parse::TDList;
  use Games::Go::AGA::Parse::Register;
  use Games::Go::AGA::Parse::Round;

=head1 DESCRIPTION

Base class parsers for for various American Go Association (AGA) file formats.
Do not B<use> this module directly, but instead B<use> one of the format
parsers:

B<Games::Go::AGA::Parse::TDList> parses the list of AGA members
(available from <http://usgo.org/ratings>).

B<Games::Go::AGA::Parse::Register> parses a register.tde file which is
the player entry file for a go tournament.

B<Games::Go::AGA::Parse::Round> parses 1.tde, 2.tde, etc files which
are the files containing round pairing and results information.

These parsers are all line-oriented.  Accordingly, they provide a
B<parse_line> method which expects a single line of input optionally
terminated with an End of Line.  B<parse> is aliased to B<parse_line>.

In order to improve error messages produced when exceptions are
thrown, you can pass a 'filename' and a 'handle' option in the
-E<gt>B<new> calls.  Alternatively, you can wrap the calls to
-E<gt>B<parse_line> in an eval block and handle any exceptions
explicitly:

    eval {
        $parser->parse_line($line);
    };
    if (my $x = Exception::Class->caught('Games::Go::AGA::Parse::Exception')) {
        # $x is a Games::Go::AGA::Parse::Exception object
    }
    elsif ($@) {
        # $@ is a normal perl error string
    }

=head1 SEE ALSO

=over

=item Games::Go::AGA::Parse::TDList

=item Games::Go::AGA::Parse::Register

=item Games::Go::AGA::Parse::Round

=item Class::Exception

=item Games::Go::AGA::Parse::Exceptions

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
