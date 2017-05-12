use Carp;

confess( "BooleanQuery has been removed.  Its past functionality now resides "
        . "in ANDQUery, ORQuery, NOTQuery, and RequiredOptionalQuery." );

1;

__END__

__POD__

=head1 NAME

KinoSearch::Search::BooleanQuery - Removed.

=head1 DESCRIPTION 

BooleanQuery has been removed from KinoSearch as of version 0.30.  
Its past functionality can now be achieved using 
L<ANDQuery|KinoSearch::Search|ANDQuery>,
L<ORQuery|KinoSearch::Search|ORQuery>,
L<NOTQuery|KinoSearch::Search|NOTQuery>, and
L<RequiredOptionalQuery|KinoSearch::Search|RequiredOptionalQuery>,

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2011 Marvin Humphrey

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

