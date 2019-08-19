package Geoffrey::Changelog::Yaml;

use utf8;
use 5.016;
use strict;
use warnings;
use YAML::XS;

$Geoffrey::Changelog::Yaml::VERSION = '0.000100';

use parent 'Geoffrey::Role::Changelog';

sub new {
    my $s_class = shift;
    my $self    = $s_class->SUPER::new(@_);
    $self->{ending} //= '.yml';
    return bless $self, $s_class;
}

sub tpl_main {
    my $s_message = <<'END_MESSAGE';

---
templates:
    - name: tpl_std
      columns:
      - name: id
        type: integer
        notnull: 1
        primarykey: 1
        default: autoincrement

prefix: smpl
postfix: end

changelogs: 
  - "01"
END_MESSAGE

    return $s_message;
}

sub tpl_sub {
    my $s_message = <<'END_MESSAGE';
- id: 001.01-maz
  author: "Mario Zieschang"
  entries:
    - action: table.add
      name: 'client'
      template: 'tpl_std'
END_MESSAGE
    return $s_message;
}

sub extension { return $_[0]->ending; }

sub load {
    my ( $self, $s_file ) = @_;
    return YAML::XS::LoadFile( $s_file . $self->extension );
}

sub write {
    my ( $self, $dir, $data, $dump ) = @_;
    return YAML::XS::Dump($data) if $dump;
    return YAML::XS::DumpFile( $dir . $self->extension, $data );
}

1;    # End of Geoffrey::Changelog

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Changelog::Yaml - module for Geoffrey::Changelog to load changeset from YAML files.

=head1 VERSION

Version 0.000100

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 new

=head2 tpl_main

=head2 tpl_sub

=head2 load

Called to load defined Yaml files

=head2 write

Called to write defined Yaml files

=head2 extension

deprecation support

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-Geoffrey at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geoffrey>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Geoffrey::Converter::SQLite

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geoffrey>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geoffrey>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geoffrey>

=item * Search CPAN

L<http://search.cpan.org/dist/Geoffrey/>

=back

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, trade name, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANT ABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
