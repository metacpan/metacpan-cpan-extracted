package FLTK;
use strict;
use warnings;
use Fl qw[:all];
our $VERSION = '0.99.15';
BEGIN {*FLTK:: = *Fl::}
1;
__END__

=encoding utf-8

=head1 NAME

FLTK - Historical Package Name Alias

=head1 SYNOPSIS

    use FLTK qw[:all];
    my $window = FLTK::Window->new(100, 100, 300, 180);
    my $box = FLTK::Box->new(FL_UP_BOX, 20, 40, 260, 100, 'Hello, World');
    $box->labelfont(FL_BOLD + FL_ITALIC);
    $box->labelsize(36);
    $box->labeltype(FL_SHADOW_LABEL);
    $window->end();
    $window->show();
    exit run();

=head1 DESCRIPTION

The FLTK package is a namespace alias for the Fl package. It's only use is to
allow (most) code written for the old FLTK distribution to use the new Fl
package with a little less work. Please note that the toolkit itself is not
100% compatible so expect complex code written for FLTK to just plain kill
over on Fl even with this alias.

Again the two toolkits are not 100% compatible!

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

