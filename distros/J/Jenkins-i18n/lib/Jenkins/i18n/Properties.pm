package Jenkins::i18n::Properties;

use 5.014004;
use strict;
use warnings;
use Carp qw(confess);
use parent 'Config::Properties';

our $VERSION = '0.03';

=pod

=head1 NAME

Jenkins::i18n::Properties - a subclass of L<Config::Properties>

=head1 SYNOPSIS

  use Jenkins::i18n::Properties;

  # reading...
  open my $fh, '<', 'my_config.props'
    or die "unable to open configuration file";
  my $properties = Config::Properties->new();
  $properties->load($fh);
  $value = $properties->getProperty($key);

  # saving...
  open my $fh, '>', 'my_config.props'
    or die "unable to open configuration file for writing";
  $properties->setProperty($key, $value);
  $properties->format('%s => %s');
  $properties->store($fh, $header );

=head1 DESCRIPTION

C<Jenkins::i18n::Properties> is a subclass of L<Config::Properties> and works
pretty much the same, except regarding the C<save> method, which is overrided.

=head2 EXPORT

None by default.

=head1 METHODS

=head2 save

This is an overrided method from the parent class.

It expects to receive the following positional parameters:

=over

=item 1.

A opened file handle created with C<open>.

=item 2.

An array reference with the license content to include in the properties file.

=back

Both are required.

This method, differently from the original of the parent class, does not
include a timestamp with C<localtime>.

This method B<does not> closes the given filehand at the end of the writting.

=cut

sub save {
    my ( $self, $fh, $license_ref ) = @_;
    confess "a file handle is a required parameter" unless ($fh);
    confess "license is a required parameter"       unless ($license_ref);
    confess "license must be an array reference"
        unless ( ref($license_ref) eq 'ARRAY' );

    foreach my $line ( @{$license_ref} ) {

        # the license is expected to have lines starting with
        # a space and with a new line at the end
        print $fh "#$line";
    }

    print $fh "\n";
    $self->_save($fh);
}

=head2 unescape

Remove escape characters from a string.

Expects a single string parameter, changing it in place.

=cut

sub unescape {
    my $text  = shift;
    my %unesc = (
        n => "\n",
        r => "\r",
        t => "\t",
    );

    $text =~ s/\\([tnr\\"' =:#!])|\\u([\da-fA-F]{4})/
        defined $1 ? $unesc{$1}||$1 : chr hex $2 /ge;
}

=head2 process_line

This is a method overrided from the superclass.

Process a single line retrieved from the Java properties file, saving the key
and value internally.

Returns C<1> if everything goes fine.

This method was overrided to allow the key value to retain it's escape
characters, as required by Jenkins translation files.

Additionally, this method will not attempt to fix UTF-8 BOM from very old perl
interpreters (version 5.6.0).

=cut

sub process_line {
    my ( $self, $file ) = @_;
    my $line = $self->read_line($file);
    defined $line or return undef;

    my $ln = $self->{last_line_number};

    # ignore comments
    $line =~ /^\s*(\#|\!|$)/ and return 1;

    # handle continuation lines
    my @lines;
    while ( $line =~ /(\\+)$/ and length($1) & 1 ) {
        $line =~ s/\\$//;
        push @lines, $line;
        $line = $self->read_line($file);
        $line = '' unless defined $line;

        # TODO: replace this with String::Strip
        $line =~ s/^\s+//;
    }
    $line = join( '', @lines, $line ) if @lines;

    my ( $key, $value ) = $line =~ /^
                                  \s*
                                  ((?:[^\s:=\\]|\\.)+)
                                  \s*
                                  [:=\s]
                                  \s*
                                  (.*)
                                  $
                                  /x
        or $self->fail("invalid property line '$line'");

    unescape($value);
    $self->validate( $key, $value );

    $self->{property_line_numbers}{$key} = $ln;
    $self->{properties}{$key}            = $value;

    return 1;
}

sub _save {
    my ( $self, $file ) = @_;

    foreach my $key ( $self->_sort_keys( keys %{ $self->{properties} } ) ) {
        $file->print(
            sprintf( $self->{'format'}, $key, $self->{properties}->{$key} ),
            "\n" );
    }
}

1;
__END__

=head1 SEE ALSO

=over

=item *

L<Config::Properties>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 of Alceu Rodrigues de Freitas Junior,
arfreitas@cpan.org

This file is part of Jenkins Translation Tool project.

Jenkins Translation Tool is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your option)
any later version.

Jenkins Translation Tool is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Jenkins Translation Tool. If not, see (http://www.gnu.org/licenses/).

The original `translation-tool.pl` script was licensed through the MIT License,
copyright (c) 2004-, Kohsuke Kawaguchi, Sun Microsystems, Inc., and a number of
other of contributors. Translations files generated by the Jenkins Translation
Tool CLI are distributed with the same MIT License.

=cut
