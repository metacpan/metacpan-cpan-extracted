package Gitosis::Config;
our $VERSION = '0.06';
use Moose;
use MooseX::Types::Path::Class qw(File);
use MooseX::AttributeHelpers;

use Gitosis::Config::Reader;
use Gitosis::Config::Writer;
use Gitosis::Config::Group;

has file => (
    isa    => File,
    coerce => 1,
    is     => 'rw',
);

has [qw(gitweb daemon loglevel repositories)] => (
    isa => 'Maybe[Str]',
    is  => 'rw',
);

has groups => (
    metaclass  => 'Collection::Array',
    isa        => 'ArrayRef[Gitosis::Config::Group]',
    is         => 'ro',
    auto_deref => 1,
    lazy_build => 1,
    provides   => {
        push => 'add_group',
		find => 'find_group',
    },
);

sub find_group_by_name {
    my ( $self, $arg ) = @_;
    $self->find_group( sub { $_[0]->name eq $arg } );
}

sub _build_groups { [] }

around 'add_group' => sub {
    my ( $next, $self, $group ) = @_;
    $group = Gitosis::Config::Group->new($group) unless ( blessed $group);
    $self->$next($group);
};

has repos => (
    metaclass  => 'Collection::Array',
    isa        => 'ArrayRef[HashRef]',
    is         => 'ro',
    auto_deref => 1,
    lazy_build => 1,
    provides   => { push => 'add_repo', }
);

sub _build_repos { [] }

#
# METHODS
#

sub to_string {
    Gitosis::Config::Writer->write_string( $_[0] );
}

sub save {
    my ($self) = @_;
    die 'Must have a filename, please set file()' unless $self->file;
    $self->file->openw->print( $self->to_string ) or die "$!";

}

#
# Constructor Hack 
#

sub BUILD {
    my ( $self, $args ) = @_;

    if ( exists $args->{config} ) {
        return $self->_build_from_config( $args->{config} );
    }

    if ( exists $args->{file} ) {
        $self->file( $args->{file} );
        my $cfg = Gitosis::Config::Reader->read_file( $args->{file} );
        return $self->_build_from_config($cfg);
    }
}

sub _build_from_config {
    my ( $self, $cfg ) = @_;
    for my $attr (qw(gitweb daemon loglevel repositories)) {
        $self->$attr( $cfg->{gitosis}{$attr} );
    }
    for my $name ( grep { $_ =~ /^group/ } keys %$cfg ) {
        my $group = $cfg->{$name};
        ( $group->{name} = $name ) =~ s/^group\s+//;
        $self->add_group($group);
    }

    for my $name ( grep { $_ =~ /^repo/ } keys %$cfg ) {
        my $repo = $cfg->{$name};
        ( $repo->{name} = $name ) =~ s/^repo\s+//;
        $self->add_repo($repo);
    }
}

no Moose;
1;
__END__


=head1 NAME

Gitosis::Config - Parse and Write gitosis config files


=head1 VERSION

This document describes Gitosis::Config version 0.05


=head1 SYNOPSIS

    use Gitosis::Config;
    my $conf = Gitosis::Config->new( file => 'gitosis.conf' );

=head1 DESCRIPTION

Gitosis::Config is an object oriented wrapper around the gitosis config
file format. It allows you to programmatically create and modify gitosis
config files.

=head1 METHODS 

=head2 new

=head2 loglevel, gitweb, daemon, repositories

=head2 groups

=head2 add_group

=head2 repos

=head2 add_repo

=head2 to_string

=head2 save

=head1 CONFIGURATION AND ENVIRONMENT
  
Gitosis::Config requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Config::INI>, L<Moose>, L<MooseX::AttributeHelpers>,
L<MooseX::Types::Path::Class>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-gitosis-config@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Chris Prather  C<< <chris@prather.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Chris Prather C<< <chris@prather.org> >>. Some rights
reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
