#
# This file is part of Language::Ook.
# Copyright (c) 2002-2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Language::Ook;

use 5.006;

=head1 NAME

Language::Ook - a Ook! interpreter.


=head1 SYNOPSIS

    use Language::Ook;
    my $interp = new Language::Ook( "program.ook" );
    $interp->run_code;

    # Print the Perl code.
    $interp->print_code;


=head1 DESCRIPTION

A programming language should be writable and readable by orang-utans.
So Ook! is a programming language designed for orang-utans.

Ook! is bijective with BrainFuck, and thus, Turing-complete.

=cut


use strict;
use warnings;
use Carp;
our $VERSION = '1.0.2';


=head1 CONSTRUCTOR

=head2 new( [filename] )

Create a new Ook interpreter. If a filename is provided, then read
and store the content of the file.

=cut
sub new {
    # Create and bless the object.
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = { code => "" };
    bless $self, $class;
    # Read the file if needed.
    my $file = shift;
    defined($file) and $self->read_file( $file );
    # Return the object.
    return $self;
}


=head1 ACCESSORS

=head2 code (  )

Return the associated Perl code.

=cut

sub code :lvalue { $_[0]->{code} }


=head1 PUBLIC METHODS

=head2 print_code(  )

Print the equivalent Perl code.

=cut

sub print_code {
    print $_[0]->code;
}

=head2 read_file( filename )

Read a file (given as argument) and store its code.

Side effect: clear the previous code.

=cut

sub read_file {
    my ($self, $filename) = @_;
    # Fetch the code.
    my $code;
    open OOK, "<$filename" or croak "$filename: $!";
    {
        local $/; # slurp mode.
        $code = <OOK>;
        $code .= " ";
    }
    close OOK;
    # Store code.
    $code =~ s/[\n\s]+/ /g;
    my $perl = "{ local \$^W = 0;\nuse bytes;\nmy \@cell = ();\nmy \$ptr = 0;\n";
    while ( $code =~ m/Ook(.) Ook(.) /g ) {
        my $instr = $1.$2;
      sw: {
            $instr eq ".?" and $perl .= '$ptr++;', last sw;
            $instr eq "?." and $perl .= '$ptr--;', last sw;
            $instr eq ".." and $perl .= '$cell[$ptr]++;', last sw;
            $instr eq "!!" and $perl .= '$cell[$ptr]--;', last sw;
            $instr eq ".!" and $perl .= 'read(STDIN,$cell[$ptr],1)?ord($cell[$ptr]):0;', last sw;
            $instr eq "!." and $perl .= 'print chr($cell[$ptr]);', last sw;
            $instr eq "!?" and $perl .= 'while ($cell[$ptr]) {', last sw;
            $instr eq "?!" and $perl .= '}', last sw;
            croak "Ook! Ook$1 Ook$2\n";
        }
        $perl .= "\n";
    }
    $perl .= "}\n";
    $self->code = $perl;
}


=head2 run_code(  )

Run the stored code.

=cut

sub run_code {
    my $self = shift;
    eval $self->{code};
}



1;
__END__

=head1 AUTHOR

Jerome Quelin, E<lt>jquelin@cpan.orgE<gt>


=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

=over 4

=item L<http://www.dangermouse.net/esoteric/ook.html>

=back

=cut
