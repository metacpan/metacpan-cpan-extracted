package File::Attributes::Extended;

use warnings;
use strict;
use base 'File::Attributes::Base';
use File::ExtAttr ':all';
our $VERSION = '0.01';

sub priority { 6 };
sub applicable {
    my $self = shift;
    my $file = shift;
    
    eval { $self->get($file, 'perltest') };
    return if $@; # can't use
    return 1; # can use
}

sub get {
    my $self = shift;
    my $file = shift;
    my $attr = shift;
    # make warnings fatal
    local $SIG{__WARN__} = sub { die "$_[0] ($!)" };
    return getfattr($file, $attr);
}

sub set {
    my $self = shift;
    my $file = shift;
    my $attr = shift;
    my $value= shift;
    
    # make warnings fatal
    local $SIG{__WARN__} = sub { die "$_[0] ($!)" };
    setfattr($file, $attr, $value);
    return 1;
}

sub list {
    my $self = shift;
    my $file = shift;
    
    local $!;
    my @result = listfattr($file);
    die "Error listing attributes: $!" if !@result && $!;
    return @result;
}

sub unset {
    my $self = shift;
    my $file = shift;
    my $attr = shift;
    
    # make warnings fatal
    local $SIG{__WARN__} = sub { die "$_[0] ($!)" };

    return delfattr($file, "$attr");
}

1;
__END__
=head1 NAME

File::Attributes::Extended - Access UNIX extended filesystem
attributes with File::Attributes.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

    use File::Attributes ':all';
    set_attribute('filename', foo => 'bar');
    print get_attribute('filename', 'foo'); # bar

This module should not be used directly --
L<File::Attributes|File::Attributes> will automatically use it when
possible.

If you're sure you don't want the C<File::Attributes> API, see
L<File::ExtAttr>.

=head1 FUNCTIONS

This module implements all of the functions File::Attributes expects.
See L<File::Attributes::Base> for more information.

=head2 get

=head2 set

=head2 unset

=head2 list

=head2 applicable

Applicable if the file's filesystem supports extended filesystem
attributes.

=head2 priority

Priority 6 (medium)

=head1 AUTHOR

Jonathan Rockway, C<< <jrockway at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-file-attributes-extended at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Attributes-Extended>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Attributes::Extended

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Attributes-Extended>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Attributes-Extended>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Attributes-Extended>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Attributes-Extended>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jonathan Rockway, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of File::Attributes::Extended
