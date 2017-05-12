#############################################################################
#
# Work with updates (typically Bodhi)
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 05/12/2009 09:54:18 PM PDT
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::MaintainerTools::Command::updates;

use 5.010;

use Moose;
use namespace::autoclean;
use IO::Prompt;

extends 'MooseX::App::Cmd::Command';

our $VERSION = '0.006';

my @CLASSES = qw{
    Fedora::Bodhi
    Text::SimpleTable
    DateTime::Format::Pg
    DateTime
};

sub execute {
    my ($self, $opt, $args) = @_;

    #$self->log->info('Beginning updatespec run.');

	die "This command isn't quite unbroken yet.\n";

    Class::MOP::load_class($_) for @CLASSES;

    my $push_date = DateTime->now->subtract( days => 5 );
    my $b = Fedora::Bodhi->new;
    my $list = $b->list(username => 'cweyl', status => 'testing');
    my @updates = @{ $list->{updates} };

    ### num updates in testing: scalar @updates

    print to_table(@updates) . "\n";

    print "Autopush parameters:\n" .
        "\tkarma >= 0, push date older than 5 days ($push_date).\n\n";

    if (prompt "Autopush? " => -YyNn1) {

        print "\n";
        _check_and_push($b, $push_date, $_) for @updates;
    }

    return;
}

sub _check_and_push {
    my ($b, $push_date, $update) =  @_;

    return unless $update->{date_pushed};

    my $push_dt =
        DateTime::Format::Pg->parse_datetime($update->{date_pushed});

    my $title = $update->{title};
    my $karma = $update->{karma};

    #print "$title (karma: $karma) $push_dt\n";

    if ($karma >= 0 && $push_dt < $push_date) {

        my $j = $b->_simple_request("request/stable/$title",
            #user_name => 'YYYY', password => 'XXXX', login => 'Login',
            #user_name => $b->userid, password => $b->passwd, login => 'Login',
        );

        say "PUSHED $update->{updateid}";
    }
}

sub to_table {
    my @updates = @_;

    my $t = Text::SimpleTable->new(
        [ 40, 'ID' ],
        #[ 12, 'status' ],
        [ 6, 'bugs' ],
        #[ 40, 'builds' ],
    );

    #my $get = sub { my @v; push @v, $_->{$_[1]} for @{$u->{$_[0]}}; @v };

    for my $u (@updates) {

        my $get = sub { my @v; push @v, $_->{$_[1]} for @{$u->{$_[0]}}; @v };
        my @builds = $get->('builds', 'nvr');

        $t->row(
            "$u->{release}->{name}: $u->{updateid}\n"
            . "$u->{status} ($u->{karma}) on $u->{date_pushed}\n"
            . join("\n", @builds),
            join("\n", $get->('bugs', 'bz_id')) || 'none',
        );
        $t->hr;
    }

    return $t->draw;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Fedora::App::MaintainerTools::Command::updatespec - Update a spec to latest GA version from the CPAN

=head1 DESCRIPTION

Updates a spec file with metadata from the CPAN.


=head1 SEE ALSO

L<Fedora::App::MaintainerTools>

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut



