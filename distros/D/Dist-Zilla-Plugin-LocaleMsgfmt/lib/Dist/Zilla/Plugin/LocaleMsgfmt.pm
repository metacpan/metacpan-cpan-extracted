package Dist::Zilla::Plugin::LocaleMsgfmt;
BEGIN {
  $Dist::Zilla::Plugin::LocaleMsgfmt::VERSION = '1.203';
}
# ABSTRACT: compiles .po files to .mo files with Local::Msgfmt

use Locale::Msgfmt 0.14;
use Moose;
use MooseX::Has::Sugar;
use Path::Class;

with 'Dist::Zilla::Role::BeforeBuild';


# -- attributes

# For Config::MVP - specify setting names that may have multiple values and that will always
# be stored in an arrayref
sub mvp_multivalue_args { qw(locale) }



has recursive => ( ro, isa=>'Bool', default=>1 );
has locale => (
    ro, lazy, auto_deref,
    isa     => 'ArrayRef[Str]',
    default => sub {
        my $self = shift;
        my $path = dir( $self->zilla->root, 'share', 'locale' );
        return -e $path ? [ $path ] : [ ];
    },
);


# -- public methods

#
# to implement Dist::Zilla::Role::BeforeBuild
sub before_build {
    my ( $self, $args ) = @_;

    for my $dir ( $self->locale ) {
        my $path = dir($dir);
        if ( ! -e $path ) {
            warn "Skipping invalid path: $path";
            next;
        }

        # find directories if recursive behaviour wanted
        my @pathes;
        if ( $self->recursive ) {
            $path->recurse(
                callback => sub {
                    my $p = shift;
                    push @pathes, $p if -d $p;
                }
            );
        } else {
            push @pathes, $path;
        }

        # generating mo files
        foreach my $p ( @pathes ) {
            $self->log("Generating .mo files from .po files in $p");
            msgfmt( { in => $p->absolute, verbose => 1, remove => 0 } );
        }
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;


=pod

=head1 NAME

Dist::Zilla::Plugin::LocaleMsgfmt - compiles .po files to .mo files with Local::Msgfmt

=head1 VERSION

version 1.203

=head1 DESCRIPTION

Put the following in your S<F<dist.ini> :>

    [LocaleMsgfmt]
    locale = share/locale ; this is the default

This plugin will compile all of the .po files it finds in the locale directory into .mo
files, via Locale::Msgfmt.

=head1 ATTRIBUTES

=head2 recursive

Whether to look up in the locale files recursively.

=head2 locale

Path to the directory containing the locale files.

=for Pod::Coverage before_build
    mvp_multivalue_args

=head1 TODO

Remove the generated files after the build finishes, or better yet do the generation inside
the build dir.

=head1 AUTHOR

Patrick Donelan <pdonelan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Patrick Donelan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

