package File::Temp::Rename;
{
  $File::Temp::Rename::VERSION = '0.02';
}
# ABSTRACT: Create a temporary file object for output, and rename it when done.

use strict;
use warnings;
use Carp;
use File::Temp;
use File::Copy qw/move/;
use Scalar::Util qw/refaddr/;
use base qw/File::Temp/;

our %obj2original;

sub new {
    my $class = shift;
    my %opt = @_;
    my $filename = delete $opt{FILE} or croak "need FILE argument";
    my $clobber  = delete $opt{CLOBBER};

    if (-e $filename and ! $clobber){
        return;
    }

    my $self = $class->SUPER::new(TEMPLATE => "$filename.tmpXXXXX", UNLINK => 0) or croak "couldn't create tmp file";
    my $tmp_filename = $self->filename;

    my $addr = refaddr($self);
    $obj2original{$addr} = $filename;
    return $self;
}

sub DESTROY{
    my $self = shift;
    my $filename = delete $obj2original{refaddr($self)} or die "$self does not have appropriate entry in obj2original? bug, please report";
    my $tmp_filename = $self->filename;
    
    $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");

    move($tmp_filename, $filename) or croak "couldn't rename $tmp_filename to $filename";
}

1;

__END__

=pod

=head1 NAME

File::Temp::Rename - Create a temporary file object for output, and rename it when done.

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 my $ftr = File::Temp::Rename->new(FILE => "output.txt", CLOBBER => 0);
 $ftr->print("This is printed to output.txt.tmpXXXXXX, where the X's are random strings");

=head1 METHODS

=head2 my $ftr = File::Temp::Rename->new(FILE => 'final-output.txt', CLOBBER => BOOL)

Constructor.  Create a temporary file named 'final-output.txt.tmpXXXXXX'.  When
the object gets destroyed, rename to 'final-output.txt'. If the final output
file already existed, overwrite it if CLOBBER is true.  Otherwise, constructor returns undef.

=head1 METHODS

File::Temp::Rename is a subclass of File::Temp, and thus inherits all its methods.

=head1 AUTHOR

T. Nishimura <tnishimura@fastmail.jp>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by T. Nishimura.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
