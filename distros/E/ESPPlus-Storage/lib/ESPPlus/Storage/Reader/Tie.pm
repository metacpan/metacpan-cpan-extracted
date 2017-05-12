package ESPPlus::Storage::Reader::Tie;
use strict;
use warnings;
use ESPPlus::Storage;

use base 'Tie::Handle';

sub TIEHANDLE {
    my $class = shift;
    my $self = {};
    $self->{'storage'} = ESPPlus::Storage->new( shift );
    $self->{'reader'}  = $self->{'storage'}->reader;
    # writer?

    bless $self, $class;
}

#sub READ { read shift()->{'reader'}->handle(), shift, shift, shift }
sub SEEK { seek shift()->{'reader'}->handle(), shift, shift }
sub TELL { tell shift()->{'reader'}->handle }
sub EOF { eof shift()->{'reader'}->handle }
sub READLINE {
    my $rd = shift()->{'reader'};
    
    return $rd->next_record_body unless wantarray;
    
    local $_;
    my @o;
    while (my $rec = $rd->next_record_body) {
	push @o, $rec;
    }
    return @o;
}
sub CLOSE { close shift()->{'reader'}->handle }

1;

__END__

=head1 NAME

ESPPlus::Storage::Reader::Tie - A simple interface for reading ESP+ Storage repository files

=head1 SYNOPSIS

 use Symbol 'gensym';
 use ESPPlus::Storage::Reader::Tie;

 my $db = gensym;
 tie *$db, 'ESPPlus::Storage::Reader::Tie,
   { filename => $Repository,
     uncompress_function => \&uncompress }
     or die "Can't tie \$db to $Repository: $!";
 while (my $record = <$db>) {
     print "$$record\n";
 }
 close $db;
 untie $db;

=head1 DESCRIPTION

This allows for a simple file oriented API to an ESP+ Storage repository. You
can just tie a file handle to your database and read it like it was a normal
file. Not all of the L<Tie::Handle> methods have been handled - everything
associated with writing to the file is omitted.

If you find this useful or have suggestions I'm very open to alterations.

=head1 COPYRIGHT AND LICENSE

Copyright 2003, Joshua b. Jore. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License as published by the Free Software
   Foundation; version 2, or

b) the "Artistic License" which comes with Perl.

=head1 SEE ALSO

L<ESPPlus::Storage::Reader>
L<ESPPlus::Storage>

=cut 
