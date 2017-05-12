package Dist::Zilla::Plugin::RunByBranch::Role::Branch;
BEGIN {
  $Dist::Zilla::Plugin::RunByBranch::Role::Branch::AUTHORITY = 'cpan:FFFINKEL';
}
{
  $Dist::Zilla::Plugin::RunByBranch::Role::Branch::VERSION = '0.214';
}

#ABSTRACT: Dist::Zilla role to run commands by Git branch regex

use Moose::Role;
use namespace::autoclean;
with qw/ Dist::Zilla::Role::Git::Repo /;

has _branch => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build__branch',
);

sub _build__branch {
    my $self = shift;

    my $ref = ( $self->git->symbolic_ref('HEAD') )[0];
    ( my $branch = $ref ) =~ s|^refs/heads/||;

    $self->log( sprintf 'Current branch is [%s]', $branch );
    return $branch;
}

around run_cmd => sub {
    my $orig    = shift;
    my $self    = shift;
    my $run_cmd = shift;

    $run_cmd =~ s/^(.*?)\s+(.*)/$2/;
    my $regexp = qr/$1/;

    if ( $self->_branch =~ m/$regexp/ ) {
        $self->log( sprintf 'Regex [%s] matches current branch [%s]', $regexp, $self->_branch );
        $self->$orig( $run_cmd, @_ );
    }
};


1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::RunByBranch::Role::Branch - Dist::Zilla role to run commands by Git branch regex

=head1 VERSION

version 0.214

=head1 DESCRIPTION

Role that surrounds run_cmd call of L<Dist::Zilla::Plugin::Run>

=head1 SEE ALSO

L<Dist::Zilla::Plugin::Run> L<Dist::Zilla::Plugin::Git>

=head1 AUTHOR

Matt Finkel <finkel.matt@gmail.com> L<http://mfinkel.net/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Matt Finkel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
