package Mason::Plugin::TidyObjectFiles;
$Mason::Plugin::TidyObjectFiles::VERSION = '2.24';
use Moose;
with 'Mason::Plugin';

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=head1 NAME

Mason::Plugin::TidyObjectFiles - Tidy object files

=head1 DESCRIPTION

Uses perltidy to tidy object files (the compiled form of Mason components).

=head1 ADDITIONAL PARAMETERS

=over

=item tidy_options

A string of perltidy options. e.g.

    tidy_options => '-noll -l=72'

    tidy_options => '--pro=/path/to/.perltidyrc'

May include --pro/--profile to point to a .perltidyrc file. If omitted, will
use default perltidy settings.

=back

=head1 SEE ALSO

L<Mason|Mason>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
