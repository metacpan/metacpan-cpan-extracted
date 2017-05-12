package Gitosis::Config::Group;
use Moose;
use Moose::Util::TypeConstraints;

has [qw(name)] => (
    isa => 'Str',
    is  => 'rw',
);

subtype 'Gitosis::Config::Group::List' => as 'ArrayRef';
coerce 'Gitosis::Config::Group::List' => from 'Str' => via {
    [ split /\s+/, $_ ];
};

has [qw(writable members)] => (
    isa    => 'Gitosis::Config::Group::List',
    is     => 'rw',
    coerce => 1,
);

no Moose;
1;
__END__

__END__

=head1 NAME

Gitosis::Config::Group - A class to represent a [group] block in gitosis.conf

=head1 SYNOPSIS

	use Gitosis::Config::Group;
	my $group = Gitosis::Config::Group->new($group);

=head1 METHODS

=head2 name

=head2 writable

=head2 members

=head1 DEPENDENCIES

Moose

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
