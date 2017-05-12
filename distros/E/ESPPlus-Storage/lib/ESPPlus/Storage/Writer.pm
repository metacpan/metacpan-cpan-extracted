package ESPPlus::Storage::Writer;
use 5.006;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $p     = shift;
    my $self = bless { %$p }, $class;
    
    return $self;
}

1;

__END__

=head1 NAME

ESPPlus::Storage::Writer - Writes ESP+ Storage repository files

=head1 SYNOPSIS

 N/A

=head1 DESCRIPTION

This module is not yet implemented. When it is, it will allow you to create
ESP+ Storage .REP files.

=head1 CONSTRUCTOR

=over 4

=item new

 $wr = ESPPlus::Storage::Writer->new(
     { compress_function => \&compress,
       handle            => $io_file_handle } );

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2003, Joshua b. Jore. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License as published by the Free Software
   Foundation; version 2, or

b) the "Artistic License" which comes with Perl.

=head1 SEE ALSO

L<ESPPlus::Storage>
