package Devel::Chitin::SubroutineLocation;

use strict;
use warnings;

our $VERSION = '0.13';

use Carp;

my @properties = qw(package subroutine line filename end code source source_line);
foreach my $prop ( @properties ) {
    my $sub = sub { shift->{$prop} };
    no strict 'refs';
    *$prop = $sub;
}

sub new {
    my($class, %props) = @_;

    foreach my $prop ( @properties ) {
        Carp::croak("$prop is a required property") unless (exists $props{$prop});
    }

    return bless \%props, $class;
}

sub new_from_db_sub {
    my($class, $subname) = @_;

    return () unless (defined($subname) and $DB::sub{$subname});
    my($filename, $line, $end) = $DB::sub{$subname} =~ m/(.*):(\d+)-(\d+)$/;
    my($source, $source_line) = $filename =~ m/\[(.*):(\d+)\]$/;
    my $glob = do {
        no strict 'refs';
        \*$subname;
    };
    return Devel::Chitin::SubroutineLocation->new(
            filename    => $filename,
            line        => $line,
            end         => $end,
            source      => $source || $filename,
            source_line => $source_line || $line,
            subroutine  => *$glob{NAME},
            package     => *$glob{PACKAGE},
            code        => *$glob{CODE} );
}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::SubroutineLocation - A class to represent the location of a subroutine

=head1 SYNOPSIS

  my $sub_name = 'The::Package::subname';
  my $loc = $debugger->subroutine_location($subname);
  printf("subroutine %s is in package %s in file %s from line %d to %d\n",
        $loc->subroutine,
        $loc->package,
        $loc->filename,
        $loc->line,
        $loc->end);

=head1 DESCRIPTION

This class is used to represent a subroutine with location in the debugged
program.

=head1 METHODS

  Devel::Chitin::SubroutineLocation->new(%params)

Construct a new instance.  The following parameters are accepted; all are
required.

=over 4

=item package

The package the subroutine was declared in.

=item filename

The file in which the subroutine appears.

=item subroutine

The name of the subroutine.

=item line

The line the subroutine starts.

=item end

The line the subroutine ends.

=item code

A callable coderef for the subroutine.

=back

Each construction parameter also has a read-only method to retrieve the value.

=head1 SEE ALSO

L<Devel::Chitin::Location>, L<Devel::Chitin>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2017, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.

