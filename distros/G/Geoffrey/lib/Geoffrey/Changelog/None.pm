package Geoffrey::Changelog::None;

use utf8;
use 5.016;
use strict;
use warnings;
use File::Slurp qw/write_file read_file/;
use Data::Dumper;

$Geoffrey::Changelog::None::VERSION = '0.000101';

use parent 'Geoffrey::Role::Changelog';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{ending}    //= '.pl';
    $self->{from_hash} //= 0;
    return bless $self, $class;
}

sub from_hash {
    my ($self, $b_load_from_hash) = @_;
    return $self->{from_hash} if !defined $b_load_from_hash;
    $self->{from_hash} = $b_load_from_hash;
    return $self;
}

sub tpl_main {
    return {
        templates => [{
                name => 'tpl_std',
                columns =>
                    [{name => 'id', type => 'integer', notnull => 1, primarykey => 1, default => 'inc',},],
            },
        ],
        prefix     => 'smpl',
        postfix    => 'end',
        changelogs => ['01',],
    };
}

sub tpl_sub {
    return [{
            id      => '001.01-maz',
            author  => 'Mario Zieschang',
            entries => [{action => 'table.add', name => 'client', template => 'tpl_std', columns => [],},],
        }];
}

sub load {
    my ($self, $ur_file_structure) = @_;
    return $self->from_hash ? $ur_file_structure : do($ur_file_structure . $self->ending());
}

sub write {
    my ($self, $dir, $hr_data, $b_dump) = @_;
    my $s_file = $dir . $self->ending;
    $hr_data = Data::Dumper->new([$hr_data])->Terse(1)->Deparse(1)->Sortkeys(1)->Dump;
    return $hr_data if $b_dump;
    return write_file($s_file, $hr_data);
}

1;    # End of Geoffrey::Changelog

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Changelog::None - File declacration for plain hashrefs or so :-P.

=head1 VERSION

Version 0.000101

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 new

=head2 tpl_main

=head2 tpl_sub

=head2 ending

=head2 load

Called to load defined Yaml files

=head2 write

Called to write defined Yaml files

=head2 from_hash

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Geoffrey

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geoffrey

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Geoffrey

    CPAN Ratings
        http://cpanratings.perl.org/d/Geoffrey

    Search CPAN
        http://search.cpan.org/dist/Geoffrey/

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
