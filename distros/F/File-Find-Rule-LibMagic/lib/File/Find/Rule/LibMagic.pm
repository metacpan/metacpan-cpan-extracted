package File::Find::Rule::LibMagic;

use warnings;
use strict;

use base 'File::Find::Rule';
use File::LibMagic 0.96;
use Text::Glob qw(glob_to_regex);
use Params::Util qw(_ARRAY0 _REGEX);

=head1 NAME

File::Find::Rule::LibMagic - rule to match on file types or mime types

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use File::Find::Rule::LibMagic;

    my @executables = find( file => magic => '*executable*', in => $searchdir );
    my @images = find( file => mime => 'image/*', in => $homepagebase );

=head1 DESCRIPTION

File::Find::Rule::LibMagic extends L<File::Find::Rule> by matching files
depending on their magic file type or MIME type delivered through
L<File::LibMagic> from C<file(1)> UNIX command.

Every UNIX user (or users of unix-like systems) knows the C<file(1)> command.
With this module files can be found depending on their file type from magic
database or their MIME type.

It conflicts with L<File::Find::Rule::MMagic>.

=head1 EXPORT

This module doesn't export any function. The provided functionality is called
by L<File::Find::Rule> according to the matching rules.

=head1 SUBROUTINES/METHODS

=head2 magic

Accepts a list of strings or regular expressions which are approved to match
the result of L<File::LibMagic/checktype_filename|checktype_filename>.

=head2 mime

Accepts a list of strings or regular expressions which are approved to match
the result of L<File::LibMagic/describe_filename|describe_filename>.

=cut

sub File::Find::Rule::magic
{
    my $self = shift;
    local $Text::Glob::strict_wildcard_slash = 0; # allow '/opt/perl32/bin/perl script text executable'
    my @args = defined( _ARRAY0( $_[0] ) ) ? @{$_[0]} : @_;
    my @patterns = map { defined( _REGEX( $_ ) ) ? $_ : glob_to_regex $_ } @args;
    my $lm = File::LibMagic->new();
    $self->exec( sub {
                     my $type = $lm->describe_filename($_);
                     foreach my $pattern (@patterns) { return 1 if($type =~ m/$pattern/) }
                     return;
                 } );
}

sub File::Find::Rule::mime
{
    my $self = shift;
    my @args = defined( _ARRAY0( $_[0] ) ) ? @{$_[0]} : @_;
    my @patterns = map { defined( _REGEX( $_ ) ) ? $_ : glob_to_regex $_ } @args;
    my $lm = File::LibMagic->new();
    $self->exec( sub {
                     my $type = $lm->checktype_filename($_);
                     foreach my $pattern (@patterns) { return 1 if($type =~ m/$pattern/) }
                     return;
                 } );
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-find-rule-libmagic at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Find-Rule-LibMagic>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Find::Rule::LibMagic


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Find-Rule-LibMagic>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Find-Rule-LibMagic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Find-Rule-LibMagic>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Find-Rule-LibMagic/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of File::Find::Rule::LibMagic
