package ExtUtils::MakeMaker::Extensions;

use 5.8.3;
use strict;
use warnings FATAL => 'all';

=head1 NAME

ExtUtils::MakeMaker::Extensions - Helper for multiple ExtUtils::MakeMaker extensions

=cut

our $VERSION = '0.001';

=head1 SYNOPSIS

For Makefile.PL authors:

    package MY;
    
    use ExtUtils::MakeMaker::Extensions ':MY';
    
    with 'File::ConfigDir::Install', '...'

For ExtUtils::MakeMaker::Extensions authors:

    package My::EUMM::Extension;
    
    use Role::Tiny;
    use Class::Method::Modifiers;

    around postamble => sub {
        my $next           = shift;
        my $self           = shift;
        my $postamble_code = $self->$next(@_);

        $postamble_code .= "${own_additions}";

        return $postamble_code;
    };

=head1 DESCRIPTION

This is a namespace reservation with kind of concept behind ...

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-extutils-makemaker-extensions at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ExtUtils-MakeMaker-Extensions>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ExtUtils::MakeMaker::Extensions

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ExtUtils-MakeMaker-Extensions>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ExtUtils-MakeMaker-Extensions>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ExtUtils-MakeMaker-Extensions>

=item * Search CPAN

L<http://search.cpan.org/dist/ExtUtils-MakeMaker-Extensions/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of ExtUtils::MakeMaker::Extensions
